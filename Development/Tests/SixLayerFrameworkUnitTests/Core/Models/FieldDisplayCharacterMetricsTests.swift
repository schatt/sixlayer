//
//  FieldDisplayCharacterMetricsTests.swift
//  SixLayerFrameworkTests
//
//  Font-aware character width for expectedLength sizing (GitHub #385).
//

import Testing
import CoreGraphics
@testable import SixLayerFramework

@Suite("Field Display Character Metrics")
struct FieldDisplayCharacterMetricsTests {

    @Test func averageCharacterWidth_bodyStyle_isPositive() {
        let width = FieldDisplayCharacterMetrics.averageCharacterWidth(
            textStyle: .body,
            contentSize: .large
        )
        #expect(width > 0)
    }

    @Test func averageCharacterWidth_scalesWithContentSize() {
        let large = FieldDisplayCharacterMetrics.averageCharacterWidth(
            textStyle: .body,
            contentSize: .large
        )
        let extraExtraExtraLarge = FieldDisplayCharacterMetrics.averageCharacterWidth(
            textStyle: .body,
            contentSize: .accessibilityExtraExtraExtraLarge
        )
        #expect(extraExtraExtraLarge >= large)
    }

    @Test func horizontalPadding_isPositive() {
        #expect(FieldDisplayCharacterMetrics.defaultHorizontalPadding > 0)
    }

    @Test func preferredWidth_usesMetricsForExpectedLength() {
        let metricsWidth = FieldDisplayCharacterMetrics.averageCharacterWidth(
            textStyle: .body,
            contentSize: .large
        )
        let hints = FieldDisplayHints(expectedLength: 10)
        let bands = FieldDisplayWidthPlatformBands(narrow: 120, medium: 180, wide: 320)
        let preferred = FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: metricsWidth,
            horizontalPadding: FieldDisplayCharacterMetrics.defaultHorizontalPadding,
            bands: bands
        )
        let expected = 10 * metricsWidth + FieldDisplayCharacterMetrics.defaultHorizontalPadding
        #expect(preferred == expected)
    }
}
