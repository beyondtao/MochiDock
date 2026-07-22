import AppKit
import SwiftUI

@MainActor
final class PetPanelController {
    private let model: PetInteractionModel
    private let preferences: any PetPreferencesStoring
    private let visibleFrames: () -> [NSRect]
    private let notificationCenter: NotificationCenter
    private let placement = PetWindowPlacement()
    private let edgePlacement = PetEdgePlacement()
    private let frameAnimator: any PetPanelFrameAnimating
    private let proximityIntentGate: PetProximityIntentGate
    private var proximityDetector: (any PointerProximityDetecting)!
    private var edgeCoordinator: PetEdgeBehaviorCoordinator!
    private var isProximityDetectorRunning = false
    private var dragStartFrame: NSRect?
    private var pendingRestorationFrame: NSRect?
    private(set) var panel: NSPanel?

    var isPetVisible: Bool {
        panel?.isVisible == true
    }

    init(model: PetInteractionModel) {
        self.model = model
        self.preferences = model.preferencesStore
        self.visibleFrames = { NSScreen.screens.map(\.visibleFrame) }
        self.notificationCenter = .default
        self.frameAnimator = AppKitPetPanelFrameAnimator()
        self.proximityIntentGate = PetProximityIntentGate(scheduler: DispatchPetAnimationScheduler())
        self.proximityDetector = nil
        self.edgeCoordinator = nil
        self.proximityDetector = PointerProximityDetector(
            scheduler: DispatchPetAnimationScheduler(),
            pointerLocation: { NSEvent.mouseLocation },
            now: { ProcessInfo.processInfo.systemUptime },
            panelFrame: { [weak self] in self?.panel?.frame ?? .zero },
            onEligibleEntry: { [weak self] in self?.handleProximityEntry() ?? false }
        )
        configureEdgeCoordinator(scheduler: DispatchPetAnimationScheduler())
        observeScreenChanges()
    }

    init(
        model: PetInteractionModel,
        proximityDetector: any PointerProximityDetecting
    ) {
        self.model = model
        self.preferences = model.preferencesStore
        self.visibleFrames = { NSScreen.screens.map(\.visibleFrame) }
        self.notificationCenter = .default
        self.frameAnimator = AppKitPetPanelFrameAnimator()
        self.proximityIntentGate = PetProximityIntentGate(scheduler: DispatchPetAnimationScheduler())
        self.proximityDetector = proximityDetector
        self.edgeCoordinator = nil
        configureEdgeCoordinator(scheduler: DispatchPetAnimationScheduler())
        observeScreenChanges()
    }

    init(
        model: PetInteractionModel,
        proximityDetector: any PointerProximityDetecting,
        visibleFrames: @escaping () -> [NSRect],
        notificationCenter: NotificationCenter
    ) {
        self.model = model
        self.preferences = model.preferencesStore
        self.visibleFrames = visibleFrames
        self.notificationCenter = notificationCenter
        self.frameAnimator = AppKitPetPanelFrameAnimator()
        self.proximityIntentGate = PetProximityIntentGate(scheduler: DispatchPetAnimationScheduler())
        self.proximityDetector = proximityDetector
        self.edgeCoordinator = nil
        configureEdgeCoordinator(scheduler: DispatchPetAnimationScheduler())
        observeScreenChanges()
    }

    init(
        model: PetInteractionModel,
        proximityDetector: any PointerProximityDetecting,
        visibleFrames: @escaping () -> [NSRect],
        notificationCenter: NotificationCenter,
        edgeScheduler: any PetAnimationScheduling,
        frameAnimator: any PetPanelFrameAnimating
    ) {
        self.model = model
        self.preferences = model.preferencesStore
        self.visibleFrames = visibleFrames
        self.notificationCenter = notificationCenter
        self.frameAnimator = frameAnimator
        self.proximityIntentGate = PetProximityIntentGate(scheduler: DispatchPetAnimationScheduler())
        self.proximityDetector = proximityDetector
        self.edgeCoordinator = nil
        configureEdgeCoordinator(scheduler: edgeScheduler)
        observeScreenChanges()
    }

    init(
        model: PetInteractionModel,
        proximityDetector: any PointerProximityDetecting,
        visibleFrames: @escaping () -> [NSRect],
        notificationCenter: NotificationCenter,
        edgeScheduler: any PetAnimationScheduling,
        proximityIntentScheduler: any PetAnimationScheduling,
        frameAnimator: any PetPanelFrameAnimating
    ) {
        self.model = model
        self.preferences = model.preferencesStore
        self.visibleFrames = visibleFrames
        self.notificationCenter = notificationCenter
        self.frameAnimator = frameAnimator
        self.proximityIntentGate = PetProximityIntentGate(scheduler: proximityIntentScheduler)
        self.proximityDetector = proximityDetector
        self.edgeCoordinator = nil
        configureEdgeCoordinator(scheduler: edgeScheduler)
        observeScreenChanges()
    }

