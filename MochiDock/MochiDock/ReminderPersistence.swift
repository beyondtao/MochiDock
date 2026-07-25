import Foundation

struct ReminderPersistencePayload: Codable, Equatable {
    var reminders: [ReminderRecord]
    var pendingReminderID: UUID?
}

protocol ReminderPersisting: AnyObject {
    func load() -> ReminderPersistencePayload
    func save(_ payload: ReminderPersistencePayload)
}

final class VolatileReminderPersistence: ReminderPersisting {
    private var payload = ReminderPersistencePayload(reminders: [], pendingReminderID: nil)
    func load() -> ReminderPersistencePayload { payload }
    func save(_ payload: ReminderPersistencePayload) { self.payload = payload }
}

final class UserDefaultsReminderPersistence: ReminderPersisting {
    static let storageKey = "reminders.payload"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> ReminderPersistencePayload {
        guard let value = userDefaults.string(forKey: Self.storageKey),
              let payload = try? Self.decode(value) else {
            return ReminderPersistencePayload(reminders: [], pendingReminderID: nil)
        }
        return payload
    }

    func save(_ payload: ReminderPersistencePayload) {
        guard let value = try? Self.encode(payload) else { return }
        userDefaults.set(value, forKey: Self.storageKey)
    }

    static func encode(_ payload: ReminderPersistencePayload) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(payload)
        guard let value = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(payload, .init(codingPath: [], debugDescription: "UTF-8 encoding failed"))
        }
        return value
    }

    static func decode(_ value: String) throws -> ReminderPersistencePayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(ReminderPersistencePayload.self, from: Data(value.utf8))
    }
}
