import Foundation
import Testing
@testable import MochiDock

@MainActor
struct ReminderCenterTests {
    @Test func draftDefaultsAndValidationMatchTheProductRules() throws {
        #expect(ReminderDraft().name == "")
        #expect(ReminderDraft().intervalMinutes == 45)
        #expect(ReminderDraft.quickIntervals == [20, 30, 45, 60])
        #expect(ReminderDraft(name: "喝水", intervalMinutes: 5).validated() != nil)
        #expect(ReminderDraft(name: "", intervalMinutes: 45).validated() == nil)
        #expect(ReminderDraft(name: String(repeating: "a", count: 31), intervalMinutes: 45).validated() == nil)
        #expect(ReminderDraft(name: "喝水", intervalMinutes: 6).validated() == nil)
        #expect(ReminderDraft(name: "喝水", intervalMinutes: 245).validated() == nil)
    }

    @Test func enablingAnotherReminderPausesTheCurrentOneAndPreservesItsRemainder() throws {
        let harness = try makeHarness()
        let first = try harness.center.add(ReminderDraft(name: "喝水", intervalMinutes: 20))
        let second = try harness.center.add(ReminderDraft(name: "远眺", intervalMinutes: 30))
        try harness.center.enable(first.id)
        harness.clock.advance(by: 300)

        try harness.center.enable(second.id)

        #expect(harness.center.reminder(id: first.id)?.state == .paused)
        #expect(harness.center.reminder(id: first.id)?.remainingSeconds == 900)
        #expect(harness.center.activeReminder?.id == second.id)
        #expect(
            harness.center.statusMessage
                == ReminderLocalizedText().switched(from: "喝水", to: "远眺")
        )
        #expect(harness.scheduler.pendingCount == 1)
    }

    @Test func pauseResumeAndActiveEditUseTheRequiredCountdownRules() throws {
        let harness = try makeHarness()
        let reminder = try harness.center.add(ReminderDraft(name: "活动", intervalMinutes: 20))
        try harness.center.enable(reminder.id)
        harness.clock.advance(by: 420)

        try harness.center.pause(reminder.id)
        #expect(harness.center.reminder(id: reminder.id)?.remainingSeconds == 780)
        harness.clock.advance(by: 100)
        try harness.center.enable(reminder.id)
        #expect(harness.center.activeReminder?.nextTriggerAt == harness.clock.now.addingTimeInterval(780))

        try harness.center.edit(reminder.id, draft: ReminderDraft(name: "走动", intervalMinutes: 30))
        #expect(harness.center.activeReminder?.name == "走动")
        #expect(harness.center.activeReminder?.nextTriggerAt == harness.clock.now.addingTimeInterval(1_800))
    }

    @Test func dueFiresOnceAndWaitsForCompleteOrFixedTenMinuteSnooze() throws {
        let harness = try makeHarness()
        let reminder = try harness.center.add(ReminderDraft(name: "喝水", intervalMinutes: 5))
        try harness.center.enable(reminder.id)

        harness.clock.advance(by: 300)
        harness.scheduler.fireDue()
        harness.scheduler.fireAllIncludingCancelled()
        #expect(harness.center.pendingReminder?.id == reminder.id)
        #expect(harness.center.presentationCount == 1)
        #expect(harness.center.activeReminder?.nextTriggerAt == nil)

        try harness.center.snoozePending()
        #expect(harness.center.activeReminder?.nextTriggerAt == harness.clock.now.addingTimeInterval(600))
        harness.clock.advance(by: 600)
        harness.scheduler.fireDue()
        try harness.center.completePending()
        #expect(harness.center.activeReminder?.nextTriggerAt == harness.clock.now.addingTimeInterval(300))
    }

    @Test func deletionDistinguishesPlainPausedFromEnabledAndPending() throws {
        let harness = try makeHarness()
        let paused = try harness.center.add(ReminderDraft(name: "普通", intervalMinutes: 20))
        let enabled = try harness.center.add(ReminderDraft(name: "启用", intervalMinutes: 30))
        #expect(harness.center.deletionPolicy(for: paused.id) == .immediate)
        try harness.center.enable(enabled.id)
        #expect(harness.center.deletionPolicy(for: enabled.id) == .requiresConfirmation)
        harness.clock.advance(by: 1_800)
        harness.scheduler.fireDue()
        #expect(harness.center.deletionPolicy(for: enabled.id) == .requiresConfirmation)

        try harness.center.delete(enabled.id, confirmed: true)
        #expect(harness.center.pendingReminder == nil)
        #expect(harness.center.activeReminder == nil)
        #expect(harness.scheduler.pendingCount == 0)
        try harness.center.delete(paused.id, confirmed: false)
        #expect(harness.center.reminders.isEmpty)
    }

    @Test func sleepSuspendsCountdownAndWakeOverduePresentsAtMostOnce() throws {
        let harness = try makeHarness()
        let reminder = try harness.center.add(ReminderDraft(name: "远眺", intervalMinutes: 5))
        try harness.center.enable(reminder.id)
        harness.clock.advance(by: 120)
        harness.center.willSleep()
        harness.clock.advance(by: 3_600)

        harness.center.didWake()
        harness.center.didWake()

        #expect(harness.center.pendingReminder?.id == reminder.id)
        #expect(harness.center.presentationCount == 1)
    }

    @Test func restorationKeepsPausedRemainderActiveDeadlineAndPendingState() throws {
        let storage = InMemoryReminderPersistence()
        let first = try makeHarness(storage: storage)
        let paused = try first.center.add(ReminderDraft(name: "暂停", intervalMinutes: 20))
        try first.center.enable(paused.id)
        first.clock.advance(by: 200)
        try first.center.pause(paused.id)
        let active = try first.center.add(ReminderDraft(name: "运行", intervalMinutes: 30))
        try first.center.enable(active.id)

        let restored = ReminderCenter(clock: first.clock, scheduler: first.scheduler, persistence: storage)
        #expect(restored.reminder(id: paused.id)?.remainingSeconds == 1_000)
        #expect(restored.activeReminder?.id == active.id)
        #expect(restored.activeReminder?.nextTriggerAt == first.clock.now.addingTimeInterval(1_800))

        first.clock.advance(by: 1_800)
        first.scheduler.fireDue()
        let pendingRestore = ReminderCenter(clock: first.clock, scheduler: first.scheduler, persistence: storage)
        #expect(pendingRestore.pendingReminder?.id == active.id)
    }

    private func makeHarness(
        storage: InMemoryReminderPersistence = InMemoryReminderPersistence()
    ) throws -> ReminderHarness {
        let clock = TestReminderClock(now: Date(timeIntervalSince1970: 1_000_000))
        let scheduler = TestReminderScheduler(clock: clock)
        return ReminderHarness(
            center: ReminderCenter(clock: clock, scheduler: scheduler, persistence: storage),
            clock: clock,
            scheduler: scheduler
        )
    }
}

