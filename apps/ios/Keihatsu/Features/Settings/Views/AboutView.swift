import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    private var accent: Color { Color(hex: preferencesStore.preferences.theme.hex) }
    private var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0" }
    private var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1" }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                missionCard
                highlightsCard
                appDetailsCard
                repositoryLink

                Text("Made for readers who always have one more chapter.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var heroCard: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(hex: "18230D"), accent.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(accent.opacity(0.32))
                .frame(width: 230, height: 230)
                .blur(radius: 54)
                .offset(x: 120, y: -100)

            VStack(spacing: 14) {
                Image("AboutLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 126, height: 126)
                    .accessibilityLabel("Keihatsu logo")

                VStack(spacing: 5) {
                    Text("Keihatsu")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Read beyond the next chapter")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text("VERSION \(version)")
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.84))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            .padding(.vertical, 28)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A better place to read")
                .font(.title2.bold())
                .fontDesign(.rounded)
            Text("Keihatsu is a native manga and manhwa reader built around a calm library, thoughtful source management, and dependable offline reading.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var highlightsCard: some View {
        VStack(spacing: 0) {
            AboutHighlightRow(icon: "swift", color: .orange, title: "Native SwiftUI", subtitle: "Designed for Apple platforms")
            Divider().padding(.leading, 66)
            AboutHighlightRow(icon: "arrow.down.circle.fill", color: accent, title: "Offline first", subtitle: "CBZ downloads ready whenever you are")
            Divider().padding(.leading, 66)
            AboutHighlightRow(icon: "lock.shield.fill", color: .blue, title: "Local by default", subtitle: "Your reading experience stays yours")
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var appDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App details")
                .font(.headline)

            AboutValueRow(label: "Version", value: version)
            Divider()
            AboutValueRow(label: "Build", value: build)
            Divider()
            AboutValueRow(label: "Platform", value: "iOS")
            Divider()
            AboutValueRow(label: "Developer", value: "404khai")
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var repositoryLink: some View {
        Link(destination: URL(string: "https://github.com/404khai/Keihatsu")!) {
            HStack(spacing: 14) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.headline)
                    .foregroundStyle(accent)
                    .frame(width: 42, height: 42)
                    .background(accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("View the project")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Explore Keihatsu on GitHub")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AboutHighlightRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(18)
    }
}

private struct AboutValueRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
            .environmentObject(AppPreferencesStore(userDefaults: .standard))
    }
}
