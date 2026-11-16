//
//  DisplayOCRLabEvaluation.swift
//  SixLayerFramework
//
//  OCR lab bulk pass/fail evaluation core (#677).
//

import Foundation

/// Per-axis outcome for a scored example (#677).
public enum DisplayOCRLabAxisOutcome: String, Codable, Sendable, Equatable {
    case pass
    case fail
    case skip
}

/// One example’s dual-axis score (#677).
public struct DisplayOCRLabExampleScore: Codable, Sendable, Equatable {
    public var exampleId: String
    public var folderName: String?
    public var structured: DisplayOCRLabAxisOutcome
    public var localization: DisplayOCRLabAxisOutcome
    public var structuredExpected: [String: String]?
    public var structuredActual: [String: String]?
    public var iou: Double?
    public var failureReasons: [String]
    public var overallPass: Bool

    public init(
        exampleId: String,
        folderName: String? = nil,
        structured: DisplayOCRLabAxisOutcome,
        localization: DisplayOCRLabAxisOutcome,
        structuredExpected: [String: String]? = nil,
        structuredActual: [String: String]? = nil,
        iou: Double? = nil,
        failureReasons: [String] = []
    ) {
        self.exampleId = exampleId
        self.folderName = folderName
        self.structured = structured
        self.localization = localization
        self.structuredExpected = structuredExpected
        self.structuredActual = structuredActual
        self.iou = iou
        self.failureReasons = failureReasons
        let scored: [DisplayOCRLabAxisOutcome] = [structured, localization].filter { $0 != .skip }
        self.overallPass = scored.allSatisfy { $0 == .pass }
    }
}

/// Baseline-diff highlights (#677).
public struct DisplayOCRLabBaselineDiff: Sendable, Equatable {
    public var lostPasses: [String]
    public var newFails: [String]

    public init(lostPasses: [String] = [], newFails: [String] = []) {
        self.lostPasses = lostPasses
        self.newFails = newFails
    }
}

/// Machine-readable bulk-check summary (#677).
public struct DisplayOCRLabRunSummary: Codable, Sendable, Equatable {
    public var passCount: Int
    public var failCount: Int
    public var skipCount: Int
    public var contextMode: String?
    public var localizationIoUThreshold: Double?
    public var examples: [DisplayOCRLabExampleScore]
    public var timestamp: String?
    /// Host OS description for regression archaeology (#677).
    public var operatingSystem: String?
    /// SixLayer framework marketing version when discoverable (#677).
    public var sixLayerVersion: String?
    /// Xcode version when known (often nil outside an Xcode-hosted process) (#677).
    public var xcodeVersion: String?

    public init(
        passCount: Int,
        failCount: Int,
        skipCount: Int,
        contextMode: String? = nil,
        localizationIoUThreshold: Double? = nil,
        examples: [DisplayOCRLabExampleScore],
        timestamp: String? = nil,
        operatingSystem: String? = nil,
        sixLayerVersion: String? = nil,
        xcodeVersion: String? = nil
    ) {
        self.passCount = passCount
        self.failCount = failCount
        self.skipCount = skipCount
        self.contextMode = contextMode
        self.localizationIoUThreshold = localizationIoUThreshold
        self.examples = examples
        self.timestamp = timestamp
        self.operatingSystem = operatingSystem
        self.sixLayerVersion = sixLayerVersion
        self.xcodeVersion = xcodeVersion
    }
}

/// Dual-axis scoring and authoring assist (#677).
public enum DisplayOCRLabEvaluation {
    public static let defaultLocalizationIoUThreshold: Double = 0.5
    /// Same absolute numeric gate production calculation checks use (`OCRService`).
    public static let productionNumericTolerance: Double = 0.01
    /// Authoring assist never auto-commits ground truth (#677).
    public static let authoringAssistAutoCommitsGroundTruth: Bool = false

