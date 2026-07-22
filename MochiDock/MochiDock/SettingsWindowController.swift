import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    static let contentSize = NSSize(width: 760, height: 500)

    init(appDelegate: MochiDockAppDelegate) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.contentSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "MochiDock Settings")
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        window.contentMinSize = Self.contentSize
        window.contentView = NSHostingView(rootView: SettingsView(appDelegate: appDelegate))
        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
