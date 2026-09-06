import SwiftUI

struct ReaderEntryView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var history: ReadingHistoryModel
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    let manga: Manga
    let chapters: [Chapter]
    let context: ReaderLaunchContext

    var body: some View {
        ReaderView(
            manga: manga,
            chapters: chapters,
            context: context,
            reader: environment.services.reader,
            history: history,
            imagePipeline: environment.imagePipeline,
            incognito: preferencesStore.preferences.incognitoModeEnabled
        )
    }
}
