#!/usr/bin/env swift

//
//  generate_hints_from_models.swift
//  SixLayer Framework
//
//  Build-time tool to generate/update .hints files from model files
//  Parses Swift source files and Core Data .xcdatamodel files to extract
//  type information and generate fully declarative hints
//

import Foundation

// MARK: - Model Parser

/// Parses Swift source files to extract struct/class property information
struct SwiftModelParser {
    /// Parse a Swift source file and extract field information
    /// Returns fields and the type name(s) this file defines or extends
    static func parseSwiftFile(at url: URL) -> (fields: [FieldInfo], definedTypes: [String], extendedTypes: [String])? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        
        // Simple regex-based parsing for struct/class properties
        // This is a basic implementation - could be enhanced with SwiftSyntax for better accuracy
        var fields: [FieldInfo] = []
        var definedTypes: [String] = []
        var extendedTypes: [String] = []
        
        // Pattern to match type definitions: struct/class/enum TypeName
        let typeDefinitionPattern = #"(?:struct|class|enum)\s+(\w+)"#
        let typeDefinitionRegex = try? NSRegularExpression(pattern: typeDefinitionPattern, options: [])
        
        // Pattern to match extension declarations: extension TypeName
        let extensionPattern = #"extension\s+(\w+)"#
        let extensionRegex = try? NSRegularExpression(pattern: extensionPattern, options: [])
        
        // Pattern to match property declarations: let/var name: Type? = defaultValue
        let propertyPattern = #"(?:let|var)\s+(\w+)\s*:\s*([\w\.\[\]?]+)(?:\s*=\s*([^\n]+))?"#
        let regex = try? NSRegularExpression(pattern: propertyPattern, options: [])
        
        let nsContent = content as NSString
        
        // Find type definitions (struct/class/enum)
        let typeMatches = typeDefinitionRegex?.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length)) ?? []
        for match in typeMatches {
            if match.numberOfRanges >= 2 {
                let typeNameRange = match.range(at: 1)
                if typeNameRange.location != NSNotFound {
                    let typeName = nsContent.substring(with: typeNameRange)
                    if !definedTypes.contains(typeName) {
                        definedTypes.append(typeName)
                    }
                }
            }
        }
        
        // Find extension declarations
        let extMatches = extensionRegex?.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length)) ?? []
        for match in extMatches {
            if match.numberOfRanges >= 2 {
                let typeNameRange = match.range(at: 1)
                if typeNameRange.location != NSNotFound {
                    let typeName = nsContent.substring(with: typeNameRange)
                    if !extendedTypes.contains(typeName) {
                        extendedTypes.append(typeName)
                    }
                }
            }
        }
        
        // Find property declarations
        let matches = regex?.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length)) ?? []
        
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            
            let nameRange = match.range(at: 1)
            let typeRange = match.range(at: 2)
            
            guard nameRange.location != NSNotFound,
                  typeRange.location != NSNotFound else { continue }
            
            // Check if this is a computed property (has { after type) vs stored property (has = or nothing)
            let matchEnd = match.range.location + match.range.length
            var isComputed = false
            if matchEnd < nsContent.length {
                // Look ahead to see what comes after the match
                let remainingContent = nsContent.substring(from: matchEnd)
                let trimmed = remainingContent.trimmingCharacters(in: .whitespacesAndNewlines)
                // If it starts with {, it's a computed property
                if trimmed.hasPrefix("{") {
                    isComputed = true
                }
            }
            
            let name = nsContent.substring(with: nameRange)
            var typeString = nsContent.substring(with: typeRange)
            
            // Determine optionality
            let isOptional = typeString.hasSuffix("?")
            if isOptional {
                typeString = String(typeString.dropLast())
            }
            
            // Determine if array
            let isArray = typeString.hasPrefix("Array<") || typeString.hasPrefix("[")
            
            // Map Swift types to fieldType strings
            let fieldType = mapSwiftTypeToFieldType(typeString)
            
            // Extract default value if present
            var defaultValue: (any Sendable)? = nil
            if match.numberOfRanges >= 4 {
                let defaultValueRange = match.range(at: 3)
                if defaultValueRange.location != NSNotFound {
                    let defaultValueString = nsContent.substring(with: defaultValueRange).trimmingCharacters(in: .whitespaces)
                    defaultValue = parseDefaultValue(from: defaultValueString, type: fieldType)
                }
            }
            
            // Determine if field should be hidden (default suggestion - can be overridden in .hints file)
            // Common patterns: cloudSyncId, syncId, internalId, _id, etc.
            // UUID fields are hidden by default
            let isHidden = shouldHideField(name: name, type: fieldType)
            
            // ID fields are non-editable by default (UUID type, exact "id", or contains "ID")
            // Users can override this in their .hints file by setting isEditable: true
            let isIDField = shouldBeNonEditableIDField(name: name, type: fieldType)
            
            // Computed properties and ID fields are not editable
            let isEditable = !isComputed && !isIDField
            
            fields.append(FieldInfo(
                name: name,
                fieldType: fieldType,
                isOptional: isOptional,
                isArray: isArray,
                defaultValue: defaultValue,
                isHidden: isHidden,
                isEditable: isEditable
            ))
        }
        
        return fields.isEmpty && definedTypes.isEmpty && extendedTypes.isEmpty ? nil : (fields, definedTypes, extendedTypes)
    }
    
    /// Parse a Swift source file and extract only field information (backward compatibility)
    static func parseSwiftFileFields(at url: URL) -> [FieldInfo]? {
        guard let result = parseSwiftFile(at: url) else { return nil }
        return result.fields.isEmpty ? nil : result.fields
    }
    
    /// Recursively find all Swift files in a directory and all subdirectories
    /// Searches through the entire directory tree, not just the top level
    static func findSwiftFiles(in directory: URL) -> [URL] {
        var swiftFiles: [URL] = []
        // Use enumerator with default options to recursively search all subdirectories
        // .skipsHiddenFiles only skips hidden files, not subdirectories
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles] // This does NOT skip subdirectories - search is recursive
        ) else {
            return swiftFiles
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                swiftFiles.append(fileURL)
            }
        }
        
        return swiftFiles
    }
    
    /// Find all Swift files that extend a given type name
    /// Recursively searches through all subdirectories in each search directory
    /// to find extension files that extend the specified type
    static func findExtensionFiles(for typeName: String, in searchDirs: [URL]) -> [URL] {
        var extensionFiles: [URL] = []
        
        for searchDir in searchDirs {
            guard FileManager.default.fileExists(atPath: searchDir.path) else { continue }
            
            // Recursively find all Swift files in this directory and all subdirectories
            let swiftFiles = findSwiftFiles(in: searchDir)
            
            // Parse each file to see if it extends the target type
            for file in swiftFiles {
                if let result = parseSwiftFile(at: file) {
                    // Check if this file extends the target type
                    if result.extendedTypes.contains(typeName) {
                        if !extensionFiles.contains(where: { $0.path == file.path }) {
                            extensionFiles.append(file)
                        }
                    }
                }
            }
        }
        
        return extensionFiles
    }
    
    /// Determine if a field should be hidden based on naming patterns and type
    /// Note: This is a default suggestion - users can override in their .hints file
    private static func shouldHideField(name: String, type: String) -> Bool {
        // UUID fields are hidden by default (they're system-managed identifiers)
        // Users can override this in their .hints file by setting isHidden: false
        if type == "uuid" {
            return true
        }
        
        let lowercased = name.lowercased()
        
        // Common patterns for internal/hidden fields
        let hiddenPatterns = [
            "cloudsyncid", "cloud_sync_id", "cloudSyncId",
            "syncid", "sync_id", "syncId",
            "internalid", "internal_id", "internalId",
            "_id", "_uuid", "_sync",
            "metadata", "internalmetadata",
            "systemid", "system_id", "systemId"
        ]
        
        // Check if field name matches any hidden pattern
        for pattern in hiddenPatterns {
            if lowercased.contains(pattern) {
                return true
            }
        }
        
        // Fields starting with underscore are typically internal
        if name.hasPrefix("_") {
            return true
        }
        
        return false
    }
    
    /// Determine if a field should be non-editable based on naming patterns and type
    /// ID fields (exact "id" or contains "ID") and UUID fields are non-editable by default
    /// Note: This is a default suggestion - users can override in their .hints file
    private static func shouldBeNonEditableIDField(name: String, type: String) -> Bool {
        // UUID fields are non-editable by default (they're system-managed identifiers)
        // Users can override this in their .hints file by setting isEditable: true
        if type == "uuid" {
            return true
        }
        
        // Check for exact "id" (case-insensitive)
        if name.lowercased() == "id" {
            return true
        }
        
        // Check if field name contains "ID" (uppercase) - like "calendarEventID", "cloudKitRecordID"
        // This avoids false positives like "widefield" matching "id"
        if name.contains("ID") {
            return true
        }
        
        return false
    }
    
    /// Map Swift type names to fieldType strings
    private static func mapSwiftTypeToFieldType(_ swiftType: String) -> String {
        // Remove generic parameters and array brackets
        let baseType = swiftType
            .replacingOccurrences(of: "Array<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        switch baseType.lowercased() {
        case "string", "string?":
            return "string"
        case "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64":
            return "number"
        case "double", "float", "cgfloat":
            return "number"
        case "bool", "boolean":
            return "boolean"
        case "date":
            return "date"
        case "url":
            return "url"
        case "uuid":
            return "uuid"
        case "data":
            return "document"
        default:
            // Check for image types
            if baseType.contains("Image") || baseType == "UIImage" || baseType == "NSImage" {
                return "image"
            }
            return "custom"
        }
    }
    
    /// Parse default value from string representation
    private static func parseDefaultValue(from string: String, type: String) -> (any Sendable)? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        
        switch type {
        case "string":
            // Remove quotes
            if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
                return String(trimmed.dropFirst().dropLast())
            }
            return trimmed
        case "number":
            if let intValue = Int(trimmed) {
                return intValue
            } else if let doubleValue = Double(trimmed) {
                return doubleValue
            }
            return nil
        case "boolean":
            if trimmed == "true" {
                return true
            } else if trimmed == "false" {
                return false
            }
            return nil
        default:
            return nil
        }
    }
}

