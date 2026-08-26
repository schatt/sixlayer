import SwiftUI

/// Theme tokens for modifiers `inspect()` will evaluate (#435).
///
/// Do not read `@Environment(\.colorSystem)`, `platformStyle`, or `designTokens` in those
/// bodies — ViewInspector cannot install Environment. Resolve from `VisualDesignSystem.shared`.
/// Public EnvironmentKeys stay for ABI; generation does not read them.
@MainActor
public enum ThemePreference {
    /// Stub: still prefers Environment so new tests fail for the right reason.
    public static func resolvedPlatformStyle(environmentValue: PlatformStyle) -> PlatformStyle {
        environmentValue
    }

    /// Stub: still prefers Environment so new tests fail for the right reason.
    public static func resolvedColorSystem(environmentValue: ColorSystem) -> ColorSystem {
        environmentValue
    }

    /// Stub: still prefers Environment so new tests fail for the right reason.
    public static func resolvedDesignTokens(environmentValue: DesignTokens.Colors) -> DesignTokens.Colors {
        environmentValue
    }
}
