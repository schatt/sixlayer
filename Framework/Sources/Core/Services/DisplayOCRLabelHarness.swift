//
//  DisplayOCRLabelHarness.swift
//  SixLayerFramework
//
//  Non-UI helpers for display OCR label harness Phase A (#609).
//

import CoreGraphics
import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#endif

/// Crops a panel ROI and runs ``OCRProcessingMode/ssocr`` for the label harness.
public enum DisplayOCRLabelHarness {

    /// Upright, scale-1 copy whose `size` is the pixel grid the crop math uses.
    /// UIKit: `UIImage.size` is points and orientation-aware, while `CGImage.cropping(to:)`
    /// takes raw pixels in unrotated bitmap space. Redrawing resolves both mismatches.
    /// AppKit: `NSImage` drawing is point-based, so the image passes through unchanged.
    public static func uprightPixelImage(_ image: PlatformImage) -> PlatformImage {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let uiImage = image.uiImage
        let target = CGSize(
            width: uiImage.size.width * uiImage.scale,
            height: uiImage.size.height * uiImage.scale
        )
        guard target.width > 0, target.height > 0 else { return image }
        UIGraphicsBeginImageContextWithOptions(target, false, 1)
        defer { UIGraphicsEndImageContext() }
        uiImage.draw(in: CGRect(origin: .zero, size: target))
        guard let redrawn = UIGraphicsGetImageFromCurrentImageContext() else { return image }
        return PlatformImage(uiImage: redrawn)
        #else
        return image
        #endif
    }

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
        let upright = uprightPixelImage(image)
        let cropRect = pixelCropRect(
            panelNormalizedRect: panelNormalizedRect,
            imageSize: upright.size
        )
        let cropped = upright.cropped(to: cropRect)
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
