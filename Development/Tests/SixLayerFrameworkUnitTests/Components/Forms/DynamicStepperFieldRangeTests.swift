//
//  DynamicStepperFieldRangeTests.swift
//  SixLayerFramework
//
//  Issue #562: DynamicStepperField must order inverted expectedRange
//  (and metadata min/max) so ClosedRange construction never traps.
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Dynamic Stepper Field Range")
@MainActor
struct DynamicStepperFieldRangeTests {

    @Test func invertedExpectedRangeIsOrderedSoTheStepperCanBeBuilt() {
        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Amount",
            defaultValue: "0",
            metadata: ["expectedRange": "40:-20"]
        )

        let range = DynamicStepperField.resolvedRange(for: field)
        #expect(range == -20...40)
    }

    @Test func orderedExpectedRangeIsUnchanged() {
        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Amount",
            defaultValue: "5",
            metadata: ["expectedRange": "2:8"]
        )

        let range = DynamicStepperField.resolvedRange(for: field)
        #expect(range == 2...8)
    }

    @Test func invertedMetadataMinMaxIsOrderedSoTheStepperCanBeBuilt() {
        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Amount",
            defaultValue: "0",
            metadata: [
                "min": "100",
                "max": "10"
            ]
        )

        let range = DynamicStepperField.resolvedRange(for: field)
        #expect(range == 10...100)
    }

    // NaN parses via Double(String) ("nan") and would trap ClosedRange construction.
    @Test func nanExpectedRangeFallsBackToMetadataInsteadOfTrapping() {
        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Amount",
            defaultValue: "0",
            metadata: [
                "expectedRange": "nan:5",
                "min": "1",
                "max": "9"
            ]
        )

        let range = DynamicStepperField.resolvedRange(for: field)
        #expect(range == 1...9)
    }

    @Test func nanMetadataBoundUsesDefaultInsteadOfTrapping() {
        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Amount",
            defaultValue: "0",
            metadata: [
                "min": "nan",
                "max": "9"
            ]
        )

        let range = DynamicStepperField.resolvedRange(for: field)
        #expect(range == 0...9)
    }
}
