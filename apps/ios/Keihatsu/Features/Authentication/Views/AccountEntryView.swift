import SwiftUI

struct AccountEntryView: View {
    @Environment(\.keihatsuTheme) private var theme
    @EnvironmentObject private var session: AccountSessionStore
    let onSignedIn: () -> Void
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
                    if let error = session.error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(theme.typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        Task { if await session.signIn() { onSignedIn() } }
                    } label: {
                        HStack {
                            if session.isAuthenticating { ProgressView().tint(.white) }
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text("Continue with Google")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ShellPrimaryButtonStyle())
                    .disabled(session.isAuthenticating)
                    .accessibilityIdentifier("account.continueWithGoogle")
                    Button("Continue as Guest", action: onContinueAsGuest)
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.colors.textSecondary)
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