    func showPet() {
        let panel = panel ?? makePanel()
        panel.orderFrontRegardless()
        model.startPlayback()
        if model.isProximityResponseEnabled {
            startProximityDetector()
        }
        rearmEdgeBehaviorForCurrentFrame()
    }

    func hidePet() {
        cancelActiveDrag()
        restoreFullFrameImmediatelyIfNeeded()
        stopProximityDetector()
        panel?.orderOut(nil)
        model.stopPlayback()
    }

    func togglePetVisibility() {
        if isPetVisible {
            hidePet()
        } else {
            showPet()
        }
    }

    func setProximityResponseEnabled(_ enabled: Bool) {
        guard model.isProximityResponseEnabled != enabled else { return }
        model.setProximityResponseEnabled(enabled)
        if enabled, isPetVisible {
            startProximityDetector()
        } else if !enabled, case .inactive = edgeCoordinator.phase {
            stopProximityDetector()
        }
    }

    func selectDisplaySize(_ size: PetDisplaySize) {
        guard model.displaySize != size else { return }

        cancelActiveDrag()
        restoreFullFrameImmediatelyIfNeeded()

        guard let panel else {
            withTransaction(PetRenderPolicy.displaySizeTransaction) {
                model.selectDisplaySize(size)
            }
            return
        }

        let center = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        let length = size.pointLength
        let frame = NSRect(
            x: center.x - length / 2,
            y: center.y - length / 2,
            width: length,
            height: length
        )
        let pendingFrame = pendingRestorationFrame.map {
            NSRect(
                origin: $0.origin,
                size: NSSize(width: length, height: length)
            )
        }
        let safeFrame = placement.safeFrame(
            for: pendingFrame ?? frame,
            visibleFrames: visibleFrames()
        )
        let finalFrame = safeFrame ?? frame

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            withTransaction(PetRenderPolicy.displaySizeTransaction) {
                model.selectDisplaySize(size)
                panel.setFrame(finalFrame, display: false, animate: false)
                panel.contentView?.layoutSubtreeIfNeeded()
            }
        }
        panel.displayIfNeeded()
        if let pendingFrame, safeFrame == nil {
            pendingRestorationFrame = pendingFrame
        } else {
            pendingRestorationFrame = nil
            persistPosition(of: finalFrame)
        }
        rearmEdgeBehaviorForCurrentFrame()
    }

    private func makePanel() -> NSPanel {
        let panel = PetPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: model.displaySize.pointLength,
                height: model.displaySize.pointLength
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.animationBehavior = NSWindow.AnimationBehavior.none
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: PetView(model: model) { [weak self] in
            self?.handlePetClick()
        })
        panel.onPointerContactChanged = { [weak self] isDown in
            self?.handlePointerContactChanged(isDown)
        }
        restoreOrCenter(panel)
        self.panel = panel
        return panel
    }

    private func observeScreenChanges() {
        notificationCenter.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func restoreOrCenter(_ panel: NSPanel) {
        guard let storedValue = preferences.string(forKey: PetPreferenceKey.windowPosition),
              let position = PetWindowPosition.decode(storedValue) else {
            panel.center()
            return
        }
        let length = model.displaySize.pointLength
        let proposedFrame = NSRect(
            origin: position.origin,
            size: NSSize(width: length, height: length)
        )
        guard let safeFrame = placement.safeFrame(
            for: proposedFrame,
            visibleFrames: visibleFrames()
        ) else {
            pendingRestorationFrame = proposedFrame
            panel.center()
            return
        }
        panel.setFrame(safeFrame, display: false)
        if safeFrame != proposedFrame {
            persistPosition(of: safeFrame)
        }
    }

    private func handlePointerContactChanged(_ isDown: Bool) {
        proximityDetector.setDragging(isDown)
        guard let panel else { return }
        if isDown {
            cancelProximityIntent()
            restoreFullFrameImmediatelyIfNeeded()
            dragStartFrame = panel.frame
            return
        }
        defer { dragStartFrame = nil }
        guard let dragStartFrame, panel.frame.origin != dragStartFrame.origin else { return }
        let finalFrame = placement.safeFrame(
            for: panel.frame,
            visibleFrames: visibleFrames()
        ) ?? panel.frame
        if finalFrame != panel.frame {
            panel.setFrame(finalFrame, display: true, animate: false)
        }
        pendingRestorationFrame = nil
        persistPosition(of: finalFrame)
        armEdgeBehaviorIfEligible(fullFrame: finalFrame)
    }

    @objc private func screenParametersDidChange() {
        cancelActiveDrag()
        restoreFullFrameImmediatelyIfNeeded()
        guard let panel else { return }
        let persistedOrigin = preferences
            .string(forKey: PetPreferenceKey.windowPosition)
            .flatMap(PetWindowPosition.decode)?
            .origin
        let proposedFrame = pendingRestorationFrame ?? panel.frame
        guard let safeFrame = placement.safeFrame(
            for: proposedFrame,
            visibleFrames: visibleFrames()
        ) else { return }

        let wasPending = pendingRestorationFrame != nil
        pendingRestorationFrame = nil
        let movedFromCurrentFrame = safeFrame != panel.frame
        if movedFromCurrentFrame {
            panel.setFrame(safeFrame, display: true, animate: false)
        }
        if safeFrame != proposedFrame
            || (!wasPending && movedFromCurrentFrame)
            || persistedOrigin.map({ $0 != safeFrame.origin }) == true {
            persistPosition(of: safeFrame)
        }
        rearmEdgeBehaviorForCurrentFrame()
    }

    private func cancelActiveDrag() {
        (panel as? PetPanel)?.cancelApplicationDrag()
        dragStartFrame = nil
        proximityDetector.setDragging(false)
        cancelProximityIntent()
    }

    private func persistPosition(of frame: NSRect) {
        guard let value = PetWindowPosition(origin: frame.origin).encoded() else { return }
        preferences.set(value, forKey: PetPreferenceKey.windowPosition)
    }

    @discardableResult
    func handleProximityEntry() -> Bool {
        let phaseBeforeEntry = edgeCoordinator.phase
        let wasPeeking: Bool
        if case .peeking = phaseBeforeEntry {
            wasPeeking = true
        } else {
            wasPeeking = false
        }
        switch phaseBeforeEntry {
        case .peeking:
            scheduleProximityIntentIfNeeded()
            return true
        case .waiting, .returning:
            edgeCoordinator.pointerEntered()
            if !model.isProximityResponseEnabled,
               !wasPeeking,
               edgeCoordinator.phase == .inactive {
                stopProximityDetector()
            }
            return true
        case .inactive:
            return model.handleProximityEntry()
        }
    }

    func handlePetClick() {
        let phaseBeforeClick = edgeCoordinator.phase
        edgeCoordinator.click()
        if !model.isProximityResponseEnabled,
           case .waiting = phaseBeforeClick {
            stopProximityDetector()
        }
    }

    private func configureEdgeCoordinator(scheduler: any PetAnimationScheduling) {
        edgeCoordinator = PetEdgeBehaviorCoordinator(
            scheduler: scheduler,
            moveToPeek: { [weak self] frame in
                guard let self, let panel else { return }
                frameAnimator.animate(panel: panel, to: frame) {}
            },
            moveToFull: { [weak self] frame, completion in
                guard let self, let panel else {
                    completion()
                    return
                }
                frameAnimator.animate(panel: panel, to: frame) { [weak self] in
                    guard let self else {
                        completion()
                        return
                    }
                    completion()
                    if case .inactive = edgeCoordinator.phase, isPetVisible {
                        rearmEdgeBehaviorForCurrentFrame()
                    }
                    if !model.isProximityResponseEnabled,
                       case .inactive = edgeCoordinator.phase {
                        stopProximityDetector()
                    }
                }
            },
            setPeekVisual: { [weak model] active in
                if active {
                    model?.enterEdgePeekVisual()
                } else {
                    model?.leaveEdgePeekVisual()
                }
            },
            requestClickResponse: { [weak model] in model?.handleClick() }
        )
    }

    private func armEdgeBehaviorIfEligible(fullFrame: NSRect) {
        let frames = visibleFrames()
        guard let edge = edgePlacement.eligibleEdge(for: fullFrame, visibleFrames: frames),
              let visibleFrame = frames.first(where: { $0.contains(fullFrame) }) else {
            edgeCoordinator.cancel(restoringFullFrame: false)
            if !model.isProximityResponseEnabled {
                stopProximityDetector()
            }
            return
        }
        let peekFrame = edgePlacement.peekFrame(
            for: fullFrame,
            edge: edge,
            visibleFrame: visibleFrame
        )
        edgeCoordinator.arm(edge: edge, fullFrame: fullFrame, peekFrame: peekFrame)
        if !model.isProximityResponseEnabled {
            startProximityDetector()
        }
    }

    private func rearmEdgeBehaviorForCurrentFrame() {
        guard let panel, panel.isVisible else { return }
        armEdgeBehaviorIfEligible(fullFrame: panel.frame)
    }

    private func scheduleProximityIntentIfNeeded() {
        proximityIntentGate.request { [weak self] in
            guard let self else { return }
            guard case .peeking = edgeCoordinator.phase else { return }
            edgeCoordinator.pointerEntered()
        }
    }

    private func cancelProximityIntent() {
        proximityIntentGate.cancel()
    }

    private func restoreFullFrameImmediatelyIfNeeded() {
        guard let panel, let fullFrame = edgeCoordinator.fullFrameToRestore else {
            edgeCoordinator.cancel(restoringFullFrame: false)
            return
        }
        frameAnimator.cancel(panel: panel)
        edgeCoordinator.cancel(restoringFullFrame: false)
        panel.setFrame(fullFrame, display: true, animate: false)
        if !model.isProximityResponseEnabled {
            stopProximityDetector()
        }
    }

    private func startProximityDetector() {
        guard !isProximityDetectorRunning else { return }
        isProximityDetectorRunning = true
        proximityDetector.start()
    }

    private func stopProximityDetector() {
        guard isProximityDetectorRunning else { return }
        isProximityDetectorRunning = false
        proximityDetector.stop()
    }
}
