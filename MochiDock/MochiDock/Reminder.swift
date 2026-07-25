import Foundation

enum ReminderState: String, Codable, Equatable {
    case paused
    case enabled
}

struct ReminderRecord: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var intervalMinutes: Int
    var state: ReminderState
    var remainingSeconds: TimeInterval?
    var nextTriggerAt: Date?

    var intervalSeconds: TimeInterval { TimeInterval(intervalMinutes * 60) }
}

struct ReminderDraft: Equatable {
    static let quickIntervals = [20, 30, 45, 60]

    var name = ""
    var intervalMinutes = 45

    func validated() -> ReminderDraft? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.count <= 30,
              (5...240).contains(intervalMinutes),
              intervalMinutes.isMultiple(of: 5) else {
            return nil
        }
        return ReminderDraft(name: trimmed, intervalMinutes: intervalMinutes)
    }
}

enum ReminderDeletionPolicy: Equatable {
    case immediate
    case requiresConfirmation
}

enum ReminderCenterError: Error, Equatable {
    case invalidDraft
    case reminderNotFound
    case confirmationRequired
    case noPendingReminder
}