/// Parses Core Data .xcdatamodel XML files
struct CoreDataModelParser {
    /// Parse a Core Data model file and extract entity/attribute information
    static func parseCoreDataModel(at url: URL) -> [EntityInfo]? {
        // .xcdatamodel is a directory containing contents.xml or contents (without extension)
        let contentsXMLURL = url.appendingPathComponent("contents.xml")
        let contentsURL = url.appendingPathComponent("contents")
        
        // Try contents.xml first, then contents (without extension)
        let actualContentsURL: URL
        if FileManager.default.fileExists(atPath: contentsXMLURL.path) {
            actualContentsURL = contentsXMLURL
        } else if FileManager.default.fileExists(atPath: contentsURL.path) {
            actualContentsURL = contentsURL
        } else {
            print("Error: Neither contents.xml nor contents found in: \(url.path)")
            print("   Model directory: \(url.path)")
            // List contents of the directory for debugging
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path) {
                print("   Directory contents: \(contents.joined(separator: ", "))")
            }
            return nil
        }
        
        guard let xmlData = try? Data(contentsOf: actualContentsURL) else {
            print("Error: Could not read contents file from: \(actualContentsURL.path)")
            return nil
        }
        
        guard let xmlString = String(data: xmlData, encoding: .utf8) else {
            print("Error: Could not decode contents file as UTF-8 from: \(actualContentsURL.path)")
            return nil
        }
        
        // Simple XML parsing (could use XMLParser for more robust parsing)
        var entities: [EntityInfo] = []
        
        // Pattern to match entity definitions
        let entityPattern = #"<entity\s+name="([^"]+)"[^>]*>"#
        let entityRegex = try? NSRegularExpression(pattern: entityPattern, options: [])
        
