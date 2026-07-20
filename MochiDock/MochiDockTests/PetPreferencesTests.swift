import Foundation
import Testing
@testable import MochiDock

@MainActor
struct PetPreferencesTests {
    @Test func userDefaultsAdapterReadsAndWritesAnIsolatedSuite() throws {
        let suiteName = "MochiDockTests.PetPreferences.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsPetPreferences(userDefaults: userDefaults)

        store.set(PetDisplaySize.large.rawValue, forKey: PetPreferenceKey.displaySize)

        #expect(store.string(forKey: PetPreferenceKey.displaySize) == PetDisplaySize.large.rawValue)
    }

    @Test func missingStoredSizeRestoresMedium() {
        let store = InMemoryPetPreferences()

        let model = PetInteractionModel(preferences: store)

        #expect(model.displaySize == .medium)
    }

    @Test(arguments: PetDisplaySize.allCases)
    func everySizePersistsAndRestoresInANewModel(size: PetDisplaySize) {
        let store = InMemoryPetPreferences()
        let firstModel = PetInteractionModel(preferences: store)

        firstModel.selectDisplaySize(size)
        let restoredModel = PetInteractionModel(preferences: store)

        #expect(restoredModel.displaySize == size)
    }

    @Test(arguments: ["", "120", "Medium", "obsolete-size"])
    func invalidStoredSizeFallsBackToMedium(storedValue: String) {
        let store = InMemoryPetPreferences(values: [PetPreferenceKey.displaySize: storedValue])

        let model = PetInteractionModel(preferences: store)

        #expect(model.displaySize == .medium)
    }

    @Test func selectingSizeWritesStableIdentifierImmediately() {
        let store = InMemoryPetPreferences()
        let model = PetInteractionModel(preferences: store)

        model.selectDisplaySize(.extraLarge)

        #expect(store.values[PetPreferenceKey.displaySize] == PetDisplaySize.extraLarge.rawValue)
        #expect(store.writeCount == 1)
    }

    @Test func repeatedSelectionStillPersistsTheCurrentChoiceImmediately() {
        let store = InMemoryPetPreferences()
        let model = PetInteractionModel(preferences: store)

        model.selectDisplaySize(.medium)
        model.selectDisplaySize(.medium)

        #expect(store.values[PetPreferenceKey.displaySize] == PetDisplaySize.medium.rawValue)
        #expect(store.writeCount == 2)
    }

    @Test(arguments: [
        NSPoint(x: 480.5, y: 220.25),
        NSPoint(x: -1_340.75, y: -620.5),
    ])
    func positionRoundTripsPositiveAndNegativeCoordinates(origin: NSPoint) throws {
        let encoded = try #require(PetWindowPosition(origin: origin).encoded())

        let decoded = PetWindowPosition.decode(encoded)

        #expect(decoded?.origin == origin)
        #expect(encoded == "{\"version\":1,\"x\":\(origin.x),\"y\":\(origin.y)}")
    }

    @Test(arguments: [
        "",
        "not-json",
        "{}",
        "{\"version\":1,\"x\":12}",
        "{\"version\":2,\"x\":12,\"y\":34}",
        "{\"version\":1,\"x\":NaN,\"y\":34}",
        "{\"version\":1,\"x\":1e400,\"y\":34}",
    ])
    func invalidPositionPayloadsAreRejected(payload: String) {
        #expect(PetWindowPosition.decode(payload) == nil)
    }

    @Test func positionPreferenceUsesAStableCentralizedKey() {
        #expect(PetPreferenceKey.windowPosition == "pet.windowPosition")
    }
}

final class InMemoryPetPreferences: PetPreferencesStoring {
    var values: [String: String]
    private(set) var writeCount = 0

    init(values: [String: String] = [:]) {
        self.values = values
    }

    func string(forKey key: String) -> String? {
        values[key]
    }

    func set(_ value: String, forKey key: String) {
        values[key] = value
        writeCount += 1
    }
}
