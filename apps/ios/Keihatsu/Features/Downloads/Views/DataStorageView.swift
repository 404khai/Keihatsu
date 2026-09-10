import SwiftUI
import UniformTypeIdentifiers

struct DataStorageView: View {
    @EnvironmentObject private var downloads: DownloadCoordinator
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @State private var showsDirectoryPicker = false
    @State private var directoryError: String?

    private var accent: Color { Color(hex: preferencesStore.preferences.theme.hex) }
    private var mangaFraction: CGFloat {
        let manga = max(downloads.storage.byteCount, 0)
        let available = max(downloads.storage.availableByteCount, 0)
        let represented = manga + available
        guard represented > 0 else { return 0 }
        return CGFloat(Double(manga) / Double(represented))
    }
    private var displayedMangaFraction: CGFloat {
        guard downloads.storage.byteCount > 0 else { return 0 }
        guard downloads.storage.availableByteCount > 0 else { return 1 }
        return min(max(mangaFraction, 0.04), 0.96)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Download directory", systemImage: "folder")
                        .font(.headline)
                        .foregroundStyle(accent)

                    Text(downloads.storage.directoryPath)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("\(mangaMegabytesLabel) used by Keihatsu downloads")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        showsDirectoryPicker = true
                    } label: {
                        Label("Change Directory", systemImage: "folder.badge.gearshape")
                    }
                    .buttonStyle(.bordered)
                    .tint(accent)
                }
                .padding(.vertical, 8)
            }

            Section("On this device") {
                VStack(alignment: .leading, spacing: 18) {
                    GeometryReader { proxy in
                        HStack(spacing: 0) {
                            accent
                                .frame(width: proxy.size.width * displayedMangaFraction)
                            Color(.systemGray3)
                                .frame(width: proxy.size.width * (1 - displayedMangaFraction))
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 16)
                    .help("Manga: \(mangaStorageLabel) • Available: \(availableStorageLabel)")
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
        .fileImporter(
            isPresented: $showsDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let directory = urls.first else { return }
                Task {
                    do {
                        try await downloads.changeDownloadDirectory(to: directory)
                    } catch {
                        directoryError = error.localizedDescription
                    }
                }
            case .failure(let error):
                directoryError = error.localizedDescription
            }
        }
        .alert("Unable to Change Directory", isPresented: Binding(
            get: { directoryError != nil },
            set: { if !$0 { directoryError = nil } }
        )) {
            Button("OK", role: .cancel) { directoryError = nil }
        } message: {
            Text(directoryError ?? "Choose another folder and try again.")
        }
    }

    private var storageLegend: some View {
        VStack(spacing: 12) {
            storageLegendRow(color: accent, title: "Manga", value: mangaStorageLabel)
            storageLegendRow(color: Color(.systemGray3), title: "Available", value: availableStorageLabel)
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

    private var mangaMegabytesLabel: String {
        let megabytes = Double(downloads.storage.byteCount) / 1_000_000
        if megabytes < 0.05 { return "0 MB" }
        return String(format: "%.1f MB", megabytes)
    }

    private var availableStorageLabel: String {
        ByteCountFormatter.string(fromByteCount: downloads.storage.availableByteCount, countStyle: .file)
    }
}
