import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    private var accent: Color {
        Color(hex: preferencesStore.preferences.theme.hex)
    }

    private let sections: [SettingsSection] = [
        SettingsSection(icon: "paintpalette", iconColor: Color(hex: "FF6EA8"), title: "Appearance", subtitle: "Themes, dark mode, display", destination: .appearance),
        SettingsSection(icon: "books.vertical", iconColor: Color(hex: "8DE328"), usesDarkSymbol: true, title: "Library", subtitle: "Categories, global updates, badges", destination: .library),
        SettingsSection(icon: "book", iconColor: Color(hex: "A98BFF"), title: "Reader", subtitle: "Reading mode, display, navigation", destination: .reader),
        SettingsSection(icon: "arrow.down.to.line.compact", iconColor: Color(hex: "42D9F5"), usesDarkSymbol: true, title: "Downloads", subtitle: "Download behavior and offline chapters", destination: .downloads),
        SettingsSection(icon: "safari", iconColor: Color(hex: "5AA7FF"), title: "Browse", subtitle: "Extensions, global search, source hints", destination: .browse),
        SettingsSection(icon: "arrow.triangle.2.circlepath", iconColor: Color(hex: "FF7A3D"), title: "Tracking", subtitle: "Sync with external reading services", destination: .tracking),
        SettingsSection(icon: "shield.checkered", iconColor: Color(hex: "FFD166"), usesDarkSymbol: true, title: "Privacy", subtitle: "History, incognito mode, visibility", destination: .privacy),
        SettingsSection(icon: "command", iconColor: Color(hex: "B8B8FF"), title: "Advanced", subtitle: "Backup, clear cache, logs", destination: .advanced)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // SettingsHeroCard(accent: accent)

                VStack(spacing: 10) {
                    ForEach(sections) { section in
                        NavigationLink {
                            settingsDestination(for: section.destination)
                        } label: {
                            SettingsNavigationTile(section: section, accent: accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 34)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func settingsDestination(for destination: SettingsDestination) -> some View {
        switch destination {
        case .appearance:
            AppearanceSettingsView()
        case .library:
            LibrarySettingsView()
        case .reader:
            ReaderSettingsView()
        case .downloads:
            DownloadsSettingsView()
        case .browse:
            BrowseSettingsView()
        case .tracking:
            TrackingSettingsView()
        case .privacy:
            PrivacySettingsView()
        case .advanced:
            AdvancedSettingsView()
        }
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    private var accent: Color {
        Color(hex: preferencesStore.preferences.theme.hex)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SettingsGroup(title: "Display") {
                    Picker("Color Scheme", selection: $preferencesStore.preferences.colorScheme) {
                        ForEach(AppColorSchemePreference.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(16)

                    SettingsDivider()

                    SettingsPickerRow(
                        icon: "app.background.dotted",
                        title: "App Icon",
                        subtitle: "Choose the launcher identity",
                        selection: $preferencesStore.preferences.appIcon,
                        options: AppIconPreference.allCases,
                        accent: accent
                    )
                }

                SettingsGroup(title: "Theme") {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ],
                        spacing: 18
                    ) {
                        ForEach(KeihatsuThemePreference.allCases) { theme in
                            Button {
                                preferencesStore.preferences.theme = theme
                                preferencesStore.preferences.accentHex = theme.hex
                            } label: {
                                ThemePickerCard(
                                    theme: theme,
                                    isSelected: preferencesStore.preferences.theme == theme
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LibrarySettingsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    var body: some View {
        SettingsControlsPage(title: "Library") {
            SettingsGroup(title: "Updates") {
                SettingsToggleRow(
                    icon: "books.vertical",
                    title: "Global Updates",
                    subtitle: "Refresh saved titles when the session syncs",
                    isOn: $preferencesStore.preferences.globalLibraryUpdatesEnabled,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )

                SettingsDivider()

                SettingsToggleRow(
                    icon: "number.circle",
                    title: "Library Badges",
                    subtitle: "Show unread, downloaded, and update indicators",
                    isOn: $preferencesStore.preferences.showChapterBadges,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )
            }
        }
    }
}

struct ReaderSettingsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    var body: some View {
        SettingsControlsPage(title: "Reader") {
            SettingsGroup(title: "Reading") {
                SettingsPickerRow(
                    icon: "rectangle.portrait.on.rectangle.portrait",
                    title: "Reading Direction",
                    subtitle: "Default flow for new chapters",
                    selection: $preferencesStore.preferences.readerDirection,
                    options: ReaderDirectionPreference.allCases,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )

                SettingsDivider()

                SettingsPickerRow(
                    icon: "circle.lefthalf.filled",
                    title: "Reader Background",
                    subtitle: "Comfort mode for long sessions",
                    selection: $preferencesStore.preferences.readerBackground,
                    options: ReaderBackgroundPreference.allCases,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )

                SettingsDivider()

                SettingsToggleRow(
                    icon: "iphone",
                    title: "Keep Screen Awake",
                    subtitle: "Prevent dimming while reading",
                    isOn: $preferencesStore.preferences.keepScreenAwake,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )
            }
        }
    }
}

struct DownloadsSettingsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    var body: some View {
        SettingsControlsPage(title: "Downloads") {
            SettingsGroup(title: "Offline") {
                SettingsToggleRow(
                    icon: "wifi",
                    title: "Wi-Fi Only",
                    subtitle: "Queue chapter downloads until Wi-Fi is available",
                    isOn: $preferencesStore.preferences.downloadOnWiFiOnly,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )

                SettingsDivider()

                SettingsToggleRow(
                    icon: "arrow.down.doc",
                    title: "Save Chapters",
                    subtitle: "Keep downloaded chapters available offline",
                    isOn: $preferencesStore.preferences.saveChaptersForOffline,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )
            }
        }
    }
}

struct BrowseSettingsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    var body: some View {
        SettingsControlsPage(title: "Browse") {
            SettingsGroup(title: "Sources") {
                SettingsToggleRow(
                    icon: "puzzlepiece.extension",
                    title: "Source Warnings",
                    subtitle: "Show availability and safety hints for plugins",
                    isOn: $preferencesStore.preferences.sourceWarningsEnabled,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )
            }
        }
    }
}

struct TrackingSettingsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @EnvironmentObject private var syncQueueStore: SyncQueueStore

    var body: some View {
        SettingsControlsPage(title: "Tracking") {
            SettingsGroup(title: "Services") {
                SettingsToggleRow(
                    icon: "point.3.connected.trianglepath.dotted",
                    title: "External Tracking",
                    subtitle: "Prepare progress sync for services like MyAnimeList",
                    isOn: $preferencesStore.preferences.trackingSyncEnabled,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )

                SettingsDivider()

                SyncStatusView(accent: Color(hex: preferencesStore.preferences.theme.hex))
            }
        }
    }
}

struct PrivacySettingsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    var body: some View {
        SettingsControlsPage(title: "Privacy") {
            SettingsGroup(title: "History") {
                SettingsToggleRow(
                    icon: "theatermasks.fill",
                    title: "Incognito Mode",
                    subtitle: "Read without saving history",
                    isOn: $preferencesStore.preferences.incognitoModeEnabled,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )
            }
        }
    }
}

struct AdvancedSettingsView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    var body: some View {
        SettingsControlsPage(title: "Advanced") {
            SettingsGroup(title: "Diagnostics") {
                SettingsToggleRow(
                    icon: "waveform.path.ecg",
                    title: "Diagnostics",
                    subtitle: "Keep local logs for sync, reader, and source debugging",
                    isOn: $preferencesStore.preferences.diagnosticsEnabled,
                    accent: Color(hex: preferencesStore.preferences.theme.hex)
                )

                SettingsDivider()

                Button(role: .destructive) {
                    preferencesStore.reset()
                } label: {
                    Text("Reset Preferences")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .padding(16)
            }
        }
    }
}

struct SettingsControlsPage<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                content
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SyncStatusView: View {
    @EnvironmentObject private var syncQueueStore: SyncQueueStore
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                SettingsIcon(symbol: "icloud.and.arrow.up", accent: accent)

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(syncQueueStore.pendingCount) pending operation\(syncQueueStore.pendingCount == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(lastSyncedText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Label("Unavailable", systemImage: "icloud.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(syncQueueStore.operations.prefix(3)) { operation in
                HStack(spacing: 10) {
                    Circle()
                        .fill(statusColor(for: operation.status))
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(operation.kind.label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)

                        Text(operation.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Text(operation.status.label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var lastSyncedText: String {
        guard let lastSyncedAt = syncQueueStore.lastSyncedAt else {
            return "Account sync is not available yet"
        }

        return "Last synced \(lastSyncedAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private func statusColor(for status: SyncOperationStatus) -> Color {
        switch status {
        case .queued: return accent
        case .syncing: return .blue
        case .failed: return .red
        case .completed: return .green
        }
    }
}

// private struct SettingsHeroCard: View {
//     let accent: Color

//     var body: some View {
//         VStack(alignment: .leading, spacing: 10) {
//             Label("Keihatsu Controls", systemImage: "sparkles")
//                 .font(.headline)
//                 .foregroundStyle(accent)

//             Text("Pick a section to tune app appearance, reader defaults, library behavior, privacy, tracking, and advanced controls.")
//                 .font(.subheadline)
//                 .foregroundStyle(.secondary)
//         }
//         .frame(maxWidth: .infinity, alignment: .leading)
//         .padding(18)
//         .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
//     }
// }

private struct SettingsNavigationTile: View {
    let section: SettingsSection
    let accent: Color

    var body: some View {
        HStack(spacing: 15) {
            SettingsIcon(symbol: section.icon, accent: accent, symbolColor: section.iconColor, usesDarkSymbol: section.usesDarkSymbol)

            VStack(alignment: .leading, spacing: 5) {
                Text(section.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(section.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ThemePickerCard: View {
    let theme: KeihatsuThemePreference
    let isSelected: Bool

    private var color: Color {
        Color(hex: theme.hex)
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(cardBackground)
                    .frame(height: 156)

                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(barColor)
                        .frame(width: 86, height: 22)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(color.opacity(0.26))
                        .frame(width: 78, height: 92)
                        .overlay {
                            Capsule()
                                .fill(color)
                                .frame(width: 44, height: 14)
                        }
                }

                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 26, height: 26)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(barColor)
                            .frame(height: 18)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }

                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(color)
                                .background(.background, in: Circle())
                        }
                        Spacer()
                    }
                    .padding(10)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? color.opacity(0.8) : Color(.separator).opacity(0.22), lineWidth: isSelected ? 2 : 1)
            }

            Text(theme.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }

    private var cardBackground: Color {
        switch theme {
        case .verdant:
            return Color(hex: "EAF8EA")
        case .moonlit:
            return Color(hex: "F0ECFF")
        case .sakuraPulse:
            return Color(hex: "FFEAF3")
        case .emberScript:
            return Color(hex: "FFEBD4")
        case .oceanFrame:
            return Color(hex: "E7FAFF")
        case .cinnabar:
            return Color(hex: "E74236")
        case .sandybrown:
            return Color(hex: "FEB172")
        }
    }

    private var barColor: Color {
        Color(.systemGray4).opacity(0.75)
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(symbol: icon, accent: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

private struct SettingsPickerRow<Option: Identifiable & Hashable>: View where Option.AllCases: RandomAccessCollection, Option: CaseIterable {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var selection: Option
    let options: Option.AllCases
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(symbol: icon, accent: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Picker(title, selection: $selection) {
                ForEach(options) { option in
                    Text(label(for: option)).tag(option)
                }
            }
            .tint(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private func label(for option: Option) -> String {
        switch option {
        case let option as AppIconPreference:
            return option.label
        case let option as ReaderDirectionPreference:
            return option.label
        case let option as ReaderBackgroundPreference:
            return option.label
        default:
            return String(describing: option)
        }
    }
}

private struct SettingsIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    let symbol: String
    let accent: Color
    var symbolColor: Color?
    var usesDarkSymbol = false

    var body: some View {
        Image(systemName: symbol)
            .font(.title3.weight(.medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(foregroundColor)
            .frame(width: 40, height: 40)
            .background(backgroundColor, in: .circle)
            .glassEffect(.regular)
    }

    private var foregroundColor: Color {
        if colorScheme == .dark {
            return symbolColor ?? accent
        }

        return usesDarkSymbol ? .black : .white
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : (symbolColor ?? accent)
    }

}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 70)
    }
}

private struct SettingsSection: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    var usesDarkSymbol = false
    let title: String
    let subtitle: String
    let destination: SettingsDestination
}

private enum SettingsDestination: Hashable {
    case appearance
    case library
    case reader
    case downloads
    case browse
    case tracking
    case privacy
    case advanced
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppPreferencesStore(userDefaults: .standard))
            .environmentObject(SyncQueueStore())
    }
}
