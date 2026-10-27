//
//  OCRSevenSegment576Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Seven-segment decode and label binding (#576).
//

import CoreGraphics
import Foundation
import Testing
@testable import SixLayerFramework

@Suite("Seven-segment OCR (#576)")
struct OCRSevenSegment576Tests {

    // MARK: - Mode

    @Test func ssocrModeIsNamedAndDoesNotSelectAVisionLevel() {
        #expect(OCRProcessingMode.ssocr.rawValue == "ssocr")
        #expect(OCRProcessingMode.ssocr.displayName == "Seven-segment")
        #expect(OCRProcessingMode.fast.serviceVisionRecognition == .fast)
        #expect(OCRProcessingMode.standard.serviceVisionRecognition == .accurate)
        #expect(OCRProcessingMode.accurate.serviceVisionRecognition == .accurate)
        #expect(OCRProcessingMode.neural.serviceVisionRecognition == .accurate)
        #expect(OCRProcessingMode.ssocr.serviceVisionRecognition == nil)
        #expect(OCRProcessingMode.neural.safetyVisionRecognition == .accurate)
        #expect(OCRProcessingMode.fast.safetyVisionRecognition == .fast)
        #expect(OCRProcessingMode.standard.safetyVisionRecognition == .fast)
        #expect(OCRProcessingMode.accurate.safetyVisionRecognition == .fast)
        #expect(OCRProcessingMode.ssocr.safetyVisionRecognition == nil)
        #expect(OCRProcessingMode.fast.labelPassVisionRecognition == .fast)
        #expect(OCRProcessingMode.accurate.labelPassVisionRecognition == .accurate)
        let context = OCRContext()
        #expect(context.processingMode == .accurate)
        #expect(context.labelProcessingMode == .accurate)
        #expect(context.segmentDeskewMaximumDegrees == 3)
        #expect(context.suppliedLabelFragments.isEmpty)
    }

    // MARK: - Glyphs

    @Test func glyphTableMapsExactPatternsAndHoldsAnUnknownCell() {
        #expect(SevenSegmentGlyph.character(for: []) == nil)
        #expect(SevenSegmentGlyph.character(for: digit(0)) == "0")
        #expect(SevenSegmentGlyph.character(for: digit(1)) == "1")
        #expect(SevenSegmentGlyph.character(for: digit(2)) == "2")
        #expect(SevenSegmentGlyph.character(for: digit(3)) == "3")
        #expect(SevenSegmentGlyph.character(for: digit(4)) == "4")
        #expect(SevenSegmentGlyph.character(for: digit(5)) == "5")
        #expect(SevenSegmentGlyph.character(for: digit(6)) == "6")
        #expect(SevenSegmentGlyph.character(for: digit(7)) == "7")
        #expect(SevenSegmentGlyph.character(for: digit(8)) == "8")
        #expect(SevenSegmentGlyph.character(for: digit(9)) == "9")
        #expect(SevenSegmentGlyph.character(for: [.g]) == "-")
        #expect(SevenSegmentGlyph.character(for: [.a]) == "_")
        let onlyA = SevenSegmentGlyph.interpreted([.a])
        #expect(onlyA?.character == "_")
        #expect(onlyA?.confidence == 0)

        var two = digit(2)
        two.remove(.a)
        let miss = SevenSegmentGlyph.interpreted(two)
        #expect(miss?.character == "2")
        #expect(miss.map { abs($0.confidence - (6.0 / 7.0)) < 0.001 } == true)
    }

    // MARK: - Rows and groups

    @Test func oneRowDecodesDigitsAndABaselineDot() {
        let result = decode(panel(["31.25"]))
        #expect(result.extractedText == "31.25")
        #expect(segmentTexts(result) == ["31.25"])
        #expect(result.confidence == 1)
        #expect(result.boundingBoxes == segmentBoxes(result))
    }

    @Test func twoThreeAndFourRowsComeBackInOrder() {
        #expect(decode(panel(["32.88", "8.022"])).extractedText == "32.88\n8.022")
        #expect(decode(panel(["11", "22", "33"])).extractedText == "11\n22\n33")
        #expect(decode(panel(["11", "22", "33", "44"])).extractedText == "11\n22\n33\n44")
    }

    @Test func wideGapSplitsGroupsAndAnEqualGapDoesNot() {
        let split = decode(panel(["12 34"]))
        #expect(split.extractedText == "12  34")
        #expect(segmentTexts(split) == ["12", "34"])

        let five = decode(panel(["1.11 2.22 3.33 4.44 5.55"]))
        #expect(five.extractedText == "1.11  2.22  3.33  4.44  5.55")
        #expect(segmentTexts(five) == ["1.11", "2.22", "3.33", "4.44", "5.55"])

        let glued = decode(panel(["1234"]))
        #expect(glued.extractedText == "1234")
        #expect(segmentTexts(glued) == ["1234"])
    }

