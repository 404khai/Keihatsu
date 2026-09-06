import SwiftUI

struct ReaderChrome: View {
    let title: String
    let chapterName: String
    let page: Int
    let pageCount: Int
    let isBookmarked: Bool
    let isIncognito: Bool
    let canOpenOlder: Bool
    let canOpenNewer: Bool
    let onDismiss: () -> Void
    let onBookmark: () -> Void
    let onComments: () -> Void
    let onOlder: () -> Void
    let onNewer: () -> Void
    let onScrub: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.backward")
                        .font(.title2.weight(.semibold))
                        .frame(width: 48, height: 48)
                }
                .glassEffect(.regular.interactive(), in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).lineLimit(1)
                    Text(chapterName).font(.caption).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                }
                Spacer(minLength: 8)
                if isIncognito {
                    Image(systemName: "eye.slash.fill")
                        .font(.caption.weight(.semibold))
                        .accessibilityLabel("Incognito reading")
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            HStack {
                Spacer()
                VStack(spacing: 12) {
                    readerAction(isBookmarked ? "bookmark.fill" : "bookmark", label: isBookmarked ? "Remove bookmark" : "Bookmark", action: onBookmark)
                    readerAction("text.bubble", label: "Comments", action: onComments)
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 18)

            HStack(spacing: 14) {
                chapterButton("backward.end.fill", label: "Previous chapter", enabled: canOpenOlder, action: onOlder)

                HStack(spacing: 10) {
                    Text(pageCount == 0 ? "–" : "\(max(page, 1))").frame(minWidth: 24)
                    Slider(
                        value: Binding(
                            get: { Double(max(page - 1, 0)) },
                            set: { onScrub(Int($0.rounded())) }
                        ),
                        in: 0...Double(max(pageCount - 1, 1)),
                        step: 1
                    )
                    .disabled(pageCount <= 1)
                    Text(pageCount == 0 ? "–" : "\(pageCount)").frame(minWidth: 24)
                }
                .font(.headline.monospacedDigit())
                .padding(.horizontal, 14)
                .frame(height: 52)
                .glassEffect(.regular.interactive(), in: .capsule)

                chapterButton("forward.end.fill", label: "Next chapter", enabled: canOpenNewer, action: onNewer)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.18))
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.68),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(height: 112)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
    }

    private func readerAction(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.title2).frame(width: 52, height: 52)
        }
        .foregroundStyle(.white)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }

    private func chapterButton(_ icon: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.title2).frame(width: 52, height: 52)
        }
        .disabled(!enabled)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }
}
