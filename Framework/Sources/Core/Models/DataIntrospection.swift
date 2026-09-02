//
//  DataIntrospection.swift
//  SixLayerFramework
//
//  Data introspection engine for intelligent UI generation
//

import Foundation
import SwiftUI
import CoreData
#if canImport(SwiftData)
import SwiftData
#endif

// MARK: - Data Structure Analysis

/// Analyzes data structures to provide intelligent UI recommendations
public struct DataIntrospectionEngine {
    
    /// Analyze a data model from type and hints alone (type-only analysis)
    /// Requires fully declarative hints to work without instance data
    /// - Parameters:
    ///   - modelType: The type to analyze
    ///   - modelName: Optional model name for hints lookup (defaults to type name)
    /// - Returns: DataAnalysisResult if hints are fully declarative, nil otherwise
    public static func analyzeFromType<T>(_ modelType: T.Type, modelName: String? = nil) -> DataAnalysisResult? {
        let typeName = modelName ?? String(describing: modelType)
            .components(separatedBy: ".").last ?? String(describing: modelType)
        
        // Load hints
        let hintsLoader = FileBasedDataHintsLoader()
        let hintsResult = hintsLoader.loadHintsResult(for: typeName)
        
        // Check if we have any hints
        guard !hintsResult.fieldHints.isEmpty else {
            return nil // No hints available, cannot analyze from type alone
        }
        
        // Check if all hints are fully declarative
        let allFullyDeclarative = hintsResult.fieldHints.values.allSatisfy { $0.isFullyDeclarative }
        
        guard allFullyDeclarative else {
            return nil // Hints are not fully declarative, need instance data
        }
        
        // Analyze from hints only (no instance data needed)
        return analyzeFromHintsOnly(hints: hintsResult.fieldHints)
    }
    
    /// Analyze fields from fully declarative hints only (no instance data)
    private static func analyzeFromHintsOnly(hints: [String: FieldDisplayHints]) -> DataAnalysisResult {
        var fields: [DataField] = []
        
        for (fieldName, hint) in hints {
            // Skip hidden fields
            guard !hint.isHidden else { continue }
            // Only use fully declarative hints
            guard hint.isFullyDeclarative else { continue }
            
            let fieldType = convertFieldTypeStringToEnum(hint.fieldType ?? "custom")
            let field = DataField(
                name: fieldName,
                type: fieldType,
                isOptional: hint.isOptional ?? false,
                isArray: hint.isArray ?? false,
                isIdentifiable: fieldName == "id" || fieldName.hasSuffix("ID"),
                hasDefaultValue: hint.defaultValue != nil
            )
            fields.append(field)
        }
        
        // Calculate complexity without instance data
        let complexity = calculateComplexity(fields: fields, data: nil)
        let patterns = detectPatterns(fields: fields)
        let recommendations = generateRecommendations(
            fields: fields,
            complexity: complexity,
            patterns: patterns
        )
        
        return DataAnalysisResult(
            fields: fields,
            complexity: complexity,
            patterns: patterns,
            recommendations: recommendations
        )
    }
    
    /// Analyze a data model and provide UI recommendations
    /// Supports Core Data (NSManagedObject), SwiftData (PersistentModel), and regular Swift types
    /// Uses hints-first discovery: checks for fully declarative hints, falls back to Mirror introspection
    public static func analyze<T>(_ data: T) -> DataAnalysisResult {
        // Check if this is a Core Data managed object
        if let managedObject = data as? NSManagedObject {
            return analyzeCoreData(managedObject)
        }
        
        // Check if this is a SwiftData PersistentModel (iOS 17+, macOS 14+)
        // SwiftData models work with standard Mirror introspection since they're regular Swift classes
        // The @Model macro doesn't prevent Mirror from working
        #if canImport(SwiftData)
        if #available(macOS 14.0, iOS 17.0, *) {
            if data is any PersistentModel {
                // SwiftData models can be analyzed using standard Mirror introspection
                // The @Model macro doesn't hide properties from Mirror
                // Fall through to hints-first analysis below
            }
        }
        #endif

