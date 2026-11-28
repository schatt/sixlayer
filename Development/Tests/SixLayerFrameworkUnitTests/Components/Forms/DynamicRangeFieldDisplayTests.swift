//
//  DynamicRangeFieldDisplayTests.swift
//  SixLayerFramework
//
//  Issue #710 (twin): DynamicRangeField read its value with `Double(String) ?? 0`, which
//  accepts "nan", "inf", and "1e30", then built the accessibility value with
//  `Int(sliderValue.wrappedValue)`, which traps for all three. The value is now
//  sanitized (non-finite -> 0) and clamped to the slider's 0...100, and the label comes
//  from the shared `platformWholeNumberText`.
//

import Foundation
import Testing
@testable import SixLayerFramework

@Suite("Dynamic Range Field Display (#710)")
@MainActor
struct DynamicRangeFieldDisplayTests {

    // MARK: - Value resolution

    @Test func storedValueWinsOverTheDefault() {
        #expect(DynamicRangeField.sliderValue(stored: "42", defaultValue: "30") == 42)
    }

    @Test func missingStoredValueFallsBackToTheDefault() {
        #expect(DynamicRangeField.sliderValue(stored: nil, defaultValue: "30") == 30)
    }

    @Test func missingEverythingIsZero() {
        #expect(DynamicRangeField.sliderValue(stored: nil, defaultValue: nil) == 0)
    }

    @Test func unparsableTextIsZero() {
        #expect(DynamicRangeField.sliderValue(stored: "abc", defaultValue: nil) == 0)
    }

    @Test func nonFiniteTextIsZero() {
        #expect(DynamicRangeField.sliderValue(stored: "nan", defaultValue: nil) == 0)
        #expect(DynamicRangeField.sliderValue(stored: "inf", defaultValue: nil) == 0)
        #expect(DynamicRangeField.sliderValue(stored: "-inf", defaultValue: nil) == 0)
    }

    @Test func outOfRangeValuesClampToTheSliderRange() {
        #expect(DynamicRangeField.sliderValue(stored: "1e30", defaultValue: nil) == 100)
        #expect(DynamicRangeField.sliderValue(stored: "-5", defaultValue: nil) == 0)
        #expect(DynamicRangeField.sliderValue(stored: "250", defaultValue: nil) == 100)
    }

    // MARK: - Accessibility value

    @Test func accessibilityValueRoundsToTheNearestWholePercent() {
        #expect(DynamicRangeField.accessibilityValue(for: 42) == "42 percent")
        #expect(DynamicRangeField.accessibilityValue(for: 4.6) == "5 percent")
    }

    // MARK: - Call-site sentinels (the real body must not trap)

    private func bodyBuilds(storedValue: String) {
        let field = DynamicFormField(id: "range", contentType: .range, label: "Level", defaultValue: "0")
        let configuration = DynamicFormConfiguration(id: "rangeForm", title: "Range", sections: [])
        let formState = DynamicFormState(configuration: configuration)
        formState.initializeField(field)
        formState.setValue(storedValue, for: field.id)

        _ = DynamicRangeField(field: field, formState: formState).body
    }

    @Test func bodyBuildsWithInfiniteStoredValue() {
        bodyBuilds(storedValue: "inf")
    }

    @Test func bodyBuildsWithNaNStoredValue() {
        bodyBuilds(storedValue: "nan")
    }

    @Test func bodyBuildsWithHugeStoredValue() {
        bodyBuilds(storedValue: "1e30")
    }
}
