import Foundation
import SwiftUI

enum PetAnimationState: Equatable {
    case idle
    case breathingIn
    case breathingOut
    case blinkingHalfClosed
    case blinkingClosed
    case blinkingHalfOpen
    case anticipatingResponse
    case jumpingUp
    case falling
    case recovering
    case attentionTail
    case attentionBase
    case reminderLift
    case reminderNodDown
    case reminderNodUp
    case reminderRecovery
}

enum PetVisualState: CaseIterable, Equatable {
    case idle
    case halfBlink
    case fullBlink
    case happy
    case attentionBase
    case attentionTail
}

struct PetAnimationTiming: Equatable {
    let breathingPeakScale: CGFloat
    let idlePause: TimeInterval
    let breathingRise: TimeInterval
    let breathingFall: TimeInterval
    let breathingCyclesPerBlink: Int
    let blinkFrameDuration: TimeInterval
    let responseAnticipation: TimeInterval
    let responseRise: TimeInterval
    let responseFall: TimeInterval
    let recoveryDuration: TimeInterval
    let attentionTailDuration: TimeInterval
    let attentionBaseDuration: TimeInterval

    static let standard = PetAnimationTiming(
        breathingPeakScale: 1.022,
        idlePause: 3.8,
        breathingRise: 1.35,
        breathingFall: 1.55,
        breathingCyclesPerBlink: 3,
        blinkFrameDuration: 0.09,
        responseAnticipation: 0.10,
        responseRise: 0.16,
        responseFall: 0.18,
        recoveryDuration: 0.12,
        attentionTailDuration: 0.22,
        attentionBaseDuration: 0.55
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
