//
//  MochiDockApp.swift
//  MochiDock
//
//  Created by Scott on 2026/7/18.
//

import AppKit
import Combine
import SwiftUI

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
        Button(appDelegate.petVisibilityActionTitle) {
            appDelegate.togglePetVisibility()
        }

        Picker(
            "Pet Size",
            selection: Binding(
                get: { appDelegate.displaySize },
                set: { appDelegate.selectDisplaySize($0) }
            )
        ) {
            ForEach(PetDisplaySize.allCases) { size in
                Text(size.menuTitle).tag(size)
            }
        }

        Divider()

        Button("Quit MochiDock") {
            NSApplication.shared.terminate(nil)
        }
    }
}

@MainActor
final class MochiDockAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    private let model: PetInteractionModel
    private let panelController: PetPanelController

    override init() {
        let model = PetInteractionModel()
        self.model = model
        self.panelController = PetPanelController(model: model)
        super.init()
    }

    init(model: PetInteractionModel, panelController: PetPanelController) {
        self.model = model
        self.panelController = panelController
        super.init()
    }

    var displaySize: PetDisplaySize { model.displaySize }
    var petVisibilityActionTitle: String {
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
        panelController.selectDisplaySize(size)
    }

    func togglePetVisibility() {
        panelController.togglePetVisibility()
        objectWillChange.send()
    }
}
