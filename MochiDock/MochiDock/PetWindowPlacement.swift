import CoreGraphics

struct PetWindowPlacement {
    func safeFrame(for proposedFrame: CGRect, visibleFrames: [CGRect]) -> CGRect? {
        guard !visibleFrames.isEmpty else { return nil }
        if visibleFrames.contains(where: { $0.contains(proposedFrame) }) {
            return proposedFrame
        }

        let target = visibleFrames.min { lhs, rhs in
            squaredDistance(from: proposedFrame.center, to: lhs)
                < squaredDistance(from: proposedFrame.center, to: rhs)
        }!
        return CGRect(
            x: clamped(proposedFrame.minX, lower: target.minX, upper: target.maxX - proposedFrame.width),
            y: clamped(proposedFrame.minY, lower: target.minY, upper: target.maxY - proposedFrame.height),
            width: proposedFrame.width,
            height: proposedFrame.height
        )
    }

    private func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let nearestX = clamped(point.x, lower: rect.minX, upper: rect.maxX)
        let nearestY = clamped(point.y, lower: rect.minY, upper: rect.maxY)
        let deltaX = point.x - nearestX
        let deltaY = point.y - nearestY
        return deltaX * deltaX + deltaY * deltaY
    }

    private func clamped(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return lower }
        return min(max(value, lower), upper)
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
