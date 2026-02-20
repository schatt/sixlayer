import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Cross-Platform Text Content Types

/// Cross-platform text content type enum that maps to UITextContentType on iOS/Mac Catalyst
/// and provides equivalent functionality on native macOS
public enum SixLayerTextContentType: String, CaseIterable, Hashable {
    // Person Names and Name Parts
    case name = "name"
    case namePrefix = "namePrefix"
    case givenName = "givenName"
    case middleName = "middleName"
    case familyName = "familyName"
    case nameSuffix = "nameSuffix"
    
    // Job/Work Information
    case jobTitle = "jobTitle"
    case organizationName = "organizationName"
    
    // Contact Information
    case emailAddress = "emailAddress"
    case telephoneNumber = "telephoneNumber"
    
    // Credentials/Login Information
    case username = "username"
    case password = "password"
    case newPassword = "newPassword"
    case oneTimeCode = "oneTimeCode"
    
    // Location/Address
    case location = "location"
    case fullStreetAddress = "fullStreetAddress"
    case streetAddressLine1 = "streetAddressLine1"
    case streetAddressLine2 = "streetAddressLine2"
    case addressCity = "addressCity"
    case addressState = "addressState"
    case addressCityAndState = "addressCityAndState"
    case sublocality = "sublocality"
    case countryName = "countryName"
    case postalCode = "postalCode"
    
    // URL and Credit Card Number
    case URL = "URL"
    case creditCardNumber = "creditCardNumber"
    
    #if canImport(UIKit)
    /// Convert to UITextContentType for iOS/Mac Catalyst
    public var uiTextContentType: UITextContentType {
        switch self {
        case .name: return .name
        case .namePrefix: return .namePrefix
        case .givenName: return .givenName
        case .middleName: return .middleName
        case .familyName: return .familyName
        case .nameSuffix: return .nameSuffix
        case .jobTitle: return .jobTitle
        case .organizationName: return .organizationName
        case .emailAddress: return .emailAddress
        case .telephoneNumber: return .telephoneNumber
        case .username: return .username
        case .password: return .password
        case .newPassword: return .newPassword
        case .oneTimeCode: return .oneTimeCode
        case .location: return .location
        case .fullStreetAddress: return .fullStreetAddress
        case .streetAddressLine1: return .streetAddressLine1
        case .streetAddressLine2: return .streetAddressLine2
        case .addressCity: return .addressCity
        case .addressState: return .addressState
        case .addressCityAndState: return .addressCityAndState
        case .sublocality: return .sublocality
        case .countryName: return .countryName
        case .postalCode: return .postalCode
        case .URL: return .URL
        case .creditCardNumber: return .creditCardNumber
        }
    }
    
    /// Create from UITextContentType
    public init(_ uiTextContentType: UITextContentType) {
        switch uiTextContentType {
        case .name: self = .name
        case .namePrefix: self = .namePrefix
        case .givenName: self = .givenName
        case .middleName: self = .middleName
        case .familyName: self = .familyName
        case .nameSuffix: self = .nameSuffix
        case .jobTitle: self = .jobTitle
        case .organizationName: self = .organizationName
        case .emailAddress: self = .emailAddress
        case .telephoneNumber: self = .telephoneNumber
        case .username: self = .username
        case .password: self = .password
        case .newPassword: self = .newPassword
        case .oneTimeCode: self = .oneTimeCode
        case .location: self = .location
        case .fullStreetAddress: self = .fullStreetAddress
        case .streetAddressLine1: self = .streetAddressLine1
        case .streetAddressLine2: self = .streetAddressLine2
        case .addressCity: self = .addressCity
        case .addressState: self = .addressState
        case .addressCityAndState: self = .addressCityAndState
        case .sublocality: self = .sublocality
        case .countryName: self = .countryName
        case .postalCode: self = .postalCode
        case .URL: self = .URL
        case .creditCardNumber: self = .creditCardNumber
        default:
            // Handle any future UITextContentType cases that might be added
            self = .name
        }
    }
    #endif
    
    /// Get string representation for native macOS
    public var stringValue: String {
        return self.rawValue
    }
}

// MARK: - Dynamic Form Field Types

/// Represents a dynamic form field configuration
public struct DynamicFormField: Identifiable {
    public let id: String
    public let textContentType: SixLayerTextContentType?  // Cross-platform text content type
    public let contentType: DynamicContentType?      // Our custom enum for UI components
    public let label: String
    public let placeholder: String?
    public let description: String? // Help text for the field
    public let isRequired: Bool
    public let validationRules: [String: String]?
    public let options: [String]? // For select/radio/checkbox fields
    public let defaultValue: String?
    public let metadata: [String: String]?

    // OCR Configuration
    public let supportsOCR: Bool // Whether this field can use OCR for input
    public let ocrHint: String? // Hint for OCR processing (e.g., "expect phone number", "expect address")
    public let ocrValidationTypes: [TextType]? // Expected OCR text types for validation
    public let ocrFieldIdentifier: String? // Unique identifier for mapping OCR results to specific fields
    public let ocrValidationRules: [String: Any]? // Custom validation rules (e.g., ["min": 0, "max": 100])
    public let ocrHints: [String]? // Keywords to help identify this field in OCR text (e.g., ["gallons", "gal", "fuel"])

    // Barcode Scanning Configuration
    public let supportsBarcodeScanning: Bool // Whether this field can use barcode scanning for input
    public let barcodeHint: String? // Hint for barcode scanning (e.g., "scan product barcode", "scan QR code")
    public let supportedBarcodeTypes: [BarcodeType]? // Expected barcode types for this field
    public let barcodeFieldIdentifier: String? // Unique identifier for mapping barcode results to specific fields

    // Calculation Configuration
    public let isCalculated: Bool // Whether this field is calculated from other fields
    public let calculationFormula: String? // Formula for calculated fields (e.g., "total_price / gallons")
    public let calculationDependencies: [String]? // Field IDs this calculation depends on
    public let calculationGroups: [CalculationGroup]? // Groups of calculations that can compute this field

    // Visibility Configuration
    /// Condition that determines if this field should be visible
    /// Returns true if field should be shown, false to hide
    public let visibilityCondition: ((DynamicFormState) -> Bool)?
    
    // Field Actions Configuration (Issue #95)
    /// Simple action for common cases (replaces/supplements supportsOCR/supportsBarcodeScanning)
    public let fieldAction: (any FieldAction)?
    
    /// View builder for complex custom actions
    /// Provides field and formState for building custom trailing UI
    public let trailingView: ((DynamicFormField, DynamicFormState) -> AnyView)?
    
    /// View builder for custom value display in display fields
    /// Provides field and formState for building custom value views (e.g., formatted dates, color swatches, status badges)
    /// When provided, replaces the default String(describing:) behavior in DynamicDisplayField
    public let valueView: ((DynamicFormField, DynamicFormState) -> AnyView)?
    
    /// Maximum number of actions to show as buttons before using menu
    public let maxVisibleActions: Int // Default: 2
    