        // Try hints-first discovery, fall back to Mirror introspection
        if let hintsResult = tryHintsFirstDiscovery(for: data) {
            return hintsResult
        }

        // Use standard Mirror introspection as fallback
        let mirror = Mirror(reflecting: data)
        let fields = extractFields(from: mirror)
        let complexity = calculateComplexity(fields: fields, data: data)
        let patterns = detectPatterns(fields: fields)
        let recommendations = generateRecommendations(
            fields: fields,
            complexity: complexity,
            patterns: patterns
        )

        return DataAnalysisResult(
            fields: fields,
            complexity: complexity,
            patterns: patterns,
            recommendations: recommendations
        )
    }
    

    
    // MARK: - Hints-First Discovery
    
    /// Try to discover fields using hints first, falling back to Mirror if hints are incomplete
    /// Returns nil if hints are not available or not fully declarative
    private static func tryHintsFirstDiscovery<T>(for data: T) -> DataAnalysisResult? {
        // Determine model name from type
        let modelName = String(describing: type(of: data))
            .components(separatedBy: ".").last ?? String(describing: type(of: data))
        
        // Load hints
        let hintsLoader = FileBasedDataHintsLoader()
        let hintsResult = hintsLoader.loadHintsResult(for: modelName)
        
        // Check if we have any hints
        guard !hintsResult.fieldHints.isEmpty else {
            return nil // No hints available, fall back to Mirror
        }
        
        // Check if all hints are fully declarative
        let allFullyDeclarative = hintsResult.fieldHints.values.allSatisfy { $0.isFullyDeclarative }
        
        if allFullyDeclarative {
            // All hints are fully declarative - use hints-only discovery
            return analyzeFromHints(hints: hintsResult.fieldHints, data: data)
        } else {
            // Some hints are partial - use hybrid approach (hints + Mirror)
            return analyzeHybrid(hints: hintsResult.fieldHints, data: data)
        }
    }
    
    /// Analyze fields from fully declarative hints only
    private static func analyzeFromHints<T>(hints: [String: FieldDisplayHints], data: T) -> DataAnalysisResult {
        var fields: [DataField] = []
        
        for (fieldName, hint) in hints {
            // Skip hidden fields
            guard !hint.isHidden else { continue }
            // Only use fully declarative hints
            guard hint.isFullyDeclarative else { continue }
            
            let fieldType = convertFieldTypeStringToEnum(hint.fieldType ?? "custom")
            let field = DataField(
                name: fieldName,
                type: fieldType,
                isOptional: hint.isOptional ?? false,
                isArray: hint.isArray ?? false,
                isIdentifiable: fieldName == "id" || fieldName.hasSuffix("ID"),
                hasDefaultValue: hint.defaultValue != nil
            )
            fields.append(field)
        }
        
        let complexity = calculateComplexity(fields: fields, data: data)
        let patterns = detectPatterns(fields: fields)
        let recommendations = generateRecommendations(
            fields: fields,
            complexity: complexity,
            patterns: patterns
        )
        
        return DataAnalysisResult(
            fields: fields,
            complexity: complexity,
            patterns: patterns,
            recommendations: recommendations
        )
    }
    
    /// Analyze using hybrid approach: hints for fully declarative fields, Mirror for others
    private static func analyzeHybrid<T>(hints: [String: FieldDisplayHints], data: T) -> DataAnalysisResult {
        // Get Mirror fields first
        let mirror = Mirror(reflecting: data)
        let mirrorFields = extractFields(from: mirror)
        
        // Create a map of hint-based fields (only fully declarative, not hidden)
        var hintFields: [String: DataField] = [:]
        for (fieldName, hint) in hints {
            // Skip hidden fields
            guard !hint.isHidden else { continue }
            guard hint.isFullyDeclarative else { continue }
            
            let fieldType = convertFieldTypeStringToEnum(hint.fieldType ?? "custom")
            let field = DataField(
                name: fieldName,
                type: fieldType,
                isOptional: hint.isOptional ?? false,
                isArray: hint.isArray ?? false,
                isIdentifiable: fieldName == "id" || fieldName.hasSuffix("ID"),
                hasDefaultValue: hint.defaultValue != nil
            )
            hintFields[fieldName] = field
        }
        
        // Merge: prefer hints over Mirror for fields that have fully declarative hints
        var mergedFields: [DataField] = []
        var processedNames = Set<String>()
        
        // Add hint-based fields first (they take priority)
        for (name, field) in hintFields {
            mergedFields.append(field)
            processedNames.insert(name)
        }
        
        // Add Mirror fields that don't have hints
        for field in mirrorFields {
            if !processedNames.contains(field.name) {
                mergedFields.append(field)
            }
        }
        
        let complexity = calculateComplexity(fields: mergedFields, data: data)
        let patterns = detectPatterns(fields: mergedFields)
        let recommendations = generateRecommendations(
            fields: mergedFields,
            complexity: complexity,
            patterns: patterns
        )
        
        return DataAnalysisResult(
            fields: mergedFields,
            complexity: complexity,
            patterns: patterns,
            recommendations: recommendations
        )
    }
    
    /// Convert fieldType string to FieldType enum
    private static func convertFieldTypeStringToEnum(_ fieldTypeString: String) -> FieldType {
        switch fieldTypeString.lowercased() {
        case "string":
            return .string
        case "number":
            return .number
        case "boolean":
            return .boolean
        case "date":
            return .date
        case "url":
            return .url
        case "uuid":
            return .uuid
        case "document":
            return .document
        case "image":
            return .image
        default:
            return .custom
        }
    }
    
    /// Analyze a collection of data items
    public static func analyzeCollection<T>(_ items: [T]) -> CollectionAnalysisResult {
        guard let firstItem = items.first else {
            return CollectionAnalysisResult(
                itemCount: 0,
                itemComplexity: .simple,
                collectionType: .empty,
                recommendations: []
            )
        }
        
        let itemAnalysis = analyze(firstItem)
        let collectionType = determineCollectionType(items: items, itemAnalysis: itemAnalysis)
        let recommendations = generateCollectionRecommendations(
            items: items,
            itemAnalysis: itemAnalysis,
            collectionType: collectionType
        )
        
        return CollectionAnalysisResult(
            itemCount: items.count,
            itemComplexity: itemAnalysis.complexity,
            collectionType: collectionType,
            recommendations: recommendations
        )
    }
}

