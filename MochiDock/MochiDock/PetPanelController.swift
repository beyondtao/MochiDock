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

    func selectDisplaySize(_ size: PetDisplaySize) {
        guard model.displaySize != size else { return }

        model.selectDisplaySize(size)
        guard let panel else { return }

        let center = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        let length = size.pointLength
        panel.setFrame(
            NSRect(
                x: center.x - length / 2,
                y: center.y - length / 2,
                width: length,
                height: length
            ),
            display: true,
            animate: false
        )
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: model.displaySize.pointLength,
                height: model.displaySize.pointLength
            ),
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