    public static func makeOCRContext(from label: DisplayOCRTrainingLabel) -> OCRContext {
        OCRContext(
            entityName: label.entityName,
            fieldAverages: label.fieldAverages,
            fieldAverageMaxPercentDeviation: label.fieldAverageMaxPercentDeviation,
            fieldFractionDigits: label.fieldFractionDigits,
            processingMode: .ssocr
        )
    }

    public static func score(
        result: OCRResult,
        label: DisplayOCRTrainingLabel,
        localizationIoUThreshold: Double = defaultLocalizationIoUThreshold,
        folderName: String? = nil
    ) -> DisplayOCRLabExampleScore {
        var reasons: [String] = []
        let expected = label.expectedStructuredFields

        let structured: DisplayOCRLabAxisOutcome
        if let expected, !expected.isEmpty {
            let fieldFailures = structuredFieldFailures(
                expected: expected,
                actual: result.structuredData
            )
            let formulaFailures = formulaConsistencyFailures(
                expected: expected,
                actual: result.structuredData
            )
            reasons.append(contentsOf: fieldFailures)
            reasons.append(contentsOf: formulaFailures)
            structured = reasons.isEmpty ? .pass : .fail
        } else {
            structured = .skip
        }

        let localization: DisplayOCRLabAxisOutcome
        let iou: Double?
        if let chosen = result.chosenPanelRect {
            let value = label.panel.iou(chosen)
            iou = value
            if value >= localizationIoUThreshold {
                localization = .pass
            } else {
                localization = .fail
                reasons.append(
                    String(
                        format: "localization_miss IoU=%.4f threshold=%.4f",
                        value,
                        localizationIoUThreshold
                    )
                )
            }
        } else {
            iou = nil
            localization = .skip
        }

        return DisplayOCRLabExampleScore(
            exampleId: label.exampleId ?? folderName ?? "unknown",
            folderName: folderName,
            structured: structured,
            localization: localization,
            structuredExpected: expected,
            structuredActual: expected == nil ? nil : result.structuredData,
            iou: iou,
            failureReasons: reasons
        )
    }

    public static func seedExpectedFields(
        fromConfirmedRows rows: [(String, String)]
    ) -> [String: String] {
        Dictionary(uniqueKeysWithValues: rows)
    }

    /// Compare expected vs actual field strings using production numeric tolerance when both parse.
    private static func structuredFieldFailures(
        expected: [String: String],
        actual: [String: String]
    ) -> [String] {
        expected.sorted { $0.key < $1.key }.compactMap { fieldId, expectedRaw in
            guard let actualRaw = actual[fieldId] else {
                return "\(fieldId) missing"
            }
            if numericValuesMatch(expectedRaw, actualRaw) {
                return nil
            }
            return "\(fieldId) mismatch expected=\(expectedRaw) actual=\(actualRaw)"
        }
    }

    /// When expected values themselves satisfy A×B≈C for three numeric fields, require actual to as well.
    private static func formulaConsistencyFailures(
        expected: [String: String],
        actual: [String: String]
    ) -> [String] {
        let expectedNums = expected.compactMap { key, raw -> (String, Double)? in
            guard let value = Double(raw) else { return nil }
            return (key, value)
        }
        guard expectedNums.count >= 3 else { return [] }

        for i in 0..<expectedNums.count {
            for j in 0..<expectedNums.count where j != i {
                for k in 0..<expectedNums.count where k != i && k != j {
                    let (aId, a) = expectedNums[i]
                    let (bId, b) = expectedNums[j]
                    let (cId, c) = expectedNums[k]
                    guard abs(a * b - c) < productionNumericTolerance else { continue }
                    guard
                        let actualA = actual[aId].flatMap(Double.init),
                        let actualB = actual[bId].flatMap(Double.init),
                        let actualC = actual[cId].flatMap(Double.init)
                    else {
                        return ["formula inconsistent: missing actual for \(aId)*\(bId)=\(cId)"]
                    }
                    if abs(actualA * actualB - actualC) >= productionNumericTolerance {
                        return [
                            "formula/calculation inconsistent: \(aId)*\(bId) should equal \(cId) within \(productionNumericTolerance)"
                        ]
                    }
                }
            }
        }
        return []
    }

