import SwiftUI

struct AccountEntryView: View {
    @Environment(\.keihatsuTheme) private var theme
    let onContinueAsGuest: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xxl) {
                    Image(systemName: "books.vertical")
                        .font(theme.typography.hero)
                        .foregroundStyle(theme.colors.accent)
                        .accessibilityHidden(true)
                    Text("Your next chapter awaits")
                        .font(theme.typography.hero)
                    Text("Discover stories and make time to read.")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textSecondary)
                    Label("Google sign-in is coming soon", systemImage: "person.crop.circle")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                    Button("Continue as Guest", action: onContinueAsGuest)
                        .buttonStyle(ShellPrimaryButtonStyle())
                        .accessibilityIdentifier("account.continueAsGuest")
                }
                .multilineTextAlignment(.center)
                .padding(theme.spacing.screenPadding)
            }
            .navigationTitle("Welcome to Keihatsu")
            .background(theme.colors.background)
        }
    }
}
