import Combine
import SwiftUI

/// State only. ContentView continues to own tab layout and destination placement.
@MainActor
final class AppNavigation: ObservableObject {
    enum Tab: Hashable { case home, library, history, extensions, profile, search }

    @Published var selectedTab: Tab = .library
    @Published var homePath = NavigationPath()
    @Published var libraryPath = NavigationPath()
    @Published var historyPath = NavigationPath()
    @Published var extensionsPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    @Published var searchPath = NavigationPath()
    @Published var inboxRequested = false
    private var visibleReaderChapter: ChapterIdentity?

    func reset() {
        selectedTab = .library
        homePath = NavigationPath()
        libraryPath = NavigationPath()
        historyPath = NavigationPath()
        extensionsPath = NavigationPath()
        profilePath = NavigationPath()
        searchPath = NavigationPath()
        visibleReaderChapter = nil
    }

    @discardableResult
    func handleLiveActivityURL(_ url: URL) -> Bool {
        guard let destination = LiveActivityDestination(url: url) else { return false }
        if case .reader(_, let context) = destination,
           visibleReaderChapter == context.chapter {
            return true
        }

        selectedTab = .library
        libraryPath = NavigationPath()
        libraryPath.append(destination)
        return true
    }

    @discardableResult
    func handleNotificationURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "keihatsu",
              let host = url.host?.lowercased() else { return false }
        let parts = url.pathComponents.filter { $0 != "/" }
        if host == "inbox" || host == "announcement" { inboxRequested = true; return true }
        guard ((host == "manga" && parts.count == 2) ||
               (host == "chapter" && parts.count == 3) ||
               (host == "comment" && parts.count == 4)),
              parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            inboxRequested = true
            return true
        }
        if host == "chapter" || host == "comment" {
            let manga = MangaIdentity(sourceID: parts[0], mangaID: parts[1])
            let chapter = ChapterIdentity(manga: manga, chapterID: parts[2])
            selectedTab = .library
            libraryPath = NavigationPath()
            libraryPath.append(LiveActivityDestination.reader(manga: manga,
                context: ReaderLaunchContext(chapter: chapter, origin: .history, pageIndex: nil)))
            return true
        }
        selectedTab = .library
        libraryPath = NavigationPath()
        libraryPath.append(MangaIdentity(sourceID: parts[0], mangaID: parts[1]))
        return true
    }

    func readerDidAppear(chapter: ChapterIdentity) {
        visibleReaderChapter = chapter
    }

    func readerDidDisappear() {
        visibleReaderChapter = nil
    }
}

nonisolated enum LiveActivityDestination: Hashable, Identifiable, Sendable {
    case downloads
    case privacy
    case reader(manga: MangaIdentity, context: ReaderLaunchContext)

    var id: String {
        switch self {
        case .downloads:
            "downloads"
        case .privacy:
            "privacy"
        case .reader(let manga, let context):
            "reader:\(manga.sourceID):\(manga.mangaID):\(context.chapter.chapterID):\(context.pageIndex ?? 0)"
        }
    }

    init?(url: URL) {
        guard url.scheme?.lowercased() == "keihatsu", let host = url.host?.lowercased() else { return nil }
        if host == "downloads" {
            self = .downloads
            return
        }
        if host == "privacy" {
            self = .privacy
            return
        }
        guard host == "reader",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let values = (components.queryItems ?? []).reduce(into: [String: String]()) { result, item in
            if result[item.name] == nil, let value = item.value {
                result[item.name] = value
            }
        }
        guard let sourceID = values["source"], !sourceID.isEmpty,
              let mangaID = values["manga"], !mangaID.isEmpty,
              let chapterID = values["chapter"], !chapterID.isEmpty else { return nil }
        let manga = MangaIdentity(sourceID: sourceID, mangaID: mangaID)
        let chapter = ChapterIdentity(manga: manga, chapterID: chapterID)
        let page = values["page"].flatMap(Int.init).map { max($0, 0) }
        self = .reader(
            manga: manga,
            context: ReaderLaunchContext(chapter: chapter, origin: .history, pageIndex: page)
        )
    }
}

/// Contracts for future API-backed destinations. Sample screens keep their existing routes.
nonisolated enum ContentRoute: Hashable, Sendable {
    case manga(MangaIdentity)
    case reader(ReaderLaunchContext)
}
