import Foundation
import Testing

@testable import SixLayerFramework

/// Joint decimal correction must use the same fail-closed locale parse as
/// calculation groups (#632). Hand comma→dot / comma-strip invents the wrong POSIX text.
@Suite("OCR joint decimal locale parse")
struct OCRJointDecimalLocaleTests {

    private let german = Locale(identifier: "de_DE")
    private let english = Locale(identifier: "en_US")

    @Test func germanCommaDecimalMatchesPosixDecimal() {
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("4,5", locale: german) == 4.5)
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("4.5", locale: german) == 4.5)
    }

    @Test func germanGroupedDecimalKeepsTheComma() {
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("1.234,5", locale: german) == 1234.5)
    }

    @Test func englishThousandsSeparatorStillParses() {
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("1,234.5", locale: english) == 1234.5)
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("1,234", locale: english) == 1234)
    }

    /// English `4,5` must not become 4.5 via comma→dot, or 45 via strip (#632 / #630).
    @Test func englishCommaDecimalFailsClosed() {
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("4,5", locale: english) == nil)
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("-4,5", locale: english) == nil)
    }

    @Test func incompleteDecimalFailsClosed() {
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("4,5abc", locale: german) == nil)
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("..", locale: german) == nil)
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue("", locale: german) == nil)
    }

    @Test func spacedLocaleDecimalParses() {
        #expect(OCRJointDecimalCorrection.parseOCRNumericValue(" 4,5 ", locale: german) == 4.5)
    }

    @Test func languageAloneUsesOCRDecimalLocale() {
        #expect(
            OCRJointDecimalCorrection.parseOCRNumericValue("4,5", language: .german) == 4.5
        )
        #expect(
            OCRJointDecimalCorrection.parseOCRNumericValue("4,5", language: .english) == nil
        )
    }
}
