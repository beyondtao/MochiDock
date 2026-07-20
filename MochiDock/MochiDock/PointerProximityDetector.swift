import CoreGraphics
import Foundation

struct PointerProximityThresholds: Equatable {
    let enterInset: CGFloat
    let exitInset: CGFloat
}

struct PointerProximityTiming: Equatable {
    let sampleInterval: TimeInterval
    let enterInsetRatio: CGFloat
    let exitInsetRatio: CGFloat
    let cooldown: TimeInterval

    static let standard = PointerProximityTiming(
        sampleInterval: 0.15,
        enterInsetRatio: 0.30,
        exitInsetRatio: 0.45,
        cooldown: 4.0
    )

    func thresholds(for panelFrame: CGRect) -> PointerProximityThresholds {
        let referenceLength = min(panelFrame.width, panelFrame.height)
        return PointerProximityThresholds(
            enterInset: referenceLength * enterInsetRatio,
            exitInset: referenceLength * exitInsetRatio
        )
    }
}

@MainActor
protocol PointerProximityDetecting: AnyObject {
    func start()
    func stop()
    func setDragging(_ dragging: Bool)
}

@MainActor
final class PointerProximityDetector: PointerProximityDetecting {
    typealias PointerLocation = @MainActor () -> CGPoint
    typealias CurrentTime = @MainActor () -> TimeInterval
    typealias PanelFrame = @MainActor () -> CGRect
    typealias EligibleEntry = @MainActor () -> Bool

    private let scheduler: any PetAnimationScheduling
    private let timing: PointerProximityTiming
    private let pointerLocation: PointerLocation
    private let now: CurrentTime
    private let panelFrame: PanelFrame
    private let onEligibleEntry: EligibleEntry

    private var samplingTask: (any PetAnimationScheduledTask)?
    private var isRunning = false
    private var isDragging = false
    private var isArmedOutside = false
    private var lastTriggerTime: TimeInterval?

    init(
        scheduler: any PetAnimationScheduling,
        timing: PointerProximityTiming,
        pointerLocation: @escaping PointerLocation,
        now: @escaping CurrentTime,
        panelFrame: @escaping PanelFrame,
        onEligibleEntry: @escaping EligibleEntry
    ) {
        self.scheduler = scheduler
        self.timing = timing
        self.pointerLocation = pointerLocation
        self.now = now
        self.panelFrame = panelFrame
        self.onEligibleEntry = onEligibleEntry
    }

    convenience init(
        scheduler: any PetAnimationScheduling,
        pointerLocation: @escaping PointerLocation,
        now: @escaping CurrentTime,
        panelFrame: @escaping PanelFrame,
        onEligibleEntry: @escaping EligibleEntry
    ) {
        self.init(
            scheduler: scheduler,
            timing: .standard,
            pointerLocation: pointerLocation,
            now: now,
            panelFrame: panelFrame,
            onEligibleEntry: onEligibleEntry
        )
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isArmedOutside = false
        scheduleNextSample()
    }

    func stop() {
        isRunning = false
        isDragging = false
        isArmedOutside = false
        samplingTask?.cancel()
        samplingTask = nil
    }

    func setDragging(_ dragging: Bool) {
        guard isRunning else { return }
        isDragging = dragging
        if !dragging {
            let thresholds = timing.thresholds(for: panelFrame())
            let exitRegion = panelFrame().insetBy(
                dx: -thresholds.exitInset,
                dy: -thresholds.exitInset
            )
            isArmedOutside = !exitRegion.contains(pointerLocation())
        }
    }

    private func sample() {
        guard isRunning, !isDragging else { return }
        let frame = panelFrame()
        let thresholds = timing.thresholds(for: frame)
        let pointer = pointerLocation()
        let exitRegion = frame.insetBy(dx: -thresholds.exitInset, dy: -thresholds.exitInset)

        if !exitRegion.contains(pointer) {
            isArmedOutside = true
            return
        }

        let enterRegion = frame.insetBy(dx: -thresholds.enterInset, dy: -thresholds.enterInset)
        guard isArmedOutside, enterRegion.contains(pointer) else { return }
        isArmedOutside = false

        let currentTime = now()
        if let lastTriggerTime, currentTime - lastTriggerTime < timing.cooldown {
            return
        }
        if onEligibleEntry() {
            lastTriggerTime = currentTime
        }
    }

    private func scheduleNextSample() {
        guard isRunning else { return }
        samplingTask = scheduler.schedule(after: timing.sampleInterval) { [weak self] in
            guard let self else { return }
            samplingTask = nil
            sample()
            scheduleNextSample()
        }
    }
}
