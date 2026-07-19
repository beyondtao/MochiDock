import CoreGraphics

enum PetDisplaySize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: Self { self }

    var resourceName: String {
        switch self {
        case .small: "RedPandaMaster80"
        case .medium: "RedPandaMaster120"
        case .large: "RedPandaMaster160"
        }
    }

    var pointLength: CGFloat {
        switch self {
        case .small: 80
        case .medium: 120
        case .large: 160
        }
    }

    var menuTitle: String {
        switch self {
        case .small: "Small — 80"
        case .medium: "Medium — 120"
        case .large: "Large — 160"
        }
    }
}
