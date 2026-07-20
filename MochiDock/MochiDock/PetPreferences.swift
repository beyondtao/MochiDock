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
}