        let nsString = xmlString as NSString
        let entityMatches = entityRegex?.matches(in: xmlString, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        if entityMatches.isEmpty {
            print("Warning: No entities found in XML. XML length: \(xmlString.count) characters")
            // Print first 500 characters for debugging
            let preview = xmlString.count > 500 ? String(xmlString.prefix(500)) + "..." : xmlString
            print("   XML preview: \(preview)")
        }
        
        for entityMatch in entityMatches {
            guard entityMatch.numberOfRanges >= 2 else { continue }
            let nameRange = entityMatch.range(at: 1)
            guard nameRange.location != NSNotFound else { continue }
            
            let entityName = nsString.substring(with: nameRange)
            
            // Find attributes for this entity
            // Look for the closing </entity> tag
            let entityStart = entityMatch.range.location + entityMatch.range.length
            let entityEndPattern = "</entity>"
            let entityEndRegex = try? NSRegularExpression(pattern: entityEndPattern, options: [])
            let endMatches = entityEndRegex?.matches(in: xmlString, options: [], range: NSRange(location: entityStart, length: nsString.length - entityStart))
            
            let entityEnd = endMatches?.first?.range.location ?? xmlString.count
            let entityContent = nsString.substring(with: NSRange(location: entityStart, length: entityEnd - entityStart))
            
            // Parse attributes - use a simpler approach that finds all attribute tags
            var fields: [FieldInfo] = []
            // Pattern to match <attribute ... /> tags (handles multi-line and different attribute orders)
            let attributeTagPattern = #"<attribute\s+[^>]*?/>"#
            let attributeTagRegex = try? NSRegularExpression(pattern: attributeTagPattern, options: [.dotMatchesLineSeparators])
            let attributeTagMatches = attributeTagRegex?.matches(in: entityContent, options: [], range: NSRange(location: 0, length: entityContent.count)) ?? []
            
            for tagMatch in attributeTagMatches {
                let tagRange = tagMatch.range
                guard tagRange.location != NSNotFound else { continue }
                
                let attributeTag = (entityContent as NSString).substring(with: tagRange)
                
                // Extract name
                let namePattern = #"name="([^"]+)""#
                let nameRegex = try? NSRegularExpression(pattern: namePattern, options: [])
                guard let nameMatch = nameRegex?.firstMatch(in: attributeTag, options: [], range: NSRange(location: 0, length: attributeTag.count)),
                      nameMatch.numberOfRanges >= 2,
                      nameMatch.range(at: 1).location != NSNotFound else {
                    continue
                }
                let name = (attributeTag as NSString).substring(with: nameMatch.range(at: 1))
                
                // Extract attributeType
                let typePattern = #"attributeType="([^"]+)""#
                let typeRegex = try? NSRegularExpression(pattern: typePattern, options: [])
                guard let typeMatch = typeRegex?.firstMatch(in: attributeTag, options: [], range: NSRange(location: 0, length: attributeTag.count)),
                      typeMatch.numberOfRanges >= 2,
                      typeMatch.range(at: 1).location != NSNotFound else {
                    print("Warning: Could not find attributeType for attribute '\(name)' in entity '\(entityName)'")
                    continue
                }
                let attributeType = (attributeTag as NSString).substring(with: typeMatch.range(at: 1))
                
                // Extract optional flag (defaults to false if not present)
                var isOptional = false
                let optionalPattern = #"optional="([^"]+)""#
                let optionalRegex = try? NSRegularExpression(pattern: optionalPattern, options: [])
                if let optionalMatch = optionalRegex?.firstMatch(in: attributeTag, options: [], range: NSRange(location: 0, length: attributeTag.count)),
                   optionalMatch.numberOfRanges >= 2,
                   optionalMatch.range(at: 1).location != NSNotFound {
                    let optionalStr = (attributeTag as NSString).substring(with: optionalMatch.range(at: 1))
                    isOptional = optionalStr == "YES"
                }
                
                let fieldType = mapCoreDataAttributeType(attributeType)
                
                // Determine if field should be hidden (default suggestion - can be overridden in .hints file)
                // UUID fields are hidden by default
                let isHidden = shouldHideField(name: name, type: fieldType)
                
                // ID fields (UUID type or contains "ID") are non-editable by default (can be overridden in .hints file)
                let isIDField = shouldBeNonEditableIDField(name: name, type: fieldType)
                
                // Core Data attributes are stored, but ID fields should not be editable
                fields.append(FieldInfo(
                    name: name,
                    fieldType: fieldType,
                    isOptional: isOptional,
                    isArray: false, // Core Data attributes are not arrays (use relationships)
                    defaultValue: nil,
                    isHidden: isHidden,
                    isEditable: !isIDField
                ))
            }
            
            entities.append(EntityInfo(name: entityName, fields: fields))
        }
        
        return entities.isEmpty ? nil : entities
    }
    
    /// Determine if a field should be hidden based on naming patterns and type
    private static func shouldHideField(name: String, type: String) -> Bool {
        // UUID fields are hidden by default (they're system-managed identifiers)
        if type == "uuid" {
            return true
        }
        
        let lowercased = name.lowercased()
        
        // Common patterns for internal/hidden fields
        let hiddenPatterns = [
            "cloudsyncid", "cloud_sync_id", "cloudSyncId",
            "syncid", "sync_id", "syncId",
            "internalid", "internal_id", "internalId",
            "_id", "_uuid", "_sync",
            "metadata", "internalmetadata",
            "systemid", "system_id", "systemId"
        ]
        
        // Check if field name matches any hidden pattern
        for pattern in hiddenPatterns {
            if lowercased.contains(pattern) {
                return true
            }
        }
        
        // Fields starting with underscore are typically internal
        if name.hasPrefix("_") {
            return true
        }
        
        return false
    }
    
    /// Determine if a field should be non-editable based on naming patterns and type
    /// ID fields (exact "id" or contains "ID") and UUID fields are non-editable by default
    /// Note: This is a default suggestion - users can override in their .hints file
    private static func shouldBeNonEditableIDField(name: String, type: String) -> Bool {
        // UUID fields are non-editable by default (they're system-managed identifiers)
        // Users can override this in their .hints file by setting isEditable: true
        if type == "uuid" {
            return true
        }
        
        // Check for exact "id" (case-insensitive)
        if name.lowercased() == "id" {
            return true
        }
        
        // Check if field name contains "ID" (uppercase) - like "calendarEventID", "cloudKitRecordID"
        // This avoids false positives like "widefield" matching "id"
        if name.contains("ID") {
            return true
        }
        
        return false
    }
    
    /// Map Core Data attribute types to fieldType strings
    private static func mapCoreDataAttributeType(_ attributeType: String) -> String {
        switch attributeType {
        case "String":
            return "string"
        case "Integer 16", "Integer 32", "Integer 64", "Decimal", "Double", "Float":
            return "number"
        case "Boolean":
            return "boolean"
        case "Date":
            return "date"
        case "UUID":
            return "uuid"
        case "Binary", "Transformable":
            return "document"
        default:
            return "custom"
        }
    }
}

// MARK: - Data Structures

struct FieldInfo {
    let name: String
    let fieldType: String
    let isOptional: Bool
    let isArray: Bool
    let defaultValue: (any Sendable)?
    let isHidden: Bool  // Whether field should be hidden from forms
    let isEditable: Bool  // Whether field is editable (false for computed properties)
}

struct EntityInfo {
    let name: String
    let fields: [FieldInfo]
}

// MARK: - Hints Generator

