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
                    Label("Keihatsu", systemImage: "arrow.down.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.keihatsuActivityAccent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.progress, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.keihatsuActivityAccent)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    DownloadActivityDetails(state: context.state, isStale: context.isStale)
                        .padding(.top, 2)
                }
            } compactLeading: {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(Color.keihatsuActivityAccent)
                    .accessibilityLabel("Keihatsu downloads")
            } compactTrailing: {
                Text(context.state.progress, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.keihatsuActivityAccent)
            } minimal: {
                ZStack {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.circular)
                        .tint(Color.keihatsuActivityAccent)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Download \(context.state.progress.formatted(.percent.precision(.fractionLength(0)))) complete")
            }
            .keylineTint(Color.keihatsuActivityAccent)
            .widgetURL(LiveActivityLink.downloads())
        }
    }
}

private struct DownloadLockScreenView: View {
    let context: ActivityViewContext<DownloadActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Keihatsu", systemImage: "arrow.down.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.keihatsuActivityAccent)
                Spacer()
                Text(context.state.status.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            DownloadActivityDetails(state: context.state, isStale: context.isStale)
        }
        .padding(14)
    }
}

private struct DownloadActivityDetails: View {
    let state: DownloadActivityAttributes.ContentState
    var isStale = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.mangaTitle)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .privacySensitive()
                    Text(state.chapterName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .privacySensitive()
                }
                Spacer(minLength: 8)
                Text(state.progress, format: .percent.precision(.fractionLength(0)))
                    .font(.headline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.keihatsuActivityAccent)
            }
            ProgressView(value: state.progress)
                .tint(Color.keihatsuActivityAccent)
            HStack {
                Text("\(state.completedChapters) of \(state.totalChapters) chapters")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(isStale ? "Last update" : state.status.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(state.status == .failed ? Color.red : Color.keihatsuActivityAccent)
            }
        }
    }
}

#Preview("Downloads", as: .content, using: DownloadActivityAttributes(batchID: UUID())) {
    DownloadLiveActivityWidget()
} contentStates: {
    DownloadActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations",
        chapterName: "Chapter 52",
        completedChapters: 2, totalChapters: 5, progress: 0.46,
        status: .downloading, updatedAt: .now
    )
}
