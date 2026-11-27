//
//  PlatformGaugeDisplayTests.swift
//  SixLayerFrameworkUnitTests
//
//  Issue #710: platformGaugeInput built labels with `Int(Double)` and a raw
//  `min...max` range. Both trap on NaN / infinity / out-of-`Int`-range values
//  (labels) and on inverted or NaN bounds (range) - the same trap class as the
//  #562 stepper. `PlatformGaugeDisplay` resolves range, value, and label text
//  once for every gauge surface; `platformWholeNumberText` is the shared
//  non-trapping whole-number formatter (also used by the stepper).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform gauge display (#710)")
struct PlatformGaugeDisplayTests {

    private let emDash = "\u{2014}"

    // MARK: - Whole-number text

    @Test func wholeNumberText_nonFiniteShowsEmDash() {
        #expect(platformWholeNumberText(.nan) == emDash)
        #expect(platformWholeNumberText(.infinity) == emDash)
        #expect(platformWholeNumberText(-.infinity) == emDash)
    }

    @Test func wholeNumberText_neverShowsNegativeZero() {
        #expect(platformWholeNumberText(-0.0) == "0")
        #expect(platformWholeNumberText(-0.4) == "0")
    }

    @Test func wholeNumberText_roundsToNearest() {
        #expect(platformWholeNumberText(7) == "7")
        #expect(platformWholeNumberText(49.9) == "50")
        #expect(platformWholeNumberText(-49.9) == "-50")
    }

    @Test func wholeNumberText_hugeFiniteValueDoesNotTrap() {
        #expect(!platformWholeNumberText(1e30).isEmpty)
        #expect(platformWholeNumberText(1e30) != emDash)
    }

    // MARK: - Resolved display

    @Test func display_ordinaryInputs() {
        let display = PlatformGaugeDisplay(value: 42, min: 0, max: 100)
        #expect(display.range == 0...100)
        #expect(display.value == 42)
        #expect(display.valueText == "42")
        #expect(display.minText == "0")
        #expect(display.maxText == "100")
    }

    @Test func display_invertedBoundsAreOrdered() {
        let display = PlatformGaugeDisplay(value: 5, min: 100, max: 0)
        #expect(display.range == 0...100)
        #expect(display.minText == "0")
        #expect(display.maxText == "100")
        #expect(display.value == 5)
    }

    @Test func display_nonFiniteBoundsFallBackPerBound() {
        #expect(PlatformGaugeDisplay(value: 1, min: .nan, max: 5).range == 0...5)
        #expect(PlatformGaugeDisplay(value: 1, min: 5, max: .infinity).range == 5...100)
        #expect(PlatformGaugeDisplay(value: 1, min: .nan, max: .nan).range == 0...100)
        #expect(PlatformGaugeDisplay(value: 1, min: -.infinity, max: .infinity).range == 0...100)
    }

    @Test func display_nonFiniteValueShowsEmDashAndSitsAtTheLowerBound() {
        let nan = PlatformGaugeDisplay(value: .nan, min: 10, max: 50)
        #expect(nan.valueText == emDash)
        #expect(nan.value == 10)

        let infinite = PlatformGaugeDisplay(value: .infinity, min: 10, max: 50)
        #expect(infinite.valueText == emDash)
        #expect(infinite.value == 10)
    }

    @Test func display_hugeFiniteInputsKeepTheirValuesAndFormatWithoutTrapping() {
        let display = PlatformGaugeDisplay(value: 1e300, min: -1e300, max: 1e300)
        #expect(display.range == -1e300...1e300)
        #expect(display.value == 1e300)
        #expect(!display.valueText.isEmpty && display.valueText != emDash)
        #expect(!display.minText.isEmpty && display.minText != emDash)
        #expect(!display.maxText.isEmpty && display.maxText != emDash)
    }

    // MARK: - Call-site sentinels (the real view builder must not trap)

    @Test @MainActor func platformGaugeInput_buildsWithNonFiniteValue() {
        _ = EmptyView().platformGaugeInput(value: .nan, min: 0, max: 100)
    }

    @Test @MainActor func platformGaugeInput_buildsWithNonFiniteBounds() {
        _ = EmptyView().platformGaugeInput(value: 5, min: .nan, max: .infinity)
    }

    @Test @MainActor func platformGaugeInput_buildsWithInvertedBounds() {
        _ = EmptyView().platformGaugeInput(value: 5, min: 100, max: 0, style: "circular")
    }

    @Test @MainActor func platformGaugeInput_buildsWithHugeFiniteValues() {
        _ = EmptyView().platformGaugeInput(value: 1e300, min: -1e300, max: 1e300)
    }
}
