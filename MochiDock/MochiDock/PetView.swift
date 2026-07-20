import SwiftUI

struct PetView: View {
    let model: PetInteractionModel

    var body: some View {
        Image(model.displaySize.resourceName)
            .resizable()
            .scaledToFit()
            .scaleEffect(
                x: model.horizontalScale * model.responseScale,
                y: model.verticalScale * model.responseScale,
                anchor: model.scaleAnchor
            )
            .offset(y: model.responseOffset)
            .brightness(model.mood == .happy ? 0.025 : 0)
            .animation(
                .easeInOut(duration: model.transitionDuration),
                value: model.animationState
            )
            .frame(
                width: model.displaySize.pointLength,
                height: model.displaySize.pointLength
            )
            .contentShape(Rectangle())
            .onTapGesture {
                model.handleClick()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("MochiDock pet")
            .accessibilityValue(model.mood == .resting ? "Resting" : "Happy")
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
