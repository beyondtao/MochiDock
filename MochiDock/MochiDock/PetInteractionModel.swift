import Observation
import SwiftUI

enum PetMood: Equatable {
    case resting
    case happy

    var accessibilityValue: LocalizedStringResource {
        switch self {
        case .resting: "Resting"
        case .happy: "Happy"
        }
    }
}

@MainActor
@Observable
final class PetInteractionModel {
    private(set) var mood: PetMood = .resting
    private(set) var displaySize: PetDisplaySize
    private(set) var animationState: PetAnimationState = .idle

    let timing: PetAnimationTiming
    private let scheduler: any PetAnimationScheduling
    private let preferences: any PetPreferencesStoring
    private var scheduledTask: (any PetAnimationScheduledTask)?
    private var isPlaybackActive = false

    init() {
        self.scheduler = DispatchPetAnimationScheduler()
        self.timing = .standard
        let preferences = UserDefaultsPetPreferences()
        self.preferences = preferences
        self.displaySize = Self.restoredDisplaySize(from: preferences)
    }

    init(preferences: any PetPreferencesStoring) {
        self.scheduler = DispatchPetAnimationScheduler()
        self.timing = .standard
        self.preferences = preferences
        self.displaySize = Self.restoredDisplaySize(from: preferences)
    }

    init(
        scheduler: any PetAnimationScheduling,
        preferences: any PetPreferencesStoring
    ) {
        self.scheduler = scheduler
        self.timing = .standard
        self.preferences = preferences
        self.displaySize = Self.restoredDisplaySize(from: preferences)
    }

    init(
        scheduler: any PetAnimationScheduling,
        timing: PetAnimationTiming,
        preferences: any PetPreferencesStoring
    ) {
        self.scheduler = scheduler
        self.timing = timing
        self.preferences = preferences
        self.displaySize = Self.restoredDisplaySize(from: preferences)
    }

    var horizontalScale: CGFloat { 1 }
    var verticalScale: CGFloat {
        animationState == .breathingIn ? timing.breathingPeakScale : 1
    }
    var scaleAnchor: UnitPoint { .bottom }
    var responseScale: CGFloat { animationState == .responding ? 1.03 : 1 }
    var responseOffset: CGFloat { animationState == .responding ? -2 : 0 }
    var transitionDuration: TimeInterval {
        switch animationState {
        case .breathingIn: timing.breathingRise
        case .breathingOut: timing.breathingFall
        case .responding: timing.responseDuration
        case .recovering: timing.recoveryDuration
        case .idle: 0
        }
    }

    func startPlayback() {
        guard !isPlaybackActive else { return }
        isPlaybackActive = true
        if mood == .happy {
            animationState = .responding
            schedule(after: timing.responseDuration) { model in
                model.beginRecovery()
            }
            return
        }
        returnToIdleAndScheduleBreathing()
    }

    func stopPlayback() {
        isPlaybackActive = false
        cancelScheduledTransition()
        animationState = .idle
    }

    func handleClick() {
        guard animationState != .responding, animationState != .recovering else { return }
        cancelScheduledTransition()
        mood = .happy
        animationState = .responding
        schedule(after: timing.responseDuration) { model in
            model.beginRecovery()
        }
    }

    func selectDisplaySize(_ size: PetDisplaySize) {
        displaySize = size
        preferences.set(size.rawValue, forKey: PetPreferenceKey.displaySize)
    }

    private static func restoredDisplaySize(
        from preferences: any PetPreferencesStoring
    ) -> PetDisplaySize {
        guard let storedValue = preferences.string(forKey: PetPreferenceKey.displaySize) else {
            return .medium
        }
        return PetDisplaySize(rawValue: storedValue) ?? .medium
    }

    private func beginBreathing() {
        animationState = .breathingIn
        schedule(after: timing.breathingRise) { model in
            model.endBreathingRise()
        }
    }

    private func endBreathingRise() {
        animationState = .breathingOut
        schedule(after: timing.breathingFall) { model in
            model.returnToIdleAndScheduleBreathing()
        }
    }

    private func beginRecovery() {
        mood = .resting
        animationState = .recovering
        schedule(after: timing.recoveryDuration) { model in
            model.returnToIdleAndScheduleBreathing()
        }
    }

    private func returnToIdleAndScheduleBreathing() {
        mood = .resting
        animationState = .idle
        guard isPlaybackActive else { return }
        schedule(after: timing.idlePause) { model in
            model.beginBreathing()
        }
    }

    private func schedule(
        after delay: TimeInterval,
        transition: @escaping @MainActor (PetInteractionModel) -> Void
    ) {
        cancelScheduledTransition()
        scheduledTask = scheduler.schedule(after: delay) { [weak self] in
            guard let self else { return }
            scheduledTask = nil
            transition(self)
        }
    }

    private func cancelScheduledTransition() {
        scheduledTask?.cancel()
        scheduledTask = nil
    }
}
