import Testing
@testable import MochiDock

@MainActor
struct ReminderSettingsTests {
    @Test func reminderSectionSitsBetweenPetAndApplicationWithoutChangingMenu() {
        #expect(SettingsSection.allCases == [.pet, .reminders, .application])
        #expect(MochiDockMenuAction.allCases == [.petVisibility, .settings, .quit])
    }

    @Test func editorModelUsesOnlyNameIntervalAndTheApprovedQuickValues() {
        let model = ReminderEditorModel()
        #expect(model.name.isEmpty)
        #expect(model.intervalMinutes == 45)
        #expect(model.quickIntervals == [20, 30, 45, 60])
        #expect(!model.canSave)
        model.name = "喝水"
        #expect(model.canSave)
    }
}
