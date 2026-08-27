import SwiftUI

/// Snapshot of theme tokens for inspect-safe resolution (#435).
public struct ThemeTokens: Sendable {
    public var platformStyle: PlatformStyle
    public var colorSystem: ColorSystem
    public var typographySystem: TypographySystem
    public var designTokens: DesignTokens.Colors
    public var spacingTokens: DesignTokens.Spacing
    public var componentStates: DesignTokens.ComponentStates
    public var accessibilitySettings: AccessibilitySettings

    public init(
        platformStyle: PlatformStyle,
        colorSystem: ColorSystem,
        typographySystem: TypographySystem,
        designTokens: DesignTokens.Colors,
        spacingTokens: DesignTokens.Spacing,
        componentStates: DesignTokens.ComponentStates,
        accessibilitySettings: AccessibilitySettings
    ) {
        self.platformStyle = platformStyle
        self.colorSystem = colorSystem
        self.typographySystem = typographySystem
        self.designTokens = designTokens
        self.spacingTokens = spacingTokens
        self.componentStates = componentStates
        self.accessibilitySettings = accessibilitySettings
    }
}

/// Theme tokens for modifiers `inspect()` will evaluate (#435).
///
/// Unhosted inspect must not instantiate `@Environment(\.colorSystem)` / `platformStyle` /
/// `designTokens`. Use `UnhostedInspection.withThemeTokens` so the hosted branch still
/// reads Environment (ThemedFrameworkView / `.environment(\.colorSystem, …)`).
/// Unhosted uses task-local then `VisualDesignSystem.shared`.
@MainActor
public enum ThemePreference {
    @TaskLocal public static var testOverride: ThemeTokens?

    public static var current: ThemeTokens {
        tokensFromShared
    }

    public static var platformStyle: PlatformStyle { current.platformStyle }
    public static var colorSystem: ColorSystem { current.colorSystem }
    public static var typographySystem: TypographySystem { current.typographySystem }
    public static var designTokens: DesignTokens.Colors { current.designTokens }
    public static var spacingTokens: DesignTokens.Spacing { current.spacingTokens }
    public static var componentStates: DesignTokens.ComponentStates { current.componentStates }
    public static var accessibilitySettings: AccessibilitySettings { current.accessibilitySettings }

    /// Stub: does not bind task-local so override tests fail at runtime.
    public static func withTestOverride<T>(
        _ tokens: ThemeTokens,
        _ body: () throws -> T
    ) rethrows -> T {
        _ = tokens
        return try body()
    }

    private static var tokensFromShared: ThemeTokens {
        let designSystem = VisualDesignSystem.shared
        return ThemeTokens(
            platformStyle: designSystem.platformStyle,
            colorSystem: ColorSystem(
                from: designSystem.designSystem,
                theme: designSystem.currentTheme
            ),
            typographySystem: TypographySystem(
                from: designSystem.designSystem,
                theme: designSystem.currentTheme
            ),
            designTokens: designSystem.currentColors,
            spacingTokens: designSystem.currentSpacing,
            componentStates: designSystem.currentComponentStates,
            accessibilitySettings: designSystem.accessibilitySettings
        )
    }
}
