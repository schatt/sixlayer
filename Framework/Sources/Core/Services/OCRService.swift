//
//  OCRService.swift
//  SixLayerFramework
//
//  OCR Service - Business Logic Layer
//  Proper separation of concerns with async/await patterns
//

import Foundation
import SwiftUI

#if canImport(Vision) && !os(watchOS)
import Vision
#endif

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - OCR Error Types

/// OCR-specific error types
public enum OCRError: Error, LocalizedError {
    case visionUnavailable
    case invalidImage
    case noTextFound
    case processingFailed
    case unsupportedPlatform
    
    public var errorDescription: String? {
        let i18n = InternationalizationService()
        switch self {
        case .visionUnavailable:
            return i18n.localizedString(for: "SixLayerFramework.ocr.visionUnavailable")
        case .invalidImage:
            return i18n.localizedString(for: "SixLayerFramework.ocr.invalidImage")
        case .noTextFound:
            return i18n.localizedString(for: "SixLayerFramework.ocr.noTextFound")
        case .processingFailed:
            return i18n.localizedString(for: "SixLayerFramework.ocr.processingFailed")
        case .unsupportedPlatform:
            return i18n.localizedString(for: "SixLayerFramework.ocr.unsupportedPlatform")
        }
    }
}

// MARK: - OCR Service Protocol

/// Protocol defining OCR service capabilities
public protocol OCRServiceProtocol: Sendable {
    /// Process an image for text recognition
    func processImage(
        _ image: PlatformImage,
        context: OCRContext,
        strategy: OCRStrategy
    ) async throws -> OCRResult
    
    /// Check if OCR is available on current platform
    var isAvailable: Bool { get }
    
    /// Get platform-specific OCR capabilities
    var capabilities: OCRCapabilities { get }
}

// MARK: - OCR Capabilities

/// Platform-specific OCR capabilities
public struct OCRCapabilities {
    public let supportsVision: Bool
    public let supportedLanguages: [OCRLanguage]
    public let supportedTextTypes: [TextType]
    public let maxImageSize: CGSize
    public let processingTimeEstimate: TimeInterval
    
    public init(
        supportsVision: Bool,
        supportedLanguages: [OCRLanguage],
        supportedTextTypes: [TextType],
        maxImageSize: CGSize,
        processingTimeEstimate: TimeInterval
    ) {
        self.supportsVision = supportsVision
        self.supportedLanguages = supportedLanguages
        self.supportedTextTypes = supportedTextTypes
        self.maxImageSize = maxImageSize
        self.processingTimeEstimate = processingTimeEstimate
    }
}

// MARK: - OCR Service Implementation

