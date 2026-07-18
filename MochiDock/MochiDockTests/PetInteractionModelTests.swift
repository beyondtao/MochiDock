import Testing
@testable import MochiDock

@MainActor
struct PetInteractionModelTests {
    @Test func startsResting() {
        let model = PetInteractionModel()

        #expect(model.mood == .resting)
    }

    @Test func clickChangesRestingToHappy() {
        let model = PetInteractionModel()

        model.handleClick()

        #expect(model.mood == .happy)
    }

    @Test func secondClickReturnsHappyToResting() {
        let model = PetInteractionModel()
        model.handleClick()

        model.handleClick()

        #expect(model.mood == .resting)
    }
}
