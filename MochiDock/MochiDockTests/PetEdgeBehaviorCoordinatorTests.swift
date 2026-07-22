import CoreGraphics
import Foundation
import Testing
@testable import MochiDock

@MainActor
struct PetEdgeBehaviorCoordinatorTests {
    private let fullFrame = CGRect(x: 0, y: 200, width: 120, height: 120)
    private let peekFrame = CGRect(x: -78, y: 200, width: 120, height: 120)

    @Test func dragEndArmsOneSixSecondWaitAndExpiryMovesToPeek() {
        let harness = makeHarness()

        harness.coordinator.arm(edge: .left, fullFrame: fullFrame, peekFrame: peekFrame)

        #expect(harness.scheduler.scheduledDelays == [6])
        #expect(harness.scheduler.pendingCount == 1)
        harness.scheduler.fireNext()
        #expect(harness.moves.peekFrames == [peekFrame])
        #expect(harness.visual.values == [true])
        #expect(harness.coordinator.phase == .peeking(edge: .left, fullFrame: fullFrame, peekFrame: peekFrame))
    }

    @Test func rearmingCancelsThePreviousWaitAndStaleCallbackCannotRetreat() {
        let harness = makeHarness()
        let rightFull = CGRect(x: 1_320, y: 200, width: 120, height: 120)
        let rightPeek = CGRect(x: 1_398, y: 200, width: 120, height: 120)
        harness.coordinator.arm(edge: .left, fullFrame: fullFrame, peekFrame: peekFrame)
        harness.coordinator.arm(edge: .right, fullFrame: rightFull, peekFrame: rightPeek)

        harness.scheduler.fireEntry(at: 0, includingCancelled: true)
        #expect(harness.moves.peekFrames.isEmpty)
        harness.scheduler.fireEntry(at: 1, includingCancelled: true)
        #expect(harness.moves.peekFrames == [rightPeek])
    }

    @Test func pointerNewDragAndPlainCancellationStopAWaitingRetreat() {
        let pointer = makeHarness()
        pointer.coordinator.arm(edge: .left, fullFrame: fullFrame, peekFrame: peekFrame)
        pointer.coordinator.pointerEntered()
        pointer.scheduler.fireAllIncludingCancelled()
        #expect(pointer.moves.peekFrames.isEmpty)
        #expect(pointer.coordinator.phase == .inactive)

        let drag = makeHarness()
        drag.coordinator.arm(edge: .left, fullFrame: fullFrame, peekFrame: peekFrame)
        drag.coordinator.beginDrag()
        drag.scheduler.fireAllIncludingCancelled()
        #expect(drag.moves.peekFrames.isEmpty)

        let cancellation = makeHarness()
        cancellation.coordinator.arm(edge: .left, fullFrame: fullFrame, peekFrame: peekFrame)
        cancellation.coordinator.cancel(restoringFullFrame: false)
        cancellation.scheduler.fireAllIncludingCancelled()
        #expect(cancellation.moves.peekFrames.isEmpty)
    }

    @Test func clickDuringWaitCancelsRetreatAndForwardsOneExistingClickResponse() {
        let harness = makeHarness()
        harness.coordinator.arm(edge: .left, fullFrame: fullFrame, peekFrame: peekFrame)

        harness.coordinator.click()
        harness.scheduler.fireAllIncludingCancelled()

        #expect(harness.clicks.count == 1)
        #expect(harness.moves.fullFrames.isEmpty)
        #expect(harness.moves.peekFrames.isEmpty)
        #expect(harness.coordinator.phase == .inactive)
    }

    @Test func pointerReturnMovesToTheExactFullFrameAndLeavesPeekVisual() {
        let harness = makePeekingHarness()

        harness.coordinator.pointerEntered()

        #expect(harness.moves.fullFrames == [fullFrame])
        #expect(harness.visual.values == [true])
        harness.moves.completeReturn()
        #expect(harness.visual.values == [true, false])
        #expect(harness.clicks.count == 0)
        #expect(harness.coordinator.phase == .inactive)
    }

