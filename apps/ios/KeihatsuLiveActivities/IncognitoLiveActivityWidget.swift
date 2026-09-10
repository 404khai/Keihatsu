import ActivityKit
import SwiftUI
import WidgetKit

struct IncognitoLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IncognitoActivityAttributes.self) { context in
            IncognitoLockScreenView(state: context.state)
                .activityBackgroundTint(Color.keihatsuActivityBackground)
                .activitySystemActionForegroundColor(.white)
                .widgetURL(LiveActivityLink.privacy())
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IncognitoActivityIcon()
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.pagePosition != nil {
                        IncognitoStatusText(state: context.state)
                            .padding(.trailing, 4)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    IncognitoActivityDetails(isReading: context.state.pagePosition != nil)
                        .padding(.horizontal, 4)
                }
            } compactLeading: {
                IncognitoActivityIcon()
            } compactTrailing: {
                IncognitoStatusText(state: context.state)
            } minimal: {
                IncognitoActivityIcon()
            }
            .contentMargins(.horizontal, 12, for: .expanded)
            .keylineTint(Color.keihatsuActivityAccent)
            .widgetURL(LiveActivityLink.privacy())
        }
    }
}

private struct IncognitoLockScreenView: View {
    let state: IncognitoActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            IncognitoActivityIcon(size: 34)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(state.pagePosition == nil ? "Incognito mode is on" : "Private reading")
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if state.pagePosition != nil {
                        IncognitoStatusText(state: state)
                    }
                }

                Text("History and progress won’t be saved")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
    }
}

private struct IncognitoActivityDetails: View {
    let isReading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(isReading ? "Private reading" : "Incognito mode is on")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text("History and progress won’t be saved")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct IncognitoStatusText: View {
    let state: IncognitoActivityAttributes.ContentState

    var body: some View {
        Text(state.pagePosition ?? "ON")
            .font(.caption2.monospacedDigit().weight(.semibold))
            .foregroundStyle(Color.keihatsuActivityAccent)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityLabel(state.pagePosition.map { "Reading page \($0)" } ?? "Incognito mode on")
    }
}

private struct IncognitoActivityIcon: View {
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: "eyeglasses")
            .font(.system(size: size * 0.62, weight: .semibold))
            .foregroundStyle(Color.keihatsuActivityAccent)
            .frame(width: size, height: size)
            .accessibilityLabel("Incognito mode")
    }
}

#Preview("Incognito Lock Screen", as: .content, using: IncognitoActivityAttributes(sessionID: UUID())) {
    IncognitoLiveActivityWidget()
} contentStates: {
    IncognitoActivityAttributes.ContentState(
        enabledAt: .now, updatedAt: .now,
        isReading: false, currentPage: nil, totalPages: nil
    )
    IncognitoActivityAttributes.ContentState(
        enabledAt: .now, updatedAt: .now,
        isReading: true, currentPage: 14, totalPages: 35
    )
}

#Preview("Incognito Compact • Idle", as: .dynamicIsland(.compact), using: IncognitoActivityAttributes(sessionID: UUID())) {
    IncognitoLiveActivityWidget()
} contentStates: {
    IncognitoActivityAttributes.ContentState(
        enabledAt: .now, updatedAt: .now,
        isReading: false, currentPage: nil, totalPages: nil
    )
}

#Preview("Incognito Compact • Reading", as: .dynamicIsland(.compact), using: IncognitoActivityAttributes(sessionID: UUID())) {
    IncognitoLiveActivityWidget()
} contentStates: {
    IncognitoActivityAttributes.ContentState(
        enabledAt: .now, updatedAt: .now,
        isReading: true, currentPage: 2, totalPages: 21
    )
}

#Preview("Incognito Expanded • Reading", as: .dynamicIsland(.expanded), using: IncognitoActivityAttributes(sessionID: UUID())) {
    IncognitoLiveActivityWidget()
} contentStates: {
    IncognitoActivityAttributes.ContentState(
        enabledAt: .now, updatedAt: .now,
        isReading: true, currentPage: 14, totalPages: 35
    )
}
