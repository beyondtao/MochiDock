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

    @Test(arguments: [
        (PetDisplaySize.small, CGFloat(80)),
        (PetDisplaySize.medium, CGFloat(120)),
        (PetDisplaySize.large, CGFloat(160)),
    ])
    func selectingSizeUpdatesPanelDimensions(size: PetDisplaySize, pointLength: CGFloat) {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()

        controller.selectDisplaySize(size)

        #expect(controller.panel?.frame.size == NSSize(width: pointLength, height: pointLength))
    }

    @Test func selectingSizeKeepsPanelIdentityAndCenter() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        let originalPanel = controller.panel
        let originalCenter = NSPoint(x: originalPanel?.frame.midX ?? 0, y: originalPanel?.frame.midY ?? 0)

        controller.selectDisplaySize(.large)

        #expect(controller.panel === originalPanel)
        #expect(controller.panel?.frame.midX == originalCenter.x)
        #expect(controller.panel?.frame.midY == originalCenter.y)
    }

    @Test func repeatedSizeSelectionDoesNotCreateAnotherPanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        let originalPanel = controller.panel

        controller.selectDisplaySize(.small)
        controller.selectDisplaySize(.small)

        #expect(controller.panel === originalPanel)
    }
}
