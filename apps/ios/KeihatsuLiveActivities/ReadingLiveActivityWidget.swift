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
                    Label("Keihatsu", systemImage: "book.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.keihatsuActivityAccent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.currentPage)/\(context.state.totalPages)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.keihatsuActivityAccent)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ReadingActivityDetails(state: context.state, showsAction: true, isStale: context.isStale)
                        .padding(.top, 2)
                }
            } compactLeading: {
                Image(systemName: "book.fill")
                    .foregroundStyle(Color.keihatsuActivityAccent)
                    .accessibilityLabel("Keihatsu reading")
            } compactTrailing: {
                Text("\(context.state.currentPage)/\(context.state.totalPages)")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.keihatsuActivityAccent)
            } minimal: {
                ZStack {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.circular)
                        .tint(Color.keihatsuActivityAccent)
                    Image(systemName: "book.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Reading page \(context.state.currentPage) of \(context.state.totalPages)")
            }
            .keylineTint(Color.keihatsuActivityAccent)
            .widgetURL(LiveActivityLink.reader(attributes: context.attributes, state: context.state))
        }
    }
}

private struct ReadingLockScreenView: View {
    let context: ActivityViewContext<ReadingActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Keihatsu", systemImage: "book.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.keihatsuActivityAccent)
                Spacer()
                Text(context.state.status == .reading ? "Reading" : "Reading paused")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            ReadingActivityDetails(
                state: context.state,
                showsAction: context.state.status != .reading,
                isStale: context.isStale
            )
        }
        .padding(14)
    }
}

private struct ReadingActivityDetails: View {
    let state: ReadingActivityAttributes.ContentState
    let showsAction: Bool
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
                Text("Page \(state.currentPage) of \(state.totalPages)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.keihatsuActivityAccent)
                    .lineLimit(1)
            }
            ProgressView(value: state.progress)
                .tint(Color.keihatsuActivityAccent)
            if showsAction {
                HStack {
                    Text(summary)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("Continue reading", systemImage: "arrow.up.forward.app")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.keihatsuActivityAccent)
                }
            }
        }
    }

    private var summary: String {
        if isStale { return "Last known position" }
        return state.status == .finished ? "Session ended" : "Progress saved"
    }
}

#Preview("Reading", as: .content, using: ReadingActivityAttributes(sessionID: UUID())) {
    ReadingLiveActivityWidget()
} contentStates: {
    ReadingActivityAttributes.ContentState(
        mangaTitle: "The Regressed Mercenary’s Machinations",
        chapterName: "Chapter 52",
        sourceID: "preview", mangaID: "manga", chapterID: "chapter-52",
        currentPage: 14, totalPages: 28, status: .reading, updatedAt: .now
    )
}