// MARK: - Field Analysis

/// Represents a field in a data model
public struct DataField: Sendable {
    public let name: String
    public let type: FieldType
    public let isOptional: Bool
    public let isArray: Bool
    public let isIdentifiable: Bool
    public let hasDefaultValue: Bool
    
    public init(
        name: String,
        type: FieldType,
        isOptional: Bool = false,
        isArray: Bool = false,
        isIdentifiable: Bool = false,
        hasDefaultValue: Bool = false
    ) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.isArray = isArray
        self.isIdentifiable = isIdentifiable
        self.hasDefaultValue = hasDefaultValue
    }
}

/// Types of fields that can be detected
public enum FieldType: String, CaseIterable, Sendable {
    case string = "string"
    case number = "number"
    case boolean = "boolean"
    case date = "date"
    case image = "image"
    case document = "document"
    case url = "url"
    case uuid = "uuid"
    case custom = "custom"
    case relationship = "relationship"
    case hierarchical = "hierarchical"
}

// MARK: - Complexity Analysis

// Note: ContentComplexity is defined in PlatformTypes.swift

/// Content richness levels for complexity analysis
public enum ContentRichness {
    case minimal
    case moderate
    case rich
    case veryRich
}
// We use the existing enum to avoid duplication

// MARK: - Pattern Detection

/// Data patterns that influence UI decisions
public struct DataPatterns: Sendable {
    public let hasMedia: Bool
    public let hasDates: Bool
    public let hasRelationships: Bool
    public let isHierarchical: Bool
    public let hasGeographicData: Bool
    public let hasFinancialData: Bool
    public let hasUserData: Bool
    
