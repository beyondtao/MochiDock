import AppKit
import Testing
@testable import MochiDock

@MainActor
struct PetDisplaySizeTests {
    @Test func mediumIsTheDefaultSize() {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())

        #expect(model.displaySize == .medium)
    }

    @Test(arguments: [
        (PetDisplaySize.small, "RedPandaProneV04_80", CGFloat(80)),
        (PetDisplaySize.medium, "RedPandaProneV04_120", CGFloat(120)),
        (PetDisplaySize.large, "RedPandaProneV04_160", CGFloat(160)),
        (PetDisplaySize.extraLarge, "RedPandaProneV04_240", CGFloat(240)),
        (PetDisplaySize.jumbo, "RedPandaProneV04_320", CGFloat(320)),
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
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())

        model.selectDisplaySize(size)

        #expect(model.displaySize == size)
    }

    @Test func selectingSizeDoesNotResetMood() {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        model.handleClick()

        model.selectDisplaySize(.large)

        #expect(model.mood == .happy)
    }

    @Test(arguments: PetDisplaySize.allCases)
    func resourceImageLoadsFromApplicationBundle(size: PetDisplaySize) {
        #expect(NSImage(named: size.resourceName) != nil)
    }

    @Test(arguments: [
        (PetDisplaySize.small, 80),
        (PetDisplaySize.medium, 120),
        (PetDisplaySize.large, 160),
        (PetDisplaySize.extraLarge, 240),
        (PetDisplaySize.jumbo, 320),
    ])
    func proneResourceHasExpectedPixelsAndAlpha(size: PetDisplaySize, pixels: Int) throws {
        let image = try #require(NSImage(named: size.resourceName))
        let cgImage = try #require(
            image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        )

        #expect(cgImage.width == pixels)
        #expect(cgImage.height == pixels)
        #expect(cgImage.alphaInfo != .none)
        #expect(cgImage.alphaInfo != .noneSkipFirst)
        #expect(cgImage.alphaInfo != .noneSkipLast)
    }
}
