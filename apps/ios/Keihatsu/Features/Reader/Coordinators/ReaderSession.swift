import Foundation

@MainActor
final class ReaderSession {
    let id = UUID()
    private(set) var latestEvent: ReaderSessionEvent?
    private var activeSince: ContinuousClock.Instant?
    private var accumulated: Duration = .zero

    func start(chapter: ChapterIdentity, now: Date = .now) {
        activeSince = .now
        latestEvent = .started(sessionID: id, chapter: chapter, at: now)
    }

    func visible(_ page: ReaderPage.ID, now: Date = .now) {
        latestEvent = .visiblePageChanged(sessionID: id, page: page, at: now)
    }

    func suspend(chapter: ChapterIdentity, pageIndex: Int, now: Date = .now) {
        pauseClock()
        latestEvent = .suspended(sessionID: id, chapter: chapter, pageIndex: pageIndex, at: now)
    }

    func resume() {
        guard activeSince == nil else { return }
        activeSince = .now
    }

    func end(chapter: ChapterIdentity, pageIndex: Int, now: Date = .now) {
        pauseClock()
        latestEvent = .ended(sessionID: id, chapter: chapter, pageIndex: pageIndex, at: now)
    }

    func consumeActiveSeconds() -> Double {
        if let activeSince {
            accumulated += activeSince.duration(to: .now)
            self.activeSince = .now
        }
        let seconds = Double(accumulated.components.seconds) + Double(accumulated.components.attoseconds) / 1e18
        accumulated = .zero
        return max(seconds, 0)
    }

    private func pauseClock() {
        guard let activeSince else { return }
        accumulated += activeSince.duration(to: .now)
        self.activeSince = nil
    }
}
