import CryptoKit
import SwiftUI

struct UserAvatarView: View {
    let seed: String
    let label: String
    var configuration: AvatarConfiguration = .default
    var size: CGFloat = 64

    var body: some View {
        Group {
            if configuration.animated {
                TimelineView(.animation(minimumInterval: 1 / 18)) { context in
                    avatar(phase: context.date.timeIntervalSinceReferenceDate)
                }
            } else {
                avatar(phase: 0)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) avatar")
    }

    private func avatar(phase: Double) -> some View {
        let traits = AvatarTraits(seed: seed, configuration: configuration)
        return Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize).insetBy(dx: 2, dy: 2)
            let pulse = configuration.animated ? sin(phase * 2) * 0.018 : 0
            let blob = blobPath(in: rect.insetBy(dx: rect.width * pulse, dy: rect.height * pulse), traits: traits)
            context.fill(blob, with: .linearGradient(
                Gradient(colors: [traits.primary, traits.secondary]),
                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
            ))
            drawFace(context: &context, rect: rect)
        }
    }

    private func blobPath(in rect: CGRect, traits: AvatarTraits) -> Path {
        let count = 12
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var points: [CGPoint] = []
        for index in 0..<count {
            let angle = Double(index) / Double(count) * .pi * 2 - .pi / 2
            let modulation = 0.84 + traits.shape * 0.11 + traits.noise[index % traits.noise.count] * 0.08
            points.append(CGPoint(x: center.x + cos(angle) * radius * modulation, y: center.y + sin(angle) * radius * modulation))
        }
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: midpoint(points.last!, first))
        for index in points.indices {
            let point = points[index]
            let next = points[(index + 1) % count]
            path.addQuadCurve(to: midpoint(point, next), control: point)
        }
        path.closeSubpath()
        return path
    }

    private func drawFace(context: inout GraphicsContext, rect: CGRect) {
        let eyeY = rect.midY - rect.height * 0.08
        let eyeSpacing = rect.width * 0.17
        let eyeRadius = max(rect.width * 0.035, 2)
        let faceColor = Color.black.opacity(0.72)
        for x in [rect.midX - eyeSpacing, rect.midX + eyeSpacing] {
            let eyeRect = CGRect(x: x - eyeRadius, y: eyeY - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2)
            if configuration.expression == .wink && x > rect.midX {
                var line = Path()
                line.move(to: CGPoint(x: eyeRect.minX, y: eyeRect.midY))
                line.addLine(to: CGPoint(x: eyeRect.maxX, y: eyeRect.midY))
                context.stroke(line, with: .color(faceColor), lineWidth: max(2, rect.width * 0.025))
            } else {
                context.fill(Path(ellipseIn: eyeRect), with: .color(faceColor))
            }
        }
        var mouth = Path()
        let mouthY = rect.midY + rect.height * 0.14
        mouth.move(to: CGPoint(x: rect.midX - rect.width * 0.12, y: mouthY))
        let curve: CGFloat
        switch configuration.expression {
        case .sad, .mad, .sick, .scared: curve = -rect.height * 0.09
        case .idle, .sleepy, .unsure, .thinking: curve = 0
        default: curve = rect.height * 0.1
        }
        mouth.addQuadCurve(to: CGPoint(x: rect.midX + rect.width * 0.12, y: mouthY), control: CGPoint(x: rect.midX, y: mouthY + curve))
        context.stroke(mouth, with: .color(faceColor), lineWidth: max(2, rect.width * 0.026))
    }

    private func midpoint(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint { CGPoint(x: (lhs.x + rhs.x) / 2, y: (lhs.y + rhs.y) / 2) }
}

private struct AvatarTraits {
    let primary: Color
    let secondary: Color
    let shape: Double
    let noise: [Double]

    init(seed: String, configuration: AvatarConfiguration) {
        let safeSeed = seed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "keihatsu-reader" : seed
        let bytes = Array(SHA256.hash(data: Data(safeSeed.utf8)))
        let derivedHue = Double(bytes[0]) / 255 * 360
        let hue = (configuration.hue ?? derivedHue).truncatingRemainder(dividingBy: 360) / 360
        shape = min(max(configuration.shape ?? Double(bytes[1]) / 255, 0), 0.999)
        noise = bytes[2..<14].map { Double($0) / 255 }
        primary = Color(hue: hue, saturation: 0.64, brightness: 0.92)
        secondary = Color(hue: (hue + 0.09).truncatingRemainder(dividingBy: 1), saturation: 0.52, brightness: 0.72)
    }
}
