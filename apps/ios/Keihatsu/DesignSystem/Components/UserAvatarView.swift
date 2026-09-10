import BlobatarCore
import BlobatarSwiftUI
import SwiftUI

/// The shared account avatar renderer for profile and community surfaces.
///
/// Flutter and Swift both use the API user ID as the deterministic seed and
/// pass the same persisted hue, shape, expression, and animation options to
/// their native Blobatar packages. Keeping this adapter free of platform-only
/// traits preserves the generation-2 cross-platform contract.
struct UserAvatarView: View {
    let seed: String
    let label: String
    var configuration: AvatarConfiguration = .default
    var size: CGFloat = 64

    var body: some View {
        Group {
            if configuration.animated {
                AnimatedBlobatar(
                    name: safeSeed,
                    size: size,
                    options: options,
                    animation: .always,
                    accessibilityLabel: "\(label) avatar"
                )
            } else {
                Blobatar(
                    name: safeSeed,
                    size: size,
                    options: options,
                    accessibilityLabel: "\(label) avatar"
                )
            }
        }
        .frame(width: size, height: size)
        .id(renderIdentity)
    }

    private var safeSeed: String {
        let value = seed.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "keihatsu-reader" : value
    }

    private var options: BlobatarOptions {
        var traits: [String: BlobatarTraitOverride] = [:]
        if let shape = configuration.shape {
            traits["shape"] = .pinned(shape)
        }

        return BlobatarOptions(
            hue: configuration.hue,
            traits: traits,
            background: .squircle,
            expression: configuration.expression.blobatarExpression
        )
    }

    private var renderIdentity: String {
        [
            safeSeed,
            configuration.hue.map { String($0) } ?? "auto",
            configuration.shape.map { String($0) } ?? "auto",
            configuration.expression.rawValue,
            String(configuration.animated)
        ].joined(separator: "|")
    }
}

private extension AvatarConfiguration.Expression {
    var blobatarExpression: BlobatarExpression {
        switch self {
        case .idle: .idle
        case .happy: .happy
        case .sad: .sad
        case .mad: .mad
        case .surprised: .surprised
        case .wink: .wink
        case .sleepy: .sleepy
        case .smug: .smug
        case .unsure: .unsure
        case .scared: .scared
        case .love: .love
        case .shy: .shy
        case .sick: .sick
        case .thinking: .thinking
        }
    }
}
