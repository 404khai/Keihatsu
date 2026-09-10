import Foundation

@MainActor
final class PagePrefetcher {
    private let pipeline: ImagePipeline
    private var tasks: [ReaderPage.ID: Task<Void, Never>] = [:]
    private let radius: Int

    init(pipeline: ImagePipeline, radius: Int = 2) {
        self.pipeline = pipeline
        self.radius = radius
    }

    func update(around page: ReaderPage, in pages: [ReaderPage]) {
        guard let index = pages.firstIndex(where: { $0.id == page.id }) else { return }
        let lower = max(0, index - radius)
        let upper = min(pages.count - 1, index + radius)
        let wanted = Set(pages[lower...upper].map(\.id))

        for (id, task) in tasks where !wanted.contains(id) {
            task.cancel()
            tasks[id] = nil
        }
        for value in pages[lower...upper] where tasks[value.id] == nil {
            tasks[value.id] = Task { [pipeline] in
                _ = try? await pipeline.readerImage(url: value.imageURL, referer: value.refererURL)
            }
        }
    }

    func cancel() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