    @Test func paddedCanvasKeepsTheSameGroupsAndRows() {
        let rows = [atoms("1.11 2.22"), atoms("3.0")]
        let content = SegmentPanel.contentSize(rows: rows)
        let tight = SegmentPanel.render(rows: rows, padding: 2)
        let padded = SegmentPanel.render(rows: rows, padding: 4 * max(content.width, content.height))
        let tightResult = decode(tight)
        let paddedResult = decode(padded)
        #expect(paddedResult.extractedText == tightResult.extractedText)
        #expect(segmentTexts(paddedResult) == segmentTexts(tightResult))
        #expect(tightResult.extractedText == "1.11  2.22\n3.0")
    }

    @Test func commaTailStaysOnItsRow() {
        let rows = [atoms("1,25"), atoms("30")]
        let result = decode(SegmentPanel.render(rows: rows, padding: 8))
        #expect(result.extractedText == "1,25\n30")
        let content = SegmentPanel.contentSize(rows: rows)
        let padded = decode(SegmentPanel.render(rows: rows, padding: 4 * max(content.width, content.height)))
        #expect(padded.extractedText == "1,25\n30")
    }

    // MARK: - Marks

    @Test func marksStayInsideTheFragment() {
        #expect(decode(panel(["3125"])).extractedText == "3125")
        #expect(!decode(panel(["3125"])).extractedText.contains("."))
        #expect(decode(panel(["1,234.56"])).extractedText == "1,234.56")
        #expect(segmentTexts(decode(panel(["1,234.56"]))).count == 1)
        #expect(decode(panel(["-12.5"])).extractedText == "-12.5")
        #expect(decode(panel(["12:30"])).extractedText == "12:30")
        let held = decode(panel(["8_2"]))
        #expect(held.extractedText == "8_2")
        #expect(segmentTexts(held) == ["8_2"])
    }

    @Test func paintedOppositePolarityMarksStayInTheFragment() {
        let period = SegmentPanel.render(rows: [[.digit(digit(3)), .digit(digit(1)), .oppositePeriod, .digit(digit(2)), .digit(digit(5))]])
        #expect(decode(period).extractedText == "31.25")
        let comma = SegmentPanel.render(rows: [[.digit(digit(1)), .oppositeComma, .digit(digit(2)), .digit(digit(5))]])
        #expect(decode(comma).extractedText == "1,25")
    }

    @Test func leadingEmptyCellDoesNotBecomeZero() {
        let result = decode(panel([" 12"]))
        #expect(result.extractedText == "12")
        #expect(!result.extractedText.contains("0"))
    }

    @Test func drawnMissOfOneSegmentKeepsTheGlyphBelowAnExactRead() {
        var two = digit(2)
        two.remove(.a)
        let result = decode(SegmentPanel.render(rows: [[.digit(two)]]))
        #expect(result.extractedText == "2")
        #expect(result.confidence > 0)
        #expect(result.confidence < 1)
        #expect(abs(result.confidence - (6.0 / 7.0)) < 0.02)
    }

    // MARK: - Confidence and non-segment ink

    @Test func unknownCellZerosOnlyItsFragment() {
        let result = decode(panel(["8_2 17.740"]))
        #expect(result.extractedText == "8_2  17.740")
        #expect(result.confidence == 0)
        let broken = result.recognizedTexts.first { $0.text.contains("_") }
        let clean = result.recognizedTexts.first { $0.text == "17.740" }
        #expect(broken?.role == .segment)
        #expect(broken?.confidence == 0)
        #expect(clean?.role == .segment)
        #expect(clean?.confidence == 1)
        #expect(result.extractedText.contains("17.740"))
    }

    @Test func filledInkBesideCleanRowsDoesNotCreateASegment() {
        var row = atoms("51.07")
        row.append(.gap(SegmentPanel.groupGap))
        row.append(contentsOf: atoms("17.740"))
        row.append(.gap(SegmentPanel.groupGap))
        row.append(.fill(width: 70, height: 70))
        let result = decode(SegmentPanel.render(rows: [row, [.fill(width: 160, height: 28)]]))
        #expect(result.extractedText == "51.07  17.740")
        #expect(segmentTexts(result) == ["51.07", "17.740"])
        #expect(result.confidence == 1)
        #expect(!result.extractedText.contains("_"))
        #expect(result.recognizedTexts.allSatisfy { $0.role == .segment })
    }

    @Test func lighterInkKeepsTheBaselineDot() {
        let image = SegmentPanel.render(
            rows: [atoms("31.25")],
            inkLevel: 100,
            backgroundLevel: 240
        )
        #expect(decode(image).extractedText == "31.25")
    }

