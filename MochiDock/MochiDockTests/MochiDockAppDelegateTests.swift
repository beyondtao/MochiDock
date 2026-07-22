import AppKit
import Combine
import Testing
@testable import MochiDock

@MainActor
struct MochiDockAppDelegateTests {
    @Test func restoredSizeIsTheMenuSelectionSourceBeforeThePanelIsCreated() {
        let store = InMemoryPetPreferences(
            values: [PetPreferenceKey.displaySize: PetDisplaySize.extraLarge.rawValue]
        )
        let model = PetInteractionModel(preferences: store)
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)

        #expect(panelController.panel == nil)
        #expect(appDelegate.displaySize == .extraLarge)

        appDelegate.showPet()
        defer { panelController.panel?.close() }
        #expect(panelController.panel?.frame.size == NSSize(width: 240, height: 240))
        #expect(appDelegate.displaySize == .extraLarge)
    }

    @Test func visibilityTitleAndToggleFollowThePanelState() {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)
        defer { panelController.panel?.close() }
        let toggleAction: (MochiDockAppDelegate) -> () -> Void = MochiDockAppDelegate.togglePetVisibility
        requireObservable(appDelegate)

        #expect(localized(appDelegate.petVisibilityActionTitle) == localizedKey("Show Pet"))

        appDelegate.showPet()
        #expect(localized(appDelegate.petVisibilityActionTitle) == localizedKey("Hide Pet"))

        appDelegate.togglePetVisibility()
        #expect(localized(appDelegate.petVisibilityActionTitle) == localizedKey("Show Pet"))

        appDelegate.togglePetVisibility()
        #expect(localized(appDelegate.petVisibilityActionTitle) == localizedKey("Hide Pet"))
        _ = toggleAction
    }

    @Test func menuContentObservesTheAppDelegate() {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)

        _ = MochiDockMenuContent(appDelegate: appDelegate)
    }

    @Test func statusMenuContainsOnlyVisibilitySettingsAndQuit() {
        #expect(MochiDockMenuAction.allCases == [.petVisibility, .settings, .quit])
    }

    @Test func settingsPreviewUsesTwoFocusedSectionsAndAComfortableSplitWindow() throws {
        #expect(SettingsSection.allCases == [.pet, .application])

        let appDelegate = makeAppDelegate(loginItem: TestLoginItemService(status: .notRegistered))
        let window = try #require(appDelegate.settingsWindowController.window)

        #expect(window.contentRect(forFrameRect: window.frame).size == SettingsWindowController.contentSize)
        #expect(window.contentMinSize == SettingsWindowController.contentSize)
    }

    @Test func settingsWindowIsSingleReusableAndIndependentFromThePet() throws {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)
        appDelegate.showPet()
        defer {
            appDelegate.settingsWindowController.window?.close()
            panelController.panel?.close()
        }

        appDelegate.openSettings()
        let firstWindow = try #require(appDelegate.settingsWindowController.window)
        #expect(firstWindow.isVisible)
        #expect(panelController.isPetVisible)

        appDelegate.openSettings()
        let repeatedWindow = try #require(appDelegate.settingsWindowController.window)
        #expect(firstWindow === repeatedWindow)

        firstWindow.close()
        #expect(!firstWindow.isVisible)
        #expect(panelController.isPetVisible)
        #expect(!appDelegate.applicationShouldTerminateAfterLastWindowClosed(.shared))

        appDelegate.openSettings()
        let reopenedWindow = try #require(appDelegate.settingsWindowController.window)
        #expect(firstWindow === reopenedWindow)
        #expect(reopenedWindow.isVisible)
        #expect(panelController.isPetVisible)
    }

    @Test func reopenedSettingsMovesTheSameWindowToTheActiveSpaceOnly() throws {
        let appDelegate = makeAppDelegate(
            loginItem: TestLoginItemService(status: .notRegistered)
        )

        appDelegate.openSettings()
        let window = try #require(appDelegate.settingsWindowController.window)

        #expect(window.collectionBehavior.contains(.moveToActiveSpace))
        #expect(!window.collectionBehavior.contains(.canJoinAllSpaces))

        window.close()
        appDelegate.openSettings()

        #expect(window === appDelegate.settingsWindowController.window)
        window.close()
    }

    @Test func openingSettingsActivatesTheApplicationAndKeepsOneWindow() throws {
        let activator = TestApplicationActivator()
        let appDelegate = makeAppDelegate(
            loginItem: TestLoginItemService(status: .notRegistered),
            applicationActivator: activator
        )

        appDelegate.openSettings()
        let firstWindow = try #require(appDelegate.settingsWindowController.window)
        appDelegate.openSettings()

        #expect(activator.activationCount == 2)
        #expect(firstWindow === appDelegate.settingsWindowController.window)
        firstWindow.close()
    }

    @Test func reopenedSettingsReadsTheRealCurrentSize() throws {
        let store = InMemoryPetPreferences()
        let model = PetInteractionModel(preferences: store)
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)

        appDelegate.openSettings()
        let window = try #require(appDelegate.settingsWindowController.window)
        appDelegate.selectDisplaySize(.jumbo)
        window.close()
        appDelegate.openSettings()

        #expect(appDelegate.displaySize == .jumbo)
        #expect(store.values[PetPreferenceKey.displaySize] == PetDisplaySize.jumbo.rawValue)
        #expect(window === appDelegate.settingsWindowController.window)
        window.close()
    }

    @Test func selectingSizePublishesTheRealSelectionToSettings() {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)
        var updateCount = 0
        let observation = appDelegate.objectWillChange.sink { updateCount += 1 }

        appDelegate.selectDisplaySize(.extraLarge)

        #expect(appDelegate.displaySize == .extraLarge)
        #expect(updateCount == 1)
        _ = observation
    }

    @Test func proximityMenuStateRestoresAndPersistsThroughTheController() {
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.proximityResponseEnabled: "false"
        ])
        let model = PetInteractionModel(preferences: store)
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)

        #expect(!appDelegate.isProximityResponseEnabled)
        appDelegate.setProximityResponseEnabled(true)

        #expect(appDelegate.isProximityResponseEnabled)
        #expect(store.values[PetPreferenceKey.proximityResponseEnabled] == "true")
    }

    @Test func loginItemMenuAlwaysReflectsActualStatusAfterRequests() {
        let loginItem = TestLoginItemService(status: .notRegistered)
        let appDelegate = makeAppDelegate(loginItem: loginItem)

        #expect(!appDelegate.isLoginItemEnabled)
        loginItem.status = .requiresApproval
        appDelegate.setLoginItemEnabled(true)

        #expect(!appDelegate.isLoginItemEnabled)
        #expect(localized(appDelegate.loginItemOutcome!) == localizedKey(
            "Allow MochiDock in System Settings > General > Login Items."
        ))
    }

    @Test func loginItemErrorsDoNotChangeTheDisplayedActualStatus() {
        let loginItem = TestLoginItemService(status: .notRegistered)
        loginItem.error = TestAppLoginItemError.failed
        let appDelegate = makeAppDelegate(loginItem: loginItem)

        appDelegate.setLoginItemEnabled(true)

        #expect(!appDelegate.isLoginItemEnabled)
        #expect(localized(appDelegate.loginItemOutcome!) == localizedKey(
            "Couldn’t update Start at Login."
        ))
    }

    @Test func loginItemNotFoundHasAnUnderstandableOutcome() {
        let loginItem = TestLoginItemService(status: .notFound)
        let appDelegate = makeAppDelegate(loginItem: loginItem)

        appDelegate.refreshLoginItemStatus()

        #expect(!appDelegate.isLoginItemEnabled)
        #expect(localized(appDelegate.loginItemOutcome!) == localizedKey(
            "MochiDock’s login item is unavailable."
        ))
    }

    private func makeAppDelegate(
        loginItem: TestLoginItemService,
        applicationActivator: (any ApplicationActivating)? = nil
    ) -> MochiDockAppDelegate {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        return MochiDockAppDelegate(
            model: model,
            panelController: PetPanelController(model: model),
            loginItemService: loginItem,
            applicationActivator: applicationActivator ?? TestApplicationActivator()
        )
    }

    private func requireObservable<T: ObservableObject>(_ value: T) {}

    private func localized(_ resource: LocalizedStringResource) -> String {
        String(localized: resource)
    }

    private func localizedKey(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }
}

@MainActor
private final class TestLoginItemService: LoginItemServicing {
    var status: LoginItemStatus
    var error: (any Error)?

    init(status: LoginItemStatus) {
        self.status = status
    }

    func setEnabled(_ enabled: Bool) throws {
        if let error { throw error }
    }
}

private enum TestAppLoginItemError: Error {
    case failed
}

@MainActor
private final class TestApplicationActivator: ApplicationActivating {
    private(set) var activationCount = 0

    func activate() {
        activationCount += 1
    }
}
