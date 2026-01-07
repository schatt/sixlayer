//
//  DataHintsLoader.swift
//  SixLayerFramework
//
//  Loads .hints files that describe how to present data models
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Item Color Provider Config

/// Configuration for presentation preference parsed from hints files
public enum PresentationPreferenceConfig: Sendable {
    case simple(String)  // Simple case like "list", "grid", etc.
    case countBased(lowCount: String, highCount: String, threshold: Int)
}

/// Configuration for item-based color provider parsed from hints files
public struct ItemColorProviderConfig: Sendable {
    /// Primary property to check (e.g., "severity", "status")
    public let type: String?
    /// Mapping from property values to colors (e.g., {"high": "red", "low": "yellow"})
    public let mapping: [String: String]
    /// Secondary property mapping (e.g., status-based colors)
    public let statusMapping: [String: String]?
    
    public init(
        type: String? = nil,
        mapping: [String: String] = [:],
        statusMapping: [String: String]? = nil
    ) {
        self.type = type
        self.mapping = mapping
        self.statusMapping = statusMapping
    }
}

// MARK: - Data Hints Result

/// Complete result from loading a hints file, including both field hints and layout sections
// TODO: Make properly Sendable once DynamicFormField is Sendable
public struct DataHintsResult: @unchecked Sendable {
    /// Field-level display hints keyed by field ID
    public let fieldHints: [String: FieldDisplayHints]
    /// Layout sections parsed from _sections array in hints file
    public let sections: [DynamicFormSection]
    /// Default color for card presentation (parsed from _defaultColor in hints file)
    public let defaultColor: String?
    /// Color mapping by type name (parsed from _colorMapping in hints file)
    /// Format: {"TypeName": "colorString"} where TypeName is your Swift type name (struct/class/enum)
    /// as a string (e.g., "Vehicle", "Task", "User") - this is the name of your Swift type,
    /// not necessarily the Core Data entity name (though they often match).
    /// colorString can be a named color or hex (e.g., "blue", "#FF0000")
    /// Note: Currently stored but not automatically converted to ObjectIdentifier-based mapping.
    /// See PresentationHints initializer TODO for type name -> ObjectIdentifier conversion.
    public let colorMapping: [String: String]?
    /// Item color provider configuration (parsed from _itemColorProvider in hints file)
    /// Contains property-based color mapping that will be converted to a closure at runtime
    public let itemColorProviderConfig: ItemColorProviderConfig?
    /// Data type hint (parsed from _dataType in hints file)
    public let dataType: String?
    /// Content complexity (parsed from _complexity in hints file)
    public let complexity: String?
    /// Presentation context (parsed from _context in hints file)
    public let context: String?
    /// Custom preferences (parsed from _customPreferences in hints file)
    public let customPreferences: [String: String]?
    /// Presentation preference configuration (parsed from _presentationPreference in hints file)
    /// Can be a simple string or a countBased configuration object
    public let presentationPreference: PresentationPreferenceConfig?
    
    public init(
        fieldHints: [String: FieldDisplayHints] = [:],
        sections: [DynamicFormSection] = [],
        defaultColor: String? = nil,
        colorMapping: [String: String]? = nil,
        itemColorProviderConfig: ItemColorProviderConfig? = nil,
        dataType: String? = nil,
        complexity: String? = nil,
        context: String? = nil,
        customPreferences: [String: String]? = nil,
        presentationPreference: PresentationPreferenceConfig? = nil
    ) {
        self.fieldHints = fieldHints
        self.sections = sections
        self.defaultColor = defaultColor
        self.colorMapping = colorMapping
        self.itemColorProviderConfig = itemColorProviderConfig
        self.dataType = dataType
        self.complexity = complexity
        self.context = context
        self.customPreferences = customPreferences
        self.presentationPreference = presentationPreference
    }
}

// MARK: - Data Hints Protocol

/// Protocol for loading hints that describe how to present data models
// TODO: Make Sendable once DataHintsResult is Sendable
public protocol DataHintsLoader {
    /// Load hints for a data model by its name (backward compatibility - returns only field hints)
    func loadHints(for modelName: String) -> [String: FieldDisplayHints]
    
    /// Load complete hints result including field hints and sections
    func loadHintsResult(for modelName: String) -> DataHintsResult
    
    /// Load complete hints result with locale support for language-specific OCR hints
    func loadHintsResult(for modelName: String, locale: Locale) -> DataHintsResult
}

// MARK: - File-Based Data Hints Loader

/// Loads .hints files from the bundle or filesystem
// TODO: Add @unchecked Sendable once DataHintsResult is Sendable
public class FileBasedDataHintsLoader: DataHintsLoader {
    private let fileManager: FileManager
    private let bundle: Bundle
    
    public init(fileManager: FileManager = .default, bundle: Bundle = .main) {
        self.fileManager = fileManager
        self.bundle = bundle
    }
    
    /// Load a .hints file for a data model (backward compatibility - returns only field hints)
    /// Example: loadHints(for: "User") looks for "User.hints" file in the Hints/ folder
    public func loadHints(for modelName: String) -> [String: FieldDisplayHints] {
        return loadHintsResult(for: modelName).fieldHints
    }
    
