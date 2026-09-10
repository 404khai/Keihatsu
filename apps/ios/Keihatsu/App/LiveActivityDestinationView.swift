import SwiftUI

struct LiveActivityDestinationView: View {
    @Environment(\.dismiss) private var dismiss
    let destination: LiveActivityDestination

    var body: some View {
        NavigationStack {
            Group {
                switch destination {
                case .downloads:
                    DownloadQueueView()
                case .privacy:
                    PrivacySettingsView()
                case .reader(let manga, let context):
                    LiveActivityReaderLoader(mangaID: manga, context: context)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Close")
                }
            }
        }
    }
}

private struct LiveActivityReaderLoader: View {
    enum LoadState {
        case loading
        case loaded(Manga, [Chapter])
        case failed(String)
    }

    @EnvironmentObject private var environment: AppEnvironment
    let mangaID: MangaIdentity
    let context: ReaderLaunchContext
    @State private var state: LoadState = .loading

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView("Restoring reading position…")
            case .loaded(let manga, let chapters):
                ReaderEntryView(manga: manga, chapters: chapters, context: context)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn’t open this manga", systemImage: "book.closed")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { Task { await load() } }
                }
            }
        }
        .task(id: mangaID) { await load() }
    }

    private func load() async {
        state = .loading
        let repository = environment.services.mangaDetails
        let cached = await repository.cachedRecord(for: mangaID)
        do {
            async let manga = repository.refreshMetadata(for: mangaID)
            async let chapters = repository.refreshChapters(for: mangaID)
            let result = try await (manga, chapters)
            guard result.1.contains(where: { $0.id == context.chapter }) else {
                throw LiveActivityRestoreError.chapterUnavailable
            }
            state = .loaded(result.0, result.1)
        } catch {
            if let cached,
               cached.chapters.contains(where: { $0.id == context.chapter }) {
                state = .loaded(cached.manga, cached.chapters)
            } else {
                state = .failed(error.localizedDescription)
            }
        }
    }
}

private enum LiveActivityRestoreError: LocalizedError {
    case chapterUnavailable

    var errorDescription: String? {
        "The saved chapter is no longer available from this source."
    }
}
