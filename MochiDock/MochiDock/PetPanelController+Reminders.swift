import Foundation

@MainActor
extension PetPanelController {
    func connectReminderCenter(_ center: ReminderCenter) {
        connectReminderCenter(center, scheduler: DispatchPetAnimationScheduler())
    }

    func connectReminderCenter(
        _ center: ReminderCenter,
        scheduler: any PetAnimationScheduling
    ) {
        reminderPanelController = ReminderPanelController(
            center: center,
            model: model,
            petPanel: { [weak self] in self?.panel },
            visibleFrames: visibleFrames,
            scheduler: scheduler,
            restoreFromPeek: { [weak self] completion in
                self?.restoreFullFrameImmediatelyIfNeeded()
                completion()
            },
            interactionContext: { [weak self] in
                (self?.dragStartFrame != nil, self?.isPeeking ?? false)
            },
            pendingStateChanged: { [weak self] pending in
                guard let self else { return }
                cancelProximityIntent()
                if pending {
                    edgeCoordinator.cancel(restoringFullFrame: false)
                } else {
                    rearmEdgeBehaviorForCurrentFrame()
                }
            }
        )
        model.onOrdinaryResponseEnded = { [weak self] in
            self?.reminderPanelController?.ordinaryResponseDidEnd()
        }
    }
}
