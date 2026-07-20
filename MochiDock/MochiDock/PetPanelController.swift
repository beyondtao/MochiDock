import AppKit
import SwiftUI

@MainActor
final class PetPanelController {
    private let model: PetInteractionModel
    private(set) var panel: NSPanel?

    var isPetVisible: Bool {
        panel?.isVisible == true
    }

    init(model: PetInteractionModel) {
        self.model = model
    }

    func showPet() {
        let panel = panel ?? makePanel()
        panel.orderFrontRegardless()
        model.startPlayback()
    }

    func hidePet() {
        panel?.orderOut(nil)
        model.stopPlayback()
    }

    func togglePetVisibility() {
        if isPetVisible {
            hidePet()
        } else {
            showPet()
        }
    }

    func selectDisplaySize(_ size: PetDisplaySize) {
        guard model.displaySize != size else { return }

        guard let panel else {
            withTransaction(PetRenderPolicy.displaySizeTransaction) {
                model.selectDisplaySize(size)
            }
            return
        }

        let center = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        let length = size.pointLength
        let frame = NSRect(
            x: center.x - length / 2,
            y: center.y - length / 2,
            width: length,
            height: length
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            withTransaction(PetRenderPolicy.displaySizeTransaction) {
                model.selectDisplaySize(size)
                panel.setFrame(frame, display: false, animate: false)
                panel.contentView?.layoutSubtreeIfNeeded()
            }
        }
        panel.displayIfNeeded()
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
        panel.animationBehavior = NSWindow.AnimationBehavior.none
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: PetView(model: model))
        panel.center()
        self.panel = panel
        return panel
    }
}
