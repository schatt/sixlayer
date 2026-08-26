//
//  ThemePreferenceResolutionTests.swift
//  SixLayerFrameworkTests
//
//  Themed modifiers must resolve tokens from VisualDesignSystem.shared,
//  never from SwiftUI Environment (inspect() cannot install Environment; #435).
//

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
    func resolvedSpacingTokensIgnoreEnvironmentInstance() {
        let shared = VisualDesignSystem.shared.currentSpacing
        let environment = HighContrastDesignSystem().spacing()
        let resolved = ThemePreference.resolvedSpacingTokens(environmentValue: environment)
        #expect(
            resolved.md == shared.md,
            "inspect() cannot install Environment; spacing tokens must come from VisualDesignSystem.shared"
        )
        #expect(
            environment.md != shared.md,
            "HighContrast spacing must differ from shared so this test can observe Environment being ignored"
        )
    }
}
