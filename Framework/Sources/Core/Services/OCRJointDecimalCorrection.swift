//
//  OCRJointDecimalCorrection.swift
//  SixLayerFramework
//
//  Calculation-group-driven joint decimal placement (#283, #284, #286).
//

import Foundation

/// Multiplication relationship parsed from hints (`target = factorA * factorB`).
struct OCRMultiplicationRelationship: Sendable {
    let groupID: String
    let productField: String
    let factorFieldA: String
    let factorFieldB: String
    
    var allFields: [String] { [productField, factorFieldA, factorFieldB] }
}

enum OCRJointDecimalCorrection {
    
    struct Result: Sendable {
        let structuredData: [String: String]
        let adjustments: [String: String]
        /// Fields that must not receive per-field decimal correction after joint failure (#286).
        let fieldsBlockedFromPerFieldCorrection: Set<String>
    }
    
    // MARK: - Public
    
    static func apply(
        to structuredData: [String: String],
        hintsRanges: [String: ValueRange],
        hintsCalculationGroups: [String: [CalculationGroup]],
        context: OCRContext
    ) -> Result {
        var data = structuredData
        var adjustments: [String: String] = [:]
        var blocked = Set<String>()
        
        let relationships = multiplicationRelationships(from: hintsCalculationGroups)
        guard !relationships.isEmpty else {
            return Result(structuredData: data, adjustments: adjustments, fieldsBlockedFromPerFieldCorrection: blocked)
        }
        
        var allRanges = hintsRanges
        if let overrideRanges = context.fieldRanges {
            for (fieldId, range) in overrideRanges {
                allRanges[fieldId] = range
            }
        }
        
        for relationship in relationships {
            let outcome = applyJointCorrection(
                relationship: relationship,
                structuredData: data,
                allRanges: allRanges,
                context: context
            )
            data = outcome.data
            for (key, value) in outcome.adjustments {
                adjustments[key] = value
            }
            blocked.formUnion(outcome.blockedFields)
        }
        
        return Result(
            structuredData: data,
            adjustments: adjustments,
            fieldsBlockedFromPerFieldCorrection: blocked
        )
    }
    
    // MARK: - Relationship discovery (#283)
    
    static func multiplicationRelationships(
        from hintsCalculationGroups: [String: [CalculationGroup]]
    ) -> [OCRMultiplicationRelationship] {
        var seenGroupIDs = Set<String>()
        var relationships: [OCRMultiplicationRelationship] = []
        
        for (_, groups) in hintsCalculationGroups {
            for group in groups {
                guard !seenGroupIDs.contains(group.id),
                      let relationship = parseMultiplicationRelationship(group) else {
                    continue
                }
                seenGroupIDs.insert(group.id)
                relationships.append(relationship)
            }
        }
        return relationships
    }
    