    /// Whether to show actions in a menu when there are multiple
    public let useActionMenu: Bool // Default: true when actions > maxVisibleActions

    public init(
        id: String,
        textContentType: SixLayerTextContentType? = nil,
        contentType: DynamicContentType? = nil,
        label: String,
        placeholder: String? = nil,
        description: String? = nil,
        isRequired: Bool = false,
        validationRules: [String: String]? = nil,
        options: [String]? = nil,
        defaultValue: String? = nil,
        metadata: [String: String]? = nil,
        supportsOCR: Bool = false,
        ocrHint: String? = nil,
        ocrValidationTypes: [TextType]? = nil,
        ocrFieldIdentifier: String? = nil,
        ocrValidationRules: [String: Any]? = nil,
        ocrHints: [String]? = nil,
        supportsBarcodeScanning: Bool = false,
        barcodeHint: String? = nil,
        supportedBarcodeTypes: [BarcodeType]? = nil,
        barcodeFieldIdentifier: String? = nil,
        isCalculated: Bool = false,
        calculationFormula: String? = nil,
        calculationDependencies: [String]? = nil,
        calculationGroups: [CalculationGroup]? = nil,
        visibilityCondition: ((DynamicFormState) -> Bool)? = nil,
        fieldAction: (any FieldAction)? = nil,
        trailingView: ((DynamicFormField, DynamicFormState) -> AnyView)? = nil,
        valueView: ((DynamicFormField, DynamicFormState) -> AnyView)? = nil,
        maxVisibleActions: Int = 2,
        useActionMenu: Bool = true
    ) {
        self.id = id
        self.textContentType = textContentType
        self.contentType = contentType
        self.label = label
        self.placeholder = placeholder
        self.description = description
        self.isRequired = isRequired
        self.validationRules = validationRules
        self.options = options
        self.defaultValue = defaultValue
        self.metadata = metadata
        self.supportsOCR = supportsOCR
        self.ocrHint = ocrHint
        self.ocrValidationTypes = ocrValidationTypes
        self.ocrFieldIdentifier = ocrFieldIdentifier
        self.ocrValidationRules = ocrValidationRules
        self.ocrHints = ocrHints
        self.supportsBarcodeScanning = supportsBarcodeScanning
        self.barcodeHint = barcodeHint
        self.supportedBarcodeTypes = supportedBarcodeTypes
        self.barcodeFieldIdentifier = barcodeFieldIdentifier
        self.isCalculated = isCalculated
        self.calculationFormula = calculationFormula
        self.calculationDependencies = calculationDependencies
        self.calculationGroups = calculationGroups
        self.visibilityCondition = visibilityCondition
        self.fieldAction = fieldAction
        self.trailingView = trailingView
        self.valueView = valueView
        self.maxVisibleActions = maxVisibleActions
        self.useActionMenu = useActionMenu
    }
    
    /// Convenience initializer for text fields using cross-platform text content type
    public init(
        id: String,
        textContentType: SixLayerTextContentType,
        label: String,
        placeholder: String? = nil,
        description: String? = nil,
        isRequired: Bool = false,
        validationRules: [String: String]? = nil,
        defaultValue: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.init(
            id: id,
            textContentType: textContentType,
            contentType: nil,
            label: label,
            placeholder: placeholder,
            description: description,
            isRequired: isRequired,
            validationRules: validationRules,
            options: nil,
            defaultValue: defaultValue,
            metadata: metadata,
            supportsOCR: false,
            ocrHint: nil,
            ocrValidationTypes: nil,
            ocrFieldIdentifier: nil,
            ocrValidationRules: nil,
            ocrHints: nil,
            supportsBarcodeScanning: false,
            barcodeHint: nil,
            supportedBarcodeTypes: nil,
            barcodeFieldIdentifier: nil,
            isCalculated: false,
            calculationFormula: nil,
            calculationDependencies: nil,
            calculationGroups: nil,
            visibilityCondition: nil,
            fieldAction: nil,
            trailingView: nil,
            valueView: nil
        )
    }
    
    /// Convenience initializer for UI components using our custom DynamicContentType
    public init(
        id: String,
        contentType: DynamicContentType,
        label: String,
        placeholder: String? = nil,
        description: String? = nil,
        isRequired: Bool = false,
        validationRules: [String: String]? = nil,
        options: [String]? = nil,
        defaultValue: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.init(
            id: id,
            textContentType: nil,
            contentType: contentType,
            label: label,
            placeholder: placeholder,
            description: description,
            isRequired: isRequired,
            validationRules: validationRules,
            options: options,
            defaultValue: defaultValue,
            metadata: metadata,
            supportsOCR: false,
            ocrHint: nil,
            ocrValidationTypes: nil,
            ocrFieldIdentifier: nil,
            ocrValidationRules: nil,
            ocrHints: nil,
            supportsBarcodeScanning: false,
            barcodeHint: nil,
            supportedBarcodeTypes: nil,
            barcodeFieldIdentifier: nil,
            isCalculated: false,
            calculationFormula: nil,
            calculationDependencies: nil,
            calculationGroups: nil,
            visibilityCondition: nil,
            fieldAction: nil,
            trailingView: nil,
            valueView: nil
        )
    }
    
    /// Convenience initializer for tests: id, label, type, value, options
    public init(id: String, label: String, type: DynamicFormFieldType, value: String, options: [String]? = nil) {
        self.id = id
        self.label = label
        self.textContentType = nil
        self.contentType = nil
        self.placeholder = nil
        self.description = nil
        self.isRequired = false
        self.validationRules = nil
        self.options = options
        self.defaultValue = value
        self.metadata = nil
        self.supportsOCR = false
        self.ocrHint = nil
        self.ocrValidationTypes = nil
        self.ocrFieldIdentifier = nil
        self.ocrValidationRules = nil
        self.ocrHints = nil
        self.supportsBarcodeScanning = false
        self.barcodeHint = nil
        self.supportedBarcodeTypes = nil
        self.barcodeFieldIdentifier = nil
        self.isCalculated = false
        self.calculationFormula = nil
        self.calculationDependencies = nil
        self.calculationGroups = nil
        self.visibilityCondition = nil
        self.fieldAction = nil
        self.trailingView = nil
        self.valueView = nil
        self.maxVisibleActions = 2
        self.useActionMenu = true
    }
    

