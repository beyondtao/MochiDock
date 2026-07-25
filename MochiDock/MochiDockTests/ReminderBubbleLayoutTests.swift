import CoreGraphics
import Testing
@testable import MochiDock

@MainActor struct ReminderBubbleLayoutTests {
    private let screen = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    private let layout = ReminderBubbleLayout()

    @Test func placesAboveWithTwelvePointGapWhenSpaceAllows() {
        let pet = CGRect(x: 400, y: 300, width: 120, height: 120)
        let result = layout.layout(
            petFrame: pet,
            requestedBubbleSize: CGSize(width: 220, height: 90),
            visibleFrame: screen
        )

        #expect(result.placement == .above)
        #expect(result.frame.minY == pet.maxY + 12)
        #expect(result.frame.midX == pet.midX)
        #expect(result.petFrame == pet)
    }

    @Test func flipsBelowWhenTheRequestedBubbleDoesNotFitAbove() {
        let pet = CGRect(x: 400, y: 700, width: 120, height: 80)
        let result = layout.layout(
            petFrame: pet,
            requestedBubbleSize: CGSize(width: 220, height: 100),
            visibleFrame: screen
        )

        #expect(result.placement == .below)
        #expect(result.frame.maxY == pet.minY - 12)
    }

    @Test func capsWidthAndClampsBothHorizontalEdges() {
        let left = layout.layout(
            petFrame: CGRect(x: 0, y: 300, width: 80, height: 80),
            requestedBubbleSize: CGSize(width: 500, height: 80),
            visibleFrame: screen
        )
        let right = layout.layout(
            petFrame: CGRect(x: 940, y: 300, width: 60, height: 60),
            requestedBubbleSize: CGSize(width: 500, height: 80),
            visibleFrame: screen
        )

        #expect(left.frame.width == 280)
        #expect(left.frame.minX == screen.minX)
        #expect(right.frame.maxX == screen.maxX)
    }

    @Test func dragSizeAndScreenChangesProduceFreshFramesWithoutMovingThePet() {
        let originalPet = CGRect(x: 300, y: 200, width: 80, height: 80)
        let draggedPet = CGRect(x: 560, y: 260, width: 80, height: 80)
        let resizedPet = CGRect(x: 520, y: 220, width: 160, height: 160)
        let original = layout.layout(
            petFrame: originalPet,
            requestedBubbleSize: CGSize(width: 240, height: 80),
            visibleFrame: screen
        )
        let dragged = layout.layout(
            petFrame: draggedPet,
            requestedBubbleSize: CGSize(width: 240, height: 80),
            visibleFrame: screen
        )
        let resized = layout.layout(
            petFrame: resizedPet,
            requestedBubbleSize: CGSize(width: 240, height: 80),
            visibleFrame: CGRect(x: 500, y: 0, width: 500, height: 800)
        )

        #expect(dragged.frame.midX - original.frame.midX == 260)
        #expect(resized.frame.minX == 500)
        #expect(original.petFrame == originalPet)
        #expect(dragged.petFrame == draggedPet)
        #expect(resized.petFrame == resizedPet)
    }

    @Test(arguments: [
        (CGRect(x: 100, y: 100, width: 160, height: 180), CGRect(x: 100, y: 120, width: 40, height: 40)),
        (CGRect(x: 100, y: 100, width: 160, height: 180), CGRect(x: 220, y: 120, width: 40, height: 40)),
        (CGRect(x: 100, y: 100, width: 160, height: 180), CGRect(x: 100, y: 240, width: 40, height: 30)),
    ])
    func narrowVisibleFramesKeepAboveAndBelowBubblesWithinHorizontalBounds(
        visibleFrame: CGRect,
        petFrame: CGRect
    ) {
        let result = layout.layout(
            petFrame: petFrame,
            requestedBubbleSize: CGSize(width: 280, height: 72),
            visibleFrame: visibleFrame
        )

        #expect(result.frame.width > 0)
        #expect(result.frame.width <= visibleFrame.width)
        #expect(result.frame.minX >= visibleFrame.minX)
        #expect(result.frame.maxX <= visibleFrame.maxX)
    }

    @Test func degenerateVisibleFrameProducesFiniteNonnegativeGeometry() {
        let result = layout.layout(
            petFrame: CGRect(x: 0, y: 0, width: 80, height: 80),
            requestedBubbleSize: CGSize(width: 280, height: 90),
            visibleFrame: CGRect(x: 40, y: 50, width: -10, height: -20)
        )

        #expect(result.frame.width >= 0)
        #expect(result.frame.height >= 0)
        #expect(result.frame.origin.x.isFinite)
        #expect(result.frame.origin.y.isFinite)
    }
}
