import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case pet
    case application

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .pet: "Pet"
        case .application: "Application"
        }
    }

    var symbolName: String {
        switch self {
        case .pet: "pawprint.fill"
        case .application: "gearshape.fill"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var appDelegate: MochiDockAppDelegate
    @State private var selection: SettingsSection = .pet

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            content
        }
        .frame(
            width: SettingsWindowController.contentSize.width,
            height: SettingsWindowController.contentSize.height
        )
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("MochiDock")
                    .font(.title2.weight(.bold))
                Text("A quiet little friend on your desktop")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 22)

            ForEach(SettingsSection.allCases) { section in
                Button {
                    selection = section
                } label: {
                    Label(section.title, systemImage: section.symbolName)
                        .font(.body.weight(selection == section ? .semibold : .regular))
                        .foregroundStyle(selection == section ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background {
                            if selection == section {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.16))
                            }
                        }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
            }

            Spacer()

            Image("RedPandaProneV04_160")
                .resizable()
                .scaledToFit()
                .frame(width: 142, height: 142)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
                .padding(.bottom, 8)
        }
        .frame(width: 190)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 5) {
                Text(selection.title)
                    .font(.largeTitle.weight(.bold))
                Text(selection == .pet
                     ? "Adjust how your little friend looks and responds."
                     : "Choose how MochiDock behaves on your Mac.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if selection == .pet {
                petSettings
            } else {
                applicationSettings
            }

            Spacer()
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var petSettings: some View {
        settingsCard {
            PetSizeSlider(
                selectedSize: appDelegate.displaySize,
                onSelect: appDelegate.selectDisplaySize
            )

            Divider()

            Toggle(
                "Pointer Proximity Response",
                isOn: Binding(
                    get: { appDelegate.isProximityResponseEnabled },
                    set: { appDelegate.setProximityResponseEnabled($0) }
                )
            )
            Text("When the pointer comes close, your little friend will notice you.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, -8)
        }
    }

    private var applicationSettings: some View {
        settingsCard {
            Toggle(
                "Start at Login",
                isOn: Binding(
                    get: { appDelegate.isLoginItemEnabled },
                    set: { appDelegate.setLoginItemEnabled($0) }
                )
            )

            if let outcome = appDelegate.loginItemOutcome {
                Text(outcome)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func settingsCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}