    /// Discover field-level display hints from the field's metadata
    /// Hints are automatically discovered from the data description, not passed in separately
    public var displayHints: FieldDisplayHints? {
        guard let metadata = metadata else { return nil }
        
        // Parse type information (new - for fully declarative hints)
        let fieldType = metadata["fieldType"]
        let isOptional: Bool? = {
            if let value = metadata["isOptional"] {
                return value == "true" ? true : (value == "false" ? false : nil)
            }
            return nil
        }()
        let isArray: Bool? = {
            if let value = metadata["isArray"] {
                return value == "true" ? true : (value == "false" ? false : nil)
            }
            return nil
        }()
        
        // Parse defaultValue (supports string, number, boolean as strings)
        let defaultValue: (any Sendable)? = {
            guard let valueStr = metadata["defaultValue"] else { return nil }
            // Try parsing as different types
            if let intValue = Int(valueStr) {
                return intValue
            } else if let doubleValue = Double(valueStr) {
                return doubleValue
            } else if valueStr.lowercased() == "true" {
                return true
            } else if valueStr.lowercased() == "false" {
                return false
            } else {
                return valueStr // Default to string
            }
        }()
        
        // Parse expectedRange from metadata (format: "min:max" or stored as separate keys)
        let expectedRange: ValueRange? = {
            // Try parsing from "expectedRange" as "min:max" format
            if let rangeStr = metadata["expectedRange"],
               let colonIndex = rangeStr.firstIndex(of: ":"),
               let min = Double(String(rangeStr[..<colonIndex])),
               let max = Double(String(rangeStr[rangeStr.index(after: colonIndex)...])) {
                return ValueRange(min: min, max: max)
            }
            // Try parsing from separate "expectedRangeMin" and "expectedRangeMax" keys
            if let minStr = metadata["expectedRangeMin"],
               let maxStr = metadata["expectedRangeMax"],
               let min = Double(minStr),
               let max = Double(maxStr) {
                return ValueRange(min: min, max: max)
            }
            return nil
        }()
        
        // Parse OCR hints (comma-separated string)
        let ocrHints: [String]? = {
            guard let hintsStr = metadata["ocrHints"], !hintsStr.isEmpty else { return nil }
            return hintsStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }()
        
        // Parse picker options from JSON string in metadata
        let pickerOptions: [PickerOption]? = {
            // Try parsing from "pickerOptions" key as JSON string
            if let optionsJsonStr = metadata["pickerOptions"],
               let jsonData = optionsJsonStr.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                var options: [PickerOption] = []
                for optionDict in jsonArray {
                    guard let value = optionDict["value"] as? String,
                          let label = optionDict["label"] as? String else {
                        continue // Skip invalid options
                    }
                    options.append(PickerOption(value: value, label: label))
                }
                return options.isEmpty ? nil : options
            }
            // Also try "options" key (alternative name)
            if let optionsJsonStr = metadata["options"],
               let jsonData = optionsJsonStr.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                var options: [PickerOption] = []
                for optionDict in jsonArray {
                    guard let value = optionDict["value"] as? String,
                          let label = optionDict["label"] as? String else {
                        continue // Skip invalid options
                    }
                    options.append(PickerOption(value: value, label: label))
                }
                return options.isEmpty ? nil : options
            }
            return nil
        }()
        
        // Parse calculation groups (stored as JSON string - would need JSON parsing for full support)
        // For now, we'll leave this as nil since it requires array of objects
        let calculationGroups: [CalculationGroup]? = nil
        
        // Parse boolean flags
        let isHidden = metadata["isHidden"] == "true"
        let isEditable = metadata["isEditable"] != "false"  // Defaults to true
        
        return FieldDisplayHints(
            // Type information (new)
            fieldType: fieldType,
            isOptional: isOptional,
            isArray: isArray,
            defaultValue: defaultValue,
            // Display properties (existing)
            expectedLength: metadata["expectedLength"].flatMap(Int.init),
            displayWidth: metadata["displayWidth"],
            showCharacterCounter: metadata["showCharacterCounter"] == "true",
            maxLength: metadata["maxLength"].flatMap(Int.init),
            minLength: metadata["minLength"].flatMap(Int.init),
            expectedRange: expectedRange,
            metadata: metadata,
            ocrHints: ocrHints,
            calculationGroups: calculationGroups,
            inputType: metadata["inputType"],
            pickerOptions: pickerOptions,
            isHidden: isHidden,
            isEditable: isEditable
        )
    }
    
    /// Get effective actions for this field
    /// Returns explicit fieldAction if set, otherwise converts supportsOCR/supportsBarcodeScanning flags to actions
    /// This ensures backward compatibility while supporting the new action system
    @MainActor
    public var effectiveActions: [any FieldAction] {
        // If explicit fieldAction is set, use it (takes precedence over flags)
        if let fieldAction = fieldAction {
            return [fieldAction]
        }
        
        // Otherwise, convert flags to actions for backward compatibility
        var actions: [any FieldAction] = []
        
        if supportsOCR {
            let ocrAction = BuiltInFieldAction.ocrScan(
                hint: ocrHint,
                validationTypes: ocrValidationTypes
            ).toFieldAction()
            actions.append(ocrAction)
        }
        
        if supportsBarcodeScanning {
            let barcodeAction = BuiltInFieldAction.barcodeScan(
                hint: barcodeHint,
                supportedTypes: supportedBarcodeTypes
            ).toFieldAction()
            actions.append(barcodeAction)
        }
        
        return actions
    }
    
    /// Apply hints to this field, creating a new field with updated properties
    /// - Parameter hints: The hints to apply
    /// - Returns: A new field with hints applied
    public func applying(hints: FieldDisplayHints) -> DynamicFormField {
        return DynamicFormField(
            id: self.id,
            textContentType: self.textContentType,
            contentType: self.contentType,
            label: self.label,
            placeholder: self.placeholder,
            description: self.description,
            isRequired: self.isRequired,
            validationRules: self.validationRules,
            options: self.options,
            defaultValue: self.defaultValue,
            metadata: self.metadata,
            supportsOCR: hints.ocrHints != nil ? true : self.supportsOCR,
            ocrHint: self.ocrHint,
            ocrValidationTypes: self.ocrValidationTypes,
            ocrFieldIdentifier: self.ocrFieldIdentifier,
            ocrValidationRules: self.ocrValidationRules,
            ocrHints: hints.ocrHints ?? self.ocrHints,
            supportsBarcodeScanning: self.supportsBarcodeScanning,
            barcodeHint: self.barcodeHint,
            supportedBarcodeTypes: self.supportedBarcodeTypes,
            barcodeFieldIdentifier: self.barcodeFieldIdentifier,
            isCalculated: hints.calculationGroups != nil ? true : self.isCalculated,
            calculationFormula: self.calculationFormula,
            calculationDependencies: self.calculationDependencies,
            calculationGroups: hints.calculationGroups ?? self.calculationGroups,
            visibilityCondition: self.visibilityCondition,
            fieldAction: self.fieldAction,
            trailingView: self.trailingView,
            valueView: self.valueView,
            maxVisibleActions: self.maxVisibleActions,
            useActionMenu: self.useActionMenu
        )
    }
}

/// Test-specific field type enum for convenience initializer
public enum DynamicFormFieldType: String, CaseIterable, Hashable {
    case text = "text"
    case email = "email"
    case password = "password"
    case phone = "phone"
    case url = "url"
    case number = "number"
    case integer = "integer"
    case date = "date"
    case time = "time"
    case datetime = "datetime"
    case select = "select"
    case multiselect = "multiselect"
    case radio = "radio"
    case checkbox = "checkbox"
    case textarea = "textarea"
    case richtext = "richtext"
    case file = "file"
    case image = "image"
    case color = "color"
    case range = "range"
    case toggle = "toggle"
    case array = "array"
    case data = "data"
    case autocomplete = "autocomplete"
    case `enum` = "enum"
    case custom = "custom"
}

