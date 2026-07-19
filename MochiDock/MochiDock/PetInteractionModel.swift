import Observation

enum PetMood: Equatable {
    case resting
    case happy
}

@MainActor
@Observable
final class PetInteractionModel {
    private(set) var mood: PetMood = .resting
    private(set) var displaySize: PetDisplaySize = .medium

    func handleClick() {
        mood = mood == .resting ? .happy : .resting
    }

    func selectDisplaySize(_ size: PetDisplaySize) {
        displaySize = size
    }
}