    /// Load complete hints result including field hints and sections
    /// Example: loadHintsResult(for: "User") looks for "User.hints" file in the Hints/ folder
    public func loadHintsResult(for modelName: String) -> DataHintsResult {
        return loadHintsResult(for: modelName, locale: Locale.current)
    }
    
    /// Load complete hints result with locale support for language-specific OCR hints
    /// Example: loadHintsResult(for: "User", locale: Locale(identifier: "es")) uses Spanish OCR hints
    public func loadHintsResult(for modelName: String, locale: Locale) -> DataHintsResult {
        // Try to load from bundle first (in Hints/ subfolder)
        if let hintsFolder = bundle.url(forResource: "Hints", withExtension: nil) {
            let url = hintsFolder.appendingPathComponent("\(modelName).hints")
            if let data = try? Data(contentsOf: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return parseHintsResult(from: json, locale: locale)
            }
        }
        
        // Also try root level for backward compatibility
        if let url = bundle.url(forResource: modelName, withExtension: "hints"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return parseHintsResult(from: json, locale: locale)
        }
        
        // Fall back to documents directory (in Hints/ subfolder)
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let hintsFolder = documentsURL.appendingPathComponent("Hints")
            let url = hintsFolder.appendingPathComponent("\(modelName).hints")
            if fileManager.fileExists(atPath: hintsFolder.path),
               let data = try? Data(contentsOf: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return parseHintsResult(from: json, locale: locale)
            }
        }
        
