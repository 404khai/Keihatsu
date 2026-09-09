import SwiftUI

struct DownloadQueueView: View {
    @EnvironmentObject private var downloads: DownloadCoordinator
    @State private var pendingRemoval: ChapterDownloadRecord?

    private var grouped: [(String, [(String, [ChapterDownloadRecord])])] {
        let extensions = Dictionary(grouping: downloads.activeRecords, by: \.request.extensionName)
        return extensions.keys.sorted().map { extensionName in
            let mangas = Dictionary(grouping: extensions[extensionName] ?? [], by: \.request.mangaTitle)
            return (extensionName, mangas.keys.sorted().map { ($0, (mangas[$0] ?? []).sorted { $0.priority < $1.priority }) })
        }
    }

    var body: some View {
        Group {
            if downloads.isRestoring {
                ProgressView("Restoring downloads…")
            } else if downloads.activeRecords.isEmpty {
                ContentUnavailableView {
                    Label("No active downloads", systemImage: "arrow.down.circle")
                } description: {
                    Text("Chapters queued from manga details will appear here.")
                }
            } else {
                List {
                    ForEach(grouped, id: \.0) { extensionName, mangas in
                        Section {
                            ForEach(mangas, id: \.0) { mangaTitle, records in
                                DisclosureGroup {
                                    ForEach(records) { record in
                                        DownloadRecordRow(
                                            record: record,
                                            pause: { downloads.pause(record.id) },
                                            resume: { downloads.resume(record.id) }
                                        )
                                        .swipeActions {
                                            Button("Remove", systemImage: "trash", role: .destructive) { pendingRemoval = record }
                                        }
                                        .contextMenu {
                                            Button("Move to Front", systemImage: "arrow.up.to.line") { downloads.moveToFront(record.id) }
                                            Button("Remove", systemImage: "trash", role: .destructive) { pendingRemoval = record }
                                        }
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(mangaTitle).font(.headline)
                                        Text(chapterCountLabel(records.count))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Label(extensionName, systemImage: "puzzlepiece.extension")
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Download Queue")
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    downloads.toggleGlobalPause()
                } label: {
                    Image(systemName: downloads.isGloballyPaused ? "play.fill" : "pause.fill")
                }
                .accessibilityLabel(downloads.isGloballyPaused ? "Resume all downloads" : "Pause all downloads")
            }
        }
        .confirmationDialog(
            "Remove this download?",
            isPresented: Binding(
                get: { pendingRemoval != nil },
                set: { if !$0 { pendingRemoval = nil } }
            ),
            presenting: pendingRemoval
        ) { record in
            Button("Remove Download", role: .destructive) { Task { await downloads.remove(record.id) } }
        } message: { record in
            Text("Downloaded pages and any completed CBZ for \(record.request.chapterName) will be removed.")
        }
    }

    private func chapterCountLabel(_ count: Int) -> String {
        "\(count) \(count == 1 ? "chapter" : "chapters")"
    }
}
