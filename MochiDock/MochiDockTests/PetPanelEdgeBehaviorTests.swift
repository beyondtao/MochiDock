import AppKit
import Testing
@testable import MochiDock

@MainActor
@Suite(.serialized)
struct PetPanelEdgeBehaviorTests {
    private let visibleFrame = NSRect(x: 0, y: 40, width: 1_440, height: 860)

    @Test(arguments: [PetScreenEdge.left, .right])
    func dragToOuterEdgeWaitsThenRetreatsWithoutPersistingPeek(edge: PetScreenEdge) {
        let harness = makeHarness()
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        let start = NSRect(x: 500, y: 300, width: 120, height: 120)
        let full = edge == .left
            ? NSRect(x: 0, y: 300, width: 120, height: 120)
            : NSRect(x: 1_320, y: 300, width: 120, height: 120)
        panel.setFrame(start, display: false)
        panel.pointerContactChanged(true)
        panel.setFrame(full, display: false)
        panel.pointerContactChanged(false)
        let persistedBeforePeek = harness.store.values[PetPreferenceKey.windowPosition]

        #expect(harness.edgeScheduler.scheduledDelays == [6])
        harness.edgeScheduler.runNext()

        #expect(panel.frame != full)
        #expect(panel.frame.width == full.width)
        #expect(visibleFrame.intersection(panel.frame).width == 42)
        #expect(harness.store.values[PetPreferenceKey.windowPosition] == persistedBeforePeek)
        #expect(harness.model.visualState == .attentionBase)
    }

    @Test func centerAndInternalDisplaySeamNeverArm() {
        let adjacent = NSRect(x: -1_280, y: 0, width: 1_280, height: 800)
        let harness = makeHarness(visibleFrames: [adjacent, visibleFrame])
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel

        drag(panel, from: NSRect(x: 500, y: 300, width: 120, height: 120), to: NSRect(x: 600, y: 300, width: 120, height: 120))
        drag(panel, from: NSRect(x: 500, y: 300, width: 120, height: 120), to: NSRect(x: 0, y: 300, width: 120, height: 120))

        #expect(harness.edgeScheduler.pendingCount == 0)
    }

    @Test func pointerReturnWorksWhileDecorativeProximityIsDisabled() {
        let harness = makeHarness(proximityEnabled: false)
        enterLeftPeek(harness)

        #expect(harness.detector.startCount == 1)
        #expect(harness.controller.handleProximityEntry())
        harness.proximityIntentScheduler.runNext()

        #expect(harness.controller.panel?.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        #expect(harness.model.visualState == .idle)
        #expect(harness.detector.stopCount == 0)
    }

    @Test func clickOnPeekReturnsFirstThenStartsOneExistingHappyResponse() {
        let harness = makeHarness(proximityEnabled: false)
        enterLeftPeek(harness)

        harness.controller.handlePetClick()
        harness.controller.handlePetClick()

        #expect(harness.controller.panel?.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        #expect(harness.model.mood == .happy)
        #expect(harness.model.visualState == .happy)
        #expect(harness.modelScheduler.pendingCount == 1)
        #expect(harness.detector.stopCount == 1)
    }

    @Test func realMouseDownTapMouseUpOnPeekReturnsThenStartsExactlyOneHappyResponse() {
        let animator = ControlledPetPanelFrameAnimator()
        let harness = makeHarness(proximityEnabled: false, frameAnimator: animator)
        enterLeftPeek(harness)
        animator.completeNext()
        let panel = harness.controller.panel as! PetPanel

        panel.sendEvent(mouseEvent(.leftMouseDown, for: panel))
        #expect(panel.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        #expect(animator.pendingFrames.isEmpty)
        #expect(harness.model.mood == .resting)
        #expect(harness.model.visualState == .idle)
        harness.controller.handlePetClick()
        harness.controller.handlePetClick()
        panel.sendEvent(mouseEvent(.leftMouseUp, for: panel))

        #expect(panel.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        #expect(harness.model.mood == .happy)
        #expect(harness.modelScheduler.pendingCount == 1)
    }