        return DataHintsResult()
    }
    
    /// Check if a hints file exists for a model
    public func hasHints(for modelName: String) -> Bool {
        // Check in Hints/ subfolder first
        if let hintsFolder = bundle.url(forResource: "Hints", withExtension: nil) {
            let url = hintsFolder.appendingPathComponent("\(modelName).hints")
            if fileManager.fileExists(atPath: url.path) {
                return true
            }
        }
        
        // Also check root level for backward compatibility
        if let _ = bundle.url(forResource: modelName, withExtension: "hints") {
            return true
        }
        
        // Check documents directory
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let hintsFolder = documentsURL.appendingPathComponent("Hints")
            let url = hintsFolder.appendingPathComponent("\(modelName).hints")
            if fileManager.fileExists(atPath: url.path) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Private Helpers
    
    private func parseHintsResult(from json: [String: Any], locale: Locale = Locale.current) -> DataHintsResult {
        var fieldHints: [String: FieldDisplayHints] = [:]
        var sections: [DynamicFormSection] = []
        
        // Get language code for OCR hints lookup (e.g., "en", "es", "fr")
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        
        // Parse color configuration from _defaults (nested structure)
        var defaultColor: String?
        var colorMapping: [String: String]?
        var itemColorProviderConfig: ItemColorProviderConfig?
        var dataType: String?
        var complexity: String?
        var context: String?
        var customPreferences: [String: String]?
        var presentationPreference: PresentationPreferenceConfig?
        
        if let defaults = json["_defaults"] as? [String: Any] {
            defaultColor = defaults["_defaultColor"] as? String
            colorMapping = defaults["_colorMapping"] as? [String: String]
            
            // Parse _itemColorProvider configuration
            if let itemColorProviderDict = defaults["_itemColorProvider"] as? [String: Any] {
                let type = itemColorProviderDict["type"] as? String
                let mapping = itemColorProviderDict["mapping"] as? [String: String] ?? [:]
                let statusMapping = itemColorProviderDict["statusMapping"] as? [String: String]
                
                itemColorProviderConfig = ItemColorProviderConfig(
                    type: type,
                    mapping: mapping,
                    statusMapping: statusMapping
                )
            }
            
            // Parse presentation properties
            dataType = defaults["_dataType"] as? String
            complexity = defaults["_complexity"] as? String
            context = defaults["_context"] as? String
            customPreferences = defaults["_customPreferences"] as? [String: String]
            
            // Parse presentationPreference (can be string or countBased object)
            if let prefString = defaults["_presentationPreference"] as? String {
                presentationPreference = .simple(prefString)
            } else if let prefDict = defaults["_presentationPreference"] as? [String: Any],
                      let type = prefDict["type"] as? String,
                      type == "countBased",
                      let lowCount = prefDict["lowCount"] as? String,
                      let highCount = prefDict["highCount"] as? String,
                      let threshold = prefDict["threshold"] as? Int {
                presentationPreference = .countBased(lowCount: lowCount, highCount: highCount, threshold: threshold)
            }
        }
        
        // Parse field hints (all keys except _sections, __example, and _defaults)
        for (key, value) in json {
            if key == "_sections" {
                continue // Handle sections separately
            }
            if key == "__example" {
                continue // Skip __example - it's documentation only
            }
            if key == "_defaults" {
                continue // Handle color config separately
            }
            
            if let properties = value as? [String: Any] {
                // Parse type information (new - for fully declarative hints)
                let fieldType = properties["fieldType"] as? String
                let isOptional = (properties["isOptional"] as? String) == "true" ||
                                (properties["isOptional"] as? Bool) == true ? true :
                                (properties["isOptional"] as? String) == "false" ||
                                (properties["isOptional"] as? Bool) == false ? false : nil
                let isArray = (properties["isArray"] as? String) == "true" ||
                             (properties["isArray"] as? Bool) == true ? true :
                             (properties["isArray"] as? String) == "false" ||
                             (properties["isArray"] as? Bool) == false ? false : nil
                // Parse defaultValue and convert to Sendable
                let defaultValue: (any Sendable)? = parseDefaultValue(from: properties["defaultValue"])
                
                // Parse standard display hints
                let expectedLength = (properties["expectedLength"] as? String).flatMap(Int.init) ?? 
                                   (properties["expectedLength"] as? Int)
                let displayWidth = properties["displayWidth"] as? String
                let showCharacterCounter = (properties["showCharacterCounter"] as? String) == "true" ||
                                          (properties["showCharacterCounter"] as? Bool) == true
                let maxLength = (properties["maxLength"] as? String).flatMap(Int.init) ?? 
                               (properties["maxLength"] as? Int)
                let minLength = (properties["minLength"] as? String).flatMap(Int.init) ?? 
                               (properties["minLength"] as? Int)
                
                // Parse expected range for numeric validation
                let expectedRange = parseExpectedRange(from: properties)
                
                // Extract metadata (all string properties that aren't special keys)
                var metadata: [String: String] = [:]
                for (propKey, propValue) in properties {
                    if !["expectedLength", "displayWidth", "showCharacterCounter", "maxLength", "minLength", 
                         "expectedRange", "ocrHints", "calculationGroups", "inputType", "options",
                         "fieldType", "isOptional", "isArray", "defaultValue", "isHidden", "isEditable"].contains(propKey) &&
                       !propKey.hasPrefix("ocrHints.") {
                        if let stringValue = propValue as? String {
                            metadata[propKey] = stringValue
                        }
                    }
                }
                
                // Parse OCR hints with language-specific support
                let ocrHints = parseOCRHints(from: properties, languageCode: languageCode)
                
                // Parse calculation groups
                let calculationGroups = parseCalculationGroups(from: properties)
                
                // Parse input type and picker options
                let inputType = properties["inputType"] as? String
                let pickerOptions = parsePickerOptions(from: properties)
                
                // Parse isHidden flag
                let isHidden = (properties["isHidden"] as? String) == "true" ||
                              (properties["isHidden"] as? Bool) == true
                
                // Parse isEditable flag (defaults to true for backward compatibility)
                let isEditable = (properties["isEditable"] as? String) == "false" ||
                               (properties["isEditable"] as? Bool) == false ? false : true
                
                fieldHints[key] = FieldDisplayHints(
                    // Type information (new)
                    fieldType: fieldType,
                    isOptional: isOptional,
                    isArray: isArray,
                    defaultValue: defaultValue,
                    // Display properties (existing)
                    expectedLength: expectedLength,
                    displayWidth: displayWidth,
                    showCharacterCounter: showCharacterCounter,
                    maxLength: maxLength,
                    minLength: minLength,
                    expectedRange: expectedRange,
                    metadata: metadata,
                    ocrHints: ocrHints,
                    calculationGroups: calculationGroups,
                    inputType: inputType,
                    pickerOptions: pickerOptions,
                    isHidden: isHidden,
                    isEditable: isEditable
                )
            }
        }
        
        // Parse _sections if present
        if let sectionsArray = json["_sections"] as? [[String: Any]] {
            sections = parseSections(from: sectionsArray)
        }
        
        return DataHintsResult(
            fieldHints: fieldHints,
            sections: sections,
            defaultColor: defaultColor,
            colorMapping: colorMapping,
            itemColorProviderConfig: itemColorProviderConfig,
            dataType: dataType,
            complexity: complexity,
            context: context,
            customPreferences: customPreferences,
            presentationPreference: presentationPreference
        )
    }
    
    /// Parse expected range from properties (supports {"min": 5, "max": 30} format)
    private func parseExpectedRange(from properties: [String: Any]) -> ValueRange? {
        guard let rangeDict = properties["expectedRange"] as? [String: Any] else {
            return nil
        }
        
        // Support both numeric and string values
        let minValue: Double?
        if let minNum = rangeDict["min"] as? Double {
            minValue = minNum
        } else if let minNum = rangeDict["min"] as? Int {
            minValue = Double(minNum)
        } else if let minStr = rangeDict["min"] as? String {
            minValue = Double(minStr)
        } else {
            minValue = nil
        }
        
        let maxValue: Double?
        if let maxNum = rangeDict["max"] as? Double {
            maxValue = maxNum
        } else if let maxNum = rangeDict["max"] as? Int {
            maxValue = Double(maxNum)
        } else if let maxStr = rangeDict["max"] as? String {
            maxValue = Double(maxStr)
        } else {
            maxValue = nil
        }
        
        guard let min = minValue, let max = maxValue else {
            return nil
        }
        
        return ValueRange(min: min, max: max)
    }
    
    /// Parse defaultValue from JSON and convert to Sendable type
    /// Supports String, Int, Bool, Double, Float (all are Sendable)
    /// Note: JSONSerialization converts Bool to NSNumber/CFBoolean, so we check for that
    private func parseDefaultValue(from value: Any?) -> (any Sendable)? {
        guard let value = value else { return nil }
        
        // Convert common Sendable types (all JSON-serializable types are Sendable)
        if let stringValue = value as? String {
            return stringValue
        } else if let boolValue = value as? Bool {
            return boolValue
        } else if let nsNumber = value as? NSNumber {
            // JSONSerialization converts Bool to NSNumber/CFBoolean
            // Check if it's a CFBoolean (true/false) vs a numeric value
            if CFGetTypeID(nsNumber) == CFBooleanGetTypeID() {
                return nsNumber.boolValue
            } else {
                // It's a numeric value - check if it's a whole number (Int) or has decimal (Double)
                if nsNumber.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                    return nsNumber.intValue
                } else {
                    return nsNumber.doubleValue
                }
            }
        } else if let intValue = value as? Int {
            return intValue
        } else if let doubleValue = value as? Double {
            return doubleValue
        } else if let floatValue = value as? Float {
            return floatValue
        }
        
        // For other types, we can't safely convert without knowing the type
        // JSON only supports String, Int, Bool, Double, so this should cover all cases
        return nil
    }
    
    /// Parse picker options from properties (supports [{"value": "...", "label": "..."}] format)
    private func parsePickerOptions(from properties: [String: Any]) -> [PickerOption]? {
        guard let optionsArray = properties["options"] as? [[String: Any]] else {
            return nil
        }
        
        var pickerOptions: [PickerOption] = []
        for optionDict in optionsArray {
            guard let value = optionDict["value"] as? String,
                  let label = optionDict["label"] as? String else {
                continue // Skip invalid options
            }
            pickerOptions.append(PickerOption(value: value, label: label))
        }
        
        return pickerOptions.isEmpty ? nil : pickerOptions
    }
    
    /// Parse OCR hints with language-specific fallback: ocrHints.{language} -> ocrHints -> nil
    private func parseOCRHints(from properties: [String: Any], languageCode: String) -> [String]? {
        // First try language-specific key (e.g., "ocrHints.es")
        let languageSpecificKey = "ocrHints.\(languageCode)"
        if let languageHints = properties[languageSpecificKey] {
            return parseOCRHintsValue(languageHints)
        }
        
        // Fallback to default "ocrHints" key
        if let defaultHints = properties["ocrHints"] {
            return parseOCRHintsValue(defaultHints)
        }
        
        return nil
    }
    
    /// Parse OCR hints value (supports array or comma-separated string)
    private func parseOCRHintsValue(_ value: Any) -> [String]? {
        if let array = value as? [String] {
            return array
        }
        
        if let string = value as? String {
            // Support comma-separated string format
            return string.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        return nil
    }
    
    /// Parse calculation groups from properties
    private func parseCalculationGroups(from properties: [String: Any]) -> [CalculationGroup]? {
        guard let groupsArray = properties["calculationGroups"] as? [[String: Any]] else {
            return nil
        }
        
        var groups: [CalculationGroup] = []
        for groupDict in groupsArray {
            guard let id = groupDict["id"] as? String,
                  let formula = groupDict["formula"] as? String,
                  let dependentFields = groupDict["dependentFields"] as? [String],
                  let priority = groupDict["priority"] as? Int else {
                continue // Skip invalid groups
            }
            
            groups.append(CalculationGroup(
                id: id,
                formula: formula,
                dependentFields: dependentFields,
                priority: priority
            ))
        }
        
        return groups.isEmpty ? nil : groups
    }
    
    private func parseSections(from sectionsArray: [[String: Any]]) -> [DynamicFormSection] {
        var sections: [DynamicFormSection] = []
        
        for sectionDict in sectionsArray {
            // Title is required (for accessibility)
            guard let id = sectionDict["id"] as? String,
                  let title = sectionDict["title"] as? String else {
                print("⚠️ Warning: Skipping section in hints file - missing required 'id' or 'title'")
                continue
            }
            
            let description = sectionDict["description"] as? String
            let fieldIds = sectionDict["fields"] as? [String] ?? []
            let layoutStyleString = sectionDict["layoutStyle"] as? String
            let layoutStyle = layoutStyleString.flatMap { FieldLayout(rawValue: $0) }
            
            // Parse collapsible properties (Issue #74: Support collapsible sections in hints)
            let isCollapsible = sectionDict["isCollapsible"] as? Bool ?? false
            let isCollapsed = sectionDict["isCollapsed"] as? Bool ?? false
            
            // Store field IDs in metadata so we can match them later when creating form
            var metadata: [String: String] = [:]
            if !fieldIds.isEmpty {
                metadata["_fieldIds"] = fieldIds.joined(separator: ",")
            }
            
            // Create section (fields will be populated later when matched with actual form fields)
            let section = DynamicFormSection(
                id: id,
                title: title,
                description: description,
                fields: [], // Fields will be populated when creating form
                isCollapsible: isCollapsible,
                isCollapsed: isCollapsed,
                metadata: metadata.isEmpty ? nil : metadata,
                layoutStyle: layoutStyle
            )
            
            sections.append(section)
        }
        
        return sections
    }
    
    // Legacy method for backward compatibility
    private func parseHints(from json: [String: [String: String]]) -> [String: FieldDisplayHints] {
        var hints: [String: FieldDisplayHints] = [:]
        
        for (fieldName, properties) in json {
            // Convert to [String: Any] for parseExpectedRange and parsePickerOptions
            let propertiesAny = properties.mapValues { $0 as Any }
            let expectedRange = parseExpectedRange(from: propertiesAny)
            
            // For legacy format, options would be in a nested structure if present
            // Since legacy format is [String: String], we can't parse complex options
            // This maintains backward compatibility
            let inputType = properties["inputType"]
            let pickerOptions: [PickerOption]? = nil // Legacy format doesn't support nested options
            
            hints[fieldName] = FieldDisplayHints(
                expectedLength: properties["expectedLength"].flatMap(Int.init),
                displayWidth: properties["displayWidth"],
                showCharacterCounter: properties["showCharacterCounter"] == "true",
                maxLength: properties["maxLength"].flatMap(Int.init),
                minLength: properties["minLength"].flatMap(Int.init),
                expectedRange: expectedRange,
                metadata: properties,
                inputType: inputType,
                pickerOptions: pickerOptions
            )
        }
        
        return hints
    }
}