    @Test func insetBezelStaysOutsideTheGlass() {
        // The frame is inside the crop. It does not touch the image edge,
        // so a border clear leaves it wrapped around the digits.
        let image = SegmentPanel.render(
            rows: [atoms("32.88"), atoms("8.022")],
            inkLevel: 140,
            backgroundLevel: 200,
            bezelLevel: 123,
            bezelWidth: 8,
            outerMargin: 24
        )
        let result = decode(image)
        #expect(result.extractedText == "32.88\n8.022")
        #expect(segmentTexts(result) == ["32.88", "8.022"])
    }

    @Test func strokeSizedWindowSeparatesAdjacentDigits() {
        // A window of one eighth of this crop is wider than the gap between digits.
        // The lit strokes are only a few levels darker than that gap, so the wide
        // window marks the gap as ink and the row becomes one blob.
        let image = SegmentPanel.render(
            rows: [atoms("32.88"), atoms("8.022")],
            inkLevel: 100,
            backgroundLevel: 130,
            scale: 4
        )
        let result = decode(image)
        #expect(result.extractedText == "32.88\n8.022")
        #expect(segmentTexts(result) == ["32.88", "8.022"])
    }

    @Test func bezelDarkerThanTheGlassKeepsWashedDigits() {
        // Scenario 1 hand crop, 2026-10-22: corners 123, glass ~200, digit cores ~140.
        // The corner ceiling is 114, so this ink is dropped even though it is darker than the glass.
        let image = SegmentPanel.render(
            rows: [atoms("32.88"), atoms("8.022")],
            inkLevel: 140,
            backgroundLevel: 200,
            bezelLevel: 123,
            bezelWidth: 8
        )
        let result = decode(image)
        #expect(result.extractedText == "32.88\n8.022")
        #expect(segmentTexts(result) == ["32.88", "8.022"])
    }

    @Test func inkCloserThanTheMarginIsNotADigit() {
        // Six levels under the glass is below the margin. Guessing a digit here is worse than silence.
        let image = SegmentPanel.render(
            rows: [atoms("32.88"), atoms("8.022")],
            inkLevel: 194,
            backgroundLevel: 200
        )
        let result = decode(image)
        #expect(result.extractedText == "")
        #expect(result.recognizedTexts.isEmpty)
    }

    @Test func thickStrokesDecodeWhenTheWindowWouldHaveCapped() {
        // A 12-pixel stroke scaled by 4 is 48 pixels, wider than the 41-pixel window.
        let image = SegmentPanel.render(
            rows: [atoms("32.88"), atoms("8.022")],
            inkLevel: 140,
            backgroundLevel: 200,
            bezelLevel: 123,
            bezelWidth: 8,
            scale: 4
        )
        #expect(decode(image).extractedText == "32.88\n8.022")
    }

    @Test func paleCommaDoesNotAskTheCorner() {
        // Ink 140 on glass 200 is not half of a bezel corner at 123.
        let image = SegmentPanel.render(
            rows: [atoms("1,234.56")],
            inkLevel: 140,
            backgroundLevel: 200,
            bezelLevel: 123,
            bezelWidth: 8
        )
        let result = decode(image)
        #expect(result.extractedText == "1,234.56")
    }

    @Test func glareAndBothPolaritiesDecodeTheSameDigits() {
        let rows = [atoms("31.25")]
        let glared = decode(SegmentPanel.render(rows: rows, glare: true))
        #expect(glared.extractedText == "31.25")
        let dark = decode(SegmentPanel.render(rows: rows, invert: false)).extractedText
        let light = decode(SegmentPanel.render(rows: rows, invert: true)).extractedText
        #expect(light == dark)
        #expect(light == "31.25")
    }

    @Test func deskewSearchesTheCallerMaximum() {
        let rows = [atoms("31.25")]
        let tilted = SegmentPanel.render(rows: rows, tiltDegrees: 3)
        #expect(decode(tilted).extractedText == "31.25")
        let steep = SegmentPanel.render(rows: rows, tiltDegrees: 6)
        #expect(decode(steep, maximum: 6).extractedText == "31.25")
        #expect(decode(tilted, maximum: 6).extractedText == "31.25")
    }

    @Test func quarterTurnStillReadsTheDigits() {
        // The scenario 1 crop stores the LCD on its side. A few degrees of
        // deskew cannot stand that up.
        let image = SegmentPanel.render(
            rows: [atoms("32.88"), atoms("8.022")],
            tiltDegrees: 90
        )
        let result = decode(image)
        #expect(result.extractedText == "32.88\n8.022")
        #expect(segmentTexts(result) == ["32.88", "8.022"])
    }

    @Test func decoderSourceDoesNotNameFields() throws {
        let source = try decoderSource()
        for word in ["This Sale", "Gallons", "FuelPurchase", "sale"] {
            #expect(!source.localizedCaseInsensitiveContains(word))
        }
        #expect(!source.localizedCaseInsensitiveContains("imlib"))
    }

    // MARK: - Label binding

