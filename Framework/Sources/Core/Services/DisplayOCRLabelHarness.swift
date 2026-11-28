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

/// Editable label state for the harness. Drawn boxes and typed text live in one row,
/// so export pairs them by construction. OCR output is applied as suggestions only.
/// Any change to photo, panel, or rows bumps `generation`, which invalidates in-flight OCR.
public struct DisplayOCRLabelDraft: Equatable, Sendable {
    public struct Row: Equatable, Sendable {
        public var box: CGRect?
        public var text: String

        public init(box: CGRect?, text: String = "") {
            self.box = box
            self.text = text
        }
    }

    public private(set) var generation: Int = 0
    public private(set) var panel: CGRect?
    public private(set) var rows: [Row] = []

    public init() {}

    public mutating func setPanel(_ rect: CGRect) {
        panel = rect
        generation &+= 1
    }

    public mutating func addRowBox(_ rect: CGRect) {
        rows.append(Row(box: rect))
        generation &+= 1
    }

    public mutating func setText(_ text: String, at index: Int) {
        guard rows.indices.contains(index) else { return }
        rows[index].text = text
    }

    public mutating func clearROIs() {
        panel = nil
        rows = []
        generation &+= 1
    }

    /// Applies OCR rows (top to bottom) as suggestions.
    /// - Returns: a status notice, or nil when the request is stale and was discarded.
    /// - Pairing: OCR row `i` goes to the `i`-th drawn box from the top. This is only
    ///   reliable when OCR finds every drawn row, so a count mismatch is reported.
    /// - Never removes boxes or user text. Only empty rows receive suggestions.
    public mutating func applySuggestions(_ texts: [String], requestGeneration: Int) -> String? {
        guard requestGeneration == generation else { return nil }

        let boxedIndices = rows.indices
            .filter { rows[$0].box != nil }
            .sorted { (rows[$0].box?.midY ?? 0) > (rows[$1].box?.midY ?? 0) }

        for (position, index) in boxedIndices.enumerated() where position < texts.count {
            if rows[index].text.isEmpty {
                rows[index].text = texts[position]
            }
        }
        rows.append(contentsOf: texts.dropFirst(boxedIndices.count).map { Row(box: nil, text: $0) })

        if texts.isEmpty {
            return "Decode returned no rows; boxes and text kept"
        }
        if texts.count != boxedIndices.count {
            return "OCR found \(texts.count) row(s) for \(boxedIndices.count) box(es); check pairing"
        }
        return "Decoded \(texts.count) row(s)"
    }
}
