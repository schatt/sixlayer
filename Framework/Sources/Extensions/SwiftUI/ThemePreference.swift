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
        testOverride ?? tokensFromShared
    }

    public static var platformStyle: PlatformStyle { current.platformStyle }
    public static var colorSystem: ColorSystem { current.colorSystem }
    public static var typographySystem: TypographySystem { current.typographySystem }
    public static var designTokens: DesignTokens.Colors { current.designTokens }
    public static var spacingTokens: DesignTokens.Spacing { current.spacingTokens }
    public static var componentStates: DesignTokens.ComponentStates { current.componentStates }
    public static var accessibilitySettings: AccessibilitySettings { current.accessibilitySettings }

    public static func withTestOverride<T>(
        _ tokens: ThemeTokens,
        _ body: () throws -> T
    ) rethrows -> T {
        try $testOverride.withValue(tokens, operation: body)
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

/// Hosted branch reads Environment; unhosted uses ThemePreference so inspect() does not.
public extension UnhostedInspection {
    @ViewBuilder
    static func withThemeTokens<V: View>(
        @ViewBuilder _ content: @escaping (ThemeTokens) -> V
    ) -> some View {
        split(
            unhosted: { content(ThemePreference.current) },
            hosted: { ThemeEnvironmentReader(content: content) }
        )
    }
}

/// Instantiated only on the hosted split so inspect() does not touch theme Environment keys.
private struct ThemeEnvironmentReader<Content: View>: View {
    @Environment(\.platformStyle) private var platformStyle
    @Environment(\.colorSystem) private var colorSystem
    @Environment(\.typographySystem) private var typographySystem
    @Environment(\.designTokens) private var designTokens
    @Environment(\.spacingTokens) private var spacingTokens
    @Environment(\.componentStates) private var componentStates
    @Environment(\.accessibilitySettings) private var accessibilitySettings

    let content: (ThemeTokens) -> Content

    var body: some View {
        content(
            ThemeTokens(
                platformStyle: platformStyle,
                colorSystem: colorSystem,
                typographySystem: typographySystem,
                designTokens: designTokens,
                spacingTokens: spacingTokens,
                componentStates: componentStates,
                accessibilitySettings: accessibilitySettings
            )
        )
    }
}