    @Test func overlapDropsOnlyALargeIntersection() {
        let segment = fragment("2.899", x: 0.2, y: 0.4, w: 0.2, h: 0.2, role: .segment)
        let heavy = fragment("87", x: 0.22, y: 0.42, w: 0.16, h: 0.16, role: .label)
        let light = fragment("87", x: 0.37, y: 0.4, w: 0.1, h: 0.2, role: .label)
        let dropped = OCRSegmentLabelBinding.merge(segments: [segment], labels: [heavy])
        #expect(dropped.map(\.text) == ["2.899"])
        let kept = OCRSegmentLabelBinding.merge(segments: [segment], labels: [light])
        #expect(kept.contains { $0.text == "87" && $0.role == .label })
        #expect(kept.contains { $0.role == .segment && $0.confidence == 1 })
    }

    @Test func fiveLeftLabelsBindIncludingTheRightmost() {
        let prices = ["1.11", "2.22", "3.33", "4.44", "5.55"]
        let names = ["A", "B", "C", "D", "E"]
        var fragments: [OCRRecognizedText] = []
        for index in 0..<5 {
            let x = CGFloat(index) * 0.18
            fragments.append(fragment(names[index], x: x, y: 0.4, w: 0.05, h: 0.12, role: .label))
            fragments.append(fragment(prices[index], x: x + 0.06, y: 0.4, w: 0.08, h: 0.12, role: .segment))
        }
        let fields = OCRSegmentLabelBinding.assign(fragments: fragments, patterns: Dictionary(uniqueKeysWithValues: names.enumerated().map { ("p\($0.offset)", $0.element) }))
        #expect(fields["p0"] == "1.11")
        #expect(fields["p4"] == "5.55")
        #expect(fields.values.sorted() == prices.sorted())
    }

    @Test func mirrorRunBindsLabelsOnTheRight() {
        var fragments: [OCRRecognizedText] = []
        for index in 0..<3 {
            let x = CGFloat(index) * 0.2
            fragments.append(fragment("\(index)", x: x, y: 0.5, w: 0.06, h: 0.1, role: .segment))
            fragments.append(fragment("L\(index)", x: x + 0.07, y: 0.5, w: 0.05, h: 0.1, role: .label))
        }
        let fields = OCRSegmentLabelBinding.assign(
            fragments: fragments,
            patterns: ["a": "L0", "b": "L1", "c": "L2"]
        )
        #expect(fields["a"] == "0")
        #expect(fields["c"] == "2")
    }

    @Test func verticalRunUsesAboveAndBelow() {
        let fragments = [
            fragment("Above", x: 0.2, y: 0.78, w: 0.16, h: 0.08, role: .label),
            fragment("10", x: 0.2, y: 0.60, w: 0.12, h: 0.1, role: .segment),
            fragment("Below", x: 0.2, y: 0.44, w: 0.16, h: 0.08, role: .label),
            fragment("20", x: 0.2, y: 0.26, w: 0.12, h: 0.1, role: .segment)
        ]
        let fields = OCRSegmentLabelBinding.assign(fragments: fragments, patterns: ["top": "Above", "bottom": "Below"])
        #expect(fields["top"] == "10")
        #expect(fields["bottom"] == "20")
    }

    @Test func parallelRowsPairByOrder() {
        let prices = ["1", "2", "3", "4", "5"]
        var fragments: [OCRRecognizedText] = []
        for index in 0..<5 {
            let x = CGFloat(index) * 0.15
            fragments.append(fragment("N\(index)", x: x, y: 0.7, w: 0.08, h: 0.08, role: .label))
            fragments.append(fragment(prices[index], x: x, y: 0.4, w: 0.08, h: 0.12, role: .segment))
        }
        let fields = OCRSegmentLabelBinding.assign(
            fragments: fragments,
            patterns: Dictionary(uniqueKeysWithValues: (0..<5).map { ("n\($0)", "N\($0)") })
        )
        #expect(fields["n0"] == "1")
        #expect(fields["n4"] == "5")
    }

    @Test func distantLabelAndStripHeadingDoNotFillAPrice() {
        let near = [
            fragment("1.00", x: 0.1, y: 0.4, w: 0.08, h: 0.1, role: .segment),
            fragment("2.00", x: 0.2, y: 0.4, w: 0.08, h: 0.1, role: .segment),
            fragment("Far", x: 0.7, y: 0.4, w: 0.1, h: 0.1, role: .label)
        ]
        #expect(OCRSegmentLabelBinding.assign(fragments: near, patterns: ["price": "Far"]).isEmpty)

        var strip: [OCRRecognizedText] = [
            fragment("Prices", x: 0.05, y: 0.7, w: 0.7, h: 0.08, role: .label)
        ]
        for index in 0..<5 {
            strip.append(fragment("9.\(index)", x: 0.05 + CGFloat(index) * 0.12, y: 0.4, w: 0.08, h: 0.12, role: .segment))
        }
        #expect(OCRSegmentLabelBinding.assign(fragments: strip, patterns: ["grade": "Prices"]).isEmpty)

        var withNeighbors = strip
        for index in 0..<5 {
            let x = 0.05 + CGFloat(index) * 0.12
            withNeighbors.append(fragment("G\(index)", x: x - 0.0, y: 0.55, w: 0.06, h: 0.06, role: .label))
        }
        let bound = OCRSegmentLabelBinding.assign(
            fragments: withNeighbors,
            patterns: ["grade": "Prices", "g0": "G0", "g4": "G4"]
        )
        #expect(bound["grade"] == nil)
        #expect(bound["g0"] == "9.0")
        #expect(bound["g4"] == "9.4")
    }