    @Test func realMouseEventsStillAllowAnOrdinaryDragToArmEdgeWaiting() {
        let harness = makeHarness()
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        panel.setFrame(NSRect(x: 500, y: 300, width: 120, height: 120), display: false)

        applicationDrag(panel, to: NSRect(x: 0, y: 300, width: 120, height: 120))

        #expect(harness.edgeScheduler.pendingCount == 1)
    }

    @Test func petPanelUsesApplicationControlledDraggingInsteadOfSystemDragging() {
        let harness = makeHarness()
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        #expect(harness.controller.panel?.isMovable == false)
        #expect(harness.controller.panel?.isMovableByWindowBackground == false)
    }

    @Test func mouseDraggedUsesScreenDeltaFromOneStartFrameWithoutAccumulatedDrift() {
        let harness = makeHarness()
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        panel.setFrame(NSRect(x: 500, y: 300, width: 120, height: 120), display: false)
        panel.sendEvent(mouseEvent(.leftMouseDown, screenLocation: NSPoint(x: 560, y: 360), for: panel))
        panel.sendEvent(mouseEvent(.leftMouseDragged, screenLocation: NSPoint(x: 580, y: 370), for: panel))
        #expect(panel.frame.origin == NSPoint(x: 520, y: 310))
        panel.sendEvent(mouseEvent(.leftMouseDragged, screenLocation: NSPoint(x: 600, y: 390), for: panel))
        #expect(panel.frame.origin == NSPoint(x: 540, y: 330))
        let writes = harness.store.writeCount
        panel.sendEvent(mouseEvent(.leftMouseUp, screenLocation: NSPoint(x: 600, y: 390), for: panel))
        #expect(harness.store.writeCount == writes + 1)
        #expect(harness.edgeScheduler.pendingCount == 0)
    }

    @Test func noMovementMouseSequenceDoesNotPersistPosition() {
        let harness = makeHarness()
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        let writes = harness.store.writeCount
        panel.sendEvent(mouseEvent(.leftMouseDown, at: NSPoint(x: 60, y: 60), for: panel))
        panel.sendEvent(mouseEvent(.leftMouseUp, at: NSPoint(x: 60, y: 60), for: panel))
        #expect(harness.store.writeCount == writes)
    }

    @Test func hideCancelsApplicationDragAndMakesStaleEventsInert() {
        let harness = makeHarness()
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        panel.setFrame(NSRect(x: 500, y: 300, width: 120, height: 120), display: false)
        let staleLocation = beginApplicationDrag(panel, delta: NSPoint(x: 80, y: 40))

        harness.controller.hidePet()
        let interruptedFrame = panel.frame
        let writesAfterHide = harness.store.writeCount
        panel.sendEvent(mouseEvent(.leftMouseDragged, screenLocation: NSPoint(x: 900, y: 700), for: panel))
        panel.sendEvent(mouseEvent(.leftMouseUp, screenLocation: staleLocation, for: panel))

        #expect(!panel.isVisible)
        #expect(panel.frame == interruptedFrame)
        #expect(harness.store.writeCount == writesAfterHide)
        #expect(harness.edgeScheduler.pendingCount == 0)
        #expect(harness.model.mood == .resting)
        #expect(harness.detector.draggingStates.last == false)

        harness.controller.showPet()
        #expect(harness.detector.startCount == 2)
    }