    private static func numericValuesMatch(_ expectedRaw: String, _ actualRaw: String) -> Bool {
        if expectedRaw == actualRaw { return true }
        guard let expected = Double(expectedRaw), let actual = Double(actualRaw) else {
            return false
        }
        return abs(expected - actual) < productionNumericTolerance
    }
}

/// Exit codes and baseline compare for the bulk CLI/app entry (#677).
public enum DisplayOCRLabBulkCheck {
    public static let usageErrorExitCode: Int = 2

    public static func exitCode(
        for summary: DisplayOCRLabRunSummary,
        baseline: DisplayOCRLabRunSummary?
    ) -> Int {
        if summary.failCount > 0 {
            return 1
        }
        if let baseline {
            let diff = compare(current: summary, baseline: baseline)
            if !diff.lostPasses.isEmpty || !diff.newFails.isEmpty {
                return 1
            }
        }
        return 0
    }

    public static func compare(
        current: DisplayOCRLabRunSummary,
        baseline: DisplayOCRLabRunSummary
    ) -> DisplayOCRLabBaselineDiff {
        let baselineById = Dictionary(
            uniqueKeysWithValues: baseline.examples.map { ($0.exampleId, $0) }
        )
        let currentById = Dictionary(
            uniqueKeysWithValues: current.examples.map { ($0.exampleId, $0) }
        )

        var lostPasses: [String] = []
        for (id, prior) in baselineById where prior.overallPass {
            let nowPassed = currentById[id]?.overallPass ?? false
            if !nowPassed {
                lostPasses.append(id)
            }
        }

        var newFails: [String] = []
        for (id, now) in currentById where !now.overallPass {
            if baselineById[id] == nil {
                newFails.append(id)
            }
        }

        return DisplayOCRLabBaselineDiff(
            lostPasses: lostPasses.sorted(),
            newFails: newFails.sorted()
        )
    }

    /// Capture host/run metadata for summary JSON (#677). Stubbed empty until green.
    public static func captureRunMetadata() -> (
        timestamp: String?,
        operatingSystem: String?,
        sixLayerVersion: String?,
        xcodeVersion: String?
    ) {
        // Deliberate incomplete stub for #677 red: metadata fields stay nil.
        (nil, nil, nil, nil)
    }

    /// Score precomputed OCR results against labels (unit-test / post-OCR path).
    public static func evaluate(
        examples: [(folderName: String, label: DisplayOCRTrainingLabel)],
        resultsByExampleId: [String: OCRResult],
        skippedUnreadableCount: Int = 0,
        contextMode: String = "app",
        localizationIoUThreshold: Double = DisplayOCRLabEvaluation.defaultLocalizationIoUThreshold
    ) -> DisplayOCRLabRunSummary {
        var scores: [DisplayOCRLabExampleScore] = []
        scores.reserveCapacity(examples.count)
        for example in examples {
            let exampleId = example.label.exampleId ?? example.folderName
            let result = resultsByExampleId[exampleId] ?? OCRResult(extractedText: "", confidence: 0)
            scores.append(
                DisplayOCRLabEvaluation.score(
                    result: result,
                    label: example.label,
                    localizationIoUThreshold: localizationIoUThreshold,
                    folderName: example.folderName
                )
            )
        }
        let passCount = scores.filter(\.overallPass).count
        let failCount = scores.filter { !$0.overallPass }.count
        let meta = captureRunMetadata()
        return DisplayOCRLabRunSummary(
            passCount: passCount,
            failCount: failCount,
            skipCount: skippedUnreadableCount,
            contextMode: contextMode,
            localizationIoUThreshold: localizationIoUThreshold,
            examples: scores,
            timestamp: meta.timestamp,
            operatingSystem: meta.operatingSystem,
            sixLayerVersion: meta.sixLayerVersion,
            xcodeVersion: meta.xcodeVersion
        )
    }

