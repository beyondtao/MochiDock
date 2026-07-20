import AppKit
import Testing
@testable import MochiDock

struct PetWindowPlacementTests {
    private let placement = PetWindowPlacement()

    @Test func frameAlreadyContainedInAnyVisibleFrameIsUnchanged() {
        let proposed = NSRect(x: -900, y: 120, width: 120, height: 120)
        let screens = [
            NSRect(x: 0, y: 0, width: 1_440, height: 860),
            NSRect(x: -1_280, y: -300, width: 1_280, height: 760),
        ]

        #expect(placement.safeFrame(for: proposed, visibleFrames: screens) == proposed)
    }

    @Test func emptyVisibleFramesDoNotAttemptCorrection() {
        #expect(placement.safeFrame(for: NSRect(x: 10, y: 20, width: 120, height: 120), visibleFrames: []) == nil)
    }

    @Test func fullyOffscreenFrameClampsToTheNearestVisibleFrame() {
        let proposed = NSRect(x: 1_900, y: 900, width: 120, height: 120)
        let screens = [
            NSRect(x: -1_280, y: 0, width: 1_280, height: 800),
            NSRect(x: 0, y: 40, width: 1_440, height: 860),
        ]

        #expect(placement.safeFrame(for: proposed, visibleFrames: screens) == NSRect(x: 1_320, y: 780, width: 120, height: 120))
    }

    @Test func partialFrameRespectsMenuBarAndDockVisibleArea() {
        let proposed = NSRect(x: 1_350, y: 850, width: 160, height: 160)
        let visible = NSRect(x: 0, y: 40, width: 1_440, height: 860)

        #expect(placement.safeFrame(for: proposed, visibleFrames: [visible]) == NSRect(x: 1_280, y: 740, width: 160, height: 160))
    }

    @Test(arguments: PetDisplaySize.allCases)
    func everyDisplaySizeIsClampedAsACompleteFrame(size: PetDisplaySize) {
        let visible = NSRect(x: -1_000, y: -700, width: 900, height: 650)
        let length = size.pointLength
        let proposed = NSRect(x: -150, y: -80, width: length, height: length)

        let result = placement.safeFrame(for: proposed, visibleFrames: [visible])

        #expect(result == NSRect(x: -100 - length, y: -50 - length, width: length, height: length))
        #expect(visible.contains(result!))
    }

    @Test func reducedVisibleAreaCorrectsAPreviouslyValidFrame() {
        let proposed = NSRect(x: 1_200, y: 700, width: 240, height: 240)
        let reducedVisible = NSRect(x: 0, y: 80, width: 1_300, height: 700)

        #expect(placement.safeFrame(for: proposed, visibleFrames: [reducedVisible]) == NSRect(x: 1_060, y: 540, width: 240, height: 240))
    }
}