/// Custom content types for non-text UI components
public enum DynamicContentType: String, CaseIterable, Hashable {
    case text = "text"               // Basic text input
    case email = "email"             // Email input
    case password = "password"       // Password input
    case phone = "phone"             // Phone number input
    case url = "url"                 // URL input
    case number = "number"           // Number input with validation
    case integer = "integer"         // Integer input
    case date = "date"               // Date picker
    case time = "time"               // Time picker
    case datetime = "datetime"       // Date & time picker
    case multiDate = "multiDate"     // Multiple date selection (iOS 16+)
    case dateRange = "dateRange"     // Date range selection
    case select = "select"           // Dropdown picker
    case multiselect = "multiselect" // Multi-select picker
    case radio = "radio"             // Radio buttons
    case checkbox = "checkbox"       // Checkboxes
    case textarea = "textarea"       // Multi-line text
    case richtext = "richtext"       // Rich text editor
    case file = "file"               // File picker
    case image = "image"             // Image picker
    case color = "color"             // Color picker
    case range = "range"             // Slider
    case stepper = "stepper"         // Increment/decrement control
    case toggle = "toggle"           // Toggle switch
    case boolean = "boolean"         // Boolean value (alias for toggle)
    case array = "array"             // Array input
    case data = "data"               // Data input
    case autocomplete = "autocomplete" // Autocomplete field
    case `enum` = "enum"             // Enum picker
    case display = "display"         // Read-only display field (uses LabeledContent on iOS 16+/macOS 13+)
    case gauge = "gauge"             // Visual gauge/level display (iOS 16+/macOS 13+)
    case custom = "custom"            // Custom component
    
    /// Check if content type supports options
    public var supportsOptions: Bool {
        switch self {
        case .select, .multiselect, .radio, .checkbox:
            return true
        default:
            return false
        }
    }
    
    /// Check if content type supports multiple values
    public var supportsMultipleValues: Bool {
        switch self {
        case .multiselect, .checkbox, .multiDate:
            return true
        default:
            return false
        }
    }
}

// MARK: - Dynamic Form Section

/// Represents a section in a dynamic form
// TODO: Make Sendable once DynamicFormField is Sendable
public struct DynamicFormSection: Identifiable {
    public let id: String
    public let title: String
    public let description: String?
    public var fields: [DynamicFormField]
    public let isCollapsible: Bool
    public let isCollapsed: Bool
    public let metadata: [String: String]?
    /// Optional layout style hint for this section (e.g., .horizontal, .vertical, .grid)
    /// When nil, framework uses default layout behavior
    public let layoutStyle: FieldLayout?
    
    public init(
        id: String,
        title: String,
        description: String? = nil,
        fields: [DynamicFormField] = [],
        isCollapsible: Bool = false,
        isCollapsed: Bool = false,
        metadata: [String: String]? = nil,
        layoutStyle: FieldLayout? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.fields = fields
        self.isCollapsible = isCollapsible
        self.isCollapsed = isCollapsed
        self.metadata = metadata
        self.layoutStyle = layoutStyle
    }
}

// MARK: - Dynamic Form Configuration

/// Complete configuration for a dynamic form
public struct DynamicFormConfiguration: Identifiable {
    public let id: String
    public let title: String
    public let description: String?
    public let sections: [DynamicFormSection]
    public let submitButtonText: String
    public let cancelButtonText: String?
    public let metadata: [String: String]?
    /// Optional model name for auto-loading hints from .hints files
    /// If provided, hints are automatically loaded and applied to fields
    public let modelName: String?
    /// Whether to show form progress indicator (Issue #82)
    public let showProgress: Bool
    
    public init(
        id: String,
        title: String,
        description: String? = nil,
        sections: [DynamicFormSection] = [],
        submitButtonText: String = "Submit",
        cancelButtonText: String? = "Cancel",
        metadata: [String: String]? = nil,
        modelName: String? = nil,
        showProgress: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.sections = sections
        self.submitButtonText = submitButtonText
        self.cancelButtonText = cancelButtonText
        self.metadata = metadata
        self.modelName = modelName
        self.showProgress = showProgress
    }
    
    /// Get all fields from all sections
    public var allFields: [DynamicFormField] {
        return sections.flatMap { $0.fields }
    }
    
    /// Get field by ID
        func getField(by id: String) -> DynamicFormField? {
        return allFields.first { $0.id == id }
    }
    
    /// Get section by ID
        func getSection(by id: String) -> DynamicFormSection? {
        return sections.first { $0.id == id }
    }

    /// Get all OCR-enabled fields in the form for batch processing
    /// - Returns: Array of fields that support OCR
    public func getOCREnabledFields() -> [DynamicFormField] {
        return sections.flatMap { $0.fields }.filter { $0.supportsOCR }
    }
    
    /// Apply hints from .hints file to this configuration
    /// If modelName is provided, loads hints and applies them to matching fields
    /// - Parameter hintsLoader: Optional hints loader (defaults to FileBasedDataHintsLoader)
    /// - Returns: New configuration with hints applied, or self if no modelName or no hints found
    public func applyingHints(hintsLoader: DataHintsLoader = FileBasedDataHintsLoader()) -> DynamicFormConfiguration {
        guard let modelName = modelName else {
            return self
        }
        
        let hintsResult = hintsLoader.loadHintsResult(for: modelName)
        let fieldHints = hintsResult.fieldHints
        
        // If no hints found, return original configuration
        guard !fieldHints.isEmpty else {
            return self
        }
        
        // Collect fields without hints for debug warning
        var fieldsWithoutHints: [String] = []
        
        // Apply hints to fields in sections
        let sectionsWithHints = sections.map { section in
            DynamicFormSection(
                id: section.id,
                title: section.title,
                description: section.description,
                fields: section.fields.map { field in
                    if let hints = fieldHints[field.id] {
                        return field.applying(hints: hints)
                    }
                    // Field exists but has no hints - collect for warning
                    fieldsWithoutHints.append(field.id)
                    return field
                },
                isCollapsible: section.isCollapsible,
                isCollapsed: section.isCollapsed,
                metadata: section.metadata,
                layoutStyle: section.layoutStyle
            )
        }
        
        // Debug warning: fields exist that aren't in hints file (hints file may be out of date)
        #if DEBUG
        if !fieldsWithoutHints.isEmpty {
            print("⚠️ Warning: Form configuration for model '\(modelName)' has fields without hints: \(fieldsWithoutHints.joined(separator: ", ")). Consider updating \(modelName).hints file.")
        }
        #endif
        
        // Create configuration with hints-applied sections
        return DynamicFormConfiguration(
            id: id,
            title: title,
            description: description,
            sections: sectionsWithHints,
            submitButtonText: submitButtonText,
            cancelButtonText: cancelButtonText,
            metadata: metadata,
            modelName: modelName
        )
    }
}