// MARK: - Data Hints Registry

/// Global registry for loading data hints
/// Since hints are immutable during execution, we use a shared cache for synchronous access
public actor DataHintsRegistry {
    private var cache: [String: [String: FieldDisplayHints]] = [:]
    private var resultCache: [String: DataHintsResult] = [:]
    private let loader: DataHintsLoader
    
    // Shared cache for synchronous access
    // File-based hints are immutable, so cached values are safe to access without actor isolation
    // Code-provided hints (like layoutSpec) are handled separately and not cached here
    // All access (reads and writes) is protected by preloadLock for thread safety
    // Using nonisolated(unsafe) because Swift 6 requires it for mutable static properties,
    // even when protected by external synchronization (the lock)
    nonisolated(unsafe) private static var sharedResultCache: [String: DataHintsResult] = [:]
    
    // Flag to track if hints have been preloaded (prevents redundant loading)
    // Once true, sharedResultCache is read-only and no writes are allowed
    // All access is protected by preloadLock for thread safety
    // Using nonisolated(unsafe) because Swift 6 requires it for mutable static properties,
    // even when protected by external synchronization (the lock)
    nonisolated(unsafe) private static var hintsPreloaded = false
    // Lock for synchronizing all cache operations (reads and writes)
    // Protects both sharedResultCache and hintsPreloaded
    nonisolated private static let preloadLock = NSLock()
    
    public init(loader: DataHintsLoader = FileBasedDataHintsLoader()) {
        self.loader = loader
    }
    
    /// Synchronously check if file-based hints are cached (nonisolated for fast access)
    /// File-based hints are immutable, so cached values are safe to access without actor isolation
    /// Note: Code-provided hints (like layoutSpec) are not cached and handled separately
    /// All access is protected by lock for thread safety
    nonisolated public static func hasCachedHints(for modelName: String) -> Bool {
        preloadLock.lock()
        defer { preloadLock.unlock() }
        return sharedResultCache[modelName] != nil
    }
    
    /// Synchronously get cached file-based hints if available (nonisolated for fast access)
    /// Returns nil if not cached - caller should use async loadHintsResult if nil
    /// File-based hints are immutable, so cached values are safe to access without actor isolation
    /// Note: Code-provided hints (like layoutSpec) are not cached and handled separately
    /// All access is protected by lock for thread safety
    nonisolated public static func getCachedHints(for modelName: String) -> DataHintsResult? {
        preloadLock.lock()
        defer { preloadLock.unlock() }
        return sharedResultCache[modelName]
    }
    
    /// Load hints for a data model, checking cache first (backward compatibility)
    public func loadHints(for modelName: String) -> [String: FieldDisplayHints] {
        return loadHintsResult(for: modelName).fieldHints
    }
    
    /// Load complete hints result including field hints and sections
    public func loadHintsResult(for modelName: String) -> DataHintsResult {
        // Check actor-local cache first
        if let cached = resultCache[modelName] {
            // Only update shared cache if NOT preloaded (before preload, can write)
            // After preload, shared cache is read-only - lazy-loaded hints stay in actor-local cache only
            if !Self.hintsPreloaded {
                Self.preloadLock.lock()
                if Self.sharedResultCache[modelName] == nil {
                    Self.sharedResultCache[modelName] = cached
                }
                Self.preloadLock.unlock()
            }
            return cached
        }
        
        // Check shared cache (might have been preloaded)
        // Access is protected by lock for thread safety
        Self.preloadLock.lock()
        let sharedCached = Self.sharedResultCache[modelName]
        Self.preloadLock.unlock()
        
        if let sharedCached = sharedCached {
            resultCache[modelName] = sharedCached
            cache[modelName] = sharedCached.fieldHints
            return sharedCached
        }
        
        // Load from file (fallback if not preloaded - should be rare in tests)
        let result = loader.loadHintsResult(for: modelName)
        
        // Cache for future use (actor-local cache always, shared cache only before preload)
        // Only cache file-based hints - code-provided hints are handled separately
        if !result.fieldHints.isEmpty || !result.sections.isEmpty {
            resultCache[modelName] = result
            cache[modelName] = result.fieldHints
            
            // Update shared cache only if NOT preloaded (with lock protection)
            // After preload, lazy-loaded hints stay in actor-local cache only
            if !Self.hintsPreloaded {
                Self.preloadLock.lock()
                Self.sharedResultCache[modelName] = result
                Self.preloadLock.unlock()
            }
        }
        
        return result
    }
    
    /// Check if hints exist for a model
    public func hasHints(for modelName: String) -> Bool {
        if cache[modelName] != nil {
            return true
        }
        
        if let fileLoader = loader as? FileBasedDataHintsLoader {
            return fileLoader.hasHints(for: modelName)
        }
        
        return false
    }
    
    /// Clear cache for a specific model
    public func clearCache(for modelName: String) {
        cache.removeValue(forKey: modelName)
    }
    
    /// Clear all cached hints
    public func clearAllCache() {
        cache.removeAll()
        resultCache.removeAll()
    }
    
    /// Preload hints for a model to ensure they're cached before use
    /// This is useful for eager loading to avoid delays during view instantiation
    /// Returns immediately if already cached, otherwise loads and caches
    /// NOTE: Only updates shared cache if NOT preloaded - after preload, shared cache is read-only
    public func preloadHints(for modelName: String) {
        // Check shared cache first (protected by lock)
        Self.preloadLock.lock()
        let existingCached = Self.sharedResultCache[modelName]
        let isPreloaded = Self.hintsPreloaded
        Self.preloadLock.unlock()
        
        if let sharedCached = existingCached {
            // Already in shared cache - update actor-local cache for consistency
            resultCache[modelName] = sharedCached
            cache[modelName] = sharedCached.fieldHints
            return
        }
        
        // If already preloaded, don't write to shared cache (it's read-only)
        // Just update actor-local cache if needed
        if isPreloaded {
            if resultCache[modelName] == nil {
                let result = loader.loadHintsResult(for: modelName)
                if !result.fieldHints.isEmpty || !result.sections.isEmpty {
                    resultCache[modelName] = result
                    cache[modelName] = result.fieldHints
                }
            }
            return
        }
        
        // Before preload: can write to shared cache (with lock protection)
        // Check actor-local cache first
        if resultCache[modelName] != nil {
            // Update shared cache so other threads can access it synchronously
            Self.preloadLock.lock()
            if !Self.hintsPreloaded {
                Self.sharedResultCache[modelName] = resultCache[modelName]
            }
            Self.preloadLock.unlock()
            return
        }
        
        // Load and cache (updates both caches for cross-thread access)
        let result = loader.loadHintsResult(for: modelName)
        if !result.fieldHints.isEmpty || !result.sections.isEmpty {
            resultCache[modelName] = result
            cache[modelName] = result.fieldHints
            
            // Update shared cache (with lock protection, only before preload)
            Self.preloadLock.lock()
            if !Self.hintsPreloaded {
                Self.sharedResultCache[modelName] = result
            }
            Self.preloadLock.unlock()
        }
    }
    
    /// Preload all hints files once at test suite startup
    /// This should be called once before any tests run to load all hints files
    /// After this, the shared cache is read-only and all reads are lock-free
    /// Thread-safe: Uses a lock during preload, then cache becomes immutable
    nonisolated public static func preloadAllHintsSync(modelNames: [String]) {
        // If already preloaded, skip (idempotent)
        if hintsPreloaded {
            return
        }
        
        // Use lock during preload phase (writes happening)
        // After preload, cache is read-only so no locking needed for reads
        preloadLock.lock()
        defer { preloadLock.unlock() }
        
        // Double-check after acquiring lock
        if hintsPreloaded {
            return
        }
        
        // Load all hints files once
        // Optimize: Skip file system checks if already cached
        let loader = FileBasedDataHintsLoader()
        for modelName in modelNames {
            // Fast path: Already cached - skip all file system operations
            if sharedResultCache[modelName] != nil {
                continue
            }
            
            // Only check file existence if not cached (avoids slow bundle.url calls)
            // Check if hints file exists before trying to load (faster than trying to load non-existent files)
            if loader.hasHints(for: modelName) {
                let result = loader.loadHintsResult(for: modelName)
                if !result.fieldHints.isEmpty || !result.sections.isEmpty {
                    sharedResultCache[modelName] = result
                }
            }
            // If hints don't exist, skip loading (avoids slow file system checks for non-existent files)
        }
        
        // Mark as preloaded - shared cache is now read-only (no more writes allowed)
        // All future reads are lock-free and safe
        hintsPreloaded = true
    }
    
    /// Preload hints for multiple models at once
    /// Useful for batch loading during app startup or test setup
    public func preloadHints(for modelNames: [String]) {
        for modelName in modelNames {
            preloadHints(for: modelName)
        }
    }
}

