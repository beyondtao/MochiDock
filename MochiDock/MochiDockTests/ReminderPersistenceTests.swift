import Foundation
import Testing
@testable import MochiDock

@MainActor struct ReminderPersistenceTests {
    @Test func payloadRoundTripsOnlyTheApprovedReminderFields() throws {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 2_000)
        let payload = ReminderPersistencePayload(reminders: [
            ReminderRecord(
                id: id,
                name: "喝水",
                intervalMinutes: 45,
                state: .enabled,
                remainingSeconds: nil,
                nextTriggerAt: date
            )
        ], pendingReminderID: nil)
        let encoded = try UserDefaultsReminderPersistence.encode(payload)
        let decoded = try UserDefaultsReminderPersistence.decode(encoded)

        #expect(decoded == payload)
        #expect(!encoded.contains("history"))
        #expect(!encoded.contains("statistics"))
        #expect(!encoded.contains("streak"))
        #expect(!encoded.contains("growth"))
    }
}

final class InMemoryReminderPersistence: ReminderPersisting {
    var payload = ReminderPersistencePayload(reminders: [], pendingReminderID: nil)
    func load() -> ReminderPersistencePayload { payload }
    func save(_ payload: ReminderPersistencePayload) { self.payload = payload }
}
