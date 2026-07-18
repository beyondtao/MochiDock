import SwiftUI

struct PetView: View {
    let model: PetInteractionModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(Color(red: 0.96, green: 0.82, blue: 0.72))
                .shadow(color: .black.opacity(0.18), radius: 7, y: 4)

            VStack(spacing: 14) {
                HStack(spacing: 30) {
                    eye
                    eye
                }

                PetMouth(isHappy: model.mood == .happy)
                    .stroke(
                        model.mood == .happy ? Color(red: 0.72, green: 0.20, blue: 0.30) : .black.opacity(0.7),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 34, height: 18)
            }
        }
        .padding(8)
        .frame(width: 128, height: 128)
        .contentShape(Rectangle())
        .onTapGesture {
            model.handleClick()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("MochiDock pet")
        .accessibilityValue(model.mood == .resting ? "Resting" : "Happy")
    }

    private var eye: some View {
        Circle()
            .fill(.black.opacity(0.76))
            .frame(width: 11, height: 11)
    }
}

private struct PetMouth: Shape {
    let isHappy: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if isHappy {
            path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.25))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.height * 0.25),
                control: CGPoint(x: rect.midX, y: rect.maxY)
            )
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }

        return path
    }
}

#Preview("Resting") {
    PetView(model: PetInteractionModel())
}

#Preview("Happy") {
    let model = PetInteractionModel()
    model.handleClick()
    return PetView(model: model)
}
