import AppKit

@MainActor
protocol PetPanelFrameAnimating: AnyObject {
    func animate(panel: NSPanel, to frame: NSRect, completion: @escaping () -> Void)
    func cancel(panel: NSPanel)
}

@MainActor
final class AppKitPetPanelFrameAnimator: PetPanelFrameAnimating {
    static let duration: TimeInterval = 0.22
    private var generation = 0

    func animate(panel: NSPanel, to frame: NSRect, completion: @escaping () -> Void) {
        generation += 1
        let animationGeneration = generation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        } completionHandler: {
            MainActor.assumeIsolated {
                guard self.generation == animationGeneration else { return }
                completion()
            }
        }
    }

    func cancel(panel: NSPanel) {
        generation += 1
        panel.setFrame(panel.frame, display: true, animate: false)
    }
}
