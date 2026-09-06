import SwiftUI

struct ReaderEntryView: View {
    let manga: Manga
    let chapters: [Chapter]
    let context: ReaderLaunchContext

    private var chapter: Chapter? { chapters.first { $0.id == context.chapter } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ContentUnavailableView {
                Label("Reader unavailable", systemImage: "book.pages")
            } description: {
                Text("Pages for \(chapter?.name ?? "this chapter") aren’t available in this build.")
            }
            .foregroundStyle(.white)
        }
        .navigationTitle(manga.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("reader.entry")
    }
}
