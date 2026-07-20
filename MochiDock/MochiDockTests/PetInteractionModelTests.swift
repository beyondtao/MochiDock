import Testing
@testable import MochiDock

@MainActor
struct PetInteractionModelTests {
    @Test func startsResting() {
        let model = PetInteractionModel(scheduler: TestPetAnimationScheduler())

        #expect(model.mood == .resting)
    }

    @Test func clickChangesRestingToHappy() {
        let model = PetInteractionModel(scheduler: TestPetAnimationScheduler())

        model.handleClick()

        #expect(model.mood == .happy)
    }

    @Test func clickRecoversHappyToRestingAfterScheduledResponse() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler)
        model.handleClick()

        scheduler.runNext()

        #expect(model.mood == .resting)
    }
}
