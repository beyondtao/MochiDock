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

        #expect(appDelegate.petVisibilityActionTitle == "Show Pet")

        appDelegate.showPet()
        #expect(appDelegate.petVisibilityActionTitle == "Hide Pet")

        appDelegate.togglePetVisibility()
        #expect(appDelegate.petVisibilityActionTitle == "Show Pet")

        appDelegate.togglePetVisibility()
        #expect(appDelegate.petVisibilityActionTitle == "Hide Pet")
        _ = toggleAction
    }

    @Test func menuContentObservesTheAppDelegate() {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)

        _ = MochiDockMenuContent(appDelegate: appDelegate)
    }

    private func requireObservable<T: ObservableObject>(_ value: T) {}
}