    @Test func sizeChangeCancelsApplicationDragBeforeStaleEventsArrive() {
        let harness = makeHarness()
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        panel.setFrame(NSRect(x: 0, y: 300, width: 120, height: 120), display: false)
        let staleLocation = beginApplicationDrag(panel, delta: NSPoint(x: 0, y: 30))

        harness.controller.selectDisplaySize(.large)
        let sizedFrame = panel.frame
        let writesAfterSize = harness.store.writeCount
        panel.sendEvent(mouseEvent(.leftMouseDragged, screenLocation: NSPoint(x: 700, y: 700), for: panel))
        panel.sendEvent(mouseEvent(.leftMouseUp, screenLocation: staleLocation, for: panel))

        #expect(panel.frame == sizedFrame)
        #expect(panel.frame.size == NSSize(width: PetDisplaySize.large.pointLength, height: PetDisplaySize.large.pointLength))
        #expect(harness.store.writeCount == writesAfterSize)
        #expect(harness.detector.draggingStates.last == false)
        #expect(harness.edgeScheduler.pendingCount == 1)
    }

    @Test func screenChangeCancelsApplicationDragBeforeStaleEventsAndCallbacks() {
        let frames = MutableVisibleFrames([visibleFrame])
        let harness = makeHarness(visibleFramesProvider: { frames.values })
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        panel.setFrame(NSRect(x: 1_250, y: 300, width: 120, height: 120), display: false)
        let staleLocation = beginApplicationDrag(panel, delta: NSPoint(x: 100, y: 40))
        frames.values = [NSRect(x: 0, y: 40, width: 1_000, height: 700)]

        harness.notificationCenter.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        let safeFrame = panel.frame
        let writesAfterScreenChange = harness.store.writeCount
        panel.sendEvent(mouseEvent(.leftMouseDragged, screenLocation: NSPoint(x: 1_300, y: 800), for: panel))
        panel.sendEvent(mouseEvent(.leftMouseUp, screenLocation: staleLocation, for: panel))
        harness.proximityIntentScheduler.runAllIncludingCancelled()

        #expect(frames.values[0].contains(safeFrame))
        #expect(panel.frame == safeFrame)
        #expect(harness.store.writeCount == writesAfterScreenChange)
        #expect(harness.detector.draggingStates.last == false)
        #expect(harness.edgeScheduler.pendingCount == 1)
        #expect(harness.model.mood == .resting)
    }

    @Test func aFreshDragAfterLifecycleCancellationUsesOnlyItsOwnOriginAndDelta() {
        let harness = makeHarness()
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        panel.setFrame(NSRect(x: 500, y: 300, width: 120, height: 120), display: false)
        _ = beginApplicationDrag(panel, delta: NSPoint(x: 70, y: 20))
        harness.controller.hidePet()
        harness.controller.showPet()

        let freshStart = panel.frame
        let freshEndLocation = beginApplicationDrag(panel, delta: NSPoint(x: -35, y: 55))
        let writesBeforeMouseUp = harness.store.writeCount
        panel.sendEvent(mouseEvent(.leftMouseUp, screenLocation: freshEndLocation, for: panel))

        #expect(panel.frame.origin == NSPoint(x: freshStart.origin.x - 35, y: freshStart.origin.y + 55))
        #expect(harness.store.writeCount == writesBeforeMouseUp + 1)
        #expect(harness.edgeScheduler.pendingCount == 0)
    }

    @Test func hideCancelsAnInFlightClickReturnAndIgnoresItsStaleCompletion() {
        let animator = ControlledPetPanelFrameAnimator()
        let harness = makeHarness(proximityEnabled: false, frameAnimator: animator)
        enterLeftPeek(harness)
        animator.completeNext()
        harness.controller.handlePetClick()

        harness.controller.hidePet()
        #expect(harness.controller.panel?.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        #expect(animator.cancelCount == 1)
        animator.completeNextIncludingCancelled()

        #expect(harness.model.mood == .resting)
        #expect(harness.model.visualState == .idle)
        #expect(harness.controller.panel?.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
    }

