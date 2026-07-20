import SwiftUI
import Testing
@testable import MochiDock

@MainActor
struct PetRenderingPolicyTests {
    @Test func visualResourceChangesUseANonAnimatedTransaction() {
        let transaction = PetRenderPolicy.discreteContentTransaction

        #expect(transaction.disablesAnimations)
        #expect(transaction.animation == nil)
    }

    @Test func displaySizeChangesUseANonAnimatedTransaction() {
        let transaction = PetRenderPolicy.displaySizeTransaction

        #expect(transaction.disablesAnimations)
        #expect(transaction.animation == nil)
    }

    @Test func geometryAnimationRetainsTheCurrentStageDuration() {
        let timing = PetAnimationTiming.standard
        let stages: [(PetAnimationState, TimeInterval)] = [
            (.breathingIn, timing.breathingRise),
            (.breathingOut, timing.breathingFall),
            (.anticipatingResponse, timing.responseAnticipation),
            (.jumpingUp, timing.responseRise),
            (.falling, timing.responseFall),
            (.recovering, timing.recoveryDuration),
        ]

        for (state, expectedDuration) in stages {
            let specification = PetRenderPolicy.geometryAnimation(
                for: state,
                timing: timing
            )
            #expect(specification?.duration == expectedDuration)
        }
    }

    @Test func blinkStagesChangeOnlyDiscreteContentWithoutGeometryAnimation() {
        for state in [
            PetAnimationState.blinkingHalfClosed,
            .blinkingClosed,
            .blinkingHalfOpen,
        ] {
            #expect(
                PetRenderPolicy.geometryAnimation(for: state, timing: .standard) == nil
            )
        }
    }

    @Test func clickAndRecoveryKeepResourceSwitchesDiscreteWhileGeometryStaysAnimated() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(
            scheduler: scheduler,
            preferences: InMemoryPetPreferences()
        )

        model.startPlayback()
        model.handleClick()
        #expect(model.visualState == .happy)
        #expect(PetRenderPolicy.discreteContentTransaction.disablesAnimations)
        #expect(
            PetRenderPolicy.geometryAnimation(for: model.animationState, timing: model.timing)?.duration
                == model.timing.responseAnticipation
        )

        for _ in 0..<4 { scheduler.runNext() }
        #expect(model.visualState == .idle)
        #expect(model.animationState == .idle)
        #expect(PetRenderPolicy.discreteContentTransaction.disablesAnimations)
        #expect(PetRenderPolicy.geometryAnimation(for: model.animationState, timing: model.timing) == nil)
    }
}
