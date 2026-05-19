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
        if let recognitionLines, !recognitionLines.isEmpty {
            var lineCandidates: [Candidate] = []
            for line in recognitionLines {
                collectCandidates(
                    in: line.text,
                    patterns: patterns,
                    recognitionLines: recognitionLines,
                    into: &lineCandidates
                )
            }
            let lineAssignments = assignExclusive(lineCandidates)
            let flatAssignments = assignExclusive(
                collectCandidates(
                    in: extractedText,
                    patterns: patterns,
                    recognitionLines: nil
                )
            )
            return mergeAssignments(preferred: lineAssignments, fallback: flatAssignments)
        }
        
        return assignExclusive(
            collectCandidates(
                in: extractedText,
                patterns: patterns,
                recognitionLines: nil
            )
        )
    }
    
    static func collectCandidates(
        in extractedText: String,
        patterns: [String: String],
        recognitionLines: [OCRRecognitionLine]?
    ) -> [Candidate] {
        var candidates: [Candidate] = []
        collectCandidates(
            in: extractedText,
            patterns: patterns,
            recognitionLines: recognitionLines,
            into: &candidates
        )
        return candidates
    }
    
    private static func mergeAssignments(
        preferred: [String: String],
        fallback: [String: String]
    ) -> [String: String] {
        var merged = fallback
        for (fieldId, value) in preferred {
            merged[fieldId] = value
        }
        return merged
    }
    
    private static func collectCandidates(
        in text: String,
        patterns: [String: String],
        recognitionLines: [OCRRecognitionLine]?,
        into candidates: inout [Candidate]
    ) {
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        for (fieldId, pattern) in patterns {
            if let parts = splitBidirectionalPattern(pattern) {
                collectMatches(
                    fieldId: fieldId,
                    pattern: parts.hintFirst,
                    in: text,
                    range: fullRange,
                    isHintFirst: true,
                    recognitionLines: recognitionLines,
                    into: &candidates
                )
                collectMatches(
                    fieldId: fieldId,
                    pattern: parts.numberFirst,
                    in: text,
                    range: fullRange,
                    isHintFirst: false,
                    recognitionLines: recognitionLines,
                    into: &candidates
                )
            } else {
                collectMatches(
                    fieldId: fieldId,
                    pattern: pattern,
                    in: text,
                    range: fullRange,
                    isHintFirst: true,
                    recognitionLines: recognitionLines,
                    into: &candidates
                )
            }
        }
    }
    
    /// Split `(?i)((hint…num)|(num…hint))` into separate arms so both can match without alternation overlap.
    private static func splitBidirectionalPattern(_ pattern: String) -> (hintFirst: String, numberFirst: String)? {
        guard pattern.hasPrefix("(?i)(("), pattern.hasSuffix("))") else { return nil }
        let innerStart = pattern.index(pattern.startIndex, offsetBy: 5)
        let innerEnd = pattern.index(pattern.endIndex, offsetBy: -1)
        let inner = String(pattern[innerStart..<innerEnd])
        guard let pipeRange = inner.range(of: "|(") else { return nil }
        let hintArm = String(inner[inner.startIndex..<pipeRange.lowerBound])
        let numberArm = String(inner[pipeRange.lowerBound...].dropFirst())
        return (
            hintFirst: "(?i)" + hintArm,
            numberFirst: "(?i)" + numberArm
        )
    }
    
    private static func collectMatches(
        fieldId: String,
        pattern: String,
        in text: String,
        range: NSRange,
        isHintFirst: Bool,
        recognitionLines: [OCRRecognitionLine]?,
        into candidates: inout [Candidate]
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        let matches = regex.matches(in: text, options: [], range: range)
        for match in matches {
            guard let numberGroupIndex = numericCaptureGroupIndex(in: match, text: text) else {
                continue
            }
            let hintGroupIndex = isHintFirst ? max(1, numberGroupIndex - 1) : numberGroupIndex + 1
            appendCandidate(
                fieldId: fieldId,
                numberRange: match.range(at: numberGroupIndex),
                hintLength: hintLengthFromMatch(match, hintGroupIndex: hintGroupIndex, in: text),
                isHintFirst: isHintFirst,
                match: match,
                extractedText: text,
                recognitionLines: recognitionLines,
                to: &candidates
            )
        }
    }
    
    /// Highest-index capture group whose value parses as a number (the OCR value).
    private static func numericCaptureGroupIndex(in match: NSTextCheckingResult, text: String) -> Int? {
        for index in stride(from: match.numberOfRanges - 1, through: 1, by: -1) {
            let range = match.range(at: index)
            guard range.location != NSNotFound, let valueRange = Range(range, in: text) else { continue }
            let value = String(text[valueRange])
            if Double(value.replacingOccurrences(of: ",", with: ".")) != nil {
                return index
            }
        }
        return nil
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
        let hintSubstring = hintSubstringForMatch(match, isHintFirst: isHintFirst, in: extractedText)
        
        for (index, line) in recognitionLines.enumerated() {
            guard line.text.contains(value) else { continue }
            guard let hintSubstring, !hintSubstring.isEmpty else { return 0 }
            if line.text.localizedCaseInsensitiveContains(hintSubstring) {
                return 30
            }
            let neighborIndices = [index - 1, index + 1]
            for neighborIndex in neighborIndices where neighborIndex >= 0 && neighborIndex < recognitionLines.count {
                if recognitionLines[neighborIndex].text.localizedCaseInsensitiveContains(hintSubstring) {
                    return 15
                }
            }
            return 0
        }
        return 0
    }
    
    private static func hintSubstringForMatch(
        _ match: NSTextCheckingResult,
        isHintFirst: Bool,
        in text: String
    ) -> String? {
        guard let numberGroupIndex = numericCaptureGroupIndex(in: match, text: text) else {
            return nil
        }
        let hintGroupIndex = isHintFirst ? max(1, numberGroupIndex - 1) : numberGroupIndex + 1
        guard hintGroupIndex < match.numberOfRanges,
              match.range(at: hintGroupIndex).location != NSNotFound,
              let range = Range(match.range(at: hintGroupIndex), in: text) else {
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
