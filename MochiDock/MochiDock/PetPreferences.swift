import CoreGraphics
import Foundation

protocol PetPreferencesStoring: AnyObject {
    func string(forKey key: String) -> String?
    func set(_ value: String, forKey key: String)
}

final class UserDefaultsPetPreferences: PetPreferencesStoring {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: key)
    }

    func set(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
}

enum PetPreferenceKey {
    static let displaySize = "pet.displaySize"
    static let windowPosition = "pet.windowPosition"
}

struct PetWindowPosition: Equatable {
    static let currentVersion = 1

    let origin: CGPoint

    init(origin: CGPoint) {
        self.origin = origin
    }

    func encoded() -> String? {
        guard origin.x.isFinite, origin.y.isFinite else { return nil }
        let payload = Payload(version: Self.currentVersion, x: origin.x, y: origin.y)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decode(_ value: String) -> PetWindowPosition? {
        guard let data = value.data(using: .utf8),
              let payload = try? JSONDecoder().decode(Payload.self, from: data),
              payload.version == currentVersion,
              payload.x.isFinite,
              payload.y.isFinite else {
            return nil
        }
        return PetWindowPosition(origin: CGPoint(x: payload.x, y: payload.y))
    }

    private struct Payload: Codable {
        let version: Int
        let x: CGFloat
        let y: CGFloat
    }
}
