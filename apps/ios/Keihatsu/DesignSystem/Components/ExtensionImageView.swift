import SwiftUI

struct ExtensionImageView: View {
    let sourceID: String
    var size: CGFloat = 22
    var cornerRadius: CGFloat = 6

    private static let bundledSources = Set([
        "atsumaru",
        "batcave",
        "mangafire",
        "manhuatop",
        "weebcentral"
    ])

    private var assetName: String {
        sourceID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }

    var body: some View {
        Group {
            if Self.bundledSources.contains(assetName) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "puzzlepiece.extension.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.2)
            }
        }
        .frame(width: size, height: size)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}
