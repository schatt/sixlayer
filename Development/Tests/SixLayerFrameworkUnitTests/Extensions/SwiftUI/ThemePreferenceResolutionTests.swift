//
//  ThemePreferenceResolutionTests.swift
//  SixLayerFrameworkTests
//
//  Unhosted inspect() cannot install Environment. Theme tokens come from
//  ThemePreference (task-local then VisualDesignSystem.shared). Hosted
//  production still reads Environment via UnhostedInspection.withThemeTokens (#435).
//

import CoreGraphics
import Testing
@testable import SixLayerFramework

@Suite("ThemePreference resolution")
struct ThemePreferenceResolutionTests {

    @Test @MainActor
    func currentPlatformStyleUsesSharedWhenNoOverride() {
        #expect(ThemePreference.current.platformStyle == VisualDesignSystem.shared.platformStyle)
    }

    @Test @MainActor
    func currentSpacingUsesSharedWhenNoOverride() {
        #expect(ThemePreference.current.spacingTokens.md == VisualDesignSystem.shared.currentSpacing.md)
    }

    @Test @MainActor
    func withTestOverrideHonorsTaskLocalPlatformStyle() {
        var override = ThemePreference.current
        let sentinel: PlatformStyle = override.platformStyle == .tvOS ? .watchOS : .tvOS
        override.platformStyle = sentinel
        ThemePreference.withTestOverride(override) {
            #expect(
                ThemePreference.current.platformStyle == sentinel,
                "task-local override must isolate parallel tests from VisualDesignSystem.shared"
            )
        }
        #expect(ThemePreference.current.platformStyle == VisualDesignSystem.shared.platformStyle)
    }

    @Test @MainActor
    func withTestOverrideHonorsTaskLocalSpacing() {
        var override = ThemePreference.current
        let sentinelMd: CGFloat = override.spacingTokens.md == 99.0 ? 97.0 : 99.0
        override.spacingTokens = DesignTokens.Spacing(
            xs: 1.0, sm: 2.0, md: sentinelMd, lg: 4.0, xl: 5.0, xxl: 6.0
        )
        ThemePreference.withTestOverride(override) {
            #expect(ThemePreference.current.spacingTokens.md == sentinelMd)
        }
        #expect(ThemePreference.current.spacingTokens.md == VisualDesignSystem.shared.currentSpacing.md)
    }

    @Test @MainActor
    func withThemeTokensSelectsPreferenceWhenUnhosted() {
        var override = ThemePreference.current
        let sentinel: PlatformStyle = override.platformStyle == .tvOS ? .watchOS : .tvOS
        override.platformStyle = sentinel
        AccessibilityIdentifierConfig.withUnhostedInspection {
            ThemePreference.withTestOverride(override) {
                let selected = UnhostedInspection.select(
                    unhosted: { ThemePreference.current.platformStyle },
                    hosted: { PlatformStyle.ios }
                )
                #expect(
                    selected == sentinel,
                    "inspect() must not instantiate theme Environment; unhosted uses ThemePreference"
                )
            }
        }
    }
}
