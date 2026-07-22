import AppKit
import Testing
@testable import MochiDock

@MainActor
struct PetPanelControllerTests {
    @Test func validStoredPositionDefinesTheFirstVisiblePanelFrame() {
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: "{\"version\":1,\"x\":-900,\"y\":140}"
        ])
        let controller = makeController(store: store, visibleFrames: [
            NSRect(x: -1_280, y: 0, width: 1_280, height: 800)
        ])

        controller.showPet()
        defer { controller.panel?.close() }

        #expect(controller.panel?.frame == NSRect(x: -900, y: 140, width: 120, height: 120))
        #expect(store.writeCount == 0)
    }

    @Test func offscreenStoredPositionIsCorrectedAndPersistedBeforeShowing() {
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: "{\"version\":1,\"x\":1900,\"y\":900}"
        ])
        let controller = makeController(
            store: store,
            visibleFrames: [NSRect(x: 0, y: 40, width: 1_440, height: 860)]
        )

        controller.showPet()
        defer { controller.panel?.close() }

        #expect(controller.panel?.frame == NSRect(x: 1_320, y: 780, width: 120, height: 120))
        #expect(PetWindowPosition.decode(store.values[PetPreferenceKey.windowPosition]!)?.origin == NSPoint(x: 1_320, y: 780))
        #expect(store.writeCount == 1)
    }

    @Test(arguments: ["bad", "{\"version\":2,\"x\":100,\"y\":100}"])
    func invalidStoredPositionUsesDefaultCenteredBehavior(payload: String) {
        let store = InMemoryPetPreferences(values: [PetPreferenceKey.windowPosition: payload])
        let controller = makeController(
            store: store,
            visibleFrames: [NSRect(x: 0, y: 0, width: 1_440, height: 900)]
        )

        controller.showPet()
        defer { controller.panel?.close() }

        #expect(controller.panel?.frame.origin != NSPoint(x: 100, y: 100))
        #expect(store.writeCount == 0)
    }

    @Test func dragWritesOnlyTheFinalMovedPositionOnPointerRelease() throws {
        let store = InMemoryPetPreferences()
        let controller = makeController(
            store: store,
            visibleFrames: [NSRect(x: 0, y: 0, width: 1_440, height: 900)]
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let panel = try #require(controller.panel as? PetPanel)

        panel.pointerContactChanged(true)
        panel.setFrameOrigin(NSPoint(x: 200, y: 220))
        panel.setFrameOrigin(NSPoint(x: 260, y: 280))
        #expect(store.writeCount == 0)

        panel.pointerContactChanged(false)
        #expect(store.writeCount == 1)
        #expect(PetWindowPosition.decode(store.values[PetPreferenceKey.windowPosition]!)?.origin == NSPoint(x: 260, y: 280))
    }

    @Test func clickWithoutMovingDoesNotWriteAPosition() throws {
        let store = InMemoryPetPreferences()
        let controller = makeController(
            store: store,
            visibleFrames: [NSRect(x: 0, y: 0, width: 1_440, height: 900)]
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let panel = try #require(controller.panel as? PetPanel)

        panel.pointerContactChanged(true)
        panel.pointerContactChanged(false)

        #expect(store.writeCount == 0)
    }

    @Test func sizeChangeKeepsCenterWhenSafeAndPersistsTheNewOrigin() {
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: "{\"version\":1,\"x\":500,\"y\":300}"
        ])
        let controller = makeController(
            store: store,
            visibleFrames: [NSRect(x: 0, y: 0, width: 1_440, height: 900)]
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let originalCenter = NSPoint(x: 560, y: 360)

        controller.selectDisplaySize(.jumbo)

        #expect(controller.panel?.frame == NSRect(x: 400, y: 200, width: 320, height: 320))
        #expect(NSPoint(x: controller.panel!.frame.midX, y: controller.panel!.frame.midY) == originalCenter)
        #expect(PetWindowPosition.decode(store.values[PetPreferenceKey.windowPosition]!)?.origin == NSPoint(x: 400, y: 200))
    }

    @Test func screenNotificationOnlyWritesWhenCorrectionMovesThePanel() {
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: "{\"version\":1,\"x\":900,\"y\":500}"
        ])
        var frames = [NSRect(x: 0, y: 0, width: 1_440, height: 900)]
        let notifications = NotificationCenter()
        let controller = makeController(
            store: store,
            visibleFrames: { frames },
            notificationCenter: notifications
        )
        controller.showPet()
        defer { controller.panel?.close() }

        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        #expect(store.writeCount == 0)

        frames = [NSRect(x: 0, y: 40, width: 800, height: 560)]
        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        #expect(controller.panel?.frame == NSRect(x: 680, y: 480, width: 120, height: 120))
        #expect(store.writeCount == 1)
    }

    @Test func screenNotificationPersistsAppKitMovedSafeFrameWithoutMovingItAgain() throws {
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: "{\"version\":1,\"x\":900,\"y\":500}"
        ])
        var frames = [NSRect(x: 0, y: 0, width: 1_440, height: 900)]
        let notifications = NotificationCenter()
        let controller = makeController(
            store: store,
            visibleFrames: { frames },
            notificationCenter: notifications
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let panel = try #require(controller.panel)

        let appKitMovedFrame = NSRect(x: 300, y: 220, width: 120, height: 120)
        panel.setFrame(appKitMovedFrame, display: false)
        frames = [NSRect(x: 0, y: 40, width: 800, height: 560)]

        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)

        #expect(panel.frame == appKitMovedFrame)
        #expect(
            PetWindowPosition.decode(store.values[PetPreferenceKey.windowPosition]!)?.origin
                == appKitMovedFrame.origin
        )
        #expect(store.writeCount == 1)
    }

    @Test func unchangedScreenNotificationDoesNotCreateAMissingPositionValue() {
        let store = InMemoryPetPreferences()
        let notifications = NotificationCenter()
        let visibleFrame = NSRect(x: 0, y: 40, width: 1_440, height: 860)
        let stableFrame = NSRect(x: 300, y: 220, width: 120, height: 120)
        let controller = makeController(
            store: store,
            visibleFrames: { [visibleFrame] },
            notificationCenter: notifications
        )
        controller.showPet()
        defer { controller.panel?.close() }
        controller.panel?.setFrame(stableFrame, display: false)

        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)

        #expect(controller.panel?.frame == stableFrame)
        #expect(store.values[PetPreferenceKey.windowPosition] == nil)
        #expect(store.writeCount == 0)
    }

    @Test func unchangedScreenNotificationDoesNotReplaceAnInvalidPositionValue() {
        let invalidValue = "not-a-position"
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: invalidValue
        ])
        let notifications = NotificationCenter()
        let visibleFrame = NSRect(x: 0, y: 40, width: 1_440, height: 860)
        let stableFrame = NSRect(x: 300, y: 220, width: 120, height: 120)
        let controller = makeController(
            store: store,
            visibleFrames: { [visibleFrame] },
            notificationCenter: notifications
        )
        controller.showPet()
        defer { controller.panel?.close() }
        controller.panel?.setFrame(stableFrame, display: false)

        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)

        #expect(controller.panel?.frame == stableFrame)
        #expect(store.values[PetPreferenceKey.windowPosition] == invalidValue)
        #expect(store.writeCount == 0)
    }

    @Test func restorationWaitsForScreenInformationThenCorrectsAndSaves() {
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: "{\"version\":1,\"x\":1900,\"y\":900}"
        ])
        var frames: [NSRect] = []
        let notifications = NotificationCenter()
        let controller = makeController(
            store: store,
            visibleFrames: { frames },
            notificationCenter: notifications
        )
        controller.showPet()
        defer { controller.panel?.close() }
        #expect(store.writeCount == 0)

        frames = [NSRect(x: 0, y: 40, width: 1_440, height: 860)]
        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)

        #expect(controller.panel?.frame == NSRect(x: 1_320, y: 780, width: 120, height: 120))
        #expect(store.writeCount == 1)
    }

    @Test func sizeChangeWhileScreensAreUnavailablePreservesPendingRestorationIntent() {
        let storedPosition = "{\"version\":1,\"x\":1900,\"y\":900}"
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: storedPosition
        ])
        var frames: [NSRect] = []
        let notifications = NotificationCenter()
        let controller = makeController(
            store: store,
            visibleFrames: { frames },
            notificationCenter: notifications
        )
        controller.showPet()
        defer { controller.panel?.close() }

        controller.selectDisplaySize(.jumbo)

        #expect(store.values[PetPreferenceKey.windowPosition] == storedPosition)
        #expect(store.writeCount == 1)

        frames = [NSRect(x: 0, y: 40, width: 1_440, height: 860)]
        notifications.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)

        let expectedFrame = NSRect(x: 1_120, y: 580, width: 320, height: 320)
        #expect(controller.panel?.frame == expectedFrame)
        #expect(
            PetWindowPosition.decode(store.values[PetPreferenceKey.windowPosition]!)?.origin
                == expectedFrame.origin
        )
        #expect(store.writeCount == 2)
    }

    @Test func hideAndShowPreserveTheExactPositionWithoutWriting() {
        let store = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: "{\"version\":1,\"x\":320,\"y\":240}"
        ])
        let controller = makeController(
            store: store,
            visibleFrames: [NSRect(x: 0, y: 0, width: 1_440, height: 900)]
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let panel = controller.panel
        let frame = panel?.frame

        controller.hidePet()
        controller.showPet()

        #expect(controller.panel === panel)
        #expect(controller.panel?.frame == frame)
        #expect(store.writeCount == 0)
    }

    @Test func showAndHideStartAndStopProximityDetectionWithTheSamePanel() {
        let detector = TestPointerProximityDetector()
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences()),
            proximityDetector: detector
        )

        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel
        controller.hidePet()
        controller.showPet()

        #expect(detector.startCount == 2)
        #expect(detector.stopCount == 1)
        #expect(controller.panel === originalPanel)
    }

    @Test func panelPointerContactSuppressesThenResynchronizesProximityDetection() throws {
        let detector = TestPointerProximityDetector()
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences()),
            proximityDetector: detector
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let panel = try #require(controller.panel as? PetPanel)

        panel.pointerContactChanged(true)
        panel.pointerContactChanged(false)

        #expect(detector.draggingChanges == [true, false])
    }

    @Test func restoredSizeDefinesTheFirstPanelFrameAndMenuSelectionSource() {
        let store = InMemoryPetPreferences(
            values: [PetPreferenceKey.displaySize: PetDisplaySize.jumbo.rawValue]
        )
        let model = PetInteractionModel(preferences: store)
        let controller = PetPanelController(model: model)

        controller.showPet()
        defer { controller.panel?.close() }

        #expect(model.displaySize == .jumbo)
        #expect(model.displaySize.resourceName == "RedPandaProneV04_320")
        #expect(controller.panel?.frame.size == NSSize(width: 320, height: 320))
    }

    @Test func restoredSizeAndRepeatedVisibilityChangesKeepOnePlaybackSchedule() {
        let store = InMemoryPetPreferences(
            values: [PetPreferenceKey.displaySize: PetDisplaySize.extraLarge.rawValue]
        )
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: store)
        let controller = PetPanelController(model: model)

        controller.showPet()
        defer { controller.panel?.close() }
        controller.selectDisplaySize(.extraLarge)
        controller.hidePet()
        controller.hidePet()
        controller.showPet()
        controller.showPet()
        controller.selectDisplaySize(.small)

        #expect(model.displaySize == .small)
        #expect(store.values[PetPreferenceKey.displaySize] == PetDisplaySize.small.rawValue)
        #expect(scheduler.pendingCount == 1)
    }

    @Test func repeatedShowAndSizeChangesKeepOnePlaybackSchedule() {
        let scheduler = TestPetAnimationScheduler()
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
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
        let model = PetInteractionModel(scheduler: scheduler, preferences: InMemoryPetPreferences())
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
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )

        controller.showPet()
        defer { controller.panel?.close() }

        let panel = controller.panel
        #expect(panel != nil)
        #expect(panel?.isOpaque == false)
        #expect(panel?.backgroundColor == .clear)
        #expect(panel?.styleMask.contains(.borderless) == true)
        #expect(panel?.isMovable == false)
        #expect(panel?.isMovableByWindowBackground == false)
        #expect(panel?.level == .floating)
        #expect(panel?.collectionBehavior.contains(.canJoinAllSpaces) == true)
        #expect(panel?.collectionBehavior.contains(.moveToActiveSpace) == false)
        #expect(panel?.collectionBehavior.contains(.fullScreenAuxiliary) == false)
    }

    @Test func repeatedShowReusesTheSamePanel() {
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let firstPanel = controller.panel

        controller.showPet()

        #expect(controller.panel === firstPanel)
    }

    @Test func showAfterCloseRestoresTheSamePanel() {
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
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
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
        controller.showPet()
        defer { controller.panel?.close() }

        controller.selectDisplaySize(size)

        #expect(controller.panel?.frame.size == NSSize(width: pointLength, height: pointLength))
    }

    @Test func selectingSizeKeepsPanelIdentityAndCenter() {
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
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
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel

        controller.selectDisplaySize(.small)
        controller.selectDisplaySize(.small)

        #expect(controller.panel === originalPanel)
    }

    @Test func rapidSizeChangesReusePanelModelAndHostingViewWithNoWindowAnimation() {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        let controller = PetPanelController(model: model)
        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel
        let originalContentView = originalPanel?.contentView
        let originalCenter = NSPoint(
            x: originalPanel?.frame.midX ?? 0,
            y: originalPanel?.frame.midY ?? 0
        )

        for size in PetDisplaySize.allCases + PetDisplaySize.allCases.reversed() {
            controller.selectDisplaySize(size)
        }

        #expect(controller.panel === originalPanel)
        #expect(controller.panel?.contentView === originalContentView)
        #expect(controller.panel?.animationBehavior == NSWindow.AnimationBehavior.none)
        #expect(model.displaySize == .small)
        #expect(controller.panel?.frame.size == NSSize(width: 80, height: 80))
        #expect(controller.panel?.frame.midX == originalCenter.x)
        #expect(controller.panel?.frame.midY == originalCenter.y)
    }

    @Test func hideMakesTheExistingPanelInvisibleWithoutReleasingIt() {
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel

        controller.hidePet()

        #expect(controller.panel === originalPanel)
        #expect(controller.panel?.isVisible == false)
    }

    @Test func showAfterHideRestoresTheSamePanel() {
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel
        controller.hidePet()

        controller.showPet()

        #expect(controller.panel === originalPanel)
        #expect(controller.panel?.isVisible == true)
    }

    @Test func hideAndShowPreserveSizeAndRestoreIdlePlayback() {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        let controller = PetPanelController(model: model)
        controller.showPet()
        defer { controller.panel?.close() }
        controller.selectDisplaySize(.large)
        model.handleClick()

        controller.hidePet()
        controller.showPet()

        #expect(model.displaySize == .large)
        #expect(controller.panel?.frame.size == NSSize(width: 160, height: 160))
        #expect(model.mood == .resting)
        #expect(model.visualState == .idle)
    }

    @Test func repeatedHideAndShowReusesOnePanel() {
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
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
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
        controller.showPet()
        defer { controller.panel?.close() }

        #expect(controller.isPetVisible == true)

        controller.hidePet()
        #expect(controller.isPetVisible == false)

        controller.showPet()
        #expect(controller.isPetVisible == true)
    }

    @Test func toggleHidesThenRestoresTheSamePanel() {
        let controller = PetPanelController(
            model: PetInteractionModel(preferences: InMemoryPetPreferences())
        )
        controller.showPet()
        defer { controller.panel?.close() }
        let originalPanel = controller.panel

        controller.togglePetVisibility()
        #expect(controller.isPetVisible == false)

        controller.togglePetVisibility()
        #expect(controller.isPetVisible == true)
        #expect(controller.panel === originalPanel)
    }

    @Test func togglePreservesSizeAndRestoresIdlePlayback() {
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        let controller = PetPanelController(model: model)
        controller.showPet()
        defer { controller.panel?.close() }
        controller.selectDisplaySize(.large)
        model.handleClick()

        controller.togglePetVisibility()
        controller.togglePetVisibility()

        #expect(controller.panel?.frame.size == NSSize(width: 160, height: 160))
        #expect(model.displaySize == .large)
        #expect(model.mood == .resting)
        #expect(model.visualState == .idle)
    }

    private func makeController(
        store: InMemoryPetPreferences,
        visibleFrames: [NSRect]
    ) -> PetPanelController {
        makeController(store: store, visibleFrames: { visibleFrames })
    }

    private func makeController(
        store: InMemoryPetPreferences,
        visibleFrames: @escaping () -> [NSRect],
        notificationCenter: NotificationCenter = NotificationCenter()
    ) -> PetPanelController {
        PetPanelController(
            model: PetInteractionModel(preferences: store),
            proximityDetector: TestPointerProximityDetector(),
            visibleFrames: visibleFrames,
            notificationCenter: notificationCenter
        )
    }
}

@MainActor
private final class TestPointerProximityDetector: PointerProximityDetecting {
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var draggingChanges: [Bool] = []

    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func setDragging(_ dragging: Bool) { draggingChanges.append(dragging) }
}
