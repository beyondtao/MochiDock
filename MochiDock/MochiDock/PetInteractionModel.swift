import Observation

enum PetMood: Equatable {
    case resting
    case happy
}

@MainActor
@Observable
final class PetInteractionModel {
    private(set) var mood: PetMood = .resting

    func handleClick() {
        mood = mood == .resting ? .happy : .resting
    }
}
