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
    private(set) var loginItemStatus: LoginItemStatus
    private(set) var loginItemOutcome: LocalizedStringResource?
    private(set) lazy var settingsWindowController = SettingsWindowController(appDelegate: self)

    override init() {
        let model = PetInteractionModel()
        let loginItemService = LoginItemService()
        self.model = model
        self.panelController = PetPanelController(model: model)
        self.loginItemService = loginItemService
        self.applicationActivator = NSApplication.shared
        self.loginItemStatus = loginItemService.status
        super.init()
    }

    init(model: PetInteractionModel, panelController: PetPanelController) {
        let loginItemService = LoginItemService()
        self.model = model
        self.panelController = panelController
        self.loginItemService = loginItemService
        self.applicationActivator = NSApplication.shared
        self.loginItemStatus = loginItemService.status
        super.init()
    }

    init(
        model: PetInteractionModel,
        panelController: PetPanelController,
        loginItemService: any LoginItemServicing,
        applicationActivator: any ApplicationActivating
    ) {
        self.model = model
        self.panelController = panelController
        self.loginItemService = loginItemService
        self.applicationActivator = applicationActivator
        self.loginItemStatus = loginItemService.status
        super.init()
    }

    var displaySize: PetDisplaySize { model.displaySize }
    var isProximityResponseEnabled: Bool { model.isProximityResponseEnabled }
    var isLoginItemEnabled: Bool { loginItemStatus == .enabled }
    var petVisibilityActionTitle: LocalizedStringResource {
        panelController.isPetVisible ? "Hide Pet" : "Show Pet"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
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