/// Main OCR service implementation
public class OCRService: OCRServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    public var isAvailable: Bool {
        return isVisionOCRAvailable()
    }
    
    public var capabilities: OCRCapabilities {
        return getOCRCapabilities()
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    
    // MARK: - Public Methods
    
    /// Process an image for text recognition
    public func processImage(
        _ image: PlatformImage,
        context: OCRContext,
        strategy: OCRStrategy
    ) async throws -> OCRResult {
        try await performVisionOCRIfAvailable(
            image: image,
            context: context,
            strategy: strategy
        ).result
    }
    
    /// Process an image for structured data extraction
    public func processStructuredExtraction(
        _ image: PlatformImage,
        context: OCRContext
    ) async throws -> OCRResult {
        let structuredStrategy = OCRStrategy(
            supportedTextTypes: context.visionStrategySupportedTextTypes,
            supportedLanguages: [context.language],
            processingMode: .accurate
        )
        let visionOutcome = try await performVisionOCRIfAvailable(
            image: image,
            context: context,
            strategy: structuredStrategy
        )
        let baseResult = visionOutcome.result
        
        // Perform structured extraction
        var structuredData = extractStructuredData(from: baseResult, context: context)
        var adjustedFields: [String: String] = [:]
        
        // Apply decimal correction heuristic based on expected ranges
        let (correctedData, decimalAdjustments) = correctDecimalPlacement(in: structuredData, context: context)
        structuredData = correctedData
        adjustedFields.merge(decimalAdjustments) { _, new in new }
        
        // Validate extracted values against expected ranges (guidelines, not hard requirements)
        let (validatedData, rangeWarnings) = validateFieldRanges(in: structuredData, context: context)
        structuredData = validatedData
        adjustedFields.merge(rangeWarnings) { existing, new in
            // Combine warnings if field already has an adjustment
            "\(existing). \(new)"
        }
        
        // Apply calculation groups to derive missing values
        var calculatedFields: [String: String] = [:]
        if context.extractionMode == .automatic || context.extractionMode == .hybrid {
            let (calculatedData, calculatedAdjustments) = applyCalculationGroups(to: structuredData, context: context)
            structuredData = calculatedData
            calculatedFields = calculatedAdjustments
        }
        adjustedFields.merge(calculatedFields) { _, new in new }
        
        let extractionConfidence = calculateExtractionConfidence(structuredData, context: context)
        let missingFields = findMissingRequiredFields(structuredData, context: context)
        
        let structuredValues = Set(
            structuredData.values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        )
        let uncategorized = OCRUncategorizedExtractionBuilder.build(
            recognizedLines: visionOutcome.recognizedLineTexts,
            structuredValues: structuredValues
        )
        
        return OCRResult(
            extractedText: baseResult.extractedText,
            confidence: baseResult.confidence,
            boundingBoxes: baseResult.boundingBoxes,
            textTypes: baseResult.textTypes,
            processingTime: baseResult.processingTime,
            language: baseResult.language,
            structuredData: structuredData,
            extractionConfidence: extractionConfidence,
            missingRequiredFields: missingFields,
            adjustedFields: adjustedFields,
            uncategorizedExtractions: uncategorized
        )
    }
    
    private func performVisionOCRIfAvailable(
        image: PlatformImage,
        context: OCRContext,
        strategy: OCRStrategy
    ) async throws -> (result: OCRResult, recognizedLineTexts: [String]) {
        guard isAvailable else {
            throw OCRError.visionUnavailable
        }
        guard let cgImage = getCGImage(from: image) else {
            throw OCRError.invalidImage
        }
        #if canImport(Vision) && !os(watchOS)
        return try await performVisionOCR(
            cgImage: cgImage,
            context: context,
            strategy: strategy
        )
        #else
        throw OCRError.unsupportedPlatform
        #endif
    }
    
    // MARK: - Structured Extraction Helper Methods
    
    private func extractStructuredData(from result: OCRResult, context: OCRContext) -> [String: String] {
        var structuredData: [String: String] = [:]
        
        // Get patterns for extraction
        let patterns = getPatterns(for: context)
        
        // Extract data using patterns (hints-based extraction or custom extractionHints)
        for (field, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: result.extractedText.utf16.count)
                // Try to find all matches (not just first) to handle multiple occurrences
                let matches = regex.matches(in: result.extractedText, options: [], range: range)
                for match in matches {
                    // Bidirectional pattern structure:
                    // Group 1: entire match
                    // Group 2: hint (if hint comes first)
                    // Group 3: number (if hint comes first)
                    // Group 4: number (if number comes first)
                    // Group 5: hint (if number comes first)
                    var value: String?
                    
                    // Check if hint-first pattern matched (group 3 has the number)
                    if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound {
                        if let valueRange = Range(match.range(at: 3), in: result.extractedText) {
                            value = String(result.extractedText[valueRange])
                        }
                    }
                    // Check if number-first pattern matched (group 4 has the number)
                    else if match.numberOfRanges > 4, match.range(at: 4).location != NSNotFound {
                        if let valueRange = Range(match.range(at: 4), in: result.extractedText) {
                            value = String(result.extractedText[valueRange])
                        }
                    }
                    // Fallback: old pattern format (group 2 has the number)
                    else if match.numberOfRanges > 2, let valueRange = Range(match.range(at: 2), in: result.extractedText) {
                        value = String(result.extractedText[valueRange])
                    }
                    
                    if let value = value, structuredData[field] == nil {
                        structuredData[field] = value
                    }
                }
            }
        }
        
        // Note: We no longer add generic text types (like "price", "number") to structuredData
        // Developers should use hints files (entityName) or custom extractionHints for explicit field mapping
        // This prevents confusion and ensures structuredData contains only explicitly mapped fields
        
        return structuredData
    }
    
    private func getPatterns(for context: OCRContext) -> [String: String] {
        var patterns: [String: String] = [:]
        
        // Automatically load hints file if extractionMode is automatic or hybrid
        if context.extractionMode == .automatic || context.extractionMode == .hybrid {
            let hintsPatterns = loadHintsPatterns(for: context)
            // Hints file patterns are the base patterns
            for (key, value) in hintsPatterns {
                patterns[key] = value
            }
        }
        
        // Override with custom hints if provided (highest priority)
        for (key, value) in context.extractionHints {
            patterns[key] = value
        }
        
        // Only extract fields that are explicitly requested via extractionHints
        // This prevents extracting unwanted fields and makes intent clear
        // With calculation groups, fields can't be "required" since any subset can calculate the rest
        if !context.extractionHints.isEmpty {
            var filteredPatterns: [String: String] = [:]
            for (key, value) in patterns {
                if context.extractionHints.keys.contains(key) {
                    filteredPatterns[key] = value
                }
            }
            return filteredPatterns
        }
        
        return patterns
    }
    
    /// Load hints file and convert ocrHints to regex patterns
    private func loadHintsPatterns(for context: OCRContext) -> [String: String] {
        // Use entityName from context - projects specify which data model's hints to use
        // If nil, return empty patterns (developer opted out of hints-based extraction)
        guard let entityName = context.entityName else {
            return [:] // No hints file loading - developer doesn't need/want hints
        }
        
        let loader = FileBasedDataHintsLoader()
        let hintsResult = loader.loadHintsResult(for: entityName, locale: Locale(identifier: context.language.rawValue))
        
        var patterns: [String: String] = [:]
        
        // Convert ocrHints to regex patterns
        for (fieldId, fieldHints) in hintsResult.fieldHints {
            if let ocrHints = fieldHints.ocrHints, !ocrHints.isEmpty {
                // Create regex pattern from ocrHints
                // Pattern supports bidirectional matching: hint before number OR number before hint
                // This handles cases where Vision reads text in different orders
                // Pattern: (?i)((hint1|hint2|hint3)\s*[:=]?\s*([\d.,]+)|([\d.,]+)\s+(hint1|hint2|hint3))
                let escapedHints = ocrHints.map { NSRegularExpression.escapedPattern(for: $0) }
                let hintsGroup = escapedHints.joined(separator: "|")
                
                // Check if any hint is a currency symbol (needs special handling)
                let hasCurrencySymbol = ocrHints.contains { hint in
                    ["$", "€", "£", "¥"].contains(hint)
                }
                
                // For currency symbols, allow optional text between symbol and number
                // For other hints, require closer proximity
                let separatorPattern = hasCurrencySymbol 
                    ? "\\s+(?:[A-Za-z]+\\s+)*"  // Allow text like " This Sale " between $ and number
                    : "\\s*[:=]?\\s*"  // Standard: just whitespace/colon/equals
                
                // Bidirectional pattern: (hint separator number) OR (number separator hint)
                let pattern = "(?i)((\(hintsGroup))\(separatorPattern)([\\d.,]+)|([\\d.,]+)\\s+(\(hintsGroup)))"
                patterns[fieldId] = pattern
            }
        }
        
        return patterns
    }
    
    private func calculateExtractionConfidence(_ structuredData: [String: String], context: OCRContext) -> Float {
        guard !context.requiredFields.isEmpty else {
            return structuredData.isEmpty ? 0.0 : 1.0
        }
        
        let foundFields = context.requiredFields.filter { structuredData.keys.contains($0) }
        return Float(foundFields.count) / Float(context.requiredFields.count)
    }
    
    private func findMissingRequiredFields(_ structuredData: [String: String], context: OCRContext) -> [String] {
        return context.requiredFields.filter { !structuredData.keys.contains($0) }
    }
    
    /// Correct decimal placement in extracted values using expected ranges and calculation groups as heuristics
    /// If a value is outside its expected range and has no decimal point, try inserting decimals
    /// at various positions. Validate corrections using:
    /// 1. Direct range check (if expectedRange is defined)
    /// 2. Inferred range from calculation groups (if field has no explicit range but related fields do)
    /// 3. Calculation group validation (if related fields exist and have ranges)
    /// Returns: (corrected data, adjustments map: fieldId -> description)
    private func correctDecimalPlacement(in structuredData: [String: String], context: OCRContext) -> ([String: String], [String: String]) {
        var correctedData = structuredData
        var adjustments: [String: String] = [:]
        
        // Get hints file data if entityName is provided
        var hintsRanges: [String: ValueRange] = [:]
        var hintsCalculationGroups: [String: [CalculationGroup]] = [:]
        if let entityName = context.entityName {
            let loader = FileBasedDataHintsLoader()
            let hintsResult = loader.loadHintsResult(for: entityName, locale: Locale(identifier: context.language.rawValue))
            for (fieldId, fieldHints) in hintsResult.fieldHints {
                if let range = fieldHints.expectedRange {
                    hintsRanges[fieldId] = range
                }
                if let groups = fieldHints.calculationGroups {
                    hintsCalculationGroups[fieldId] = groups
                }
            }
        }
        
        // Infer ranges for fields that don't have explicit ranges but have calculation groups
        // Example: totalCost = pricePerGallon * gallons
        // If pricePerGallon has range 0-10 and gallons has range 0-32, then totalCost inferred range is 0-320
        let inferredRanges = inferRangesFromCalculationGroups(
            hintsRanges: hintsRanges,
            hintsCalculationGroups: hintsCalculationGroups,
            context: context
        )
        
        // Merge explicit and inferred ranges (explicit takes precedence)
        var allRanges = inferredRanges
        for (fieldId, range) in hintsRanges {
            allRanges[fieldId] = range // Explicit ranges override inferred
        }
        // Runtime overrides take highest precedence
        if let overrideRanges = context.fieldRanges {
            for (fieldId, range) in overrideRanges {
                allRanges[fieldId] = range
            }
        }
        
        // Try to correct each extracted value
        for (fieldId, valueString) in structuredData {
            // Skip if value already has a decimal point or comma
            guard !valueString.contains(".") && !valueString.contains(",") else {
                continue
            }
            
            // Try to parse as integer (no decimals)
            guard let intValue = Int(valueString) else {
                continue // Not a numeric value
            }
            
            // Get range: override first, then hints file
            let range: ValueRange?
            if let overrideRange = context.fieldRanges?[fieldId] {
                range = overrideRange
            } else {
                range = hintsRanges[fieldId]
            }
            
            let doubleValue = Double(intValue)
            
            // If value is already in range, no correction needed
            if let range = range, range.contains(doubleValue) {
                continue
            }
            
            // Try inserting decimal point at various positions
            // For "3288", try: "32.88", "3.288", "328.8", "3288.0"
            let valueChars = Array(valueString)
            var candidateCorrections: [(value: String, score: Double)] = []
            
            // Try decimal positions from right to left (most common: 2 decimal places)
            for decimalPos in 1..<valueChars.count {
                var correctedChars = valueChars
                correctedChars.insert(".", at: valueChars.count - decimalPos)
                let correctedString = String(correctedChars)
                
                guard let correctedValue = Double(correctedString) else {
                    continue
                }
                
                var score: Double = 0.0
                var isValid = false
                
                // Check 1: Direct range validation (if range is defined)
                if let range = range {
                    if range.contains(correctedValue) {
                        isValid = true
                        // Prefer values closer to average (if provided) or middle of range
                        let preferredValue: Double
                        if let average = context.fieldAverages?[fieldId] {
                            preferredValue = average
                        } else {
                            preferredValue = (range.min + range.max) / 2.0
                        }
                        let distance = abs(correctedValue - preferredValue)
                        let rangeSize = range.max - range.min
                        score += (1.0 - (distance / rangeSize)) * 10.0 // Up to 10 points
                    }
                } else {
                    // No direct range, but we can still try calculation validation
                    isValid = true // Allow it if calculation validation passes
                }
                
                // Check 2: Calculation group validation
                // If this field is part of calculation groups, validate by calculating related fields
                if let groups = hintsCalculationGroups[fieldId] {
                    for group in groups {
                        // Check if we can calculate a related field using this correction
                        let testData = correctedData.merging([fieldId: correctedString]) { _, new in new }
                        
                        // Try to calculate each dependent field and check if result is in range
                        for dependentField in group.dependentFields {
                            if dependentField != fieldId, let dependentRange = allRanges[dependentField] {
                                // Try to calculate this dependent field using the corrected value
                                if let calculatedValue = evaluateCalculationGroupForField(
                                    fieldId: dependentField,
                                    group: group,
                                    fieldValues: testData
                                ) {
                                    if dependentRange.contains(calculatedValue) {
                                        isValid = true
                                        score += 5.0 // Bonus points for calculation validation
                                    }
                                }
                            }
                        }
                        
                        // Also check if other fields can calculate this corrected value
                        // (reverse calculation: if totalCost = pricePerGallon * gallons, and we have gallons and pricePerGallon,
                        //  we can verify the corrected totalCost matches)
                        if let calculatedValue = evaluateCalculationGroupForField(
                            fieldId: fieldId,
                            group: group,
                            fieldValues: testData
                        ) {
                            // If calculation matches our corrected value (within tolerance), it's valid
                            if abs(calculatedValue - correctedValue) < 0.01 {
                                isValid = true
                                score += 5.0
                            }
                        }
                    }
                }
                
                if isValid {
                    candidateCorrections.append((correctedString, score))
                }
            }
            
            // Apply the best correction (highest score)
            if let bestCorrection = candidateCorrections.max(by: { $0.score < $1.score }) {
                let originalValue = valueString
                let correctedValue = bestCorrection.value
                correctedData[fieldId] = correctedValue
                adjustments[fieldId] = "Decimal point corrected: '\(originalValue)' → '\(correctedValue)' (inferred from expected range)"
            }
        }
        
        return (correctedData, adjustments)
    }
    
    /// Infer expected ranges for fields that don't have explicit ranges but have calculation groups
    /// Example: If totalCost = pricePerGallon * gallons, and we know:
    ///   - pricePerGallon range: 0-10
    ///   - gallons range: 0-32
    /// Then totalCost inferred range: 0-320 (10 * 32)
    private func inferRangesFromCalculationGroups(
        hintsRanges: [String: ValueRange],
        hintsCalculationGroups: [String: [CalculationGroup]],
        context: OCRContext
    ) -> [String: ValueRange] {
        var inferredRanges: [String: ValueRange] = [:]
        
        // Collect all calculation groups
        var allGroups: [(targetField: String, group: CalculationGroup)] = []
        for (_, groups) in hintsCalculationGroups {
            for group in groups {
                // Parse target field from formula: "target = expression"
                let parts = group.formula.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    let targetField = parts[0]
                    allGroups.append((targetField: targetField, group: group))
                }
            }
        }
        
        // For each field that doesn't have an explicit range, try to infer from calculation groups
        for (targetField, group) in allGroups {
            // Skip if field already has explicit range
            if hintsRanges[targetField] != nil || context.fieldRanges?[targetField] != nil {
                continue
            }
            
            // Check if all dependent fields have ranges
            var dependentRanges: [String: ValueRange] = [:]
            for dependentField in group.dependentFields {
                if let range = hintsRanges[dependentField] ?? context.fieldRanges?[dependentField] {
                    dependentRanges[dependentField] = range
                } else {
                    // Missing range for a dependent field, can't infer
                    break
                }
            }
            
            // If we have ranges for all dependent fields, infer the target field's range
            if dependentRanges.count == group.dependentFields.count {
                if let inferredRange = calculateRangeFromFormula(
                    formula: group.formula,
                    targetField: targetField,
                    dependentRanges: dependentRanges
                ) {
                    inferredRanges[targetField] = inferredRange
                }
            }
        }
        
        return inferredRanges
    }
    
    /// Calculate the range for a target field based on a formula and dependent field ranges
    /// Supports basic operations: +, -, *, /
    /// Example: totalCost = pricePerGallon * gallons
    ///   If pricePerGallon: 0-10, gallons: 0-32
    ///   Then totalCost: 0-320 (min: 0*0, max: 10*32)
    private func calculateRangeFromFormula(
        formula: String,
        targetField: String,
        dependentRanges: [String: ValueRange]
    ) -> ValueRange? {
        // Parse the formula: "target = expression"
        let parts = formula.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, parts[0] == targetField else { return nil }
        
        let expression = parts[1]
        
        // Simple range calculation for basic operations
        // For multiplication: min = min1 * min2, max = max1 * max2 (if all positive)
        // For addition: min = min1 + min2, max = max1 + max2
        // For subtraction: min = min1 - max2, max = max1 - min2
        // For division: min = min1 / max2, max = max1 / min2 (if all positive)
        
        // Try to identify the operation and operands
        if expression.contains("*") {
            let operands = expression.split(separator: "*").map { $0.trimmingCharacters(in: .whitespaces) }
            if operands.count == 2,
               let range1 = dependentRanges[operands[0]],
               let range2 = dependentRanges[operands[1]] {
                // Multiplication: consider all combinations
                let combinations = [
                    range1.min * range2.min,
                    range1.min * range2.max,
                    range1.max * range2.min,
                    range1.max * range2.max
                ]
                return ValueRange(min: combinations.min()!, max: combinations.max()!)
            }
        } else if expression.contains("+") {
            let operands = expression.split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }
            if operands.count == 2,
               let range1 = dependentRanges[operands[0]],
               let range2 = dependentRanges[operands[1]] {
                return ValueRange(min: range1.min + range2.min, max: range1.max + range2.max)
            }
        } else if expression.contains("-") {
            let operands = expression.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            if operands.count == 2,
               let range1 = dependentRanges[operands[0]],
               let range2 = dependentRanges[operands[1]] {
                return ValueRange(min: range1.min - range2.max, max: range1.max - range2.min)
            }
        } else if expression.contains("/") {
            let operands = expression.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
            if operands.count == 2,
               let range1 = dependentRanges[operands[0]],
               let range2 = dependentRanges[operands[1]],
               range2.min > 0, range2.max > 0 { // Avoid division by zero
                // Division: consider all combinations
                let combinations = [
                    range1.min / range2.max,
                    range1.min / range2.min,
                    range1.max / range2.max,
                    range1.max / range2.min
                ]
                return ValueRange(min: combinations.min()!, max: combinations.max()!)
            }
        }
        
        return nil // Unsupported formula format
    }
    
    /// Helper to evaluate a calculation group for a specific field
    private func evaluateCalculationGroupForField(
        fieldId: String,
        group: CalculationGroup,
        fieldValues: [String: String]
    ) -> Double? {
        // Parse the formula: "target = expression"
        let parts = group.formula.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }
        
        // Check if this group can calculate the target field
        let targetField = parts[0]
        guard targetField == fieldId else { return nil }
        
        // Check if all dependent fields are available
        let allDependenciesAvailable = group.dependentFields.allSatisfy { fieldId in
            fieldValues[fieldId] != nil
        }
        guard allDependenciesAvailable else { return nil }
        
        // Replace field references with their values
        var expression = parts[1]
        for dependentField in group.dependentFields {
            if let valueString = fieldValues[dependentField],
               let value = Double(valueString.replacingOccurrences(of: ",", with: "")) {
                expression = expression.replacingOccurrences(of: dependentField, with: String(value))
            } else {
                return nil
            }
        }
        
        // Evaluate the mathematical expression
        return evaluateMathExpression(expression)
    }
    
    /// Validate extracted field values against expected ranges
    /// Expected ranges are GUIDELINES, not hard requirements
    /// Out-of-range values are kept but flagged as questionable
    /// Priority: context.fieldRanges (override) > hints file expectedRange
    /// Returns: (validated data, range warnings: fieldId -> description)
    private func validateFieldRanges(in structuredData: [String: String], context: OCRContext) -> ([String: String], [String: String]) {
        let validatedData = structuredData
        var rangeWarnings: [String: String] = [:]
        
        // Get hints file ranges if entityName is provided
        var hintsRanges: [String: ValueRange] = [:]
        if let entityName = context.entityName {
            let loader = FileBasedDataHintsLoader()
            let hintsResult = loader.loadHintsResult(for: entityName, locale: Locale(identifier: context.language.rawValue))
            for (fieldId, fieldHints) in hintsResult.fieldHints {
                if let range = fieldHints.expectedRange {
                    hintsRanges[fieldId] = range
                }
            }
        }
        
        // Validate each extracted value
        for (fieldId, valueString) in structuredData {
            // Try to parse as numeric value
            guard let numericValue = Double(valueString.replacingOccurrences(of: ",", with: "")) else {
                continue // Not a numeric value, skip range validation
            }
            
            // Get range: override first, then hints file
            let range: ValueRange?
            if let overrideRange = context.fieldRanges?[fieldId] {
                range = overrideRange
            } else {
                range = hintsRanges[fieldId]
            }
            
            // Check if value is outside range or far from average (if provided)
            var shouldFlag = false
            var flagReason = ""
            
            if let range = range, !range.contains(numericValue) {
                // Outside expected range
                shouldFlag = true
                let rangeDescription = "\(range.min) - \(range.max)"
                
                // Check if calculation groups confirm this value (makes it less questionable)
                var confirmedByCalculation = false
                if let entityName = context.entityName {
                    let loader = FileBasedDataHintsLoader()
                    let hintsResult = loader.loadHintsResult(for: entityName, locale: Locale(identifier: context.language.rawValue))
                    if let fieldHints = hintsResult.fieldHints[fieldId],
                       let calculationGroups = fieldHints.calculationGroups {
                        // Try to calculate this field from related fields
                        for group in calculationGroups {
                            if let calculatedValue = evaluateCalculationGroupForField(
                                fieldId: fieldId,
                                group: group,
                                fieldValues: structuredData
                            ) {
                                // If calculated value matches extracted value (within tolerance), it's confirmed
                                if abs(calculatedValue - numericValue) < 0.01 {
                                    confirmedByCalculation = true
                                    break
                                }
                            }
                        }
                    }
                }
                
                if confirmedByCalculation {
                    flagReason = "Value '\(valueString)' is outside expected range (\(rangeDescription)), but confirmed by calculation. Please verify."
                } else {
                    flagReason = "Value '\(valueString)' is outside expected range (\(rangeDescription)). Please verify."
                }
            } else if let average = context.fieldAverages?[fieldId] {
                // Within range, but check if far from average
                let deviation = abs(numericValue - average)
                let percentDeviation = (deviation / average) * 100.0
                
                // Flag if more than 50% deviation from average (configurable threshold)
                if percentDeviation > 50.0 {
                    shouldFlag = true
                    flagReason = "Value '\(valueString)' is within expected range but significantly different from typical value (\(String(format: "%.2f", average))). Deviation: \(String(format: "%.1f", percentDeviation))%. Please verify."
                }
            }
            
            if shouldFlag {
                rangeWarnings[fieldId] = flagReason
                // Note: We keep flagged values because:
                // 1. Expected ranges are guidelines, not absolute limits
                // 2. Calculation groups may confirm the value is correct
                // 3. Real-world scenarios may legitimately fall outside typical ranges
                // 4. Values far from average may still be correct (e.g., expensive gas in remote locations)
            }
        }
        
        return (validatedData, rangeWarnings)
    }
    
    /// Get the expected range for a field (override first, then hints file)
    private func getExpectedRange(for fieldId: String, context: OCRContext) -> ValueRange? {
        // Check override first
        if let overrideRange = context.fieldRanges?[fieldId] {
            return overrideRange
        }
        
        // Check hints file
        guard let entityName = context.entityName else {
            return nil
        }
        
        let loader = FileBasedDataHintsLoader()
        let hintsResult = loader.loadHintsResult(for: entityName, locale: Locale(identifier: context.language.rawValue))
        return hintsResult.fieldHints[fieldId]?.expectedRange
    }
    
    /// Apply calculation groups to derive missing field values
    /// Returns: (calculated data, adjustments map: fieldId -> description)
    private func applyCalculationGroups(to structuredData: [String: String], context: OCRContext) -> ([String: String], [String: String]) {
        var result = structuredData
        var adjustments: [String: String] = [:]
        
        // Use entityName from context - projects specify which data model's hints to use
        // If nil, return data unchanged (developer opted out of hints-based extraction)
        guard let entityName = context.entityName else {
            return (result, [:]) // No calculation groups - developer doesn't need/want hints
        }
        
        let loader = FileBasedDataHintsLoader()
        let hintsResult = loader.loadHintsResult(for: entityName, locale: Locale(identifier: context.language.rawValue))
        
        // Collect all calculation groups, sorted by priority
        var allGroups: [(fieldId: String, group: CalculationGroup)] = []
        for (fieldId, fieldHints) in hintsResult.fieldHints {
            if let calculationGroups = fieldHints.calculationGroups {
                for group in calculationGroups {
                    allGroups.append((fieldId: fieldId, group: group))
                }
            }
        }
        
        // Sort by priority (lower number = higher priority)
        allGroups.sort { $0.group.priority < $1.group.priority }
        
        // Apply calculation groups in priority order
        // Only calculate fields that are explicitly requested via extractionHints
        // This prevents calculating unwanted fields when using hints files with many fields
        let requestedFields = Set(context.extractionHints.keys)
        let shouldFilterCalculations = !requestedFields.isEmpty
        
        for (fieldId, group) in allGroups {
            // Skip if field already has a value
            if result[fieldId] != nil {
                continue
            }
            
            // Only calculate fields that were explicitly requested (if extractionHints is provided)
            if shouldFilterCalculations && !requestedFields.contains(fieldId) {
                continue
            }
            
            // Check if all dependent fields are available
            let allDependenciesAvailable = group.dependentFields.allSatisfy { fieldId in
                result[fieldId] != nil
            }
            
            if allDependenciesAvailable {
                // Calculate the value
                if let calculatedValue = evaluateCalculationGroup(group, fieldValues: result) {
                    result[fieldId] = String(calculatedValue)
                    // Format the calculation for the adjustment message
                    let formula = group.formula
                    adjustments[fieldId] = "Calculated from formula: \(formula) = \(String(format: "%.2f", calculatedValue))"
                }
            }
        }
        
        return (result, adjustments)
    }
    
    /// Evaluate a calculation group formula
    private func evaluateCalculationGroup(_ group: CalculationGroup, fieldValues: [String: String]) -> Double? {
        // Parse the formula: "target = expression"
        let parts = group.formula.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard parts.count == 2 else { return nil }
        let expression = parts[1]
        
        // Replace field references with their numeric values
        var processedExpression = expression
        for fieldId in group.dependentFields {
            if let valueString = fieldValues[fieldId],
               let value = Double(valueString.replacingOccurrences(of: ",", with: "")) {
                processedExpression = processedExpression.replacingOccurrences(of: fieldId, with: String(value))
            } else {
                return nil // Missing dependency or invalid value
            }
        }
        
        // Evaluate the mathematical expression
        return evaluateMathExpression(processedExpression)
    }
    
    /// Evaluate a simple mathematical expression (supports +, -, *, /, parentheses)
    private func evaluateMathExpression(_ expression: String) -> Double? {
        // Use NSExpression for safe evaluation
        let expression = NSExpression(format: expression)
        if let result = expression.expressionValue(with: nil, context: nil) as? Double {
            return result
        } else if let result = expression.expressionValue(with: nil, context: nil) as? Int {
            return Double(result)
        }
        return nil
    }
    
    private func getFieldName(for textType: TextType) -> String {
        switch textType {
        case .price:
            return "price"
        case .date:
            return "date"
        case .number:
            return "number"
        case .name:
            return "name"
        case .idNumber:
            return "idNumber"
        case .stationName:
            return "stationName"
        case .total:
            return "total"
        case .vendor:
            return "vendor"
        case .expiryDate:
            return "expiryDate"
        case .quantity:
            return "quantity"
        case .unit:
            return "unit"
        case .currency:
            return "currency"
        case .percentage:
            return "percentage"
        case .postalCode:
            return "postalCode"
        case .state:
            return "state"
        case .country:
            return "country"
        case .general:
            return "general"
        case .address:
            return "address"
        case .email:
            return "email"
        case .phone:
            return "phone"
        case .url:
            return "url"
        }
    }
    
    // MARK: - Private Methods
    
    #if canImport(Vision) && !os(watchOS)
    private func performVisionOCR(
        cgImage: CGImage,
        context: OCRContext,
        strategy: OCRStrategy
    ) async throws -> (result: OCRResult, recognizedLineTexts: [String]) {
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let outcome = self.processVisionResults(
                    observations: observations,
                    context: context,
                    strategy: strategy
                )
                continuation.resume(returning: outcome)
            }
            
            // Configure request based on strategy
            configureVisionRequest(request, context: context, strategy: strategy)
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func configureVisionRequest(
        _ request: VNRecognizeTextRequest,
        context: OCRContext,
        strategy: OCRStrategy
    ) {
        // Configure recognition level
        switch strategy.processingMode {
        case .fast:
            request.recognitionLevel = .fast
        case .standard:
            request.recognitionLevel = .accurate
        case .accurate:
            request.recognitionLevel = .accurate
        case .neural:
            request.recognitionLevel = .accurate
        }
        
        // Configure language
        request.recognitionLanguages = [context.language.rawValue]
        
        // Configure text types
        if !strategy.supportedTextTypes.isEmpty {
            // Vision framework automatically detects text types
            // We'll filter results based on our text types
        }
        
        // Configure confidence threshold
        request.minimumTextHeight = 0.01 // Minimum text height
    }
    
    private func processVisionResults(
        observations: [VNRecognizedTextObservation],
        context: OCRContext,
        strategy: OCRStrategy
    ) -> (result: OCRResult, recognizedLineTexts: [String]) {
        
        // Sort observations by position (top to bottom, left to right) for proper reading order
        // Vision returns observations in arbitrary order, not reading order
        // Vision uses normalized coordinates where (0,0) is bottom-left, Y increases upward
        // So higher Y = higher on screen = should come first in reading order
        let sortedObservations = observations.sorted { obs1, obs2 in
            let box1 = obs1.boundingBox
            let box2 = obs2.boundingBox
            // First sort by Y coordinate (top to bottom) - higher Y = higher on screen
            if abs(box1.origin.y - box2.origin.y) > 0.05 { // Different rows (5% threshold)
                return box1.origin.y > box2.origin.y // Higher Y = higher on screen = comes first
            }
            // Same row: sort by X coordinate (left to right)
            return box1.origin.x < box2.origin.x
        }
        
        var extractedText = ""
        var recognizedLineTexts: [String] = []
        var boundingBoxes: [CGRect] = []
        var textTypes: [TextType: String] = [:]
        var totalConfidence: Float = 0.0
        var validObservations = 0
        
        for observation in sortedObservations {
            // Get top candidate, but also check multiple candidates for better accuracy
            // Sometimes the top candidate misses decimal points or labels
            let candidates = observation.topCandidates(3) // Get top 3 candidates
            
            guard let topCandidate = candidates.first else { continue }
            
            // Try to find a candidate with decimal points if available
            var bestCandidate = topCandidate
            for candidate in candidates {
                // Prefer candidates that have decimal points or more complete text
                if candidate.string.contains(".") || candidate.string.count > bestCandidate.string.count {
                    if candidate.confidence >= context.confidenceThreshold {
                        bestCandidate = candidate
                        break
                    }
                }
            }
            
            let text = bestCandidate.string
            let confidence = bestCandidate.confidence
            
            // Check confidence threshold
            guard confidence >= context.confidenceThreshold else { continue }
            
            // Filter by text types if specified
            if !strategy.supportedTextTypes.isEmpty {
                let detectedType = OCRTextTypeInference.inferredType(for: text)
                guard strategy.supportedTextTypes.contains(detectedType) else { continue }
            }
            
            extractedText += text + " "
            recognizedLineTexts.append(text)
            boundingBoxes.append(observation.boundingBox)
            textTypes[OCRTextTypeInference.inferredType(for: text)] = text
            
            totalConfidence += confidence
            validObservations += 1
        }
        
        // Calculate average confidence
        let averageConfidence = validObservations > 0 ? totalConfidence / Float(validObservations) : 0.0
        
        let result = OCRResult(
            extractedText: extractedText.trimmingCharacters(in: .whitespacesAndNewlines),
            confidence: averageConfidence,
            boundingBoxes: boundingBoxes,
            textTypes: textTypes,
            processingTime: 0.0, // Will be set by caller
            language: context.language,
            uncategorizedExtractions: []
        )
        return (result, recognizedLineTexts)
    }
    #endif
    
    private func getCGImage(from image: PlatformImage) -> CGImage? {
        #if os(iOS)
        return image.uiImage.cgImage
        #elseif os(macOS)
        return image.nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return nil
        #endif
    }
    
    private func getOCRCapabilities() -> OCRCapabilities {
        #if canImport(Vision)
        #if os(iOS)
        if #available(iOS 11.0, *) {
            return OCRCapabilities(
                supportsVision: true,
                supportedLanguages: [.english, .spanish, .french, .german, .italian, .portuguese, .chinese, .japanese, .korean, .arabic, .russian],
                supportedTextTypes: TextType.allCases,
                maxImageSize: CGSize(width: 4096, height: 4096),
                processingTimeEstimate: 2.0
            )
        }
        #elseif os(macOS)
        if #available(macOS 10.15, *) {
            return OCRCapabilities(
                supportsVision: true,
                supportedLanguages: [.english, .spanish, .french, .german, .italian, .portuguese, .chinese, .japanese, .korean, .arabic, .russian],
                supportedTextTypes: TextType.allCases,
                maxImageSize: CGSize(width: 8192, height: 8192),
                processingTimeEstimate: 1.5
            )
        }
        #endif
        #endif
        
        return OCRCapabilities(
            supportsVision: false,
            supportedLanguages: [],
            supportedTextTypes: [],
            maxImageSize: .zero,
            processingTimeEstimate: 0.0
        )
    }
}

