import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var bootstrap: AppBootstrap

    var body: some View {
        Group {
            switch bootstrap.stage {
            case .onboarding:
                OnboardingView(
                    model: OnboardingViewModel(loader: environment.services.contentLoader),
                    onComplete: bootstrap.completeOnboarding
                )
            case .accountEntry:
                AccountEntryView(
                    onSignedIn: bootstrap.enterAuthenticated,
                    onContinueAsGuest: bootstrap.enterAsGuest
                )
            case .mainApp:
                ContentView()
            }
        }
        .task {
            await environment.accountSession.restore()
            if environment.accountSession.isAuthenticated { bootstrap.enterAuthenticated() }
        }
    }
}

#Preview("First launch") {
    AppRootView().appEnvironment(.preview(showOnboarding: true))
}
