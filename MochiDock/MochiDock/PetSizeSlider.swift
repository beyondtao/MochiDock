import SwiftUI

enum SizeSliderMove {
    case left
    case right
}

enum PetSizeSliderModel {
    static let sizes = PetDisplaySize.allCases

    static func nearestSize(to normalizedPosition: Double) -> PetDisplaySize {
        let boundedPosition = min(max(normalizedPosition, 0), 1)
        let lastIndex = sizes.count - 1
        let index = Int((boundedPosition * Double(lastIndex)).rounded())
        return sizes[index]
    }

    static func normalizedPosition(for size: PetDisplaySize) -> Double {
        guard let index = sizes.firstIndex(of: size), sizes.count > 1 else { return 0 }
        return Double(index) / Double(sizes.count - 1)
    }

    static func selectStop(
        _ index: Int,
        onSelect: (PetDisplaySize) -> Void
    ) {
        guard sizes.indices.contains(index) else { return }
        onSelect(sizes[index])
    }

    static func movedSize(
        from current: PetDisplaySize,
        direction: SizeSliderMove
    ) -> PetDisplaySize {
        guard let currentIndex = sizes.firstIndex(of: current) else { return sizes[0] }
        let offset = direction == .left ? -1 : 1
        let nextIndex = min(max(currentIndex + offset, 0), sizes.count - 1)
        return sizes[nextIndex]
    }
}

struct PetSizeSliderInteraction {
    static let controlHeight: CGFloat = 24
    static let horizontalInset: CGFloat = 12

    let trackWidth: CGFloat

    var hitRegion: CGRect {
        CGRect(x: 0, y: 0, width: max(trackWidth, 0), height: Self.controlHeight)
    }

    func point(for size: PetDisplaySize) -> CGPoint {
        let position = PetSizeSliderModel.normalizedPosition(for: size)
        return CGPoint(
            x: Self.horizontalInset + usableTrackWidth * CGFloat(position),
            y: hitRegion.midY
        )
    }

    func selection(at point: CGPoint) -> PetDisplaySize? {
        guard hitRegion.contains(point), usableTrackWidth > 0 else { return nil }
        let position = (point.x - Self.horizontalInset) / usableTrackWidth
        return PetSizeSliderModel.nearestSize(to: Double(position))
    }

    func drag(
        from start: CGPoint,
        through points: [CGPoint],
        onSelect: (PetDisplaySize) -> Void
    ) {
        for point in [start] + points {
            if let size = selection(at: point) {
                onSelect(size)
            }
        }
    }

    private var usableTrackWidth: CGFloat {
        max(trackWidth - (Self.horizontalInset * 2), 0)
    }
}

struct PetSizeSlider: View {
    let selectedSize: PetDisplaySize
    let onSelect: (PetDisplaySize) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pet Size")
                Spacer()
                Text(selectedSize.menuTitle)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack {
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 3)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, PetSizeSliderInteraction.horizontalInset)

                    HStack(spacing: 0) {
                        ForEach(Array(PetSizeSliderModel.sizes.enumerated()), id: \.offset) {
                            index, size in
                            stop(size: size)
                            if index < PetSizeSliderModel.sizes.count - 1 {
                                Spacer(minLength: 0)
                            }
                        }
                    }

                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(dragGesture(trackWidth: geometry.size.width))
                }
            }
            .frame(height: PetSizeSliderInteraction.controlHeight)

            HStack(spacing: 0) {
                ForEach(Array(PetSizeSliderModel.sizes.enumerated()), id: \.offset) {
                    index, size in
                    Text("\(Int(size.pointLength))")
                        .font(.caption2)
                        .foregroundStyle(size == selectedSize ? Color.primary : Color.secondary)
                        .frame(minWidth: 24)
                    if index < PetSizeSliderModel.sizes.count - 1 {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onMoveCommand { direction in
            switch direction {
            case .left:
                onSelect(PetSizeSliderModel.movedSize(from: selectedSize, direction: .left))
            case .right:
                onSelect(PetSizeSliderModel.movedSize(from: selectedSize, direction: .right))
            default:
                break
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Pet Size"))
        .accessibilityValue(Text(selectedSize.menuTitle))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .decrement:
                onSelect(PetSizeSliderModel.movedSize(from: selectedSize, direction: .left))
            case .increment:
                onSelect(PetSizeSliderModel.movedSize(from: selectedSize, direction: .right))
            @unknown default:
                break
            }
        }
    }

    private func stop(size: PetDisplaySize) -> some View {
        ZStack {
            if size == selectedSize, isFocused {
                Circle()
                    .stroke(Color.accentColor.opacity(0.45), lineWidth: 2)
                    .frame(width: 19, height: 19)
            }

            Circle()
                .fill(size == selectedSize ? Color.accentColor : Color.secondary.opacity(0.65))
                .frame(width: size == selectedSize ? 14 : 8, height: size == selectedSize ? 14 : 8)
        }
        .frame(width: 24, height: 24)
    }

    private func dragGesture(trackWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let interaction = PetSizeSliderInteraction(trackWidth: trackWidth)
                guard let size = interaction.selection(at: value.location) else { return }
                onSelect(size)
                isFocused = true
            }
    }
}