    @Test func sizeChangeCancelsAnInFlightReturnWithoutOldFrameOrClickWinning() {
        let animator = ControlledPetPanelFrameAnimator()
        let harness = makeHarness(proximityEnabled: false, frameAnimator: animator)
        enterLeftPeek(harness)
        animator.completeNext()
        harness.controller.handlePetClick()

        harness.controller.selectDisplaySize(.large)
        let resizedFrame = harness.controller.panel!.frame
        #expect(resizedFrame.width == 160)
        #expect(visibleFrame.contains(resizedFrame))
        animator.completeNextIncludingCancelled()

        #expect(harness.controller.panel?.frame == resizedFrame)
        #expect(harness.model.mood == .resting)
        #expect(harness.model.visualState == .idle)
    }

    @Test func screenChangeCancelsAnInFlightReturnAndStaleCompletionCannotOverwriteSafety() {
        let animator = ControlledPetPanelFrameAnimator()
        let frames = MutableVisibleFrames([visibleFrame])
        let harness = makeHarness(
            proximityEnabled: false,
            visibleFramesProvider: { frames.values },
            frameAnimator: animator
        )
        enterLeftPeek(harness)
        animator.completeNext()
        harness.controller.handlePetClick()
        frames.values = [NSRect(x: 200, y: 40, width: 1_440, height: 860)]

        harness.notificationCenter.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        let safeFrame = harness.controller.panel!.frame
        #expect(frames.values[0].contains(safeFrame))
        animator.completeNextIncludingCancelled()

        #expect(harness.controller.panel?.frame == safeFrame)
        #expect(harness.model.mood == .resting)
    }

    @Test func newDragCancelsAnInFlightReturnAndStaleCompletionCannotUndoDrag() {
        let animator = ControlledPetPanelFrameAnimator()
        let harness = makeHarness(proximityEnabled: false, frameAnimator: animator)
        enterLeftPeek(harness)
        animator.completeNext()
        harness.controller.handlePetClick()
        let panel = harness.controller.panel as! PetPanel

        applicationDrag(panel, to: NSRect(x: 500, y: 300, width: 120, height: 120))
        let draggedFrame = panel.frame
        animator.completeNextIncludingCancelled()

        #expect(panel.frame == draggedFrame)
        #expect(harness.model.mood == .resting)
        #expect(harness.edgeScheduler.pendingCount == 0)
    }

    @Test func directDragFromPeekingToAnotherOuterEdgeSynchronouslyTakesFrameOwnership() {
        verifyDirectDragFromPeek(
            to: NSRect(x: 1_320, y: 300, width: 120, height: 120),
            expectedWaitCount: 1
        )
    }

    @Test func directDragFromPeekingToCenterDoesNotRearmEdgeWaiting() {
        verifyDirectDragFromPeek(
            to: NSRect(x: 500, y: 300, width: 120, height: 120),
            expectedWaitCount: 0
        )
    }

    @Test func disablingDecorativeProximityWhileWaitingKeepsSafetyDetectionUntilClickCancels() {
        let harness = makeHarness(proximityEnabled: true)
        harness.controller.showPet()
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        drag(
            panel,
            from: NSRect(x: 500, y: 300, width: 120, height: 120),
            to: NSRect(x: 0, y: 300, width: 120, height: 120)
        )

        harness.controller.setProximityResponseEnabled(false)
        harness.controller.setProximityResponseEnabled(false)
        #expect(harness.detector.startCount == 1)
        #expect(harness.detector.stopCount == 0)

        harness.controller.handlePetClick()
        #expect(harness.model.mood == .happy)
        #expect(harness.detector.stopCount == 1)
    }

    @Test func disablingDecorativeProximityWhilePeekingPreservesSafetyAndVisualUntilClickReturn() {
        let harness = makeHarness(proximityEnabled: true)
        enterLeftPeek(harness)

        harness.controller.setProximityResponseEnabled(false)
        harness.controller.setProximityResponseEnabled(false)
        #expect(harness.detector.startCount == 1)
        #expect(harness.detector.stopCount == 0)
        #expect(harness.model.visualState == .attentionBase)

        harness.controller.handlePetClick()
        #expect(harness.controller.panel?.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        #expect(harness.model.mood == .happy)
        #expect(harness.detector.stopCount == 0)
    }