// MARK: - Calculation Groups

/// Represents a group of fields that can be used to calculate a target field
public struct CalculationGroup: Sendable {
    /// Unique identifier for this calculation group
    public let id: String
    /// Formula for calculating the target field (e.g., "total = price * quantity")
    public let formula: String
    /// Field IDs that this formula depends on
    public let dependentFields: [String]
    /// Priority for calculation order (lower numbers = higher priority)
    public let priority: Int

    public init(id: String, formula: String, dependentFields: [String], priority: Int) {
        self.id = id
        self.formula = formula
        self.dependentFields = dependentFields
        self.priority = priority
    }
}

/// Confidence level for calculated field values
public enum CalculationConfidence {
    /// High confidence - all calculation groups agree or only one group calculated
    case high
    /// Medium confidence - some uncertainty but generally reliable
    case medium
    /// Very low confidence - calculation groups produced conflicting results
    case veryLow
}

/// Result of calculating a field from calculation groups
public struct GroupCalculationResult {
    /// The calculated value
    public let calculatedValue: Double
    /// Confidence in the calculation result
    public let confidence: CalculationConfidence
    /// ID of the calculation group that was used (for high confidence single calculations)
    public let usedGroupId: String?
}

// MARK: - Dynamic Form State

/// State management for dynamic forms
/// Result of calculating a missing field from OCR data
public struct CalculatedFieldResult {
    /// The ID of the calculated field
    public let fieldId: String
    /// The calculated value
    public let calculatedValue: Double
}

// MARK: - Form Progress (Issue #82)

/// Represents the progress of form completion
public struct FormProgress {
    /// Number of completed required fields
    public let completed: Int
    /// Total number of required fields
    public let total: Int
    /// Completion percentage (0.0 to 1.0)
    public let percentage: Double
    
    public init(completed: Int, total: Int, percentage: Double) {
        self.completed = completed
        self.total = total
        self.percentage = percentage
    }
}

@MainActor
public class DynamicFormState: ObservableObject {
    @Published public var fieldValues: [String: Any] = [:]
    @Published public var fieldErrors: [String: [String]] = [:]
    @Published public var sectionStates: [String: Bool] = [:] // collapsed state
    @Published public var isSubmitting: Bool = false
    @Published public var isDirty: Bool = false
    @Published public var focusedFieldId: String? // Focus management (Issue #81)
    
    private let configuration: DynamicFormConfiguration
    
    // MARK: - Auto-Save Properties (Issue #80)
    
    /// Storage for form drafts
    private let storage: FormStateStorage
    
    /// Auto-save timer for periodic saves
    nonisolated(unsafe) private var autoSaveTimer: Timer?
    
    /// Debounce timer for change-based saves
    nonisolated(unsafe) private var debounceTimer: Timer?
    
    /// Auto-save configuration
    public var autoSaveEnabled: Bool = true
    public var autoSaveInterval: TimeInterval = 30.0 // seconds
    public var debounceDelay: TimeInterval = 2.0 // seconds
    
    /// Form ID for draft storage (uses configuration.id)
    private var formId: String {
        return configuration.id
    }
    
    /// Initialize with configuration and optional storage
    /// - Parameters:
    ///   - configuration: Form configuration
    ///   - storage: Optional storage implementation (defaults to UserDefaultsFormStateStorage)
    public init(
        configuration: DynamicFormConfiguration,
        storage: FormStateStorage? = nil
    ) {
        self.configuration = configuration
        self.storage = storage ?? UserDefaultsFormStateStorage()
        setupInitialState()
    }
    
    /// Get value for a specific field
    public func getValue<T>(for fieldId: String) -> T? {
        return fieldValues[fieldId] as? T
    }
    
    /// Set value for a specific field
    public func setValue<T>(_ value: T, for fieldId: String) {
        fieldValues[fieldId] = value
        isDirty = true
        clearErrors(for: fieldId)
    }

    /// Process OCR results and intelligently map them to OCR-enabled fields
    /// - Parameters:
    ///   - ocrResults: Array of OCR data candidates from document processing
    ///   - ocrEnabledFields: Fields that support OCR input
    /// - Returns: Dictionary mapping field IDs to assigned OCR values
    public func processBatchOCRResults(_ ocrResults: [OCRDataCandidate], for ocrEnabledFields: [DynamicFormField]) -> [String: String] {
        var assignments: [String: String] = [:]

        // Group OCR results by text type for intelligent mapping
        var resultsByType: [TextType: [OCRDataCandidate]] = [:]
        for result in ocrResults {
            resultsByType[result.suggestedType, default: []].append(result)
        }

        // For each OCR-enabled field, find the best available OCR result
        for field in ocrEnabledFields {
            guard let validationTypes = field.ocrValidationTypes else { continue }

            // Find the highest confidence OCR result that matches the field's expected types
            // and hasn't been assigned yet
            var bestMatch: OCRDataCandidate?
            var bestConfidence: Float = 0.0

            for validationType in validationTypes {
                if let typeResults = resultsByType[validationType] {
                    for result in typeResults {
                        if result.confidence > bestConfidence {
                            bestMatch = result
                            bestConfidence = result.confidence
                        }
                    }
                }
            }

            if let bestMatch = bestMatch {
                // Use ocrFieldIdentifier if provided, otherwise use field.id
                let targetFieldId = field.ocrFieldIdentifier ?? field.id
                assignments[targetFieldId] = bestMatch.text

                // Set the value in form state
                setValue(bestMatch.text, for: targetFieldId)

                // Remove this result from all type lists to prevent duplicate assignments
                for (type, results) in resultsByType {
                    resultsByType[type] = results.filter { $0.id != bestMatch.id }
                }
            }
        }

        return assignments
    }

    /// Initialize a field with its default value
    /// - Parameter field: The field to initialize
    public func initializeField(_ field: DynamicFormField) {
        if let defaultValue = field.defaultValue {
            fieldValues[field.id] = defaultValue
        }
    }

    /// Calculate a field value from other field values using a formula
    /// - Parameters:
    ///   - formula: The calculation formula (e.g., "total_price / gallons")
    ///   - dependencies: Array of field IDs that the formula depends on
    /// - Returns: The calculated value as Double, or nil if calculation fails
    public func calculateFieldValue(formula: String, dependencies: [String]) -> Double? {
        // Parse the formula and evaluate it using current field values
        // This is a basic implementation that supports simple arithmetic

        var processedFormula = formula

        // Replace field references with their current values
        for dependency in dependencies {
            if let value = fieldValues[dependency] {
                // Convert to string for replacement
                let stringValue = String(describing: value)
                processedFormula = processedFormula.replacingOccurrences(of: dependency, with: stringValue)
            } else {
                // If any dependency is missing, can't calculate
                return nil
            }
        }

        // Evaluate the mathematical expression
        return evaluateMathExpression(processedFormula)
    }