/// Generates .hints JSON files from parsed model information
struct HintsGenerator {
    /// Generate hints file content from field information
    /// Returns both the hints dictionary and the field order (to preserve custom ordering)
    /// For existing fields, preserves all properties exactly as they are
    /// Only adds type information if missing (for fully declarative hints)
    /// Preserves _sections if they exist, or creates a default section if none exist
    static func generateHintsJSON(
        fields: [FieldInfo], 
        existingHints: [String: Any]? = nil
    ) -> (hints: [String: Any], fieldOrder: [String]) {
        let hints: [String: Any] = existingHints ?? [:]
        var fieldOrder: [String] = []
        
        // Extract field hints (everything except _sections and __example)
        var fieldHints: [String: [String: Any]] = [:]
        var existingSections: [[String: Any]]? = nil
        
        for (key, value) in hints {
            if key == "_sections" {
                if let sections = value as? [[String: Any]] {
                    existingSections = sections
                }
            } else if key != "__example" {
                if let fieldDict = value as? [String: Any] {
                    fieldHints[key] = fieldDict
                }
            }
        }
        
        // Preserve order from existing field hints first
        fieldOrder = Array(fieldHints.keys)
        
        // Process fields from model (in source order)
        // Skip __example field if it exists (it's documentation only)
        for field in fields {
            // Skip __example - it's a documentation field, not a real model field
            if field.name == "__example" {
                continue
            }
            
            let existingFieldHints = fieldHints[field.name]
            var fieldHintsDict: [String: Any] = existingFieldHints ?? [:]
            
            // Always include type information (core fields for fully declarative hints)
            // Only override if not already present in existing hints
            if fieldHintsDict["fieldType"] == nil {
                fieldHintsDict["fieldType"] = field.fieldType
            }
            if fieldHintsDict["isOptional"] == nil {
                fieldHintsDict["isOptional"] = field.isOptional
            }
            if fieldHintsDict["isArray"] == nil {
                fieldHintsDict["isArray"] = field.isArray
            }
            if field.defaultValue != nil && fieldHintsDict["defaultValue"] == nil {
                fieldHintsDict["defaultValue"] = field.defaultValue
            }
            // Add isHidden (only if not already present, to allow manual override)
            // Users can manually set isHidden: false to show fields that would normally be hidden
            // (e.g., to show UUID fields or ID fields if needed)
            if fieldHintsDict["isHidden"] == nil {
                fieldHintsDict["isHidden"] = field.isHidden
            }
            // Add isEditable (only if not already present, to allow manual override)
            // Users can manually set isEditable: true to make fields editable that would normally be read-only
            // (e.g., UUID fields, ID fields, or computed properties)
            if fieldHintsDict["isEditable"] == nil {
                fieldHintsDict["isEditable"] = field.isEditable
            }
            
            // For existing fields: don't add any properties that weren't already there
            // This preserves developer's choice to remove properties
            // New fields get minimal type info only - see __example for all options
            
            fieldHints[field.name] = fieldHintsDict
            
            // Add to order if not already present (new fields go at end)
            if !fieldOrder.contains(field.name) {
                fieldOrder.append(field.name)
            }
        }
        
        // Build final hints dictionary with field hints
        var finalHints: [String: Any] = fieldHints
        
        // Handle sections: preserve existing or create default
        let allFieldNames = fieldOrder.filter { $0 != "__example" }
        if let existingSections = existingSections {
            // Preserve existing sections (even if empty - user may have intentionally removed all sections)
            finalHints["_sections"] = existingSections
        } else {
            // Create default section with all fields if no sections exist
            if !allFieldNames.isEmpty {
                finalHints["_sections"] = [[
                    "id": "default",
                    "title": "Form Fields",
                    "fields": allFieldNames
                ]]
            }
        }
        
        return (finalHints, fieldOrder)
    }
    
