import ActivityKit
import SwiftUI
import WidgetKit

struct ReadingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingActivityAttributes.self) { context in
            ReadingLockScreenView(context: context)
                .activityBackgroundTint(Color.keihatsuActivityBackground)
                .activitySystemActionForegroundColor(.white)
                .widgetURL(LiveActivityLink.reader(attributes: context.attributes, state: context.state))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ReadingActivityIcon()
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ReadingPageCount(state: context.state)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ReadingActivityDetails(state: context.state, isStale: context.isStale, isExpanded: true)
                        .padding(.horizontal, 8)
                }
            } compactLeading: {
                ReadingActivityIcon()
            } compactTrailing: {
                ReadingPageCount(state: context.state, compact: true)
            } minimal: {
                ReadingActivityIcon(progress: context.state.progress, size: 24)
                    .accessibilityLabel(
                        "Reading page \(context.state.currentPage) of \(context.state.totalPages)"
                    )
            }
            .contentMargins(.horizontal, 16, for: .expanded)
            .keylineTint(Color.keihatsuActivityAccent)
            .widgetURL(LiveActivityLink.reader(attributes: context.attributes, state: context.state))
        }
    }
}

private struct ReadingLockScreenView: View {
    let context: ActivityViewContext<ReadingActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                ReadingActivityIcon(size: 20)
                Text(statusLabel)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                ReadingPageCount(state: context.state)
            }

            ReadingActivityDetails(state: context.state, isStale: context.isStale)
        }
        .padding(14)
    }

    private var statusLabel: String {
        switch context.state.status {
        case .reading: "Reading"
        case .paused: "Reading paused"
        case .finished: "Finished"
        }
    }
}

private struct ReadingActivityDetails: View {
    let state: ReadingActivityAttributes.ContentState
    let isStale: Bool
    var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.mangaTitle)
                    .font((isExpanded ? Font.subheadline : Font.headline).weight(.semibold))
                    .lineLimit(1)
                    .privacySensitive()
                Text(state.chapterName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .privacySensitive()
            }

            ProgressView(value: state.progress)
                .tint(Color.keihatsuActivityAccent)

            Text(progressLabel)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var progressLabel: String {
        let percent = state.progress.formatted(.percent.precision(.fractionLength(0)))
        return isStale ? "Last known · \(percent) read" : "\(percent) read"
    }
}

private struct ReadingActivityIcon: View {
    var progress: Double?
    var size: CGFloat

    init(progress: Double? = nil, size: CGFloat = 22) {
        self.progress = progress
        self.size = size
    }

    var body: some View {
        ZStack {
            if let progress {
                Circle()
                    .stroke(Color.keihatsuActivityAccent.opacity(0.28), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(Color.keihatsuActivityAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            Image(systemName: "book.fill")
                .font(.system(size: size * (progress == nil ? 0.7 : 0.42), weight: .semibold))
                .foregroundStyle(Color.keihatsuActivityAccent)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Reading")
    }
}

private struct ReadingPageCount: View {
    let state: ReadingActivityAttributes.ContentState
    var compact = false

    var body: some View {
        Text(compact ? "\(state.currentPage)/\(state.totalPages)" : "\(state.currentPage) of \(state.totalPages)")
            .font((compact ? Font.caption2 : Font.caption).monospacedDigit().weight(.semibold))
            .foregroundStyle(Color.keihatsuActivityAccent)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .minimumScaleFactor(0.8)
            .accessibilityLabel("Page \(state.currentPage) of \(state.totalPages)")
    }
}

#Preview("Reading Lock • Page 2", as: .content, using: ReadingActivityAttributes(sessionID: UUID())) {
    ReadingLiveActivityWidget()
} contentStates: {
    ReadingActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations", chapterName: "Chapter 52",
        sourceID: "preview", mangaID: "manga", chapterID: "chapter-52",
        currentPage: 2, totalPages: 21, status: .reading, updatedAt: .now
    )
    ReadingActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations", chapterName: "Chapter 52",
        sourceID: "preview", mangaID: "manga", chapterID: "chapter-52",
        currentPage: 14, totalPages: 28, status: .paused, updatedAt: .now
    )
    ReadingActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations", chapterName: "Chapter 52",
        sourceID: "preview", mangaID: "manga", chapterID: "chapter-52",
        currentPage: 21, totalPages: 21, status: .finished, updatedAt: .now
    )
}

#Preview("Reading Compact", as: .dynamicIsland(.compact), using: ReadingActivityAttributes(sessionID: UUID())) {
    ReadingLiveActivityWidget()
} contentStates: {
    ReadingActivityAttributes.ContentState(
        mangaTitle: "Manga", chapterName: "Chapter 52",
        sourceID: "preview", mangaID: "manga", chapterID: "chapter-52",
        currentPage: 2, totalPages: 21, status: .reading, updatedAt: .now
    )
}

#Preview("Reading Expanded • Long Title", as: .dynamicIsland(.expanded), using: ReadingActivityAttributes(sessionID: UUID())) {
    ReadingLiveActivityWidget()
} contentStates: {
    ReadingActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations", chapterName: "Chapter 52",
        sourceID: "preview", mangaID: "manga", chapterID: "chapter-52",
        currentPage: 14, totalPages: 28, status: .reading, updatedAt: .now
    )
}

#Preview("Reading Minimal", as: .dynamicIsland(.minimal), using: ReadingActivityAttributes(sessionID: UUID())) {
    ReadingLiveActivityWidget()
} contentStates: {
    ReadingActivityAttributes.ContentState(
        mangaTitle: "Manga", chapterName: "Chapter 52",
        sourceID: "preview", mangaID: "manga", chapterID: "chapter-52",
        currentPage: 2, totalPages: 21, status: .reading, updatedAt: .now
    )
}
