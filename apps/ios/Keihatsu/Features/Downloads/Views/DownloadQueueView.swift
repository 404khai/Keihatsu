import SwiftUI

struct DownloadQueueView: View {
    @EnvironmentObject private var downloads: DownloadCoordinator
    @State private var pendingRemoval: ChapterDownloadRecord?
    @State private var pendingMangaCancellation: ChapterDownloadRecord?

    private var grouped: [(name: String, records: [ChapterDownloadRecord])] {
        let extensions = Dictionary(grouping: downloads.activeRecords, by: \.request.extensionName)
        return extensions.keys.sorted().map { extensionName in
            (extensionName, (extensions[extensionName] ?? []).sorted { $0.priority < $1.priority })
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
                    ForEach(grouped, id: \.name) { group in
                        Section {
                            ForEach(group.records) { record in
                                HStack(spacing: 8) {
                                    DownloadRecordRow(
                                        record: record,
                                        pause: { downloads.pause(record.id) },
                                        resume: { downloads.resume(record.id) }
                                    )

                                    Button {
                                        pendingMangaCancellation = record
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Cancel all downloads for \(record.request.mangaTitle)")
                                }
                                .swipeActions {
                                    Button("Remove", systemImage: "trash", role: .destructive) { pendingRemoval = record }
                                }
                                .contextMenu {
                                    Button("Move to Front", systemImage: "arrow.up.to.line") { downloads.moveToFront(record.id) }
                                    Button("Cancel Manga Downloads", systemImage: "xmark.circle", role: .destructive) {
                                        pendingMangaCancellation = record
                                    }
                                    Button("Remove Chapter", systemImage: "trash", role: .destructive) { pendingRemoval = record }
                                }
                            }
                            .onMove { offsets, destination in
                                downloads.move(in: group.name, from: offsets, to: destination)
                            }
                        } header: {
                            Label(group.name, systemImage: "puzzlepiece.extension")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, .constant(.active))
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
        .confirmationDialog(
            "Cancel downloads for \(pendingMangaCancellation?.request.mangaTitle ?? "this manga")?",
            isPresented: Binding(
                get: { pendingMangaCancellation != nil },
                set: { if !$0 { pendingMangaCancellation = nil } }
            ),
            presenting: pendingMangaCancellation
        ) { record in
            Button("Cancel All Manga Downloads", role: .destructive) {
                let identity = MangaIdentity(
                    sourceID: record.request.identity.sourceID,
                    mangaID: record.request.identity.mangaID
                )
                Task { await downloads.cancelDownloads(for: identity) }
            }
        } message: { record in
            Text("Every queued or in-progress chapter for \(record.request.mangaTitle) will be removed from this extension's queue.")
        }
    }
}
