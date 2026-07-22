import AppKit
import Testing
@testable import MochiDock

@MainActor
struct PetSizeSliderTests {
    @Test func unifiedPointerSurfaceDragsFromSelectedStopAcrossMultipleStops() {
        let interaction = PetSizeSliderInteraction(trackWidth: 400)
        var selections: [PetDisplaySize] = []

        interaction.drag(
            from: interaction.point(for: .medium),
            through: [interaction.point(for: .large), interaction.point(for: .extraLarge)],
            onSelect: { selections.append($0) }
        )

        #expect(selections == [.medium, .large, .extraLarge])
    }

    @Test(arguments: [
        PetDisplaySize.small, .medium, .large, .extraLarge, .jumbo,
    ])
    func unifiedPointerSurfaceAcceptsDragStartingOnEveryStop(start: PetDisplaySize) {
        let interaction = PetSizeSliderInteraction(trackWidth: 400)
        var selections: [PetDisplaySize] = []

        interaction.drag(
            from: interaction.point(for: start),
            through: [interaction.point(for: .jumbo)],
            onSelect: { selections.append($0) }
        )

        #expect(selections.first == start)
        #expect(selections.last == .jumbo)
    }

    @Test func unifiedPointerSurfaceAcceptsDragStartingBetweenStops() {
        let interaction = PetSizeSliderInteraction(trackWidth: 400)
        var selections: [PetDisplaySize] = []

        interaction.drag(
            from: CGPoint(x: 160, y: interaction.hitRegion.midY),
            through: [CGPoint(x: 280, y: interaction.hitRegion.midY)],
            onSelect: { selections.append($0) }
        )

        #expect(selections == [.large, .extraLarge])
    }

    @Test func unifiedPointerHitRegionContainsTrackAndAllRenderedStops() {
        let interaction = PetSizeSliderInteraction(trackWidth: 400)

        #expect(interaction.hitRegion.height == PetSizeSliderInteraction.controlHeight)
        for size in PetSizeSliderModel.sizes {
            #expect(interaction.hitRegion.contains(interaction.point(for: size)))
        }
        #expect(interaction.hitRegion.contains(CGPoint(x: 50, y: interaction.hitRegion.midY)))
    }

    @Test func exposesExactlyTheFiveExistingSizesInBusinessOrder() {
        #expect(PetSizeSliderModel.sizes == [
            .small, .medium, .large, .extraLarge, .jumbo,
        ])
        #expect(PetSizeSliderModel.sizes.map(\.pointLength) == [80, 120, 160, 240, 320])
    }

    @Test(arguments: [
        (-1.0, PetDisplaySize.small),
        (0.0, .small),
        (0.12, .small),
        (0.13, .medium),
        (0.37, .medium),
        (0.38, .large),
        (0.62, .large),
        (0.63, .extraLarge),
        (0.87, .extraLarge),
        (0.88, .jumbo),
        (1.0, .jumbo),
        (2.0, .jumbo),
    ])
    func anyDragPositionSnapsToTheNearestStop(
        position: Double,
        expected: PetDisplaySize
    ) {
        #expect(PetSizeSliderModel.nearestSize(to: position) == expected)
    }

    @Test(arguments: [
        (0, PetDisplaySize.small),
        (1, .medium),
        (2, .large),
        (3, .extraLarge),
        (4, .jumbo),
    ])
    func clickingAStopSelectsItsMatchingSize(index: Int, expected: PetDisplaySize) {
        var selected: PetDisplaySize?

        PetSizeSliderModel.selectStop(index) { selected = $0 }

        #expect(selected == expected)
    }

    @Test func invalidStopsNeverSelectAnOutOfRangeValue() {
        var selections: [PetDisplaySize] = []

        PetSizeSliderModel.selectStop(-1) { selections.append($0) }
        PetSizeSliderModel.selectStop(PetSizeSliderModel.sizes.count) { selections.append($0) }

        #expect(selections.isEmpty)
    }

    @Test(arguments: [
        (PetDisplaySize.small, SizeSliderMove.left, PetDisplaySize.small),
        (.small, .right, .medium),
        (.medium, .right, .large),
        (.large, .left, .medium),
        (.extraLarge, .right, .jumbo),
        (.jumbo, .right, .jumbo),
    ])
    func arrowKeysMoveAtMostOneStop(
        current: PetDisplaySize,
        direction: SizeSliderMove,
        expected: PetDisplaySize
    ) {
        #expect(PetSizeSliderModel.movedSize(from: current, direction: direction) == expected)
    }

    @Test func committedStopsUseExistingPanelAndPersistencePathOnly() {
        let store = InMemoryPetPreferences()
        let model = PetInteractionModel(preferences: store)
        let panelController = PetPanelController(model: model)
        let appDelegate = MochiDockAppDelegate(model: model, panelController: panelController)
        appDelegate.showPet()
        defer { panelController.panel?.close() }

        for (index, expected) in PetSizeSliderModel.sizes.enumerated() {
            PetSizeSliderModel.selectStop(index, onSelect: appDelegate.selectDisplaySize)

            #expect(appDelegate.displaySize == expected)
            #expect(store.values[PetPreferenceKey.displaySize] == expected.rawValue)
            #expect(panelController.panel?.frame.size == NSSize(
                width: expected.pointLength,
                height: expected.pointLength
            ))
        }
    }
}