// MARK: - Mock OCR Service

/// Mock OCR service for testing
/// COMMENTED OUT: Force tests to use real Vision framework
/*
public class MockOCRService: OCRServiceProtocol {
    
    public var isAvailable: Bool = true
    
    public var capabilities: OCRCapabilities {
        return OCRCapabilities(
            supportsVision: true,
            supportedLanguages: [.english],
            supportedTextTypes: [.general],
            maxImageSize: CGSize(width: 1000, height: 1000),
            processingTimeEstimate: 0.1
        )
    }
    
    private let mockResult: OCRResult
    
    public init(mockResult: OCRResult? = nil) {
        self.mockResult = mockResult ?? OCRResult(
            extractedText: "Mock OCR Result",
            confidence: 0.95,
            boundingBoxes: [CGRect(x: 0, y: 0, width: 100, height: 20)],
            textTypes: [.general: "Mock OCR Result"],
            processingTime: 0.1,
            language: .english
        )
    }
    
    public func processImage(
        _ image: PlatformImage,
        context: OCRContext,
        strategy: OCRStrategy
    ) async throws -> OCRResult {
        // Simulate validation for testing
        guard let cgImage = getCGImage(from: image) else {
            throw OCRError.invalidImage
        }
        
        // Check if image is too small (simulate invalid image)
        if cgImage.width < 10 || cgImage.height < 10 {
            throw OCRError.invalidImage
        }
        
        // Return immediately for testing - no sleep needed
        // Create a new result with the language from the context
        let result = OCRResult(
            extractedText: mockResult.extractedText,
            confidence: mockResult.confidence,
            boundingBoxes: mockResult.boundingBoxes,
            textTypes: mockResult.textTypes,
            processingTime: 0.0, // No processing time for tests
            language: context.language
        )
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func getCGImage(from image: PlatformImage) -> CGImage? {
        #if os(iOS)
        return image.uiImage.cgImage
        #elseif os(macOS)
        return image.nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return nil
        #endif
    }
    
    // MARK: - Structured Extraction Helper Methods
    
    private func extractStructuredData(from result: OCRResult, context: OCRContext) -> [String: String] {
        var structuredData: [String: String] = [:]
        let text = result.extractedText
        
        // Get patterns based on extraction mode
        let patterns = getPatterns(for: context)
        
        // Apply patterns to extract structured data
        for (fieldName, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    if let matchRange = Range(match.range(at: 1), in: text) {
                        let extractedValue = String(text[matchRange])
                        structuredData[fieldName] = extractedValue
                    }
                }
            }
        }
        
        return structuredData
    }
    
    private func getPatterns(for context: OCRContext) -> [String: String] {
        var patterns: [String: String] = [:]
        
        switch context.extractionMode {
        case .automatic:
            // Automatic mode uses hints file patterns (loaded via entityName) or custom hints
            patterns = context.extractionHints
        case .custom:
            // Use custom extraction hints
            patterns = context.extractionHints
        case .hybrid:
            // Hybrid mode uses hints file patterns with custom hints as overrides
            // Custom patterns override hints file patterns
            for (key, value) in context.extractionHints {
                patterns[key] = value
            }
        }
        
        return patterns
    }
    
    private func calculateExtractionConfidence(_ structuredData: [String: String], context: OCRContext) -> Float {
        let totalFields = context.requiredFields.count
        let extractedFields = context.requiredFields.filter { structuredData[$0] != nil }.count
        
        if totalFields == 0 {
            return 1.0 // No required fields, perfect confidence
        }
        
        return Float(extractedFields) / Float(totalFields)
    }
    
    private func findMissingRequiredFields(_ structuredData: [String: String], context: OCRContext) -> [String] {
        return context.requiredFields.filter { structuredData[$0] == nil }
    }
}
*/

// MARK: - OCR Service Factory

/// Factory for creating OCR services
public class OCRServiceFactory {
    
    /// Create an OCR service instance
    public static func create() -> OCRServiceProtocol {
        return OCRService()
    }
    
    /// Create a mock OCR service for testing
    /// COMMENTED OUT: Force tests to use real Vision framework
    /*
    public static func createMock(result: OCRResult? = nil) -> OCRServiceProtocol {
        return MockOCRService(mockResult: result)
    }
    */
}
