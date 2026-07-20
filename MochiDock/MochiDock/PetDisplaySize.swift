import CoreGraphics
import Foundation

enum PetDisplaySize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case extraLarge
    case jumbo

    var id: Self { self }

    var resourceName: String {
        resourceName(for: .idle)
    }

    func resourceName(for visualState: PetVisualState) -> String {
        let prefix: String
        switch visualState {
        case .idle: prefix = "RedPandaProneV04"
        case .halfBlink: prefix = "RedPandaProneHalfBlinkV04"
        case .fullBlink: prefix = "RedPandaProneFullBlinkV04"
        case .happy: prefix = "RedPandaProneHappyV04"
        }

        let pixels: Int
        switch self {
        case .small: pixels = 80
        case .medium: pixels = 120
        case .large: pixels = 160
        case .extraLarge: pixels = 240
        case .jumbo: pixels = 320
        }
        return "\(prefix)_\(pixels)"
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

    var menuTitle: LocalizedStringResource {
        switch self {
        case .small: "Small — 80"
        case .medium: "Medium — 120"
        case .large: "Large — 160"
        case .extraLarge: "Extra Large — 240"
        case .jumbo: "Jumbo — 320"
        }
    }
}