    @Test func unmatchedWordDoesNotFillAField() {
        let fragments = [
            fragment("Hello", x: 0.1, y: 0.6, w: 0.1, h: 0.08, role: .label),
            fragment("15", x: 0.1, y: 0.4, w: 0.08, h: 0.1, role: .segment)
        ]
        #expect(OCRSegmentLabelBinding.assign(fragments: fragments, patterns: ["sale": "This Sale"]).isEmpty)
    }

    // MARK: - Service

    #if os(iOS) || os(macOS)
    @Test func processImageDecodesWithoutVision() async throws {
        let service = OCRService()
        let before = service.visionTextRecognitionRequestCount
        let image = PlatformImage(cgImage: panel(["31.25"]))
        let strategy = OCRStrategy(supportedTextTypes: [], supportedLanguages: [.english], processingMode: .ssocr)
        let result = try await service.processImage(image, context: OCRContext(processingMode: .ssocr), strategy: strategy)
        #expect(service.visionTextRecognitionRequestCount == before)
        #expect(result.extractedText == "31.25")
        #expect(result.recognizedTexts.allSatisfy { $0.role == .segment })
    }

    @Test func structuredExtractionBindsSuppliedLabelsAndSkipsVision() async throws {
        let image = panel(["32.88", "8.022"])
        let preview = decode(image)
        let segments = preview.recognizedTexts.filter { $0.role == .segment }
        #expect(segments.count == 2)
        let sale = segments[0]
        let volume = segments[1]
        let labels = [
            OCRRecognizedText(
                text: "This Sale",
                boundingBox: CGRect(
                    x: sale.boundingBox.minX - sale.boundingBox.width * 0.25,
                    y: sale.boundingBox.maxY + 0.008,
                    width: sale.boundingBox.width * 1.6,
                    height: 0.03
                ),
                confidence: 0.2,
                role: .label
            ),
            OCRRecognizedText(
                text: "Gallons",
                boundingBox: CGRect(
                    x: volume.boundingBox.minX,
                    y: volume.boundingBox.minY - 0.04,
                    width: volume.boundingBox.width,
                    height: 0.025
                ),
                confidence: 0.15,
                role: .label
            )
        ]
        let service = OCRService()
        let before = service.visionTextRecognitionRequestCount
        let context = OCRContext(
            extractionHints: ["sale": "This Sale", "volume": "Gallons"],
            extractionMode: .custom,
            processingMode: .ssocr,
            suppliedLabelFragments: labels
        )
        let result = try await service.processStructuredExtraction(PlatformImage(cgImage: image), context: context)
        #expect(service.visionTextRecognitionRequestCount == before)
        #expect(result.extractedText == "32.88\n8.022")
        #expect(!result.extractedText.contains("This Sale"))
        #expect(!result.extractedText.contains("Gallons"))
        #expect(result.structuredData["sale"] == "32.88")
        #expect(result.structuredData["volume"] == "8.022")
        #expect(result.confidence == 1)
        #expect(result.extractionConfidence == 1)
        let saleFragment = result.recognizedTexts.first { $0.text == "32.88" }
        #expect(saleFragment?.confidence == 1)
        #expect(result.recognizedTexts.contains { $0.text == "This Sale" && $0.role == .label })
    }

    @Test func structuredExtractionStillAsksVisionWhenLabelsAreNotSupplied() async throws {
        let service = OCRService()
        let before = service.visionTextRecognitionRequestCount
        let context = OCRContext(extractionMode: .custom, processingMode: .ssocr)
        let result = try await service.processStructuredExtraction(
            PlatformImage(cgImage: panel(["31.25"])),
            context: context
        )
        #expect(service.visionTextRecognitionRequestCount > before)
        #expect(result.extractedText == "31.25")
        #expect(result.confidence == 1)
    }

