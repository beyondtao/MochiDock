import AppKit

@MainActor
final class PetPanel: NSPanel {
    var onPointerContactChanged: ((Bool) -> Void)?
    var onFrameChanged: (() -> Void)?
    private var dragStartScreenLocation: NSPoint?
    private var dragStartFrame: NSRect?

    func pointerContactChanged(_ isDown: Bool) {
        onPointerContactChanged?(isDown)
    }

    func cancelApplicationDrag() {
        dragStartScreenLocation = nil
        dragStartFrame = nil
    }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            let pointerScreenLocation = screenLocation(of: event)
            pointerContactChanged(true)
            dragStartScreenLocation = pointerScreenLocation
            dragStartFrame = frame
        case .leftMouseDragged:
            guard let dragStartScreenLocation, let dragStartFrame else { return }
            let currentLocation = screenLocation(of: event)
            let delta = NSPoint(
                x: currentLocation.x - dragStartScreenLocation.x,
                y: currentLocation.y - dragStartScreenLocation.y
            )
            setFrameOrigin(NSPoint(
                x: dragStartFrame.origin.x + delta.x,
                y: dragStartFrame.origin.y + delta.y
            ))
            onFrameChanged?()
        case .leftMouseUp:
            guard dragStartFrame != nil else { return }
            pointerContactChanged(false)
            cancelApplicationDrag()
        default:
            break
        }
        super.sendEvent(event)
    }

    private func screenLocation(of event: NSEvent) -> NSPoint {
        convertPoint(toScreen: event.locationInWindow)
    }
}
