import Foundation
import Testing

@testable import SixLayerFramework

/// Formula, gauge, and stepper read a current-locale decimal the same way they read `4.5` (#624).
/// POSIX `4.5` still wins when the locale uses a comma. A string that is not a number still fails.
@Suite("Locale decimal readers")
@MainActor
struct DynamicFormLocaleDecimalReaderTests {

    private let german = Locale(identifier: "de_DE")
    private let posix = Locale(identifier: "en_US_POSIX")

    private func formState() -> DynamicFormState {
        DynamicFormState(configuration: DynamicFormConfiguration(id: "fuel", title: "Fuel"))
    }

    private func costGroup() -> CalculationGroup {
        CalculationGroup(
            id: "cost",
            formula: "result = gallons * price",
            dependentFields: ["gallons", "price"],
            priority: 1
        )
    }

    private func calculated(_ gallons: String, _ price: String, locale: Locale) -> Double? {
        let form = formState()
        form.setValue(gallons, for: "gallons")
        form.setValue(price, for: "price")
        return form.calculateFieldFromGroups(
            fieldId: "result",
            calculationGroups: [costGroup()],
            locale: locale
        )?.calculatedValue
    }

    @Test func formula_localeCommaDecimalMatchesPosixDecimal() {
        #expect(calculated("4,5", "2", locale: german) == 9)
        #expect(calculated("4.5", "2", locale: german) == 9)
    }

    @Test func formula_negativeLocaleDecimalMatchesPosix() {
        #expect(calculated("-4,5", "2", locale: german) == -9)
        #expect(calculated("-4.5", "2", locale: german) == -9)
    }

    @Test func formula_posixPointDecimalStaysPointDecimal() {
        #expect(calculated("1.234", "1", locale: german) == Double("1.234"))
    }

    @Test func formula_posixLocaleRejectsCommaDecimal() {
        #expect(calculated("4,5", "2", locale: posix) == nil)
    }

    @Test func formula_incompleteLocaleDecimalDoesNotCalculate() {
        #expect(calculated("4,5abc", "2", locale: german) == nil)
        #expect(calculated("..", "2", locale: german) == nil)
        #expect(calculated("", "2", locale: german) == nil)
    }

    @Test func formula_spacedLocaleDecimalCalculates() {
        #expect(calculated(" 4,5 ", "2", locale: german) == 9)
    }

    private func gauge(stored: String?, defaultValue: String?, locale: Locale) -> Double {
        let form = formState()
        let field = DynamicFormField(
            id: "level",
            contentType: .gauge,
            label: "Level",
            defaultValue: defaultValue,
            metadata: ["min": "0", "max": "100"]
        )
        if let stored {
            form.setValue(stored, for: "level")
        }
        return DynamicGaugeField(field: field, formState: form, locale: locale).value
    }

    @Test func gauge_localeCommaDecimalMatchesPosixDecimal() {
        #expect(gauge(stored: "4,5", defaultValue: nil, locale: german) == 4.5)
        #expect(gauge(stored: "4.5", defaultValue: nil, locale: german) == 4.5)
    }

    @Test func gauge_negativeLocaleDecimal() {
        #expect(gauge(stored: "-4,5", defaultValue: "0", locale: german) == -4.5)
    }

    @Test func gauge_rejectsNonNumberAndPosixComma() {
        #expect(gauge(stored: "4,5abc", defaultValue: nil, locale: german) == 0)
        #expect(gauge(stored: "4,5", defaultValue: nil, locale: posix) == 0)
    }

    @Test func gauge_localeDefaultWhenNothingStored() {
        #expect(gauge(stored: nil, defaultValue: "4,5", locale: german) == 4.5)
    }

    private func stepper(stored: String?, defaultValue: String, locale: Locale) -> Double {
        let form = formState()
        let field = DynamicFormField(
            id: "count",
            contentType: .stepper,
            label: "Count",
            defaultValue: defaultValue,
            metadata: ["min": "0", "max": "100", "step": "0.5"]
        )
        if let stored {
            form.setValue(stored, for: "count")
        }
        return DynamicStepperField(field: field, formState: form, locale: locale).value.wrappedValue
    }

    @Test func stepper_localeCommaDecimalMatchesPosixDecimal() {
        #expect(stepper(stored: "4,5", defaultValue: "0", locale: german) == 4.5)
        #expect(stepper(stored: "4.5", defaultValue: "0", locale: german) == 4.5)
    }

    @Test func stepper_negativeLocaleDecimal() {
        #expect(stepper(stored: "-4,5", defaultValue: "0", locale: german) == -4.5)
    }

    @Test func stepper_rejectsNonNumberAndUsesDefault() {
        #expect(stepper(stored: "4,5abc", defaultValue: "1", locale: german) == 1)
        #expect(stepper(stored: "4,5", defaultValue: "1", locale: posix) == 1)
    }

    @Test func stepper_localeDefaultWhenNothingStored() {
        #expect(stepper(stored: nil, defaultValue: "4,5", locale: german) == 4.5)
    }
}
