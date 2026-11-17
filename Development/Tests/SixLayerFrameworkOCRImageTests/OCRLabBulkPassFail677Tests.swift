//
//  OCRLabBulkPassFail677Tests.swift
//  SixLayerFrameworkOCRImageTests
//
//  #677: OCR lab bulk pass/fail — schema, chosenPanelRect, dual-axis score,
//  summary/baseline exit codes. Default oracle is app-mode library OCR.
//  Heavy image/decode suite — not part of SLF-*-UnitTests (#692).
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import SixLayerFramework

@Suite("OCR lab bulk pass/fail (#677)")
struct OCRLabBulkPassFail677Tests {

    // MARK: - Geometry

    @Test func normalizedBoxIoUIsOneForIdenticalBoxes() {
        let box = DisplayOCRNormalizedBox(x: 0.1, y: 0.2, width: 0.4, height: 0.3)
        #expect(abs(box.iou(box) - 1.0) < 0.000_001)
    }

    @Test func normalizedBoxIoUIsZeroWhenBoxesMiss() {
        let a = DisplayOCRNormalizedBox(x: 0, y: 0, width: 0.2, height: 0.2)
        let b = DisplayOCRNormalizedBox(x: 0.8, y: 0.8, width: 0.2, height: 0.2)
        #expect(a.iou(b) == 0)
    }

