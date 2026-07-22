import CoreGraphics
import Testing
@testable import MochiDock

struct PetEdgePlacementTests {
    private let policy = PetEdgePlacement()
    private let primary = CGRect(x: 0, y: 40, width: 1_440, height: 860)

    @Test func resolvesOnlyFullyVisibleFramesInsideTheLeftOrRightTriggerBand() {
        let left = CGRect(x: 20, y: 300, width: 120, height: 120)
        let right = CGRect(x: 1_296, y: 300, width: 120, height: 120)
        let center = CGRect(x: 600, y: 300, width: 120, height: 120)
        let partiallyOutside = CGRect(x: -1, y: 300, width: 120, height: 120)

        #expect(policy.eligibleEdge(for: left, visibleFrames: [primary]) == .left)
        #expect(policy.eligibleEdge(for: right, visibleFrames: [primary]) == .right)
        #expect(policy.eligibleEdge(for: center, visibleFrames: [primary]) == nil)
        #expect(policy.eligibleEdge(for: partiallyOutside, visibleFrames: [primary]) == nil)
        #expect(PetEdgePlacement.triggerBand == 24)
    }

    @Test func topAndBottomPlacementDoNotCountAsAnEdgeWithoutHorizontalEligibility() {
        let topCenter = CGRect(x: 600, y: 780, width: 120, height: 120)
        let bottomCenter = CGRect(x: 600, y: 40, width: 120, height: 120)

        #expect(policy.eligibleEdge(for: topCenter, visibleFrames: [primary]) == nil)
        #expect(policy.eligibleEdge(for: bottomCenter, visibleFrames: [primary]) == nil)
    }

    @Test func adjacentDisplaySeamsAreNotExternalEdgesAcrossThePanelsVerticalSpan() {
        let leftDisplay = CGRect(x: -1_280, y: 0, width: 1_280, height: 800)
        let frameAtPrimaryLeftSeam = CGRect(x: 0, y: 300, width: 120, height: 120)
        let frameAtLeftDisplayRightSeam = CGRect(x: -120, y: 300, width: 120, height: 120)

        #expect(policy.eligibleEdge(
            for: frameAtPrimaryLeftSeam,
            visibleFrames: [leftDisplay, primary]
        ) == nil)
        #expect(policy.eligibleEdge(
            for: frameAtLeftDisplayRightSeam,
            visibleFrames: [leftDisplay, primary]
        ) == nil)
    }

    @Test func aNeighborThatDoesNotOverlapThePanelsVerticalSpanDoesNotBlockTheOuterEdge() {
        let upperLeftDisplay = CGRect(x: -1_280, y: 500, width: 1_280, height: 800)
        let lowFrameAtPrimaryLeft = CGRect(x: 0, y: 100, width: 120, height: 120)

        #expect(policy.eligibleEdge(
            for: lowFrameAtPrimaryLeft,
            visibleFrames: [upperLeftDisplay, primary]
        ) == .left)
    }

    @Test func negativeCoordinateDisplaySupportsBothTrueOuterEdges() {
        let display = CGRect(x: -1_600, y: -300, width: 1_200, height: 800)
        let left = CGRect(x: -1_590, y: -100, width: 160, height: 160)
        let right = CGRect(x: -584, y: -100, width: 160, height: 160)

        #expect(policy.eligibleEdge(for: left, visibleFrames: [display]) == .left)
        #expect(policy.eligibleEdge(for: right, visibleFrames: [display]) == .right)
    }

    @Test(arguments: PetDisplaySize.allCases)
    func peekFrameKeepsTheRequiredDiscoverableWidthForEverySize(size: PetDisplaySize) {
        let length = size.pointLength
        let fullLeft = CGRect(x: primary.minX, y: 300, width: length, height: length)
        let fullRight = CGRect(x: primary.maxX - length, y: 300, width: length, height: length)
        let visibleWidth = max(length * 0.35, 32)

        let leftPeek = policy.peekFrame(for: fullLeft, edge: .left, visibleFrame: primary)
        let rightPeek = policy.peekFrame(for: fullRight, edge: .right, visibleFrame: primary)

        #expect(leftPeek == CGRect(
            x: primary.minX - (length - visibleWidth),
            y: fullLeft.minY,
            width: length,
            height: length
        ))
        #expect(rightPeek == CGRect(
            x: primary.maxX - visibleWidth,
            y: fullRight.minY,
            width: length,
            height: length
        ))
        #expect(policy.fullFrame(from: leftPeek, restoring: fullLeft) == fullLeft)
        #expect(policy.fullFrame(from: rightPeek, restoring: fullRight) == fullRight)
    }
}
