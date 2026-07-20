import AppKit
import Testing
@testable import MochiDock

@MainActor
struct PetPanelControllerTests {
    @Test func repeatedShowAndSizeChangesKeepOnePlaybackSchedule() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler)
        let controller = PetPanelController(model: model)

        controller.showPet()
        defer { controller.panel?.close() }
        controller.showPet()
        controller.selectDisplaySize(.small)
        controller.selectDisplaySize(.large)

        #expect(scheduler.pendingCount == 1)
        #expect(scheduler.totalScheduled == 1)
    }

    @Test func hideStopsPlaybackAndShowRestartsOneSchedule() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler)
        let controller = PetPanelController(model: model)
        controller.showPet()
        defer { controller.panel?.close() }

        controller.hidePet()
        #expect(scheduler.pendingCount == 0)

        controller.showPet()
        controller.showPet()
        #expect(scheduler.pendingCount == 1)
    }

    @Test func showPetConfiguresTransparentMovablePanel() {
        let controller = PetPanelController(model: PetInteractionModel())

        controller.showPet()
        defer { controller.panel?.close() }

        let panel = controller.panel
        #expect(panel != nil)
        #expect(panel?.isOpaque == false)
        #expect(panel?.backgroundColor == .clear)
        #expect(panel?.styleMask.contains(.borderless) == true)
        #expect(panel?.isMovableByWindowBackground == true)
        #expect(panel?.level == .floating)
        #expect(panel?.collectionBehavior.contains(.canJoinAllSpaces) == true)
        #expect(panel?.collectionBehavior.contains(.moveToActiveSpace) == false)
        #expect(panel?.collectionBehavior.contains(.fullScreenAuxiliary) == false)
    }

    @Test func repeatedShowReusesTheSamePanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        defer { controller.panel?.close() }
        let firstPanel = controller.panel

        controller.showPet()

        #expect(controller.panel === firstPanel)
    }

    @Test func showAfterCloseRestoresTheSamePanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        defer { controller.panel?.close() }
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
        (PetDisplaySize.extraLarge, CGFloat(240)),
        (PetDisplaySize.jumbo, CGFloat(320)),
    ])
    func selectingSizeUpdatesPanelDimensions(size: PetDisplaySize, pointLength: CGFloat) {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        defer { controller.panel?.close() }

        controller.selectDisplaySize(size)

        #expect(controller.panel?.frame.size == NSSize(width: pointLength, height: pointLength))
    }

    @Test func selectingSizeKeepsPanelIdentityAndCenter() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        defer { controller.panel?.close() }
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
        defer { controller.panel?.close() }
        let originalPanel = controller.panel

        controller.selectDisplaySize(.small)
        controller.selectDisplaySize(.small)

        #expect(controller.panel === originalPanel)
    }

    @Test func hideMakesTheExistingPanelInvisibleWithoutReleasingIt() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel

        controller.hidePet()

        #expect(controller.panel === originalPanel)
        #expect(controller.panel?.isVisible == false)
    }

    @Test func showAfterHideRestoresTheSamePanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel
        controller.hidePet()

        controller.showPet()

        #expect(controller.panel === originalPanel)
        #expect(controller.panel?.isVisible == true)
    }

    @Test func hideAndShowPreserveSizeAndMood() {
        let model = PetInteractionModel()
        let controller = PetPanelController(model: model)
        controller.showPet()
        defer { controller.panel?.close() }
        controller.selectDisplaySize(.large)
        model.handleClick()

        controller.hidePet()
        controller.showPet()

        #expect(model.displaySize == .large)
        #expect(controller.panel?.frame.size == NSSize(width: 160, height: 160))
        #expect(model.mood == .happy)
    }

    @Test func repeatedHideAndShowReusesOnePanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel

        controller.hidePet()
        controller.hidePet()
        controller.showPet()
        controller.showPet()

        #expect(controller.panel === originalPanel)
        #expect(controller.panel?.isVisible == true)
    }

    @Test func visibilityTracksTheActualPanelState() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        defer { controller.panel?.close() }

        #expect(controller.isPetVisible == true)

        controller.hidePet()
        #expect(controller.isPetVisible == false)

        controller.showPet()
        #expect(controller.isPetVisible == true)
    }

    @Test func toggleHidesThenRestoresTheSamePanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel

        controller.togglePetVisibility()
        #expect(controller.isPetVisible == false)

        controller.togglePetVisibility()
        #expect(controller.isPetVisible == true)
        #expect(controller.panel === originalPanel)
    }

    @Test func togglePreservesSizeAndMood() {
        let model = PetInteractionModel()
        let controller = PetPanelController(model: model)
        controller.showPet()
        defer { controller.panel?.close() }
        controller.selectDisplaySize(.large)
        model.handleClick()

        controller.togglePetVisibility()
        controller.togglePetVisibility()

        #expect(controller.panel?.frame.size == NSSize(width: 160, height: 160))
        #expect(model.displaySize == .large)
        #expect(model.mood == .happy)
    }
}
