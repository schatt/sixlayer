//
//  OCRSegmentLabelBinding.swift
//  SixLayerFramework
//
//  Box binding for segment groups and printed labels (#576).
//

import CoreGraphics
import Foundation

enum OCRSegmentLabelBinding {
    static func merge(segments: [OCRRecognizedText], labels: [OCRRecognizedText]) -> [OCRRecognizedText] {
        let kept = labels.filter { label in
            !segments.contains { segment in overlapsEnough(label.boundingBox, segment.boundingBox) }
        }
        return segments + kept
    }

    static func assign(fragments: [OCRRecognizedText], patterns: [String: String]) -> [String: String] {
        let segments = fragments.filter { $0.role == .segment }
        let labels = fragments.filter { $0.role == .label }
        guard !segments.isEmpty, !labels.isEmpty, !patterns.isEmpty else { return [:] }
        let segmentBoxes = segments.map(\.boundingBox)
        let usable = labels.filter { !isStripHeading($0.boundingBox, segments: segmentBoxes) }
        guard !usable.isEmpty else { return [:] }
        let pairs = pair(segments: segments, labels: usable)
        var fields: [String: String] = [:]
        for (field, pattern) in patterns {
            let hits = pairs.filter { labelMatches($0.label.text, pattern: pattern) }
            guard let best = hits.min(by: { edgeGap($0.label.boundingBox, $0.segment.boundingBox) < edgeGap($1.label.boundingBox, $1.segment.boundingBox) }) else {
                continue
            }
            fields[field] = best.segment.text
        }
        return fields
    }

    private struct Pair {
        var label: OCRRecognizedText
        var segment: OCRRecognizedText
    }

    private static func pair(segments: [OCRRecognizedText], labels: [OCRRecognizedText]) -> [Pair] {
        if let parallel = parallelPairs(segments: segments, labels: labels) {
            return parallel
        }
        if let alternating = alternatingPairs(segments: segments, labels: labels) {
            return alternating
        }
        return nearestPairs(segments: segments, labels: labels)
    }

    private static func parallelPairs(segments: [OCRRecognizedText], labels: [OCRRecognizedText]) -> [Pair]? {
        guard labels.count == segments.count, !labels.isEmpty else { return nil }
        let labelMinY = labels.map(\.boundingBox.minY).min() ?? 0
        let labelMaxY = labels.map(\.boundingBox.maxY).max() ?? 0
        let segmentMinY = segments.map(\.boundingBox.minY).min() ?? 0
        let segmentMaxY = segments.map(\.boundingBox.maxY).max() ?? 0
        let stacked = labelMinY >= segmentMaxY || labelMaxY <= segmentMinY
        guard stacked else { return nil }
        let orderedLabels = labels.sorted { $0.boundingBox.midX < $1.boundingBox.midX }
        let orderedSegments = segments.sorted { $0.boundingBox.midX < $1.boundingBox.midX }
        return zip(orderedLabels, orderedSegments).map { Pair(label: $0.0, segment: $0.1) }
    }

    private static func alternatingPairs(segments: [OCRRecognizedText], labels: [OCRRecognizedText]) -> [Pair]? {
        let items = (segments.map { (text: $0, label: false) }) + (labels.map { (text: $0, label: true) })
        let xRange = span(items.map { $0.text.boundingBox.midX })
        let yRange = span(items.map { $0.text.boundingBox.midY })
        let vertical = yRange > xRange
        let ordered = items.sorted { lhs, rhs in
            vertical
                ? lhs.text.boundingBox.midY > rhs.text.boundingBox.midY
                : lhs.text.boundingBox.midX < rhs.text.boundingBox.midX
        }
        guard ordered.count >= 2, ordered.count.isMultiple(of: 2) else { return nil }
        let flags = ordered.map(\.label)
        let alternates = zip(flags, flags.dropFirst()).allSatisfy { $0 != $1 }
        guard alternates, flags.first != flags.last else { return nil }
        var pairs: [Pair] = []
        var index = 0
        while index + 1 < ordered.count {
            let first = ordered[index]
            let second = ordered[index + 1]
            let label = first.label ? first.text : second.text
            let segment = first.label ? second.text : first.text
            pairs.append(Pair(label: label, segment: segment))
            index += 2
        }
        return pairs
    }

    private static func nearestPairs(segments: [OCRRecognizedText], labels: [OCRRecognizedText]) -> [Pair] {
        var candidates: [(pair: Pair, gap: CGFloat)] = []
        for segment in segments {
            let neighbor = segments
                .filter { $0.boundingBox != segment.boundingBox || $0.text != segment.text }
                .map { edgeGap($0.boundingBox, segment.boundingBox) }
                .min()
            for label in labels {
                let gap = edgeGap(label.boundingBox, segment.boundingBox)
                if let neighbor, gap > neighbor { continue }
                candidates.append((Pair(label: label, segment: segment), gap))
            }
        }
        let ordered = candidates.sorted { $0.gap < $1.gap }
        var usedLabels: [CGRect] = []
        var usedSegments: [CGRect] = []
        var pairs: [Pair] = []
        for candidate in ordered {
            if usedLabels.contains(candidate.pair.label.boundingBox) { continue }
            if usedSegments.contains(candidate.pair.segment.boundingBox) { continue }
            usedLabels.append(candidate.pair.label.boundingBox)
            usedSegments.append(candidate.pair.segment.boundingBox)
            pairs.append(candidate.pair)
        }
        return pairs
    }

    private static func isStripHeading(_ label: CGRect, segments: [CGRect]) -> Bool {
        let covered = segments.filter { label.minX <= $0.midX && $0.midX <= label.maxX }
        let sorted = covered.sorted { $0.midY < $1.midY }
        var run = 0
        var best = 0
        var previous: CGRect?
        for rect in sorted {
            if let previous, rect.minY <= previous.maxY {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = rect
        }
        return best >= 2
    }

    private static func overlapsEnough(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        let width = min(lhs.maxX, rhs.maxX) - max(lhs.minX, rhs.minX)
        let height = min(lhs.maxY, rhs.maxY) - max(lhs.minY, rhs.minY)
        guard width > 0, height > 0 else { return false }
        let intersection = width * height
        let smaller = min(lhs.width * lhs.height, rhs.width * rhs.height)
        guard smaller > 0 else { return false }
        return intersection >= smaller * 0.5
    }

    private static func edgeGap(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let dx: CGFloat
        if lhs.maxX < rhs.minX {
            dx = rhs.minX - lhs.maxX
        } else if rhs.maxX < lhs.minX {
            dx = lhs.minX - rhs.maxX
        } else {
            dx = 0
        }
        let dy: CGFloat
        if lhs.maxY < rhs.minY {
            dy = rhs.minY - lhs.maxY
        } else if rhs.maxY < lhs.minY {
            dy = lhs.minY - rhs.maxY
        } else {
            dy = 0
        }
        return hypot(dx, dy)
    }

    private static func span(_ values: [CGFloat]) -> CGFloat {
        guard let low = values.min(), let high = values.max() else { return 0 }
        return high - low
    }

    private static func labelMatches(_ text: String, pattern: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            if expression.firstMatch(in: trimmed, options: [], range: range) != nil {
                return true
            }
        }
        return trimmed.localizedCaseInsensitiveContains(pattern)
    }
}