    /// Write hints to a .hints file
    /// Preserves field order from existing hints, then appends new fields
    /// Writes _sections after all fields but before __example
    /// Note: JSONSerialization doesn't guarantee order, so we manually construct JSON
    static func writeHints(_ hints: [String: Any], to url: URL, preserveOrder: [String]? = nil) throws {
        // Build JSON string manually to preserve order
        var jsonLines: [String] = ["{"]
        
        // Separate fields, _defaults, _sections, and __example
        let fieldOrder = preserveOrder ?? Array(hints.keys).sorted()
        var fieldsToWrite: [String] = []
        // Check if _sections and _defaults exist in hints (not just in fieldOrder, since they're excluded from fieldOrder)
        let hasSections = hints["_sections"] != nil
        let hasDefaults = hints["_defaults"] != nil
        var hasExample = false
        
        for key in fieldOrder {
            if key == "__example" {
                hasExample = true
            } else if key != "_sections" && key != "_defaults" {
                // _sections and _defaults are handled separately, don't add them to fieldsToWrite
                fieldsToWrite.append(key)
            }
        }
        
        var isFirst = true
        
        // Write all field definitions first
        for fieldName in fieldsToWrite {
            guard let fieldHints = hints[fieldName] as? [String: Any] else { continue }
            
            if !isFirst {
                jsonLines[jsonLines.count - 1] += ","
            }
            isFirst = false
            
            // Field name
            jsonLines.append("  \"\(fieldName)\": {")
            
            // Field properties (sorted for consistency within each field)
            let sortedKeys = fieldHints.keys.sorted()
            var isFirstProp = true
            for key in sortedKeys {
                guard let value = fieldHints[key] else { continue }
                
                if !isFirstProp {
                    jsonLines[jsonLines.count - 1] += ","
                }
                isFirstProp = false
                
                // Format value based on type
                let valueString: String
                if value is NSNull {
                    valueString = "null"
                } else if let stringValue = value as? String {
                    // Escape quotes in strings
                    let escaped = stringValue.replacingOccurrences(of: "\"", with: "\\\"")
                    valueString = "\"\(escaped)\""
                } else if let boolValue = value as? Bool {
                    valueString = boolValue ? "true" : "false"
                } else if let numberValue = value as? NSNumber {
                    valueString = "\(numberValue)"
                } else if let arrayValue = value as? [Any] {
                    // Handle arrays explicitly to avoid escaping forward slashes
                    let items = arrayValue.map { item -> String in
                        if item is NSNull {
                            return "null"
                        } else if let stringItem = item as? String {
                            // Only escape quotes, not forward slashes
                            let escaped = stringItem.replacingOccurrences(of: "\"", with: "\\\"")
                            return "\"\(escaped)\""
                        } else if let boolItem = item as? Bool {
                            return boolItem ? "true" : "false"
                        } else if let numberItem = item as? NSNumber {
                            return "\(numberItem)"
                        } else {
                            // For complex array items, use JSONSerialization but unescape forward slashes
                            if let jsonData = try? JSONSerialization.data(withJSONObject: item, options: []),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                // Unescape forward slashes (\/ -> /)
                                return jsonString.replacingOccurrences(of: "\\/", with: "/")
                            }
                            return "null"
                        }
                    }
                    valueString = "[\(items.joined(separator: ", "))]"
                } else if let dictValue = value as? [String: Any] {
                    // Handle dictionaries (like metadata: {})
                    if dictValue.isEmpty {
                        valueString = "{}"
                    } else {
                        // Use JSONSerialization but unescape forward slashes
                        if let jsonData = try? JSONSerialization.data(withJSONObject: dictValue, options: []),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            // Unescape forward slashes (\/ -> /)
                            valueString = jsonString.replacingOccurrences(of: "\\/", with: "/")
                        } else {
                            valueString = "{}"
                        }
                    }
                } else {
                    // Fallback: use JSONSerialization for complex types, but unescape forward slashes
                    if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: []),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        // Unescape forward slashes (\/ -> /)
                        valueString = jsonString.replacingOccurrences(of: "\\/", with: "/")
                    } else {
                        valueString = "null"
                    }
                }
                
                jsonLines.append("    \"\(key)\": \(valueString)")
            }
            
            jsonLines.append("  }")
        }
        
        // Write _defaults after fields but before _sections
        if hasDefaults, let defaults = hints["_defaults"] as? [String: Any] {
            if !isFirst {
                jsonLines[jsonLines.count - 1] += ","
            }
            isFirst = false
            
            jsonLines.append("  \"_defaults\": {")
            
            var defaultsProps: [String] = []
            if let defaultColor = defaults["_defaultColor"] {
                defaultsProps.append("\"_defaultColor\": \(formatJSONValue(defaultColor))")
            }
            if let colorMapping = defaults["_colorMapping"] {
                defaultsProps.append("\"_colorMapping\": \(formatJSONValue(colorMapping))")
            }
            
            for (index, prop) in defaultsProps.enumerated() {
                if index > 0 {
                    jsonLines[jsonLines.count - 1] += ","
                }
                jsonLines.append("    \(prop)")
            }
            
            jsonLines.append("  }")
        }
        
        // Write _sections after _defaults but before __example
        if hasSections, let sections = hints["_sections"] {
            if !isFirst {
                jsonLines[jsonLines.count - 1] += ","
            }
            isFirst = false
            
            jsonLines.append("  \"_sections\": [")
            
            if let sectionsArray = sections as? [[String: Any]] {
                var isFirstSection = true
                for section in sectionsArray {
                    if !isFirstSection {
                        jsonLines[jsonLines.count - 1] += ","
                    }
                    isFirstSection = false
                    
                    jsonLines.append("    {")
                    
                    // Write section properties in a consistent order
                    var sectionProps: [String] = []
                    if let id = section["id"] { sectionProps.append("\"id\": \(formatJSONValue(id))") }
                    if let title = section["title"] { sectionProps.append("\"title\": \(formatJSONValue(title))") }
                    if let description = section["description"] { sectionProps.append("\"description\": \(formatJSONValue(description))") }
                    if let fields = section["fields"] { sectionProps.append("\"fields\": \(formatJSONValue(fields))") }
                    if let layoutStyle = section["layoutStyle"] { sectionProps.append("\"layoutStyle\": \(formatJSONValue(layoutStyle))") }
                    if let isCollapsible = section["isCollapsible"] { sectionProps.append("\"isCollapsible\": \(formatJSONValue(isCollapsible))") }
                    if let isCollapsed = section["isCollapsed"] { sectionProps.append("\"isCollapsed\": \(formatJSONValue(isCollapsed))") }
                    
                    // Add any other properties
                    for (key, value) in section {
                        if !["id", "title", "description", "fields", "layoutStyle", "isCollapsible", "isCollapsed"].contains(key) {
                            sectionProps.append("\"\(key)\": \(formatJSONValue(value))")
                        }
                    }
                    
                    for (index, prop) in sectionProps.enumerated() {
                        if index > 0 {
                            jsonLines[jsonLines.count - 1] += ","
                        }
                        jsonLines.append("      \(prop)")
                    }
                    
                    jsonLines.append("    }")
                }
            }
            
            jsonLines.append("  ]")
        }
        
        // Write __example last
        if hasExample, let example = hints["__example"] as? [String: Any] {
            if !isFirst {
                jsonLines[jsonLines.count - 1] += ","
            }
            
            jsonLines.append("  \"__example\": {")
            
            let sortedKeys = example.keys.sorted()
            var isFirstProp = true
            for key in sortedKeys {
                guard let value = example[key] else { continue }
                
                if !isFirstProp {
                    jsonLines[jsonLines.count - 1] += ","
                }
                isFirstProp = false
                
                jsonLines.append("    \"\(key)\": \(formatJSONValue(value))")
            }
            
            jsonLines.append("  }")
        }
        
        jsonLines.append("}")
        
        // Join with proper spacing
        let jsonString = jsonLines.joined(separator: "\n")
        let data = jsonString.data(using: .utf8)!
        try data.write(to: url)
    }
    
    /// Helper to format JSON values consistently
    private static func formatJSONValue(_ value: Any) -> String {
        if value is NSNull {
            return "null"
        } else if let stringValue = value as? String {
            let escaped = stringValue.replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        } else if let boolValue = value as? Bool {
            return boolValue ? "true" : "false"
        } else if let numberValue = value as? NSNumber {
            return "\(numberValue)"
        } else if let arrayValue = value as? [Any] {
            // Handle arrays explicitly to avoid escaping forward slashes
            let items = arrayValue.map { item -> String in
                if item is NSNull {
                    return "null"
                } else if let stringItem = item as? String {
                    // Only escape quotes, not forward slashes
                    let escaped = stringItem.replacingOccurrences(of: "\"", with: "\\\"")
                    return "\"\(escaped)\""
                } else if let boolItem = item as? Bool {
                    return boolItem ? "true" : "false"
                } else if let numberItem = item as? NSNumber {
                    return "\(numberItem)"
                } else {
                    // For complex array items, use JSONSerialization but unescape forward slashes
                    if let jsonData = try? JSONSerialization.data(withJSONObject: item, options: []),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        // Unescape forward slashes (\/ -> /)
                        return jsonString.replacingOccurrences(of: "\\/", with: "/")
                    }
                    return "null"
                }
            }
            return "[\(items.joined(separator: ", "))]"
        } else if let dictValue = value as? [String: Any] {
            if dictValue.isEmpty {
                return "{}"
            } else {
                // Use JSONSerialization but unescape forward slashes
                if let jsonData = try? JSONSerialization.data(withJSONObject: dictValue, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    // Unescape forward slashes (\/ -> /)
                    return jsonString.replacingOccurrences(of: "\\/", with: "/")
                } else {
                    return "{}"
                }
            }
        } else {
            // Fallback: use JSONSerialization but unescape forward slashes
            if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                // Unescape forward slashes (\/ -> /)
                return jsonString.replacingOccurrences(of: "\\/", with: "/")
            } else {
                return "null"
            }
        }
    }
}

