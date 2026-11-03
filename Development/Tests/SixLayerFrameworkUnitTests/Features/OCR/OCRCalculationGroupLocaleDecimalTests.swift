import Foundation
import Testing

@testable import SixLayerFramework

/// OCR calculation groups read a locale decimal as the same number as `4.5` (#629).
/// A thousands separator still comes out, and it is not the decimal comma.
@Suite("OCR calculation group locale decimals")
struct OCRCalculationGroupLocaleDecimalTests {

    private let german = Locale(identifier: "de_DE")
    private let english = Locale(identifier: "en_US")

    private func cost(gallons: String, price: String, locale: Locale) -> Double? {
        let service = OCRService()
        let group = CalculationGroup(
            id: "cost",
            formula: "cost = gallons * price",
            dependentFields: ["gallons", "price"],
            priority: 1
        )
        return service.evaluateCalculationGroup(
            group,
            fieldValues: ["gallons": gallons, "price": price],
            locale: locale
        )
    }

    @Test func localeCommaDecimalMatchesPosixDecimal() {
        #expect(cost(gallons: "4,5", price: "2", locale: german) == 9)
        #expect(cost(gallons: "4.5", price: "2", locale: german) == 9)
    }

    @Test func negativeLocaleDecimalMatchesPosix() {
        #expect(cost(gallons: "-4,5", price: "2", locale: german) == -9)
        #expect(cost(gallons: "-4.5", price: "2", locale: german) == -9)
    }

    @Test func posixPointDecimalStaysPointDecimal() {
        #expect(cost(gallons: "1.234", price: "1", locale: german) == Double("1.234"))
    }

    @Test func germanGroupedDecimalKeepsTheComma() {
        #expect(cost(gallons: "1.234,5", price: "1", locale: german) == 1234.5)
    }

    @Test func englishThousandsSeparatorStillCalculates() {
        #expect(cost(gallons: "1,234.5", price: "2", locale: english) == 2469)
    }

    @Test func incompleteDecimalFailsClosed() {
        #expect(cost(gallons: "4,5abc", price: "2", locale: german) == nil)
        #expect(cost(gallons: "..", price: "2", locale: german) == nil)
        #expect(cost(gallons: "", price: "2", locale: german) == nil)
    }

    @Test func spacedLocaleDecimalCalculates() {
        #expect(cost(gallons: " 4,5 ", price: "2", locale: german) == 9)
    }
}
