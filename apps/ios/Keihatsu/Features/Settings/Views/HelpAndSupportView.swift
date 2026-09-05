import SwiftUI

struct HelpAndSupportView: View {
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @State private var expandedTopic: SupportTopic.ID?

    private var accent: Color {
        Color(hex: preferencesStore.preferences.theme.hex)
    }

    private let topics = SupportTopic.sampleTopics

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Need a hand?", systemImage: "questionmark.bubble.fill")
                        .font(.headline)
                        .foregroundStyle(accent)

                    Text("Find answers for library sync, source plugins, reader behavior, downloads, and account settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Help")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        ForEach(topics) { topic in
                            SupportTopicRow(
                                topic: topic,
                                isExpanded: expandedTopic == topic.id,
                                accent: accent
                            ) {
                                withAnimation(.snappy) {
                                    expandedTopic = expandedTopic == topic.id ? nil : topic.id
                                }
                            }

                            if topic.id != topics.last?.id {
                                Divider().padding(.leading, 70)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        SupportContactRow(icon: "envelope", title: "Email Support", subtitle: "support@keihatsu.app", accent: accent)
                        Divider().padding(.leading, 70)
                        SupportContactRow(icon: "ladybug", title: "Report a Bug", subtitle: "Include screenshots and source name", accent: accent)
                        Divider().padding(.leading, 70)
                        SupportContactRow(icon: "lightbulb", title: "Request a Feature", subtitle: "Tell us what would improve your reading flow", accent: accent)
                    }
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SupportTopicRow: View {
    let topic: SupportTopic
    let isExpanded: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    SupportIcon(symbol: topic.icon, accent: accent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(topic.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.tertiary)
                }

                if isExpanded {
                    Text(topic.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 54)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

private struct SupportContactRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            SupportIcon(symbol: icon, accent: accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

private struct SupportIcon: View {
    let symbol: String
    let accent: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.headline)
            .foregroundStyle(accent)
            .frame(width: 40, height: 40)
            // .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .background(Color.black, in: .circle)
            .glassEffect(.regular)
    }
}

private struct SupportTopic: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let summary: String
    let details: String

    static let sampleTopics = [
        SupportTopic(
            icon: "arrow.triangle.2.circlepath",
            title: "Library sync",
            summary: "Why your library or history may show pending changes.",
            details: "Keihatsu keeps reading progress local first, then queues library, history, bookmark, and preference updates for sync when a backend session is available."
        ),
        SupportTopic(
            icon: "puzzlepiece.extension",
            title: "Source plugins",
            summary: "Manage installed sources and plugin availability.",
            details: "If a source is unavailable, check the Plugins screen for enabled status, source warnings, and migration options before retrying search or chapter loading."
        ),
        SupportTopic(
            icon: "book",
            title: "Reader controls",
            summary: "Adjust reading direction, background, and screen behavior.",
            details: "Reader defaults live in Settings > Reader. These preferences are designed to apply to future reader sessions without changing the current chapter unexpectedly."
        )
    ]
}

#Preview {
    NavigationStack {
        HelpAndSupportView()
            .environmentObject(AppPreferencesStore(userDefaults: .standard))
    }
}
