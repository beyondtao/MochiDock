import AppKit
import Testing
@testable import MochiDock

@MainActor
struct PetDisplaySizeTests {
    @Test func mediumIsTheDefaultSize() {
        let model = PetInteractionModel()

        #expect(model.displaySize == .medium)
    }

    @Test(arguments: [
        (PetDisplaySize.small, "RedPandaMaster80", CGFloat(80)),
        (PetDisplaySize.medium, "RedPandaMaster120", CGFloat(120)),
        (PetDisplaySize.large, "RedPandaMaster160", CGFloat(160)),
    ])
    func sizeMapsToResourceAndPointLength(
        size: PetDisplaySize,
        resourceName: String,
        pointLength: CGFloat
    ) {
        #expect(size.resourceName == resourceName)
        #expect(size.pointLength == pointLength)
    }

    @Test(arguments: PetDisplaySize.allCases)
    func selectingEachSizeUpdatesState(size: PetDisplaySize) {
        let model = PetInteractionModel()

        model.selectDisplaySize(size)

        #expect(model.displaySize == size)
    }

    @Test func selectingSizeDoesNotResetMood() {
        let model = PetInteractionModel()
        model.handleClick()

        model.selectDisplaySize(.large)

        #expect(model.mood == .happy)
    }

    @Test(arguments: PetDisplaySize.allCases)
    func resourceImageLoadsFromApplicationBundle(size: PetDisplaySize) {
        #expect(NSImage(named: size.resourceName) != nil)
    }
}