    @Test func disablingDecorativeProximityWhilePeekingStillAllowsPointerSafetyRecall() {
        let harness = makeHarness(proximityEnabled: true)
        enterLeftPeek(harness)
        harness.controller.setProximityResponseEnabled(false)

        #expect(harness.controller.handleProximityEntry())
        harness.proximityIntentScheduler.runNext()
        #expect(harness.controller.panel?.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        #expect(harness.model.visualState == .idle)
        #expect(harness.detector.startCount == 1)
        #expect(harness.detector.stopCount == 0)
    }

    @Test func hideShowRestoresTheFullFrameAndKeepsTheSamePanel() {
        let harness = makeHarness()
        enterLeftPeek(harness)
        let panel = harness.controller.panel

        harness.controller.hidePet()
        #expect(harness.controller.panel?.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        harness.controller.showPet()

        #expect(harness.controller.panel === panel)
        #expect(harness.controller.panel?.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        harness.controller.panel?.close()
    }

    @Test func sizeAndScreenChangesRestoreBeforeApplyingOrdinarySafetyRules() {
        let sizeHarness = makeHarness()
        enterLeftPeek(sizeHarness)
        sizeHarness.controller.selectDisplaySize(.large)
        #expect(sizeHarness.controller.panel?.frame.width == 160)
        #expect(visibleFrame.contains(sizeHarness.controller.panel!.frame))
        sizeHarness.controller.panel?.close()

        let screenHarness = makeHarness()
        enterLeftPeek(screenHarness)
        screenHarness.notificationCenter.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        #expect(screenHarness.controller.panel?.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        #expect(visibleFrame.contains(screenHarness.controller.panel!.frame))
        screenHarness.controller.panel?.close()
    }

    @Test func pointerRecallAtEdgeRearmsAndRetreatsAgainAfterSixSeconds() {
        let harness = makeHarness()
        enterLeftPeek(harness)
        #expect(harness.controller.handleProximityEntry())
        harness.proximityIntentScheduler.runNext()
        #expect(harness.edgeScheduler.pendingCount == 1)
        harness.edgeScheduler.runNext()
        #expect(harness.model.visualState == .attentionBase)
    }

    @Test func hideShowAndSizeAndScreenLifecycleRearmOnlyOneEdgeWait() {
        let harness = makeHarness()
        enterLeftPeek(harness)
        harness.controller.hidePet()
        harness.controller.showPet()
        harness.controller.showPet()
        #expect(harness.edgeScheduler.pendingCount == 1)
        harness.controller.selectDisplaySize(.large)
        #expect(harness.edgeScheduler.pendingCount == 1)
        harness.notificationCenter.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        harness.notificationCenter.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        #expect(harness.edgeScheduler.pendingCount == 1)
        harness.controller.panel?.close()
    }

