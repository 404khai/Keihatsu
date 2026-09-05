import SwiftUI

struct PlaceholderFeatureCard: View {
    let destination: FeatureDestination

    @Environment(\.keihatsuTheme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.lg) {
            Image(systemName: destination.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.colors.accent)
                .frame(width: 42, height: 42)
                .background(theme.colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous))

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(destination.rawValue)
                    .font(theme.typography.cardTitle)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(destination.summary)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: theme.spacing.md)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(theme.colors.textSecondary)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.large, style: .continuous))
        .shadow(color: theme.elevation.card.color, radius: theme.elevation.card.radius, y: theme.elevation.card.y)
        .overlay {
            RoundedRectangle(cornerRadius: theme.radius.large, style: .continuous)
                .stroke(theme.colors.border, lineWidth: 1)
        }
    }
}
