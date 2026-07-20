import Foundation
import SwiftUI

enum PetAnimationState: Equatable {
    case idle
    case breathingIn
    case breathingOut
    case responding
    case recovering
}

struct PetAnimationTiming: Equatable {
    let breathingPeakScale: CGFloat
    let idlePause: TimeInterval
    let breathingRise: TimeInterval
    let breathingFall: TimeInterval
    let responseDuration: TimeInterval
    let recoveryDuration: TimeInterval

    static let standard = PetAnimationTiming(
        breathingPeakScale: 1.022,
        idlePause: 3.8,
        breathingRise: 1.35,
        breathingFall: 1.55,
        responseDuration: 0.18,
        recoveryDuration: 0.22
    )
}

@MainActor
protocol PetAnimationScheduledTask: AnyObject {
    func cancel()
}

@MainActor
protocol PetAnimationScheduling: AnyObject {
    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any PetAnimationScheduledTask
}

@MainActor
final class DispatchPetAnimationScheduler: PetAnimationScheduling {
    private final class ScheduledTask: PetAnimationScheduledTask {
        private let workItem: DispatchWorkItem

        init(workItem: DispatchWorkItem) {
            self.workItem = workItem
        }

        func cancel() {
            workItem.cancel()
        }
    }

    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any PetAnimationScheduledTask {
        let workItem = DispatchWorkItem {
            MainActor.assumeIsolated {
                action()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return ScheduledTask(workItem: workItem)
    }
}
