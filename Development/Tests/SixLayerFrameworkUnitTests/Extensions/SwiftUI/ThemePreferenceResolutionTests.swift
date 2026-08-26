//
//  ThemePreferenceResolutionTests.swift
//  SixLayerFrameworkTests
//
//  Themed modifiers must resolve tokens from VisualDesignSystem.shared,
//  never from SwiftUI Environment (inspect() cannot install Environment; #435).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("ThemePreference resolution")
struct ThemePreferenceResolutionTests {

    @Test @MainActor
    func resolvedPlatformStyleIgnoresEnvironmentInstance() {
        let shared = VisualDesignSystem.shared.platformStyle
        let environment: PlatformStyle = shared == .tvOS ? .watchOS : .tvOS
        let resolved = ThemePreference.resolvedPlatformStyle(environmentValue: environment)
        #expect(
            resolved == shared,
            "inspect() cannot install Environment; platform style must come from VisualDesignSystem.shared"
        )
    }

    @Test @MainActor
    func resolvedColorSystemIgnoresEnvironmentInstance() {
        let shared = ColorSystem(
            from: VisualDesignSystem.shared.designSystem,
            theme: VisualDesignSystem.shared.currentTheme
        )
        let environment = ColorSystem(from: HighContrastDesignSystem(), theme: .dark)
        let resolved = ThemePreference.resolvedColorSystem(environmentValue: environment)
        #expect(
            resolved.primary == shared.primary,
            "inspect() cannot install Environment; color system must come from VisualDesignSystem.shared"
        )
    }

    @Test @MainActor
    func resolvedDesignTokensIgnoreEnvironmentInstance() {
        let shared = VisualDesignSystem.shared.currentColors
        let environment = HighContrastDesignSystem().colors(for: .dark)
        let resolved = ThemePreference.resolvedDesignTokens(environmentValue: environment)
        #expect(
            resolved.primary == shared.primary,
            "inspect() cannot install Environment; design tokens must come from VisualDesignSystem.shared"
        )
    }
}
