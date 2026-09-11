//
//  OCRDisambiguationTypes.swift
//  SixLayerFramework
//
//  OCR Disambiguation Types
//  Data structures for handling ambiguous OCR results that require user disambiguation
//

import Foundation
import SwiftUI

// MARK: - OCR Data Candidate

/// Represents a single piece of data found by OCR that may need disambiguation
public struct OCRDataCandidate: Identifiable, Equatable, Hashable {
    public let id: String
    public let text: String
    public let boundingBox: CGRect
    public let confidence: Float
    public let suggestedType: TextType
    public let alternativeTypes: [TextType]
    
    public init(
        text: String,
        boundingBox: CGRect,
        confidence: Float,
        suggestedType: TextType,
        alternativeTypes: [TextType]
    ) {
        self.id = "\(text)|\(boundingBox.origin.x)|\(boundingBox.origin.y)|\(boundingBox.size.width)|\(boundingBox.size.height)|\(suggestedType.rawValue)"
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.suggestedType = suggestedType
        self.alternativeTypes = alternativeTypes
    }
    
    // Custom equality that ignores UUID for testing
    public static func == (lhs: OCRDataCandidate, rhs: OCRDataCandidate) -> Bool {
        return lhs.text == rhs.text &&
               lhs.boundingBox == rhs.boundingBox &&
               lhs.confidence == rhs.confidence &&
               lhs.suggestedType == rhs.suggestedType &&
               lhs.alternativeTypes == rhs.alternativeTypes
    }
}

// MARK: - OCR Disambiguation Result

/// Result of OCR processing that may require user disambiguation
public struct OCRDisambiguationResult {
    public let candidates: [OCRDataCandidate]
    public let confidence: Float
    public let requiresUserSelection: Bool
    
    public init(
        candidates: [OCRDataCandidate],
        confidence: Float,
        requiresUserSelection: Bool
    ) {
        self.candidates = candidates
        self.confidence = confidence
        self.requiresUserSelection = requiresUserSelection
    }
}

// MARK: - OCR Disambiguation Selection

/// User's selection for disambiguation
public struct OCRDisambiguationSelection {
    public let candidateId: String
    public let selectedType: TextType
    public let customText: String?
    
    public init(
        candidateId: String,
        selectedType: TextType,
        customText: String? = nil
    ) {
        self.candidateId = candidateId
        self.selectedType = selectedType
        self.customText = customText
    }
}

// MARK: - OCR Disambiguation Configuration

/// Configuration for disambiguation behavior
public struct OCRDisambiguationConfiguration {
    public let confidenceThreshold: Float
    public let maxCandidates: Int
    public let enableCustomText: Bool
    public let showBoundingBoxes: Bool
    public let allowSkip: Bool
    
    public init(
        confidenceThreshold: Float = 0.8,
        maxCandidates: Int = 5,
        enableCustomText: Bool = true,
        showBoundingBoxes: Bool = true,
        allowSkip: Bool = true
    ) {
        self.confidenceThreshold = confidenceThreshold
        self.maxCandidates = maxCandidates
        self.enableCustomText = enableCustomText
        self.showBoundingBoxes = showBoundingBoxes
        self.allowSkip = allowSkip
    }
}

// MARK: - Disambiguation Detection Logic

/// Determine if disambiguation is required based on candidates
public func shouldRequireDisambiguation(candidates: [OCRDataCandidate]) -> Bool {
    // Need at least 2 candidates to require disambiguation
    guard candidates.count >= 2 else { return false }
    
    // Group candidates by suggested type
    let typeGroups = Dictionary(grouping: candidates) { $0.suggestedType }
    
    // Check if any type group has multiple candidates with similar confidence
    for (_, groupCandidates) in typeGroups {
        if groupCandidates.count >= 2 {
            let confidences = groupCandidates.map { $0.confidence }
            let avgConfidence = confidences.reduce(0, +) / Float(confidences.count)
            let confidenceRange = confidences.max()! - confidences.min()!
            
            // Require disambiguation if:
            // 1. Average confidence is below threshold, OR
            // 2. Confidence range is small (similar confidence), OR
            // 3. Any candidate has very low confidence
            if avgConfidence < 0.7 || confidenceRange < 0.2 || confidences.contains(where: { $0 < 0.5 }) {
                return true
            }
        }
    }
    
    // Check for identical text with different types
    let textGroups = Dictionary(grouping: candidates) { $0.text }
    for (_, groupCandidates) in textGroups {
        if groupCandidates.count >= 2 {
            let types = Set(groupCandidates.map { $0.suggestedType })
            if types.count > 1 {
                return true
            }
        }
    }
    
    // Check for mixed confidence levels (high confidence difference)
    let confidences = candidates.map { $0.confidence }
    let maxConfidence = confidences.max() ?? 0
    let minConfidence = confidences.min() ?? 0
    let confidenceRange = maxConfidence - minConfidence
    
    // Require disambiguation if confidence range is large (mixed confidence)
    if confidenceRange > 0.3 {
        return true
    }
    
    return false
}

// MARK: - Disambiguation Helper Functions

/// Create disambiguation result from OCR candidates
public func createDisambiguationResult(
    from candidates: [OCRDataCandidate],
    configuration: OCRDisambiguationConfiguration = OCRDisambiguationConfiguration()
) -> OCRDisambiguationResult {
    let requiresDisambiguation = shouldRequireDisambiguation(candidates: candidates)
    
    // Limit candidates if needed
    let limitedCandidates = Array(candidates.prefix(configuration.maxCandidates))
    
    // Calculate average confidence
    let avgConfidence = limitedCandidates.isEmpty ? 0.0 : 
        limitedCandidates.map { $0.confidence }.reduce(0, +) / Float(limitedCandidates.count)
    
    return OCRDisambiguationResult(
        candidates: limitedCandidates,
        confidence: avgConfidence,
        requiresUserSelection: requiresDisambiguation
    )
}

/// Filter candidates by confidence threshold
public func filterCandidatesByConfidence(
    _ candidates: [OCRDataCandidate],
    threshold: Float
) -> [OCRDataCandidate] {
    return candidates.filter { $0.confidence >= threshold }
}

/// Sort candidates by confidence (highest first)
public func sortCandidatesByConfidence(
    _ candidates: [OCRDataCandidate]
) -> [OCRDataCandidate] {
    return candidates.sorted { $0.confidence > $1.confidence }
}

/// Group candidates by type
public func groupCandidatesByType(
    _ candidates: [OCRDataCandidate]
) -> [TextType: [OCRDataCandidate]] {
    return Dictionary(grouping: candidates) { $0.suggestedType }
}

/// Find candidates with identical text
public func findIdenticalTextCandidates(
    _ candidates: [OCRDataCandidate]
) -> [String: [OCRDataCandidate]] {
    return Dictionary(grouping: candidates) { $0.text }
}

// MARK: - OCR Disambiguation Alternative (for backward compatibility)

/// Alternative representation for OCR disambiguation (legacy support)
public struct OCRDisambiguationAlternative {
    public let text: String
    public let confidence: Float

    public init(text: String, confidence: Float) {
        self.text = text
        self.confidence = confidence
    }
}
