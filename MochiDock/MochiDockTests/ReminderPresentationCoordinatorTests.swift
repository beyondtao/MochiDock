import Foundation
import Testing
@testable import MochiDock

@MainActor
struct ReminderPresentationCoordinatorTests {
    @Test func presentsOnceAndAutoCollapsesAfterEightSecondsWhileRemainingPending() {
        let harness = makeHarness()
        harness.coordinator.reminderBecamePending(petVisible: true, isDragging: false, isOrdinaryResponseActive: false, isPeeking: false)

        #expect(harness.actions.animationCount == 1)
        #expect(harness.actions.showCount == 1)
        #expect(harness.scheduler.scheduledDelays == [8])
        harness.scheduler.runNext()
        #expect(!harness.coordinator.isBubbleVisible)
        #expect(harness.coordinator.isPending)
        #expect(harness.actions.hideCount == 1)
    }

    @Test func clickReopensCollapsedPendingBubbleInsteadOfOrdinaryHappyAction() {
        let harness = makeHarness()
        harness.coordinator.reminderBecamePending(petVisible: true, isDragging: false, isOrdinaryResponseActive: false, isPeeking: false)
        harness.scheduler.runNext()

        #expect(harness.coordinator.handlePetClick())
        #expect(harness.actions.showCount == 2)
        #expect(harness.actions.animationCount == 1)
    }

    @Test func dragAndOrdinaryResponseDelayFirstPresentationUntilInteractionEnds() {
        for condition in [(true, false), (false, true)] {
            let harness = makeHarness()
            harness.coordinator.reminderBecamePending(
                petVisible: true,
                isDragging: condition.0,
                isOrdinaryResponseActive: condition.1,
                isPeeking: false
            )
            #expect(harness.actions.showCount == 0)
            if condition.0 {
                harness.coordinator.dragDidEnd(petVisible: true)
            } else {
                harness.coordinator.ordinaryResponseDidEnd(petVisible: true)
            }
            #expect(harness.actions.showCount == 1)
        }
    }

    @Test func overlappingDragAndHappyWaitForHappyWhenDragEndsFirstAndPresentOnce() {
        let harness = makeHarness()
        harness.coordinator.reminderBecamePending(
            petVisible: true,
            isDragging: true,
            isOrdinaryResponseActive: true,
            isPeeking: false
        )

        harness.coordinator.dragDidEnd(petVisible: true)
        #expect(harness.actions.showCount == 0)
        #expect(harness.actions.animationCount == 0)

        harness.coordinator.ordinaryResponseDidEnd(petVisible: true)
        harness.coordinator.ordinaryResponseDidEnd(petVisible: true)
        harness.coordinator.dragDidEnd(petVisible: true)
        #expect(harness.actions.showCount == 1)
        #expect(harness.actions.animationCount == 1)
        #expect(harness.coordinator.isPending)
    }

    @Test func overlappingDragAndHappyWaitForDragWhenHappyEndsFirstAndPresentOnce() {
        let harness = makeHarness()
        harness.coordinator.reminderBecamePending(
            petVisible: true,
            isDragging: true,
            isOrdinaryResponseActive: true,
            isPeeking: false
        )

        harness.coordinator.ordinaryResponseDidEnd(petVisible: true)
        #expect(harness.actions.showCount == 0)
        #expect(harness.actions.animationCount == 0)

        harness.coordinator.dragDidEnd(petVisible: true)
        harness.coordinator.dragDidEnd(petVisible: true)
        harness.coordinator.ordinaryResponseDidEnd(petVisible: true)
        #expect(harness.actions.showCount == 1)
        #expect(harness.actions.animationCount == 1)
        #expect(harness.coordinator.isPending)
    }

    @Test func peekingRestoresFullFrameBeforePresentation() {
        let harness = makeHarness()
        harness.coordinator.reminderBecamePending(petVisible: true, isDragging: false, isOrdinaryResponseActive: false, isPeeking: true)
        #expect(harness.actions.restoreCount == 1)
        #expect(harness.actions.showCount == 0)
        harness.actions.completeRestore()
        #expect(harness.actions.showCount == 1)
    }

    @Test func hideCollapsesButShowRestoresPendingWithoutReplayingAnimation() {
        let harness = makeHarness()
        harness.coordinator.reminderBecamePending(petVisible: false, isDragging: false, isOrdinaryResponseActive: false, isPeeking: false)
        #expect(harness.actions.showCount == 0)
        harness.coordinator.petDidShow()
        #expect(harness.actions.showCount == 1)
        #expect(harness.actions.animationCount == 1)
        harness.coordinator.petDidHide()
        harness.coordinator.petDidShow()
        #expect(harness.actions.showCount == 2)
        #expect(harness.actions.animationCount == 1)
    }

    @Test(arguments: [
        (true, false),
        (false, true),
        (true, true),
    ])
    func hideCancelsActiveInteractionBlockersAndShowPresentsOnce(
        isDragging: Bool,
        isOrdinaryResponseActive: Bool
    ) {
        let harness = makeHarness()
        harness.coordinator.reminderBecamePending(
            petVisible: true,
            isDragging: isDragging,
            isOrdinaryResponseActive: isOrdinaryResponseActive,
            isPeeking: false
        )
        #expect(harness.actions.showCount == 0)

        harness.coordinator.petDidHide()
        harness.coordinator.petDidHide()
        #expect(harness.actions.showCount == 0)
        #expect(harness.actions.animationCount == 0)

        harness.coordinator.petDidShow()
        harness.coordinator.petDidShow()
        #expect(harness.actions.showCount == 1)
        #expect(harness.actions.animationCount == 1)
        #expect(harness.coordinator.isPending)
    }

    @Test func pendingSuppressesDecorativeBehaviorAndRelayoutsOnlyVisibleBubble() {
        let harness = makeHarness()
        harness.coordinator.reminderBecamePending(petVisible: true, isDragging: false, isOrdinaryResponseActive: false, isPeeking: false)
        #expect(harness.coordinator.suppressesEdgeRetreat)
        #expect(harness.coordinator.suppressesDecorativeProximity)
        harness.coordinator.petGeometryDidChange()
        #expect(harness.actions.relayoutCount == 1)
        harness.scheduler.runNext()
        harness.coordinator.petGeometryDidChange()
        #expect(harness.actions.relayoutCount == 1)
        harness.coordinator.pendingWasResolved()
        #expect(!harness.coordinator.isPending)
    }

    private func makeHarness() -> PresentationHarness {
        let scheduler = TestPetAnimationScheduler()
        let actions = PresentationActions()
        let coordinator = ReminderPresentationCoordinator(
            scheduler: scheduler,
            showBubble: { actions.showCount += 1 },
            hideBubble: { actions.hideCount += 1 },
            relayoutBubble: { actions.relayoutCount += 1 },
            playReminderAnimation: { actions.animationCount += 1 },
            restoreFromPeek: { completion in
                actions.restoreCount += 1
                actions.restoreCompletion = completion
            }
        )
        return PresentationHarness(coordinator: coordinator, scheduler: scheduler, actions: actions)
    }
}

@MainActor private struct PresentationHarness {
    let coordinator: ReminderPresentationCoordinator
    let scheduler: TestPetAnimationScheduler
    let actions: PresentationActions
}

@MainActor private final class PresentationActions {
    var showCount = 0
    var hideCount = 0
    var relayoutCount = 0
    var animationCount = 0
    var restoreCount = 0
    var restoreCompletion: (() -> Void)?
    func completeRestore() { restoreCompletion?(); restoreCompletion = nil }
}
