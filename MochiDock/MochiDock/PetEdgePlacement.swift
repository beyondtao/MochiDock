import CoreGraphics

nonisolated enum PetScreenEdge: Equatable {
    case left
    case right
}

nonisolated struct PetEdgePlacement {
    static let triggerBand: CGFloat = 24
    static let visibleWidthRatio: CGFloat = 0.35
    static let minimumVisibleWidth: CGFloat = 32

    func eligibleEdge(for fullFrame: CGRect, visibleFrames: [CGRect]) -> PetScreenEdge? {
        guard let visibleFrame = visibleFrames.first(where: { $0.contains(fullFrame) }) else {
            return nil
        }

        let leftDistance = fullFrame.minX - visibleFrame.minX
        if leftDistance <= Self.triggerBand,
           isExternal(.left, of: visibleFrame, panelFrame: fullFrame, visibleFrames: visibleFrames) {
            return .left
        }

        let rightDistance = visibleFrame.maxX - fullFrame.maxX
        if rightDistance <= Self.triggerBand,
           isExternal(.right, of: visibleFrame, panelFrame: fullFrame, visibleFrames: visibleFrames) {
            return .right
        }

        return nil
    }

    func peekFrame(
        for fullFrame: CGRect,
        edge: PetScreenEdge,
        visibleFrame: CGRect
    ) -> CGRect {
        let visibleWidth = max(fullFrame.width * Self.visibleWidthRatio, Self.minimumVisibleWidth)
        let x: CGFloat
        switch edge {
        case .left:
            x = visibleFrame.minX - (fullFrame.width - visibleWidth)
        case .right:
            x = visibleFrame.maxX - visibleWidth
        }
        return CGRect(x: x, y: fullFrame.minY, width: fullFrame.width, height: fullFrame.height)
    }

    func fullFrame(from peekFrame: CGRect, restoring fullFrame: CGRect) -> CGRect {
        fullFrame
    }

    private func isExternal(
        _ edge: PetScreenEdge,
        of visibleFrame: CGRect,
        panelFrame: CGRect,
        visibleFrames: [CGRect]
    ) -> Bool {
        !visibleFrames.contains { candidate in
            guard candidate != visibleFrame,
                  candidate.minY < panelFrame.maxY,
                  candidate.maxY > panelFrame.minY else {
                return false
            }
            switch edge {
            case .left:
                return abs(candidate.maxX - visibleFrame.minX) <= 1
            case .right:
                return abs(candidate.minX - visibleFrame.maxX) <= 1
            }
        }
    }
}
