import SwiftUI

struct DataStorageView: View {
    @EnvironmentObject private var downloads: DownloadCoordinator
    @State private var pendingDeletion: ChapterDownloadRecord?

    var body: some View {
        List {
            Section("On this device") {
                LabeledContent("Offline chapters", value: "\(downloads.storage.archiveCount)")
                LabeledContent("Download storage", value: ByteCountFormatter.string(fromByteCount: downloads.storage.byteCount, countStyle: .file))
                Text("CBZ files are stored under Keihatsu/downloads/extension/manga/chapter and are separate from disposable image cache.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Section("Saved chapters") {
                if downloads.completedRecords.isEmpty {
                    ContentUnavailableView("No offline chapters", systemImage: "books.vertical", description: Text("Completed chapter downloads will be listed here."))
                }
                ForEach(downloads.completedRecords) { record in
                    VStack(alignment: .leading, spacing: 8) {
                        DownloadRecordRow(record: record, pause: {}, resume: {})
                        HStack {
                            ShareLink(item: downloads.exportURL(for: record)) {
                                Label("Export CBZ", systemImage: "square.and.arrow.up")
                            }
                            Spacer()
                            Button("Delete", systemImage: "trash", role: .destructive) { pendingDeletion = record }
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Data & Storage")
        .task { await downloads.refreshStorage() }
        .refreshable { await downloads.refreshStorage() }
        .confirmationDialog(
            "Delete offline chapter?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { record in
            Button("Delete CBZ", role: .destructive) { Task { await downloads.remove(record.id) } }
        } message: { record in
            Text("\(record.request.chapterName) will no longer be available offline. Reading history is kept.")
        }
    }
}
