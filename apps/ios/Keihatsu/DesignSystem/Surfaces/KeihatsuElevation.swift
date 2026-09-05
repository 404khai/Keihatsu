import SwiftUI

struct KeihatsuElevation {
    let card = ShadowSpec(
        color: Color.black.opacity(0.22),
        radius: 18,
        y: 10
    )
}

struct ShadowSpec {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}