    /// App-mode bulk check: invoke the injected library OCR entry for each package.
    public static func runAppMode(
        examples: [(folderName: String, package: DisplayOCRTrainingPackage)],
        localizationIoUThreshold: Double = DisplayOCRLabEvaluation.defaultLocalizationIoUThreshold,
        process: @escaping @Sendable (PlatformImage, OCRContext) async throws -> OCRResult
    ) async throws -> DisplayOCRLabRunSummary {
        var pairs: [(folderName: String, label: DisplayOCRTrainingLabel)] = []
        var results: [String: OCRResult] = [:]
        for example in examples {
            let label = example.package.label
            let exampleId = label.exampleId ?? example.folderName
            pairs.append((example.folderName, label))
            let image = PlatformImage(data: example.package.imagePNG) ?? PlatformImage()
            let context = DisplayOCRLabEvaluation.makeOCRContext(from: label)
            let ocrResult = try await process(image, context)
            results[exampleId] = ocrResult
        }
        return evaluate(
            examples: pairs,
            resultsByExampleId: results,
            contextMode: "app",
            localizationIoUThreshold: localizationIoUThreshold
        )
    }

    /// Load a training-library root and run app-mode OCR via ``OCRService``.
    public static func runLibrary(
        at root: URL,
        localizationIoUThreshold: Double = DisplayOCRLabEvaluation.defaultLocalizationIoUThreshold,
        process: (@Sendable (PlatformImage, OCRContext) async throws -> OCRResult)? = nil
    ) async throws -> DisplayOCRLabRunSummary {
        let library = DisplayOCRTraining.library(in: root)
        let loaded = DisplayOCRTraining.loadingImages(library)
        let examples = loaded.examples.map {
            (folderName: $0.directory.lastPathComponent, package: $0.package)
        }
        let runner: @Sendable (PlatformImage, OCRContext) async throws -> OCRResult
        if let process {
            runner = process
        } else {
            runner = { image, context in
                let strategy = OCRStrategy(
                    supportedTextTypes: context.textTypes,
                    supportedLanguages: [context.language],
                    processingMode: .ssocr
                )
                return try await OCRService().processImage(image, context: context, strategy: strategy)
            }
        }
        var summary = try await runAppMode(
            examples: examples,
            localizationIoUThreshold: localizationIoUThreshold,
            process: runner
        )
        // Unreadable packages are library skips, not OCR fails (#677).
        if !library.rejections.isEmpty {
            summary = DisplayOCRLabRunSummary(
                passCount: summary.passCount,
                failCount: summary.failCount,
                skipCount: summary.skipCount + library.rejections.count,
                contextMode: summary.contextMode,
                localizationIoUThreshold: summary.localizationIoUThreshold,
                examples: summary.examples,
                timestamp: summary.timestamp,
                operatingSystem: summary.operatingSystem,
                sixLayerVersion: summary.sixLayerVersion,
                xcodeVersion: summary.xcodeVersion
            )
        }
        return summary
    }

    /// Human-readable per-example lines for CLI / lab console.
    public static func formatHumanReadable(_ summary: DisplayOCRLabRunSummary) -> String {
        var lines: [String] = []
        lines.append(
            "pass=\(summary.passCount) fail=\(summary.failCount) skip=\(summary.skipCount) mode=\(summary.contextMode ?? "?")"
        )
        for example in summary.examples {
            let folder = example.folderName ?? "-"
            let iou = example.iou.map { String(format: "%.3f", $0) } ?? "-"
            let reasons = example.failureReasons.isEmpty ? "" : " \(example.failureReasons.joined(separator: "; "))"
            lines.append(
                "\(example.exampleId) (\(folder)) structured=\(example.structured.rawValue) localization=\(example.localization.rawValue) iou=\(iou)\(reasons)"
            )
        }
        return lines.joined(separator: "\n")
    }
}