    public init(
        hasMedia: Bool = false,
        hasDates: Bool = false,
        hasRelationships: Bool = false,
        isHierarchical: Bool = false,
        hasGeographicData: Bool = false,
        hasFinancialData: Bool = false,
        hasUserData: Bool = false
    ) {
        self.hasMedia = hasMedia
        self.hasDates = hasDates
        self.hasRelationships = hasRelationships
        self.isHierarchical = isHierarchical
        self.hasGeographicData = hasGeographicData
        self.hasFinancialData = hasFinancialData
        self.hasUserData = hasUserData
    }
}

// MARK: - Collection Types

/// Types of collections for UI optimization
public enum CollectionType: String, CaseIterable {
    case empty = "empty"
    case single = "single"
    case small = "small"        // 2-10 items
    case medium = "medium"      // 11-100 items
    case large = "large"        // 101-1000 items
    case veryLarge = "veryLarge" // 1000+ items
}

// MARK: - Analysis Results

/// Result of data structure analysis
public struct DataAnalysisResult: Sendable {
    public let fields: [DataField]
    public let complexity: ContentComplexity
    public let patterns: DataPatterns
    public let recommendations: [UIRecommendation]
    
    public init(
        fields: [DataField],
        complexity: ContentComplexity,
        patterns: DataPatterns,
        recommendations: [UIRecommendation]
    ) {
        self.fields = fields
        self.complexity = complexity
        self.patterns = patterns
        self.recommendations = recommendations
    }
}

/// Result of collection analysis
public struct CollectionAnalysisResult {
    public let itemCount: Int
    public let itemComplexity: ContentComplexity
    public let collectionType: CollectionType
    public let recommendations: [UIRecommendation]
    
    public init(
        itemCount: Int,
        itemComplexity: ContentComplexity,
        collectionType: CollectionType,
        recommendations: [UIRecommendation]
    ) {
        self.itemCount = itemCount
        self.itemComplexity = itemComplexity
        self.collectionType = collectionType
        self.recommendations = recommendations
    }
}

// MARK: - UI Recommendations

/// UI recommendations based on data analysis
public struct UIRecommendation: Sendable {
    public let type: RecommendationType
    public let priority: RecommendationPriority
    public let description: String
    public let implementation: String
    
    public init(
        type: RecommendationType,
        priority: RecommendationPriority,
        description: String,
        implementation: String
    ) {
        self.type = type
        self.priority = priority
        self.description = description
        self.implementation = implementation
    }
}

/// Types of UI recommendations
public enum RecommendationType: String, CaseIterable, Sendable {
    case layout = "layout"
    case navigation = "navigation"
    case presentation = "presentation"
    case interaction = "interaction"
    case performance = "performance"
    case accessibility = "accessibility"
}

/// Priority levels for recommendations
public enum RecommendationPriority: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Public Utility Methods

public extension DataIntrospectionEngine {
    
    /// Get a summary of data analysis for debugging
    static func getAnalysisSummary<T>(_ data: T) -> String {
        let analysis = analyze(data)
        return """
        Data Analysis Summary:
        - Fields: \(analysis.fields.count)
        - Complexity: \(analysis.complexity.rawValue)
        - Has Media: \(analysis.patterns.hasMedia)
        - Has Dates: \(analysis.patterns.hasDates)
        - Has Relationships: \(analysis.patterns.hasRelationships)
        - Is Hierarchical: \(analysis.patterns.isHierarchical)
        - Recommendations: \(analysis.recommendations.count)
        """
    }
    
    /// Get field names as a simple array
    static func getFieldNames<T>(_ data: T) -> [String] {
        let analysis = analyze(data)
        return analysis.fields.map { $0.name }
    }
    
    /// Check if data has specific field types
    static func hasFieldType<T>(_ data: T, type: FieldType) -> Bool {
        let analysis = analyze(data)
        return analysis.fields.contains { $0.type == type }
    }
    
    /// Get fields of a specific type
    static func getFieldsOfType<T>(_ data: T, type: FieldType) -> [DataField] {
        let analysis = analyze(data)
        return analysis.fields.filter { $0.type == type }
    }
}

