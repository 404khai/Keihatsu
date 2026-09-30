import SwiftUI

struct NotificationMangaDestinationView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Namespace private var transition
    let identity: MangaIdentity
    @State private var manga: Manga?
    @State private var error: String?

    var body: some View {
        Group {
            if let manga {
                MangaDetailView(seed: MangaDetailsSeed(manga: manga), animation: transition)
            } else if let error {
                ContentUnavailableView {
                    Label("Manga unavailable", systemImage: "book.closed")
                } description: { Text(error) } actions: {
                    Button("Try Again") { Task { await load() } }
                }
            } else { ProgressView("Opening manga…") }
        }
        .task(id: identity) { await load() }
    }

    private func load() async {
        error = nil
        do { manga = try await environment.services.mangaDetails.refreshMetadata(for: identity) }
        catch { self.error = "Could not open this manga from its source." }
    }
}
