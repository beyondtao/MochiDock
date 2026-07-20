import CoreGraphics
import Foundation
import Testing
@testable import MochiDock

@MainActor
struct PointerProximityDetectorTests {
    private let panelFrame = CGRect(x: 100, y: 100, width: 120, height: 120)

    @Test func thresholdsScaleWithTheDisplayedPetSizeAndKeepExitLargerThanEntry() {
        let thresholds = PointerProximityTiming.standard.thresholds(for: panelFrame)
        #expect(thresholds.enterInset == 36)
        #expect(thresholds.exitInset == 54)
        #expect(thresholds.exitInset > thresholds.enterInset)
    }

    @Test func startingWhilePointerIsInsideRequiresARealExitBeforeEntry() {
        let harness = makeHarness(initialPointer: CGPoint(x: 110, y: 110))
        harness.detector.start()
        harness.scheduler.runNext()
        #expect(harness.entryCount() == 0)
        harness.pointer.set(CGPoint(x: 20, y: 20))
        harness.scheduler.runNext()
        harness.pointer.set(CGPoint(x: 90, y: 160))
        harness.scheduler.runNext()
        #expect(harness.entryCount() == 1)
    }

    @Test func firstEntryTriggersOnceAndStationaryPointerDoesNotRepeat() {
        let harness = makeHarness(initialPointer: CGPoint(x: 20, y: 20))
        harness.detector.start()
        harness.scheduler.runNext()
        harness.pointer.set(CGPoint(x: 90, y: 160))
        harness.scheduler.runNext()
        for _ in 0..<5 { harness.scheduler.runNext() }
        #expect(harness.entryCount() == 1)
        #expect(harness.scheduler.pendingCount == 1)
    }

    @Test func exitAndCooldownAreBothRequiredBeforeRetriggering() {
        let clock = TestMonotonicClock()
        let harness = makeHarness(initialPointer: CGPoint(x: 20, y: 20), clock: clock)
        harness.detector.start()
        harness.scheduler.runNext()
        harness.pointer.set(CGPoint(x: 90, y: 160))
        harness.scheduler.runNext()
        harness.pointer.set(CGPoint(x: 20, y: 20))
        harness.scheduler.runNext()
        harness.pointer.set(CGPoint(x: 90, y: 160))
        harness.scheduler.runNext()
        #expect(harness.entryCount() == 1)
        harness.pointer.set(CGPoint(x: 20, y: 20))
        harness.scheduler.runNext()
        clock.advance(by: PointerProximityTiming.standard.cooldown)
        harness.pointer.set(CGPoint(x: 90, y: 160))
        harness.scheduler.runNext()
        #expect(harness.entryCount() == 2)
    }

    @Test func draggingSuppressesEntriesAndReleaseResynchronizesWithoutImmediateTrigger() {
        let harness = makeHarness(initialPointer: CGPoint(x: 20, y: 20))
        harness.detector.start()
        harness.scheduler.runNext()
        harness.detector.setDragging(true)
        harness.pointer.set(CGPoint(x: 120, y: 120))
        harness.scheduler.runNext()
        harness.detector.setDragging(false)
        for _ in 0..<3 { harness.scheduler.runNext() }
        #expect(harness.entryCount() == 0)
        harness.pointer.set(CGPoint(x: 20, y: 20))
        harness.scheduler.runNext()
        harness.pointer.set(CGPoint(x: 120, y: 120))
        harness.scheduler.runNext()
        #expect(harness.entryCount() == 1)
    }

    @Test func stopCancelsSamplingAndRestartKeepsOneSchedule() {
        let harness = makeHarness(initialPointer: CGPoint(x: 20, y: 20))
        harness.detector.start()
        harness.detector.start()
        #expect(harness.scheduler.pendingCount == 1)
        harness.detector.stop()
        #expect(harness.scheduler.pendingCount == 0)
        harness.detector.start()
        harness.detector.start()
        #expect(harness.scheduler.pendingCount == 1)
    }

    private func makeHarness(
        initialPointer: CGPoint,
        clock: TestMonotonicClock? = nil
    ) -> DetectorHarness {
        let clock = clock ?? TestMonotonicClock()
        let scheduler = TestPetAnimationScheduler()
        let pointer = TestPointerSource(location: initialPointer)
        let entries = EntryCounter()
        let detector = PointerProximityDetector(
            scheduler: scheduler,
            pointerLocation: { pointer.location },
            now: { clock.now },
            panelFrame: { panelFrame },
            onEligibleEntry: { entries.value += 1; return true }
        )
        return DetectorHarness(detector: detector, scheduler: scheduler, pointer: pointer) {
            entries.value
        }
    }
}

@MainActor private struct DetectorHarness {
    let detector: PointerProximityDetector
    let scheduler: TestPetAnimationScheduler
    let pointer: TestPointerSource
    let entryCount: () -> Int
}

@MainActor private final class TestPointerSource {
    private(set) var location: CGPoint
    init(location: CGPoint) { self.location = location }
    func set(_ location: CGPoint) { self.location = location }
}

@MainActor private final class TestMonotonicClock {
    private(set) var now: TimeInterval = 0
    func advance(by interval: TimeInterval) { now += interval }
}

@MainActor private final class EntryCounter { var value = 0 }
