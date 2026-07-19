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
}

@MainActor
final class MochiDockAppDelegate: NSObject, NSApplicationDelegate {
    private let model = PetInteractionModel()
    private lazy var panelController = PetPanelController(model: model)

    var displaySize: PetDisplaySize { model.displaySize }

    func applicationDidFinishLaunching(_ notification: Notification) {
        showPet()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func showPet() {
        panelController.showPet()
    }

    func selectDisplaySize(_ size: PetDisplaySize) {
        panelController.selectDisplaySize(size)
    }
}
