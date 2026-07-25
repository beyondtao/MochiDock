import AppKit
import SwiftUI

@MainActor
final class ReminderPanelController {
    private let center: ReminderCenter
    private let model: PetInteractionModel
    private let petPanel: () -> NSPanel?
    private let visibleFrames: () -> [NSRect]
    private let layout = ReminderBubbleLayout()
    private let restoreFromPeek: (@escaping () -> Void) -> Void
    private let interactionContext: () -> (isDragging: Bool, isPeeking: Bool)
    private let pendingStateChanged: (Bool) -> Void
    private(set) var presentation: ReminderPresentationCoordinator!
    private(set) var panel: NSPanel?

    var suppressesEdgeRetreat: Bool { presentation.suppressesEdgeRetreat }
    var suppressesDecorativeProximity: Bool { presentation.suppressesDecorativeProximity }

    init(
        center: ReminderCenter,
        model: PetInteractionModel,
        petPanel: @escaping () -> NSPanel?,
        visibleFrames: @escaping () -> [NSRect],
        scheduler: any PetAnimationScheduling,
        restoreFromPeek: @escaping (@escaping () -> Void) -> Void,
        interactionContext: @escaping () -> (isDragging: Bool, isPeeking: Bool) = { (false, false) },
        pendingStateChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.center = center
        self.model = model
        self.petPanel = petPanel
        self.visibleFrames = visibleFrames
        self.restoreFromPeek = restoreFromPeek
        self.interactionContext = interactionContext
        self.pendingStateChanged = pendingStateChanged
        self.presentation = ReminderPresentationCoordinator(
            scheduler: scheduler,
            showBubble: { [weak self] in self?.showBubble() },
            hideBubble: { [weak self] in self?.panel?.orderOut(nil) },
            relayoutBubble: { [weak self] in self?.relayout() },
            playReminderAnimation: { [weak model] in model?.playReminderAnimation() },
            restoreFromPeek: { [weak self] completion in
                self?.restoreFromPeek(completion) ?? completion()
            }
        )
        center.onReminderPending = { [weak self] _ in
            let context = self?.interactionContext()
            self?.presentPending(
                isDragging: context?.isDragging ?? false,
                isOrdinaryResponseActive: model.isOrdinaryResponseActive,
                isPeeking: context?.isPeeking ?? false
            )
            self?.pendingStateChanged(true)
        }
        center.onPendingResolved = { [weak self] in
            self?.presentation.pendingWasResolved()
            self?.pendingStateChanged(false)
        }
        synchronizePendingState()
    }

    func presentPending(
        isDragging: Bool,
        isOrdinaryResponseActive: Bool,
        isPeeking: Bool
    ) {
        guard center.pendingReminder != nil else { return }
        presentation.reminderBecamePending(
            petVisible: petPanel()?.isVisible == true,
            isDragging: isDragging,
            isOrdinaryResponseActive: isOrdinaryResponseActive,
            isPeeking: isPeeking
        )
    }

    func petDidShow(isDragging: Bool, isPeeking: Bool) {
        if presentation.isPending {
            presentation.petDidShow()
        } else if center.pendingReminder != nil {
            presentPending(
                isDragging: isDragging,
                isOrdinaryResponseActive: model.isOrdinaryResponseActive,
                isPeeking: isPeeking
            )
        }
    }

    func petDidHide() { presentation.petDidHide() }
    func dragDidEnd() { presentation.dragDidEnd(petVisible: petPanel()?.isVisible == true) }
    func ordinaryResponseDidEnd() {
        presentation.ordinaryResponseDidEnd(petVisible: petPanel()?.isVisible == true)
    }
    func petGeometryDidChange() { presentation.petGeometryDidChange() }
    func handlePetClick() -> Bool { presentation.handlePetClick() }

    func complete() {
        try? center.completePending()
    }

    func snooze() {
        try? center.snoozePending()
    }

    func pendingWasDeleted() { presentation.pendingWasResolved() }

    private func synchronizePendingState() {
        guard center.pendingReminder != nil else {
            pendingStateChanged(false)
            return
        }
        let context = interactionContext()
        presentPending(
            isDragging: context.isDragging,
            isOrdinaryResponseActive: model.isOrdinaryResponseActive,
            isPeeking: context.isPeeking
        )
        pendingStateChanged(true)
    }

    private func showBubble() {
        guard let reminder = center.pendingReminder else { return }
        let panel = panel ?? makePanel()
        panel.contentView = NSHostingView(rootView: ReminderBubbleView(
            reminder: reminder,
            onComplete: { [weak self] in self?.complete() },
            onSnooze: { [weak self] in self?.snooze() }
        ))
        panel.contentView?.layoutSubtreeIfNeeded()
        relayout()
        panel.orderFrontRegardless()
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 112),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        self.panel = panel
        return panel
    }

    private func relayout() {
        guard let petWindow = petPanel(), let panel else { return }
        let frames = visibleFrames()
        guard let screen = frames.max(by: {
            $0.intersection(petWindow.frame).area < $1.intersection(petWindow.frame).area
        }) else { return }
        let requested = panel.contentView?.fittingSize ?? panel.frame.size
        let result = layout.layout(
            petFrame: petWindow.frame,
            requestedBubbleSize: requested,
            visibleFrame: screen
        )
        panel.setFrame(result.frame, display: true, animate: false)
    }
}

private extension CGRect {
    var area: CGFloat { max(0, width) * max(0, height) }
}
