//
//  OCRMathExpressionSafetyTests.swift
//  SixLayerFrameworkUnitTests
//
//  A malformed OCR formula must not reach NSExpression (GitHub #544).
//

import Testing
@testable import SixLayerFramework

@Suite("OCR math expression safety")
struct OCRMathExpressionSafetyTests {

    private let service = OCRService()

    @Test func formatTokenReturnsNil() {
        // "%@" alone does not throw; a format token left in a formula does.
        let value = service.evaluateMathExpression("2.0 * %@")
        #expect(value == nil)
    }

    @Test func emptyFormulaReturnsNil() {
        let value = service.evaluateMathExpression("")
        #expect(value == nil)
    }

    @Test func percentBetweenNumbersReturnsNil() {
        let value = service.evaluateMathExpression("2.0%3.0")
        #expect(value == nil)
    }

    @Test func parenthesizedFormulaStillEvaluates() {
        let value = service.evaluateMathExpression("(2 * 3) + 4")
        #expect(value == 10)
    }
}
