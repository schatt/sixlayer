//
//  EntityCreationUtilities.swift
//  SixLayerFramework
//
//  Shared utilities for creating Core Data and SwiftData entities
//  Used by both IntelligentFormView and DynamicFormView
//

import Foundation
#if canImport(CoreData)
import CoreData
#endif
#if canImport(SwiftData)
import SwiftData
#endif

/// Shared utilities for entity creation
/// DRY: Centralizes entity creation logic used by both IntelligentFormView and DynamicFormView
@MainActor
public enum EntityCreationUtilities {

    #if canImport(CoreData)
    /// Creating the named Core Data entity failed before `setValue` could raise (#606, #613).
    public enum CoreDataCreationError: Error, Equatable, LocalizedError {
        case unavailable(entityName: String)
        case unknownProperty(entityName: String, key: String)
        case incompatibleValue(entityName: String, key: String)

        public var errorDescription: String? {
            switch self {
            case .unavailable(let entityName):
                return "Cannot create Core Data entity \"\(entityName)\". The model is not available in this context."
            case .unknownProperty(let entityName, let key):
                return "Cannot create Core Data entity \"\(entityName)\". \"\(key)\" is not a property of the model."
            case .incompatibleValue(let entityName, let key):
                return "Cannot create Core Data entity \"\(entityName)\". The value for \"\(key)\" cannot be stored."
            }
        }
    }
    #endif
    
    // MARK: - Core Data Entity Creation
    
    #if canImport(CoreData)
    /// Create a Core Data entity from a dictionary of values
    /// - Parameters:
    ///   - entityName: Name of the Core Data entity
    ///   - values: Dictionary of field names to values
    ///   - context: Managed object context to insert into
    ///   - fieldHints: Optional hints to filter hidden fields
    /// - Returns: Created NSManagedObject
    /// - Throws: `CoreDataCreationError` when the name, property, or value cannot be stored,
    ///   or the context save error (entity is rolled back on save failure)
    public static func createCoreDataEntity(
        entityName: String,
        values: [String: Any],
        context: NSManagedObjectContext,
        fieldHints: [String: FieldDisplayHints]? = nil
    ) throws -> NSManagedObject {
        guard let description = insertableEntity(named: entityName, in: context) else {
            throw CoreDataCreationError.unavailable(entityName: entityName)
        }

        var assignments: [(key: String, value: Any?)] = []
        for (fieldId, value) in values {
            if let hints = fieldHints, let hint = hints[fieldId], hint.isHidden {
                continue
            }
            let prepared = preparedValue(value, forKey: fieldId, on: description)
            if let rejection = assignmentRejection(
                value: prepared,
                key: fieldId,
                entityName: entityName,
                description: description
            ) {
                throw rejection
            }
            assignments.append((fieldId, prepared))
        }

        let entity = insert(description, assignments: assignments, into: context)
        
        // Save context - throw error if save fails (entity will be rolled back)
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            // Rollback: Delete entity if save fails
            context.delete(entity)
            // Reset context to discard changes
            context.rollback()
            throw error
        }
        
