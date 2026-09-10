import SwiftUI

struct ShellPrimaryButtonStyle: PrimitiveButtonStyle {
    @Environment(\.keihatsuTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label
                .font(theme.typography.cardTitle)
                .frame(maxWidth: .infinity, minHeight: theme.spacing.minimumControlHeight)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
    }
}
