import SwiftUI

struct CatalogueCover: View {
    @EnvironmentObject private var environment: AppEnvironment
    var url: URL? = nil
    var referer: URL? = nil
    var asset: String? = nil
    @State private var artwork: UIImage?
    @State private var failed = false
    @State private var retry = 0

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let asset, !asset.isEmpty {
                    Image(asset).resizable().scaledToFill()
                } else if let artwork {
                    Image(uiImage: artwork).resizable().scaledToFill()
                } else {
                    Rectangle().fill(.quaternary)
                        .overlay {
                            if failed {
                                Button { retry += 1 } label: { Image(systemName: "arrow.clockwise") }
                                    .accessibilityLabel("Retry cover")
                            } else if url != nil { ProgressView() }
                            else { Image(systemName: "book.closed").foregroundStyle(.secondary) }
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .task(id: "\(url?.absoluteString ?? "")-\(retry)") {
            artwork = nil
            failed = false
            guard let url else { return }
            do { artwork = try await environment.imagePipeline.image(url: url, referer: referer) }
            catch is CancellationError { }
            catch { if !Task.isCancelled { failed = true } }
        }
    }
}

struct CatalogueMessage: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message).font(.subheadline).foregroundStyle(.secondary)
            if let retry { Button("Retry", action: retry).buttonStyle(.bordered) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 18))
    }
}
