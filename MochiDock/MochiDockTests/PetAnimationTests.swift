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

        #expect(model.animationState == .responding)
        #expect(model.mood == .happy)
        #expect(scheduler.pendingCount == 1)

        scheduler.runNext()
        #expect(model.animationState == .recovering)
        #expect(model.mood == .resting)

        scheduler.runNext()
        #expect(model.animationState == .idle)
        #expect(model.mood == .resting)
        #expect(scheduler.pendingCount == 1)
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
}
