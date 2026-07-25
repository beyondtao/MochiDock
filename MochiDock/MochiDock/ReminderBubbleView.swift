import SwiftUI

struct ReminderBubbleView: View {
    let reminder: ReminderRecord
    let onComplete: () -> Void
    let onSnooze: () -> Void
    private let localizedText = ReminderLocalizedText()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: localizedText.bubble(name: reminder.name))
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                Button("Complete", action: onComplete)
                    .buttonStyle(.borderedProminent)
                Button("Remind me in 10 minutes", action: onSnooze)
                    .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        }
    }
}
