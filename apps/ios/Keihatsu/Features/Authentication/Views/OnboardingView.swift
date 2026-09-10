import SwiftUI

struct OnboardingView: View {
    @Environment(\.keihatsuTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model: OnboardingViewModel
    let onComplete: () -> Void

    init(model: OnboardingViewModel, onComplete: @escaping () -> Void) {
        _model = StateObject(wrappedValue: model)
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Group {
                if let message = model.errorMessage {
                    ContentUnavailableView {
                        Label("Welcome to Keihatsu", systemImage: "book")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again", action: model.load)
                    }
                } else {
                    TabView(selection: $model.selection) {
                        ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                            pageContent(page).tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip", action: onComplete)
                        .accessibilityIdentifier("onboarding.skip")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !model.pages.isEmpty {
                    VStack(spacing: theme.spacing.md) {
                        Text("\(model.selection + 1) of \(model.pages.count)")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .accessibilityLabel("Page \(model.selection + 1) of \(model.pages.count)")
                        Button(model.isLastPage ? "Get Started" : "Next") {
                            if model.isLastPage {
                                onComplete()
                            } else {
                                withAnimation(reduceMotion ? nil : theme.motion.navigationSpring) { model.advance() }
                            }
                        }
                        .buttonStyle(ShellPrimaryButtonStyle())
                        .accessibilityIdentifier("onboarding.next")
                    }
                    .padding(theme.spacing.screenPadding)
                }
            }
        }
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        ScrollView {
            VStack(spacing: theme.spacing.xxl) {
                Image(page.image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: theme.spacing.onboardingArtworkHeight)
                    .accessibilityHidden(true)
                Text(page.title)
                    .font(theme.typography.hero)
                    .accessibilityAddTraits(.isHeader)
                Text(page.subtitle)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.screenPadding)
        }
    }
}