// MARK: - Private Implementation

private extension DataIntrospectionEngine {

    /// Analyze Core Data managed objects using NSEntityDescription
    static func analyzeCoreData(_ managedObject: NSManagedObject) -> DataAnalysisResult {
        let entity = managedObject.entity
        let properties = entity.propertiesByName

        // If no properties, fallback to Mirror
        if properties.isEmpty {
            return analyzeWithMirror(managedObject)
        }

        var fields: [DataField] = []

        for (name, property) in properties {
            // Skip relationships for now
            guard let attribute = property as? NSAttributeDescription else { continue }

            let fieldType = inferCoreDataFieldType(attributeType: attribute.attributeType)
            let field = DataField(
                name: name,
                type: fieldType,
                isOptional: property.isOptional,
                isArray: false,
                isIdentifiable: name == "id" || name.hasSuffix("ID"),
                hasDefaultValue: false
            )
            fields.append(field)
        }

        let complexity = calculateComplexity(fields: fields, data: managedObject)
        let patterns = detectPatterns(fields: fields)
        let recommendations = generateRecommendations(
            fields: fields,
            complexity: complexity,
            patterns: patterns
        )

        return DataAnalysisResult(
            fields: fields,
            complexity: complexity,
            patterns: patterns,
            recommendations: recommendations
        )
    }

    /// Infer field type from Core Data attribute type
    static func inferCoreDataFieldType(attributeType: NSAttributeType) -> FieldType {
        switch attributeType {
        case .stringAttributeType:
            return .string
        case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType,
             .decimalAttributeType, .doubleAttributeType, .floatAttributeType:
            return .number
        case .booleanAttributeType:
            return .boolean
        case .dateAttributeType:
            return .date
        case .UUIDAttributeType:
            return .uuid
        case .binaryDataAttributeType, .transformableAttributeType:
            return .document
        default:
            return .custom
        }
    }

    /// Analyze with Mirror (fallback for non-Core Data or empty Core Data entities)
    static func analyzeWithMirror<T>(_ data: T) -> DataAnalysisResult {
        let mirror = Mirror(reflecting: data)
        let fields = extractFields(from: mirror)
        let complexity = calculateComplexity(fields: fields, data: data)
        let patterns = detectPatterns(fields: fields)
        let recommendations = generateRecommendations(
            fields: fields,
            complexity: complexity,
            patterns: patterns
        )
        
        return DataAnalysisResult(
            fields: fields,
            complexity: complexity,
            patterns: patterns,
            recommendations: recommendations
        )
    }
    
    /// Extract field information from a Mirror
    static func extractFields(from mirror: Mirror) -> [DataField] {
        var fields: [DataField] = []
        
        for child in mirror.children {
            guard let label = child.label else { continue }
            
            let field = DataField(
                name: label,
                type: determineFieldType(child.value),
                isOptional: isOptional(child.value),
                isArray: isArray(child.value),
                isIdentifiable: isIdentifiable(child.value),
                hasDefaultValue: hasDefaultValue(child.value)
            )
            
            fields.append(field)
        }
        
        return fields
    }
    
    /// Determine the type of a field
    static func determineFieldType(_ value: Any) -> FieldType {
        switch value {
        case is String:
            return .string
        case is Int, is Double, is Float, is CGFloat:
            return .number
        case is Bool:
            return .boolean
        case is Date:
            return .date
        case is URL:
            return .url
        case is UUID:
            return .uuid
        case is Data:
            return .document
        default:
            // Check for more complex types using Mirror
            let mirror = Mirror(reflecting: value)
            
            // Check for image types
            #if os(iOS)
            if mirror.subjectType == UIImage.self {
                return .image
            }
            #elseif os(macOS)
            if mirror.subjectType == NSImage.self {
                return .image
            }
            #endif
            
            // Check for relationships (objects with properties)
            if mirror.displayStyle == .class || mirror.displayStyle == .struct {
                // If it has many properties, it might be a relationship
                if mirror.children.count > 3 {
                    return .relationship
                }
                return .custom
            }
            
            // Check for hierarchical structures
            if mirror.displayStyle == .collection {
                return .hierarchical
            }
            
            return .custom
        }
    }
    