    @Test func restoredSavedEdgeRearmsOnShowButRestoredCenterDoesNot() {
        let edgeStore = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: PetWindowPosition(origin: NSPoint(x: 0, y: 300)).encoded()!
        ])
        let edge = makeHarness(store: edgeStore)
        edge.controller.showPet()
        #expect(edge.edgeScheduler.pendingCount == 1)
        edge.controller.panel?.close()

        let centerStore = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: PetWindowPosition(origin: NSPoint(x: 500, y: 300)).encoded()!
        ])
        let center = makeHarness(store: centerStore)
        center.controller.showPet()
        #expect(center.edgeScheduler.pendingCount == 0)
        center.controller.panel?.close()
    }

    @Test func pointerEntryUsesOneQuarterSecondIntentGateBeforeRecall() {
        let harness = makeHarness()
        enterLeftPeek(harness)
        #expect(harness.controller.handleProximityEntry())
        #expect(harness.controller.handleProximityEntry())
        #expect(harness.proximityIntentScheduler.scheduledDelays == [0.25])
        #expect(harness.proximityIntentScheduler.pendingCount == 1)
        #expect(harness.model.visualState == .attentionBase)
        harness.proximityIntentScheduler.runNext()
        #expect(harness.model.visualState == .idle)
        #expect(harness.edgeScheduler.pendingCount == 1)
    }

    @Test func pointerIntentThenRealMouseDownTapCancelsRecallAndRespondsOnce() {
        let harness = makeHarness()
        enterLeftPeek(harness)
        let panel = harness.controller.panel as! PetPanel
        #expect(harness.controller.handleProximityEntry())
        panel.sendEvent(mouseEvent(.leftMouseDown, for: panel))
        harness.controller.handlePetClick()
        harness.controller.handlePetClick()
        panel.sendEvent(mouseEvent(.leftMouseUp, for: panel))
        harness.proximityIntentScheduler.runAllIncludingCancelled()
        #expect(harness.model.mood == .happy)
        #expect(panel.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
    }

    @Test func pointerIntentThenDirectDragCancelsStaleRecallForCenterAndOtherEdge() {
        for destination in [
            NSRect(x: 500, y: 300, width: 120, height: 120),
            NSRect(x: 1_320, y: 300, width: 120, height: 120)
        ] {
            let harness = makeHarness()
            enterLeftPeek(harness)
            let panel = harness.controller.panel as! PetPanel
            #expect(harness.controller.handleProximityEntry())
            applicationDrag(panel, to: destination)
            harness.proximityIntentScheduler.runAllIncludingCancelled()
            #expect(panel.frame == destination)
            #expect(harness.model.mood == .resting)
            #expect(harness.edgeScheduler.pendingCount == (destination.minX == 500 ? 0 : 1))
            panel.close()
        }
    }

    @Test func hideSizeAndScreenChangesCancelPendingPointerIntentAndStaleCallbacks() {
        for action in 0..<3 {
            let harness = makeHarness()
            enterLeftPeek(harness)
            #expect(harness.controller.handleProximityEntry())
            if action == 0 { harness.controller.hidePet() }
            if action == 1 { harness.controller.selectDisplaySize(.large) }
            if action == 2 {
                harness.notificationCenter.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
            }
            let frame = harness.controller.panel!.frame
            harness.proximityIntentScheduler.runAllIncludingCancelled()
            #expect(harness.controller.panel?.frame == frame)
            #expect(harness.model.mood == .resting)
            harness.controller.panel?.close()
        }
    }

    private func enterLeftPeek(_ harness: PanelEdgeHarness) {
        harness.controller.showPet()
        let panel = harness.controller.panel as! PetPanel
        drag(
            panel,
            from: NSRect(x: 500, y: 300, width: 120, height: 120),
            to: NSRect(x: 0, y: 300, width: 120, height: 120)
        )
        harness.edgeScheduler.runNext()
    }

    private func verifyDirectDragFromPeek(to draggedFrame: NSRect, expectedWaitCount: Int) {
        let animator = ControlledPetPanelFrameAnimator()
        let harness = makeHarness(proximityEnabled: false, frameAnimator: animator)
        enterLeftPeek(harness)
        defer { harness.controller.panel?.close() }
        let panel = harness.controller.panel as! PetPanel
        animator.applyNextFrameWithoutCompleting()
        let writesBeforeDrag = harness.store.writeCount
        let persistedBeforeDrag = harness.store.values[PetPreferenceKey.windowPosition]

        let downScreen = panel.convertPoint(
            toScreen: NSPoint(x: panel.frame.width / 2, y: panel.frame.height / 2)
        )
        panel.sendEvent(mouseEvent(.leftMouseDown, screenLocation: downScreen, for: panel))

        #expect(animator.cancelCount == 1)
        #expect(animator.pendingFrames.count == 1)
        #expect(panel.frame == NSRect(x: 0, y: 300, width: 120, height: 120))
        #expect(harness.model.visualState == .idle)
        #expect(harness.model.mood == .resting)
        #expect(harness.store.writeCount == writesBeforeDrag)
        #expect(harness.store.values[PetPreferenceKey.windowPosition] == persistedBeforeDrag)

        let dragScreen = NSPoint(
            x: downScreen.x + draggedFrame.origin.x - panel.frame.origin.x,
            y: downScreen.y + draggedFrame.origin.y - panel.frame.origin.y
        )
        panel.sendEvent(mouseEvent(.leftMouseDragged, screenLocation: dragScreen, for: panel))
        #expect(harness.store.writeCount == writesBeforeDrag)
        panel.sendEvent(mouseEvent(.leftMouseUp, screenLocation: dragScreen, for: panel))

        #expect(panel.frame == draggedFrame)
        #expect(harness.store.writeCount == writesBeforeDrag + 1)
        #expect(
            harness.store.values[PetPreferenceKey.windowPosition]
                == PetWindowPosition(origin: draggedFrame.origin).encoded()
        )
        #expect(harness.edgeScheduler.pendingCount == expectedWaitCount)

        animator.completeNextIncludingCancelled()
        #expect(panel.frame == draggedFrame)
        #expect(harness.model.mood == .resting)
        #expect(harness.model.visualState == .idle)
        #expect(animator.pendingFrames.isEmpty)
    }

    private func drag(_ panel: PetPanel, from start: NSRect, to end: NSRect) {
        panel.setFrame(start, display: false)
        panel.pointerContactChanged(true)
        panel.setFrame(end, display: false)
        panel.pointerContactChanged(false)
    }

    private func applicationDrag(_ panel: PetPanel, to destination: NSRect) {
        let downScreen = panel.convertPoint(
            toScreen: NSPoint(x: panel.frame.width / 2, y: panel.frame.height / 2)
        )
        panel.sendEvent(mouseEvent(.leftMouseDown, screenLocation: downScreen, for: panel))
        let dragScreen = NSPoint(
            x: downScreen.x + destination.origin.x - panel.frame.origin.x,
            y: downScreen.y + destination.origin.y - panel.frame.origin.y
        )
        panel.sendEvent(mouseEvent(.leftMouseDragged, screenLocation: dragScreen, for: panel))
        panel.sendEvent(mouseEvent(.leftMouseUp, screenLocation: dragScreen, for: panel))
    }

    private func beginApplicationDrag(_ panel: PetPanel, delta: NSPoint) -> NSPoint {
        let downScreen = panel.convertPoint(
            toScreen: NSPoint(x: panel.frame.width / 2, y: panel.frame.height / 2)
        )
        panel.sendEvent(mouseEvent(.leftMouseDown, screenLocation: downScreen, for: panel))
        let draggedScreen = NSPoint(x: downScreen.x + delta.x, y: downScreen.y + delta.y)
        panel.sendEvent(mouseEvent(.leftMouseDragged, screenLocation: draggedScreen, for: panel))
        return draggedScreen
    }

    private func mouseEvent(_ type: NSEvent.EventType, for panel: NSPanel) -> NSEvent {
        mouseEvent(type, at: NSPoint(x: panel.frame.width / 2, y: panel.frame.height / 2), for: panel)
    }

    private func mouseEvent(_ type: NSEvent.EventType, at location: NSPoint, for panel: NSPanel) -> NSEvent {
        NSEvent.mouseEvent(
            with: type,
            location: location,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: panel.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )!
    }

    private func mouseEvent(
        _ type: NSEvent.EventType,
        screenLocation: NSPoint,
        for panel: NSPanel
    ) -> NSEvent {
        mouseEvent(type, at: panel.convertPoint(fromScreen: screenLocation), for: panel)
    }

    private func makeHarness(
        proximityEnabled: Bool = true,
        visibleFrames: [NSRect]? = nil,
        visibleFramesProvider: (() -> [NSRect])? = nil,
        frameAnimator: (any PetPanelFrameAnimating)? = nil,
        store suppliedStore: InMemoryPetPreferences? = nil
    ) -> PanelEdgeHarness {
        let store = suppliedStore ?? InMemoryPetPreferences(values: [
            PetPreferenceKey.proximityResponseEnabled: String(proximityEnabled)
        ])
        let modelScheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: modelScheduler, preferences: store)
        let edgeScheduler = TestPetAnimationScheduler()
        let proximityIntentScheduler = TestPetAnimationScheduler()
        let detector = EdgePointerProximityDetector()
        let notificationCenter = NotificationCenter()
        let animator = frameAnimator ?? ImmediatePetPanelFrameAnimator()
        let controller = PetPanelController(
            model: model,
            proximityDetector: detector,
            visibleFrames: { visibleFramesProvider?() ?? visibleFrames ?? [self.visibleFrame] },
            notificationCenter: notificationCenter,
            edgeScheduler: edgeScheduler,
            proximityIntentScheduler: proximityIntentScheduler,
            frameAnimator: animator
        )
        return PanelEdgeHarness(
            controller: controller,
            model: model,
            modelScheduler: modelScheduler,
            edgeScheduler: edgeScheduler,
            proximityIntentScheduler: proximityIntentScheduler,
            detector: detector,
            store: store,
            notificationCenter: notificationCenter
        )
    }
}

