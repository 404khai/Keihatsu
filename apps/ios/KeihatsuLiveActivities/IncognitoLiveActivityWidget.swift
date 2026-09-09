import ActivityKit
import SwiftUI
import WidgetKit

struct IncognitoLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IncognitoActivityAttributes.self) { _ in
            IncognitoLockScreenView()
                .activityBackgroundTint(Color.keihatsuActivityBackground)
                .activitySystemActionForegroundColor(.white)
                .widgetURL(LiveActivityLink.privacy())
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    KeihatsuActivityMark()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "theatermasks")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.keihatsuActivityAccent)
                        .accessibilityLabel("Incognito mode")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    IncognitoActivityDetails()
                        .padding(.top, 2)
                }
            } compactLeading: {
                KeihatsuActivityMark()
                    .accessibilityLabel("Keihatsu")
            } compactTrailing: {
                Image(systemName: "theatermasks")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.keihatsuActivityAccent)
                    .accessibilityLabel("Incognito mode")
            } minimal: {
                Image(systemName: "theatermasks")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.keihatsuActivityAccent)
                    .accessibilityLabel("Keihatsu incognito mode")
            }
            .keylineTint(Color.keihatsuActivityAccent)
            .widgetURL(LiveActivityLink.privacy())
        }
    }
}

private struct IncognitoLockScreenView: View {
    var body: some View {
        HStack(spacing: 12) {
            KeihatsuActivityMark(size: 34)
            IncognitoActivityDetails()
        }
        .padding(14)
    }
}

private struct IncognitoActivityDetails: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Incognito mode is on")
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                Text("Reading history and progress won’t be saved")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Image(systemName: "theatermasks")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.keihatsuActivityAccent)
                .accessibilityHidden(true)
        }
    }
}

private struct KeihatsuActivityMark: View {
    var size: CGFloat = 22

    var body: some View {
        Text("K")
            .font(.system(size: size * 0.56, weight: .black, design: .rounded))
            .foregroundStyle(.black)
            .frame(width: size, height: size)
            .background(Color.keihatsuActivityAccent, in: Circle())
    }
}

#Preview("Incognito", as: .content, using: IncognitoActivityAttributes(sessionID: UUID())) {
    IncognitoLiveActivityWidget()
} contentStates: {
    IncognitoActivityAttributes.ContentState(enabledAt: .now, updatedAt: .now)
}