// MARK: - Command Line Argument Parsing

struct Arguments {
    var modelPath: String?
    var modeldPath: String?
    var extensionsDir: [String] = []
    var outputDir: String = "Hints"
    
    static func parse() -> Arguments? {
        var args = Arguments()
        let arguments = CommandLine.arguments
        var i = 1
        
        while i < arguments.count {
            let arg = arguments[i]
            
            switch arg {
            case "-model":
                guard i + 1 < arguments.count else {
                    print("Error: -model requires a file path")
                    return nil
                }
                args.modelPath = arguments[i + 1]
                i += 2
                
            case "-modeld":
                guard i + 1 < arguments.count else {
                    print("Error: -modeld requires a Core Data model path")
                    return nil
                }
                args.modeldPath = arguments[i + 1]
                i += 2
                
            case "-extensionsdir":
                guard i + 1 < arguments.count else {
                    print("Error: -extensionsdir requires a directory path")
                    return nil
                }
                args.extensionsDir.append(arguments[i + 1])
                i += 2
                
            case "-outputdir":
                guard i + 1 < arguments.count else {
                    print("Error: -outputdir requires a directory path")
                    return nil
                }
                args.outputDir = arguments[i + 1]
                i += 2
                
            case "-h", "-help", "--help":
                printUsage()
                exit(0)
                
            default:
                print("Error: Unknown argument: \(arg)")
                printUsage()
                return nil
            }
        }
        
        return args
    }
    
    static func printUsage() {
        print("Usage: generate_hints_from_models.swift -model <swift_file> | -modeld <xcdatamodel|xcdatamodeld> [options]")
        print("")
        print("Options:")
        print("  -model <path>          Swift .swift file to process")
        print("  -modeld <path>         Core Data .xcdatamodel directory or .xcdatamodeld bundle to process")
        print("  -extensionsdir <path>  Additional directory to recursively search for extension files")
        print("                         (defaults to model's directory and parent directory)")
        print("                         Can be specified multiple times to search additional directories")
        print("  -outputdir <path>      Output directory for .hints files (defaults to ./Hints)")
        print("  -h, -help, --help      Show this help message")
        print("")
        print("Examples:")
        print("  # Swift model with extensions in same directory")
        print("  ./scripts/generate_hints_from_models.swift -model Models/User.swift")
        print("")
        print("  # Swift model (automatically searches model's directory and subdirectories)")
        print("  ./scripts/generate_hints_from_models.swift -model Models/User.swift")
        print("")
        print("  # Swift model with extensions in additional directory")
        print("  ./scripts/generate_hints_from_models.swift -model Models/User.swift -extensionsdir Extensions/")
        print("")
        print("  # Core Data model (automatically searches model's directory and subdirectories)")
        print("  ./scripts/generate_hints_from_models.swift -modeld Shared/Models/MyModel.xcdatamodeld")
        print("")
        print("  # Core Data model with extensions in additional directory")
        print("  ./scripts/generate_hints_from_models.swift -modeld MyModel.xcdatamodel -extensionsdir Extensions/")
        print("")
        print("  # Core Data model bundle (.xcdatamodeld)")
        print("  ./scripts/generate_hints_from_models.swift -modeld MyModel.xcdatamodeld -extensionsdir Extensions/")
        print("")
        print("  # Custom output directory")
        print("  ./scripts/generate_hints_from_models.swift -model Models/User.swift -outputdir Generated/Hints/")
    }
}

// MARK: - Main

