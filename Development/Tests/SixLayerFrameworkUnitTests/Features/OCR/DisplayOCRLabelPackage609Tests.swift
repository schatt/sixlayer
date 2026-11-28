//
//  DisplayOCRLabelPackage609Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Phase A label package + ssocr harness decode path (#609).
//

import CoreGraphics
import Foundation
#if os(iOS)
import UIKit
#endif
import Testing
@testable import SixLayerFramework

@Suite("Display OCR label package (#609)")
struct DisplayOCRLabelPackage609Tests {

    @Test func labelPackageRoundTripsJSONWithPanelRowsAndDeskew() throws {
        let png = Data([0x89, 0x50, 0x4E, 0x47])
        let panel = DisplayOCRLabelRect(x: 0.1, y: 0.2, width: 0.5, height: 0.3)
        let rowBox = DisplayOCRLabelRect(x: 0.1, y: 0.45, width: 0.5, height: 0.1)
        let original = DisplayOCRLabelPackage(
            schemaVersion: DisplayOCRLabelPackage.currentSchemaVersion,
            imagePNGData: png,
            panelBoundingBox: panel,
            rows: [
                DisplayOCRLabeledRow(boundingBox: rowBox, confirmedText: "32.88"),
                DisplayOCRLabeledRow(boundingBox: nil, confirmedText: "8.022")
            ],
            segmentDeskewMaximumDegrees: 3
        )

        let data = try original.encodedJSON()
        let decoded = try DisplayOCRLabelPackage.decode(from: data)

        #expect(decoded == original)
        #expect(decoded.schemaVersion == DisplayOCRLabelPackage.currentSchemaVersion)
        #expect(decoded.rows.map(\.confirmedText) == ["32.88", "8.022"])
    }

    @Test func harnessSsocrContextAndStrategySelectSevenSegmentMode() {
        let context = DisplayOCRLabelHarness.makeContext(deskewMaximumDegrees: 2)
        let strategy = DisplayOCRLabelHarness.makeStrategy()

        #expect(context.processingMode == .ssocr)
        #expect(context.segmentDeskewMaximumDegrees == 2)
        #expect(strategy.processingMode == .ssocr)
        #expect(strategy.processingMode.serviceVisionRecognition == nil)
    }

    @Test func harnessDecodePassesSsocrStrategyToService() async throws {
        let recorder = RecordingOCRService()
        let image = solidPlatformImage(width: 40, height: 20)
        let panel = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)

        _ = try await DisplayOCRLabelHarness.decode(
            image: image,
            panelNormalizedRect: panel,
            deskewMaximumDegrees: 3,
            service: recorder
        )

