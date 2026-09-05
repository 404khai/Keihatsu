import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    private var accent: Color {
        Color(hex: preferencesStore.preferences.theme.hex)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 16) {
                    Image("user1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 82, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keihatsu")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("A native iOS manga and manhwa reader focused on a premium reading experience, local-first library behavior, and clean source management.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                AboutInfoGroup(accent: accent)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Credits")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 14) {
                        AboutCreditRow(icon: "person.crop.circle", title: "Creator", value: "Kaizel", accent: accent)
                        Divider().padding(.leading, 56)
                        AboutCreditRow(icon: "textformat", title: "Typography", value: "Bricolage Grotesque", accent: accent)
                        Divider().padding(.leading, 56)
                        AboutCreditRow(icon: "sparkles", title: "Theme", value: preferencesStore.preferences.theme.label, accent: accent)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AboutInfoGroup: View {
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                AboutCreditRow(icon: "number", title: "Version", value: "1.0 Preview", accent: accent)
                Divider().padding(.leading, 56)
                AboutCreditRow(icon: "iphone", title: "Platform", value: "iOS", accent: accent)
                Divider().padding(.leading, 56)
                AboutCreditRow(icon: "book.closed", title: "Reader", value: "Local-first SwiftUI", accent: accent)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

private struct AboutCreditRow: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(title)
                .font(.headline)

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
            .environmentObject(AppPreferencesStore(userDefaults: .standard))
    }
}