func main() {
    guard let args = Arguments.parse() else {
        exit(1)
    }
    
    // Validate that exactly one of -model or -modeld is provided
    guard (args.modelPath != nil) != (args.modeldPath != nil) else {
        print("Error: Must specify exactly one of -model or -modeld")
        Arguments.printUsage()
        exit(1)
    }
    
    let modelURL: URL
    if let modelPath = args.modelPath {
        modelURL = URL(fileURLWithPath: modelPath)
    } else {
        modelURL = URL(fileURLWithPath: args.modeldPath!)
    }
    
    guard FileManager.default.fileExists(atPath: modelURL.path) else {
        print("Error: Model file not found: \(modelURL.path)")
        exit(1)
    }
    
    // Determine output directory (defaults to ./Hints in current directory)
    // If relative path, make it relative to current working directory
    let outputDir: URL
    if args.outputDir.hasPrefix("/") {
        outputDir = URL(fileURLWithPath: args.outputDir)
    } else {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        outputDir = currentDir.appendingPathComponent(args.outputDir)
    }
    let extensionSearchPaths = args.extensionsDir.map { URL(fileURLWithPath: $0) }
    
    // Ensure output directory exists
    try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    
    // Parse model file and generate hints
    if modelURL.pathExtension == "swift" {
        // Swift file: may have extensions in separate files
        // Find all related files (main file + extension files like ModelName+*.swift)
        let modelName = modelURL.deletingPathExtension().lastPathComponent
        let modelDir = modelURL.deletingLastPathComponent()
        
        // Find all Swift files that might contain this model or its extensions
        var swiftFiles: [URL] = [modelURL] // Start with the main file
        
        // First, parse the main file to get the actual type name(s) it defines
        var actualTypeNames: [String] = [modelName] // Fallback to filename
        if let mainFileResult = SwiftModelParser.parseSwiftFile(at: modelURL) {
            if !mainFileResult.definedTypes.isEmpty {
                actualTypeNames = mainFileResult.definedTypes
            }
        }
        
        // Search directories for extension files that extend any of the type names
        var searchDirs = [modelDir] // Start with same directory as main file
        searchDirs.append(contentsOf: extensionSearchPaths) // Add any provided search paths
        
        // Find extension files by parsing Swift files and matching extension declarations
        for typeName in actualTypeNames {
            let extensionFiles = SwiftModelParser.findExtensionFiles(for: typeName, in: searchDirs)
            for extFile in extensionFiles {
                if !swiftFiles.contains(where: { $0.path == extFile.path }) {
                    swiftFiles.append(extFile)
                }
            }
        }
        
        // Parse all related files and combine fields
        var allFields: [FieldInfo] = []
        for file in swiftFiles {
            if let result = SwiftModelParser.parseSwiftFile(at: file) {
                allFields.append(contentsOf: result.fields)
            }
        }
        
        guard !allFields.isEmpty else {
            print("Error: Could not parse Swift file(s) or no fields found")
            if swiftFiles.count > 1 {
                print("   Searched files: \(swiftFiles.map { $0.lastPathComponent }.joined(separator: ", "))")
            }
            exit(1)
        }
        
        let outputURL = outputDir.appendingPathComponent("\(modelName).hints")
        
        generateHintsFile(for: allFields, outputURL: outputURL)
        print("✅ Generated hints file: \(outputURL.path)")
        print("   Found \(allFields.count) fields")
        if swiftFiles.count > 1 {
            print("   Processed \(swiftFiles.count) file(s): \(swiftFiles.map { $0.lastPathComponent }.joined(separator: ", "))")
        }
        
    } else if modelURL.pathExtension == "xcdatamodel" || modelURL.lastPathComponent.hasSuffix(".xcdatamodel") {
        // Core Data model: multiple entities, generate/update one hints file per entity
        processCoreDataModel(at: modelURL, outputDir: outputDir, extensionSearchPaths: extensionSearchPaths)
        
    } else if modelURL.pathExtension == "xcdatamodeld" || modelURL.lastPathComponent.hasSuffix(".xcdatamodeld") {
        // Core Data model bundle: contains one or more .xcdatamodel directories
        // Find the current model version from .xccurrentversion (if multiple versions exist)
        
        // Enumerate all .xcdatamodel directories within the bundle
        var modelDirectories: [URL] = []
        
        guard let enumerator = FileManager.default.enumerator(
            at: modelURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("Error: Could not enumerate contents of .xcdatamodeld bundle: \(modelURL.path)")
            exit(1)
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "xcdatamodel" || fileURL.lastPathComponent.hasSuffix(".xcdatamodel") {
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    modelDirectories.append(fileURL)
                }
            }
        }
        
        if modelDirectories.isEmpty {
            print("Error: No .xcdatamodel directories found in .xcdatamodeld bundle: \(modelURL.path)")
            exit(1)
        }
        
        // If only one version exists, use it directly (no .xccurrentversion needed)
        let modelToProcess: URL
        if modelDirectories.count == 1 {
            modelToProcess = modelDirectories[0]
            print("Processing model version: \(modelToProcess.deletingPathExtension().lastPathComponent)")
        } else {
            // Multiple versions exist - read .xccurrentversion to find current version
            let currentVersionURL = modelURL.appendingPathComponent(".xccurrentversion")
            var currentVersionName: String? = nil
            
            if FileManager.default.fileExists(atPath: currentVersionURL.path),
               let plistData = try? Data(contentsOf: currentVersionURL),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                // Try different possible keys for the current version name
                if let versionName = plist["_XCCurrentVersionName"] as? String {
                    currentVersionName = versionName
                } else if let versionName = plist["NSManagedObjectModel_CurrentVersionName"] as? String {
                    currentVersionName = versionName
                } else if let versionName = plist["currentVersion"] as? String {
                    currentVersionName = versionName
                }
            }
            
            // Find the current model directory
            var currentModelDirectory: URL? = nil
            for modelDir in modelDirectories {
                let modelName = modelDir.deletingPathExtension().lastPathComponent
                if let currentVersion = currentVersionName, modelName == currentVersion {
                    currentModelDirectory = modelDir
                    break
                }
            }
            
            // Use current version if found, otherwise use the first one with a warning
            if let current = currentModelDirectory {
                modelToProcess = current
                if let versionName = currentVersionName {
                    print("Processing current model version: \(versionName)")
                }
            } else {
                if let versionName = currentVersionName {
                    print("Warning: Current version '\(versionName)' not found in bundle. Found versions: \(modelDirectories.map { $0.deletingPathExtension().lastPathComponent }.joined(separator: ", "))")
                } else {
                    print("Warning: Could not determine current version from .xccurrentversion. Found versions: \(modelDirectories.map { $0.deletingPathExtension().lastPathComponent }.joined(separator: ", "))")
                }
                print("Processing first available version: \(modelDirectories[0].deletingPathExtension().lastPathComponent)")
                modelToProcess = modelDirectories[0]
            }
        }
        
        processCoreDataModel(at: modelToProcess, outputDir: outputDir, extensionSearchPaths: extensionSearchPaths)
        
    } else {
        print("Error: Unsupported model file type. Supported: .swift, .xcdatamodel, .xcdatamodeld")
        exit(1)
    }
}

