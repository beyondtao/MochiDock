import AppKit
import SwiftUI

@MainActor
final class PetPanelController {
    private let model: PetInteractionModel
    private(set) var panel: NSPanel?

    init(model: PetInteractionModel) {
        self.model = model
    }

    func showPet() {
        let panel = panel ?? makePanel()
        panel.orderFrontRegardless()
    }

    func hidePet() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 128, height: 128),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: PetView(model: model))
        panel.center()
        self.panel = panel
        return panel
    }
}