    /// Calculate missing fields from available OCR data
    /// Given a set of available field values and possible calculation formulas,
    /// determines which field is missing and calculates it
    /// - Parameters:
    ///   - availableFields: Array of field IDs that have values
    ///   - possibleFormulas: Dictionary mapping field IDs to their calculation formulas
    /// - Returns: A CalculatedFieldResult if a field can be calculated, nil otherwise
    public func calculateMissingFieldFromOCR(
        availableFields: [String],
        possibleFormulas: [String: String]
    ) -> CalculatedFieldResult? {
        // Find which fields are missing from the available set
        let allFields = Set(possibleFormulas.keys)
        let availableSet = Set(availableFields)
        let missingFields = allFields.subtracting(availableSet)

        // If no fields are missing, nothing to calculate
        if missingFields.isEmpty {
            return nil
        }

        // If more than one field is missing, we can't determine which to calculate
        if missingFields.count > 1 {
            return nil
        }

        // There's exactly one missing field - try to calculate it
        let missingField = missingFields.first!

        if let formula = possibleFormulas[missingField] {
            // Extract dependencies from the formula (simplified - assumes field names are used directly)
            let dependencies = extractFieldDependencies(from: formula)

            if let calculatedValue = calculateFieldValue(formula: formula, dependencies: dependencies) {
                return CalculatedFieldResult(
                    fieldId: missingField,
                    calculatedValue: calculatedValue
                )
            }
        }

        return nil
    }

    /// Evaluate a simple mathematical expression
    /// Supports basic arithmetic: +, -, *, /
    private func evaluateMathExpression(_ expression: String) -> Double? {
        // This is a very basic implementation for demonstration
        // In a real implementation, you'd use a proper expression parser

        let cleanedExpression = expression.replacingOccurrences(of: " ", with: "")

        // Handle simple operations
        if let result = evaluateSimpleExpression(cleanedExpression) {
            return result
        }

        return nil
    }

    /// Evaluate simple expressions with one operator
    private func evaluateSimpleExpression(_ expression: String) -> Double? {
        // Look for operators in order of precedence
        let operators: [(Character, (Double, Double) -> Double)] = [
            ("/", { $0 / $1 }),
            ("*", { $0 * $1 }),
            ("-", { $0 - $1 }),
            ("+", { $0 + $1 })
        ]

        for (opChar, operation) in operators {
            if let opIndex = expression.firstIndex(of: opChar) {
                let leftPart = String(expression[..<opIndex])
                let rightPart = String(expression[expression.index(after: opIndex)...])

                if let leftValue = Double(leftPart), let rightValue = Double(rightPart) {
                    return operation(leftValue, rightValue)
                }
            }
        }

        // If no operators found, try to parse as a single number
        return Double(expression)
    }

    /// Extract field dependencies from a formula
    /// This is a simplified implementation that assumes field names are alphanumeric
    private func extractFieldDependencies(from formula: String) -> [String] {
        // Split by operators and extract field names
        // This is very basic - a real implementation would need proper parsing

        let operators: [Character] = ["+", "-", "*", "/", "(", ")"]
        var currentWord = ""
        var dependencies: [String] = []

        for char in formula {
            if operators.contains(char) || char.isWhitespace {
                if !currentWord.isEmpty {
                    dependencies.append(currentWord)
                    currentWord = ""
                }
            } else {
                currentWord.append(char)
            }
        }

        if !currentWord.isEmpty {
            dependencies.append(currentWord)
        }

        return dependencies
    }

    /// Calculate a field value using calculation groups with conflict resolution
    /// - Parameters:
    ///   - fieldId: The ID of the field to calculate
    ///   - calculationGroups: Array of calculation groups that can compute this field
    /// - Returns: GroupCalculationResult if calculation is possible, nil otherwise
    public func calculateFieldFromGroups(
        fieldId: String,
        calculationGroups: [CalculationGroup]
    ) -> GroupCalculationResult? {
        // Sort groups by priority (lower number = higher priority)
        let sortedGroups = calculationGroups.sorted { $0.priority < $1.priority }

        var calculatedResults: [(value: Double, groupId: String)] = []

        // Try to calculate using each group in priority order
        for group in sortedGroups {
            if canCalculateWithGroup(group) {
                if let value = calculateWithGroup(group, targetFieldId: fieldId) {
                    calculatedResults.append((value: value, groupId: group.id))
                }
            }
        }

        // No groups could calculate
        if calculatedResults.isEmpty {
            return nil
        }

        // Only one group calculated - high confidence
        if calculatedResults.count == 1 {
            let result = calculatedResults[0]
            return GroupCalculationResult(
                calculatedValue: result.value,
                confidence: .high,
                usedGroupId: result.groupId
            )
        }

        // Multiple groups calculated - check for conflicts
        let firstValue = calculatedResults[0].value
        let allAgree = calculatedResults.allSatisfy { abs($0.value - firstValue) < 0.0001 }

        if allAgree {
            // All groups agree - high confidence
            return GroupCalculationResult(
                calculatedValue: firstValue,
                confidence: .high,
                usedGroupId: nil // Multiple groups agreed
            )
        } else {
            // Groups disagree - very low confidence, use first (highest priority) result
            return GroupCalculationResult(
                calculatedValue: firstValue,
                confidence: .veryLow,
                usedGroupId: calculatedResults[0].groupId
            )
        }
    }

    /// Check if all dependent fields for a calculation group are available
    private func canCalculateWithGroup(_ group: CalculationGroup) -> Bool {
        return group.dependentFields.allSatisfy { fieldValues[$0] != nil }
    }

    /// Calculate a field value using a specific calculation group
    private func calculateWithGroup(_ group: CalculationGroup, targetFieldId: String) -> Double? {
        // Parse the formula: "target = expression"
        let parts = group.formula.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }

        guard parts.count == 2 else { return nil }
        let expression = parts[1]

        // Replace field references with their values
        var processedExpression = expression
        for fieldId in group.dependentFields {
            if let value = fieldValues[fieldId] {
                let stringValue = String(describing: value)
                processedExpression = processedExpression.replacingOccurrences(of: fieldId, with: stringValue)
            } else {
                return nil // Missing dependency
            }
        }

