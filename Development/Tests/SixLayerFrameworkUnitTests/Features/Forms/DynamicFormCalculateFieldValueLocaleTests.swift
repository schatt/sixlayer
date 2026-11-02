import Foundation
import Testing

@testable import SixLayerFramework

/// `calculateFieldValue` reads a locale decimal the same way it reads `4.5` (#628).
/// POSIX `4.5` still wins when the locale uses a comma. A non-number fails closed.
@Suite("calculateFieldValue locale decimals")
@MainActor
struct DynamicFormCalculateFieldValueLocaleTests {

    private let german = Locale(identifier: "de_DE")
    private let posix = Locale(identifier: "en_US_POSIX")

    private func formState() -> DynamicFormState {
        DynamicFormState(configuration: DynamicFormConfiguration(id: "fuel", title: "Fuel"))
    }

    private func product(_ gallons: String, _ price: String, locale: Locale) -> Double? {
        let form = formState()
        form.setValue(gallons, for: "gallons")
        form.setValue(price, for: "price")
        return form.calculateFieldValue(
            formula: "gallons * price",
            dependencies: ["gallons", "price"],
            locale: locale
        )
    }

    @Test func localeCommaDecimalMatchesPosixDecimal() {
        #expect(product("4,5", "2", locale: german) == 9)
        #expect(product("4.5", "2", locale: german) == 9)
    }

    @Test func negativeLocaleDecimalMatchesPosix() {
        #expect(product("-4,5", "2", locale: german) == -9)
        #expect(product("-4.5", "2", locale: german) == -9)
    }

    @Test func posixPointDecimalStaysPointDecimal() {
        #expect(product("1.234", "1", locale: german) == Double("1.234"))
    }

    @Test func posixLocaleRejectsCommaDecimal() {
        #expect(product("4,5", "2", locale: posix) == nil)
    }

    @Test func incompleteValueFailsClosed() {
        #expect(product("4,5abc", "2", locale: german) == nil)
        #expect(product("..", "2", locale: german) == nil)
        #expect(product("", "2", locale: german) == nil)
        #expect(product("true", "2", locale: german) == nil)
    }

    @Test func spacedLocaleDecimalCalculates() {
        #expect(product(" 4,5 ", "2", locale: german) == 9)
    }

    @Test func missingDependencyFailsClosed() {
        let form = formState()
        form.setValue("4,5", for: "gallons")
        #expect(
            form.calculateFieldValue(
                formula: "gallons * price",
                dependencies: ["gallons", "price"],
                locale: german
            ) == nil
        )
    }

    @Test func storedNumbersStillCalculate() {
        let form = formState()
        form.setValue(2, for: "gallons")
        form.setValue(3.25, for: "price")
        #expect(
            form.calculateFieldValue(
                formula: "gallons * price",
                dependencies: ["gallons", "price"],
                locale: german
            ) == 6.5
        )
    }

    @Test func missingOCRFieldUsesLocaleDecimal() {
        let form = formState()
        form.setValue("4,5", for: "gallons")
        form.setValue("2", for: "price")

        let fromComma = form.calculateMissingFieldFromOCR(
            availableFields: ["gallons", "price"],
            possibleFormulas: ["cost": "gallons * price"],
            locale: german
        )
        #expect(fromComma?.fieldId == "cost")
        #expect(fromComma?.calculatedValue == 9)

        form.setValue("4.5", for: "gallons")
        let fromPosix = form.calculateMissingFieldFromOCR(
            availableFields: ["gallons", "price"],
            possibleFormulas: ["cost": "gallons * price"],
            locale: german
        )
        #expect(fromPosix?.calculatedValue == 9)
    }

    @Test func missingOCRFieldRejectsNonNumber() {
        let form = formState()
        form.setValue("4,5abc", for: "gallons")
        form.setValue("2", for: "price")
        #expect(
            form.calculateMissingFieldFromOCR(
                availableFields: ["gallons", "price"],
                possibleFormulas: ["cost": "gallons * price"],
                locale: german
            ) == nil
        )
    }
}
