//
//  FieldDisplayWidthResolverTests.swift
//  SixLayerFrameworkTests
//
//  Shared preferred-width resolution for FieldDisplayHints (GitHub #385).
//

import Testing
import CoreGraphics
@testable import SixLayerFramework

@Suite("Field Display Width Resolver")
struct FieldDisplayWidthResolverTests {

    private let bands = FieldDisplayWidthPlatformBands(narrow: 150, medium: 200, wide: 400)
    private let characterWidth: CGFloat = 10
    private let padding: CGFloat = 16

    @Test func preferredWidth_nilHints_returnsNil() {
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: nil,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands
        )
        #expect(width == nil)
    }

    @Test func preferredWidth_emptyHints_returnsNil() {
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: FieldDisplayHints(),
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands
        )
        #expect(width == nil)
    }

    @Test func preferredWidth_numericDisplayWidth_usesExactPoints() {
        let hints = FieldDisplayHints(displayWidth: "250")
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands
        )
        #expect(width == 250)
    }

    @Test func preferredWidth_narrowBand_usesPlatformNarrow() {
        let hints = FieldDisplayHints(displayWidth: "narrow")
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands
        )
        #expect(width == 150)
    }

    @Test func preferredWidth_mediumBand_usesPlatformMedium() {
        let hints = FieldDisplayHints(displayWidth: "medium")
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands
        )
        #expect(width == 200)
    }

    @Test func preferredWidth_wideBand_usesPlatformWide() {
        let hints = FieldDisplayHints(displayWidth: "wide")
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands
        )
        #expect(width == 400)
    }

    @Test func preferredWidth_expectedLengthOnly_usesFontMetrics() {
        // 12 chars × 10pt + 16 padding = 136
        let hints = FieldDisplayHints(expectedLength: 12)
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands
        )
        #expect(width == 136)
    }

    @Test func preferredWidth_numericBeatsExpectedLength() {
        let hints = FieldDisplayHints(expectedLength: 12, displayWidth: "250")
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands
        )
        #expect(width == 250)
    }

    @Test func preferredWidth_bandBeatsExpectedLength() {
        let hints = FieldDisplayHints(expectedLength: 12, displayWidth: "narrow")
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands
        )
        #expect(width == 150)
    }

    @Test func preferredWidth_capsToAvailableWidth() {
        let hints = FieldDisplayHints(displayWidth: "wide")
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands,
            availableWidth: 320
        )
        #expect(width == 320)
    }

    @Test func preferredWidth_doesNotCapWhenAvailableIsLarger() {
        let hints = FieldDisplayHints(displayWidth: "narrow")
        let width = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: padding,
            bands: bands,
            availableWidth: 500
        )
        #expect(width == 150)
    }

    @Test func platformBands_differByPlatform() {
        let iOS = FieldDisplayWidthPlatformBands.forPlatform(.iOS)
        let macOS = FieldDisplayWidthPlatformBands.forPlatform(.macOS)
        // Documented platform differences must exist (values may evolve; inequality is the contract for now).
        #expect(iOS != macOS || iOS.narrow != macOS.narrow || iOS.wide != macOS.wide)
        // Prefer explicit expected table once chosen — at minimum macOS wide >= iOS wide for sheet density.
        #expect(macOS.wide >= iOS.wide)
        #expect(macOS.medium >= iOS.medium)
        #expect(macOS.narrow >= iOS.narrow)
    }
}
