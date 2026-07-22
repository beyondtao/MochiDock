import CoreGraphics
import Foundation

@MainActor
enum PetEdgeBehaviorPhase: Equatable {
    case inactive
    case waiting(edge: PetScreenEdge, fullFrame: CGRect, peekFrame: CGRect)
    case peeking(edge: PetScreenEdge, fullFrame: CGRect, peekFrame: CGRect)
    case returning
}

@MainActor
final class PetEdgeBehaviorCoordinator {
    static let retreatDelay: TimeInterval = 6

    private let scheduler: any PetAnimationScheduling
    private let moveToPeek: (CGRect) -> Void
    private let moveToFull: (CGRect, @escaping () -> Void) -> Void
    private let setPeekVisual: (Bool) -> Void
    private let requestClickResponse: () -> Void

    private var waitTask: (any PetAnimationScheduledTask)?
    private var generation = 0
    private var returningFullFrame: CGRect?
    private var requestsClickAfterReturn = false
    private(set) var phase: PetEdgeBehaviorPhase = .inactive

    var fullFrameToRestore: CGRect? {
        switch phase {
        case let .waiting(_, fullFrame, _), let .peeking(_, fullFrame, _):
            fullFrame
        case .returning:
            returningFullFrame
        case .inactive:
            nil
        }
    }

    init(
        scheduler: any PetAnimationScheduling,
        moveToPeek: @escaping (CGRect) -> Void,
        moveToFull: @escaping (CGRect, @escaping () -> Void) -> Void,
        setPeekVisual: @escaping (Bool) -> Void,
        requestClickResponse: @escaping () -> Void
    ) {
        self.scheduler = scheduler
        self.moveToPeek = moveToPeek
        self.moveToFull = moveToFull
        self.setPeekVisual = setPeekVisual
        self.requestClickResponse = requestClickResponse
    }

    func arm(edge: PetScreenEdge, fullFrame: CGRect, peekFrame: CGRect) {
        cancelWait()
        generation += 1
        let armedGeneration = generation
        phase = .waiting(edge: edge, fullFrame: fullFrame, peekFrame: peekFrame)
        waitTask = scheduler.schedule(after: Self.retreatDelay) { [weak self] in
            guard let self,
                  generation == armedGeneration,
                  phase == .waiting(edge: edge, fullFrame: fullFrame, peekFrame: peekFrame) else {
                return
            }
            waitTask = nil
            phase = .peeking(edge: edge, fullFrame: fullFrame, peekFrame: peekFrame)
            setPeekVisual(true)
            moveToPeek(peekFrame)
        }
    }

    func pointerEntered() {
        switch phase {
        case .waiting:
            cancel(restoringFullFrame: false)
        case let .peeking(_, fullFrame, _):
            beginReturn(to: fullFrame, requestClick: false)
        case .inactive, .returning:
            break
        }
    }

    func click() {
        switch phase {
        case .waiting:
            cancel(restoringFullFrame: false)
            requestClickResponse()
        case let .peeking(_, fullFrame, _):
            beginReturn(to: fullFrame, requestClick: true)
        case .inactive:
            requestClickResponse()
        case .returning:
            requestsClickAfterReturn = true
        }
    }

    func beginDrag() {
        cancel(restoringFullFrame: true)
    }

    func cancel(restoringFullFrame: Bool) {
        switch phase {
        case .inactive:
            break
        case .waiting:
            cancelWait()
            generation += 1
            phase = .inactive
        case let .peeking(_, fullFrame, _):
            if restoringFullFrame {
                beginReturn(to: fullFrame, requestClick: false)
            } else {
                generation += 1
                setPeekVisual(false)
                phase = .inactive
            }
        case .returning:
            generation += 1
            returningFullFrame = nil
            requestsClickAfterReturn = false
            setPeekVisual(false)
            phase = .inactive
        }
    }

    private func beginReturn(to fullFrame: CGRect, requestClick: Bool) {
        guard phase != .returning else { return }
        cancelWait()
        generation += 1
        let returnGeneration = generation
        returningFullFrame = fullFrame
        requestsClickAfterReturn = requestClick
        phase = .returning
        moveToFull(fullFrame) { [weak self] in
            guard let self,
                  generation == returnGeneration,
                  phase == .returning,
                  returningFullFrame == fullFrame else {
                return
            }
            let shouldClick = requestsClickAfterReturn
            returningFullFrame = nil
            requestsClickAfterReturn = false
            setPeekVisual(false)
            phase = .inactive
            if shouldClick {
                requestClickResponse()
            }
        }
    }

    private func cancelWait() {
        waitTask?.cancel()
        waitTask = nil
    }
}
