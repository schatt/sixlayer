//
//  OCRLabelAnchoredExtraction.swift
//  SixLayerFramework
//
//  Label-anchored structured field binding (#282, #285).
//

import Foundation
import CoreGraphics

/// One Vision observation line aligned with its bounding box (reading order).
struct OCRRecognitionLine: Sendable {
    let text: String
    let boundingBox: CGRect
}

enum OCRLabelAnchoredExtraction {
    
    struct Candidate {
        let fieldId: String
        let value: String
        let numberRange: NSRange
        let hintLength: Int
        let isHintFirst: Bool
        let matchLocation: Int
        let layoutScore: Int
    }
    
    static func extract(
        from extractedText: String,
        patterns: [String: String],
        recognitionLines: [OCRRecognitionLine]?
    ) -> [String: String] {
        let candidates = collectCandidates(
            in: extractedText,
            patterns: patterns,
            recognitionLines: recognitionLines
        )
        return assignExclusive(candidates)
    }
    
    static func collectCandidates(
        in extractedText: String,
        patterns: [String: String],
        recognitionLines: [OCRRecognitionLine]?
    ) -> [Candidate] {
        var candidates: [Candidate] = []
        let fullRange = NSRange(location: 0, length: extractedText.utf16.count)
        
        for (fieldId, pattern) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let matches = regex.matches(in: extractedText, options: [], range: fullRange)
            for match in matches {
                if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound {
                    appendCandidate(
                        fieldId: fieldId,
                        numberRange: match.range(at: 3),
                        hintLength: hintLengthFromMatch(match, hintGroupIndex: 2, in: extractedText),
                        isHintFirst: true,
                        match: match,
                        extractedText: extractedText,
                        recognitionLines: recognitionLines,
                        to: &candidates
                    )
                } else if match.numberOfRanges > 4, match.range(at: 4).location != NSNotFound {
                    appendCandidate(
                        fieldId: fieldId,
                        numberRange: match.range(at: 4),
                        hintLength: hintLengthFromMatch(match, hintGroupIndex: 5, in: extractedText),
                        isHintFirst: false,
                        match: match,
                        extractedText: extractedText,
                        recognitionLines: recognitionLines,
                        to: &candidates
                    )
                } else if match.numberOfRanges > 2, match.range(at: 2).location != NSNotFound {
                    appendCandidate(
                        fieldId: fieldId,
                        numberRange: match.range(at: 2),
                        hintLength: 0,
                        isHintFirst: true,
                        match: match,
                        extractedText: extractedText,
                        recognitionLines: recognitionLines,
                        to: &candidates
                    )
                }
            }
        }
        return candidates
    }
    
    private static func appendCandidate(
        fieldId: String,
        numberRange: NSRange,
        hintLength: Int,
        isHintFirst: Bool,
        match: NSTextCheckingResult,
        extractedText: String,
        recognitionLines: [OCRRecognitionLine]?,
        to candidates: inout [Candidate]
    ) {
        guard let valueRange = Range(numberRange, in: extractedText) else { return }
        let value = String(extractedText[valueRange])
        let layoutScore = layoutProximityScore(
            forNumberValue: value,
            isHintFirst: isHintFirst,
            match: match,
            extractedText: extractedText,
            recognitionLines: recognitionLines
        )
        candidates.append(Candidate(
            fieldId: fieldId,
            value: value,
            numberRange: numberRange,
            hintLength: hintLength,
            isHintFirst: isHintFirst,
            matchLocation: match.range.location,
            layoutScore: layoutScore
        ))
    }
    
    static func assignExclusive(_ candidates: [Candidate]) -> [String: String] {
        let sorted = candidates.sorted { lhs, rhs in
            if lhs.layoutScore != rhs.layoutScore { return lhs.layoutScore > rhs.layoutScore }
            if lhs.isHintFirst != rhs.isHintFirst { return lhs.isHintFirst && !rhs.isHintFirst }
            if lhs.hintLength != rhs.hintLength { return lhs.hintLength > rhs.hintLength }
            if lhs.matchLocation != rhs.matchLocation { return lhs.matchLocation < rhs.matchLocation }
            return lhs.fieldId < rhs.fieldId
        }
        
        var structuredData: [String: String] = [:]
        var claimedNumberRanges: [NSRange] = []
        
        for candidate in sorted {
            if structuredData[candidate.fieldId] != nil { continue }
            if claimedNumberRanges.contains(where: { NSIntersectionRange($0, candidate.numberRange).length > 0 }) {
                continue
            }
            structuredData[candidate.fieldId] = candidate.value
            claimedNumberRanges.append(candidate.numberRange)
        }
        return structuredData
    }
    
    private static func layoutProximityScore(
        forNumberValue value: String,
        isHintFirst: Bool,
        match: NSTextCheckingResult,
        extractedText: String,
        recognitionLines: [OCRRecognitionLine]?
    ) -> Int {
        guard let recognitionLines, !recognitionLines.isEmpty else { return 0 }
        
        let numberLineIndex = recognitionLines.firstIndex { line in
            line.text.contains(value) || value.contains(line.text.trimmingCharacters(in: .whitespaces))
        }
        
        let hintSubstring = hintSubstringForMatch(match, isHintFirst: isHintFirst, in: extractedText)
        let hintLineIndex = hintSubstring.flatMap { hint in
            recognitionLines.firstIndex { $0.text.localizedCaseInsensitiveContains(hint) }
        }
        
        guard let numberLineIndex else { return 0 }
        guard let hintLineIndex else { return 0 }
        
        if numberLineIndex == hintLineIndex { return 30 }
        if abs(numberLineIndex - hintLineIndex) == 1 { return 15 }
        return 0
    }
    
    private static func hintSubstringForMatch(
        _ match: NSTextCheckingResult,
        isHintFirst: Bool,
        in text: String
    ) -> String? {
        let hintIndex = isHintFirst ? 2 : 5
        guard hintIndex < match.numberOfRanges,
              match.range(at: hintIndex).location != NSNotFound,
              let range = Range(match.range(at: hintIndex), in: text) else {
            return nil
        }
        return String(text[range])
    }
    
    private static func hintLengthFromMatch(_ match: NSTextCheckingResult, hintGroupIndex: Int, in text: String) -> Int {
        guard hintGroupIndex < match.numberOfRanges,
              match.range(at: hintGroupIndex).location != NSNotFound,
              let hintRange = Range(match.range(at: hintGroupIndex), in: text) else {
            return 0
        }
        return text[hintRange].count
    }
}
