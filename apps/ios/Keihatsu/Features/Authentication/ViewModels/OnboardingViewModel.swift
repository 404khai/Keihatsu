import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var pages: [OnboardingPage] = []
    @Published private(set) var errorMessage: String?
    @Published var selection = 0
    private let loader: BundledJSONLoader

    var isLastPage: Bool { selection == pages.count - 1 }

    init(loader: BundledJSONLoader) {
        self.loader = loader
        load()
    }

    func load() {
        do {
            let pages = try loader.load("onboarding", as: [OnboardingPage].self)
            guard !pages.isEmpty, Set(pages.map(\.id)).count == pages.count else {
                throw CocoaError(.coderReadCorrupt)
            }
            self.pages = pages
            selection = 0
            errorMessage = nil
        } catch {
            errorMessage = "The welcome content could not be loaded."
        }
    }

    func advance() {
        guard !isLastPage, !pages.isEmpty else { return }
        selection += 1
    }
}
