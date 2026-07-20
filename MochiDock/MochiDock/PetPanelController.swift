import AppKit
import SwiftUI

@MainActor
final class PetPanelController {
    private let model: PetInteractionModel
    private var proximityDetector: (any PointerProximityDetecting)!
    private(set) var panel: NSPanel?

    var isPetVisible: Bool {
        panel?.isVisible == true
    }

    init(model: PetInteractionModel) {
        self.model = model
        self.proximityDetector = nil
        self.proximityDetector = PointerProximityDetector(
            scheduler: DispatchPetAnimationScheduler(),
            pointerLocation: { NSEvent.mouseLocation },
            now: { ProcessInfo.processInfo.systemUptime },
            panelFrame: { [weak self] in self?.panel?.frame ?? .zero },
            onEligibleEntry: { [weak model] in model?.handleProximityEntry() ?? false }
        )
    }

    init(
        model: PetInteractionModel,
        proximityDetector: any PointerProximityDetecting
    ) {
        self.model = model
        self.proximityDetector = proximityDetector
    }

    func showPet() {
        let panel = panel ?? makePanel()
        panel.orderFrontRegardless()
        model.startPlayback()
        proximityDetector.start()
    }

    func hidePet() {
        proximityDetector.stop()
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
        let panel = PetPanel(
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
        panel.onPointerContactChanged = { [weak self] isDown in
            self?.proximityDetector.setDragging(isDown)
        }
        panel.center()
        self.panel = panel
        return panel
    }
}

@MainActor
final class PetPanel: NSPanel {
    var onPointerContactChanged: ((Bool) -> Void)?

    func pointerContactChanged(_ isDown: Bool) {
        onPointerContactChanged?(isDown)
    }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            pointerContactChanged(true)
        case .leftMouseUp:
            pointerContactChanged(false)
        default:
            break
        }
        super.sendEvent(event)
    }
}