    @Test func lowSegmentScoreStaysInTheTextAndOutOfExtractionConfidence() async throws {
        let image = panel(["8_2 17.740"])
        let preview = decode(image)
        let clean = try #require(preview.recognizedTexts.first { $0.text == "17.740" })
        let label = OCRRecognizedText(
            text: "Total",
            boundingBox: CGRect(x: clean.boundingBox.minX, y: clean.boundingBox.maxY + 0.01, width: clean.boundingBox.width, height: 0.03),
            confidence: 0.1,
            role: .label
        )
        let context = OCRContext(
            extractionHints: ["amount": "Total"],
            extractionMode: .custom,
            processingMode: .ssocr,
            suppliedLabelFragments: [label]
        )
        let result = try await service().processStructuredExtraction(PlatformImage(cgImage: image), context: context)
        #expect(result.confidence == 0)
        #expect(result.extractedText.contains("8_2"))
        #expect(result.extractedText.contains("17.740"))
        #expect(result.structuredData["amount"] == "17.740")
        #expect(result.extractionConfidence == 1)
        #expect(result.recognizedTexts.contains { $0.text == "Total" && $0.role == .label && $0.confidence == 0.1 })
    }
    #endif

    // MARK: - Helpers

    private func service() -> OCRService { OCRService() }

    private func decode(_ image: CGImage, maximum: Double = 3) -> OCRResult {
        SevenSegmentOCR.decode(cgImage: image, deskewMaximumDegrees: maximum)
    }

    private func panel(_ rows: [String]) -> CGImage {
        SegmentPanel.render(rows: rows.map(atoms))
    }

    private func atoms(_ text: String) -> [SegmentPanel.Atom] {
        text.map { character in
            switch character {
            case "0"..."9":
                return .digit(digit(Int(String(character)) ?? 0))
            case ".":
                return .period
            case ",":
                return .comma
            case "-":
                return .hyphen
            case ":":
                return .colon
            case "_":
                return .topBar
            case " ":
                return .gap(SegmentPanel.groupGap)
            default:
                return .gap(0)
            }
        }
    }

    private func digit(_ value: Int) -> SevenSegmentPattern {
        switch value {
        case 0: return [.a, .b, .c, .d, .e, .f]
        case 1: return [.b, .c]
        case 2: return [.a, .b, .d, .e, .g]
        case 3: return [.a, .b, .c, .d, .g]
        case 4: return [.b, .c, .f, .g]
        case 5: return [.a, .c, .d, .f, .g]
        case 6: return [.a, .c, .d, .e, .f, .g]
        case 7: return [.a, .b, .c]
        case 8: return [.a, .b, .c, .d, .e, .f, .g]
        default: return [.a, .b, .c, .d, .f, .g]
        }
    }

    private func segmentTexts(_ result: OCRResult) -> [String] {
        result.recognizedTexts.filter { $0.role == .segment }.map(\.text)
    }

    private func segmentBoxes(_ result: OCRResult) -> [CGRect] {
        result.recognizedTexts.filter { $0.role == .segment }.map(\.boundingBox)
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

    private func decoderSource() throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Framework/Sources/Core/Services/SevenSegmentOCR.swift")
        return try String(contentsOf: url, encoding: .utf8)
    }
}

private enum SegmentPanel {
    static let cellW = 50
    static let cellH = 90
    static let stroke = 12
    static let intra = 8
    static let groupGap = 48
    static let rowGap = 64

    enum Atom {
        case digit(SevenSegmentPattern)
        case period
        case comma
        case colon
        case hyphen
        case topBar
        case fill(width: Int, height: Int)
        case gap(Int)
        case oppositePeriod
        case oppositeComma
    }

    static func contentSize(rows: [[Atom]]) -> (width: Int, height: Int) {
        let laid = layout(rows: rows, padding: 0)
        return (laid.width, laid.height)
    }

    static func render(
        rows: [[Atom]],
        padding: Int = 16,
        invert: Bool = false,
        glare: Bool = false,
        tiltDegrees: Double = 0,
        inkLevel: UInt8? = nil,
        backgroundLevel: UInt8? = nil,
        bezelLevel: UInt8? = nil,
        bezelWidth: Int = 0,
        outerMargin: Int = 0,
        scale: Int = 1
    ) -> CGImage {
        let laid = layout(rows: rows, padding: padding)
        let background: UInt8 = backgroundLevel ?? (invert ? 28 : 214)
        let ink: UInt8 = inkLevel ?? (invert ? 228 : 22)
        let markInk: UInt8 = 255
        var pixels = [UInt8](repeating: background, count: laid.width * laid.height)
        if bezelWidth > 0, let bezelLevel {
            let band = min(bezelWidth, min(laid.width, laid.height) / 2)
            fill(&pixels, width: laid.width, height: laid.height, rect: CGRect(x: 0, y: 0, width: laid.width, height: band), value: bezelLevel)
            fill(&pixels, width: laid.width, height: laid.height, rect: CGRect(x: 0, y: laid.height - band, width: laid.width, height: band), value: bezelLevel)
            fill(&pixels, width: laid.width, height: laid.height, rect: CGRect(x: 0, y: 0, width: band, height: laid.height), value: bezelLevel)
            fill(&pixels, width: laid.width, height: laid.height, rect: CGRect(x: laid.width - band, y: 0, width: band, height: laid.height), value: bezelLevel)
        }
        for stroke in laid.strokes where !stroke.opposite {
            fill(&pixels, width: laid.width, height: laid.height, rect: stroke.rect, value: ink)
        }
        for stroke in laid.strokes where stroke.opposite {
            fill(&pixels, width: laid.width, height: laid.height, rect: stroke.rect, value: markInk)
        }
        if glare, let band = laid.rowBands.first {
            let y0 = max(0, band.midY - stroke)
            let y1 = min(laid.height, band.midY + stroke)
            for y in y0..<y1 {
                for x in 0..<laid.width {
                    let index = y * laid.width + x
                    pixels[index] = pixels[index] < 80 ? 176 : 250
                }
            }
        }
        var width = laid.width
        var height = laid.height
        if abs(tiltDegrees) > 0.01 {
            let turned = rotate(pixels: pixels, width: width, height: height, degrees: tiltDegrees, fill: background)
            pixels = turned.pixels
            width = turned.width
            height = turned.height
        }
        if scale > 1 {
            let grown = scalePixels(pixels, width: width, height: height, factor: scale)
            pixels = grown.pixels
            width = grown.width
            height = grown.height
        }
        if outerMargin > 0 {
            let paddedW = width + outerMargin * 2
            let paddedH = height + outerMargin * 2
            var padded = [UInt8](repeating: background, count: paddedW * paddedH)
            for y in 0..<height {
                for x in 0..<width {
                    padded[(y + outerMargin) * paddedW + (x + outerMargin)] = pixels[y * width + x]
                }
            }
            pixels = padded
            width = paddedW
            height = paddedH
        }
        return image(pixels: pixels, width: width, height: height)
    }

