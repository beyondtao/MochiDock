import SwiftUI

struct PetGeometryAnimationSpecification: Equatable {
    let duration: TimeInterval

    var animation: Animation {
        .easeInOut(duration: duration)
    }
}

enum PetRenderPolicy {
    static var discreteContentTransaction: Transaction {
        nonAnimatedTransaction()
    }

    static var displaySizeTransaction: Transaction {
        nonAnimatedTransaction()
    }

    static func geometryAnimation(
        for state: PetAnimationState,
        timing: PetAnimationTiming
    ) -> PetGeometryAnimationSpecification? {
        let duration: TimeInterval
        switch state {
        case .breathingIn: duration = timing.breathingRise
        case .breathingOut: duration = timing.breathingFall
        case .anticipatingResponse: duration = timing.responseAnticipation
        case .jumpingUp: duration = timing.responseRise
        case .falling: duration = timing.responseFall
        case .recovering: duration = timing.recoveryDuration
        case .attentionTail: duration = timing.attentionTailDuration
        case .attentionBase: duration = timing.attentionBaseDuration
        case .idle, .blinkingHalfClosed, .blinkingClosed, .blinkingHalfOpen:
            return nil
        }
        return PetGeometryAnimationSpecification(duration: duration)
    }

    static func disableDiscreteContentAnimation(_ transaction: inout Transaction) {
        transaction.animation = nil
        transaction.disablesAnimations = true
    }

    private static func nonAnimatedTransaction() -> Transaction {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        return transaction
    }
}
