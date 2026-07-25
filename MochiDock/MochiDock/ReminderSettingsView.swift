import Observation
import SwiftUI

@MainActor
@Observable
final class ReminderEditorModel {
    let id = UUID()
    var name: String
    var intervalMinutes: Int
    let quickIntervals = ReminderDraft.quickIntervals

    var canSave: Bool { draft.validated() != nil }
    var draft: ReminderDraft { ReminderDraft(name: name, intervalMinutes: intervalMinutes) }

    init(reminder: ReminderRecord? = nil) {
        self.name = reminder?.name ?? ""
        self.intervalMinutes = reminder?.intervalMinutes ?? 45
    }
}

extension ReminderEditorModel: Identifiable {}

struct ReminderSettingsView: View {
    @Bindable var center: ReminderCenter
    @State private var editor: ReminderEditorModel?
    @State private var editingID: UUID?
    @State private var deletionCandidate: ReminderRecord?
    private let localizedText = ReminderLocalizedText()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let active = center.activeReminder {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: localizedText.currentlyRunning(name: active.name))
                            .font(.headline)
                        Text(verbatim: center.pendingReminder?.id == active.id
                             ? localizedText.pending
                             : localizedText.remaining(formatted(center.remainingSeconds(for: active))))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let message = center.statusMessage {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }

            List(center.reminders) { reminder in
                HStack {
                    VStack(alignment: .leading) {
                        Text(reminder.name)
                        Text(verbatim: localizedText.interval(minutes: reminder.intervalMinutes))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(reminder.state == .enabled ? "Pause" : "Enable") {
                        if reminder.state == .enabled { try? center.pause(reminder.id) }
                        else { try? center.enable(reminder.id) }
                    }
                    Button("Edit") { beginEditing(reminder) }
                    Button(role: .destructive) { requestDelete(reminder) } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .frame(minHeight: 220)

            Button("Add Reminder") {
                editingID = nil
                editor = ReminderEditorModel()
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(item: $editor) { editor in editorSheet(editor) }
        .alert("Delete Reminder?", isPresented: Binding(
            get: { deletionCandidate != nil },
            set: { if !$0 { deletionCandidate = nil } }
        )) {
            Button("Cancel", role: .cancel) { deletionCandidate = nil }
            Button("Delete", role: .destructive) {
                if let reminder = deletionCandidate { try? center.delete(reminder.id, confirmed: true) }
                deletionCandidate = nil
            }
        }
    }

    private func editorSheet(_ model: ReminderEditorModel) -> some View {
        @Bindable var editor = model
        return VStack(alignment: .leading, spacing: 16) {
            Text(editingID == nil ? "Add Reminder" : "Edit Reminder").font(.title2.bold())
            TextField("Reminder Name", text: $editor.name)
                .onChange(of: editor.name) { _, value in
                    if value.count > 30 { editor.name = String(value.prefix(30)) }
                }
            Stepper(value: $editor.intervalMinutes, in: 5...240, step: 5) {
                Text(verbatim: localizedText.interval(minutes: editor.intervalMinutes))
            }
            HStack {
                ForEach(editor.quickIntervals, id: \.self) { value in
                    Button("\(value)") { editor.intervalMinutes = value }
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { self.editor = nil }
                Button("Save") { save(editor) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!editor.canSave)
            }
        }
        .padding(24)
        .frame(width: 380)
    }

    private func beginEditing(_ reminder: ReminderRecord) {
        editingID = reminder.id
        editor = ReminderEditorModel(reminder: reminder)
    }

    private func save(_ editor: ReminderEditorModel) {
        if let editingID { try? center.edit(editingID, draft: editor.draft) }
        else { _ = try? center.add(editor.draft) }
        self.editor = nil
    }

    private func requestDelete(_ reminder: ReminderRecord) {
        if center.deletionPolicy(for: reminder.id) == .requiresConfirmation {
            deletionCandidate = reminder
        } else {
            try? center.delete(reminder.id, confirmed: false)
        }
    }

    private func formatted(_ seconds: TimeInterval) -> String {
        let total = Int(ceil(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
