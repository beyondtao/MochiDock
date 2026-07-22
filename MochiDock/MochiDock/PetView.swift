import SwiftUI

struct PetView: View {
    let model: PetInteractionModel
    let onClick: () -> Void

    init(model: PetInteractionModel, onClick: @escaping () -> Void) {
        self.model = model
        self.onClick = onClick
    }

    init(model: PetInteractionModel) {
        self.model = model
        self.onClick = { model.handleClick() }
    }

    var body: some View {
        Image(model.displaySize.resourceName(for: model.visualState))
            .resizable()
            .scaledToFit()
            .transaction { transaction in
                PetRenderPolicy.disableDiscreteContentAnimation(&transaction)
            }
            .scaleEffect(
                x: model.horizontalScale,
                y: model.verticalScale,
                anchor: model.scaleAnchor
            )
            .offset(y: model.responseOffset)
            .animation(
                PetRenderPolicy.geometryAnimation(
                    for: model.animationState,
                    timing: model.timing
                )?.animation,
                value: model.animationState
            )
            .frame(
                width: model.displaySize.pointLength,
                height: model.displaySize.pointLength
            )
            .transaction(value: model.displaySize) { transaction in
                PetRenderPolicy.disableDiscreteContentAnimation(&transaction)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onClick()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("MochiDock pet")
            .accessibilityValue(Text(model.mood.accessibilityValue))
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
