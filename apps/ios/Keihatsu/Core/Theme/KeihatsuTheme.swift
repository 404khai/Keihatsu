import SwiftUI

struct KeihatsuTheme {
    let colors: KeihatsuColors
    let spacing: KeihatsuSpacing
    let typography: KeihatsuTypography
    let radius: KeihatsuRadius
    let elevation: KeihatsuElevation
    let motion: KeihatsuMotion

    static let `default` = KeihatsuTheme(
        colors: KeihatsuColors(),
        spacing: KeihatsuSpacing(),
        typography: KeihatsuTypography(),
        radius: KeihatsuRadius(),
        elevation: KeihatsuElevation(),
        motion: KeihatsuMotion()
    )
}

private struct KeihatsuThemeKey: EnvironmentKey {
    static let defaultValue = KeihatsuTheme.default
}

extension EnvironmentValues {
    var keihatsuTheme: KeihatsuTheme {
        get { self[KeihatsuThemeKey.self] }
        set { self[KeihatsuThemeKey.self] = newValue }
    }
}
