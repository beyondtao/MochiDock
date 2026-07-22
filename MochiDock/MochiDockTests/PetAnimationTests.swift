import Foundation
import SwiftUI
import Testing
@testable import MochiDock

@MainActor
struct PetAnimationTests {
    @Test func breathingMovesToPeakThenReturnsToIdleBeforeWaiting() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())

        model.startPlayback()
        #expect(model.animationState == .idle)
        #expect(model.verticalScale == 1)
        #expect(scheduler.pendingCount == 1)

        scheduler.runNext()
        #expect(model.animationState == .breathingIn)
        #expect(model.verticalScale > 1)
        #expect(model.verticalScale <= 1.024)

        scheduler.runNext()
        #expect(model.animationState == .breathingOut)
        #expect(model.verticalScale == 1)

        scheduler.runNext()
        #expect(model.animationState == .idle)
        #expect(model.verticalScale == 1)
        #expect(scheduler.scheduledDelays.last == PetAnimationTiming.standard.idlePause)
    }

    @Test func presentationKeepsHorizontalScaleAndBottomAnchorStable() {
        let model = PetInteractionModel(
            scheduler: TestPetAnimationScheduler(),
            preferences: InMemoryPetPreferences()
        )

        #expect(model.horizontalScale == 1)
        #expect(model.scaleAnchor == .bottom)
    }

    @Test func repeatedStartAndSizeChangesKeepOneScheduledTransition() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())

        model.startPlayback()
        model.startPlayback()
        model.selectDisplaySize(.small)
        model.selectDisplaySize(.large)

        #expect(scheduler.pendingCount == 1)
        #expect(scheduler.totalScheduled == 1)
    }

    @Test func stopCancelsPlaybackAndRestartCreatesOnlyOneTransition() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
        model.startPlayback()

        model.stopPlayback()
        #expect(model.animationState == .idle)
        #expect(model.verticalScale == 1)
        #expect(scheduler.pendingCount == 0)

        model.startPlayback()
        model.startPlayback()
        #expect(scheduler.pendingCount == 1)
    }

    @Test func rapidClicksDoNotQueueResponsesAndRecoverToIdle() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
        model.startPlayback()

        for _ in 0..<20 { model.handleClick() }

        #expect(model.animationState == .anticipatingResponse)
        #expect(model.mood == .happy)
        #expect(scheduler.pendingCount == 1)

        for _ in 0..<4 { scheduler.runNext() }
        #expect(model.animationState == .idle)
        #expect(model.mood == .resting)
        #expect(scheduler.pendingCount == 1)
    }

    @Test func blinkUsesTheConfirmedVisualSequenceAndReturnsToPausedIdle() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
        model.startPlayback()

        for _ in 0..<PetAnimationTiming.standard.breathingCyclesPerBlink {
            scheduler.runNext()
            scheduler.runNext()
            scheduler.runNext()
        }
        scheduler.runNext()

        #expect(model.visualState == .halfBlink)
        scheduler.runNext()
        #expect(model.visualState == .fullBlink)
        scheduler.runNext()
        #expect(model.visualState == .halfBlink)
        scheduler.runNext()
        #expect(model.visualState == .idle)
        #expect(model.animationState == .idle)
        #expect(scheduler.scheduledDelays.last == PetAnimationTiming.standard.idlePause)
    }

    @Test func clickRunsOneBoundedHappyJumpThenRestoresIdleBreathing() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
        model.startPlayback()

        model.handleClick()
        #expect(model.visualState == .happy)
        #expect(model.animationState == .anticipatingResponse)
        #expect(model.verticalScale < 1)

        scheduler.runNext()
        #expect(model.animationState == .jumpingUp)
        #expect(model.responseOffset < 0)
        scheduler.runNext()
        #expect(model.animationState == .falling)
        scheduler.runNext()
        #expect(model.animationState == .recovering)
        scheduler.runNext()

        #expect(model.visualState == .idle)
        #expect(model.animationState == .idle)
        #expect(model.verticalScale == 1)
        #expect(model.responseOffset == 0)
        #expect(scheduler.pendingCount == 1)
    }

    @Test func clickInterruptsBlinkAndCancelledBlinkCannotResume() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
        model.startPlayback()
        for _ in 0..<PetAnimationTiming.standard.breathingCyclesPerBlink {
            scheduler.runNext()
            scheduler.runNext()
            scheduler.runNext()
        }
        scheduler.runNext()
        #expect(model.visualState == .halfBlink)

        model.handleClick()
        #expect(model.visualState == .happy)
        #expect(scheduler.pendingCount == 1)

        scheduler.runNext()
        #expect(model.animationState == .jumpingUp)
        #expect(model.visualState == .happy)
    }

    @Test func rapidClicksKeepOneBoundedResponseSchedule() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
        model.startPlayback()

        for _ in 0..<100 { model.handleClick() }

        #expect(scheduler.pendingCount == 1)
        #expect(scheduler.totalScheduled == 2)
        for _ in 0..<4 { scheduler.runNext() }
        #expect(model.animationState == .idle)
        #expect(model.visualState == .idle)
        #expect(scheduler.pendingCount == 1)
    }

    @Test func stopDuringActionCancelsAndShowRestartsOnlyOneIdleSchedule() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
        model.startPlayback()
        model.handleClick()

        model.stopPlayback()
        #expect(model.animationState == .idle)
        #expect(model.visualState == .idle)
        #expect(model.mood == .resting)
        #expect(scheduler.pendingCount == 0)

        model.startPlayback()
        model.startPlayback()
        #expect(scheduler.pendingCount == 1)
    }

    @Test func proximityRunsOneTailBaseIdleSequenceAndRestoresAutomaticPlayback() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
        model.startPlayback()

        #expect(model.handleProximityEntry())
        #expect(model.visualState == .attentionTail)
        #expect(scheduler.pendingCount == 1)
        scheduler.runNext()
        #expect(model.visualState == .attentionBase)
        scheduler.runNext()
        #expect(model.visualState == .idle)
        #expect(model.animationState == .idle)
        #expect(scheduler.pendingCount == 1)
    }

    @Test func proximityReplacesBlinkButCannotInterruptClickResponse() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
        model.startPlayback()
        for _ in 0..<PetAnimationTiming.standard.breathingCyclesPerBlink {
            scheduler.runNext(); scheduler.runNext(); scheduler.runNext()
        }
        scheduler.runNext()
        #expect(model.visualState == .halfBlink)

        #expect(model.handleProximityEntry())
        #expect(model.visualState == .attentionTail)
        model.handleClick()
        #expect(model.visualState == .happy)
        #expect(model.handleProximityEntry() == false)
        #expect(model.visualState == .happy)
        #expect(scheduler.pendingCount == 1)
    }

    @Test func disabledProximityDoesNotStartAttention() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(
            scheduler: scheduler,
            preferences: InMemoryPetPreferences(values: [
                PetPreferenceKey.proximityResponseEnabled: "false"
            ])
        )
        model.startPlayback()

        #expect(!model.handleProximityEntry())
        #expect(model.visualState == .idle)
        #expect(scheduler.pendingCount == 1)
    }

    @Test func disablingDuringAttentionCancelsItAndRestoresIdlePlayback() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(
            scheduler: scheduler,
            preferences: InMemoryPetPreferences()
        )
        model.startPlayback()
        #expect(model.handleProximityEntry())
        #expect(model.visualState == .attentionTail)

        model.setProximityResponseEnabled(false)

        #expect(model.visualState == .idle)
        #expect(model.animationState == .idle)
        #expect(model.mood == .resting)
        #expect(scheduler.pendingCount == 1)
        scheduler.runNext()
        #expect(model.animationState == .breathingIn)
    }
}

@MainActor
final class TestPetAnimationScheduler: PetAnimationScheduling {
    private final class Entry: PetAnimationScheduledTask {
        let action: @MainActor () -> Void
        var isCancelled = false

        init(action: @escaping @MainActor () -> Void) {
            self.action = action
        }

        func cancel() { isCancelled = true }
    }

    private var entries: [Entry] = []
    private(set) var scheduledDelays: [TimeInterval] = []
    var totalScheduled: Int { scheduledDelays.count }
    var pendingCount: Int { entries.count(where: { !$0.isCancelled }) }

    func schedule(
        after delay: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any PetAnimationScheduledTask {
        scheduledDelays.append(delay)
        let entry = Entry(action: action)
        entries.append(entry)
        return entry
    }

    func runNext() {
        while !entries.isEmpty {
            let entry = entries.removeFirst()
            guard !entry.isCancelled else { continue }
            entry.action()
            return
        }
    }

    func runAllIncludingCancelled() {
        let pending = entries
        entries.removeAll()
        for entry in pending { entry.action() }
    }
}
