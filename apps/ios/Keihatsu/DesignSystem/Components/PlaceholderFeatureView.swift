import SwiftUI

struct PlaceholderFeatureView: View {
    let title: String
    let summary: String
    let nextMilestone: String

    @Environment(\.keihatsuTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                Text(title)
                    .font(theme.typography.hero)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(summary)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)

                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Next Phase")
                        .font(theme.typography.sectionTitle)
                        .foregroundStyle(theme.colors.textPrimary)

                    Text(nextMilestone)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .padding(theme.spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.large, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: theme.radius.large, style: .continuous)
                        .stroke(theme.colors.border, lineWidth: 1)
                }
            }
            .padding(.horizontal, theme.spacing.screenPadding)
            .padding(.vertical, theme.spacing.xxl)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }
}
