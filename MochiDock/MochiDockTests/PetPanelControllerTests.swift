import AppKit
import Testing
@testable import MochiDock

@MainActor
struct PetPanelControllerTests {
    @Test func showPetConfiguresTransparentMovablePanel() {
        let controller = PetPanelController(model: PetInteractionModel())

        controller.showPet()

        let panel = controller.panel
        #expect(panel != nil)
        #expect(panel?.isOpaque == false)
        #expect(panel?.backgroundColor == .clear)
        #expect(panel?.styleMask.contains(.borderless) == true)
        #expect(panel?.isMovableByWindowBackground == true)
        #expect(panel?.level == .floating)
        #expect(panel?.collectionBehavior.contains(.moveToActiveSpace) == true)
        #expect(panel?.collectionBehavior.contains(.fullScreenAuxiliary) == false)
    }

    @Test func repeatedShowReusesTheSamePanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        let firstPanel = controller.panel

        controller.showPet()

        #expect(controller.panel === firstPanel)
    }

    @Test func showAfterCloseRestoresTheSamePanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        let firstPanel = controller.panel
        firstPanel?.close()

        controller.showPet()

        #expect(controller.panel === firstPanel)
        #expect(controller.panel?.isVisible == true)
    }
}
