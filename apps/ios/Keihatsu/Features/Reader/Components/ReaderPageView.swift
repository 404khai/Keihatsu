import SwiftUI
import UIKit

struct ReaderPageView: View {
    let page: ReaderPage
    let pipeline: ImagePipeline
    @State private var image: UIImage?
    @State private var error: String?
    @State private var retryID = UUID()

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            } else if error != nil {
                Button {
                    error = nil
                    retryID = UUID()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise.circle").font(.largeTitle)
                        Text("Page couldn’t be loaded").font(.headline)
                        Text("Tap to retry").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 420)
                }
                .buttonStyle(.plain)
            } else {
                ZStack {
                    Color.white.opacity(0.035)
                    ProgressView().tint(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, minHeight: 420)
            }
        }
        .background(.black)
        .task(id: retryID) {
            do { image = try await pipeline.readerImage(url: page.imageURL, referer: page.refererURL) }
            catch is CancellationError { }
            catch { self.error = error.localizedDescription }
        }
        .accessibilityIdentifier("reader.page.\(page.id.chapter.chapterID).\(page.id.index)")
    }
}

struct ReaderChapterBoundary: View {
    let previous: String
    let next: String

    var body: some View {
        VStack(spacing: 10) {
            Text("End of \(previous)").font(.caption).foregroundStyle(.white.opacity(0.55))
            Image(systemName: "chevron.down.2").foregroundStyle(.tint)
            Text(next).font(.title3.weight(.semibold)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(.black)
        .accessibilityElement(children: .combine)
    }
}

struct ReaderFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Chapter unavailable", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retry).buttonStyle(.borderedProminent)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
