import Testing
@testable import SixLayerFramework

/// Unit tests for FieldViewTypeDeterminer
/// These are FAST - no view rendering, just pure logic testing
@Suite("Field View Type Determiner")
struct FieldViewTypeDeterminerTests {
    
    @Test func testTextFieldForTextContentType() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .text)
        #expect(viewType == .textField(keyboardType: .default, autocapitalization: .sentences))
    }
    
    @Test func testEmailFieldReturnsEmailKeyboard() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .email)
        #expect(viewType == .textField(keyboardType: .emailAddress, autocapitalization: .none))
    }
    
    @Test func testPhoneFieldReturnsPhoneKeyboard() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .phone)
        #expect(viewType == .textField(keyboardType: .phonePad, autocapitalization: .none))
    }
    
    @Test func testPasswordReturnsSecureField() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .password)
        #expect(viewType == .secureField)
    }
    
    @Test func testNumberFieldReturnsDecimalPad() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .number)
        #expect(viewType == .textField(keyboardType: .decimalPad, autocapitalization: .none))
    }
    
    @Test func testIntegerFieldReturnsDecimalPad() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .integer)
        #expect(viewType == .textField(keyboardType: .decimalPad, autocapitalization: .none))
    }
    
    @Test func testURLFieldReturnsURLKeyboard() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .url)
        #expect(viewType == .textField(keyboardType: .url, autocapitalization: .none))
    }
    
    @Test func testDateFieldReturnsDatePicker() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .date)
        #expect(viewType == .datePicker(displayedComponents: .date))
    }
    
    @Test func testTimeFieldReturnsTimePicker() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .time)
        #expect(viewType == .timePicker)
    }
    
    @Test func testDateTimeFieldReturnsDateTimePicker() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .datetime)
        #expect(viewType == .dateTimePicker)
    }
    
    @Test func testSelectFieldReturnsSelectComponent() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .select)
        #expect(viewType == .dynamicSelectField)
    }
    
    @Test func testRadioFieldReturnsRadioWithOptions() {
        let options = ["Option 1", "Option 2", "Option 3"]
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .radio, options: options)
        #expect(viewType == .radio(options: options))
    }
    
    @Test func testCheckboxFieldReturnsCheckboxComponent() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .checkbox)
        #expect(viewType == .dynamicCheckboxField)
    }
    
    @Test func testToggleFieldReturnsToggleComponent() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .toggle)
        #expect(viewType == .dynamicToggleField)
    }
    
    @Test func testTextAreaFieldReturnsTextAreaComponent() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .textarea)
        #expect(viewType == .dynamicTextAreaField)
    }
    
    @Test func testColorFieldReturnsColorComponent() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .color)
        #expect(viewType == .dynamicColorField)
    }
    
    @Test func testEnumFieldReturnsEnumPickerWithOptions() {
        let options = ["Red", "Green", "Blue"]
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .enum, options: options)
        #expect(viewType == .enumPicker(options: options))
    }
    
    @Test func testTextContentTypeEmailAddressReturnsEmailKeyboard() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .emailAddress)
        #expect(viewType == .textField(keyboardType: .emailAddress, autocapitalization: .none))
    }
    
    @Test func testTextContentTypeTelephoneNumberReturnsPhoneKeyboard() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .telephoneNumber)
        #expect(viewType == .textField(keyboardType: .phonePad, autocapitalization: .none))
    }
    
    @Test func testTextContentTypePasswordReturnsSecureField() {
        let viewType = FieldViewTypeDeterminer.determineViewType(for: .password)
        #expect(viewType == .secureField)
    }
    
    @Test func testAllContentTypesReturnValidViewTypes() {
        // Test that every DynamicContentType returns a valid view type
        for contentType in DynamicContentType.allCases {
            let viewType = FieldViewTypeDeterminer.determineViewType(for: contentType)
            // Just verify it doesn't crash - the type system ensures it's valid
        }
    }
}
