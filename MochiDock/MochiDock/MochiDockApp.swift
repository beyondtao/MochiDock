//
//  MochiDockApp.swift
//  MochiDock
//
//  Created by Scott on 2026/7/18.
//

import AppKit
import Combine
import SwiftUI

@MainActor
protocol ApplicationActivating: AnyObject {
    func activate()
}

extension NSApplication: ApplicationActivating {}

@main
struct MochiDockApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: MochiDockAppDelegate

    var body: some Scene {
        MenuBarExtra("MochiDock", systemImage: "pawprint.fill") {
            MochiDockMenuContent(appDelegate: appDelegate)
        }
    }
}

struct MochiDockMenuContent: View {
    @ObservedObject var appDelegate: MochiDockAppDelegate

    var body: some View {
        ForEach(MochiDockMenuAction.allCases, id: \.self) { action in
            switch action {
            case .petVisibility:
                Button(appDelegate.petVisibilityActionTitle) {
                    appDelegate.togglePetVisibility()
                }
            case .settings:
                Button("Settings…") {
                    appDelegate.openSettings()
                }
            case .quit:
                Divider()
                Button("Quit MochiDock") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}

enum MochiDockMenuAction: CaseIterable {
    case petVisibility
    case settings
    case quit
}

@MainActor
final class MochiDockAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    private let model: PetInteractionModel
    private let panelController: PetPanelController
    private let loginItemService: any LoginItemServicing
    private let applicationActivator: any ApplicationActivating
    let reminderCenter: ReminderCenter
    private(set) var loginItemStatus: LoginItemStatus
    private(set) var loginItemOutcome: LocalizedStringResource?
    private(set) lazy var settingsWindowController = SettingsWindowController(appDelegate: self)

    override init() {
        let model = PetInteractionModel()
        let loginItemService = LoginItemService()
        let reminderCenter = ReminderCenter()
        self.model = model
        self.panelController = PetPanelController(model: model)
        self.loginItemService = loginItemService
        self.applicationActivator = NSApplication.shared
        self.reminderCenter = reminderCenter
        self.loginItemStatus = loginItemService.status
        super.init()
        panelController.connectReminderCenter(reminderCenter)
    }

    init(model: PetInteractionModel, panelController: PetPanelController) {
        let loginItemService = LoginItemService()
        let reminderCenter = Self.makeTransientReminderCenter()
        self.model = model
        self.panelController = panelController
        self.loginItemService = loginItemService
        self.applicationActivator = NSApplication.shared
        self.reminderCenter = reminderCenter
        self.loginItemStatus = loginItemService.status
        super.init()
        panelController.connectReminderCenter(reminderCenter)
    }

    init(
        model: PetInteractionModel,
        panelController: PetPanelController,
        loginItemService: any LoginItemServicing,
        applicationActivator: any ApplicationActivating
    ) {
        let reminderCenter = Self.makeTransientReminderCenter()
        self.model = model
        self.panelController = panelController
        self.loginItemService = loginItemService
        self.applicationActivator = applicationActivator
        self.reminderCenter = reminderCenter
        self.loginItemStatus = loginItemService.status
        super.init()
        panelController.connectReminderCenter(reminderCenter)
    }

    var displaySize: PetDisplaySize { model.displaySize }
    var isProximityResponseEnabled: Bool { model.isProximityResponseEnabled }
    var isLoginItemEnabled: Bool { loginItemStatus == .enabled }
    var petVisibilityActionTitle: LocalizedStringResource {
        panelController.isPetVisible ? "Hide Pet" : "Show Pet"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceCenter.addObserver(
            self,
            selector: #selector(applicationWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        workspaceCenter.addObserver(
            self,
            selector: #selector(applicationDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        showPet()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func showPet() {
        panelController.showPet()
        objectWillChange.send()
    }

    func selectDisplaySize(_ size: PetDisplaySize) {
        guard displaySize != size else { return }
        panelController.selectDisplaySize(size)
        objectWillChange.send()
    }

    func setProximityResponseEnabled(_ enabled: Bool) {
        panelController.setProximityResponseEnabled(enabled)
        objectWillChange.send()
    }

    func refreshLoginItemStatus() {
        loginItemStatus = loginItemService.status
        loginItemOutcome = outcome(for: loginItemStatus)
        objectWillChange.send()
    }

    func setLoginItemEnabled(_ enabled: Bool) {
        var failed = false
        do {
            try loginItemService.setEnabled(enabled)
        } catch {
            failed = true
        }
        loginItemStatus = loginItemService.status
        loginItemOutcome = failed
            ? "Couldn’t update Start at Login."
            : outcome(for: loginItemStatus)
        objectWillChange.send()
    }

    func openSettings() {
        refreshLoginItemStatus()
        applicationActivator.activate()
        settingsWindowController.showWindow(nil)
        settingsWindowController.window?.makeKeyAndOrderFront(nil)
    }

    func togglePetVisibility() {
        panelController.togglePetVisibility()
        objectWillChange.send()
    }

    @objc func applicationWillSleep() { reminderCenter.willSleep() }
    @objc func applicationDidWake() { reminderCenter.didWake() }

    private static func makeTransientReminderCenter() -> ReminderCenter {
        let clock = SystemReminderClock()
        return ReminderCenter(
            clock: clock,
            scheduler: DispatchReminderScheduler(now: { clock.now }),
            persistence: VolatileReminderPersistence()
        )
    }

    private func outcome(for status: LoginItemStatus) -> LocalizedStringResource? {
        switch status {
        case .requiresApproval:
            "Allow MochiDock in System Settings > General > Login Items."
        case .notFound:
            "MochiDock’s login item is unavailable."
        case .notRegistered, .enabled:
            nil
        }
    }
}