// MARK: - Section Builder Helper

/// Helper to build DynamicFormSection instances from hints sections, matching fields by ID
/// REFACTOR: Optimized field mapping and cleaner error handling
public enum SectionBuilder {
    /// Build sections from hints, matching field IDs to actual DynamicFormField instances
    /// - Parameters:
    ///   - hintsSections: Sections parsed from hints file (with field IDs in metadata)
    ///   - fields: Actual DynamicFormField instances to match
    /// - Returns: Sections with matched fields, preserving field order from hints
    public static func buildSections(
        from hintsSections: [DynamicFormSection],
        matching fields: [DynamicFormField]
    ) -> [DynamicFormSection] {
        // DRY: Create field map once for O(1) lookups
        let fieldMap = Dictionary(uniqueKeysWithValues: fields.map { ($0.id, $0) })
        
        var builtSections: [DynamicFormSection] = []
        
        for hintsSection in hintsSections {
            // Extract field IDs from metadata
            guard let fieldIdsString = hintsSection.metadata?["_fieldIds"] else {
                // No fields specified - create empty section
                builtSections.append(hintsSection)
                continue
            }
            
            // Parse and match fields in order specified in hints (DRY)
            let fieldIds = fieldIdsString
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
            
            let matchedFields = fieldIds.compactMap { fieldMap[$0] }
            let missingFields = fieldIds.filter { fieldMap[$0] == nil }
            
            // Warn about missing fields (graceful degradation)
            if !missingFields.isEmpty {
                print("⚠️ Warning: Section '\(hintsSection.title)' (id: \(hintsSection.id)) references fields that don't exist: \(missingFields.joined(separator: ", ")). These fields will be ignored.")
            }
            
            // Create section with matched fields
            var updatedMetadata = hintsSection.metadata ?? [:]
            updatedMetadata.removeValue(forKey: "_fieldIds") // Remove temporary field IDs storage
            
            let builtSection = DynamicFormSection(
                id: hintsSection.id,
                title: hintsSection.title,
                description: hintsSection.description,
                fields: matchedFields,
                isCollapsible: hintsSection.isCollapsible,
                isCollapsed: hintsSection.isCollapsed,
                metadata: updatedMetadata.isEmpty ? nil : updatedMetadata,
                layoutStyle: hintsSection.layoutStyle
            )
            
            builtSections.append(builtSection)
        }
        
        return builtSections
    }
}

