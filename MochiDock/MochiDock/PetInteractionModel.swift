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
    private(set) var isProximityResponseEnabled: Bool
    private(set) var animationState: PetAnimationState = .idle
    private(set) var visualState: PetVisualState = .idle

    let timing: PetAnimationTiming
    private let scheduler: any PetAnimationScheduling
    private let preferences: any PetPreferencesStoring
    private var scheduledTask: (any PetAnimationScheduledTask)?
    private var isPlaybackActive = false
    private var completedBreathingCycles = 0

    var preferencesStore: any PetPreferencesStoring { preferences }

    init() {
        self.scheduler = DispatchPetAnimationScheduler()
        self.timing = .standard
        let preferences = UserDefaultsPetPreferences()
        self.preferences = preferences
        self.displaySize = Self.restoredDisplaySize(from: preferences)
        self.isProximityResponseEnabled = Self.restoredProximityResponseEnabled(from: preferences)
    }

    init(preferences: any PetPreferencesStoring) {
        self.scheduler = DispatchPetAnimationScheduler()
        self.timing = .standard
        self.preferences = preferences
        self.displaySize = Self.restoredDisplaySize(from: preferences)
        self.isProximityResponseEnabled = Self.restoredProximityResponseEnabled(from: preferences)
    }

    init(
        scheduler: any PetAnimationScheduling,
        preferences: any PetPreferencesStoring
    ) {
        self.scheduler = scheduler
        self.timing = .standard
        self.preferences = preferences
        self.displaySize = Self.restoredDisplaySize(from: preferences)
        self.isProximityResponseEnabled = Self.restoredProximityResponseEnabled(from: preferences)
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
        self.isProximityResponseEnabled = Self.restoredProximityResponseEnabled(from: preferences)
    }

    var horizontalScale: CGFloat {
        animationState == .anticipatingResponse ? 1.02 : 1
    }
    var verticalScale: CGFloat {
        switch animationState {
        case .breathingIn: timing.breathingPeakScale
        case .anticipatingResponse: 0.94
        case .jumpingUp: 1.04
        case .falling: 1.015
        case .attentionTail: 1.01
        case .attentionBase: 1.005
        default: 1
        }
    }
    var scaleAnchor: UnitPoint { .bottom }
    var responseOffset: CGFloat {
        switch animationState {
        case .jumpingUp: -displaySize.pointLength * 0.08
        case .falling: -displaySize.pointLength * 0.02
        case .attentionTail, .attentionBase: -displaySize.pointLength * 0.01
        default: 0
        }
    }
    var transitionDuration: TimeInterval {
        switch animationState {
        case .breathingIn: timing.breathingRise
        case .breathingOut: timing.breathingFall
        case .blinkingHalfClosed, .blinkingClosed, .blinkingHalfOpen:
            timing.blinkFrameDuration
        case .anticipatingResponse: timing.responseAnticipation
        case .jumpingUp: timing.responseRise
        case .falling: timing.responseFall
        case .recovering: timing.recoveryDuration
        case .attentionTail: timing.attentionTailDuration
        case .attentionBase: timing.attentionBaseDuration
        case .idle: 0
        }
    }

    func startPlayback() {
        guard !isPlaybackActive else { return }
        isPlaybackActive = true
        returnToIdleAndScheduleNextAction()
    }

    func stopPlayback() {
        isPlaybackActive = false
        cancelScheduledTransition()
        animationState = .idle
        visualState = .idle
        mood = .resting
        completedBreathingCycles = 0
    }

    func handleClick() {
        guard !isResponseInProgress else { return }
        cancelScheduledTransition()
        mood = .happy
        visualState = .happy
        animationState = .anticipatingResponse
        schedule(after: timing.responseAnticipation) { model in
            model.beginJump()
        }
    }

    @discardableResult
    func handleProximityEntry() -> Bool {
        guard isProximityResponseEnabled,
              isPlaybackActive,
              !isResponseInProgress,
              !isAttentionInProgress else {
            return false
        }
        cancelScheduledTransition()
        mood = .resting
        visualState = .attentionTail
        animationState = .attentionTail
        schedule(after: timing.attentionTailDuration) { model in
            model.visualState = .attentionBase
            model.animationState = .attentionBase
            model.schedule(after: model.timing.attentionBaseDuration) { model in
                model.completedBreathingCycles = 0
                model.returnToIdleAndScheduleNextAction()
            }
        }
        return true
    }

    func selectDisplaySize(_ size: PetDisplaySize) {
        displaySize = size
        preferences.set(size.rawValue, forKey: PetPreferenceKey.displaySize)
    }

    func setProximityResponseEnabled(_ enabled: Bool) {
        let changed = isProximityResponseEnabled != enabled
        isProximityResponseEnabled = enabled
        preferences.set(String(enabled), forKey: PetPreferenceKey.proximityResponseEnabled)
        guard changed else { return }
        guard !enabled, isAttentionInProgress else { return }
        cancelScheduledTransition()
        completedBreathingCycles = 0
        returnToIdleAndScheduleNextAction()
    }

    private static func restoredDisplaySize(
        from preferences: any PetPreferencesStoring
    ) -> PetDisplaySize {
        guard let storedValue = preferences.string(forKey: PetPreferenceKey.displaySize) else {
            return .medium
        }
        return PetDisplaySize(rawValue: storedValue) ?? .medium
    }

    private static func restoredProximityResponseEnabled(
        from preferences: any PetPreferencesStoring
    ) -> Bool {
        guard let storedValue = preferences.string(
            forKey: PetPreferenceKey.proximityResponseEnabled
        ) else {
            return true
        }
        switch storedValue {
        case "true": return true
        case "false": return false
        default: return true
        }
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
            model.completedBreathingCycles += 1
            model.returnToIdleAndScheduleNextAction()
        }
    }

    private func beginBlink() {
        visualState = .halfBlink
        animationState = .blinkingHalfClosed
        schedule(after: timing.blinkFrameDuration) { model in
            model.visualState = .fullBlink
            model.animationState = .blinkingClosed
            model.schedule(after: model.timing.blinkFrameDuration) { model in
                model.visualState = .halfBlink
                model.animationState = .blinkingHalfOpen
                model.schedule(after: model.timing.blinkFrameDuration) { model in
                    model.completedBreathingCycles = 0
                    model.returnToIdleAndScheduleNextAction()
                }
            }
        }
    }

    private func beginJump() {
        animationState = .jumpingUp
        schedule(after: timing.responseRise) { model in
            model.beginFall()
        }
    }

    private func beginFall() {
        animationState = .falling
        schedule(after: timing.responseFall) { model in
            model.beginRecovery()
        }
    }

    private func beginRecovery() {
        animationState = .recovering
        schedule(after: timing.recoveryDuration) { model in
            model.completedBreathingCycles = 0
            model.returnToIdleAndScheduleNextAction()
        }
    }

    private func returnToIdleAndScheduleNextAction() {
        mood = .resting
        visualState = .idle
        animationState = .idle
        guard isPlaybackActive else { return }
        schedule(after: timing.idlePause) { model in
            if model.completedBreathingCycles >= model.timing.breathingCyclesPerBlink {
                model.beginBlink()
            } else {
                model.beginBreathing()
            }
        }
    }

    private var isResponseInProgress: Bool {
        switch animationState {
        case .anticipatingResponse, .jumpingUp, .falling, .recovering: true
        default: false
        }
    }

    private var isAttentionInProgress: Bool {
        switch animationState {
        case .attentionTail, .attentionBase: true
        default: false
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
