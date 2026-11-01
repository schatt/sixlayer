//
//  DisplayOCRLabelHarness.swift
//  SixLayerFramework
//
//  Non-UI helpers for display OCR label harness Phase A (#609).
//

import CoreGraphics
import Foundation

/// Crops a panel ROI and runs ``OCRProcessingMode/ssocr`` for the label harness.
public enum DisplayOCRLabelHarness {

    public static func makeContext(deskewMaximumDegrees: Double = 3) -> OCRContext {
        OCRContext(
            processingMode: .ssocr,
            segmentDeskewMaximumDegrees: deskewMaximumDegrees
        )
    }

    public static func makeStrategy() -> OCRStrategy {
        OCRStrategy(
            supportedTextTypes: [.number],
            supportedLanguages: [.english],
            processingMode: .ssocr
        )
    }

    public static func pixelCropRect(
        panelNormalizedRect: CGRect,
        imageSize: CGSize
    ) -> CGRect {
        OCRBoundingBoxLayout.visionNormalizedToImagePixels(
            panelNormalizedRect,
            imageSize: imageSize
        )
    }

    public static func decode(
        image: PlatformImage,
        panelNormalizedRect: CGRect,
        deskewMaximumDegrees: Double = 3,
        service: OCRServiceProtocol
    ) async throws -> OCRResult {
        let cropRect = pixelCropRect(
            panelNormalizedRect: panelNormalizedRect,
            imageSize: image.size
        )
        let cropped = image.cropped(to: cropRect)
        let context = makeContext(deskewMaximumDegrees: deskewMaximumDegrees)
        let strategy = makeStrategy()
        return try await service.processImage(cropped, context: context, strategy: strategy)
    }

    public static func rowTexts(from result: OCRResult) -> [String] {
        result.extractedText
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    public static func makePackage(
        image: PlatformImage,
        panelNormalizedRect: CGRect,
        rows: [(boundingBox: CGRect?, confirmedText: String)],
        deskewMaximumDegrees: Double?
    ) -> DisplayOCRLabelPackage? {
        guard let png = image.exportPNG() else { return nil }
        let labeledRows = rows.map { row in
            DisplayOCRLabeledRow(
                boundingBox: row.boundingBox.map(DisplayOCRLabelRect.init),
                confirmedText: row.confirmedText
            )
        }
        return DisplayOCRLabelPackage(
            imagePNGData: png,
            panelBoundingBox: DisplayOCRLabelRect(panelNormalizedRect),
            rows: labeledRows,
            segmentDeskewMaximumDegrees: deskewMaximumDegrees
        )
    }
}
