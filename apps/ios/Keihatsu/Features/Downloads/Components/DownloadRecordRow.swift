import SwiftUI

struct DownloadRecordRow: View {
    let record: ChapterDownloadRecord
    let pause: () -> Void
    let resume: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            CatalogueCover(url: record.request.thumbnailURL, referer: nil)
                .frame(width: 52, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(record.request.mangaTitle).font(.headline).lineLimit(1)
                Text(record.request.chapterName).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 6) {
                    Text(statusLabel)
                    if record.pageCount > 0 {
                        Text("• \(record.completedPageCount)/\(record.pageCount) pages")
                    }
                }
                .font(.caption)
                .foregroundStyle(record.status == .failed ? .red : .secondary)
                if record.status != .completed {
                    ProgressView(value: record.progress).progressViewStyle(.linear)
                }
            }

            Spacer(minLength: 4)
            action
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.request.mangaTitle), \(record.request.chapterName), \(statusLabel)")
    }

    @ViewBuilder private var action: some View {
        switch record.status {
        case .downloading, .resolving, .packaging, .queued:
            Button(action: pause) { Image(systemName: "pause.circle.fill") }
                .font(.title2).accessibilityLabel("Pause download")
        case .paused, .waitingForWiFi, .failed:
            Button(action: resume) { Image(systemName: record.status == .failed ? "arrow.clockwise.circle.fill" : "play.circle.fill") }
                .font(.title2).accessibilityLabel(record.status == .failed ? "Retry download" : "Resume download")
        case .completed:
            Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(Color(hex: "B7FF3C"))
        }
    }

    private var statusLabel: String {
        switch record.status {
        case .queued: "Queued"
        case .resolving: "Preparing pages"
        case .downloading: "Downloading"
        case .packaging: "Creating CBZ"
        case .paused: "Paused"
        case .waitingForWiFi: record.errorMessage ?? "Waiting for Wi-Fi"
        case .failed: record.errorMessage ?? "Download failed"
        case .completed: "Saved as CBZ"
        }
    }
}
