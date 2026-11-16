//
//  DisplayOCRLabEvaluation.swift
//  SixLayerFramework
//
//  OCR lab bulk pass/fail evaluation core (#677). Stubs for deliberate red.
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

    public init(
        passCount: Int,
        failCount: Int,
        skipCount: Int,
        contextMode: String? = nil,
        localizationIoUThreshold: Double? = nil,
        examples: [DisplayOCRLabExampleScore],
        timestamp: String? = nil
    ) {
        self.passCount = passCount
        self.failCount = failCount
        self.skipCount = skipCount
        self.contextMode = contextMode
        self.localizationIoUThreshold = localizationIoUThreshold
        self.examples = examples
        self.timestamp = timestamp
    }
}

/// Dual-axis scoring and authoring assist (#677). Stubbed for deliberate red.
public enum DisplayOCRLabEvaluation {
    public static let defaultLocalizationIoUThreshold: Double = 0.5
    /// Same absolute numeric gate production calculation checks use (`OCRService`).
    public static let productionNumericTolerance: Double = 0.01
    /// Authoring assist never auto-commits ground truth (#677).
    public static let authoringAssistAutoCommitsGroundTruth: Bool = true

    public static func makeOCRContext(from label: DisplayOCRTrainingLabel) -> OCRContext {
        OCRContext()
    }

    public static func score(
        result: OCRResult,
        label: DisplayOCRTrainingLabel,
        localizationIoUThreshold: Double = defaultLocalizationIoUThreshold,
        folderName: String? = nil
    ) -> DisplayOCRLabExampleScore {
        // Deliberate-red stub: always fail both axes until green (#677).
        DisplayOCRLabExampleScore(
            exampleId: label.exampleId ?? folderName ?? "unknown",
            folderName: folderName,
            structured: .fail,
            localization: .fail,
            failureReasons: ["stub"]
        )
    }

    public static func seedExpectedFields(
        fromConfirmedRows rows: [(String, String)]
    ) -> [String: String] {
        [:]
    }
}

/// Exit codes and baseline compare for the bulk CLI/app entry (#677). Stubbed for deliberate red.
public enum DisplayOCRLabBulkCheck {
    public static let usageErrorExitCode: Int = 0

    public static func exitCode(
        for summary: DisplayOCRLabRunSummary,
        baseline: DisplayOCRLabRunSummary?
    ) -> Int {
        99
    }

    public static func compare(
        current: DisplayOCRLabRunSummary,
        baseline: DisplayOCRLabRunSummary
    ) -> DisplayOCRLabBaselineDiff {
        DisplayOCRLabBaselineDiff()
    }
}