    static func parseMultiplicationRelationship(_ group: CalculationGroup) -> OCRMultiplicationRelationship? {
        let parts = group.formula.split(separator: "=", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        guard parts.count == 2 else { return nil }
        let productField = parts[0]
        let expression = parts[1]
        guard expression.contains("*") else { return nil }
        let operands = expression.split(separator: "*").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        guard operands.count == 2 else { return nil }
        return OCRMultiplicationRelationship(
            groupID: group.id,
            productField: productField,
            factorFieldA: operands[0],
            factorFieldB: operands[1]
        )
    }
    
    // MARK: - Joint scoring (#283, #284)
    
    private struct JointOutcome {
        let data: [String: String]
        let adjustments: [String: String]
        let blockedFields: Set<String>
    }
    
    private static func applyJointCorrection(
        relationship: OCRMultiplicationRelationship,
        structuredData: [String: String],
        allRanges: [String: ValueRange],
        context: OCRContext
    ) -> JointOutcome {
        let fields = relationship.allFields
        let presentValues = fields.compactMap { field -> (String, String)? in
            guard let value = structuredData[field], !value.isEmpty else { return nil }
            return (field, value)
        }
        guard presentValues.count >= 2 else {
            return JointOutcome(data: structuredData, adjustments: [:], blockedFields: [])
        }
        
        let needsCorrection: [String: Bool] = Dictionary(uniqueKeysWithValues: fields.map { field in
            (field, valueNeedsDecimalPlacement(structuredData[field] ?? "", language: context.language))
        })
        
        guard needsCorrection.values.contains(true) else {
            return JointOutcome(data: structuredData, adjustments: [:], blockedFields: [])
        }
        
        let rateField = identifyRateField(relationship: relationship, ranges: allRanges)
        let volumeField = identifyVolumeField(
            relationship: relationship,
            rateField: rateField,
            ranges: allRanges
        )
        
        let rateRange = rateField.flatMap { allRanges[$0] } ?? ValueRange(min: 2.0, max: 10.0)
        let printedRate: Double? = rateField.flatMap { field in
            let raw = structuredData[field] ?? ""
            guard !valueNeedsDecimalPlacement(raw, language: context.language) else { return nil }
            return parseOCRNumericValue(raw, language: context.language)
        }
        
        var candidateMap: [String: [String]] = [:]
        for field in fields {
            let raw = structuredData[field] ?? ""
            if needsCorrection[field] == true {
                candidateMap[field] = decimalPlacementCandidates(for: raw, language: context.language)
            } else if !raw.isEmpty {
                candidateMap[field] = [raw]
            } else {
                candidateMap[field] = []
            }
        }
        
        let fieldsWithCandidates = fields.filter { !(candidateMap[$0] ?? []).isEmpty }
        guard fieldsWithCandidates.count >= 2 else {
            return jointFailureOutcome(
                relationship: relationship,
                structuredData: structuredData,
                reason: "insufficient numeric fields"
            )
        }
        
        var best: (values: [String: String], score: Double)?
        let ppgTolerance = 0.05
        
        func search(assignments: [String: String], remaining: [String]) {
            if remaining.isEmpty {
                var merged = structuredData
                for (field, value) in assignments {
                    merged[field] = value
                }
                guard let productVal = parseOCRNumericValue(merged[relationship.productField] ?? "", language: context.language) else {
                    return
                }
                let factorAVal = parseOCRNumericValue(merged[relationship.factorFieldA] ?? "", language: context.language)
                let factorBVal = parseOCRNumericValue(merged[relationship.factorFieldB] ?? "", language: context.language)
                if let factorAVal, let factorBVal {
                    guard abs(factorAVal * factorBVal - productVal) < 0.15 else { return }
                }
                
                var score = 0.0
                for field in fields where needsCorrection[field] == true {
                    guard let raw = structuredData[field],
                          let candidate = assignments[field],
                          let numeric = parseOCRNumericValue(candidate, language: context.language) else {
                        return
                    }
                    if let range = allRanges[field], range.contains(numeric) {
                        score += 20
                    } else {
                        return
                    }
                    _ = raw
                }
                
                if let volumeField, let rateField, volumeField != rateField,
                   let volumeVal = parseOCRNumericValue(merged[volumeField] ?? "", language: context.language),
                   volumeVal > 0 {
                    let impliedRate = productVal / volumeVal
                    guard impliedRate >= rateRange.min && impliedRate <= rateRange.max else { return }
                    score += 10
                    if let printedRate {
                        score += max(0, 50 - abs(impliedRate - printedRate) * 100)
                    } else {
                        let midRate = (rateRange.min + rateRange.max) / 2
                        score += max(0, 10 - abs(impliedRate - midRate))
                    }
                    _ = rateField
                }
                
                if let productCandidate = assignments[relationship.productField], productCandidate.contains(".") {
                    let parts = productCandidate.split(separator: ".", omittingEmptySubsequences: false)
                    if parts.count == 2, parts[1].count == 2 {
                        score += 2
                    }
                }
                
                if best == nil || score > best!.score {
                    best = (assignments, score)
                }
                return
            }
            let field = remaining[0]
            let rest = Array(remaining.dropFirst())
            for candidate in candidateMap[field] ?? [] {
                var next = assignments
                next[field] = candidate
                search(assignments: next, remaining: rest)
            }
        }
        
        search(assignments: [:], remaining: fieldsWithCandidates)
        
        guard let best else {
            return jointFailureOutcome(
                relationship: relationship,
                structuredData: structuredData,
                reason: "no retail-plausible pair"
            )
        }
        
        var result = structuredData
        var adjustments: [String: String] = [:]
        for field in fields where needsCorrection[field] == true {
            let original = structuredData[field] ?? ""
            let corrected = best.values[field] ?? original
            if corrected != original {
                result[field] = corrected
                adjustments[field] = "Joint decimal correction (\(relationship.groupID)): '\(original)' → '\(corrected)'"
            }
        }
        return JointOutcome(data: result, adjustments: adjustments, blockedFields: [])
    }
    
    private static func jointFailureOutcome(
        relationship: OCRMultiplicationRelationship,
        structuredData: [String: String],
        reason: String
    ) -> JointOutcome {
        var adjustments: [String: String] = [:]
        let message = "Joint decimal correction (\(relationship.groupID)): \(reason)"
        adjustments[relationship.productField] = message
        return JointOutcome(
            data: structuredData,
            adjustments: adjustments,
            blockedFields: Set(relationship.allFields)
        )
    }
    
    private static func identifyRateField(
        relationship: OCRMultiplicationRelationship,
        ranges: [String: ValueRange]
    ) -> String? {
        let factors = [relationship.factorFieldA, relationship.factorFieldB]
        let r0 = ranges[factors[0]]
        let r1 = ranges[factors[1]]
        if let r0, let r1 {
            if r0.max <= 15 && r1.max > 15 { return factors[0] }
            if r1.max <= 15 && r0.max > 15 { return factors[1] }
        }
        for factor in factors {
            let lower = factor.lowercased()
            if lower.contains("price") || lower.contains("rate") || lower.contains("ppg") {
                return factor
            }
        }
        return nil
    }
    
    private static func identifyVolumeField(
        relationship: OCRMultiplicationRelationship,
        rateField: String?,
        ranges: [String: ValueRange]
    ) -> String? {
        let factors = [relationship.factorFieldA, relationship.factorFieldB]
        if let rateField, rateField == factors[0] { return factors[1] }
        if let rateField, rateField == factors[1] { return factors[0] }
        if let r0 = ranges[factors[0]], let r1 = ranges[factors[1]], r0.max > r1.max {
            return factors[0]
        }
        if let r0 = ranges[factors[0]], let r1 = ranges[factors[1]], r1.max > r0.max {
            return factors[1]
        }
        for factor in factors {
            let lower = factor.lowercased()
            if lower.contains("gallon") || lower.contains("liter") || lower.contains("litre")
                || lower.contains("volume") || lower.contains("quantity") {
                return factor
            }
        }
        return factors[1]
    }
    
    // MARK: - Numeric parsing (#287 baseline)
    
    static func valueNeedsDecimalPlacement(_ value: String, language: OCRLanguage) -> Bool {
        guard !value.isEmpty else { return false }
        if value.contains(".") { return false }
        if value.contains(",") {
            return !isThousandsCommaOnly(value)
        }
        return Int(value) != nil
    }
    
    static func parseOCRNumericValue(_ valueString: String, language: OCRLanguage) -> Double? {
        Double(normalizeDecimalString(valueString, language: language))
    }
    
    static func normalizeDecimalString(_ value: String, language: OCRLanguage) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains(",") && !trimmed.contains(".") {
            return trimmed.replacingOccurrences(of: ",", with: ".")
        }
        return trimmed.replacingOccurrences(of: ",", with: "")
    }
    
    private static func isThousandsCommaOnly(_ value: String) -> Bool {
        let pattern = #"^\d{1,3}(,\d{3})+(\.\d+)?$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
    
    static func decimalPlacementCandidates(for valueString: String, language: OCRLanguage) -> [String] {
        guard valueNeedsDecimalPlacement(valueString, language: language) else {
            return [valueString]
        }
        guard Int(normalizeDecimalString(valueString, language: language).replacingOccurrences(of: ".", with: "")) != nil
            || Int(valueString) != nil else {
            return [valueString]
        }
        let normalized = valueString
        var candidates = [valueString]
        let digitsOnly = normalized.filter { $0.isNumber }
        let chars = Array(digitsOnly)
        for decimalPos in 1..<chars.count {
            var correctedChars = chars
            correctedChars.insert(".", at: chars.count - decimalPos)
            candidates.append(String(correctedChars))
        }
        return candidates
    }
}
