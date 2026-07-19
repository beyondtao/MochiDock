import SwiftUI

struct PetView: View {
    let model: PetInteractionModel

    var body: some View {
        Image(model.displaySize.resourceName)
            .resizable()
            .scaledToFit()
            .scaleEffect(model.mood == .happy ? 1.03 : 1)
            .offset(y: model.mood == .happy ? -2 : 0)
            .brightness(model.mood == .happy ? 0.025 : 0)
            .animation(.easeOut(duration: 0.16), value: model.mood)
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
