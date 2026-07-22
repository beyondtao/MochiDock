import Foundation

@MainActor
final class PetProximityIntentGate {
    static let delay: TimeInterval = 0.25

    private let scheduler: any PetAnimationScheduling
    private var task: (any PetAnimationScheduledTask)?
    private var generation = 0

    init(scheduler: any PetAnimationScheduling) {
        self.scheduler = scheduler
    }

    func request(_ action: @escaping @MainActor () -> Void) {
        guard task == nil else { return }
        generation += 1
        let requestedGeneration = generation
        task = scheduler.schedule(after: Self.delay) { [weak self] in
            guard let self, generation == requestedGeneration else { return }
            task = nil
            action()
        }
    }

    func cancel() {
        generation += 1
        task?.cancel()
        task = nil
    }
}