    @Test func clickReturnWaitsForMovementCompletionThenRequestsOneResponse() {
        let harness = makePeekingHarness()

        harness.coordinator.click()
        harness.coordinator.click()
        #expect(harness.clicks.count == 0)
        #expect(harness.moves.fullFrames == [fullFrame])

        harness.moves.completeReturn()
        harness.moves.completeReturn()
        #expect(harness.visual.values == [true, false])
        #expect(harness.clicks.count == 1)
        #expect(harness.coordinator.phase == .inactive)
    }

    @Test func hideSizeAndScreenCancellationRestoreBeforeBecomingInactive() {
        for _ in 0..<3 {
            let harness = makePeekingHarness()
            harness.coordinator.cancel(restoringFullFrame: true)
            #expect(harness.moves.fullFrames == [fullFrame])
            harness.moves.completeReturn()
            #expect(harness.coordinator.phase == .inactive)
            #expect(harness.clicks.count == 0)
        }
    }

    @Test func cancellingAnInFlightReturnInvalidatesItsClickAndStaleCompletion() {
        let harness = makePeekingHarness()
        harness.coordinator.click()

        #expect(harness.coordinator.fullFrameToRestore == fullFrame)
        harness.coordinator.cancel(restoringFullFrame: false)
        #expect(harness.coordinator.phase == .inactive)
        #expect(harness.visual.values == [true, false])

        harness.moves.completeReturn()
        #expect(harness.coordinator.phase == .inactive)
        #expect(harness.visual.values == [true, false])
        #expect(harness.clicks.count == 0)
    }

    private func makePeekingHarness() -> CoordinatorHarness {
        let harness = makeHarness()
        harness.coordinator.arm(edge: .left, fullFrame: fullFrame, peekFrame: peekFrame)
        harness.scheduler.fireNext()
        return harness
    }

    private func makeHarness() -> CoordinatorHarness {
        let scheduler = EdgeTestScheduler()
        let moves = EdgeMoveRecorder()
        let visual = EdgeBoolRecorder()
        let clicks = EdgeCounter()
        let coordinator = PetEdgeBehaviorCoordinator(
            scheduler: scheduler,
            moveToPeek: { moves.peekFrames.append($0) },
            moveToFull: { frame, completion in
                moves.fullFrames.append(frame)
                moves.completion = completion
            },
            setPeekVisual: { visual.values.append($0) },
            requestClickResponse: { clicks.count += 1 }
        )
        return CoordinatorHarness(
            coordinator: coordinator,
            scheduler: scheduler,
            moves: moves,
            visual: visual,
            clicks: clicks
        )
    }
}

@MainActor private struct CoordinatorHarness {
    let coordinator: PetEdgeBehaviorCoordinator
    let scheduler: EdgeTestScheduler
    let moves: EdgeMoveRecorder
    let visual: EdgeBoolRecorder
    let clicks: EdgeCounter
}

@MainActor private final class EdgeMoveRecorder {
    var peekFrames: [CGRect] = []
    var fullFrames: [CGRect] = []
    var completion: (() -> Void)?
    func completeReturn() {
        let action = completion
        completion = nil
        action?()
    }
}

@MainActor private final class EdgeBoolRecorder { var values: [Bool] = [] }
@MainActor private final class EdgeCounter { var count = 0 }

@MainActor private final class EdgeTestScheduler: PetAnimationScheduling {
    private final class Entry: PetAnimationScheduledTask {
        let action: @MainActor () -> Void
        var isCancelled = false
        init(action: @escaping @MainActor () -> Void) { self.action = action }
        func cancel() { isCancelled = true }
    }

    private var entries: [Entry] = []
    private(set) var scheduledDelays: [TimeInterval] = []
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

    func fireNext() {
        guard let index = entries.firstIndex(where: { !$0.isCancelled }) else { return }
        fireEntry(at: index, includingCancelled: false)
    }

    func fireEntry(at index: Int, includingCancelled: Bool) {
        guard entries.indices.contains(index) else { return }
        let entry = entries[index]
        guard includingCancelled || !entry.isCancelled else { return }
        entry.action()
    }

    func fireAllIncludingCancelled() {
        for entry in entries { entry.action() }
    }
}
