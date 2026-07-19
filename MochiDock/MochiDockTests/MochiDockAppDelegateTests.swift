import AppKit
import Combine
import Testing
@testable import MochiDock

@MainActor
struct MochiDockAppDelegateTests {
    @Test func visibilityTitleAndToggleFollowThePanelState() {
        let model = PetInteractionModel()
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
        let model = PetInteractionModel()
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)

        _ = MochiDockMenuContent(appDelegate: appDelegate)
    }

    private func requireObservable<T: ObservableObject>(_ value: T) {}
}
