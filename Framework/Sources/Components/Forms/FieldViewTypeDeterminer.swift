//
//  FieldViewTypeDeterminer.swift
//  SixLayerFramework
//
//  Pure business logic for determining which view type to create for a field
//  This is testable WITHOUT rendering views - just test input -> output
//

import Foundation

// MARK: - Field View Type Configuration

/// Describes what type of view should be created for a field
/// This is pure data - testable without SwiftUI
public enum FieldViewType: Equatable {
    case textField(keyboardType: FormKeyboardType?, autocapitalization: FormAutocapitalizationType)
    case secureField
    case datePicker(displayedComponents: FormDatePickerComponents)
    case timePicker
    case dateTimePicker
    case picker(style: FormPickerStyle)
    case radio(options: [String])
    case multiselect(options: [String])
    case toggle
    case textArea
    case colorPicker
    case autocomplete(suggestions: [String])
    case richTextEditor
    case fileUpload
    case imagePicker
    case dataInput
    case arrayInput
    case enumPicker(options: [String])
    case custom
    
    // Specific component types when they exist
    case dynamicColorField
    case dynamicToggleField
    case dynamicCheckboxField
    case dynamicTextAreaField
    case dynamicSelectField
}

/// Keyboard type for form fields (avoiding conflict with SwiftUI.UIKeyboardType)
public enum FormKeyboardType: Equatable {
    case emailAddress
    case phonePad
    case decimalPad
    case url
    case `default`
}

/// Autocapitalization type for form fields (avoiding conflict with SwiftUI.UITextAutocapitalizationType)
public enum FormAutocapitalizationType: Equatable {
    case none
    case words
    case sentences
}

/// Picker style for form fields (avoiding conflict with SwiftUI.PickerStyle)
public enum FormPickerStyle: Equatable {
    case menu
    case segmented
    case wheel
}

/// Date picker components for form fields (avoiding conflict with SwiftUI.DatePickerComponents)
public enum FormDatePickerComponents: Equatable {
    case date
    case time
    case dateAndTime
}

// MARK: - Field View Type Determiner

/// Pure function that determines what view type to create for a field
/// This is testable WITHOUT rendering SwiftUI views
public struct FieldViewTypeDeterminer {
    
    /// Determine the view type for a given contentType
    /// This is PURE business logic - no SwiftUI dependencies
    public static func determineViewType(
        for contentType: DynamicContentType,
        options: [String]? = nil
    ) -> FieldViewType {
        switch contentType {
        case .text:
            return .textField(keyboardType: FormKeyboardType.default, autocapitalization: FormAutocapitalizationType.sentences)
        case .email:
            return .textField(keyboardType: FormKeyboardType.emailAddress, autocapitalization: FormAutocapitalizationType.none)
        case .phone:
            return .textField(keyboardType: FormKeyboardType.phonePad, autocapitalization: FormAutocapitalizationType.none)
        case .password:
            return .secureField
        case .number, .integer:
            return .textField(keyboardType: FormKeyboardType.decimalPad, autocapitalization: FormAutocapitalizationType.none)
        case .url:
            return .textField(keyboardType: FormKeyboardType.url, autocapitalization: FormAutocapitalizationType.none)
        case .date:
            return .datePicker(displayedComponents: FormDatePickerComponents.date)
        case .time:
            return .timePicker
        case .datetime:
            return .dateTimePicker
        case .multiDate:
            return .datePicker(displayedComponents: FormDatePickerComponents.date) // Use datePicker as fallback
        case .dateRange:
            return .datePicker(displayedComponents: FormDatePickerComponents.date) // Use datePicker as fallback
        case .select:
            return .dynamicSelectField
        case .enum:
            return .enumPicker(options: options ?? [])
        case .radio:
            return .radio(options: options ?? [])
        case .checkbox:
            return .dynamicCheckboxField
        case .toggle, .boolean:
            return .dynamicToggleField
        case .textarea:
            return .dynamicTextAreaField
        case .color:
            return .dynamicColorField
        case .richtext:
            return .richTextEditor
        case .autocomplete:
            return .autocomplete(suggestions: options ?? [])
        case .multiselect:
            return .multiselect(options: options ?? [])
        case .file:
            return .fileUpload
        case .image:
            return .imagePicker
        case .data:
            return .dataInput
        case .array:
            return .arrayInput
        case .range, .gauge:
            return .toggle  // Range/slider/gauge uses toggle-like component
        case .stepper:
            return .textField(keyboardType: FormKeyboardType.decimalPad, autocapitalization: FormAutocapitalizationType.none)  // Stepper uses numeric input
        case .display:
            return .textField(keyboardType: nil, autocapitalization: FormAutocapitalizationType.none)  // Display fields are read-only text
        case .custom:
            return .custom
        @unknown default:
            // Handle any future cases or unknown cases gracefully
            return .textField(keyboardType: FormKeyboardType.default, autocapitalization: FormAutocapitalizationType.sentences)
        }
    }
    
    /// Determine the view type for a textContentType
    public static func determineViewType(
        for textContentType: SixLayerTextContentType
    ) -> FieldViewType {
        // Map OS text content types to our view types
        // This is also pure logic - testable
        switch textContentType {
        case .emailAddress, .username:
            return .textField(keyboardType: FormKeyboardType.emailAddress, autocapitalization: FormAutocapitalizationType.none)
        case .telephoneNumber:
            return .textField(keyboardType: FormKeyboardType.phonePad, autocapitalization: FormAutocapitalizationType.none)
        case .URL:
            return .textField(keyboardType: FormKeyboardType.url, autocapitalization: FormAutocapitalizationType.none)
        case .password, .newPassword:
            return .secureField
        case .name, .namePrefix, .givenName, .middleName, .familyName, .nameSuffix,
             .jobTitle, .organizationName,
             .location, .fullStreetAddress, .streetAddressLine1, .streetAddressLine2,
             .addressCity, .addressState, .addressCityAndState, .sublocality,
             .countryName, .postalCode, .creditCardNumber, .oneTimeCode:
            return .textField(keyboardType: FormKeyboardType.default, autocapitalization: FormAutocapitalizationType.words)
        }
    }
}
