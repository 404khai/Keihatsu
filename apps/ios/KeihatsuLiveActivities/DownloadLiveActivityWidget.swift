import ActivityKit
import SwiftUI
import WidgetKit

struct DownloadLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadActivityAttributes.self) { context in
            DownloadLockScreenView(context: context)
                .activityBackgroundTint(Color.keihatsuActivityBackground)
                .activitySystemActionForegroundColor(.white)
                .widgetURL(LiveActivityLink.downloads())
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DownloadProgressIcon(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    DownloadPercentage(progress: context.state.progress)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    DownloadExpandedDetails(state: context.state, isStale: context.isStale)
                }
            } compactLeading: {
                DownloadProgressIcon(state: context.state, size: 23)
            } compactTrailing: {
                DownloadPercentage(progress: context.state.progress, compact: true)
            } minimal: {
                DownloadProgressIcon(state: context.state, size: 24)
                    .accessibilityLabel(downloadAccessibilityLabel(context.state.progress))
            }
            .keylineTint(Color.keihatsuActivityAccent)
            .widgetURL(LiveActivityLink.downloads())
        }
    }

    private func downloadAccessibilityLabel(_ progress: Double) -> String {
        let percent = Int((min(max(progress, 0), 1) * 100).rounded())
        return "Download \(percent) percent complete"
    }
}

private struct DownloadLockScreenView: View {
    let context: ActivityViewContext<DownloadActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                DownloadProgressIcon(state: context.state, size: 22)
                Text(context.isStale ? "Last update" : context.state.status.label)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                DownloadPercentage(progress: context.state.progress)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.mangaTitle)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .privacySensitive()
                Text(lockScreenDetail)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .privacySensitive(context.state.totalChapters == 1)
            }

            ProgressView(value: context.state.progress)
                .tint(Color.keihatsuActivityAccent)
        }
        .padding(14)
    }

    private var lockScreenDetail: String {
        if context.state.totalChapters == 1, context.state.chapterName != "Keihatsu" {
            return context.state.chapterName
        }
        return chapterCount(context.state)
    }
}

private struct DownloadExpandedDetails: View {
    let state: DownloadActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.mangaTitle)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .privacySensitive()
                Text(statusDetail)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .privacySensitive(state.totalChapters == 1)
            }

            ProgressView(value: state.progress)
                .tint(Color.keihatsuActivityAccent)

            if state.totalChapters > 1 {
                Text(chapterCount(state))
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var statusDetail: String {
        if isStale { return "Last known download progress" }

        if state.totalChapters == 1 {
            let chapter = state.chapterName == "Keihatsu" ? "chapter" : state.chapterName
            switch state.status {
            case .queued: return "Queued \(chapter)"
            case .resolving: return "Preparing \(chapter)"
            case .downloading: return "Downloading \(chapter)"
            case .packaging: return "Saving \(chapter)"
            case .paused: return "Paused \(chapter)"
            case .waitingForWiFi: return "Waiting for Wi-Fi"
            case .failed: return "Couldn’t download \(chapter)"
            case .completed: return "Downloaded \(chapter)"
            }
        }

        return switch state.status {
        case .queued: "Chapters queued"
        case .resolving: "Preparing chapters"
        case .downloading: "Downloading chapters"
        case .packaging: "Saving chapters"
        case .paused: "Chapter downloads paused"
        case .waitingForWiFi: "Waiting for Wi-Fi"
        case .failed: "Chapter download failed"
        case .completed: "Chapters downloaded"
        }
    }
}

private struct DownloadProgressIcon: View {
    let state: DownloadActivityAttributes.ContentState
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.keihatsuActivityAccent.opacity(0.28), lineWidth: 2)
            Circle()
                .trim(from: 0, to: min(max(state.progress, 0), 1))
                .stroke(Color.keihatsuActivityAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Image(systemName: state.status == .completed ? "checkmark" : "arrow.down")
                .font(.system(size: size * 0.43, weight: .bold))
                .foregroundStyle(Color.keihatsuActivityAccent)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(state.status == .completed ? "Download complete" : "Downloading")
    }
}

private struct DownloadPercentage: View {
    let progress: Double
    var compact = false

    var body: some View {
        Text(progress, format: .percent.precision(.fractionLength(0)))
            .font((compact ? Font.caption2 : Font.caption).monospacedDigit().weight(.semibold))
            .foregroundStyle(Color.keihatsuActivityAccent)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

private func chapterCount(_ state: DownloadActivityAttributes.ContentState) -> String {
    "\(state.completedChapters) of \(state.totalChapters) chapters"
}

#Preview("Downloads Lock • Multi-chapter", as: .content, using: DownloadActivityAttributes(batchID: UUID())) {
    DownloadLiveActivityWidget()
} contentStates: {
    DownloadActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations", chapterName: "Chapter 52",
        completedChapters: 0, totalChapters: 12, progress: 0,
        status: .queued, updatedAt: .now
    )
    DownloadActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations", chapterName: "Chapter 52",
        completedChapters: 8, totalChapters: 12, progress: 0.67,
        status: .downloading, updatedAt: .now
    )
    DownloadActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations", chapterName: "Chapter 52",
        completedChapters: 12, totalChapters: 12, progress: 1,
        status: .completed, updatedAt: .now
    )
}

#Preview("Downloads Compact • 67%", as: .dynamicIsland(.compact), using: DownloadActivityAttributes(batchID: UUID())) {
    DownloadLiveActivityWidget()
} contentStates: {
    DownloadActivityAttributes.ContentState(
        mangaTitle: "Manga", chapterName: "Chapter 52",
        completedChapters: 8, totalChapters: 12, progress: 0.67,
        status: .downloading, updatedAt: .now
    )
}

#Preview("Downloads Expanded • Long Title", as: .dynamicIsland(.expanded), using: DownloadActivityAttributes(batchID: UUID())) {
    DownloadLiveActivityWidget()
} contentStates: {
    DownloadActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations", chapterName: "Chapter 52",
        completedChapters: 8, totalChapters: 12, progress: 0.67,
        status: .downloading, updatedAt: .now
    )
}

#Preview("Downloads Minimal • 0%", as: .dynamicIsland(.minimal), using: DownloadActivityAttributes(batchID: UUID())) {
    DownloadLiveActivityWidget()
} contentStates: {
    DownloadActivityAttributes.ContentState(
        mangaTitle: "Manga", chapterName: "Chapter 52",
        completedChapters: 0, totalChapters: 1, progress: 0,
        status: .queued, updatedAt: .now
    )
}