@MainActor private struct ReminderHarness {
    let center: ReminderCenter
    let clock: TestReminderClock
    let scheduler: TestReminderScheduler
}

@MainActor final class TestReminderClock: ReminderClock {
    var now: Date
    init(now: Date) { self.now = now }
    func advance(by seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
}

@MainActor final class TestReminderScheduler: ReminderScheduling {
    private final class Entry: ReminderScheduledTask {
        let date: Date
        let action: @MainActor () -> Void
        var cancelled = false
        init(date: Date, action: @escaping @MainActor () -> Void) {
            self.date = date
            self.action = action
        }
        func cancel() { cancelled = true }
    }

    private let clock: TestReminderClock
    private var entries: [Entry] = []
    var pendingCount: Int { entries.count(where: { !$0.cancelled }) }
    init(clock: TestReminderClock) { self.clock = clock }

    func schedule(at date: Date, action: @escaping @MainActor () -> Void) -> any ReminderScheduledTask {
        let entry = Entry(date: date, action: action)
        entries.append(entry)
        return entry
    }

    func fireDue() {
        let due = entries.filter { !$0.cancelled && $0.date <= clock.now }
        due.forEach { $0.cancelled = true; $0.action() }
    }

    func fireAllIncludingCancelled() { entries.forEach { $0.action() } }
}