/// Generate or update a hints file for a set of fields
/// Preserves existing hints properties and field order
func generateHintsFile(for fields: [FieldInfo], outputURL: URL) {
    // Ensure output directory exists
    let outputDir = outputURL.deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    // Load existing hints if they exist, preserving field order and sections
    var existingHints: [String: Any]? = nil
    var existingFieldOrder: [String] = []
    
    if FileManager.default.fileExists(atPath: outputURL.path),
       let data = try? Data(contentsOf: outputURL),
       let jsonString = String(data: data, encoding: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        existingHints = json
        
        // Extract field order from JSON string (fields appear in order in JSON)
        // Simple regex to find field names in order: "fieldName": {
        let fieldPattern = #""([^"]+)":\s*\{"#
        let regex = try? NSRegularExpression(pattern: fieldPattern, options: [])
        let nsString = jsonString as NSString
        let matches = regex?.matches(in: jsonString, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        for match in matches {
            if match.numberOfRanges >= 2 {
                let fieldNameRange = match.range(at: 1)
                if fieldNameRange.location != NSNotFound {
                    let fieldName = nsString.substring(with: fieldNameRange)
                    // Skip __example, _sections, and _defaults when tracking order
                    if fieldName != "__example" && fieldName != "_sections" && 
                       fieldName != "_defaults" &&
                       !existingFieldOrder.contains(fieldName) {
                        existingFieldOrder.append(fieldName)
                    }
                }
            }
        }
        
        // Preserve color configuration if it exists (nested under _defaults)
        if let defaults = json["_defaults"] as? [String: Any] {
            existingHints?["_defaults"] = defaults
        }
    }
    
    // Generate hints (returns both hints and field order)
    let (hints, newFieldOrder) = HintsGenerator.generateHintsJSON(
        fields: fields, 
        existingHints: existingHints
    )
    
    // Restore preserved color configuration (if it was in existing hints)
    var finalHints = hints
    var hasColorConfig = false
    if let existing = existingHints, let defaults = existing["_defaults"] as? [String: Any] {
        finalHints["_defaults"] = defaults
        hasColorConfig = true
    }
    
    // Add example color configuration if none exists (to help developers discover the feature)
    // Since JSON doesn't support comments, we add it as actual JSON with example values
    // Developers can modify these values or remove the lines if not needed
    if !hasColorConfig {
        finalHints["_defaults"] = [
            "_defaultColor": "blue",  // Example: change to "red", "#FF0000", or remove
            "_colorMapping": [
                "Vehicle": "blue",  // Example: map Vehicle type to blue
                "Task": "green"     // Example: map Task type to green
            ] as [String: String]
        ] as [String: Any]
    }
    
    // Add/update __example field with complete hints file structure
    // This serves as a complete template that developers can copy
    // To use: copy the contents of __example, remove the "__example": wrapper and outer braces,
    // and you have a complete, valid hints file structure
    // The structure inside __example mirrors the top-level structure of a hints file
    finalHints["__example"] = [
        // Example field definition (shows all field-level properties)
        // In a real hints file, you'd have actual field names like "username", "email", etc.
        "__examplefield": [
            "fieldType": "string",  // string, number, boolean, date, url, uuid, document, image, custom
            "isOptional": false,
            "isArray": false,
            "defaultValue": NSNull(),  // Can be String, Int, Bool, Double, etc.
            "isHidden": false,
            "isEditable": true,  // false for computed/read-only fields
            "expectedLength": NSNull(),  // Int or null
            "displayWidth": NSNull(),  // "narrow", "medium", "wide", or numeric value
            "showCharacterCounter": false,
            "maxLength": NSNull(),  // Int or null
            "minLength": NSNull(),  // Int or null
            "expectedRange": NSNull(),  // {"min": 0.0, "max": 100.0} or null
            "metadata": [:],  // Dictionary of string key-value pairs
            "ocrHints": NSNull(),  // ["keyword1", "keyword2"] or null
            "calculationGroups": NSNull(),  // [{"id": "...", "formula": "...", ...}] or null
            "inputType": NSNull(),  // "picker", "text", etc. or null
            "pickerOptions": NSNull()  // [{"value": "...", "label": "..."}] or null
        ],
        // Top-level sections configuration (copy to root level to activate)
        // This shows how to organize fields into sections
        "_sections": [
            [
                "id": "default",
                "title": "Form Fields",
                "description": NSNull(),  // Optional section description
                "fields": ["__examplefield", "anotherField"],  // Array of field names in this section
                "layoutStyle": NSNull(),  // Optional layout style
                "isCollapsible": false,  // Whether section can be collapsed
                "isCollapsed": false  // Whether section starts collapsed
            ]
        ],
        // Presentation defaults (this is the actual structure used in hints files)
        // Color configuration is nested under _defaults for logical grouping
        "_defaults": [
            // Default color for card presentation (named color or hex like "#FF0000")
            "_defaultColor": "blue",
            // Type-based color mapping: use your Swift type name (struct/class/enum)
            // as a string (e.g., "Vehicle", "Task", "User"). This is the Swift type
            // name, not the Core Data entity name (though they often match).
            // Value is color string: named color (e.g., "blue") or hex (e.g., "#FF0000")
            // Note: Currently parsed but not automatically converted to ObjectIdentifier mapping.
            // Use colorMapping parameter in PresentationHints for ObjectIdentifier-based mapping.
            "_colorMapping": [
                "Vehicle": "blue",
                "Task": "green"
            ]
        ]
    ] as [String: Any]
    
    // Use existing field order if available, otherwise use new order
    // Always ensure __example is at the end
    let finalFieldOrder: [String] = {
        var merged: [String]
        if existingFieldOrder.isEmpty {
            // New file: use new order
            merged = newFieldOrder
        } else {
            // Existing file: merge existing order with new fields
            merged = existingFieldOrder
            for fieldName in newFieldOrder {
                if !merged.contains(fieldName) {
                    merged.append(fieldName)
                }
            }
        }
        // Always move __example to the end (remove if present, then append)
        merged.removeAll { $0 == "__example" }
        merged.append("__example")
        return merged
    }()
    
    // Write hints file (preserving field order)
    do {
        try HintsGenerator.writeHints(finalHints, to: outputURL, preserveOrder: finalFieldOrder)
    } catch {
        print("Error: Failed to write hints file \(outputURL.path): \(error)")
        exit(1)
    }
}

/// Process a Core Data model (.xcdatamodel) and generate hints files for all entities
func processCoreDataModel(at modelURL: URL, outputDir: URL, extensionSearchPaths: [URL]) {
    guard let entities = CoreDataModelParser.parseCoreDataModel(at: modelURL) else {
        print("Error: Could not parse Core Data model or no entities found")
        exit(1)
    }
    
    if entities.isEmpty {
        print("Error: No entities found in Core Data model")
        exit(1)
    }
    
    print("Found \(entities.count) entity/entities in Core Data model:")
    for entity in entities {
        // For each entity, look for extension files in search paths
        var entityFields = entity.fields
        
        // Search for extension files for this entity
        // Always include the model's directory (and subdirectories) in the search
        var searchDirs: [URL] = []
        
        // Add the model's directory (where .xcdatamodel or .xcdatamodeld is located)
        // This will be searched recursively for extension files
        let modelDir = modelURL.deletingLastPathComponent()
        if !searchDirs.contains(where: { $0.path == modelDir.path }) {
            searchDirs.append(modelDir)
        }
        
        // Also include parent directory as a common location for extensions
        let parentDir = modelDir.deletingLastPathComponent()
        if !searchDirs.contains(where: { $0.path == parentDir.path }) {
            searchDirs.append(parentDir)
        }
        
        // Add any explicitly provided extension search paths
        for extPath in extensionSearchPaths {
            if !searchDirs.contains(where: { $0.path == extPath.path }) {
                searchDirs.append(extPath)
            }
        }
        
        // Find extension files by parsing Swift files and matching extension declarations
        // This is more robust than filename pattern matching
        let extensionFiles = SwiftModelParser.findExtensionFiles(for: entity.name, in: searchDirs)
        
        // Parse extension files and add their fields
        for extFile in extensionFiles {
            if let result = SwiftModelParser.parseSwiftFile(at: extFile) {
                entityFields.append(contentsOf: result.fields)
            }
        }
        
        let outputURL = outputDir.appendingPathComponent("\(entity.name).hints")
        generateHintsFile(for: entityFields, outputURL: outputURL)
        print("✅ Generated/updated hints file: \(outputURL.path)")
        print("   Entity: \(entity.name), Found \(entityFields.count) fields")
        if !extensionFiles.isEmpty {
            print("   Extension files: \(extensionFiles.map { $0.lastPathComponent }.joined(separator: ", "))")
        }
    }
}

main()
