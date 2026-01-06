//
//  GenericTypes.swift
//  SixLayerFramework Examples
//
//  EXAMPLE TYPES: Generic types for demonstration and testing purposes
//  These are example implementations showing how to use the framework
//  with generic data types. Copy and modify these for your own use cases.
//

import Foundation
import SwiftUI

// Import the CardDisplayable protocol from the framework
// Note: In a real project, you would import SixLayerFramework
// import SixLayerFramework

// MARK: - Generic Vehicle Type

/// EXAMPLE: Generic vehicle type for demonstration and testing purposes
/// This shows how to create a custom type that works with the framework
/// Copy this pattern and modify for your own vehicle types
public struct GenericVehicle: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let type: VehicleType
    
    public init(name: String, description: String, type: VehicleType = .generic) {
        self.name = name
        self.description = description
        self.type = type
    }
    
        public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: GenericVehicle, rhs: GenericVehicle) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Vehicle Type Enumeration

/// Generic vehicle types for categorization
public enum VehicleType: String, CaseIterable {
    case generic = "Generic"
    case car = "Car"
    case truck = "Truck"
    case motorcycle = "Motorcycle"
    case boat = "Boat"
    case aircraft = "Aircraft"
    case other = "Other"
}

// MARK: - Generic Data Types

/// EXAMPLE: Generic data item for collections
/// This shows how to create a generic container that works with the framework
/// Copy this pattern and modify for your own data types
public struct GenericDataItem: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let data: [String: Any]
    
    public init(title: String, subtitle: String? = nil, data: [String: Any] = [:]) {
        self.title = title
        self.subtitle = subtitle
        self.data = data
    }
    
        public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: GenericDataItem, rhs: GenericDataItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Generic Form Field

/// Generic form field for form handling with binding support
/// 
/// ⚠️ **DEPRECATED**: This struct is deprecated and will be removed in a future version.
/// Use `DynamicFormField` with `DynamicFormState` instead, which provides:
/// - Native data type support (Date, Bool, Double, etc.)
/// - Better type safety
/// - More flexible field configuration
/// - Consistent API across the framework
/// 
/// **Migration Guide:**
/// ```swift
/// // Old (deprecated)
/// GenericFormField(
///     label: "Date",
///     value: $dateString,  // String binding
///     fieldType: .date
/// )
/// 
/// // New (recommended)
/// DynamicFormField(
///     id: "date",
///     type: .date,
///     label: "Date"
/// )
/// // Use with DynamicFormState for native Date binding
/// ```
@available(*, deprecated, message: "Use DynamicFormField with DynamicFormState instead for better type safety and native data type support")
/*
public struct GenericFormField: Identifiable {
    public let id = UUID()
    public let label: String
    public let placeholder: String?
    public let isRequired: Bool
    public let fieldType: DynamicFieldType
    public let validationRules: [ValidationRule]
    public let options: [String] // For select, radio, multiselect fields
    public let maxLength: Int?
    public let minLength: Int?
    
    // Binding for two-way data binding
    @Binding public var value: String
    
    public init(
        label: String,
        placeholder: String? = nil,
        value: Binding<String>,
        isRequired: Bool = false,
        fieldType: DynamicFieldType = .text,
        validationRules: [ValidationRule] = [],
        options: [String] = [],
        maxLength: Int? = nil,
        minLength: Int? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._value = value
        self.isRequired = isRequired
        self.fieldType = fieldType
        self.validationRules = validationRules
        self.options = options
        self.maxLength = maxLength
        self.minLength = minLength
    }
}
*/

// MARK: - Validation Rule

/// Form field validation rule
public struct ValidationRule {
    public let rule: ValidationRuleType
    public let message: String
    public let customValidator: ((String) -> Bool)?
    
    public init(
        rule: ValidationRuleType,
        message: String,
        customValidator: ((String) -> Bool)? = nil
    ) {
        self.rule = rule
        self.message = message
        self.customValidator = customValidator
    }
}

// MARK: - Validation Rule Types

public enum ValidationRuleType {
    case required
    case email
    case phone
    case url
    case minLength(Int)
    case maxLength(Int)
    case pattern(String) // Regex pattern
    case custom((String) -> Bool)
}

// MARK: - Form Validation Result

public struct FormValidationResult {
    public let isValid: Bool
    public let errors: [String: String] // fieldId: errorMessage
    
    public init(isValid: Bool, errors: [String: String] = [:]) {
        self.isValid = isValid
        self.errors = errors
    }
}


// MARK: - Generic Media Item

/// Generic media item for media collections
public struct GenericMediaItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String?
    public let mediaType: MediaType
    public let url: URL?
    
    public init(
        title: String,
        description: String? = nil,
        mediaType: MediaType = .image,
        url: URL? = nil
    ) {
        self.title = title
        self.description = description
        self.mediaType = mediaType
        self.url = url
    }
}

// MARK: - Media Type