    private static func scalePixels(_ pixels: [UInt8], width: Int, height: Int, factor: Int) -> (pixels: [UInt8], width: Int, height: Int) {
        let newW = width * factor
        let newH = height * factor
        var output = [UInt8](repeating: 0, count: newW * newH)
        for y in 0..<newH {
            for x in 0..<newW {
                output[y * newW + x] = pixels[(y / factor) * width + (x / factor)]
            }
        }
        return (output, newW, newH)
    }

    private struct Stroke {
        var rect: CGRect
        var opposite: Bool
    }

    private struct RowBand {
        var minY: Int
        var maxY: Int
        var midY: Int { (minY + maxY) / 2 }
    }

    private struct Layout {
        var width: Int
        var height: Int
        var strokes: [Stroke]
        var rowBands: [RowBand]
    }

    private static func layout(rows: [[Atom]], padding: Int) -> Layout {
        var strokes: [Stroke] = []
        var bands: [RowBand] = []
        var y = padding
        var maxX = padding
        for row in rows {
            var x = padding
            let rowTop = y
            for atom in row {
                switch atom {
                case .gap(let extra):
                    x += extra
                case .digit(let pattern):
                    strokes.append(contentsOf: digitStrokes(pattern, x: x, y: y, opposite: false))
                    x += cellW + intra
                case .period:
                    strokes.append(Stroke(rect: periodRect(x: x, y: y), opposite: false))
                    x += stroke + intra
                case .comma:
                    strokes.append(contentsOf: commaStrokes(x: x, y: y, opposite: false))
                    x += stroke + intra
                case .colon:
                    strokes.append(contentsOf: colonStrokes(x: x, y: y))
                    x += stroke + intra
                case .hyphen:
                    strokes.append(Stroke(rect: CGRect(x: x, y: y + cellH / 2 - stroke / 2, width: cellW, height: stroke), opposite: false))
                    x += cellW + intra
                case .topBar:
                    strokes.append(Stroke(rect: CGRect(x: x, y: y, width: cellW, height: stroke), opposite: false))
                    x += cellW + intra
                case .fill(let width, let height):
                    strokes.append(Stroke(rect: CGRect(x: x, y: y + max(0, (cellH - height) / 2), width: width, height: height), opposite: false))
                    x += width + intra
                case .oppositePeriod:
                    strokes.append(Stroke(rect: periodRect(x: x, y: y), opposite: true))
                    x += stroke + intra
                case .oppositeComma:
                    strokes.append(contentsOf: commaStrokes(x: x, y: y, opposite: true))
                    x += stroke + intra
                }
            }
            maxX = max(maxX, x)
            bands.append(RowBand(minY: rowTop, maxY: rowTop + cellH))
            y += cellH + rowGap
        }
        let height = max(padding, y - rowGap + padding)
        let width = max(padding, maxX - intra + padding)
        return Layout(width: max(width, 1), height: max(height, 1), strokes: strokes, rowBands: bands)
    }

    private static func isNarrowOne(_ pattern: SevenSegmentPattern) -> Bool {
        pattern == [.b, .c]
    }

    private static func periodRect(x: Int, y: Int) -> CGRect {
        CGRect(x: x, y: y + cellH - stroke, width: stroke, height: stroke)
    }

