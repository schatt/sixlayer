//
//  OCRSegmentFieldBinding720Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Segment-to-field binding exposed on OCRResult (#720).
//

import CoreGraphics
import Foundation
import Testing
@testable import SixLayerFramework

@Suite("OCR segment-to-field binding (#720)")
struct OCRSegmentFieldBinding720Tests {

    private let service = OCRService()

    // MARK: - Binding helper keeps the chosen segment box

    @Test func assignSegments_returnsChosenSegmentTextAndBox() {
        let fragments = pumpRows(sale: "32.88", volume: "7.740")
        let segments = OCRSegmentLabelBinding.assignSegments(
            fragments: fragments.all,
            patterns: ["sale": "This Sale", "volume": "Gallons"]
        )

        #expect(segments["sale"]?.text == "32.88")
        #expect(segments["sale"]?.boundingBox == fragments.saleSegment.boundingBox)
        #expect(segments["volume"]?.text == "7.740")
        #expect(segments["volume"]?.boundingBox == fragments.volumeSegment.boundingBox)
    }

    @Test func assignSegments_omitsRowWithoutPrintedLabel() {
        let fragments = pumpRows(sale: "32.88", volume: "7.740", volumeLabel: nil)
        let segments = OCRSegmentLabelBinding.assignSegments(
            fragments: fragments.all,
            patterns: ["sale": "This Sale", "volume": "Gallons"]
        )

        #expect(segments["sale"]?.text == "32.88")
        #expect(segments["volume"] == nil)
    }

    // MARK: - Pipeline exposes the same binding on the result path

    @Test func applyStructuredExtraction_exposesFieldSegmentsForAssignedHints() {
        let fragments = pumpRows(sale: "32.88", volume: "7.740")
        let context = OCRContext(
            extractionHints: ["sale": "This Sale", "volume": "Gallons"],
            extractionMode: .custom
        )
        let base = OCRResult(
            extractedText: "32.88\n7.740",
            confidence: 1,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 0,
            language: .english
        )

        let outcome = service.structuredExtractionOutcome(
            from: base,
            context: context,
            recognitionLines: fragments.all
        )

        #expect(outcome.fieldSegments["volume"]?.text == "7.740")
        #expect(outcome.fieldSegments["volume"]?.boundingBox == fragments.volumeSegment.boundingBox)
        #expect(outcome.fieldSegments["sale"]?.text == "32.88")
    }

    // MARK: - OCRResult public property

    @Test func filtered_belowThreshold_clearsFieldSegments() {
        let result = OCRResult(
            extractedText: "7.740",
            confidence: 0.1,
            fieldSegments: [
                "volume": OCRFieldSegment(text: "7.740", boundingBox: CGRect(x: 0.2, y: 0.4, width: 0.2, height: 0.1))
            ]
        )

        #expect(result.fieldSegments["volume"]?.text == "7.740")
        #expect(result.filtered(by: 0.5).fieldSegments.isEmpty)
    }

    // MARK: - Fixtures

    private struct PumpRows {
        let all: [OCRRecognizedText]
        let saleSegment: OCRRecognizedText
        let volumeSegment: OCRRecognizedText
    }

    /// Two stacked rows: a printed label sits directly above each digit row.
    private func pumpRows(sale: String, volume: String, volumeLabel: String? = "Gallons") -> PumpRows {
        let saleSegment = fragment(sale, x: 0.2, y: 0.70, w: 0.2, h: 0.10, role: .segment)
        let volumeSegment = fragment(volume, x: 0.2, y: 0.40, w: 0.2, h: 0.10, role: .segment)
        var all = [
            fragment("This Sale", x: 0.2, y: 0.82, w: 0.2, h: 0.04, role: .label),
            saleSegment,
            volumeSegment
        ]
        if let volumeLabel {
            all.insert(fragment(volumeLabel, x: 0.2, y: 0.52, w: 0.2, h: 0.04, role: .label), at: 2)
        }
        return PumpRows(all: all, saleSegment: saleSegment, volumeSegment: volumeSegment)
    }

    private func fragment(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        w: CGFloat,
        h: CGFloat,
        role: OCRRecognizedText.Role
    ) -> OCRRecognizedText {
        OCRRecognizedText(text: text, boundingBox: CGRect(x: x, y: y, width: w, height: h), confidence: 1, role: role)
    }
}
