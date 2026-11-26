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

    // Display text used `Int(value)`, which traps on NaN, infinity, and finite values outside Int range.
    @Test func displayTextShowsWholeStepsWithoutDecimals() {
        #expect(DynamicStepperField.displayText(value: 5, step: 1) == "5")
    }

    @Test func displayTextShowsFractionalStepsWithTwoDecimals() {
        #expect(DynamicStepperField.displayText(value: 2.5, step: 0.5) == "2.50")
    }

    @Test func displayTextDoesNotTrapOnNonFiniteValues() {
        #expect(DynamicStepperField.displayText(value: .nan, step: 1) == "\u{2014}")
        #expect(DynamicStepperField.displayText(value: .infinity, step: 1) == "\u{2014}")
    }

    @Test func displayTextDoesNotTrapOnValuesOutsideIntRange() {
        #expect(DynamicStepperField.displayText(value: 1e300, step: 1).hasPrefix("1"))
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
