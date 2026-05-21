import Foundation
import Testing

@testable import SixLayerFramework

@Suite("DynamicFormStoredNumericDisplay")
struct DynamicFormStoredNumericDisplayTests {

    @Test func displayString_usesStringAsIs() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: "12.5", defaultValue: "0")
            == "12.5"
        )
    }

    @Test func displayString_formatsDoubleWithoutScientificNotation() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: 12.5, defaultValue: nil)
            == "12.5"
        )
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: 42_000.0, defaultValue: nil)
            == "42000"
        )
    }

    @Test func displayString_formatsInt() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: 7, defaultValue: nil)
            == "7"
        )
    }

    @Test func displayString_formatsNSNumber() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: NSNumber(value: 12.5), defaultValue: nil)
            == "12.5"
        )
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: NSNumber(value: 9), defaultValue: nil)
            == "9"
        )
    }

    @Test func displayString_fallsBackToDefaultWhenNilOrUnsupported() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: nil, defaultValue: "9")
            == "9"
        )
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: Date(), defaultValue: "fallback")
            == "fallback"
        )
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: nil, defaultValue: nil)
            == ""
        )
    }

    @Test @MainActor func formState_doubleValueDisplaysForNumberFieldBinding() {
        let field = DynamicFormField(
            id: "gallons",
            contentType: .number,
            label: "Gallons",
            defaultValue: "0"
        )
        let config = DynamicFormConfiguration(id: "fuel", title: "Fuel", sections: [])
        let state = DynamicFormState(configuration: config)
        state.setValue(12.5, for: "gallons")

        let binding = field.numericTextBinding(formState: state)
        #expect(binding.wrappedValue == "12.5")
        #expect(binding.wrappedValue.isEmpty == false)
    }

    @Test @MainActor func formState_intValueDisplaysForIntegerFieldBinding() {
        let field = DynamicFormField(
            id: "odometer",
            contentType: .integer,
            label: "Odometer"
        )
        let config = DynamicFormConfiguration(id: "car", title: "Car", sections: [])
        let state = DynamicFormState(configuration: config)
        state.setValue(12345, for: "odometer")

        let binding = field.numericTextBinding(formState: state)
        #expect(binding.wrappedValue == "12345")
    }

    @Test @MainActor func formState_existingStringValueUnchanged() {
        let field = DynamicFormField(
            id: "gallons",
            contentType: .number,
            label: "Gallons"
        )
        let config = DynamicFormConfiguration(id: "fuel", title: "Fuel", sections: [])
        let state = DynamicFormState(configuration: config)
        state.setValue("12.50", for: "gallons")

        let binding = field.numericTextBinding(formState: state)
        #expect(binding.wrappedValue == "12.50")
    }
}
