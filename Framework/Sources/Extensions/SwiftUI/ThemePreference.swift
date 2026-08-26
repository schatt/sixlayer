import SwiftUI

/// Theme tokens for modifiers `inspect()` will evaluate (#435).
///
/// Do not read `@Environment(\.colorSystem)`, `platformStyle`, or `designTokens` in those
/// bodies — ViewInspector cannot install Environment. Resolve from `VisualDesignSystem.shared`.
/// Public EnvironmentKeys stay for ABI; generation does not read them.
@MainActor
public enum ThemePreference {
    public static var platformStyle: PlatformStyle {
        VisualDesignSystem.shared.platformStyle
    }

    public static var colorSystem: ColorSystem {
        ColorSystem(
            from: VisualDesignSystem.shared.designSystem,
            theme: VisualDesignSystem.shared.currentTheme
        )
    }

    public static var typographySystem: TypographySystem {
        TypographySystem(
            from: VisualDesignSystem.shared.designSystem,
            theme: VisualDesignSystem.shared.currentTheme
        )
    }

    public static var designTokens: DesignTokens.Colors {
        VisualDesignSystem.shared.currentColors
    }

    public static var spacingTokens: DesignTokens.Spacing {
        VisualDesignSystem.shared.currentSpacing
    }

    public static var componentStates: DesignTokens.ComponentStates {
        VisualDesignSystem.shared.currentComponentStates
    }

    public static var accessibilitySettings: AccessibilitySettings {
        VisualDesignSystem.shared.accessibilitySettings
    }

    public static func resolvedPlatformStyle(environmentValue _: PlatformStyle) -> PlatformStyle {
        platformStyle
    }

    public static func resolvedColorSystem(environmentValue _: ColorSystem) -> ColorSystem {
        colorSystem
    }

    public static func resolvedDesignTokens(environmentValue _: DesignTokens.Colors) -> DesignTokens.Colors {
        designTokens
    }

    public static func resolvedSpacingTokens(environmentValue _: DesignTokens.Spacing) -> DesignTokens.Spacing {
        spacingTokens
    }
}