    @Test func normalizedBoxIoUMatchesHalfOverlap() {
        // Two 1×1 boxes overlapping on a 0.5×1 strip → intersection 0.5, union 1.5 → IoU = 1/3
        let a = DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1)
        let b = DisplayOCRNormalizedBox(x: 0.5, y: 0, width: 1, height: 1)
        #expect(abs(a.iou(b) - (1.0 / 3.0)) < 0.000_001)
    }

    // MARK: - OCRResult.chosenPanelRect

    @Test func ocrResultStoresChosenPanelRectInOriginalNormalizedCoords() {
        let panel = DisplayOCRNormalizedBox(x: 0.2, y: 0.3, width: 0.5, height: 0.25)
        let result = OCRResult(
            extractedText: "1.234",
            confidence: 1.0,
            chosenPanelRect: panel
        )
        #expect(result.chosenPanelRect == panel)
        #expect(OCRResult(extractedText: "x", confidence: 1.0).chosenPanelRect == nil)
    }

    // MARK: - label.json schema

    @Test func labelRoundTripsStableExampleIdAndMultiImageNames() throws {
        let label = DisplayOCRTrainingLabel(
            schemaVersion: DisplayOCRTraining.schemaVersion,
            origin: .topLeft,
            imageFileName: "image.png",
            imagePixelWidth: 100,
            imagePixelHeight: 80,
            sourceName: nil,
            panel: DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.5, height: 0.4),
            rows: [],
            exampleId: "ex-stable-001",
            additionalImageFileNames: ["glare.png"],
            expectedStructuredFields: ["gallons": "8.022", "pricePerGallon": "3.459"],
            entityName: "FuelPurchase",
            fieldAverages: ["pricePerGallon": 3.4],
            fieldAverageMaxPercentDeviation: 75,
            fieldFractionDigits: ["gallons": 3]
        )
        let data = try JSONEncoder().encode(label)
        let decoded = try DisplayOCRTraining.label(from: data)
        #expect(decoded.exampleId == "ex-stable-001")
        #expect(decoded.imageFileNames == ["image.png", "glare.png"])
        #expect(decoded.expectedStructuredFields?["gallons"] == "8.022")
        #expect(decoded.entityName == "FuelPurchase")
        #expect(decoded.fieldAverages?["pricePerGallon"] == 3.4)
        #expect(decoded.fieldAverageMaxPercentDeviation == 75)
        #expect(decoded.fieldFractionDigits?["gallons"] == 3)
    }

    @Test func labelDecodesLegacySingleImageFileNameWithoutNewKeys() throws {
        let legacy = """
        {
          "schemaVersion": 1,
          "origin": "topLeft",
          "imageFileName": "image.png",
          "imagePixelWidth": 10,
          "imagePixelHeight": 10,
          "panel": { "x": 0.1, "y": 0.1, "width": 0.5, "height": 0.5 },
          "rows": []
        }
        """.data(using: .utf8)!
        let decoded = try DisplayOCRTraining.label(from: legacy)
        #expect(decoded.imageFileName == "image.png")
        #expect(decoded.imageFileNames == ["image.png"])
        #expect(decoded.exampleId == nil)
        #expect(decoded.expectedStructuredFields == nil)
        #expect(decoded.fieldAverages == nil)
    }

    @Test func makeOCRContextAppliesPerExamplePriorsFromLabel() {
        let label = DisplayOCRTrainingLabel(
            schemaVersion: 1,
            origin: .topLeft,
            imageFileName: "image.png",
            imagePixelWidth: 10,
            imagePixelHeight: 10,
            sourceName: nil,
            panel: DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1),
            rows: [],
            entityName: "FuelPurchase",
            fieldAverages: ["pricePerGallon": 4.34, "gallons": 12.0],
            fieldAverageMaxPercentDeviation: 40,
            fieldFractionDigits: ["gallons": 3]
        )
        let context = DisplayOCRLabEvaluation.makeOCRContext(from: label)
        #expect(context.entityName == "FuelPurchase")
        #expect(context.fieldAverages?["pricePerGallon"] == 4.34)
        #expect(context.fieldAverages?["gallons"] == 12.0)
        #expect(context.fieldAverageMaxPercentDeviation == 40)
        #expect(context.fieldFractionDigits?["gallons"] == 3)
    }

    @Test func makeOCRContextOmitsDeviationWhenLabelHasNone() {
        let label = DisplayOCRTrainingLabel(
            schemaVersion: 1,
            origin: .topLeft,
            imageFileName: "image.png",
            imagePixelWidth: 10,
            imagePixelHeight: 10,
            sourceName: nil,
            panel: DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1),
            rows: [],
            fieldAverages: ["pricePerGallon": 4.0]
        )
        let context = DisplayOCRLabEvaluation.makeOCRContext(from: label)
        #expect(context.fieldAverageMaxPercentDeviation == nil)
        #expect(context.resolvedFieldAverageMaxPercentDeviation == OCRContext.defaultFieldAverageMaxPercentDeviation)
    }

    // MARK: - Dual-axis evaluation

    @Test func structuredAxisPassesWhenFieldsMatchWithinTolerance() {
        let label = sampleLabel(
            expected: ["gallons": "8.022", "pricePerGallon": "3.459"],
            panel: DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.5, height: 0.4)
        )
        let result = OCRResult(
            extractedText: "ok",
            confidence: 1.0,
            structuredData: ["gallons": "8.022", "pricePerGallon": "3.459"],
            chosenPanelRect: label.panel
        )
        let score = DisplayOCRLabEvaluation.score(result: result, label: label)
        #expect(score.structured == .pass)
        #expect(score.localization == .pass)
        #expect(score.overallPass)
    }

    @Test func structuredAxisFailsWhenFieldLabelsAreSwapped() {
        let label = sampleLabel(
            expected: ["gallons": "8.022", "pricePerGallon": "3.459"],
            panel: DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.5, height: 0.4)
        )
        let result = OCRResult(
            extractedText: "ok",
            confidence: 1.0,
            structuredData: ["gallons": "3.459", "pricePerGallon": "8.022"],
            chosenPanelRect: label.panel
        )
        let score = DisplayOCRLabEvaluation.score(result: result, label: label)
        #expect(score.structured == .fail)
        #expect(score.overallPass == false)
        #expect(score.failureReasons.contains { $0.contains("gallons") })
    }

    @Test func structuredAxisFailsWhenFormulaIsInconsistent() {
        // Expected implies gallons * ppg ≈ totalCost; actual breaks that beyond 0.01.
        let label = sampleLabel(
            expected: [
                "gallons": "10.000",
                "pricePerGallon": "3.000",
                "totalCost": "30.000"
            ],
            panel: DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.5, height: 0.4),
            calculationCheck: true
        )
        let result = OCRResult(
            extractedText: "ok",
            confidence: 1.0,
            structuredData: [
                "gallons": "10.000",
                "pricePerGallon": "3.000",
                "totalCost": "25.000"
            ],
            chosenPanelRect: label.panel
        )
        let score = DisplayOCRLabEvaluation.score(result: result, label: label)
        #expect(score.structured == .fail)
        #expect(score.failureReasons.contains { $0.lowercased().contains("formula") || $0.lowercased().contains("calculation") })
    }

    @Test func localizationFailsEvenWhenStructuredIsCorrect() {
        let labeled = DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.4, height: 0.3)
        let wild = DisplayOCRNormalizedBox(x: 0.7, y: 0.7, width: 0.2, height: 0.2)
        let label = sampleLabel(expected: ["gallons": "8.022"], panel: labeled)
        let result = OCRResult(
            extractedText: "ok",
            confidence: 1.0,
            structuredData: ["gallons": "8.022"],
            chosenPanelRect: wild
        )
        let score = DisplayOCRLabEvaluation.score(result: result, label: label)
        #expect(score.structured == .pass)
        #expect(score.localization == .fail)
        #expect(score.overallPass == false)
        #expect(score.iou != nil)
        #expect((score.iou ?? 1) < DisplayOCRLabEvaluation.defaultLocalizationIoUThreshold)
    }

    @Test func missingExpectationsSkipsStructuredAxis() {
        let label = sampleLabel(expected: nil, panel: DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.5, height: 0.4))
        let result = OCRResult(
            extractedText: "ok",
            confidence: 1.0,
            structuredData: ["gallons": "1"],
            chosenPanelRect: label.panel
        )
        let score = DisplayOCRLabEvaluation.score(result: result, label: label)
        #expect(score.structured == .skip)
        #expect(score.localization == .pass)
        #expect(score.overallPass)
    }

    @Test func missingChosenPanelSkipsLocalizationAxis() {
        let label = sampleLabel(
            expected: ["gallons": "8.022"],
            panel: DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.5, height: 0.4)
        )
        let result = OCRResult(
            extractedText: "ok",
            confidence: 1.0,
            structuredData: ["gallons": "8.022"],
            chosenPanelRect: nil
        )
        let score = DisplayOCRLabEvaluation.score(result: result, label: label)
        #expect(score.localization == .skip)
        #expect(score.structured == .pass)
        #expect(score.overallPass)
    }

    @Test func offCenterChosenPanelStaysInOriginalNormalizedSpace() {
        // Contract: chosenPanelRect is original-image normalized, not crop-local.
        let offCenter = DisplayOCRNormalizedBox(x: 0.55, y: 0.40, width: 0.30, height: 0.20)
        let result = OCRResult(
            extractedText: "ok",
            confidence: 1.0,
            chosenPanelRect: offCenter
        )
        #expect(result.chosenPanelRect?.x == 0.55)
        #expect(result.chosenPanelRect?.y == 0.40)
        #expect((result.chosenPanelRect?.x ?? 0) > 0.5)
    }

    // MARK: - Summary / baseline / exit codes

    @Test func exitCodeZeroWhenAllScoredAxesPass() {
        let summary = DisplayOCRLabRunSummary(
            passCount: 2,
            failCount: 0,
            skipCount: 1,
            examples: []
        )
        #expect(DisplayOCRLabBulkCheck.exitCode(for: summary, baseline: nil) == 0)
    }

    @Test func exitCodeOneWhenAnyScoredFailure() {
        let summary = DisplayOCRLabRunSummary(
            passCount: 1,
            failCount: 1,
            skipCount: 0,
            examples: [
                DisplayOCRLabExampleScore(
                    exampleId: "ex-1",
                    folderName: "folder-a",
                    structured: .fail,
                    localization: .pass,
                    failureReasons: ["gallons mismatch"]
                )
            ]
        )
        #expect(DisplayOCRLabBulkCheck.exitCode(for: summary, baseline: nil) == 1)
    }

    @Test func exitCodeTwoForUsageErrors() {
        #expect(DisplayOCRLabBulkCheck.usageErrorExitCode == 2)
    }

    @Test func baselineCompareDetectsLostPass() {
        let prior = DisplayOCRLabRunSummary(
            passCount: 1,
            failCount: 0,
            skipCount: 0,
            examples: [
                DisplayOCRLabExampleScore(
                    exampleId: "ex-1",
                    folderName: "a",
                    structured: .pass,
                    localization: .pass,
                    failureReasons: []
                )
            ]
        )
        let current = DisplayOCRLabRunSummary(
            passCount: 0,
            failCount: 1,
            skipCount: 0,
            examples: [
                DisplayOCRLabExampleScore(
                    exampleId: "ex-1",
                    folderName: "a",
                    structured: .fail,
                    localization: .pass,
                    failureReasons: ["gallons mismatch"]
                )
            ]
        )
        let diff = DisplayOCRLabBulkCheck.compare(current: current, baseline: prior)
        #expect(diff.lostPasses.contains("ex-1"))
        #expect(DisplayOCRLabBulkCheck.exitCode(for: current, baseline: prior) == 1)
    }

    @Test func summaryJSONRoundTripsRunMetadataAndExampleIds() throws {
        let summary = DisplayOCRLabRunSummary(
            passCount: 1,
            failCount: 0,
            skipCount: 0,
            contextMode: "app",
            localizationIoUThreshold: 0.5,
            examples: [
                DisplayOCRLabExampleScore(
                    exampleId: "ex-stable-001",
                    folderName: "uuid-folder",
                    structured: .pass,
                    localization: .pass,
                    iou: 0.92,
                    failureReasons: []
                )
            ],
            timestamp: "2026-11-16T22:00:00Z",
            operatingSystem: "macOS 15.0",
            sixLayerVersion: "1.2.3",
            xcodeVersion: "16.0"
        )
        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(DisplayOCRLabRunSummary.self, from: data)
        #expect(decoded.examples.first?.exampleId == "ex-stable-001")
        #expect(decoded.contextMode == "app")
        #expect(decoded.localizationIoUThreshold == 0.5)
        #expect(decoded.passCount == 1)
        #expect(decoded.operatingSystem == "macOS 15.0")
        #expect(decoded.sixLayerVersion == "1.2.3")
        #expect(decoded.xcodeVersion == "16.0")
        #expect(decoded.timestamp == "2026-11-16T22:00:00Z")
    }

    @Test func evaluateAttachesHostRunMetadata() {
        let summary = DisplayOCRLabBulkCheck.evaluate(
            examples: [],
            resultsByExampleId: [:],
            contextMode: "app"
        )
        #expect(summary.timestamp != nil)
        #expect(!(summary.timestamp ?? "").isEmpty)
        #expect(summary.operatingSystem != nil)
        #expect(!(summary.operatingSystem ?? "").isEmpty)
        // sixLayerVersion / xcodeVersion are best-effort when discoverable.
        #expect(summary.contextMode == "app")
    }

    @Test func authoringAssistSeedIsEditableDraftNotSilentTruth() {
        let draft = DisplayOCRLabEvaluation.seedExpectedFields(
            fromConfirmedRows: [
                ("gallons", "8.022"),
                ("pricePerGallon", "3.459")
            ]
        )
        #expect(draft["gallons"] == "8.022")
        // Seed is a draft map — callers must confirm before writing as ground truth.
        #expect(DisplayOCRLabEvaluation.authoringAssistAutoCommitsGroundTruth == false)
    }

    // MARK: - Production chosenPanelRect from decode

    // MARK: - Bulk library evaluation core

    @Test func bulkEvaluatePassesTinyLibraryAndExitZero() {
        let panel = DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.5, height: 0.4)
        let label = sampleLabel(expected: ["gallons": "8.022"], panel: panel)
        let result = OCRResult(
            extractedText: "ok",
            confidence: 1.0,
            structuredData: ["gallons": "8.022"],
            chosenPanelRect: panel
        )
        let summary = DisplayOCRLabBulkCheck.evaluate(
            examples: [(folderName: "folder-a", label: label)],
            resultsByExampleId: ["ex-sample": result],
            contextMode: "app"
        )
        #expect(summary.passCount == 1)
        #expect(summary.failCount == 0)
        #expect(summary.contextMode == "app")
        #expect(DisplayOCRLabBulkCheck.exitCode(for: summary, baseline: nil) == 0)
    }

    @Test func bulkEvaluateReportsFailureAndExitOne() {
        let panel = DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.5, height: 0.4)
        let label = sampleLabel(expected: ["gallons": "8.022"], panel: panel)
        let result = OCRResult(
            extractedText: "ok",
            confidence: 1.0,
            structuredData: ["gallons": "9.999"],
            chosenPanelRect: panel
        )
        let summary = DisplayOCRLabBulkCheck.evaluate(
            examples: [(folderName: "folder-a", label: label)],
            resultsByExampleId: ["ex-sample": result],
            contextMode: "app"
        )
        #expect(summary.failCount == 1)
        #expect(summary.examples.first?.exampleId == "ex-sample")
        #expect(summary.examples.first?.structured == .fail)
        #expect(DisplayOCRLabBulkCheck.exitCode(for: summary, baseline: nil) == 1)
    }

    @Test func bulkEvaluateSkipsUnreadableWithoutFailingExit() {
        let summary = DisplayOCRLabBulkCheck.evaluate(
            examples: [],
            resultsByExampleId: [:],
            skippedUnreadableCount: 2,
            contextMode: "app"
        )
        #expect(summary.skipCount == 2)
        #expect(summary.failCount == 0)
        #expect(DisplayOCRLabBulkCheck.exitCode(for: summary, baseline: nil) == 0)
    }

    @Test func appModeOCRRunnerInvokesInjectedLibraryEntryPoint() async throws {
        final class Spy: @unchecked Sendable {
            var callCount = 0
            var lastEntityName: String?
        }
        let spy = Spy()
        let panel = DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.5, height: 0.4)
        let label = sampleLabel(expected: ["gallons": "8.022"], panel: panel)
        var labelWithEntity = label
        labelWithEntity.entityName = "FuelPurchase"
        let image = grayImage(width: 8, height: 8, fill: 180)
        let package = DisplayOCRTrainingPackage(
            label: labelWithEntity,
            imagePNG: pngData(from: image)
        )
        let summary = try await DisplayOCRLabBulkCheck.runAppMode(
            examples: [(folderName: "a", package: package)],
            process: { image, context in
                spy.callCount += 1
                spy.lastEntityName = context.entityName
                return OCRResult(
                    extractedText: "ok",
                    confidence: 1.0,
                    structuredData: ["gallons": "8.022"],
                    chosenPanelRect: panel
                )
            }
        )
        #expect(spy.callCount == 1)
        #expect(spy.lastEntityName == "FuelPurchase")
        #expect(summary.passCount == 1)
        #expect(summary.contextMode == "app")
    }

    @Test func decodeRecordsChosenPanelRectFromPanelLocatorInOriginalNormalizedCoords() {
        let width = 200
        let height = 100
        let image = grayImage(width: width, height: height, fill: 200)
        let panelPixels = CGRect(x: 110, y: 40, width: 60, height: 40)
        let decoded = SevenSegmentOCR.decode(
            cgImage: image,
            deskewMaximumDegrees: 0,
            localizeDigitPanel: true,
            panelLocator: DisplayOCRPanelLocator { _ in panelPixels }
        )
        let expected = DisplayOCRNormalizedBox(
            pixelRect: panelPixels,
            imageWidth: width,
            imageHeight: height
        )
        #expect(decoded.chosenPanelRect != nil)
        #expect(abs((decoded.chosenPanelRect?.x ?? -1) - expected.x) < 0.001)
        #expect(abs((decoded.chosenPanelRect?.y ?? -1) - expected.y) < 0.001)
        #expect(abs((decoded.chosenPanelRect?.width ?? -1) - expected.width) < 0.001)
        #expect(abs((decoded.chosenPanelRect?.height ?? -1) - expected.height) < 0.001)
        #expect((decoded.chosenPanelRect?.x ?? 0) > 0.5)
    }

    @Test func processSevenSegmentStructuredForwardsChosenPanelRect() async throws {
        let width = 200
        let height = 100
        let image = grayImage(width: width, height: height, fill: 200)
        let panelPixels = CGRect(x: 110, y: 40, width: 60, height: 40)
        let context = OCRContext(
            processingMode: .ssocr,
            panelLocator: DisplayOCRPanelLocator { _ in panelPixels }
        )
        let strategy = OCRStrategy(
            supportedTextTypes: [],
            supportedLanguages: [.english],
            processingMode: .ssocr
        )
        let result = try await OCRService().processImage(
            PlatformImage(cgImage: image),
            context: context,
            strategy: strategy
        )
        let expected = DisplayOCRNormalizedBox(
            pixelRect: panelPixels,
            imageWidth: width,
            imageHeight: height
        )
        #expect(result.chosenPanelRect != nil)
        #expect(abs((result.chosenPanelRect?.x ?? -1) - expected.x) < 0.001)
        #expect((result.chosenPanelRect?.x ?? 0) > 0.5)
    }

    // MARK: - Helpers

    private func grayImage(width: Int, height: Int, fill: UInt8) -> CGImage {
        let pixels = [UInt8](repeating: fill, count: width * height)
        let data = Data(pixels) as CFData
        let provider = CGDataProvider(data: data)!
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }


    private func sampleLabel(
        expected: [String: String]?,
        panel: DisplayOCRNormalizedBox,
        calculationCheck: Bool = false
    ) -> DisplayOCRTrainingLabel {
        DisplayOCRTrainingLabel(
            schemaVersion: 1,
            origin: .topLeft,
            imageFileName: "image.png",
            imagePixelWidth: 100,
            imagePixelHeight: 80,
            sourceName: nil,
            panel: panel,
            rows: [],
            exampleId: "ex-sample",
            expectedStructuredFields: expected,
            entityName: calculationCheck ? "FuelPurchase" : nil
        )
    }

    private func pngData(from image: CGImage) -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        )!
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return data as Data
    }
}
