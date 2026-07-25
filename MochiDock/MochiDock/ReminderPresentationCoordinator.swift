import Foundation

@MainActor
final class ReminderPresentationCoordinator {
    static let bubbleDuration: TimeInterval = 8

    private let scheduler: any PetAnimationScheduling
    private let showBubble: () -> Void
    private let hideBubble: () -> Void
    private let relayoutBubble: () -> Void
    private let playReminderAnimation: () -> Void
    private let restoreFromPeek: (@escaping () -> Void) -> Void
    private var collapseTask: (any PetAnimationScheduledTask)?
    private var isDragging = false
    private var isOrdinaryResponseActive = false
    private var isPeeking = false
    private var isRestoringFromPeek = false
    private var hasPlayedAnimation = false

    private(set) var isPending = false
    private(set) var isBubbleVisible = false

    var suppressesEdgeRetreat: Bool { isPending }
    var suppressesDecorativeProximity: Bool { isPending }

    init(
        scheduler: any PetAnimationScheduling,
        showBubble: @escaping () -> Void,
        hideBubble: @escaping () -> Void,
        relayoutBubble: @escaping () -> Void,
        playReminderAnimation: @escaping () -> Void,
        restoreFromPeek: @escaping (@escaping () -> Void) -> Void
    ) {
        self.scheduler = scheduler
        self.showBubble = showBubble
        self.hideBubble = hideBubble
        self.relayoutBubble = relayoutBubble
        self.playReminderAnimation = playReminderAnimation
        self.restoreFromPeek = restoreFromPeek
    }

    func reminderBecamePending(
        petVisible: Bool,
        isDragging: Bool,
        isOrdinaryResponseActive: Bool,
        isPeeking: Bool
    ) {
        guard !isPending else { return }
        isPending = true
        hasPlayedAnimation = false
        self.isDragging = isDragging
        self.isOrdinaryResponseActive = isOrdinaryResponseActive
        self.isPeeking = isPeeking
        guard petVisible else { return }
        presentIfUnblocked(petVisible: true)
    }

    func dragDidEnd(petVisible: Bool) {
        guard isPending, isDragging else { return }
        isDragging = false
        presentIfUnblocked(petVisible: petVisible)
    }

    func ordinaryResponseDidEnd(petVisible: Bool) {
        guard isPending, isOrdinaryResponseActive else { return }
        isOrdinaryResponseActive = false
        presentIfUnblocked(petVisible: petVisible)
    }

    @discardableResult
    func handlePetClick() -> Bool {
        guard isPending else { return false }
        if !isBubbleVisible { showPendingBubble() }
        return true
    }

    func petDidHide() {
        guard isPending else { return }
        collapseTask?.cancel()
        collapseTask = nil
        if isBubbleVisible { hideBubble() }
        isBubbleVisible = false
        isDragging = false
        isOrdinaryResponseActive = false
    }

    func petDidShow() {
        guard isPending else { return }
        presentIfUnblocked(petVisible: true)
    }

    func petGeometryDidChange() {
        if isBubbleVisible { relayoutBubble() }
    }

    func pendingWasResolved() {
        collapseTask?.cancel()
        collapseTask = nil
        if isBubbleVisible { hideBubble() }
        isPending = false
        isBubbleVisible = false
        isDragging = false
        isOrdinaryResponseActive = false
        isPeeking = false
        isRestoringFromPeek = false
        hasPlayedAnimation = false
    }

    private func presentIfUnblocked(petVisible: Bool) {
        guard isPending,
              petVisible,
              !isDragging,
              !isOrdinaryResponseActive,
              !isRestoringFromPeek else { return }
        if isPeeking {
            isRestoringFromPeek = true
            restoreFromPeek { [weak self] in
                guard let self, isPending else { return }
                isRestoringFromPeek = false
                isPeeking = false
                present()
            }
        } else if hasPlayedAnimation {
            if !isBubbleVisible { showPendingBubble() }
        } else {
            present()
        }
    }

    private func present() {
        guard isPending else { return }
        if !hasPlayedAnimation {
            hasPlayedAnimation = true
            playReminderAnimation()
        }
        showPendingBubble()
    }

    private func showPendingBubble() {
        collapseTask?.cancel()
        showBubble()
        isBubbleVisible = true
        collapseTask = scheduler.schedule(after: Self.bubbleDuration) { [weak self] in
            guard let self, isPending, isBubbleVisible else { return }
            collapseTask = nil
            hideBubble()
            isBubbleVisible = false
        }
    }
}
