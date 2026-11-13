//
//  FormDraftTypes.swift
//  SixLayerFramework
//
//  Form draft and auto-save functionality
//  Implements Issue #80: Form auto-save and draft functionality
//

import Foundation

// MARK: - Form Draft Model

/// Represents a draft of form state that can be saved and restored
public struct FormDraft: Codable, Equatable {
    /// Unique identifier for the form
    public let formId: String
    
    /// Field values stored in the draft
    public let fieldValues: [String: AnyCodable]
    
    /// Timestamp when the draft was created/updated
    public let timestamp: Date
    
    /// Optional metadata about the draft
    public let metadata: [String: String]?
    
    public init(
        formId: String,
        fieldValues: [String: Any],
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.formId = formId
        self.timestamp = timestamp
        self.metadata = metadata
        
        // Convert [String: Any] to [String: AnyCodable]
        var codableValues: [String: AnyCodable] = [:]
        for (key, value) in fieldValues {
            codableValues[key] = AnyCodable(value)
        }
        self.fieldValues = codableValues
    }
    
    /// Convert draft back to field values dictionary
    public func toFieldValues() -> [String: Any] {
        var values: [String: Any] = [:]
        for (key, codableValue) in fieldValues {
            values[key] = codableValue.value
        }
        return values
    }
}

// MARK: - AnyCodable Helper

/// Type-erased Codable wrapper for storing Any values in Codable structures.
///
/// Non-JSON form value types are stored as single-key tagged objects so round-trips restore
/// the original type rather than `String(describing:)` (#672 Date, #674 URL / Data / UUID).
/// Bare strings that look like those values stay `String`.
public struct AnyCodable: Codable, Equatable {
    public let value: Any

    /// Reserved keys for typed boxes in draft JSON. Not normal form field value shapes.
    static let dateTagKey = "__sixlayer_date__"
    static let urlTagKey = "__sixlayer_url__"
    static let dataTagKey = "__sixlayer_data__"
    static let uuidTagKey = "__sixlayer_uuid__"
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            if let tagged = Self.value(fromTaggedDictionary: dict) {
                value = tagged
            } else {
                value = dict.mapValues { $0.value }
            }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let date as Date:
            try container.encode([Self.dateTagKey: AnyCodable(Self.iso8601String(from: date))])
        case let url as URL:
            try container.encode([Self.urlTagKey: AnyCodable(url.absoluteString)])
        case let data as Data:
            try container.encode([Self.dataTagKey: AnyCodable(data.base64EncodedString())])
        case let uuid as UUID:
            try container.encode([Self.uuidTagKey: AnyCodable(uuid.uuidString)])
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            // For other types, encode as string representation
            try container.encode(String(describing: value))
        }
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        if let left = lhs.value as? Date, let right = rhs.value as? Date {
            return abs(left.timeIntervalSince1970 - right.timeIntervalSince1970) < 0.001
        }
        if let left = lhs.value as? URL, let right = rhs.value as? URL {
            return left == right
        }
        if let left = lhs.value as? Data, let right = rhs.value as? Data {
            return left == right
        }
        if let left = lhs.value as? UUID, let right = rhs.value as? UUID {
            return left == right
        }
        return String(describing: lhs.value) == String(describing: rhs.value)
    }

    private static func value(fromTaggedDictionary dict: [String: AnyCodable]) -> Any? {
        guard dict.count == 1, let (key, boxed) = dict.first else { return nil }
        guard let tagged = boxed.value as? String else { return nil }
        switch key {
        case dateTagKey:
            return DynamicFormStoredDateValue.date(fromStoredValue: tagged)
        case urlTagKey:
            return URL(string: tagged)
        case dataTagKey:
            return Data(base64Encoded: tagged)
        case uuidTagKey:
            return UUID(uuidString: tagged)
        default:
            return nil
        }
    }

    private static func iso8601String(from date: Date) -> String {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.string(from: date)
    }
}

// MARK: - Form State Storage Protocol

/// Protocol for storing and loading form drafts
public protocol FormStateStorage {
    /// Save a draft to storage
    /// - Parameter draft: The draft to save
    /// - Throws: Storage errors if save fails
    func saveDraft(_ draft: FormDraft) throws
    
    /// Load a draft from storage
    /// - Parameter formId: The form identifier
    /// - Returns: The draft if it exists, nil otherwise
    func loadDraft(formId: String) -> FormDraft?
    
    /// Clear a draft from storage
    /// - Parameter formId: The form identifier
    /// - Throws: Storage errors if clear fails
    func clearDraft(formId: String) throws
    
    /// Check if a draft exists for a form
    /// - Parameter formId: The form identifier
    /// - Returns: True if draft exists, false otherwise
    func hasDraft(formId: String) -> Bool
}
