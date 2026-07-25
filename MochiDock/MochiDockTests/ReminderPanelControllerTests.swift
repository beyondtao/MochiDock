import AppKit
import Foundation
import Testing
@testable import MochiDock

@MainActor
struct ReminderPanelControllerTests {
    @Test func bubblePanelIsBorderlessNonactivatingAndTracksSyntheticPetGeometry() throws {
        let pet = NSPanel(
            contentRect: NSRect(x: 400, y: 300, width: 120, height: 120),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        let centerHarness = try makePendingCenter()
        pet.orderFront(nil)
        let controller = ReminderPanelController(
            center: centerHarness.center,
            model: PetInteractionModel(preferences: InMemoryPetPreferences()),
            petPanel: { pet },
            visibleFrames: { [NSRect(x: 0, y: 0, width: 1_000, height: 800)] },
            scheduler: TestPetAnimationScheduler(),
            restoreFromPeek: { $0() }
        )

        controller.presentPending(isDragging: false, isOrdinaryResponseActive: false, isPeeking: false)
        let bubble = try #require(controller.panel)
        defer { bubble.close(); pet.close() }
        #expect(bubble.styleMask.contains(.borderless))
        #expect(bubble.styleMask.contains(.nonactivatingPanel))
        #expect(bubble.frame.minY == pet.frame.maxY + 12)
        let originalFrame = bubble.frame
        pet.setFrameOrigin(NSPoint(x: 500, y: 350))
        controller.petGeometryDidChange()
        #expect(bubble.frame != originalFrame)
        #expect(pet.frame.origin == NSPoint(x: 500, y: 350))
    }

    @Test func bubbleActionsResolvePendingWithoutCreatingAnotherCycleImmediately() throws {
        let harness = try makePendingCenter()
        let pet = NSPanel(contentRect: NSRect(x: 300, y: 200, width: 120, height: 120), styleMask: .borderless, backing: .buffered, defer: false)
        let controller = ReminderPanelController(
            center: harness.center,
            model: PetInteractionModel(preferences: InMemoryPetPreferences()),
            petPanel: { pet },
            visibleFrames: { [NSRect(x: 0, y: 0, width: 1_000, height: 800)] },
            scheduler: TestPetAnimationScheduler(),
            restoreFromPeek: { $0() }
        )
        defer { controller.panel?.close(); pet.close() }
        controller.presentPending(isDragging: false, isOrdinaryResponseActive: false, isPeeking: false)

        controller.complete()

        #expect(harness.center.pendingReminder == nil)
        #expect(harness.center.activeReminder?.nextTriggerAt == harness.clock.now.addingTimeInterval(300))
        #expect(controller.panel?.isVisible != true)
    }

    @Test func restoredPendingCancelsProductionOrderEdgeRetreatAndResolutionRearmsIt() throws {
        let harness = makeRestoredPendingPanelHarness()
        harness.controller.showPet()
        defer {
            harness.controller.reminderPanelController?.panel?.close()
            harness.controller.panel?.close()
        }
        let fullFrame = try #require(harness.controller.panel?.frame)

        #expect(harness.edgeScheduler.pendingCount == 0)
        harness.edgeScheduler.runAllIncludingCancelled()
        #expect(harness.controller.panel?.frame == fullFrame)
        #expect(harness.controller.reminderPanelController?.panel?.isVisible == true)

        harness.controller.reminderPanelController?.complete()
        #expect(harness.edgeScheduler.pendingCount == 1)
        harness.edgeScheduler.runNext()
        #expect(harness.controller.panel?.frame != fullFrame)
    }

    @Test func hideAndShowRestoresPersistedPendingWithoutImmediateEdgeRetreat() throws {
        let harness = makeRestoredPendingPanelHarness()
        harness.controller.showPet()
        defer {
            harness.controller.reminderPanelController?.panel?.close()
            harness.controller.panel?.close()
        }

        harness.controller.hidePet()
        #expect(harness.center.pendingReminder != nil)
        #expect(harness.controller.reminderPanelController?.panel?.isVisible != true)

        harness.controller.showPet()
        let shownFrame = try #require(harness.controller.panel?.frame)
        #expect(harness.controller.reminderPanelController?.panel?.isVisible == true)
        #expect(harness.edgeScheduler.pendingCount == 0)
        harness.edgeScheduler.runAllIncludingCancelled()
        #expect(harness.controller.panel?.frame == shownFrame)
    }

    @Test func dueDuringDragAndHappyThenHideShowClearsCancelledBlockersAndPresentsOnce() throws {
        let harness = try makeRunningPanelHarness()
        harness.controller.showPet()
        defer {
            harness.controller.reminderPanelController?.panel?.close()
            harness.controller.panel?.close()
        }
        let petPanel = try #require(harness.controller.panel as? PetPanel)

        petPanel.pointerContactChanged(true)
        harness.model.handleClick()
        #expect(harness.model.isOrdinaryResponseActive)
        harness.clock.advance(by: 300)
        harness.reminderScheduler.fireDue()
        #expect(harness.center.pendingReminder != nil)
        #expect(harness.controller.reminderPanelController?.panel?.isVisible != true)

        harness.controller.hidePet()
        harness.controller.hidePet()
        #expect(harness.center.pendingReminder != nil)

        harness.controller.showPet()
        harness.controller.showPet()
        #expect(harness.controller.reminderPanelController?.panel?.isVisible == true)
        #expect(harness.edgeScheduler.pendingCount == 0)

        harness.controller.reminderPanelController?.complete()
        #expect(harness.edgeScheduler.pendingCount == 1)
    }

    private func makePendingCenter() throws -> PendingCenterHarness {
        let clock = TestReminderClock(now: Date(timeIntervalSince1970: 10_000))
        let scheduler = TestReminderScheduler(clock: clock)
        let center = ReminderCenter(clock: clock, scheduler: scheduler, persistence: InMemoryReminderPersistence())
        let reminder = try center.add(ReminderDraft(name: "喝水", intervalMinutes: 5))
        try center.enable(reminder.id)
        clock.advance(by: 300)
        scheduler.fireDue()
        return PendingCenterHarness(center: center, clock: clock)
    }

    private func makeRestoredPendingPanelHarness() -> RestoredPendingPanelHarness {
        let id = UUID()
        let persistence = InMemoryReminderPersistence()
        persistence.payload = ReminderPersistencePayload(
            reminders: [ReminderRecord(
                id: id,
                name: "喝水",
                intervalMinutes: 5,
                state: .enabled,
                remainingSeconds: nil,
                nextTriggerAt: nil
            )],
            pendingReminderID: id
        )
        let clock = TestReminderClock(now: Date(timeIntervalSince1970: 10_000))
        let center = ReminderCenter(
            clock: clock,
            scheduler: TestReminderScheduler(clock: clock),
            persistence: persistence
        )
        let preferences = InMemoryPetPreferences(values: [
            PetPreferenceKey.windowPosition: "{\"version\":1,\"x\":0,\"y\":200}"
        ])
        let model = PetInteractionModel(
            scheduler: TestPetAnimationScheduler(),
            preferences: preferences
        )
        let edgeScheduler = TestPetAnimationScheduler()
        let controller = PetPanelController(
            model: model,
            proximityDetector: ReminderTestProximityDetector(),
            visibleFrames: { [NSRect(x: 0, y: 0, width: 1_000, height: 800)] },
            notificationCenter: NotificationCenter(),
            edgeScheduler: edgeScheduler,
            frameAnimator: ReminderImmediateFrameAnimator()
        )
        controller.connectReminderCenter(center, scheduler: TestPetAnimationScheduler())
        return RestoredPendingPanelHarness(
            controller: controller,
            center: center,
            edgeScheduler: edgeScheduler
        )
    }

    private func makeRunningPanelHarness() throws -> RunningPanelHarness {
        let clock = TestReminderClock(now: Date(timeIntervalSince1970: 20_000))
        let reminderScheduler = TestReminderScheduler(clock: clock)
        let center = ReminderCenter(
            clock: clock,
            scheduler: reminderScheduler,
            persistence: InMemoryReminderPersistence()
        )
        let reminder = try center.add(ReminderDraft(name: "活动", intervalMinutes: 5))
        try center.enable(reminder.id)
        let model = PetInteractionModel(
            scheduler: TestPetAnimationScheduler(),
            preferences: InMemoryPetPreferences(values: [
                PetPreferenceKey.windowPosition: "{\"version\":1,\"x\":0,\"y\":200}"
            ])
        )
        let edgeScheduler = TestPetAnimationScheduler()
        let controller = PetPanelController(
            model: model,
            proximityDetector: ReminderTestProximityDetector(),
            visibleFrames: { [NSRect(x: 0, y: 0, width: 1_000, height: 800)] },
            notificationCenter: NotificationCenter(),
            edgeScheduler: edgeScheduler,
            frameAnimator: ReminderImmediateFrameAnimator()
        )
        controller.connectReminderCenter(center, scheduler: TestPetAnimationScheduler())
        return RunningPanelHarness(
            controller: controller,
            center: center,
            model: model,
            clock: clock,
            reminderScheduler: reminderScheduler,
            edgeScheduler: edgeScheduler
        )
    }
}

@MainActor private struct PendingCenterHarness {
    let center: ReminderCenter
    let clock: TestReminderClock
}

@MainActor private struct RestoredPendingPanelHarness {
    let controller: PetPanelController
    let center: ReminderCenter
    let edgeScheduler: TestPetAnimationScheduler
}

@MainActor private struct RunningPanelHarness {
    let controller: PetPanelController
    let center: ReminderCenter
    let model: PetInteractionModel
    let clock: TestReminderClock
    let reminderScheduler: TestReminderScheduler
    let edgeScheduler: TestPetAnimationScheduler
}

@MainActor private final class ReminderTestProximityDetector: PointerProximityDetecting {
    func start() {}
    func stop() {}
    func setDragging(_: Bool) {}
}

@MainActor private final class ReminderImmediateFrameAnimator: PetPanelFrameAnimating {
    func animate(panel: NSPanel, to frame: NSRect, completion: @escaping () -> Void) {
        panel.setFrame(frame, display: true, animate: false)
        completion()
    }

    func cancel(panel _: NSPanel) {}
}
