import SwiftUI

struct DataStorageView: View {
    @EnvironmentObject private var downloads: DownloadCoordinator
    @EnvironmentObject private var preferencesStore: AppPreferencesStore

    private var accent: Color { Color(hex: preferencesStore.preferences.theme.hex) }
    private var mangaFraction: CGFloat {
        let manga = max(downloads.storage.byteCount, 0)
        let available = max(downloads.storage.availableByteCount, 0)
        let represented = manga + available
        guard represented > 0 else { return 0 }
        return CGFloat(Double(manga) / Double(represented))
    }

    var body: some View {
        List {
            Section("On this device") {
                VStack(alignment: .leading, spacing: 18) {
                    GeometryReader { proxy in
                        HStack(spacing: 0) {
                            accent
                                .frame(width: proxy.size.width * mangaFraction)
                            Color(.tertiarySystemFill)
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 16)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Device storage for manga downloads")
                    .accessibilityValue("\(mangaStorageLabel) used by manga, \(availableStorageLabel) available")

                    storageLegend

                    Text("CBZ files are stored under Keihatsu/downloads/extension/manga/chapter.cbz and are separate from disposable image cache.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Data & Storage")
        .toolbar(.hidden, for: .tabBar)
        .task { await downloads.refreshStorage() }
        .refreshable { await downloads.refreshStorage() }
    }

    private var storageLegend: some View {
        VStack(spacing: 12) {
            storageLegendRow(color: accent, title: "Manga", value: mangaStorageLabel)
            storageLegendRow(color: Color(.tertiarySystemFill), title: "Available", value: availableStorageLabel)
        }
    }

    private func storageLegendRow(color: Color, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private var mangaStorageLabel: String {
        ByteCountFormatter.string(fromByteCount: downloads.storage.byteCount, countStyle: .file)
    }

    private var availableStorageLabel: String {
        ByteCountFormatter.string(fromByteCount: downloads.storage.availableByteCount, countStyle: .file)
    }
}
