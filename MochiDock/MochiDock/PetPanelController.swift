import AppKit
import SwiftUI

@MainActor
final class PetPanelController {
    private let model: PetInteractionModel
    private let preferences: any PetPreferencesStoring
    private let visibleFrames: () -> [NSRect]
    private let notificationCenter: NotificationCenter
    private let placement = PetWindowPlacement()
    private var proximityDetector: (any PointerProximityDetecting)!
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
        self.proximityDetector = nil
        self.proximityDetector = PointerProximityDetector(
            scheduler: DispatchPetAnimationScheduler(),
            pointerLocation: { NSEvent.mouseLocation },
            now: { ProcessInfo.processInfo.systemUptime },
            panelFrame: { [weak self] in self?.panel?.frame ?? .zero },
            onEligibleEntry: { [weak model] in model?.handleProximityEntry() ?? false }
        )
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
        self.proximityDetector = proximityDetector
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
        self.proximityDetector = proximityDetector
        observeScreenChanges()
    }

    func showPet() {
        let panel = panel ?? makePanel()
        panel.orderFrontRegardless()
        model.startPlayback()
        proximityDetector.start()
    }

    func hidePet() {
        proximityDetector.stop()
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

    func selectDisplaySize(_ size: PetDisplaySize) {
        guard model.displaySize != size else { return }

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
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: PetView(model: model))
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
    }

    @objc private func screenParametersDidChange() {
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
    }

    private func persistPosition(of frame: NSRect) {
        guard let value = PetWindowPosition(origin: frame.origin).encoded() else { return }
        preferences.set(value, forKey: PetPreferenceKey.windowPosition)
    }
}

@MainActor
final class PetPanel: NSPanel {
    var onPointerContactChanged: ((Bool) -> Void)?

    func pointerContactChanged(_ isDown: Bool) {
        onPointerContactChanged?(isDown)
    }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            pointerContactChanged(true)
        case .leftMouseUp:
            pointerContactChanged(false)
        default:
            break
        }
        super.sendEvent(event)
    }
}