    private static func commaStrokes(x: Int, y: Int, opposite: Bool) -> [Stroke] {
        [
            Stroke(rect: periodRect(x: x, y: y), opposite: opposite),
            Stroke(rect: CGRect(x: x + stroke / 3, y: y + cellH, width: stroke / 2, height: stroke + 4), opposite: opposite)
        ]
    }

    private static func colonStrokes(x: Int, y: Int) -> [Stroke] {
        [
            Stroke(rect: CGRect(x: x, y: y + cellH / 5, width: stroke, height: stroke), opposite: false),
            Stroke(rect: CGRect(x: x, y: y + cellH * 3 / 5, width: stroke, height: stroke), opposite: false)
        ]
    }

    private static func digitStrokes(_ pattern: SevenSegmentPattern, x: Int, y: Int, opposite: Bool) -> [Stroke] {
        let mid = y + cellH / 2 - stroke / 2
        var rects: [CGRect] = []
        if pattern.contains(.a) { rects.append(CGRect(x: x + stroke, y: y, width: cellW - 2 * stroke, height: stroke)) }
        if pattern.contains(.b) { rects.append(CGRect(x: x + cellW - stroke, y: y + stroke, width: stroke, height: cellH / 2 - stroke)) }
        if pattern.contains(.c) { rects.append(CGRect(x: x + cellW - stroke, y: y + cellH / 2, width: stroke, height: cellH / 2 - stroke)) }
        if pattern.contains(.d) { rects.append(CGRect(x: x + stroke, y: y + cellH - stroke, width: cellW - 2 * stroke, height: stroke)) }
        if pattern.contains(.e) { rects.append(CGRect(x: x, y: y + cellH / 2, width: stroke, height: cellH / 2 - stroke)) }
        if pattern.contains(.f) { rects.append(CGRect(x: x, y: y + stroke, width: stroke, height: cellH / 2 - stroke)) }
        if pattern.contains(.g) { rects.append(CGRect(x: x + stroke, y: mid, width: cellW - 2 * stroke, height: stroke)) }
        // A one is a full cell. The stem is the right edge, not a narrower glyph.
        if isNarrowOne(pattern) {
            rects = [CGRect(x: x + cellW - stroke, y: y, width: stroke, height: cellH)]
        }
        return rects.map { Stroke(rect: $0, opposite: opposite) }
    }

    private static func fill(_ pixels: inout [UInt8], width: Int, height: Int, rect: CGRect, value: UInt8) {
        let x0 = max(0, Int(rect.minX))
        let y0 = max(0, Int(rect.minY))
        let x1 = min(width, Int(rect.maxX.rounded(.up)))
        let y1 = min(height, Int(rect.maxY.rounded(.up)))
        guard x1 > x0, y1 > y0 else { return }
        for y in y0..<y1 {
            for x in x0..<x1 {
                pixels[y * width + x] = value
            }
        }
    }

    private static func image(pixels: [UInt8], width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let data = Data(pixels) as CFData
        guard let provider = CGDataProvider(data: data) else {
            fatalError("segment fixture could not wrap pixels")
        }
        guard let image = CGImage(
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
        ) else {
            fatalError("segment fixture could not build an image")
        }
        return image
    }

    private static func rotate(
        pixels: [UInt8],
        width: Int,
        height: Int,
        degrees: Double,
        fill: UInt8
    ) -> (pixels: [UInt8], width: Int, height: Int) {
        let radians = degrees * Double.pi / 180
        let cosine = cos(radians)
        let sine = sin(radians)
        let centerX = Double(width) / 2
        let centerY = Double(height) / 2
        let corners = [(0.0, 0.0), (Double(width), 0), (0, Double(height)), (Double(width), Double(height))]
        let turned = corners.map { point -> (Double, Double) in
            let dx = point.0 - centerX
            let dy = point.1 - centerY
            return (cosine * dx - sine * dy + centerX, sine * dx + cosine * dy + centerY)
        }
        let minX = turned.map(\.0).min() ?? 0
        let minY = turned.map(\.1).min() ?? 0
        let maxX = turned.map(\.0).max() ?? 0
        let maxY = turned.map(\.1).max() ?? 0
        let newW = max(1, Int(ceil(maxX - minX)))
        let newH = max(1, Int(ceil(maxY - minY)))
        let destCenterX = Double(newW) / 2
        let destCenterY = Double(newH) / 2
        var output = [UInt8](repeating: fill, count: newW * newH)
        for y in 0..<newH {
            for x in 0..<newW {
                let dx = Double(x) - destCenterX
                let dy = Double(y) - destCenterY
                let sourceX = Int((cosine * dx + sine * dy + centerX).rounded())
                let sourceY = Int((-sine * dx + cosine * dy + centerY).rounded())
                guard sourceX >= 0, sourceY >= 0, sourceX < width, sourceY < height else { continue }
                output[y * newW + x] = pixels[sourceY * width + sourceX]
            }
        }
        return (output, newW, newH)
    }
}
