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

    @Test(arguments: [
        (PetDisplaySize.small, "Small — 80", "小 — 80"),
        (PetDisplaySize.medium, "Medium — 120", "中 — 120"),
        (PetDisplaySize.large, "Large — 160", "大 — 160"),
        (PetDisplaySize.extraLarge, "Extra Large — 240", "超大 — 240"),
        (PetDisplaySize.jumbo, "Jumbo — 320", "特大 — 320"),
    ])
    func sizeMenuTitlesAreLocalizedWithoutChangingStableValues(
        size: PetDisplaySize,
        english: String,
        simplifiedChinese: String
    ) {
        #expect(localized(size.menuTitle) == localizedKey(english))
        #expect(localizedKey(english, localization: "zh-Hans") == simplifiedChinese)
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

    @Test(arguments: PetDisplaySize.allCases)
    func everyVisualStateMapsToAStableResourceForEverySize(size: PetDisplaySize) {
        let suffix = Int(size.pointLength)

        #expect(size.resourceName(for: .idle) == "RedPandaProneV04_\(suffix)")
        #expect(size.resourceName(for: .halfBlink) == "RedPandaProneHalfBlinkV04_\(suffix)")
        #expect(size.resourceName(for: .fullBlink) == "RedPandaProneFullBlinkV04_\(suffix)")
        #expect(size.resourceName(for: .happy) == "RedPandaProneHappyV04_\(suffix)")
        #expect(size.resourceName(for: .attentionBase) == "RedPandaProneAttentionBaseV04_\(suffix)")
        #expect(size.resourceName(for: .attentionTail) == "RedPandaProneAttentionTailV04_\(suffix)")
    }

    @Test(arguments: PetDisplaySize.allCases)
    func everyRuntimeVisualResourceLoadsWithExpectedPixelsAndAlpha(size: PetDisplaySize) throws {
        for visualState in PetVisualState.allCases {
            let image = try #require(NSImage(named: size.resourceName(for: visualState)))
            let cgImage = try #require(
                image.cgImage(forProposedRect: nil, context: nil, hints: nil)
            )

            #expect(cgImage.width == Int(size.pointLength))
            #expect(cgImage.height == Int(size.pointLength))
            #expect(cgImage.alphaInfo != .none)
            #expect(cgImage.alphaInfo != .noneSkipFirst)
            #expect(cgImage.alphaInfo != .noneSkipLast)
        }
    }

    private func localized(_ resource: LocalizedStringResource) -> String {
        String(localized: resource)
    }

    private func localizedKey(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }

    private func localizedKey(_ key: String, localization: String) -> String? {
        guard
            let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return nil }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