// MARK: - Convenience Global Registry

/// Global registry instance for data hints
public let globalDataHintsRegistry = DataHintsRegistry()

// MARK: - Extensions

public extension PresentationHints {
    /// Create hints with field hints loaded from a data model's .hints file
    init(
        dataType: DataTypeHint = .generic,
        presentationPreference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        context: PresentationContext = .dashboard,
        customPreferences: [String: String] = [:],
        modelName: String,
        registry: DataHintsRegistry = globalDataHintsRegistry,
        colorMapping: [ObjectIdentifier: Color]? = nil,
        itemColorProvider: (@Sendable (any CardDisplayable) -> Color?)? = nil,
        defaultColor: Color? = nil
    ) async {
        let hintsResult = await registry.loadHintsResult(for: modelName)
        let fieldHints = hintsResult.fieldHints
        
        // Parse color configuration from hints file
        let finalColorMapping = colorMapping
        var finalDefaultColor = defaultColor
        var finalItemColorProvider = itemColorProvider
        
        // If hints file has color config, use it (but allow override via parameters)
        if let hintsDefaultColor = hintsResult.defaultColor {
            finalDefaultColor = finalDefaultColor ?? Self.parseColorFromString(hintsDefaultColor)
        }
        
        // Convert itemColorProvider config from hints file to closure
        if let config = hintsResult.itemColorProviderConfig, finalItemColorProvider == nil {
            finalItemColorProvider = Self.createItemColorProvider(from: config)
        }
        
        // Parse presentation properties from hints file (allow override via parameters)
        // Use hints file values when code parameters are at their defaults
        var finalDataType = dataType
        var finalComplexity = complexity
        var finalContext = context
        var finalCustomPreferences = customPreferences
        var finalPresentationPreference = presentationPreference
        
        // Use hints file value if code parameter is at default
        if let hintsDataType = hintsResult.dataType, dataType == .generic {
            if let parsed = Self.parseDataTypeFromString(hintsDataType) {
                finalDataType = parsed
            }
        }
        
        if let hintsComplexity = hintsResult.complexity, complexity == .moderate {
            if let parsed = Self.parseComplexityFromString(hintsComplexity) {
                finalComplexity = parsed
            }
        }
        
        if let hintsContext = hintsResult.context, context == .dashboard {
            if let parsed = Self.parseContextFromString(hintsContext) {
                finalContext = parsed
            }
        }
        
        if let hintsCustomPreferences = hintsResult.customPreferences {
            // Merge: hints file values are defaults, code parameters override
            var merged = hintsCustomPreferences
            for (key, value) in customPreferences {
                merged[key] = value
            }
            finalCustomPreferences = merged
        }
        
        if let hintsPresentationPreference = hintsResult.presentationPreference, finalPresentationPreference == .automatic {
            finalPresentationPreference = Self.parsePresentationPreference(from: hintsPresentationPreference)
        }
        
        // Convert type name -> color string mapping to ObjectIdentifier -> Color mapping
        // Note: We can't resolve ObjectIdentifier from type name at runtime without
        // additional type registry. For now, hints file colorMapping is stored but not
        // automatically converted. Developers should use the colorMapping parameter for
        // ObjectIdentifier-based mapping.
        // TODO: Consider adding a type registry to support type name -> ObjectIdentifier mapping
        
        self.init(
            dataType: finalDataType,
            presentationPreference: finalPresentationPreference,
            complexity: finalComplexity,
            context: finalContext,
            customPreferences: finalCustomPreferences,
            fieldHints: fieldHints,
            colorMapping: finalColorMapping,
            itemColorProvider: finalItemColorProvider,
            defaultColor: finalDefaultColor
        )
    }
    
