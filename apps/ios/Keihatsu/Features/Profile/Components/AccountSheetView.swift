import SwiftUI

struct AccountSheetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @State private var incognitoModeEnabled = false

    private var pageBackground: Color {
        incognitoModeEnabled ? Color.black.opacity(0.94) : Color(.systemGroupedBackground)
    }

    private var cardBackground: Color {
        incognitoModeEnabled
            ? Color.white.opacity(0.08)
            : Color(.secondarySystemGroupedBackground)
    }

    private var accent: Color {
        Color(hex: preferencesStore.preferences.theme.hex)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileHeader
                    statsCard

                    AccountSheetGroup(background: cardBackground) {
                        AccountSheetRow(
                            icon: "icloud.and.arrow.down",
                            title: "Download Queue",
                            showsChevron: true
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

                    AccountSheetGroup(background: cardBackground) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            AccountSheetRow(icon: "gearshape", title: "Settings", showsChevron: true)
                        }
                        .buttonStyle(.plain)
                        accountDivider
                        AccountSheetRow(icon: "chart.bar", title: "Stats", showsChevron: true)
                        accountDivider
                        AccountSheetRow(icon: "tray", title: "Inbox", showsChevron: true)
                    }
                    
                    AccountSheetGroup(background: cardBackground) {
                        AccountSheetRow(icon: "tag", title: "Categories", showsChevron: true)
                        accountDivider
                        AccountSheetRow(icon: "server.rack", title: "Data & Storage", showsChevron: true)
                    }

                    AccountSheetGroup(background: cardBackground) {
                        NavigationLink {
                            HelpAndSupportView()
                        } label: {
                            AccountSheetRow(icon: "questionmark.circle", title: "Help & Support", showsChevron: true)
                        }
                        .buttonStyle(.plain)
                        accountDivider
                        AccountSheetRow(icon: "lightbulb.max", title: "Suggest a Feature", showsChevron: true)
                        accountDivider
                        AccountSheetRow(icon: "gift", title: "Support the Developer", showsChevron: true)
                        accountDivider
                        NavigationLink {
                            AboutView()
                        } label: {
                            AccountSheetRow(icon: "info.circle", title: "About", showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    }

                    AccountSheetGroup(background: cardBackground) {
                        HStack(spacing: 18) {
                            AccountIcon(symbol: "theatermasks.fill")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Incognito Mode")
                                    .font(.title3.weight(.medium))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.primary)

                                Text("Read without saving history")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 12)

                            Toggle("Incognito Mode", isOn: $preferencesStore.preferences.incognitoModeEnabled)
                                .labelsHidden()
                                .tint(accent)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                    }

                    logoutButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 34)
            }
            .background(pageBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(incognitoModeEnabled ? .dark : nil)
            .onAppear {
                incognitoModeEnabled = preferencesStore.preferences.incognitoModeEnabled
            }
            .onChange(of: preferencesStore.preferences.incognitoModeEnabled) { _, newValue in
                incognitoModeEnabled = newValue
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var accountDivider: some View {
        Divider()
            .overlay(Color(.separator).opacity(incognitoModeEnabled ? 0.25 : 0.5))
            .padding(.leading, 18)
            .padding(.trailing, 18)
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            dismiss()
        } label: {
            Text("Log Out")
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.top, 6)
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image("user1")
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.primary.opacity(colorScheme == .dark ? 0.14 : 0.08), lineWidth: 1)
                }

            VStack(spacing: 8) {
                HStack(spacing: 8){
                    Text("Kaizel")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Image(systemName: "hammer.circle.fill")
                        .font(.title3)
                        .foregroundStyle(accent)
                }

                Text("El Endministrator, Creator of Keihatsu")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                HStack(spacing: 18) {
                    Label("Member since 2025", systemImage: "calendar")
                    Label("Switzerland", systemImage: "mappin.and.ellipse")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 16) {
                Button {
                } label: {
                    Label("Share Profile", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .glassEffect(.regular.interactive())

                Button {
                } label: {
                    Image(systemName: "pencil")
                        .font(.headline)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .glassEffect(.regular.interactive())
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            AccountStat(value: "143", label: "in Library")
            AccountStat(value: "5h", label: "reading")
            AccountStat(value: "7", label: "read")
            AccountStat(value: "3", label: "comments", showsDivider: false)
        }
        .padding(.vertical, 18)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct AccountSheetGroup<Content: View>: View {
    var background: Color = Color(.secondarySystemGroupedBackground)
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(background, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

private struct AccountSheetRow: View {
    let icon: String
    let title: String
    var showsChevron: Bool = false

    var body: some View {
        HStack(spacing: 18) {
            AccountIcon(symbol: icon)

            Text(title)
                .font(.title3.weight(.medium))
                .fontDesign(.rounded)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
    }
}

private struct AccountIcon: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.title2.weight(.medium))
            .symbolRenderingMode(.hierarchical)
            .frame(width: 38, height: 38)
            .foregroundStyle(.primary)
    }
}

private struct AccountStat: View {
    let value: String
    let label: String
    var showsDivider = true

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)

                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            if showsDivider {
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(width: 1, height: 42)
            }
        }
    }
}