        // Evaluate the mathematical expression
        return evaluateMathExpression(processedExpression)
    }

    /// Check if field has errors
    public func hasErrors(for fieldId: String) -> Bool {
        return !(fieldErrors[fieldId]?.isEmpty ?? true)
    }
    
    /// Get errors for a specific field
    public func getErrors(for fieldId: String) -> [String] {
        return fieldErrors[fieldId] ?? []
    }
    
    /// Add error for a specific field
    public func addError(_ error: String, for fieldId: String) {
        if fieldErrors[fieldId] == nil {
            fieldErrors[fieldId] = []
        }
        fieldErrors[fieldId]?.append(error)
    }
    
    /// Clear errors for a specific field
    public func clearErrors(for fieldId: String) {
        fieldErrors.removeValue(forKey: fieldId)
    }
    
    /// Clear all errors
    public func clearAllErrors() {
        fieldErrors.removeAll()
    }
    
    /// Check if section is collapsed
    public func isSectionCollapsed(_ sectionId: String) -> Bool {
        return sectionStates[sectionId] ?? false
    }
    
    /// Toggle section collapsed state
    public func toggleSection(_ sectionId: String) {
        sectionStates[sectionId] = !isSectionCollapsed(sectionId)
    }
    
    /// Check if form is valid
    public var isValid: Bool {
        return fieldErrors.values.allSatisfy { $0.isEmpty }
    }
    
    /// Check if form has any validation errors
    public var hasValidationErrors: Bool {
        return !fieldErrors.values.allSatisfy { $0.isEmpty }
    }
    
    /// Get total count of all validation errors across all fields
    public var errorCount: Int {
        return fieldErrors.values.reduce(0) { $0 + $1.count }
    }
    
    /// Get all validation errors as a flat list with field information
    /// Returns array of tuples: (fieldId: String, fieldLabel: String, message: String)
    public func allErrors(with configuration: DynamicFormConfiguration) -> [(fieldId: String, fieldLabel: String, message: String)] {
        var errors: [(fieldId: String, fieldLabel: String, message: String)] = []
        
        for (fieldId, errorMessages) in fieldErrors {
            guard !errorMessages.isEmpty else { continue }
            
            // Get field label from configuration
            let fieldLabel = configuration.getField(by: fieldId)?.label ?? fieldId
            
            // Add each error message
            for message in errorMessages {
                errors.append((fieldId: fieldId, fieldLabel: fieldLabel, message: message))
            }
        }
        
        return errors
    }
    
    /// Reset form to initial state
    public func reset() {
        fieldValues.removeAll()
        fieldErrors.removeAll()
        sectionStates.removeAll()
        isDirty = false
        setupInitialState()
    }
    
    /// Get form data as dictionary
    public var formData: [String: Any] {
        return fieldValues
    }
    
    // MARK: - Form Progress (Issue #82)
    
    /// Calculate form completion progress based on required fields
    public var formProgress: FormProgress {
        let allRequiredFields = configuration.allFields.filter { $0.isRequired }
        let completedRequiredFields = allRequiredFields.filter { field in
            if let value = fieldValues[field.id] {
                // For string values, check if not empty
                if let stringValue = value as? String {
                    return !stringValue.isEmpty
                }
                // Non-string values are considered filled if they exist
                return true
            }
            return false
        }
        
        let totalFields = allRequiredFields.count
        let completedFields = completedRequiredFields.count
        let percentage = totalFields > 0 ? Double(completedFields) / Double(totalFields) : 0.0
        
        return FormProgress(
            completed: completedFields,
            total: totalFields,
            percentage: percentage
        )
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        // Set default values
        for field in configuration.allFields {
            if let defaultValue = field.defaultValue {
                fieldValues[field.id] = defaultValue
            }
        }

        // Set initial section states
        for section in configuration.sections {
            sectionStates[section.id] = section.isCollapsed
        }
    }
    
    // MARK: - Auto-Save Methods (Issue #80)
    
    /// Start auto-save timer
    /// - Parameter interval: Save interval in seconds (defaults to autoSaveInterval)
    public func startAutoSave(interval: TimeInterval? = nil) {
        guard autoSaveEnabled else { return }
        
        stopAutoSave()
        
        let saveInterval = interval ?? autoSaveInterval
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveDraft()
            }
        }
    }
    
    /// Stop auto-save timer
    public func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    /// Save current form state as draft
    public func saveDraft() {
        guard autoSaveEnabled else { return }
        
        let draft = FormDraft(
            formId: formId,
            fieldValues: fieldValues,
            timestamp: Date()
        )
        
        do {
            try storage.saveDraft(draft)
        } catch {
            // Log error but don't crash - form should continue to function
            print("Error saving form draft: \(error.localizedDescription)")
        }
    }
    
    /// Load draft state if it exists
    /// - Returns: True if draft was loaded, false otherwise
    @discardableResult
    public func loadDraft() -> Bool {
        guard let draft = storage.loadDraft(formId: formId) else {
            return false
        }
        
        // Restore field values from draft
        fieldValues = draft.toFieldValues()
        return true
    }
    
    /// Clear draft state
    public func clearDraft() {
        do {
            try storage.clearDraft(formId: formId)
        } catch {
            // Log error but don't crash
            print("Error clearing form draft: \(error.localizedDescription)")
        }
    }
    
    /// Check if draft exists
    public func hasDraft() -> Bool {
        return storage.hasDraft(formId: formId)
    }
    
    /// Trigger debounced save on field change
    /// This should be called when fieldValues change
    public func triggerDebouncedSave() {
        guard autoSaveEnabled else { return }
        
        // Cancel existing debounce timer
        debounceTimer?.invalidate()
        
        // Start new debounce timer
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.saveDraft()
            }
        }
    }
    
    // MARK: - Focus Management Methods (Issue #81)
    
    /// Move focus to the next field in form order
    /// - Parameter currentFieldId: The ID of the currently focused field
    /// Skips non-focusable fields (e.g., date pickers that don't support keyboard focus)
    public func focusNextField(from currentFieldId: String) {
        let allFields = configuration.allFields
        
        // Find current field index
        guard let currentIndex = allFields.firstIndex(where: { $0.id == currentFieldId }) else {
            return
        }
        
        // Find next focusable field
        let nextIndex = currentIndex + 1
        if nextIndex < allFields.count {
            // Check if next field is focusable (text-based fields)
            let nextField = allFields[nextIndex]
            if isFieldFocusable(nextField) {
                focusedFieldId = nextField.id
            } else {
                // Skip non-focusable field and try next
                if nextIndex + 1 < allFields.count {
                    let nextNextField = allFields[nextIndex + 1]
                    if isFieldFocusable(nextNextField) {
                        focusedFieldId = nextNextField.id
                    } else {
                        // No more focusable fields, clear focus
                        focusedFieldId = nil
                    }
                } else {
                    // At end, clear focus
                    focusedFieldId = nil
                }
            }
        } else {
            // At last field, clear focus (no wrap)
            focusedFieldId = nil
        }
    }
    
    /// Move focus to the first field with a validation error
    /// Focuses the first field in form order that has errors
    public func focusFirstError() {
        guard !fieldErrors.isEmpty else {
            focusedFieldId = nil
            return
        }
        
        // Get all fields in order
        let allFields = configuration.allFields
        
        // Find first field with error
        for field in allFields {
            if hasErrors(for: field.id) && isFieldFocusable(field) {
                focusedFieldId = field.id
                return
            }
        }
        
        // No focusable fields with errors
        focusedFieldId = nil
    }
    
    /// Check if a field supports keyboard focus
    /// - Parameter field: The field to check
    /// - Returns: True if field supports keyboard focus (text-based fields)
    private func isFieldFocusable(_ field: DynamicFormField) -> Bool {
        // Text-based fields support focus
        switch field.contentType {
        case .text, .email, .password, .phone, .url, .number, .integer, .textarea, .autocomplete:
            return true
        case .date, .time, .datetime, .multiDate, .dateRange:
            // Date pickers don't support keyboard focus in the same way
            return false
        case .select, .multiselect, .radio, .checkbox:
            // These can be focused but navigation is different
            return true
        case .toggle, .boolean, .range, .stepper:
            // These can be focused
            return true
        case .file, .image, .color, .richtext, .data, .array, .enum, .custom:
            // These may or may not support focus depending on implementation
            return true
        case .display, .gauge:
            // Display fields and gauges are read-only and don't support focus
            return false
        case .none:
            // If no contentType, check textContentType
            return field.textContentType != nil
        }
    }
    
    deinit {
        // Invalidate timers directly in deinit (safe to do from any context)
        autoSaveTimer?.invalidate()
        debounceTimer?.invalidate()
    }
}