/// Types of media
public enum MediaType: String, CaseIterable {
    case image = "image"
    case video = "video"
    case audio = "audio"
    case document = "document"
    case other = "other"
}

// MARK: - Generic Temporal Data

/// Generic temporal data for date-based collections
public struct GenericTemporalData: Identifiable {
    public let id = UUID()
    public let title: String
    public let date: Date
    public let description: String?
    public let data: [String: Any]
    
    public init(
        title: String,
        date: Date,
        description: String? = nil,
        data: [String: Any] = [:]
    ) {
        self.title = title
        self.date = date
        self.description = description
        self.data = data
    }
}

// MARK: - Generic Hierarchical Data

/// Generic hierarchical data for tree-like structures
public struct GenericHierarchicalData: Identifiable {
    public let id = UUID()
    public let title: String
    public let children: [GenericHierarchicalData]
    public let data: [String: Any]
    
    public init(
        title: String,
        children: [GenericHierarchicalData] = [],
        data: [String: Any] = [:]
    ) {
        self.title = title
        self.children = children
        self.data = data
    }
}

// MARK: - Generic Numeric Data

/// Generic numeric data for charts and analytics
public struct GenericNumericData: Identifiable {
    public let id = UUID()
    public let label: String
    public let value: Double
    public let unit: String?
    public let metadata: [String: Any]
    
    public init(
        label: String,
        value: Double,
        unit: String? = nil,
        metadata: [String: Any] = [:]
    ) {
        self.label = label
        self.value = value
        self.unit = unit
        self.metadata = metadata
    }
}

// MARK: - Generic Hierarchical Item

/// Generic hierarchical item for tree-like structures
public struct GenericHierarchicalItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let children: [GenericHierarchicalItem]
    public let data: [String: Any]
    
    public init(
        title: String,
        children: [GenericHierarchicalItem] = [],
        data: [String: Any] = [:]
    ) {
        self.title = title
        self.children = children
        self.data = data
    }
}

// MARK: - Generic Temporal Item

/// Generic temporal item for date-based collections
public struct GenericTemporalItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let date: Date
    public let description: String?
    public let data: [String: Any]
    
    public init(
        title: String,
        date: Date,
        description: String? = nil,
        data: [String: Any] = [:]
    ) {
        self.title = title
        self.date = date
        self.description = description
        self.data = data
    }
}

// MARK: - CardDisplayable Extensions
// These extensions show how to make your custom types work with the framework

/// Extension to make GenericDataItem conform to CardDisplayable
extension GenericDataItem: CardDisplayable {
    public var cardTitle: String { title }
    public var cardSubtitle: String? { subtitle }
    public var cardDescription: String? { nil }
    public var cardIcon: String? { "doc.text" }
    // cardColor removed - configure via PresentationHints instead (Issue #142)
}

/// Extension to make GenericVehicle conform to CardDisplayable
extension GenericVehicle: CardDisplayable {
    public var cardTitle: String { name }
    public var cardSubtitle: String? { type.rawValue }
    public var cardDescription: String? { description }
    public var cardIcon: String? { 
        switch type {
        case .car: return "car.fill"
        case .truck: return "truck.box.fill"
        case .motorcycle: return "motorcycle.fill"
        case .boat: return "sailboat.fill"
        case .aircraft: return "airplane"
        case .other: return "questionmark.circle.fill"
        case .generic: return "star.fill"
        }
    }
    // cardColor removed - configure via PresentationHints instead (Issue #142)
    // Example: PresentationHints(itemColorProvider: { item in
    //     if let vehicle = item as? GenericVehicle {
    //         switch vehicle.type {
    //         case .car: return .blue
    //         case .truck: return .orange
    //         // ... etc
    //         }
    //     }
    //     return nil
    // })
}

/// Extension to make GenericMediaItem conform to CardDisplayable
extension GenericMediaItem: CardDisplayable {
    public var cardTitle: String { title }
    public var cardSubtitle: String? { mediaType.rawValue.capitalized }
    public var cardDescription: String? { description }
    public var cardIcon: String? { 
        switch mediaType {
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .audio: return "music.note"
        case .document: return "doc.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    // cardColor removed - configure via PresentationHints instead (Issue #142)
}

/// Extension to make GenericTemporalData conform to CardDisplayable
extension GenericTemporalData: CardDisplayable {
    public var cardTitle: String { title }
    public var cardSubtitle: String? { 
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    public var cardDescription: String? { description }
    public var cardIcon: String? { "calendar" }
    // cardColor removed - configure via PresentationHints instead (Issue #142)
}

/// Extension to make GenericHierarchicalData conform to CardDisplayable
extension GenericHierarchicalData: CardDisplayable {
    public var cardTitle: String { title }
    public var cardSubtitle: String? { nil }
    public var cardDescription: String? { nil }
    public var cardIcon: String? { "folder.fill" }
    // cardColor removed - configure via PresentationHints instead (Issue #142)
}
