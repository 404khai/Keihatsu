import SwiftUI

struct SupportDeveloperView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    private let projectURL = URL(string: "https://github.com/404khai/Keihatsu")!
    private var accent: Color { Color(hex: preferencesStore.preferences.theme.hex) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 88, height: 88)
                        .background(
                            LinearGradient(colors: [accent, accent.opacity(0.62)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                        )

                    VStack(spacing: 8) {
                        Text("Support Keihatsu")
                            .font(.largeTitle.bold())
                            .fontDesign(.rounded)
                        Text("Your encouragement helps keep the servers running and gives the project room to grow.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                VStack(spacing: 0) {
                    Link(destination: projectURL) {
                        SupportActionRow(
                            icon: "star.fill",
                            color: .orange,
                            title: "Star on GitHub",
                            subtitle: "Help more readers discover the project",
                            trailingIcon: "arrow.up.right"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 70)

                    ShareLink(item: projectURL) {
                        SupportActionRow(
                            icon: "square.and.arrow.up.fill",
                            color: accent,
                            title: "Share Keihatsu",
                            subtitle: "Send the project to another manga reader",
                            trailingIcon: "chevron.right"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Label("Direct support", systemImage: "gift.fill")
                        .font(.headline)
                        .foregroundStyle(accent)
                    Text("Donation options are being prepared. They will appear here once secure payment destinations are available.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Support the Developer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct SupportActionRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let trailingIcon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
            Image(systemName: trailingIcon).foregroundStyle(.tertiary)
        }
        .padding(18)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SupportDeveloperView()
            .environmentObject(AppPreferencesStore(userDefaults: .standard))
    }
}