    /// Parse dataType string to DataTypeHint enum
    private static func parseDataTypeFromString(_ string: String) -> DataTypeHint? {
        return DataTypeHint(rawValue: string.lowercased())
    }
    
    /// Parse complexity string to ContentComplexity enum
    private static func parseComplexityFromString(_ string: String) -> ContentComplexity? {
        return ContentComplexity(rawValue: string.lowercased())
    }
    
    /// Parse context string to PresentationContext enum
    private static func parseContextFromString(_ string: String) -> PresentationContext? {
        return PresentationContext(rawValue: string.lowercased())
    }
    
    /// Parse presentationPreference config to PresentationPreference enum
    private static func parsePresentationPreference(from config: PresentationPreferenceConfig) -> PresentationPreference {
        switch config {
        case .simple(let string):
            // Map string to enum case
            switch string.lowercased() {
            case "automatic": return .automatic
            case "minimal": return .minimal
            case "moderate": return .moderate
            case "rich": return .rich
            case "custom": return .custom
            case "detail": return .detail
            case "modal": return .modal
            case "navigation": return .navigation
            case "list": return .list
            case "masonry": return .masonry
            case "standard": return .standard
            case "form": return .form
            case "card": return .card
            case "cards": return .cards
            case "compact": return .compact
            case "grid": return .grid
            case "chart": return .chart
            case "coverflow": return .coverFlow
            default: return .automatic
            }
        case .countBased(let lowCount, let highCount, let threshold):
            let lowPref = parsePresentationPreference(from: .simple(lowCount))
            let highPref = parsePresentationPreference(from: .simple(highCount))
            return .countBased(lowCount: lowPref, highCount: highPref, threshold: threshold)
        }
    }
    
