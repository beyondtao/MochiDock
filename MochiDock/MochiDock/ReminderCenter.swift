import Foundation
import Observation

@MainActor
protocol ReminderClock: AnyObject {
    var now: Date { get }
}

@MainActor
final class SystemReminderClock: ReminderClock {
    var now: Date { Date() }
}

@MainActor
protocol ReminderScheduledTask: AnyObject {
    func cancel()
}

@MainActor
protocol ReminderScheduling: AnyObject {
    func schedule(
        at date: Date,
        action: @escaping @MainActor () -> Void
    ) -> any ReminderScheduledTask
}

@MainActor
final class DispatchReminderScheduler: ReminderScheduling {
    private final class Task: ReminderScheduledTask {
        let workItem: DispatchWorkItem
        init(_ workItem: DispatchWorkItem) { self.workItem = workItem }
        func cancel() { workItem.cancel() }
    }

    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    func schedule(
        at date: Date,
        action: @escaping @MainActor () -> Void
    ) -> any ReminderScheduledTask {
        let item = DispatchWorkItem { MainActor.assumeIsolated { action() } }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + max(0, date.timeIntervalSince(now())),
            execute: item
        )
        return Task(item)
    }
}

@MainActor
@Observable
final class ReminderCenter {
    private(set) var reminders: [ReminderRecord]
    private(set) var pendingReminderID: UUID?
    private(set) var statusMessage: String?
    private(set) var presentationCount = 0

    var onReminderPending: ((ReminderRecord) -> Void)?
    var onPendingResolved: (() -> Void)?

    private let clock: any ReminderClock
    private let scheduler: any ReminderScheduling
    private let persistence: any ReminderPersisting
    private let localizedText: ReminderLocalizedText
    private var scheduledTask: (any ReminderScheduledTask)?
    private var scheduleGeneration = 0

    var activeReminder: ReminderRecord? {
        reminders.first(where: { $0.state == .enabled })
    }

    var pendingReminder: ReminderRecord? {
        pendingReminderID.flatMap(reminder(id:))
    }

    init(
        clock: any ReminderClock,
        scheduler: any ReminderScheduling,
        persistence: any ReminderPersisting,
        localizedText: ReminderLocalizedText
    ) {
        self.clock = clock
        self.scheduler = scheduler
        self.persistence = persistence
        self.localizedText = localizedText
        let payload = persistence.load()
        self.reminders = Self.normalized(payload.reminders)
        self.pendingReminderID = payload.pendingReminderID.flatMap { id in
            reminders.contains(where: { $0.id == id && $0.state == .enabled }) ? id : nil
        }
        restoreSchedule()
    }

    convenience init(
        clock: any ReminderClock,
        scheduler: any ReminderScheduling,
        persistence: any ReminderPersisting
    ) {
        self.init(
            clock: clock,
            scheduler: scheduler,
            persistence: persistence,
            localizedText: ReminderLocalizedText()
        )
    }

    convenience init() {
        let clock = SystemReminderClock()
        self.init(
            clock: clock,
            scheduler: DispatchReminderScheduler(now: { clock.now }),
            persistence: UserDefaultsReminderPersistence()
        )
    }

    func reminder(id: UUID) -> ReminderRecord? {
        reminders.first(where: { $0.id == id })
    }

    @discardableResult
    func add(_ draft: ReminderDraft) throws -> ReminderRecord {
        guard let draft = draft.validated() else { throw ReminderCenterError.invalidDraft }
        let reminder = ReminderRecord(
            id: UUID(),
            name: draft.name,
            intervalMinutes: draft.intervalMinutes,
            state: .paused,
            remainingSeconds: TimeInterval(draft.intervalMinutes * 60),
            nextTriggerAt: nil
        )
        reminders.append(reminder)
        persist()
        return reminder
    }

    func enable(_ id: UUID) throws {
        guard let targetIndex = index(of: id) else { throw ReminderCenterError.reminderNotFound }
        let previous = activeReminder
        if let previous, previous.id != id, let previousIndex = index(of: previous.id) {
            pauseRecord(at: previousIndex)
            if pendingReminderID != nil { onPendingResolved?() }
            pendingReminderID = nil
        }
        let remaining = reminders[targetIndex].remainingSeconds ?? reminders[targetIndex].intervalSeconds
        reminders[targetIndex].state = .enabled
        reminders[targetIndex].remainingSeconds = nil
        reminders[targetIndex].nextTriggerAt = clock.now.addingTimeInterval(max(0, remaining))
        if let previous, previous.id != id {
            statusMessage = localizedText.switched(
                from: previous.name,
                to: reminders[targetIndex].name
            )
        } else {
            statusMessage = nil
        }
        scheduleActive()
        persist()
    }

    func pause(_ id: UUID) throws {
        guard let index = index(of: id) else { throw ReminderCenterError.reminderNotFound }
        guard reminders[index].state == .enabled else { return }
        pauseRecord(at: index)
        if pendingReminderID == id { pendingReminderID = nil; onPendingResolved?() }
        cancelSchedule()
        persist()
    }

