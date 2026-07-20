import CoreGraphics

enum PetDisplaySize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case extraLarge
    case jumbo

    var id: Self { self }

    var resourceName: String {
        switch self {
        case .small: "RedPandaProneV04_80"
        case .medium: "RedPandaProneV04_120"
        case .large: "RedPandaProneV04_160"
        case .extraLarge: "RedPandaProneV04_240"
        case .jumbo: "RedPandaProneV04_320"
        }
    }

    var pointLength: CGFloat {
        switch self {
        case .small: 80
        case .medium: 120
        case .large: 160
        case .extraLarge: 240
        case .jumbo: 320
        }
    }

    var menuTitle: String {
        switch self {
        case .small: "Small — 80"
        case .medium: "Medium — 120"
        case .large: "Large — 160"
        case .extraLarge: "Extra Large — 240"
        case .jumbo: "Jumbo — 320"
        }
    }
}