        #expect(recorder.processImageCallCount == 1)
        #expect(recorder.lastStrategy?.processingMode == .ssocr)
        #expect(recorder.lastContext?.processingMode == .ssocr)
    }

    @Test func harnessBuildsPackageFromConfirmedRowTexts() {
        let image = solidPlatformImage(width: 40, height: 20)
        let panel = CGRect(x: 0.05, y: 0.1, width: 0.9, height: 0.8)
        let row = CGRect(x: 0.05, y: 0.55, width: 0.9, height: 0.3)

        let package = DisplayOCRLabelHarness.makePackage(
            image: image,
            panelNormalizedRect: panel,
            rows: [
                (boundingBox: row, confirmedText: "32.88"),
                (boundingBox: nil, confirmedText: "8.022")
            ],
            deskewMaximumDegrees: 3
        )

        #expect(package != nil)
        #expect(package?.panelBoundingBox.cgRect == panel)
        #expect(package?.rows.count == 2)
        #expect(package?.rows[0].confirmedText == "32.88")
        #expect(package?.rows[0].boundingBox?.cgRect == row)
        #expect(package?.rows[1].boundingBox == nil)
        #expect(package?.segmentDeskewMaximumDegrees == 3)
        #expect(package.map { !$0.imagePNGData.isEmpty } == true)
    }

    @Test func rowTextsSplitExtractedTextOnNewlines() {
        let result = OCRResult(extractedText: "32.88\n8.022", confidence: 1)
        #expect(DisplayOCRLabelHarness.rowTexts(from: result) == ["32.88", "8.022"])
    }

    #if os(iOS)
    // Lane-only (UIKit): UIImage.size is points while CGImage.cropping(to:) takes pixels.
    // macOS NSImage crop is point-based via draw(from:), so no equivalent failure mode.
    @Test func harnessCropsPanelInPixelsForScaledImage() async throws {
        let recorder = RecordingOCRService()
        // 80x40 pixels at scale 2 => 40x20 points.
        let image = solidUIKitImage(pixelWidth: 80, pixelHeight: 40, scale: 2, orientation: .up)

        _ = try await DisplayOCRLabelHarness.decode(
            image: image,
            panelNormalizedRect: CGRect(x: 0, y: 0, width: 0.5, height: 1),
            service: recorder
        )

        let crop = try #require(recorder.lastImage)
        // Left half of 80 px wide x full 40 px tall.
        #expect(crop.size == CGSize(width: 40, height: 40))
    }

    @Test func harnessCropsUprightOrientationForRotatedImage() async throws {
        let recorder = RecordingOCRService()
        // Raw bitmap 80x40 px, orientation .right => displayed/upright 40x80.
        let image = solidUIKitImage(pixelWidth: 80, pixelHeight: 40, scale: 1, orientation: .right)

        _ = try await DisplayOCRLabelHarness.decode(
            image: image,
            panelNormalizedRect: CGRect(x: 0, y: 0, width: 1, height: 0.25),
            service: recorder
        )

        let crop = try #require(recorder.lastImage)
        // Bottom quarter of the upright 40x80 image => 40 px wide x 20 px tall.
        #expect(crop.size == CGSize(width: 40, height: 20))
    }
    #endif

    @Test func pixelCropUsesVisionNormalizedPanel() {
        let imageSize = CGSize(width: 200, height: 100)
        let normalized = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.3)
        let pixels = DisplayOCRLabelHarness.pixelCropRect(
            panelNormalizedRect: normalized,
            imageSize: imageSize
        )
        #expect(pixels == OCRBoundingBoxLayout.visionNormalizedToImagePixels(normalized, imageSize: imageSize))
    }
}

// MARK: - Helpers

private final class RecordingOCRService: OCRServiceProtocol, @unchecked Sendable {
    private(set) var processImageCallCount = 0
    private(set) var lastContext: OCRContext?
    private(set) var lastStrategy: OCRStrategy?
    private(set) var lastImage: PlatformImage?

    var isAvailable: Bool { true }
    var capabilities: OCRCapabilities {
        OCRCapabilities(
            supportsVision: false,
            supportedLanguages: [.english],
            supportedTextTypes: [.number],
            maxImageSize: CGSize(width: 4000, height: 4000),
            processingTimeEstimate: 0.01
        )
    }

    func processImage(
        _ image: PlatformImage,
        context: OCRContext,
        strategy: OCRStrategy
    ) async throws -> OCRResult {
        processImageCallCount += 1
        lastImage = image
        lastContext = context
        lastStrategy = strategy
        return OCRResult(extractedText: "1", confidence: 1)
    }
}

private func solidPlatformImage(width: Int, height: Int) -> PlatformImage {
    let colorSpace = CGColorSpaceCreateDeviceGray()
    var pixels = [UInt8](repeating: 200, count: width * height)
    let data = CFDataCreateMutable(nil, pixels.count)!
    CFDataAppendBytes(data, &pixels, pixels.count)
    let provider = CGDataProvider(data: data)!
    let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        bytesPerRow: width,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
    return PlatformImage(cgImage: cgImage)
}

#if os(iOS)
private func solidUIKitImage(
    pixelWidth: Int,
    pixelHeight: Int,
    scale: CGFloat,
    orientation: UIImage.Orientation
) -> PlatformImage {
    let cgImage = solidPlatformImage(width: pixelWidth, height: pixelHeight).uiImage.cgImage!
    return PlatformImage(uiImage: UIImage(cgImage: cgImage, scale: scale, orientation: orientation))
}
#endif