@MainActor private struct PanelEdgeHarness {
    let controller: PetPanelController
    let model: PetInteractionModel
    let modelScheduler: TestPetAnimationScheduler
    let edgeScheduler: TestPetAnimationScheduler
    let proximityIntentScheduler: TestPetAnimationScheduler
    let detector: EdgePointerProximityDetector
    let store: InMemoryPetPreferences
    let notificationCenter: NotificationCenter
}

@MainActor private final class EdgePointerProximityDetector: PointerProximityDetecting {
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var draggingStates: [Bool] = []
    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func setDragging(_ dragging: Bool) { draggingStates.append(dragging) }
}

@MainActor private final class ImmediatePetPanelFrameAnimator: PetPanelFrameAnimating {
    func animate(panel: NSPanel, to frame: NSRect, completion: @escaping () -> Void) {
        panel.setFrame(frame, display: true, animate: false)
        completion()
    }
    func cancel(panel: NSPanel) {}
}

@MainActor private final class ControlledPetPanelFrameAnimator: PetPanelFrameAnimating {
    private struct PendingAnimation {
        weak var panel: NSPanel?
        let frame: NSRect
        let completion: () -> Void
        var isCancelled = false
    }

    private var animations: [PendingAnimation] = []
    private(set) var cancelCount = 0
    var pendingFrames: [NSRect] { animations.map(\.frame) }

    func animate(panel: NSPanel, to frame: NSRect, completion: @escaping () -> Void) {
        animations.append(PendingAnimation(panel: panel, frame: frame, completion: completion))
    }

    func completeNext() {
        guard !animations.isEmpty else { return }
        let animation = animations.removeFirst()
        animation.panel?.setFrame(animation.frame, display: true, animate: false)
        animation.completion()
    }

    func applyNextFrameWithoutCompleting() {
        guard let animation = animations.first else { return }
        animation.panel?.setFrame(animation.frame, display: true, animate: false)
    }

    func cancel(panel: NSPanel) {
        guard let index = animations.firstIndex(where: { $0.panel === panel && !$0.isCancelled }) else { return }
        animations[index].isCancelled = true
        cancelCount += 1
    }

    func completeNextIncludingCancelled() {
        guard !animations.isEmpty else { return }
        let animation = animations.removeFirst()
        if !animation.isCancelled {
            animation.panel?.setFrame(animation.frame, display: true, animate: false)
        }
        animation.completion()
    }
}

@MainActor private final class MutableVisibleFrames {
    var values: [NSRect]
    init(_ values: [NSRect]) { self.values = values }
}
