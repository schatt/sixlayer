//
//  IntelligentFormNumberPresentationTests.swift
//  SixLayerFramework
//
//  Issue #550: IntelligentFormView number fields opt into signed entry
//  and honor expectedRange for the stepper.
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Intelligent Form Number Presentation")
struct IntelligentFormNumberPresentationTests {

    @Test func unsignedHintsKeepDecimalPadAndZeroToOneThousand() {
        let hints = FieldDisplayHints()
        #expect(IntelligentFormNumberPresentation.keyboardType(allowsNegative: hints.allowsNegative) == .decimalPad)
        #expect(IntelligentFormNumberPresentation.stepperRange(hints: hints) == 0...1000)
        #expect(IntelligentFormNumberPresentation.stepperRange(hints: nil) == 0...1000)
    }

    @Test func allowsNegativeSelectsAKeyboardThatCanTypeAMinus() {
        let hints = FieldDisplayHints(allowsNegative: true)
        #expect(
            IntelligentFormNumberPresentation.keyboardType(allowsNegative: hints.allowsNegative)
                == .numbersAndPunctuation
        )
    }

    @Test func allowsNegativeStepperIsNotStuckAtZero() {
        let range = IntelligentFormNumberPresentation.stepperRange(
            hints: FieldDisplayHints(allowsNegative: true)
        )
        #expect(range.lowerBound < 0)
        #expect(range.contains(0))
        #expect(range.upperBound == 1000)
        #expect(range.lowerBound == -1000)
    }

    @Test func expectedRangeReplacesTheHardCodedStepperBounds() {
        let wide = IntelligentFormNumberPresentation.stepperRange(
            hints: FieldDisplayHints(expectedRange: ValueRange(min: 0, max: 5000))
        )
        #expect(wide == 0...5000)

        let signed = IntelligentFormNumberPresentation.stepperRange(
            hints: FieldDisplayHints(
                expectedRange: ValueRange(min: -40, max: 40),
                allowsNegative: true
            )
        )
        #expect(signed == -40...40)
    }

    @Test func expectedRangeWinsOverTheSignedDefault() {
        let range = IntelligentFormNumberPresentation.stepperRange(
            hints: FieldDisplayHints(
                expectedRange: ValueRange(min: 10, max: 20),
                allowsNegative: true
            )
        )
        #expect(range == 10...20)
    }

    @Test func invertedExpectedRangeIsOrderedSoTheStepperCanBeBuilt() {
        let range = IntelligentFormNumberPresentation.stepperRange(
            hints: FieldDisplayHints(expectedRange: ValueRange(min: 40, max: -20))
        )
        #expect(range == -20...40)
    }

    @Test func negativeRangeDoesNotImplyASignedKeyboard() {
        let hints = FieldDisplayHints(expectedRange: ValueRange(min: -5, max: 5))
        #expect(hints.allowsNegative == false)
        #expect(IntelligentFormNumberPresentation.keyboardType(allowsNegative: hints.allowsNegative) == .decimalPad)
    }
}
