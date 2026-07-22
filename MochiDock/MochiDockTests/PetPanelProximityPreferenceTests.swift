import AppKit
import Testing
@testable import MochiDock

@MainActor
struct PetPanelProximityPreferenceTests {
    @Test func restoredDisabledProximityDoesNotStartSamplingWhenShown() {
        let detector = PreferencePointerProximityDetector()
        let model = PetInteractionModel(preferences: InMemoryPetPreferences(values: [
            PetPreferenceKey.proximityResponseEnabled: "false"
        ]))
        let controller = PetPanelController(model: model, proximityDetector: detector)

        controller.showPet()
        defer { controller.panel?.close() }

        #expect(detector.startCount == 0)
    }

    @Test func proximityToggleControlsSamplingOnlyWhilePanelIsVisible() {
        let detector = PreferencePointerProximityDetector()
        let model = PetInteractionModel(preferences: InMemoryPetPreferences())
        let controller = PetPanelController(model: model, proximityDetector: detector)
        controller.showPet()
        defer { controller.panel?.close() }

        controller.setProximityResponseEnabled(false)
        controller.setProximityResponseEnabled(false)
        #expect(detector.stopCount == 1)

        controller.setProximityResponseEnabled(true)
        controller.setProximityResponseEnabled(true)
        #expect(detector.startCount == 2)

        controller.hidePet()
        controller.setProximityResponseEnabled(false)
        controller.setProximityResponseEnabled(true)
        #expect(detector.startCount == 2)

        controller.showPet()
        #expect(detector.startCount == 3)
    }
}

@MainActor
private final class PreferencePointerProximityDetector: PointerProximityDetecting {
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func setDragging(_ dragging: Bool) {}
}