// MARK: - Dynamic Form Builder

/// Builder for creating dynamic form configurations
public struct DynamicFormBuilder {
    private var sections: [DynamicFormSection] = []
    private var currentSection: DynamicFormSection?
    
    public init() {}
    
    /// Start a new section
    public mutating func startSection(
        id: String,
        title: String,
        description: String? = nil,
        isCollapsible: Bool = false,
        isCollapsed: Bool = false
    ) {
        // Complete previous section if exists
        if let section = currentSection {
            sections.append(section)
        }
        
        currentSection = DynamicFormSection(
            id: id,
            title: title,
            description: description,
            isCollapsible: isCollapsible,
            isCollapsed: isCollapsed
        )
    }
    
    /// Add a text field using cross-platform text content type
    public mutating func addTextField(
        id: String,
        textContentType: SixLayerTextContentType,
        label: String,
        placeholder: String? = nil,
        isRequired: Bool = false,
        validationRules: [String: String]? = nil,
        defaultValue: String? = nil,
        metadata: [String: String]? = nil
    ) {
        if currentSection == nil {
            // Create default section if none exists
            currentSection = DynamicFormSection(
                id: "default",
                title: "Form Fields",
                fields: []
            )
        }
        
        let field = DynamicFormField(
            id: id,
            textContentType: textContentType,
            label: label,
            placeholder: placeholder,
            isRequired: isRequired,
            validationRules: validationRules,
            defaultValue: defaultValue,
            metadata: metadata
        )
        
        currentSection?.fields.append(field)
    }
    
    /// Add a UI component using our custom DynamicContentType
    public mutating func addContentField(
        id: String,
        contentType: DynamicContentType,
        label: String,
        placeholder: String? = nil,
        isRequired: Bool = false,
        validationRules: [String: String]? = nil,
        options: [String]? = nil,
        defaultValue: String? = nil,
        metadata: [String: String]? = nil
    ) {
        if currentSection == nil {
            // Create default section if none exists
            currentSection = DynamicFormSection(
                id: "default",
                title: "Form Fields",
                fields: []
            )
        }
        
        let field = DynamicFormField(
            id: id,
            contentType: contentType,
            label: label,
            placeholder: placeholder,
            isRequired: isRequired,
            validationRules: validationRules,
            options: options,
            defaultValue: defaultValue,
            metadata: metadata
        )
        
        currentSection?.fields.append(field)
    }
    
    /// Complete the current section
    public mutating func endSection() {
        if let section = currentSection {
            sections.append(section)
            currentSection = nil
        }
    }
    
    /// Build the form configuration
    public mutating func build(
        id: String,
        title: String,
        description: String? = nil,
        submitButtonText: String = "Submit",
        cancelButtonText: String? = "Cancel"
    ) -> DynamicFormConfiguration {
        // Complete any remaining section
        if let section = currentSection {
            sections.append(section)
        }
        
        return DynamicFormConfiguration(
            id: id,
            title: title,
            description: description,
            sections: sections,
            submitButtonText: submitButtonText,
            cancelButtonText: cancelButtonText
        )
    }
}

// MARK: - Custom Field Components

/// Protocol for custom field components in the dynamic form system
/// Allows registration of custom field types that can be rendered by CustomFieldView
public protocol CustomFieldComponent: View {
    /// The field configuration this component should render
    var field: DynamicFormField { get }

    /// The form state for data binding
    var formState: DynamicFormState { get }

    /// Initialize the component with field configuration and form state
    init(field: DynamicFormField, formState: DynamicFormState)
}

/// Registry for custom field components
/// Allows registering custom field types by key for dynamic rendering
public final class CustomFieldRegistry: @unchecked Sendable {
    /// Shared instance for global registration
    public static let shared = CustomFieldRegistry()

    /// Dictionary mapping field type keys to component factories
    private var componentFactories: [String: (DynamicFormField, DynamicFormState) -> any CustomFieldComponent] = [:]
    private let lock = NSLock()

    private init() {}

    /// Register a custom field component factory
    /// - Parameters:
    ///   - key: The field type key (e.g., "slider", "color-picker")
    ///   - factory: Factory closure that creates the component
    public func register(_ key: String, factory: @escaping (DynamicFormField, DynamicFormState) -> any CustomFieldComponent) {
        lock.lock()
        defer { lock.unlock() }
        componentFactories[key] = factory
    }

    /// Unregister a custom field component
    /// - Parameter key: The field type key to remove
    public func unregister(_ key: String) {
        lock.lock()
        defer { lock.unlock() }
        componentFactories.removeValue(forKey: key)
    }

    /// Create a component for the given field if registered
    /// - Parameters:
    ///   - field: The field configuration
    ///   - formState: The form state
    /// - Returns: The custom component if registered, nil otherwise
    public func createComponent(for field: DynamicFormField, formState: DynamicFormState) -> (any CustomFieldComponent)? {
        lock.lock()
        defer { lock.unlock() }
        guard let factory = componentFactories[field.contentType?.rawValue ?? ""] else {
            return nil
        }
        return factory(field, formState)
    }

    /// Check if a field type is registered
    /// - Parameter key: The field type key
    /// - Returns: True if registered, false otherwise
    public func isRegistered(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return componentFactories[key] != nil
    }

    /// Get all registered field type keys
    /// - Returns: Array of registered keys
    public func registeredKeys() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(componentFactories.keys)
    }

    /// Reset the registry (primarily for testing)
    /// - Note: This clears all registered components
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        componentFactories.removeAll()
    }
}

// MARK: - Accessibility Support

/// Protocol for elements that support accessibility validation
public protocol AccessibleElement {
    /// The accessibility label
    var accessibilityLabel: String? { get }

    /// The accessibility hint
    var accessibilityHint: String? { get }

    /// The accessibility traits
    var accessibilityTraits: AccessibilityTraits { get }

    /// The frame of the element
    var frame: CGRect { get }
}