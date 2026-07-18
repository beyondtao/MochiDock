//
//  MochiDockApp.swift
//  MochiDock
//
//  Created by Scott on 2026/7/18.
//

import AppKit
import SwiftUI

@main
struct MochiDockApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: MochiDockAppDelegate

    var body: some Scene {
        MenuBarExtra("MochiDock", systemImage: "pawprint.fill") {
            Button("Show Pet") {
                appDelegate.showPet()
            }

            Divider()

            Button("Quit MochiDock") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

@MainActor
final class MochiDockAppDelegate: NSObject, NSApplicationDelegate {
    private let model = PetInteractionModel()
    private lazy var panelController = PetPanelController(model: model)

    func applicationDidFinishLaunching(_ notification: Notification) {
        showPet()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func showPet() {
        panelController.showPet()
    }
}