    func edit(_ id: UUID, draft: ReminderDraft) throws {
        guard let draft = draft.validated() else { throw ReminderCenterError.invalidDraft }
        guard let index = index(of: id) else { throw ReminderCenterError.reminderNotFound }
        let isEnabled = reminders[index].state == .enabled
        reminders[index].name = draft.name
        reminders[index].intervalMinutes = draft.intervalMinutes
        if isEnabled {
            if pendingReminderID == id { onPendingResolved?() }
            pendingReminderID = nil
            reminders[index].remainingSeconds = nil
            reminders[index].nextTriggerAt = clock.now.addingTimeInterval(reminders[index].intervalSeconds)
            scheduleActive()
        } else {
            reminders[index].remainingSeconds = reminders[index].intervalSeconds
        }
        persist()
    }

    func deletionPolicy(for id: UUID) -> ReminderDeletionPolicy? {
        guard let reminder = reminder(id: id) else { return nil }
        return reminder.state == .enabled || pendingReminderID == id
            ? .requiresConfirmation
            : .immediate
    }

    func delete(_ id: UUID, confirmed: Bool) throws {
        guard let policy = deletionPolicy(for: id), let index = index(of: id) else {
            throw ReminderCenterError.reminderNotFound
        }
        if policy == .requiresConfirmation && !confirmed {
            throw ReminderCenterError.confirmationRequired
        }
        if reminders[index].state == .enabled { cancelSchedule() }
        reminders.remove(at: index)
        if pendingReminderID == id { pendingReminderID = nil; onPendingResolved?() }
        persist()
    }

    func completePending() throws {
        guard let id = pendingReminderID, let index = index(of: id) else {
            throw ReminderCenterError.noPendingReminder
        }
        pendingReminderID = nil
        onPendingResolved?()
        reminders[index].nextTriggerAt = clock.now.addingTimeInterval(reminders[index].intervalSeconds)
        scheduleActive()
        persist()
    }

    func snoozePending() throws {
        guard let id = pendingReminderID, let index = index(of: id) else {
            throw ReminderCenterError.noPendingReminder
        }
        pendingReminderID = nil
        onPendingResolved?()
        reminders[index].nextTriggerAt = clock.now.addingTimeInterval(600)
        scheduleActive()
        persist()
    }

    func willSleep() {
        cancelSchedule()
    }

    func didWake() {
        guard pendingReminderID == nil, let active = activeReminder else { return }
        if let date = active.nextTriggerAt, date <= clock.now {
            markDue(id: active.id, expectedDate: date)
        } else {
            scheduleActive()
        }
    }

    func remainingSeconds(for reminder: ReminderRecord) -> TimeInterval {
        if reminder.state == .paused { return max(0, reminder.remainingSeconds ?? reminder.intervalSeconds) }
        guard pendingReminderID != reminder.id, let date = reminder.nextTriggerAt else { return 0 }
        return max(0, date.timeIntervalSince(clock.now))
    }

    private func restoreSchedule() {
        guard pendingReminderID == nil, let active = activeReminder else { return }
        guard let date = active.nextTriggerAt else {
            if let index = index(of: active.id) {
                reminders[index].nextTriggerAt = clock.now.addingTimeInterval(active.intervalSeconds)
                persist()
                scheduleActive()
            }
            return
        }
        if date <= clock.now {
            markDue(id: active.id, expectedDate: date)
        } else {
            scheduleActive()
        }
    }

    private func scheduleActive() {
        cancelSchedule()
        guard pendingReminderID == nil,
              let active = activeReminder,
              let date = active.nextTriggerAt else { return }
        scheduleGeneration += 1
        let generation = scheduleGeneration
        scheduledTask = scheduler.schedule(at: date) { [weak self] in
            guard let self, scheduleGeneration == generation else { return }
            scheduledTask = nil
            markDue(id: active.id, expectedDate: date)
        }
    }

    private func markDue(id: UUID, expectedDate: Date) {
        guard pendingReminderID == nil,
              let index = index(of: id),
              reminders[index].state == .enabled,
              reminders[index].nextTriggerAt == expectedDate,
              expectedDate <= clock.now else { return }
        cancelSchedule()
        reminders[index].nextTriggerAt = nil
        pendingReminderID = id
        presentationCount += 1
        persist()
        onReminderPending?(reminders[index])
    }

    private func pauseRecord(at index: Int) {
        let remaining = reminders[index].nextTriggerAt.map { max(0, $0.timeIntervalSince(clock.now)) }
            ?? reminders[index].remainingSeconds
            ?? reminders[index].intervalSeconds
        reminders[index].state = .paused
        reminders[index].remainingSeconds = remaining
        reminders[index].nextTriggerAt = nil
    }

    private func cancelSchedule() {
        scheduleGeneration += 1
        scheduledTask?.cancel()
        scheduledTask = nil
    }

    private func index(of id: UUID) -> Int? {
        reminders.firstIndex(where: { $0.id == id })
    }

    private func persist() {
        persistence.save(ReminderPersistencePayload(
            reminders: reminders,
            pendingReminderID: pendingReminderID
        ))
    }

    private static func normalized(_ records: [ReminderRecord]) -> [ReminderRecord] {
        var foundEnabled = false
        return records.map { record in
            var record = record
            guard record.state == .enabled else { return record }
            if foundEnabled {
                record.state = .paused
                record.remainingSeconds = record.remainingSeconds ?? record.intervalSeconds
                record.nextTriggerAt = nil
            } else {
                foundEnabled = true
            }
            return record
        }
    }
}