    #if canImport(SwiftUI)
    /// Create an item color provider closure from hints file configuration
    private static func createItemColorProvider(from config: ItemColorProviderConfig) -> (@Sendable (any CardDisplayable) -> Color?)? {
        return { item in
            // Use Mirror to extract property values
            let mirror = Mirror(reflecting: item)
            
            // Helper to find case-insensitive match in mapping
            func findColor(in mapping: [String: String], for value: String) -> String? {
                let lowercasedValue = value.lowercased()
                // First try exact lowercase match
                if let color = mapping[lowercasedValue] {
                    return color
                }
                // Then try case-insensitive match against all keys
                for (key, color) in mapping {
                    if key.lowercased() == lowercasedValue {
                        return color
                    }
                }
                return nil
            }
            
            // Check primary property (e.g., "severity")
            if let typeProperty = config.type {
                for child in mirror.children {
                    if child.label == typeProperty,
                       let value = child.value as? String,
                       let colorString = findColor(in: config.mapping, for: value) {
                        return Self.parseColorFromString(colorString)
                    }
                }
            } else {
                // If no type specified, check all properties against mapping
                for child in mirror.children {
                    if let _ = child.label,
                       let value = child.value as? String,
                       let colorString = findColor(in: config.mapping, for: value) {
                        return Self.parseColorFromString(colorString)
                    }
                }
            }
            
            // Check status mapping if available
            if let statusMapping = config.statusMapping {
                for child in mirror.children {
                    if child.label == "status",
                       let value = child.value as? String,
                       let colorString = findColor(in: statusMapping, for: value) {
                        return Self.parseColorFromString(colorString)
                    }
                }
            }
            
            return nil
        }
    }
    
    /// Parse a color string (named color or hex) into a Color
    private static func parseColorFromString(_ colorString: String) -> Color? {
        let trimmed = colorString.trimmingCharacters(in: .whitespaces)
        
        // Try hex format first (#RRGGBB or #RGB)
        if trimmed.hasPrefix("#") {
            return Color(hex: trimmed)
        }
        
        // Try named colors
        let lowercased = trimmed.lowercased()
        switch lowercased {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .gray
        case "black": return .black
        case "white": return .white
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        default: return nil
        }
    }
    #else
    private static func parseColorFromString(_ colorString: String) -> Color? {
        return nil // SwiftUI not available
    }
    #endif
}

public extension EnhancedPresentationHints {
    /// Create enhanced hints with field hints loaded from a data model's .hints file
    init(
        dataType: DataTypeHint,
        presentationPreference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        context: PresentationContext = .dashboard,
        customPreferences: [String: String] = [:],
        extensibleHints: [ExtensibleHint] = [],
        modelName: String,
        registry: DataHintsRegistry = globalDataHintsRegistry
    ) async {
        let fieldHints = await registry.loadHints(for: modelName)
        
        self.init(
            dataType: dataType,
            presentationPreference: presentationPreference,
            complexity: complexity,
            context: context,
            customPreferences: customPreferences,
            extensibleHints: extensibleHints,
            fieldHints: fieldHints
        )
    }
}