        return entity
    }
    
    /// Create a blank Core Data entity with defaults from hints
    /// - Parameters:
    ///   - entityName: Name of the Core Data entity
    ///   - context: Managed object context to insert into
    ///   - fields: Array of DataField from analysis
    ///   - fieldHints: Hints containing default values
    /// - Returns: Created NSManagedObject with defaults populated, or nil if creation failed
    public static func createBlankCoreDataEntity(
        entityName: String,
        context: NSManagedObjectContext,
        fields: [DataField],
        fieldHints: [String: FieldDisplayHints]
    ) -> NSManagedObject? {
        guard let description = insertableEntity(named: entityName, in: context) else {
            return nil
        }

        var assignments: [(key: String, value: Any?)] = []
        for field in fields {
            guard let hint = fieldHints[field.name], !hint.isHidden else { continue }
            let value: Any?
            if let defaultValue = hint.defaultValue {
                value = defaultValue
            } else if field.isOptional {
                value = nil
            } else {
                value = getDefaultValueForType(field.type)
            }
            let prepared = preparedValue(value, forKey: field.name, on: description)
            if assignmentRejection(
                value: prepared,
                key: field.name,
                entityName: entityName,
                description: description
            ) != nil {
                return nil
            }
            assignments.append((field.name, prepared))
        }

        let entity = insert(description, assignments: assignments, into: context)
        
        return entity
    }

    /// Description safe to insert, or nil when the context has no coordinator or the name
    /// is absent from the model. Name lookup raises if `persistentStoreCoordinator` is nil.
    private static func insertableEntity(
        named entityName: String,
        in context: NSManagedObjectContext
    ) -> NSEntityDescription? {
        guard context.persistentStoreCoordinator != nil else { return nil }
        return NSEntityDescription.entity(forEntityName: entityName, in: context)
    }

    private static func insert(
        _ description: NSEntityDescription,
        assignments: [(key: String, value: Any?)],
        into context: NSManagedObjectContext
    ) -> NSManagedObject {
        let entity = NSManagedObject(entity: description, insertInto: context)
        for assignment in assignments {
            entity.setValue(assignment.value, forKey: assignment.key)
        }
        return entity
    }

    /// Why this value cannot be assigned, or nil when `setValue` can take it.
    /// `setValue` raises for an unknown key and for a value the property cannot store.
    private static func assignmentRejection(
        value: Any?,
        key: String,
        entityName: String,
        description: NSEntityDescription
    ) -> CoreDataCreationError? {
        if let attribute = description.attributesByName[key] {
            return valueFits(value, attribute: attribute)
                ? nil
                : .incompatibleValue(entityName: entityName, key: key)
        }
        if let relationship = description.relationshipsByName[key] {
            return valueFits(value, relationship: relationship)
                ? nil
                : .incompatibleValue(entityName: entityName, key: key)
        }
        return .unknownProperty(entityName: entityName, key: key)
    }

    /// Form fields store numbers, booleans, and some dates as strings (#615).
    /// Convert those before the class check. The check itself still matches `setValue`.
    private static func preparedValue(
        _ value: Any?,
        forKey key: String,
        on description: NSEntityDescription
    ) -> Any? {
        guard let attribute = description.attributesByName[key] else { return value }
        return valueReadyToAssign(value, to: attribute)
    }

    private static func valueReadyToAssign(_ value: Any?, to attribute: NSAttributeDescription) -> Any? {
        guard let value else { return nil }
        if valueFits(value, attribute: attribute) { return value }
        switch attribute.attributeType {
        case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType:
            if let int = integerStored(in: value) { return int }
        case .doubleAttributeType, .floatAttributeType:
            if let double = doubleStored(in: value) { return double }
        case .decimalAttributeType:
            if let decimal = decimalStored(in: value) { return decimal }
        case .booleanAttributeType:
            if let bool = boolStored(in: value) { return bool }
        case .dateAttributeType:
            if let date = DynamicFormStoredDateValue.date(fromStoredValue: value) { return date }
        default:
            break
        }
        return value
    }

    /// `Int` text, or an integral decimal such as the stepper's `"4.0"`.
    /// A value that does not fit in `Int` stays unparsed. `Double` would round it
    /// and `Int(_:)` would trap or store a different number.
    private static func integerStored(in value: Any) -> Int? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let int = Int(trimmed) { return int }
        guard let decimal = entireDecimal(trimmed) else { return nil }
        let number = NSDecimalNumber(decimal: decimal)
        let int64 = number.int64Value
        guard NSDecimalNumber(value: int64) == number else { return nil }
        return Int(exactly: int64)
    }

    /// The whole string is one decimal. `Decimal(string:)` accepts a prefix (`"4abc"` → 4).
    private static func entireDecimal(_ text: String) -> Decimal? {
        let scanner = Scanner(string: text)
        scanner.locale = Locale(identifier: "en_US_POSIX")
        guard let decimal = scanner.scanDecimal(), scanner.isAtEnd else { return nil }
        return decimal
    }

    private static func doubleStored(in value: Any) -> Double? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let double = Double(trimmed), double.isFinite else { return nil }
        return double
    }

    private static func decimalStored(in value: Any) -> Decimal? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return entireDecimal(trimmed)
    }

    private static func boolStored(in value: Any) -> Bool? {
        guard let string = value as? String else { return nil }
        switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "true", "1": return true
        case "false", "0": return false
        default: return nil
        }
    }

    private static func valueFits(_ value: Any?, attribute: NSAttributeDescription) -> Bool {
        guard let value, !(value is NSNull) else { return true }
        let object = value as AnyObject
        switch attribute.attributeType {
        case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType,
             .decimalAttributeType, .doubleAttributeType, .floatAttributeType,
             .booleanAttributeType:
            return object is NSNumber
        case .stringAttributeType:
            return object is NSString
        case .dateAttributeType:
            return object is NSDate
        case .binaryDataAttributeType:
            return object is NSData
        case .UUIDAttributeType:
            return object is NSUUID
        case .URIAttributeType:
            return object is NSURL
        case .transformableAttributeType, .undefinedAttributeType,
             .objectIDAttributeType, .compositeAttributeType:
            // These store an object rather than one bridged class.
            return true
        @unknown default:
            return true
        }
    }

    private static func valueFits(_ value: Any?, relationship: NSRelationshipDescription) -> Bool {
        guard let value, !(value is NSNull) else { return true }
        let object = value as AnyObject
        if relationship.isToMany {
            return relationship.isOrdered ? object is NSOrderedSet : object is NSSet
        }
        return object is NSManagedObject
    }
    #endif
    
    // MARK: - SwiftData Entity Creation
    
    #if canImport(SwiftData)
    /// Create a SwiftData entity from a dictionary of values using Codable
    /// - Parameters:
    ///   - entityType: The SwiftData entity type (must conform to Decodable)
    ///   - values: Dictionary of field names to values
    ///   - context: Model context to insert into
    ///   - fieldHints: Optional hints to filter hidden fields
    /// - Returns: Created entity
    /// - Throws: Error if entity creation or save fails (entity is rolled back on error)
    @available(macOS 14.0, iOS 17.0, *)
    public static func createSwiftDataEntity(
        entityType: Any.Type,
        values: [String: Any],
        context: ModelContext,
        fieldHints: [String: FieldDisplayHints]? = nil
    ) throws -> Any {
        // Check if entityType conforms to Decodable
        guard let decodableType = entityType as? any Decodable.Type else {
            throw NSError(
                domain: "EntityCreationUtilities",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Entity type does not conform to Decodable"]
            )
        }
        
        // Filter out hidden fields
        var filteredValues = values
        if let hints = fieldHints {
            filteredValues = values.filter { fieldId, _ in
                guard let hint = hints[fieldId] else { return true }
                return !hint.isHidden
            }
        }
        
        // Encode values to JSON, then decode to entity type
        let jsonData: Data
        let decoded: Any
        
        do {
            jsonData = try JSONSerialization.data(withJSONObject: filteredValues)
            let decoder = JSONDecoder()
            decoded = try decoder.decode(decodableType, from: jsonData)
        } catch {
            throw NSError(
                domain: "EntityCreationUtilities",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to decode entity from form values: \(error.localizedDescription)",
                    NSUnderlyingErrorKey: error
                ]
            )
        }
        
        // Insert into context
        guard let persistentModel = decoded as? any PersistentModel else {
            throw NSError(
                domain: "EntityCreationUtilities",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Decoded entity does not conform to PersistentModel"]
            )
        }
        
        context.insert(persistentModel)
        
        // Save context - throw error if save fails (entity will be rolled back)
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            // Rollback: Delete entity if save fails
            context.delete(persistentModel)
            throw error
        }
        
        return decoded
    }
    
    /// Create a blank SwiftData entity with defaults from hints using Codable
    /// - Parameters:
    ///   - entityType: The SwiftData entity type (must conform to Decodable)
    ///   - context: Model context to insert into
    ///   - fields: Array of DataField from analysis
    ///   - fieldHints: Hints containing default values
    /// - Returns: Created entity with defaults populated, or nil if creation failed
    @available(macOS 14.0, iOS 17.0, *)
    public static func createBlankSwiftDataEntity(
        entityType: Any.Type,
        context: ModelContext,
        fields: [DataField],
        fieldHints: [String: FieldDisplayHints]
    ) -> Any? {
        // Check if entityType conforms to Decodable
        guard let decodableType = entityType as? any Decodable.Type else { return nil }
        
        // Build dictionary from hints defaults
        var values: [String: Any] = [:]
        for field in fields {
            guard let hint = fieldHints[field.name] else { continue }
            guard !hint.isHidden else { continue }
            
            if let defaultValue = hint.defaultValue {
                values[field.name] = defaultValue
            } else if field.isOptional {
                // Optional fields can be nil (represented as NSNull in JSON)
                values[field.name] = NSNull()
            } else {
                // Required fields without defaults - use type-based defaults
                values[field.name] = getDefaultValueForType(field.type)
            }
        }
        
        // Encode to JSON, then decode to T using type-erased Decodable
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: values)
            let decoder = JSONDecoder()
            
            // Use type-erased decoding: cast T.self to Decodable.Type, decode, then cast back
            let decoded = try decoder.decode(decodableType, from: jsonData)
            
            // Insert into context
            if let persistentModel = decoded as? any PersistentModel {
                context.insert(persistentModel)
            }
            
            return decoded
        } catch {
            // Codable failed
            print("Error creating SwiftData entity from hints: \(error.localizedDescription)")
            return nil
        }
    }
    #endif
    
    // MARK: - Helper Functions
    
    /// Get default value for a field type
    /// - Parameter fieldType: The field type to get default for
    /// - Returns: Default value for the type
    public static func getDefaultValueForType(_ fieldType: FieldType) -> Any {
        switch fieldType {
        case .string: return ""
        case .number: return 0
        case .boolean: return false
        case .date: return Date()
        case .url: return URL(string: "https://example.com") ?? URL(string: "https://example.com")!
        case .uuid: return UUID()
        case .image, .document: return ""
        case .relationship, .hierarchical, .custom: return ""
        }
    }
}
