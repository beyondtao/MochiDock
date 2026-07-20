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

        scheduler.runNext()

        #expect(model.mood == .resting)
    }

    @Test func moodAccessibilityValuesAreLocalized() {
        #expect(localized(PetMood.resting.accessibilityValue) == localizedKey("Resting"))
        #expect(localized(PetMood.happy.accessibilityValue) == localizedKey("Happy"))
    }

    private func localized(_ resource: LocalizedStringResource) -> String {
        String(localized: resource)
    }

    private func localizedKey(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }
}
