import SwiftUI
import WidgetKit

@main
struct KeihatsuLiveActivitiesBundle: WidgetBundle {
    var body: some Widget {
        ReadingLiveActivityWidget()
        DownloadLiveActivityWidget()
        IncognitoLiveActivityWidget()
    }
}
