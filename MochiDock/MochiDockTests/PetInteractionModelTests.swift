import Foundation
import Testing
@testable import MochiDock

@MainActor
struct PetInteractionModelTests {
    @Test func startsResting() {
        let model = PetInteractionModel(
            scheduler: TestPetAnimationScheduler(),
            preferences: InMemoryPetPreferences()
        )

        #expect(model.mood == .resting)
    }

    @Test func clickChangesRestingToHappy() {
        let model = PetInteractionModel(
            scheduler: TestPetAnimationScheduler(),
            preferences: InMemoryPetPreferences()
        )

        model.handleClick()

        #expect(model.mood == .happy)
    }

    @Test func clickRecoversHappyToRestingAfterScheduledResponse() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(
            scheduler: scheduler,
            preferences: InMemoryPetPreferences()
        )
        model.handleClick()

        for _ in 0..<4 { scheduler.runNext() }

        #expect(model.mood == .resting)
    }

    @Test func moodAccessibilityValuesAreLocalized() {
        #expect(localized(PetMood.resting.accessibilityValue) == localizedKey("Resting"))
        #expect(localized(PetMood.happy.accessibilityValue) == localizedKey("Happy"))
    }

    @Test func enteringEdgePeekCancelsOrdinaryPlaybackAndHoldsAttentionBaseWithoutALoop() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(
            scheduler: scheduler,
            preferences: InMemoryPetPreferences()
        )
        model.startPlayback()
        #expect(scheduler.pendingCount == 1)

        model.enterEdgePeekVisual()

        #expect(model.visualState == .attentionBase)
        #expect(model.animationState == .attentionBase)
        #expect(model.mood == .resting)
        #expect(scheduler.pendingCount == 0)
        #expect(scheduler.totalScheduled == 1)
    }

    @Test func leavingEdgePeekResumesOneOrdinaryIdleScheduleAndIsIdempotent() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(
            scheduler: scheduler,
            preferences: InMemoryPetPreferences()
        )
        model.startPlayback()
        model.enterEdgePeekVisual()

        model.leaveEdgePeekVisual()
        model.leaveEdgePeekVisual()

        #expect(model.visualState == .idle)
        #expect(model.animationState == .idle)
        #expect(scheduler.pendingCount == 1)
        #expect(scheduler.totalScheduled == 2)
    }

    @Test func clickAfterLeavingEdgePeekUsesTheExistingHappyResponse() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(
            scheduler: scheduler,
            preferences: InMemoryPetPreferences()
        )
        model.startPlayback()
        model.enterEdgePeekVisual()
        model.leaveEdgePeekVisual()

        model.handleClick()

        #expect(model.mood == .happy)
        #expect(model.visualState == .happy)
        #expect(model.animationState == .anticipatingResponse)
        #expect(scheduler.pendingCount == 1)
    }

    @Test func stoppingPlaybackClearsAnActiveEdgePeekVisual() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(
            scheduler: scheduler,
            preferences: InMemoryPetPreferences()
        )
        model.startPlayback()
        model.enterEdgePeekVisual()

        model.stopPlayback()

        #expect(model.visualState == .idle)
        #expect(model.animationState == .idle)
        #expect(model.mood == .resting)
        #expect(scheduler.pendingCount == 0)
    }

    @Test func reminderAnimationUsesAttentionVisualForOneLiftAndTwoNodsThenReturnsIdle() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(
            scheduler: scheduler,
            preferences: InMemoryPetPreferences()
        )
        var completionCount = 0

        model.playReminderAnimation { completionCount += 1 }

        #expect(model.visualState == .attentionBase)
        #expect(model.animationState == .reminderLift)
        for _ in 0..<6 { scheduler.runNext() }
        #expect(model.visualState == .idle)
        #expect(model.animationState == .idle)
        #expect(completionCount == 1)
        #expect(scheduler.scheduledDelays.reduce(0, +) == 1.5)
    }

    private func localized(_ resource: LocalizedStringResource) -> String {
        String(localized: resource)
    }

    private func localizedKey(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }
}
