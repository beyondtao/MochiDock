import CoreGraphics

enum ReminderBubblePlacement: Equatable {
    case above
    case below
}

struct ReminderBubbleLayoutResult: Equatable {
    let frame: CGRect
    let placement: ReminderBubblePlacement
    let petFrame: CGRect
}

struct ReminderBubbleLayout {
    static let gap: CGFloat = 12
    static let maximumWidth: CGFloat = 280

    func layout(
        petFrame: CGRect,
        requestedBubbleSize: CGSize,
        visibleFrame: CGRect
    ) -> ReminderBubbleLayoutResult {
        let visibleFrame = visibleFrame.standardized
        let size = CGSize(
            width: min(
                visibleFrame.width,
                min(Self.maximumWidth, max(0, requestedBubbleSize.width))
            ),
            height: min(visibleFrame.height, max(0, requestedBubbleSize.height))
        )
        let centeredX = petFrame.midX - size.width / 2
        let x = min(max(centeredX, visibleFrame.minX), visibleFrame.maxX - size.width)
        let aboveY = petFrame.maxY + Self.gap
        let fitsAbove = aboveY + size.height <= visibleFrame.maxY
        let preferredY = fitsAbove
            ? aboveY
            : petFrame.minY - Self.gap - size.height
        let y = min(max(preferredY, visibleFrame.minY), visibleFrame.maxY - size.height)

        return ReminderBubbleLayoutResult(
            frame: CGRect(origin: CGPoint(x: x, y: y), size: size),
            placement: fitsAbove ? .above : .below,
            petFrame: petFrame
        )
    }
}
