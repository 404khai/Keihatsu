import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var bootstrap: AppBootstrap

    var body: some View {
        switch bootstrap.stage {
        case .onboarding:
            OnboardingView(
                model: OnboardingViewModel(loader: environment.services.contentLoader),
                onComplete: bootstrap.completeOnboarding
            )
        case .accountEntry:
            AccountEntryView(onContinueAsGuest: bootstrap.enterAsGuest)
        case .mainApp:
            ContentView()
        }
    }
}

#Preview("First launch") {
    AppRootView().appEnvironment(.preview(showOnboarding: true))
}
