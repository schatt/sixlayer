//
//  DynamicGaugeFieldDisplayTests.swift
//  SixLayerFramework
//
//  Issue #710: DynamicGaugeField is the Components twin of platformGaugeInput.
//  Its labels used `Int(Double)` and its `min > max` guard missed NaN, so
//  `min...max` trapped for "nan" metadata. It now resolves everything through
//  the shared PlatformGaugeDisplay (inverted bounds are ordered, matching the
//  #562 stepper; non-finite bounds fall back per bound to 0 / 100).
//

import Foundation
import Testing
@testable import SixLayerFramework

@Suite("Dynamic Gauge Field Display (#710)")
@MainActor
struct DynamicGaugeFieldDisplayTests {

    private let emDash = "\u{2014}"

    private func field(metadata: [String: String]?) -> DynamicFormField {
        DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Level",
            defaultValue: "0",
            metadata: metadata
        )
    }

    @Test func defaultsToZeroToHundredWithoutMetadata() {
        let display = DynamicGaugeField.display(for: field(metadata: nil), value: 25)
        #expect(display.range == 0...100)
        #expect(display.valueText == "25")
        #expect(display.minText == "0")
        #expect(display.maxText == "100")
    }

    @Test func usesMetadataBounds() {
        let display = DynamicGaugeField.display(for: field(metadata: ["min": "10", "max": "50"]), value: 25)
        #expect(display.range == 10...50)
        #expect(display.minText == "10")
        #expect(display.maxText == "50")
    }

    @Test func invertedMetadataBoundsAreOrdered() {
        // Previously fell back to 0...100; now ordered like the #562 stepper.
        let display = DynamicGaugeField.display(for: field(metadata: ["min": "50", "max": "10"]), value: 25)
        #expect(display.range == 10...50)
    }

    @Test func unparsableMetadataFallsBackToTheDefaults() {
        let display = DynamicGaugeField.display(for: field(metadata: ["min": "abc", "max": "xyz"]), value: 25)
        #expect(display.range == 0...100)
    }

    @Test func nonFiniteMetadataBoundsFallBackPerBound() {
        #expect(DynamicGaugeField.display(for: field(metadata: ["min": "nan", "max": "5"]), value: 1).range == 0...5)
        #expect(DynamicGaugeField.display(for: field(metadata: ["min": "5", "max": "inf"]), value: 1).range == 5...100)
    }

    @Test func nonFiniteValueShowsEmDash() {
        let display = DynamicGaugeField.display(for: field(metadata: ["min": "10", "max": "50"]), value: .nan)
        #expect(display.valueText == emDash)
        #expect(display.value == 10)
    }

    // MARK: - Call-site sentinels (the real body must not trap)

    @Test func bodyBuildsWithNaNMetadataBound() {
        let configuration = DynamicFormConfiguration(id: "gaugeForm", title: "Gauge", sections: [])
        let formState = DynamicFormState(configuration: configuration)
        let gaugeField = field(metadata: ["min": "nan", "max": "5"])
        formState.initializeField(gaugeField)

        _ = DynamicGaugeField(field: gaugeField, formState: formState).body
    }

    @Test func bodyBuildsWithNonFiniteStoredValue() {
        let configuration = DynamicFormConfiguration(id: "gaugeForm", title: "Gauge", sections: [])
        let formState = DynamicFormState(configuration: configuration)
        let gaugeField = field(metadata: ["min": "0", "max": "100"])
        formState.initializeField(gaugeField)
        formState.setValue(Double.nan, for: gaugeField.id)

        _ = DynamicGaugeField(field: gaugeField, formState: formState).body
    }
}