    /// Check if a value is optional
    static func isOptional(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)
        return mirror.displayStyle == .optional
    }
    
    /// Check if a value is an array
    static func isArray(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)
        return mirror.displayStyle == .collection
    }
    
    /// Check if a value conforms to Identifiable
    static func isIdentifiable(_ value: Any) -> Bool {
        // Check if the value has an 'id' property
        let mirror = Mirror(reflecting: value)
        return mirror.children.contains { $0.label == "id" }
    }
    
    /// Check if a value has a default value
    static func hasDefaultValue(_ value: Any) -> Bool {
        // For now, we'll assume all values have defaults
        // This could be enhanced with more sophisticated detection
        return true
    }
    
    /// Calculate complexity based on fields and content richness
    static func calculateComplexity(fields: [DataField], data: Any? = nil) -> ContentComplexity {
        let fieldCount = fields.count
        let hasComplexTypes = fields.contains { $0.type == .relationship }
        let hasHierarchicalTypes = fields.contains { $0.type == .hierarchical }
        
        // Count hierarchical types separately as they're less complex than relationships
        let hierarchicalCount = fields.filter { $0.type == .hierarchical }.count
        
        // Analyze content richness if data is provided
        let contentRichness = data != nil ? analyzeContentRichness(data: data!, fields: fields) : .minimal
        
        // Base complexity from field structure
        let baseComplexity: ContentComplexity
        switch (fieldCount, hasComplexTypes, hasHierarchicalTypes, hierarchicalCount) {
        case (0...3, false, false, 0):
            baseComplexity = .simple
        case (4...7, false, false, 0):
            baseComplexity = .moderate
        case (4...7, false, true, 1...2):
            baseComplexity = .moderate  // Allow 1-2 hierarchical types for moderate
        case (8...15, false, false, 0):
            baseComplexity = .complex
        case (8...15, false, true, 1...3):
            baseComplexity = .complex   // Allow 1-3 hierarchical types for complex
        case (_, true, _, _):
            baseComplexity = .veryComplex  // Any relationships make it very complex
        default:
            baseComplexity = .veryComplex
        }
        
        // Adjust complexity based on content richness
        return adjustComplexityForContent(baseComplexity, contentRichness: contentRichness)
    }
    
    /// Analyze content richness of the data
    static func analyzeContentRichness(data: Any, fields: [DataField]) -> ContentRichness {
        let mirror = Mirror(reflecting: data)
        var totalContentLength = 0
        var richFieldCount = 0
        var maxFieldLength = 0
        
        for child in mirror.children {
            guard let label = child.label,
                  let _ = fields.first(where: { $0.name == label }) else { continue }
            
            let contentLength = getContentLength(child.value)
            totalContentLength += contentLength
            maxFieldLength = max(maxFieldLength, contentLength)
            
            // Consider a field "rich" if it has substantial content
            if contentLength > 50 {
                richFieldCount += 1
            }
        }
        
        // Determine richness level
        if totalContentLength > 500 || richFieldCount >= 3 || maxFieldLength > 200 {
            return .veryRich
        } else if totalContentLength > 200 || richFieldCount >= 2 || maxFieldLength > 100 {
            return .rich
        } else if totalContentLength > 50 || richFieldCount >= 1 {
            return .moderate
        } else {
            return .minimal
        }
    }
    
    /// Get content length for a value
    static func getContentLength(_ value: Any) -> Int {
        switch value {
        case let string as String:
            return string.count
        case let array as [Any]:
            return array.reduce(0) { $0 + getContentLength($1) }
        case let dict as [String: Any]:
            return dict.values.reduce(0) { $0 + getContentLength($1) }
        default:
            return String(describing: value).count
        }
    }
    
    /// Adjust complexity based on content richness
    static func adjustComplexityForContent(_ baseComplexity: ContentComplexity, contentRichness: ContentRichness) -> ContentComplexity {
        switch (baseComplexity, contentRichness) {
        case (.simple, .veryRich):
            return .complex
        case (.simple, .rich):
            return .moderate
        case (.moderate, .veryRich):
            return .veryComplex
        case (.moderate, .rich):
            return .complex
        case (.complex, .veryRich):
            return .veryComplex
        default:
            return baseComplexity
        }
    }
    
    /// Detect patterns in the data
    static func detectPatterns(fields: [DataField]) -> DataPatterns {
        let hasMedia = fields.contains { $0.type == .image || $0.type == .document }
        let hasDates = fields.contains { $0.type == .date }
        let hasRelationships = fields.contains { $0.type == .relationship }
        let isHierarchical = fields.contains { $0.type == .hierarchical }
        
        // For now, we'll assume that if we have relationships or hierarchical structures,
        // they might contain dates, so we'll be more lenient
        let likelyHasDates = hasDates || hasRelationships || isHierarchical
        
        return DataPatterns(
            hasMedia: hasMedia,
            hasDates: likelyHasDates,
            hasRelationships: hasRelationships,
            isHierarchical: isHierarchical
        )
    }
    
    /// Generate UI recommendations
    static func generateRecommendations(
        fields: [DataField],
        complexity: ContentComplexity,
        patterns: DataPatterns
    ) -> [UIRecommendation] {
        var recommendations: [UIRecommendation] = []
        
        // Layout recommendations based on complexity
        switch complexity {
        case .simple:
            recommendations.append(UIRecommendation(
                type: .layout,
                priority: .high,
                description: "Use compact layout for simple data",
                implementation: "platformCompactLayout"
            ))
        case .moderate:
            recommendations.append(UIRecommendation(
                type: .layout,
                priority: .high,
                description: "Use standard layout with sections",
                implementation: "platformStandardLayout"
            ))
        case .complex, .veryComplex, .advanced:
            recommendations.append(UIRecommendation(
                type: .layout,
                priority: .critical,
                description: "Use tabbed or master-detail layout",
                implementation: "platformTabbedLayout"
            ))
        }
        
        // Media handling recommendations
        if patterns.hasMedia {
            recommendations.append(UIRecommendation(
                type: .presentation,
                priority: .high,
                description: "Include media gallery or viewer",
                implementation: "platformMediaGallery"
            ))
        }
        
        // Date handling recommendations
        if patterns.hasDates {
            recommendations.append(UIRecommendation(
                type: .presentation,
                priority: .medium,
                description: "Include date picker and calendar views",
                implementation: "platformDateHandling"
            ))
        }
        
        return recommendations
    }
    
    /// Determine collection type based on item count
    static func determineCollectionType<T>(
        items: [T],
        itemAnalysis: DataAnalysisResult
    ) -> CollectionType {
        switch items.count {
        case 0:
            return .empty
        case 1:
            return .single
        case 2...10:
            return .small
        case 11...100:
            return .medium
        case 101...1000:
            return .large
        default:
            return .veryLarge
        }
    }
    
    /// Generate collection-specific recommendations
    static func generateCollectionRecommendations<T>(
        items: [T],
        itemAnalysis: DataAnalysisResult,
        collectionType: CollectionType
    ) -> [UIRecommendation] {
        var recommendations: [UIRecommendation] = []
        
        // Collection size recommendations
        switch collectionType {
        case .small:
            recommendations.append(UIRecommendation(
                type: .layout,
                priority: .high,
                description: "Use grid layout for small collections",
                implementation: "platformGridLayout"
            ))
        case .medium:
            recommendations.append(UIRecommendation(
                type: .layout,
                priority: .high,
                description: "Use list layout with search",
                implementation: "platformListWithSearch"
            ))
        case .large, .veryLarge:
            recommendations.append(UIRecommendation(
                type: .performance,
                priority: .critical,
                description: "Use lazy loading and pagination",
                implementation: "LazyVStack / pagination (no platformLazyLoading API)"
            ))
        default:
            break
        }
        
        // Add item complexity recommendations
        recommendations.append(contentsOf: itemAnalysis.recommendations)
        
        return recommendations
    }
}
