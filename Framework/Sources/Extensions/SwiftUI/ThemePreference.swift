import SwiftUI

/// Theme tokens for modifiers `inspect()` will evaluate (#435).
///
/// Do not read `@Environment(\.colorSystem)`, `platformStyle`, or `designTokens` in those
/// bodies — ViewInspector cannot install Environment. Resolve from `VisualDesignSystem.shared`.
/// Public EnvironmentKeys stay for ABI; generation does not read them.
@MainActor
public enum ThemePreference {
    public static func resolvedPlatformStyle(environmentValue _: PlatformStyle) -> PlatformStyle {
        VisualDesignSystem.shared.platformStyle
    }

    public static func resolvedColorSystem(environmentValue _: ColorSystem) -> ColorSystem {
        ColorSystem(
            from: VisualDesignSystem.shared.designSystem,
            theme: VisualDesignSystem.shared.currentTheme
        )
    }

    public static func resolvedDesignTokens(environmentValue _: DesignTokens.Colors) -> DesignTokens.Colors {
        VisualDesignSystem.shared.currentColors
    }

    public static func resolvedSpacingTokens(environmentValue _: DesignTokens.Spacing) -> DesignTokens.Spacing {
        VisualDesignSystem.shared.currentSpacing
    }
}
