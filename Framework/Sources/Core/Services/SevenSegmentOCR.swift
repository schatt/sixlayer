//
//  SevenSegmentOCR.swift
//  SixLayerFramework
//
//  Segment-panel decode (#576). Glyphs are 0–9, a baseline dot, a comma, a hyphen, and a colon.
//

import CoreGraphics
import Foundation

public struct SevenSegmentPattern: OptionSet, Sendable, Equatable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let a = SevenSegmentPattern(rawValue: 1 << 0)
    public static let b = SevenSegmentPattern(rawValue: 1 << 1)
    public static let c = SevenSegmentPattern(rawValue: 1 << 2)
    public static let d = SevenSegmentPattern(rawValue: 1 << 3)
    public static let e = SevenSegmentPattern(rawValue: 1 << 4)
    public static let f = SevenSegmentPattern(rawValue: 1 << 5)
    public static let g = SevenSegmentPattern(rawValue: 1 << 6)
}

public enum SevenSegmentGlyph {
    public static func character(for pattern: SevenSegmentPattern) -> Character? {
        interpreted(pattern)?.character
    }

    static func interpreted(_ pattern: SevenSegmentPattern) -> (character: Character, confidence: Float)? {
        return match(pattern)
    }

    private static let templates: [(Character, UInt8)] = [
        ("0", SevenSegmentPattern([.a, .b, .c, .d, .e, .f]).rawValue),
        ("1", SevenSegmentPattern([.b, .c]).rawValue),
        ("2", SevenSegmentPattern([.a, .b, .d, .e, .g]).rawValue),
        ("3", SevenSegmentPattern([.a, .b, .c, .d, .g]).rawValue),
        ("4", SevenSegmentPattern([.b, .c, .f, .g]).rawValue),
        ("5", SevenSegmentPattern([.a, .c, .d, .f, .g]).rawValue),
        ("6", SevenSegmentPattern([.a, .c, .d, .e, .f, .g]).rawValue),
        ("7", SevenSegmentPattern([.a, .b, .c]).rawValue),
        ("8", SevenSegmentPattern([.a, .b, .c, .d, .e, .f, .g]).rawValue),
        ("9", SevenSegmentPattern([.a, .b, .c, .d, .f, .g]).rawValue),
        ("-", SevenSegmentPattern.g.rawValue)
    ]

    /// Nil when the pattern is empty or two templates share the best distance.
    /// `preferMissing`: on a Hamming tie, prefer a template that only needs
    /// missing segments (pattern ⊆ template) over one that needs clearing lit
    /// bits — e.g. abcdeg ties 2/3/8 at distance 1; only 8 is missing-only.
    fileprivate static func nearest(
        _ pattern: SevenSegmentPattern,
        preferMissing: Bool = false
    ) -> (character: Character, distance: Int)? {
        if pattern.rawValue == 0 { return nil }
        var bestDistance = Int.max
        var atBest: [(character: Character, missingOnly: Bool)] = []
        for template in templates {
            let distance = (template.1 ^ pattern.rawValue).nonzeroBitCount
            let missingOnly = (pattern.rawValue & ~template.1) == 0
            if distance < bestDistance {
                bestDistance = distance
                atBest = [(template.0, missingOnly)]
            } else if distance == bestDistance {
                atBest.append((template.0, missingOnly))
            }
        }
        if atBest.isEmpty { return nil }
        if atBest.count == 1 { return (atBest[0].character, bestDistance) }
        if preferMissing {
            let missingOnly = atBest.filter(\.missingOnly)
            if missingOnly.count == 1 {
                return (missingOnly[0].character, bestDistance)
            }
        }
        return nil
    }

    fileprivate static func match(
        _ pattern: SevenSegmentPattern,
        preferMissing: Bool = false
    ) -> (character: Character, confidence: Float)? {
        if pattern.rawValue == 0 { return nil }
        guard let found = nearest(pattern, preferMissing: preferMissing) else { return ("_", 0) }
        if found.distance == 0 { return (found.character, 1) }
        return (found.character, Float(7 - found.distance) / 7)
    }
}

/// One way to propose the digit-panel rectangle (#600).
public enum SegmentFrameFinder: String, CaseIterable, Sendable {
    case wholeFrame
    case sealedPocket
    case inkStack
}

/// One way to turn a crop into rows. The count is whatever the finder reports.
public enum SegmentRowFinder: String, CaseIterable, Sendable {
    /// Every pale gap, so one row stays one and three rows stay three.
    case allGaps
    /// The single gap nearest the middle. A taller stack collapses to two bands.
    case deepestPair
}

/// One way to read the glyphs inside a row.
public enum SegmentDigitReader: String, CaseIterable, Sendable {
    /// One scanline per segment, as ssocr does.
    case scanline
    /// A few pixels either side of that scanline, for a broken or washed stroke.
    case bandSample

    var sampleBand: Int {
        switch self {
        case .scanline: return 0
        case .bandSample: return 3
        }
    }
}

public struct SegmentFrameCandidate: Equatable, Sendable {
    public var finder: SegmentFrameFinder
    public var rect: CGRect
}

/// One combination of frame, row, and digit finders, scored for the lab matrix.
public struct SegmentSearchHit: Equatable, Sendable {
    public var frame: SegmentFrameFinder
    public var rows: SegmentRowFinder
    public var digits: SegmentDigitReader
    public var text: String
    public var exactDigitCount: Int
    public var lineCount: Int
}

public enum SevenSegmentOCR {
    /// Size of the image the frame finder searches. Callers map the rect back
    /// with `fullWidth / smallWidth` and `fullHeight / smallHeight`.
    ///
    /// The cap is the long side. A 3:4 portrait frame and a 3:4 landscape
    /// frame both shrink until that side is `maxSide`; a square camera stays
    /// square; a frame already inside the cap is not enlarged.
    static func findBufferSize(width: Int, height: Int, maxSide: Int = 1600) -> (width: Int, height: Int) {
        guard width > 0, height > 0, maxSide > 0 else { return (width, height) }
        let longSide = max(width, height)
        guard longSide > maxSide else { return (width, height) }
        if width >= height {
            let smallHeight = max(1, Int((Double(height) * Double(maxSide) / Double(width)).rounded()))
            return (maxSide, smallHeight)
        }
        let smallWidth = max(1, Int((Double(width) * Double(maxSide) / Double(height)).rounded()))
        return (smallWidth, maxSide)
    }

    /// Long-edge cap for panel localization analysis (#650). Full-resolution
    /// library photos are fitted to this before `masks()` / `localRange`.
    public static let digitPanelAnalysisMaxSide = 1600

    /// Long edge of the buffer that `digitPanelBounds` last analyzed. Test probe (#650).
    ///
    /// Decodes can run at once (``decode(frames:keyFrame:deskewMaximumDegrees:localizeDigitPanel:)``),
    /// so the probe is locked; after concurrent decodes it holds one of their values.
    public static var lastDigitPanelAnalysisLongEdge: Int? {
        get { digitPanelLongEdgeProbe.value }
        set { digitPanelLongEdgeProbe.value = newValue }
    }

    /// Long edge of the buffer that `decode` last ran `masks` on. Test probe (#654).
    /// Locked like ``lastDigitPanelAnalysisLongEdge``.
    public static var lastDecodeAnalysisLongEdge: Int? {
        get { decodeLongEdgeProbe.value }
        set { decodeLongEdgeProbe.value = newValue }
    }

    private static let digitPanelLongEdgeProbe = LockedProbe()
    private static let decodeLongEdgeProbe = LockedProbe()

    /// Pixel rect of the digit panel (glass plus a bezel margin) in the source
    /// image's coordinates, or `nil` when no sealed panel is found.
    ///
    /// Frames larger than ``digitPanelAnalysisMaxSide`` are searched on a
    /// fitted buffer. The rect is scaled back by `source / analysis` on each axis.
    ///
    /// Absolute crop rectangles are **per photo**. Reusing one image's rect on
    /// another frame is not a valid test of decode quality (#596).
    public static func digitPanelRegion(in cgImage: CGImage) -> CGRect? {
        guard let gray = GrayBuffer.read(cgImage) else { return nil }
        return gray.digitPanelBounds()
    }

    /// Rectangles the frame step can hand to a row finder. The lab ranks these.
    /// Production decode still uses the sealed pocket only when asked.
    public static func frameCandidates(in cgImage: CGImage) -> [SegmentFrameCandidate] {
        let whole = SegmentFrameCandidate(
            finder: .wholeFrame,
            rect: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        )
        guard let gray = GrayBuffer.read(cgImage) else { return [whole] }
        return gray.frameCandidates(whole: whole)
    }

    /// Every frame × row × digit combination, best exact-digit count first.
    /// This is the measurement matrix, not the production read.
    public static func searchPaths(
        in cgImage: CGImage,
        deskewMaximumDegrees: Double = 3
    ) -> [SegmentSearchHit] {
        guard let gray = GrayBuffer.read(cgImage) else { return [] }
        let whole = SegmentFrameCandidate(
            finder: .wholeFrame,
            rect: CGRect(x: 0, y: 0, width: gray.width, height: gray.height)
        )
        var hits: [SegmentSearchHit] = []
        for frame in gray.frameCandidates(whole: whole) {
            let rect = frame.rect
            let cropped = gray.cropped(
                x0: Int(rect.minX.rounded(.down)),
                y0: Int(rect.minY.rounded(.down)),
                x1: Int(rect.maxX.rounded(.up)),
                y1: Int(rect.maxY.rounded(.up))
            )
            guard cropped.width > 8, cropped.height > 8 else { continue }
            let upright = GrayBuffer.deskew(cropped, maximumDegrees: deskewMaximumDegrees)
            for rows in SegmentRowFinder.allCases {
                for digits in SegmentDigitReader.allCases {
                    let pieces = GrayBuffer.fragments(
                        in: upright,
                        rowFinder: rows,
                        sampleBand: digits.sampleBand
                    )
                    let lines = pieces.map { row in row.map(\.text).joined(separator: "  ") }
                    let exactDigitCount = pieces.flatMap { $0 }.reduce(0) { total, piece in
                        guard piece.confidence == 1 else { return total }
                        return total + piece.text.filter(\.isNumber).count
                    }
                    hits.append(
                        SegmentSearchHit(
                            frame: frame.finder,
                            rows: rows,
                            digits: digits,
                            text: lines.joined(separator: "\n"),
                            exactDigitCount: exactDigitCount,
                            lineCount: pieces.count
                        )
                    )
                }
            }
        }
        return hits.sorted { $0.exactDigitCount > $1.exactDigitCount }
    }

    /// Decode seven-segment glyphs.
    ///
    /// When `localizeDigitPanel` is true, a sealed digit panel is located and
    /// cropped before decode so a resized full pump frame can feed `.ssocr`
    /// without a hand-tuned ROI (#596). Tight crops keep working: a missing or
    /// near-full-frame region falls back to the whole image.
    ///
    /// `panelLocator`, when set, is the trained panel model (#609). A nil
    /// result from it still uses the classical finder.
    ///
    /// After localization, analysis is fitted to ``digitPanelAnalysisMaxSide``
    /// so full-resolution panel crops from the training harness do not stall
    /// in `localRange` (#654). Normalized glyph boxes stay valid (same aspect).
    public static func decode(
        cgImage: CGImage,
        deskewMaximumDegrees: Double = 3,
        localizeDigitPanel: Bool = false,
        panelLocator: DisplayOCRPanelLocator? = nil
    ) -> OCRResult {
        guard var gray = GrayBuffer.read(cgImage) else {
            return OCRResult(extractedText: "", confidence: 0)
        }
        let frame = gray
        if localizeDigitPanel {
            let modelRegion = panelLocator?.panelRegion(in: cgImage)
            if let modelRegion, let cropped = gray.panelCrop(modelRegion) {
                gray = cropped
            } else if let region = gray.digitPanelBounds(), let cropped = gray.panelCrop(region) {
                gray = cropped
            }
        }
        // Huge pale pad around a small panel (training / paddedCanvas) must
        // not survive into masks — fit alone leaves tiny glyphs (#648).
        gray = gray.trimmingUniformMargin()
        gray = gray.fitted(maxSide: digitPanelAnalysisMaxSide)
        lastDecodeAnalysisLongEdge = max(gray.width, gray.height)
        let upright = GrayBuffer.deskew(gray, maximumDegrees: deskewMaximumDegrees)
        let fragments = GrayBuffer.fragments(in: upright)
        let legacy = result(fragments)
        // Photographed panels: italic digits, segment gaps, reflections and
        // uneven light defeat the fixed-pixel path above. The lattice reader
        // measures everything from the panel itself (#576 real photos).
        var rows = SevenSegmentLatticeReader.readRefined(pixels: gray.pixels, width: gray.width, height: gray.height)
        var lattice = result(rows.map { [latticeFragment($0, width: gray.width, height: gray.height)] })
        let cropLattice = lattice.extractedText
        // The panel finder above can pick the wrong region of a real photo
        // (a payment screen, an ad). When the crop does not read cleanly,
        // search the whole frame for the region that reads best. Those
        // boxes are normalized to the whole image.
        // A confident read of one short row ("88") can be a fragment of the
        // panel; search too when it holds fewer than four digits.
        let cropDigits = rows.flatMap { $0 }.filter { $0.character.isNumber }.count
        if localizeDigitPanel, !SevenSegmentLatticeReader.isConfident(rows) || cropDigits < 4 {
            let located = SevenSegmentLatticeReader.locateAndRead(
                pixels: frame.pixels, width: frame.width, height: frame.height
            )
            if SevenSegmentLatticeReader.rank(located) > SevenSegmentLatticeReader.rank(rows) {
                rows = located
                lattice = result(located.map { [latticeFragment($0, width: frame.width, height: frame.height)] })
            }
        }
        // Legacy carries group spacing, commas, colons and unknown-cell
        // placeholders, so it stays when it is believable. Its photo output
        // is mostly "1", "_" and stray marks, sometimes at confidence 1.0, so
        // a confident lattice read needs a richer legacy read to lose.
        if SevenSegmentLatticeReader.isConfident(rows) {
            if isPlausible(fragments) {
                // On a tie legacy keeps its spacing, marks and 1s, but only
                // when both agree on every digit other than 1 (the ones
                // quality counts). When they disagree, the lattice read,
                // exact in every row, wins: legacy can read a dark panel's
                // unlit segments as a row of exact 8s.
                func information(_ text: String) -> String { text.filter { $0.isNumber && $0 != "1" } }
                let sameDigits = information(legacy.extractedText) == information(lattice.extractedText)
                if quality(legacy) > quality(lattice) { return legacy }
                return quality(legacy) == quality(lattice) && sameDigits ? legacy : lattice
            }
            let latticeText = String(rows.flatMap { $0 }.map(\.character))
            return legacyOutweighsLattice(fragments, latticeText: latticeText) ? legacy : lattice
        }
        if isPlausible(fragments) {
            return legacy
        }
        if !rows.isEmpty, quality(lattice) >= quality(legacy) {
            return lattice
        }
        return legacy
    }

    /// Whether an implausible legacy read still beats a confident lattice read.
    ///
    /// Only high-confidence plausible fragments count, and they must hold at
    /// least half the legacy characters. Digits are compared without 1s:
    /// legacy photo output is often runs of 1s at high confidence. When
    /// neither side has a digit other than 1 ("11.11"), every digit counts,
    /// so a couple of stray 1s cannot replace a full read of 1s.
    static func legacyOutweighsLattice(_ fragments: [[OCRRecognizedText]], latticeText: String) -> Bool {
        let trusted = fragments.flatMap { $0 }.filter { fragment in
            fragment.confidence >= 6.0 / 7.0 && isPlausible([[fragment]])
        }
        let trustedText = trusted.map(\.text).joined()
        let allChars = fragments.flatMap { $0 }.reduce(0) { $0 + $1.text.count }
        guard trustedText.count * 2 >= allChars else { return false }
        func digits(_ text: String, countingOnes: Bool) -> Int {
            text.filter { $0.isNumber && (countingOnes || $0 != "1") }.count
        }
        let trustedDigits = digits(trustedText, countingOnes: false)
        let latticeDigits = digits(latticeText, countingOnes: false)
        if trustedDigits == 0, latticeDigits == 0 {
            return digits(trustedText, countingOnes: true) >= digits(latticeText, countingOnes: true)
        }
        return trustedDigits >= latticeDigits
    }

    private static func quality(_ result: OCRResult) -> Int {
        let text = result.extractedText
        let glyphs = text.filter { $0.isNumber && $0 != "1" }.count
        return glyphs - text.filter { $0 == "_" }.count
    }

    private static func result(_ fragments: [[OCRRecognizedText]]) -> OCRResult {
        let lines = fragments.map { row in row.map(\.text).joined(separator: "  ") }
        let extracted = lines.joined(separator: "\n") + (glareHeadNote.isEmpty ? "" : "\n" + glareHeadNote)
        let flat = fragments.flatMap { $0 }
        let confidence = flat.map(\.confidence).min() ?? 0
        return OCRResult(
            extractedText: extracted,
            confidence: confidence,
            boundingBoxes: flat.map(\.boundingBox),
            textTypes: extracted.isEmpty ? [:] : [.number: extracted],
            recognizedTexts: flat
        )
    }

    /// Every group holds a digit, has no unknown cell, and does not start or
    /// end on a mark. Garbage such as ".  ...  .8" can score 1.0 otherwise.
    private static func isPlausible(_ fragments: [[OCRRecognizedText]]) -> Bool {
        let flat = fragments.flatMap { $0 }
        guard !flat.isEmpty, flat.allSatisfy({ $0.confidence > 0 && !$0.text.contains("_") }) else { return false }
        return flat.allSatisfy { fragment in
            let text = fragment.text
            guard text.contains(where: \.isNumber), let first = text.first, let last = text.last else { return false }
            return first != "." && first != "," && last != "." && last != ","
        }
    }

    private static func latticeFragment(
        _ row: [SevenSegmentLatticeReader.Cell],
        width: Int,
        height: Int
    ) -> OCRRecognizedText {
        let minX = row.map(\.minX).min() ?? 0
        let maxX = row.map(\.maxX).max() ?? 0
        let minY = row.map(\.minY).min() ?? 0
        let maxY = row.map(\.maxY).max() ?? 0
        let w = Double(max(1, width))
        let h = Double(max(1, height))
        return OCRRecognizedText(
            text: String(row.map(\.character)),
            boundingBox: CGRect(
                x: minX / w,
                y: 1 - maxY / h,
                width: max(1, maxX - minX) / w,
                height: max(1, maxY - minY) / h
            ),
            confidence: row.map(\.confidence).min() ?? 0,
            role: .segment
        )
    }
}

private struct GrayBuffer {
    var pixels: [UInt8]
    var width: Int
    var height: Int

    static func read(_ image: CGImage) -> GrayBuffer? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return nil }
        let count = width * height
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        pointer.initialize(repeating: 0, count: count)
        defer { pointer.deallocate() }
        guard let context = CGContext(
            data: pointer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return GrayBuffer(pixels: Array(UnsafeBufferPointer(start: pointer, count: count)), width: width, height: height)
    }

    static func deskew(_ buffer: GrayBuffer, maximumDegrees: Double) -> GrayBuffer {
        // Padded single-line crops pull bezel and extra glass (#651). Trim
        // solid edge chrome, peel side glass tight (side pad invents stems),
        // and snap to the densest ink band with 4px vertical glass — enough
        // for #641 border clearing, less than the 6px span that left
        // isotropic / both-vertical pad reading "_".
        let prepared = buffer
            .trimmingEdgeBezel()
            .tightenedToDigitLine(marginX: 0, marginY: 4)
        let turned = standingUp(prepared)
        let limit = Int(max(0, maximumDegrees).rounded(.down))
        guard limit > 0 else { return turned }
        let small = turned.fitted(maxSide: 280)
        let uprightScore = score(small)
        let upright = readQuality(small)
        var bestAngle = 0
        var bestScore = uprightScore
        for angle in -limit...limit where angle != 0 {
            let turnedSample = small.rotated(degrees: Double(angle))
            let value = score(turnedSample)
            // A tilt that lights an extra segment is a worse read, even when
            // the row sums vary more. Turning never changes which polarity is
            // ink, so a tilt that reads the other one is reading the glass
            // lit beside the strokes (#609: a turned 7 read as two slivers, 11).
            guard value > bestScore else { continue }
            let tilted = readQuality(turnedSample)
            if tilted.confidence >= upright.confidence, upright.isDark == nil || tilted.isDark == upright.isDark {
                bestScore = value
                bestAngle = angle
            }
        }
        if bestAngle == 0 || uprightScore * 100 >= bestScore * 98 {
            return turned
        }
        let tilted = turned.rotated(degrees: Double(bestAngle))
        // The loose mask can prefer a tilt that smears the digit rows back
        // together. Keep the upright crop when that tilt closes the core.
        if coreStaysOpen(turned), !coreStaysOpen(tilted) {
            return turned
        }
        return tilted
    }

    /// Lowest cell confidence, and the polarity read as ink (nil when no
    /// cell was read). A tilt that only adds row-sum noise scores higher and
    /// still reads worse; deskew keeps the surer angle.
    private static func readQuality(_ buffer: GrayBuffer) -> (confidence: Float, isDark: Bool?) {
        var isDark: Bool?
        let cells = readRows(in: buffer, allowBandPitch: false, polarityRead: { isDark = $0 }).flatMap { $0 }
        guard !cells.isEmpty else { return (0, nil) }
        return (cells.map(\.confidence).min() ?? 0, isDark)
    }

    /// True when one polarity's core splits a full-height loose mask into
    /// shorter rows. Deskew uses this so a tilt cannot smear those rows shut.
    private static func coreStaysOpen(_ buffer: GrayBuffer) -> Bool {
        let raw = buffer.masks()
        let sealed = (dark: keepingInteriorInk(raw.dark), light: keepingInteriorInk(raw.light))
        let masks = (dark: clearingBorderComponents(sealed.dark), light: clearingBorderComponents(sealed.light))
        let sealedCore = (dark: keepingInteriorInk(raw.darkCore), light: keepingInteriorInk(raw.lightCore))
        let cores = (dark: clearingBorderComponents(sealedCore.dark), light: clearingBorderComponents(sealedCore.light))
        let dark = polarity(isDark: true, loose: masks.dark, core: cores.dark)
        let light = polarity(isDark: false, loose: masks.light, core: cores.light)
        return dark.opens || light.opens
    }

    /// A pump photo can store the LCD on its side. A few degrees of deskew
    /// never reaches that. A field of narrow slices reads as ones, so the
    /// turn with wide digits wins, then the one whose decimals sit below.
    private static func standingUp(_ buffer: GrayBuffer) -> GrayBuffer {
        let small = buffer.fitted(maxSide: 480)
        let scores = (0...3).map { turns -> OrientationScore in
            let sample = turns == 0 ? small : small.rotated(degrees: Double(turns * 90))
            return orientationScore(in: sample)
        }
        let bestTurns = scores.enumerated().max { left, right in
            if left.element.wideDigits != right.element.wideDigits {
                return left.element.wideDigits < right.element.wideDigits
            }
            if left.element.marksBelow != right.element.marksBelow {
                return left.element.marksBelow < right.element.marksBelow
            }
            if left.element.rowVariance != right.element.rowVariance {
                return left.element.rowVariance < right.element.rowVariance
            }
            return left.element.confidence < right.element.confidence
        }?.offset ?? 0
        guard bestTurns != 0 else { return buffer }
        guard acceptsOrientation(bestTurns, scores: scores, buffer: buffer) else { return buffer }
        return buffer.rotated(degrees: Double(bestTurns * 90))
    }

    /// A small tilt still belongs to the fine deskew. Speck rows on a
    /// sideways sample read as a few wide glyphs and must not spin an
    /// upright panel. A real quarter turn is mostly digits. A half turn of
    /// 0/2/8 still looks numeric — only take 180° when decimals sit below
    /// after the turn. A short wide strip is already one upright line
    /// (#625); padded top-line crops that keep a little glass still look
    /// short-wide and must not half-turn into `"_"` (#651).
    /// A 480px sample of an upright panel can drop two wide digits.
    /// That lead is not a turn. A field of ones still turns on a lead of two.
    private static func acceptsOrientation(
        _ turns: Int,
        scores: [OrientationScore],
        buffer: GrayBuffer
    ) -> Bool {
        // Line crops (Vision box ± pad) are already upright. Blocking only
        // 90° left 180° free to invent `"_"` / spoilers on isotropic pad.
        if buffer.width * 4 > buffer.height * 5 {
            return false
        }
        let glyphs = scores[turns].text.filter { $0 != "/" }
        let numbers = glyphs.filter(\.isNumber).count
        let mostlyNumbers = !glyphs.isEmpty && numbers * 2 > glyphs.count
        if turns == 2 {
            return mostlyNumbers && scores[2].marksBelow > scores[0].marksBelow
        }
        let uprightWide = scores[0].wideDigits
        let turnedWide = scores[turns].wideDigits
        let minimumLead = uprightWide >= 4 ? 4 : 2
        return mostlyNumbers && turnedWide >= 4 && turnedWide >= uprightWide + minimumLead
    }

    private struct OrientationScore {
        var wideDigits: Int
        var marksBelow: Int
        var rowVariance: Int
        var confidence: Float
        var text: String
    }

    /// A real digit is wider than the narrow slice the decoder calls "1".
    /// A decimal sits under that digit, so an upside-down read puts it above.
    private static func orientationScore(in buffer: GrayBuffer) -> OrientationScore {
        // Must not use bandPitch: a failed rowcrop on the 480px sample would
        // pitch-split noise and flip standingUp away from the true upright.
        let rows = readRows(in: buffer, allowBandPitch: false)
        let placed = rows.flatMap { row -> [(cell: Cell, markBelow: Bool)] in
            let tall = row.filter { $0.character.isNumber && $0.height > 0 }
            let digitMid = median(tall.map { ($0.minY + $0.maxY) / 2 })
            return row.map { cell in
                let markBelow: Bool
                if let digitMid, cell.character == "." || cell.character == "," {
                    markBelow = (cell.minY + cell.maxY) / 2 > digitMid
                } else {
                    markBelow = false
                }
                return (cell, markBelow)
            }
        }
        let wideDigits = placed.filter { item in
            let cell = item.cell
            return cell.character.isNumber && cell.height > 0 && cell.box.width * 100 > cell.height * 30
        }.count
        return OrientationScore(
            wideDigits: wideDigits,
            marksBelow: placed.filter(\.markBelow).count,
            rowVariance: score(buffer),
            confidence: placed.reduce(Float(0)) { $0 + $1.cell.confidence },
            text: rows.map { String($0.map(\.character)) }.joined(separator: "/")
        )
    }

    private static func cells(
        in band: (Int, Int),
        mask: Mask,
        buffer: GrayBuffer,
        bandIndex: Int,
        darkInk: Bool,
        preferredPitch: PreferredDigitPitch? = nil,
        sampleBand: Int = 0
    ) -> [Cell] {
        let columns = columnRuns(
            mask,
            y0: band.0,
            y1: band.1,
            width: buffer.width,
            preferredPitch: preferredPitch
        )
        let rawBoxes = columns.map { span -> PixelBox in
            tightBox(mask, x0: span.0, x1: span.1, y0: band.0, y1: band.1, width: buffer.width)
        }.filter { $0.width > 0 && $0.height > 0 }
        let tallest = rawBoxes.map(\.height).max() ?? 1
        let minimum = max(1, tallest / 20)
        let boxes = rawBoxes.filter { $0.width >= minimum && $0.height >= minimum }
        guard !boxes.isEmpty else { return [] }
        let maxHeight = boxes.map(\.height).max() ?? 1
        let tall = boxes.filter { $0.height * 100 >= maxHeight * 55 }
        let digitHeight = median(tall.map(\.height)) ?? maxHeight
        let baseline = median(tall.map(\.maxY)) ?? band.1
        let frameTop = median(tall.map(\.minY)) ?? band.0
        // A fused wash blob inflates the median width. Prefer a pitch copied
        // from a known-good row, else the 7-seg aspect (≈ height/2).
        let measured = median(tall.map(\.width)) ?? digitHeight
        let aspectWidth = max(1, digitHeight / 2)
        let digitWidth = preferredPitch?.body
            ?? (measured > aspectWidth + aspectWidth / 4 ? aspectWidth : measured)
        let capped = boxes.map { box -> PixelBox in
            // Cap only blobs clearly wider than one digit; a normal glyph can
            // sit a few pixels over height/2 without being fused.
            guard box.width > digitWidth + digitWidth / 4 else { return box }
            let mid = box.midX
            let half = digitWidth / 2
            return PixelBox(
                minX: mid - half,
                minY: box.minY,
                maxX: mid + (digitWidth - half),
                maxY: box.maxY
            )
        }
        // Pitch-driven volume rows have solid wash bridges. Left-half stem
        // scans light false `f` on that fringe (pat 123 → 2/8 tie). Gate the
        // tighter stem sample on preferredPitch so clean price rows stay put.
        let washAwareStems = preferredPitch != nil
        let markBaseline = Self.baseline(of: tall, mask: mask, width: buffer.width, digitWidth: digitWidth)
            ?? (baseline, false)
        let classified = capped.compactMap { box -> Cell? in
            let cell = classify(
                box,
                mask: mask,
                width: buffer.width,
                digitHeight: digitHeight,
                digitWidth: digitWidth,
                baseline: baseline,
                markBaseline: markBaseline,
                frameTop: frameTop,
                bandIndex: bandIndex,
                buffer: buffer,
                darkInk: darkInk,
                washAwareStems: washAwareStems,
                sampleBand: sampleBand
            )
            // Volume rowcrops are ~980px; keep traces on those for #591.
            if buffer.width >= 900 {
                let pattern = sample(
                    mask,
                    box: densestInkBand(
                        mask,
                        box: box,
                        width: buffer.width,
                        digitWidth: digitWidth,
                        forceDigitTall: washAwareStems
                    ),
                    width: buffer.width,
                    washAwareStems: washAwareStems,
                    sampleBand: sampleBand
                )
                let cover = coverage(mask, box: box, width: buffer.width)
                let name = cell.map { String($0.character) } ?? "drop"
                let pitchNote = preferredPitch.map { " pitch \($0.body)x\($0.count)" } ?? ""
                let bits = [
                    pattern.contains(.a) ? "a" : "",
                    pattern.contains(.b) ? "b" : "",
                    pattern.contains(.c) ? "c" : "",
                    pattern.contains(.d) ? "d" : "",
                    pattern.contains(.e) ? "e" : "",
                    pattern.contains(.f) ? "f" : "",
                    pattern.contains(.g) ? "g" : ""
                ].joined()
                trace(
                    "cell \(name) box \(box.minX),\(box.minY) \(box.width)x\(box.height) pat \(pattern.rawValue) [\(bits)] cov \(cover) h \(digitHeight)\(pitchNote)\n"
                )
            }
            return cell
        }
        // A real one is a single stem, always under a third of the copied
        // body width. Dropping those deleted the leading 1 of 15.556 and
        // 1.840 (both real pump volumes). Junk is rejected in classify.
        return classified
    }

    /// A washed decimal shares its columns with the digit beside it, so the
    /// column walk never gives it a box. It is a short run on the baseline
    /// sitting in the gap between two digit bars, with empty glass above it.
    private static func baselineDots(
        in band: (Int, Int),
        mask: Mask,
        cells: [Cell],
        width: Int,
        bandIndex: Int
    ) -> [Cell] {
        let digits = cells.filter { $0.character.isNumber && $0.height > 0 }
        guard digits.count >= 2 else { return [] }
        let digitWidth = median(digits.map(\.box.width)) ?? 0
        let digitHeight = median(digits.map(\.height)) ?? 0
        guard digitWidth > 8, digitHeight > 8 else { return [] }
        let baseline = median(digits.map(\.maxY)) ?? band.1
        let top = max(band.0, baseline - max(4, digitHeight / 8))
        let bottom = min(mask.height, max(baseline, band.1))
        guard bottom > top else { return [] }
        let sums = columnSums(mask, y0: top, y1: bottom, width: width)
        let floor = max(2, (bottom - top) / 4)
        var spans: [(Int, Int)] = []
        var start: Int?
        for x in 0...width {
            let on = x < width && sums[x] >= floor
            if on {
                if start == nil { start = x }
            } else if let open = start {
                spans.append((open, x))
                start = nil
            }
        }
        let wide = digitWidth / 2
        let narrow = digitWidth / 4
        let gapTop = max(band.0, top - max(4, digitHeight / 10))
        let above = columnSums(mask, y0: gapTop, y1: top, width: width)
        let bodies = spans.filter { $0.1 - $0.0 > 4 }
        var dots: [Cell] = []
        for (index, span) in bodies.enumerated() {
            let spanWidth = span.1 - span.0
            guard spanWidth < narrow else { continue }
            guard let left = bodies[..<index].last, let right = bodies.dropFirst(index + 1).first else { continue }
            let leftWidth = left.1 - left.0
            let rightWidth = right.1 - right.0
            guard leftWidth >= wide, rightWidth >= wide else { continue }
            guard span.0 - left.1 < digitWidth, right.0 - span.1 < digitWidth else { continue }
            let aboveInk = (span.0..<span.1).reduce(0) { $0 + above[$1] }
            let room = max(1, (top - gapTop) * spanWidth)
            guard aboveInk * 5 < room else { continue }
            let box = tightBox(mask, x0: span.0, x1: span.1, y0: top, y1: bottom, width: width)
            let alreadyMarked = cells.contains { cell in
                (cell.character == "." || cell.character == ",") && overlap(cell.box, box) > 0
            }
            if alreadyMarked { continue }
            dots.append(Cell(box: box, character: ".", confidence: 1, band: bandIndex))
        }
        return dots
    }

    private static func oppositeMarks(
        in band: (Int, Int),
        secondary: Mask,
        existing: [Cell],
        buffer: GrayBuffer,
        bandIndex: Int
    ) -> [Cell] {
        let digitHeight = median(existing.map(\.height)) ?? max(1, band.1 - band.0)
        let barredDigits = existing.filter { "0235689".contains($0.character) }
        let barredBaseline = !barredDigits.isEmpty
        let baseline = median((barredBaseline ? barredDigits : existing).map(\.maxY)) ?? band.1
        let minimum = max(1, digitHeight / 20)
        let expanded = (max(0, band.0 - digitHeight / 2), min(buffer.height, band.1 + digitHeight / 2))
        let columns = columnRuns(secondary, y0: expanded.0, y1: expanded.1, width: buffer.width)
        return columns.compactMap { span -> Cell? in
            let box = tightBox(secondary, x0: span.0, x1: span.1, y0: expanded.0, y1: expanded.1, width: buffer.width)
            guard box.width >= minimum, box.height >= minimum else { return nil }
            guard box.width < digitHeight * 30 / 100, box.height < digitHeight * 55 / 100 else { return nil }
            if existing.contains(where: { overlap($0.box, box) > 0 }) { return nil }
            return Cell(
                box: box,
                character: markCharacter(box: box, baseline: baseline, barredBaseline: barredBaseline),
                confidence: 1,
                band: bandIndex
            )
        }
    }

    /// Period = a dot sitting on the baseline; comma = a mark that reaches
    /// below it. The mark's own width (about one stroke) is the yardstick, so
    /// the rule scales with the photo: reaching below the baseline by more
    /// than a quarter of that width is more than edge blur.
    ///
    /// `barredBaseline` says the baseline came from digits with a bottom bar.
    /// Without one (a row of 1s, 4s and 7s), the stems end above the true
    /// baseline and a period looks low (#647 / #658), so the mark must also
    /// be taller than wide: a period is square, a comma is not.
    private static func markCharacter(box: PixelBox, baseline: Int, barredBaseline: Bool) -> Character {
        let reachesBelow = (box.maxY - baseline) * 4 > box.width
        guard reachesBelow else { return "." }
        return barredBaseline || box.height > box.width ? "," : "."
    }

    /// Median bottom of the boxes whose lowest ink row is a bar, and whether
    /// any were found. In 1, 4 and 7 the lowest ink is a stem, narrower than
    /// half a digit; their bottoms sit above the bar of 0, 2, 3, 5, 6, 8, 9.
    private static func baseline(
        of boxes: [PixelBox],
        mask: Mask,
        width: Int,
        digitWidth: Int
    ) -> (Int, Bool)? {
        let barred = boxes.filter { box in
            let y = box.maxY - 1
            guard y >= 0, y < mask.height, box.maxX > box.minX else { return false }
            var longest = 0
            var run = 0
            for x in max(0, box.minX)..<min(width, box.maxX) {
                run = mask.bits[y * width + x] ? run + 1 : 0
                longest = max(longest, run)
            }
            return longest * 2 >= digitWidth
        }
        if let bottom = median(barred.map(\.maxY)) { return (bottom, true) }
        return median(boxes.map(\.maxY)).map { ($0, false) }
    }

    private static func classify(
        _ box: PixelBox,
        mask: Mask,
        width: Int,
        digitHeight: Int,
        digitWidth: Int,
        baseline: Int,
        markBaseline: (Int, Bool),
        frameTop: Int,
        bandIndex: Int,
        buffer: GrayBuffer,
        darkInk: Bool,
        washAwareStems: Bool = false,
        sampleBand: Int = 0
    ) -> Cell? {
        let vertical = verticalRuns(mask, box: box, width: width)
        let splitGap = vertical.count == 2 ? vertical[1].0 - vertical[0].1 : 0
        let shorterRun = vertical.count == 2
            ? min(vertical[0].1 - vertical[0].0, vertical[1].1 - vertical[1].0)
            : 0
        let colonGap = vertical.count == 2 && splitGap >= shorterRun
        // Mid-row glare brightens the glass strip; the rows just above/below
        // then look like ink in empty inter-digit columns (#645). That yields
        // two speck-tall runs with a colon-sized gap. Real colon dots are a
        // meaningful share of the digit height — drop the speck pair instead
        // of falling through to '.' .
        let stackedNarrowDots = colonGap
            && box.width * 100 <= box.height * 30
            && vertical.allSatisfy { $0.1 - $0.0 < digitHeight * 45 / 100 }
        if stackedNarrowDots {
            let minDot = max(3, digitHeight * 8 / 100)
            guard shorterRun >= minDot else { return nil }
            return Cell(box: box, character: ":", confidence: 1, band: bandIndex)
        }
        // Glare lifts the glass on both sides of its band. Those short bands
        // share the decimal's columns, so the three reads as one unknown.
        // A colon's dots are the same height and stay one mark.
        if vertical.count >= 2, let kept = vertical.last {
            let keptHeight = kept.1 - kept.0
            let fringe = vertical.dropLast().allSatisfy { run in
                let height = run.1 - run.0
                return height * 2 < keptHeight && height * 5 < digitHeight && kept.0 - run.1 > height
            }
            if fringe {
                let lower = PixelBox(minX: box.minX, minY: kept.0, maxX: box.maxX, maxY: kept.1)
                return classify(
                    lower,
                    mask: mask,
                    width: width,
                    digitHeight: digitHeight,
                    digitWidth: digitWidth,
                    baseline: baseline,
                    markBaseline: markBaseline,
                    frameTop: frameTop,
                    bandIndex: bandIndex,
                    buffer: buffer,
                    darkInk: darkInk,
                    washAwareStems: washAwareStems,
                    sampleBand: sampleBand
                )
            }
        }
        // ssocr: a box narrower than a quarter of its height is a one.
        if box.height * 100 >= digitHeight * 55, box.width * 4 < box.height {
            return Cell(box: box, character: "1", confidence: 1, band: bandIndex)
        }
        if box.height * 100 >= digitHeight * 50,
           box.width * 100 >= digitHeight * 40,
           (coverage(mask, box: box, width: width) > solidCoverage || inkFraction(buffer, box: box, darkInk: darkInk) > solidCoverage) {
            return nil
        }
        if box.height * 100 < digitHeight * 45, box.width * 100 < digitHeight * 30 {
            // A thin comma tail can miss the mask while the raw pixels are
            // still darker than the glass around the mark.
            guard markIsInk(mask, box: box, width: width, buffer: buffer, darkInk: darkInk) else { return nil }
            return Cell(
                box: box,
                character: markCharacter(box: box, baseline: markBaseline.0, barredBaseline: markBaseline.1),
                confidence: 1,
                band: bandIndex
            )
        }
        // Do not clamp this frame to the mask. Washed bezels inflate
        // digitHeight so frameTop + digitHeight can sit past the buffer;
        // shortening the frame misreads good crops (#596 after #597).
        // Bad-ROI safety is the empty-scan guards in foregroundCount (#597).
        let frame = PixelBox(
            minX: box.midX - max(digitWidth, box.width) / 2,
            minY: frameTop,
            maxX: box.midX + max(digitWidth, box.width) / 2,
            maxY: frameTop + max(digitHeight, 1)
        )
        if box.height * 100 < digitHeight * 70, coverage(mask, box: frame, width: width) > solidCoverage {
            return nil
        }
        // A reflection beside the digits is wider than a glyph. Compare to the
        // band's digit height — not the ink-tight box height. Digits that omit
        // top/bottom bars (especially 4) shrink vertically and otherwise trip
        // this as a "wide" reflection (#647).
        if box.height * 100 >= digitHeight * 50, box.width * 5 > digitHeight * 4 {
            return nil
        }
        let sampledBox = box.height * 100 < digitHeight * 70 ? frame : box
        // Glare above the top bar stretches the box. Upper stem scans then sit
        // in that fringe and light a/f. A digit-tall ink band keeps the scan
        // on the glyph the way a tight price-row crop already does.
        let trimmed = densestInkBand(
            mask,
            box: sampledBox,
            width: width,
            digitWidth: digitWidth,
            forceDigitTall: washAwareStems
        )
        let trimmedPattern = sample(
            mask,
            box: trimmed,
            width: width,
            washAwareStems: washAwareStems,
            sampleBand: sampleBand
        )
        // Pitch volume: Y-trim can clip `c` and mint an exact 2 while the
        // untrimmed box is abcdeg (one f from 8). Prefer a near-8 that still
        // has `c` over that false exact 2.
        let pattern: SevenSegmentPattern
        if washAwareStems {
            let fullPattern = sample(
                mask,
                box: sampledBox,
                width: width,
                washAwareStems: washAwareStems,
                sampleBand: sampleBand
            )
            pattern = preferWashAwarePattern(trimmedPattern, fullPattern)
        } else {
            pattern = trimmedPattern
        }
        guard let glyph = SevenSegmentGlyph.match(pattern, preferMissing: washAwareStems) else {
            return nil
        }
        return Cell(box: box, character: glyph.character, confidence: glyph.confidence, band: bandIndex)
    }

    /// Prefer a near-8 that still has the right stem over an exact 2 from a
    /// Y-trim that clipped `c`. Otherwise keep the denser-band pattern.
    private static func preferWashAwarePattern(
        _ trimmed: SevenSegmentPattern,
        _ full: SevenSegmentPattern
    ) -> SevenSegmentPattern {
        func nearEightWithC(_ pattern: SevenSegmentPattern) -> Bool {
            guard pattern.contains(.c) else { return false }
            guard let found = SevenSegmentGlyph.nearest(pattern, preferMissing: true) else {
                return false
            }
            return found.character == "8" && found.distance <= 1
        }
        func exactTwoWithoutC(_ pattern: SevenSegmentPattern) -> Bool {
            !pattern.contains(.c)
                && SevenSegmentGlyph.nearest(pattern)?.distance == 0
                && SevenSegmentGlyph.nearest(pattern)?.character == "2"
        }
        if nearEightWithC(full), exactTwoWithoutC(trimmed) { return full }
        if nearEightWithC(trimmed) { return trimmed }
        if nearEightWithC(full) { return full }
        return trimmed
    }

    /// Six scanlines, as ssocr does. The center column is split into thirds
    /// for the top, middle, and bottom bars. Lines a quarter down from the
    /// top and a quarter up from the bottom are split into halves for the
    /// stems. A segment lights on a consecutive run of at least two pixels
    /// (#599). One pixel on an empty stem stays dark. A fraction of the scan
    /// (an eighth) fit synthetic strokes of 12px in a ~30px third, and rejected
    /// this crop: the 3's bars are runs of 7–11 in a third of ~111, and the
    /// 2's lower-left stem is a run of 2 in a half of 91. Those became `1`
    /// and a 2/3 tie.
    ///
    /// `washAwareStems`: skip the outer left fringe on f/e scans so a solid
    /// wash bridge beside the glyph cannot mint a false upper/lower-left stem.
    /// Does not invent ink on the right (c/b).
    private static func sample(
        _ mask: Mask,
        box: PixelBox,
        width: Int,
        washAwareStems: Bool = false,
        sampleBand: Int = 0
    ) -> SevenSegmentPattern {
        let boxWidth = box.width
        let boxHeight = box.height
        guard boxWidth > 1, boxHeight > 2, width > 0 else { return [] }
        func ink(_ x: Int, _ y: Int, _ length: Int, _ vertical: Bool) -> Int {
            foregroundCount(
                mask,
                x: x,
                y: y,
                length: length,
                vertical: vertical,
                sampleBand: sampleBand
            )
        }
        var pattern = SevenSegmentPattern()
        let midX = box.minX + boxWidth / 2
        let third = max(1, boxHeight / 3)
        if segmentIsLit(mask, x: midX, y: box.minY, length: third, vertical: true, sampleBand: sampleBand) {
            pattern.formUnion(.a)
        }
        if segmentIsLit(mask, x: midX, y: box.minY + third, length: third, vertical: true, sampleBand: sampleBand) {
            pattern.formUnion(.g)
        }
        let lower = box.minY + third * 2
        if segmentIsLit(mask, x: midX, y: lower, length: max(1, box.maxY - lower), vertical: true, sampleBand: sampleBand) {
            pattern.formUnion(.d)
        }
        let quarter = box.minY + boxHeight / 4
        let threeQuarters = box.minY + (boxHeight * 3) / 4
        let half = boxWidth / 2
        let right = max(1, box.maxX - (midX + 1))
        // Right stems first so wash-aware `f` can see whether `c` is present
        // (8-candidates keep f; 2-like glyphs drop wash f).
        if segmentIsLit(mask, x: midX + 1, y: quarter, length: right, vertical: false, sampleBand: sampleBand) {
            pattern.formUnion(.b)
        }
        if segmentIsLit(mask, x: midX + 1, y: threeQuarters, length: right, vertical: false, sampleBand: sampleBand) {
            pattern.formUnion(.c)
        }
        let eFringe = washAwareStems ? max(1, boxWidth / 6) : 0
        let eLength = max(1, half - eFringe)
        let eRun = longestForegroundRun(
            mask, x: box.minX + eFringe, y: threeQuarters, length: eLength, vertical: false, sampleBand: sampleBand
        )
        // The fringe starts inside a real stem. The tail past it can be a
        // single pixel; requiring two turned a washed 8 into a 9. The fringe
        // already skipped the bridge (#599).
        let eLit = washAwareStems ? eRun >= 1 : eRun >= 2
        if eLit {
            pattern.formUnion(.e)
        }
        // Wash bridges light false `f` on 2-like glyphs (pat 123 → 2/8 tie).
        // When `c` is already lit the glyph may be 8/0/9/… — scan f like price
        // (no fringe) so a real left stem at the box edge still lights. When
        // `c` is dark, require stem-zone ink, reject fringe-dominated wash,
        // and drop f if the remainder is an exact digit.
        if !washAwareStems || pattern.contains(.c) {
            if segmentIsLit(mask, x: box.minX, y: quarter, length: half, vertical: false, sampleBand: sampleBand) {
                pattern.formUnion(.f)
            }
        } else {
            let fFringe = max(1, boxWidth / 5)
            let fEdge = ink(box.minX, quarter, fFringe, false)
            let fStem = ink(box.minX + fFringe, quarter, max(1, half - fFringe), false)
            let washDominated = fEdge >= fStem && fEdge * 2 >= fFringe
            let fLength = max(1, half - fFringe)
            let fRun = longestForegroundRun(
                mask, x: box.minX + fFringe, y: quarter, length: fLength, vertical: false, sampleBand: sampleBand
            )
            if fRun >= 1, !washDominated {
                pattern.formUnion(.f)
            }
            if pattern.contains(.f) {
                var withoutF = pattern
                withoutF.remove(.f)
                if let exact = SevenSegmentGlyph.nearest(withoutF), exact.distance == 0 {
                    pattern = withoutF
                }
            }
        }
        return pattern
    }

    fileprivate static func group(_ cells: [Cell]) -> [[Cell]] {
        guard !cells.isEmpty else { return [] }
        let ordered = cells.sorted { $0.minX < $1.minX }
        guard ordered.count > 1 else { return [ordered] }
        // Narrow stems shrink a plain median and start late in their slot, so
        // a body→stem edge gap looks cell-wide (#646). Upper-half pitch plus
        // right-anchored padding keeps only true group holes above the bar.
        let pitch = bodyPitch(of: ordered)
        let slots = groupSlots(ordered, pitch: pitch)
        let gaps = zip(slots, slots.dropFirst()).map { max(0, $1.minX - $0.maxX) }
        let middle = median(gaps) ?? 0
        var groups: [[Cell]] = [[ordered[0]]]
        for (index, cell) in ordered.dropFirst().enumerated() {
            let gap = gaps[index]
            let wideAsACell = pitch > 0 && gap >= pitch
            if middle > 0, gap >= middle * 2, gap > middle, wideAsACell {
                groups.append([cell])
            } else {
                groups[groups.count - 1].append(cell)
            }
        }
        return groups
    }

    /// Median of the upper half of tall non-mark widths — resists skinny "1"s.
    private static func bodyPitch(of cells: [Cell]) -> Int {
        let tallest = cells.map(\.height).max() ?? 1
        let widths = cells.filter { cell in
            cell.height * 100 >= tallest * 55 && !isMark(cell.character)
        }.map(\.box.width).sorted()
        guard !widths.isEmpty else { return 0 }
        return median(Array(widths[(widths.count / 2)...])) ?? 0
    }

    /// Pad thin digits out to `pitch`, anchored on maxX (stems sit on the right).
    private static func groupSlots(_ cells: [Cell], pitch: Int) -> [(minX: Int, maxX: Int)] {
        cells.map { cell in
            if isMark(cell.character) || pitch <= 0 || cell.box.width >= pitch {
                return (cell.minX, cell.maxX)
            }
            return (cell.maxX - pitch, cell.maxX)
        }
    }

    private static func isMark(_ character: Character) -> Bool {
        character == "." || character == "," || character == ":" || character == "-"
    }

    private static func score(_ buffer: GrayBuffer) -> Int {
        let masks = buffer.masks()
        let chosen = prefersDark(masks.dark, masks.light) ? masks.dark : masks.light
        return score(chosen)
    }

    private static func score(_ mask: Mask) -> Int {
        let rows = mask.rowSums
        guard !rows.isEmpty else { return 0 }
        let total = rows.reduce(Int64(0)) { $0 + Int64($1) }
        let mean = total / Int64(rows.count)
        return rows.reduce(0) { partial, row in
            let delta = Int64(row) - mean
            let next = partial + Int(delta * delta)
            return next
        }
    }

    private func masks() -> (dark: Mask, light: Mask, darkCore: Mask, lightCore: Mask) {
        // ssocr dynamic_threshold: halfway from the local minimum to the
        // local maximum. The window has to see a washed stroke and still
        // miss the next digit. On the price row the gap is about 40 pixels,
        // and a 35-pixel window meets across it. A short crop (the glare
        // fixture is 122 on its short side) stays at the tight window.
        let shortSide = min(width, height)
        let radius = windowRadius(width: width, height: height)
        let range = localRange(radius: radius)
        var dark = [Bool](repeating: false, count: pixels.count)
        var light = [Bool](repeating: false, count: pixels.count)
        for index in pixels.indices {
            let pixel = Int(pixels[index])
            let low = range.low[index]
            let high = range.high[index]
            // Glare glass varies, but only by a small share of its level.
            // A stroke is at least a quarter of the brighter level darker
            // than that level. The halfway cut alone marks the glare.
            guard high - low > inkMargin, (high - low) * 4 > high else { continue }
            let mid = low + (high - low) / 2
            dark[index] = pixel < mid && pixel + inkMargin <= high
            light[index] = pixel > mid && pixel >= low + inkMargin
        }
        // The middle of a wide pale bar matches itself, so the halfway cut
        // never marks it. The edges of that bar are already ink. Fill the
        // middle only in those columns, and only when the pixel is darker
        // than a wide average. An open hole is not darker than that average.
        let meanRadius = min(64, max(24, shortSide / 8))
        let mean = boxMean(radius: meanRadius)
        fillPaleBar(into: &dark, mean: mean, darker: true)
        fillPaleBar(into: &light, mean: mean, darker: false)
        let darkMask = Mask(bits: dark, width: width, height: height)
        let lightMask = Mask(bits: light, width: width, height: height)
        return (darkMask, lightMask, darkMask, lightMask)
    }

    /// Min and max inside a square window. A square window separates into a
    /// horizontal pass and a vertical pass.
    ///
    /// Uses C-style index loops — Swift `ClosedRange` iteration dominated the
    /// #650 photo-library hang sample (generic metadata / IndexingIterator).
    private func localRange(radius: Int) -> (low: [Int], high: [Int]) {
        var horizontalLow = [Int](repeating: 255, count: pixels.count)
        var horizontalHigh = [Int](repeating: 0, count: pixels.count)
        for y in 0..<height {
            let row = y * width
            for x in 0..<width {
                let x0 = max(0, x - radius)
                let x1 = min(width - 1, x + radius)
                var low = 255
                var high = 0
                var sample = x0
                while sample <= x1 {
                    let level = Int(pixels[row + sample])
                    if level < low { low = level }
                    if level > high { high = level }
                    sample += 1
                }
                horizontalLow[row + x] = low
                horizontalHigh[row + x] = high
            }
        }
        var low = [Int](repeating: 255, count: pixels.count)
        var high = [Int](repeating: 0, count: pixels.count)
        for x in 0..<width {
            for y in 0..<height {
                let y0 = max(0, y - radius)
                let y1 = min(height - 1, y + radius)
                var columnLow = 255
                var columnHigh = 0
                var sample = y0
                while sample <= y1 {
                    let index = sample * width + x
                    if horizontalLow[index] < columnLow { columnLow = horizontalLow[index] }
                    if horizontalHigh[index] > columnHigh { columnHigh = horizontalHigh[index] }
                    sample += 1
                }
                let index = y * width + x
                low[index] = columnLow
                high[index] = columnHigh
            }
        }
        return (low, high)
    }

    /// Mean of a square window, as a horizontal pass and then a vertical pass.
    private func boxMean(radius: Int) -> [Int] {
        var horizontal = [Int](repeating: 0, count: pixels.count)
        for y in 0..<height {
            var prefix = [Int](repeating: 0, count: width + 1)
            let row = y * width
            for x in 0..<width {
                prefix[x + 1] = prefix[x] + Int(pixels[row + x])
            }
            for x in 0..<width {
                let start = max(0, x - radius)
                let end = min(width - 1, x + radius)
                horizontal[row + x] = (prefix[end + 1] - prefix[start]) / (end - start + 1)
            }
        }
        var mean = [Int](repeating: 0, count: pixels.count)
        for x in 0..<width {
            var prefix = [Int](repeating: 0, count: height + 1)
            for y in 0..<height {
                prefix[y + 1] = prefix[y] + horizontal[y * width + x]
            }
            for y in 0..<height {
                let start = max(0, y - radius)
                let end = min(height - 1, y + radius)
                mean[y * width + x] = (prefix[end + 1] - prefix[start]) / (end - start + 1)
            }
        }
        return mean
    }

    /// Close a pale bar between stroke pixels on the same row. A hole between
    /// the stems is not darker than the wide average, so it stays open.
    private func fillPaleBar(into mask: inout [Bool], mean: [Int], darker: Bool) {
        for y in 0..<height {
            let row = y * width
            var inkOnLeft = [Bool](repeating: false, count: width)
            var seen = false
            for x in 0..<width {
                inkOnLeft[x] = seen
                if mask[row + x] { seen = true }
            }
            var inkOnRight = false
            for x in stride(from: width - 1, through: 0, by: -1) {
                let index = row + x
                let wasInk = mask[index]
                if inkOnLeft[x], inkOnRight, !wasInk {
                    let pixel = Int(pixels[index])
                    let average = mean[index]
                    let pale = darker
                        ? pixel + paleBarMargin < average
                        : pixel > average + paleBarMargin
                    if pale { mask[index] = true }
                }
                if wasInk { inkOnRight = true }
            }
        }
    }

    func fitted(maxSide: Int) -> GrayBuffer {
        let longest = max(width, height)
        guard longest > maxSide, longest > 0 else { return self }
        let ratio = Double(maxSide) / Double(longest)
        let newW = max(1, Int((Double(width) * ratio).rounded()))
        let newH = max(1, Int((Double(height) * ratio).rounded()))
        var output = [UInt8](repeating: 0, count: newW * newH)
        for y in 0..<newH {
            for x in 0..<newW {
                let sourceX = min(width - 1, Int(Double(x) / ratio))
                let sourceY = min(height - 1, Int(Double(y) / ratio))
                output[y * newW + x] = pixels[sourceY * width + sourceX]
            }
        }
        return GrayBuffer(pixels: output, width: newW, height: newH)
    }

    private func rotated(degrees: Double) -> GrayBuffer {
        if abs(degrees) < 0.01 { return self }
        let radians = degrees * Double.pi / 180
        let cosine = cos(radians)
        let sine = sin(radians)
        let centerX = Double(width) / 2
        let centerY = Double(height) / 2
        let corners = [(0.0, 0.0), (Double(width), 0), (0, Double(height)), (Double(width), Double(height))]
        let turned = corners.map { corner -> (Double, Double) in
            let dx = corner.0 - centerX
            let dy = corner.1 - centerY
            return (cosine * dx - sine * dy + centerX, sine * dx + cosine * dy + centerY)
        }
        let minX = turned.map(\.0).min() ?? 0
        let minY = turned.map(\.1).min() ?? 0
        let maxX = turned.map(\.0).max() ?? 0
        let maxY = turned.map(\.1).max() ?? 0
        let newW = max(1, Int(ceil(maxX - minX)))
        let newH = max(1, Int(ceil(maxY - minY)))
        let fill = cornerFill()
        var output = [UInt8](repeating: fill, count: newW * newH)
        let destCenterX = Double(newW) / 2
        let destCenterY = Double(newH) / 2
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
        return GrayBuffer(pixels: output, width: newW, height: newH)
    }

    fileprivate func cornerFill() -> UInt8 {
        let corners = [pixels[0], pixels[width - 1], pixels[(height - 1) * width], pixels[pixels.count - 1]]
        return corners.sorted()[corners.count / 2]
    }

    /// Peel uniform border that matches the corner fill (synthetic pad /
    /// letterbox). Keeps a small glass margin so bezels stay when present (#648).
    func trimmingUniformMargin() -> GrayBuffer {
        guard width > 16, height > 16 else { return self }
        let fill = Int(cornerFill())
        let slack = inkMargin
        func isMarginRow(_ y: Int) -> Bool {
            let start = y * width
            for x in 0..<width where abs(Int(pixels[start + x]) - fill) > slack {
                return false
            }
            return true
        }
        func isMarginColumn(_ x: Int) -> Bool {
            for y in 0..<height where abs(Int(pixels[y * width + x]) - fill) > slack {
                return false
            }
            return true
        }
        var top = 0
        while top < height - 8, isMarginRow(top) { top += 1 }
        var bottom = height
        while bottom > top + 8, isMarginRow(bottom - 1) { bottom -= 1 }
        var left = 0
        while left < width - 8, isMarginColumn(left) { left += 1 }
        var right = width
        while right > left + 8, isMarginColumn(right - 1) { right -= 1 }
        // Ignore hairline "pad" so glare / invert fixtures keep full glass (#645).
        let peeled = top + (height - bottom) + left + (width - right)
        guard peeled >= 64 else { return self }
        let margin = 4
        let x0 = max(0, left - margin)
        let y0 = max(0, top - margin)
        let x1 = min(width, right + margin)
        let y1 = min(height, bottom + margin)
        if x0 == 0, y0 == 0, x1 == width, y1 == height { return self }
        return cropped(x0: x0, y0: y0, x1: x1, y1: y1)
    }

    fileprivate func extremeMarkMask() -> Mask {
        Mask(
            bits: pixels.map { $0 <= 10 || $0 >= extremeHighlight },
            width: width,
            height: height
        )
    }
}

nonisolated(unsafe) private var glareHeadNote = ""

private func trace(_ message: String) {
    fputs(message, stderr)
}

private struct Mask {
    var bits: [Bool]
    var width: Int
    var height: Int

    var rowSums: [Int] {
        (0..<height).map { y in
            var sum = 0
            let start = y * width
            for x in 0..<width where bits[start + x] {
                sum += 1
            }
            return sum
        }
    }
}

private struct PixelBox {
    var minX: Int
    var minY: Int
    var maxX: Int
    var maxY: Int

    var width: Int { maxX - minX }
    var height: Int { maxY - minY }
    var midX: Int { (minX + maxX) / 2 }
}

private struct Cell {
    var box: PixelBox
    var character: Character
    var confidence: Float
    var band: Int

    var minX: Int { box.minX }
    var maxX: Int { box.maxX }
    var minY: Int { box.minY }
    var maxY: Int { box.maxY }
    var height: Int { box.height }

    func shifted(dx: Int, dy: Int) -> Cell {
        Cell(
            box: PixelBox(
                minX: box.minX + dx,
                minY: box.minY + dy,
                maxX: box.maxX + dx,
                maxY: box.maxY + dy
            ),
            character: character,
            confidence: confidence,
            band: band
        )
    }
}

private func recognizedGroups(_ cells: [Cell], width: Int, height: Int) -> [OCRRecognizedText] {
    let pieces = GrayBuffer.group(cells)
    return pieces.map { group in
        let text = String(group.map(\.character))
        let confidence = group.map(\.confidence).min() ?? 0
        let box = reCropGlassBox(
            minX: group.map(\.minX).min() ?? 0,
            maxX: group.map(\.maxX).max() ?? 0,
            minY: group.map(\.minY).min() ?? 0,
            maxY: group.map(\.maxY).max() ?? 0,
            width: width,
            height: height
        )
        return OCRRecognizedText(
            text: text,
            boundingBox: CGRect(
                x: CGFloat(box.minX) / CGFloat(width),
                y: 1 - CGFloat(box.maxY) / CGFloat(height),
                width: CGFloat(max(1, box.maxX - box.minX)) / CGFloat(width),
                height: CGFloat(max(1, box.maxY - box.minY)) / CGFloat(height)
            ),
            confidence: confidence,
            role: .segment
        )
    }
}

/// Ink-tight bounds leave no glass for a zero-margin re-crop on a lower
/// sealed line (#641). Grow with real panel glass when the group sits below
/// the top band — expanding the top line pulls chrome and breaks a read that
/// already works at pad=0.
private func reCropGlassBox(
    minX: Int,
    maxX: Int,
    minY: Int,
    maxY: Int,
    width: Int,
    height: Int,
    glass: Int = 6
) -> (minX: Int, maxX: Int, minY: Int, maxY: Int) {
    guard minY * 3 > height else {
        return (minX, maxX, minY, maxY)
    }
    return (
        max(0, minX - glass),
        min(width, maxX + glass),
        max(0, minY - glass),
        min(height, maxY + glass)
    )
}

private extension GrayBuffer {
    static func fragments(
        in buffer: GrayBuffer,
        rowFinder: SegmentRowFinder? = nil,
        sampleBand: Int = 0
    ) -> [[OCRRecognizedText]] {
        glareHeadNote = ""
        if let rowFinder {
            return finderFragments(in: buffer, rowFinder: rowFinder, sampleBand: sampleBand)
        }
        // A padded single LCD line (glass above/below, maybe beside) can
        // register extra bands and collapse the read (#651). Treat short wide
        // crops as one line: no row split, no band-pitch copy.
        let singleLine = buffer.height < 160 && buffer.width * 4 > buffer.height * 5
        let rows = readRows(
            in: buffer,
            splittingRows: !singleLine,
            allowBandPitch: !singleLine
        )
        let chosen: [[Cell]]
        if singleLine, rows.count > 1 {
            chosen = [rows.max(by: { left, right in
                digitWeight(left) < digitWeight(right)
            }) ?? []]
        } else {
            chosen = rows
        }
        return chosen.compactMap { row in
            let texts = recognizedGroups(row, width: buffer.width, height: buffer.height)
            return texts.isEmpty ? nil : texts
        }
    }

    /// One output line per finder band. A pair band may hold several digit
    /// rows; those cells stay on one line so the row finder decides the count.
    private static func finderFragments(
        in buffer: GrayBuffer,
        rowFinder: SegmentRowFinder,
        sampleBand: Int
    ) -> [[OCRRecognizedText]] {
        readRows(
            in: buffer,
            allowBandPitch: true,
            sampleBand: sampleBand,
            rowFinder: rowFinder
        ).compactMap { row in
            let texts = recognizedGroups(row, width: buffer.width, height: buffer.height)
            return texts.isEmpty ? nil : texts
        }
    }

    /// Rows for one finder. Polarity can follow the glass holes after a punch
    /// opens a counter, so both loose masks are read and the one with more
    /// exact digits wins. A tie stays on the dark strokes.
    private static func finderRows(
        in buffer: GrayBuffer,
        dark: Mask,
        light: Mask,
        rowFinder: SegmentRowFinder,
        sampleBand: Int,
        preferredPitch: PreferredDigitPitch?
    ) -> [[Cell]] {
        let paintedMarks = buffer.extremeMarkMask()
        func lineRows(ink: Mask, isDark: Bool) -> [[Cell]] {
            let projected = projectionBands(ink.rowSums, height: buffer.height)
            let lines = rowFinder == .deepestPair
                ? pairBands(projected, height: buffer.height)
                : projected
            let decoded = projected.map { band in
                cellsInFinderBand(
                    band,
                    ink: ink,
                    isDark: isDark,
                    buffer: buffer,
                    paintedMarks: paintedMarks,
                    sampleBand: sampleBand,
                    preferredPitch: preferredPitch
                )
            }
            return lines.compactMap { line in
                var combined: [Cell] = []
                for (band, row) in zip(projected, decoded) where band.0 >= line.0 && band.1 <= line.1 {
                    combined.append(contentsOf: row)
                }
                return combined.isEmpty ? nil : combined
            }
        }
        let darkRows = lineRows(ink: dark, isDark: true)
        let lightRows = lineRows(ink: light, isDark: false)
        if exactDigitCells(lightRows) > exactDigitCells(darkRows) {
            return lightRows
        }
        return darkRows
    }

    private static func cellsInFinderBand(
        _ band: (Int, Int),
        ink: Mask,
        isDark: Bool,
        buffer: GrayBuffer,
        paintedMarks: Mask,
        sampleBand: Int,
        preferredPitch: PreferredDigitPitch?
    ) -> [Cell] {
        let found = cells(
            in: band,
            mask: ink,
            buffer: buffer,
            bandIndex: 0,
            darkInk: isDark,
            preferredPitch: preferredPitch,
            sampleBand: sampleBand
        )
        let marks = oppositeMarks(
            in: band,
            secondary: paintedMarks,
            existing: found,
            buffer: buffer,
            bandIndex: 0
        )
        let dots = baselineDots(in: band, mask: ink, cells: found, width: buffer.width, bandIndex: 0)
        var row = found + marks + dots
        if preferredPitch != nil {
            row = pitchRowMarks(row, mask: ink, band: band, width: buffer.width)
        }
        return row
    }

    private static func exactDigitCells(_ rows: [[Cell]]) -> Int {
        rows.flatMap { $0 }.reduce(0) { total, cell in
            guard cell.confidence == 1, cell.character.isNumber else { return total }
            return total + 1
        }
    }

    /// Prefer the row with the most digit ink when a line crop spuriously
    /// splits (#651).
    private static func digitWeight(_ row: [Cell]) -> Int {
        row.reduce(0) { score, cell in
            guard cell.character.isNumber, cell.height > 0 else { return score }
            return score + cell.height * max(1, cell.box.width)
        }
    }

    /// Drop solid chrome that a padded line crop pulled in from the panel
    /// bezel (#651). Only short wide strips — a full panel keeps its bezel
    /// for sealed-glass localization. Side columns need a stricter dark
    /// fraction than rows: digit stems at a tight crop edge are dark but
    /// not solid chrome (a looser side trim previously read `32.86`).
    func trimmingEdgeBezel() -> GrayBuffer {
        guard height > 0, width > 0, height < 160, width * 4 > height * 5 else {
            return self
        }
        func isBezelRow(_ y: Int) -> Bool {
            var dark = 0
            for x in 0..<width where pixels[y * width + x] < 80 {
                dark += 1
            }
            return dark * 4 > width * 3
        }
        func isBezelColumn(_ x: Int) -> Bool {
            var dark = 0
            for y in 0..<height where pixels[y * width + x] < 80 {
                dark += 1
            }
            return dark * 10 >= height * 9
        }
        var top = 0
        while top < height - 8, isBezelRow(top) {
            top += 1
        }
        var bottom = height
        while bottom > top + 8, isBezelRow(bottom - 1) {
            bottom -= 1
        }
        var left = 0
        while left < width - 8, isBezelColumn(left) {
            left += 1
        }
        var right = width
        while right > left + 8, isBezelColumn(right - 1) {
            right -= 1
        }
        if top == 0, bottom == height, left == 0, right == width {
            return self
        }
        return cropped(x0: left, y0: top, x1: right, y1: bottom)
    }

    /// Peel empty side glass (tight — side pad invents stems) and crop to
    /// the densest vertical ink band with a glass margin (#651 / #641).
    /// Row-gap noise from both-vertical pad is too dark for a plain glass
    /// peel but too weak to win the densest-band pick.
    func tightenedToDigitLine(marginX: Int, marginY: Int) -> GrayBuffer {
        guard height > 0, width > 0, height < 160, width * 4 > height * 5 else {
            return self
        }
        // Relative to panel glass, not a fixed <80 cut (#664). Washed strokes
        // (~140–176 on lower-half / mid-row wash) must still count as ink while
        // glass near the median does not. Light-on-dark panels flip the test.
        let median = peelGlassMedian()
        let margin = max(inkMargin, 24)
        let inkIsDark = median > 127
        func isPeelInk(_ pixel: UInt8) -> Bool {
            let level = Int(pixel)
            if inkIsDark {
                return level + margin < median
            }
            return level > median + margin
        }
        func columnDark(_ x: Int) -> Int {
            var dark = 0
            for y in 0..<height where isPeelInk(pixels[y * width + x]) {
                dark += 1
            }
            return dark
        }
        func rowDark(_ y: Int) -> Int {
            var dark = 0
            for x in 0..<width where isPeelInk(pixels[y * width + x]) {
                dark += 1
            }
            return dark
        }
        let emptyColumn = max(1, height / 16)
        var glassLeft = 0
        while glassLeft < width - 8, columnDark(glassLeft) <= emptyColumn {
            glassLeft += 1
        }
        var glassRight = 0
        while glassRight < width - 8, columnDark(width - 1 - glassRight) <= emptyColumn {
            glassRight += 1
        }
        let x0 = max(0, glassLeft - marginX)
        let x1 = min(width, width - glassRight + marginX)
        let rowInk = (0..<height).map(rowDark)
        let peak = rowInk.max() ?? 0
        let floor = max(max(1, width / 20) * 2, peak / 10)
        var bestStart = 0
        var bestEnd = height
        var bestInk = -1
        var cursor = 0
        while cursor < height {
            while cursor < height, rowInk[cursor] < floor {
                cursor += 1
            }
            guard cursor < height else { break }
            let start = cursor
            var ink = 0
            while cursor < height, rowInk[cursor] >= floor {
                ink += rowInk[cursor]
                cursor += 1
            }
            if ink > bestInk {
                bestInk = ink
                bestStart = start
                bestEnd = cursor
            }
        }
        guard bestInk >= 0 else { return self }
        // Belt-and-suspenders with adaptive peel ink (#664): if a wash still
        // leaves only a short densest run, refuse to peel into that stub
        // (#660). Real padded line crops keep a digit-tall densest band.
        let bandHeight = bestEnd - bestStart
        if bandHeight * 3 < height {
            return self
        }
        let y0 = max(0, bestStart - marginY)
        let y1 = min(height, bestEnd + marginY)
        if x0 == 0, y0 == 0, x1 == width, y1 == height {
            return self
        }
        guard x1 - x0 > 8, y1 - y0 > 8 else { return self }
        return cropped(x0: x0, y0: y0, x1: x1, y1: y1)
    }

    /// Median luminance — proxy for glass on a mostly-glass short-wide crop.
    fileprivate func peelGlassMedian() -> Int {
        guard !pixels.isEmpty else { return 128 }
        var hist = [Int](repeating: 0, count: 256)
        for pixel in pixels {
            hist[Int(pixel)] += 1
        }
        var seen = 0
        let mid = (pixels.count + 1) / 2
        for level in 0..<256 {
            seen += hist[level]
            if seen >= mid {
                return level
            }
        }
        return 128
    }

    /// A panel crop, or nil when the rect is tiny, nearly the whole frame, or empty.
    func panelCrop(_ region: CGRect) -> GrayBuffer? {
        let area = region.width * region.height
        let full = CGFloat(width * height)
        guard area > 64, area < full * 0.85 else { return nil }
        let x0 = Int(region.minX.rounded(.down))
        let y0 = Int(region.minY.rounded(.down))
        let x1 = Int(region.maxX.rounded(.up))
        let y1 = Int(region.maxY.rounded(.up))
        let cropped = cropped(x0: x0, y0: y0, x1: x1, y1: y1)
        guard cropped.width > 8, cropped.height > 8 else { return nil }
        return cropped
    }

    func cropped(x0: Int, y0: Int, x1: Int, y1: Int) -> GrayBuffer {
        let left = max(0, min(width, x0))
        let top = max(0, min(height, y0))
        let right = max(left, min(width, x1))
        let bottom = max(top, min(height, y1))
        let newW = right - left
        let newH = bottom - top
        guard newW > 0, newH > 0 else { return GrayBuffer(pixels: [], width: 0, height: 0) }
        var out = [UInt8](repeating: 0, count: newW * newH)
        for y in 0..<newH {
            let source = (top + y) * width + left
            out.replaceSubrange(
                (y * newW)..<((y + 1) * newW),
                with: pixels[source..<(source + newW)]
            )
        }
        return GrayBuffer(pixels: out, width: newW, height: newH)
    }

    /// Area-average into a smaller buffer. Used so the finder does not walk
    /// every pixel of a large sensor. The caller maps the rect back.
    func downsampled(width targetWidth: Int, height targetHeight: Int) -> GrayBuffer {
        guard targetWidth > 0, targetHeight > 0, width > 0, height > 0 else { return self }
        if targetWidth == width, targetHeight == height { return self }
        var out = [UInt8](repeating: 0, count: targetWidth * targetHeight)
        for y in 0..<targetHeight {
            let srcY0 = y * height / targetHeight
            let srcY1 = min(height, max(srcY0 + 1, (y + 1) * height / targetHeight))
            for x in 0..<targetWidth {
                let srcX0 = x * width / targetWidth
                let srcX1 = min(width, max(srcX0 + 1, (x + 1) * width / targetWidth))
                var sum = 0
                var count = 0
                for sy in srcY0..<srcY1 {
                    let row = sy * width
                    for sx in srcX0..<srcX1 {
                        sum += Int(pixels[row + sx])
                        count += 1
                    }
                }
                out[y * targetWidth + x] = count > 0 ? UInt8(sum / count) : 0
            }
        }
        return GrayBuffer(pixels: out, width: targetWidth, height: targetHeight)
    }

    /// Locate a sealed LCD glass (non-ink pocket closed by bezel ink) and
    /// expand by a bezel margin. Returns nil when the frame has no panel that
    /// is meaningfully smaller than the whole image (#596).
    ///
    /// Analysis runs on a fitted buffer (max long edge
    /// ``SevenSegmentOCR.digitPanelAnalysisMaxSide``) so full-resolution
    /// library photos do not stall in `localRange` (#650). The returned rect
    /// is mapped back to this buffer's coordinates.
    func digitPanelBounds() -> CGRect? {
        let analysis = fitted(maxSide: SevenSegmentOCR.digitPanelAnalysisMaxSide)
        SevenSegmentOCR.lastDigitPanelAnalysisLongEdge = max(analysis.width, analysis.height)
        let raw = analysis.masks()
        guard let found = Self.largerPanel(
            analysis.sealedPanelBounds(in: raw.dark),
            analysis.sealedPanelBounds(in: raw.light)
        ) else { return nil }
        return mapRect(found, from: analysis)
    }

    private static func largerPanel(_ dark: CGRect?, _ light: CGRect?) -> CGRect? {
        switch (dark, light) {
        case let (d?, l?):
            return d.width * d.height >= l.width * l.height ? d : l
        case let (d?, nil):
            return d
        case let (nil, l?):
            return l
        case (nil, nil):
            return nil
        }
    }

    func frameCandidates(whole: SegmentFrameCandidate) -> [SegmentFrameCandidate] {
        var candidates = [whole]
        let raw = masks()
        if let sealed = Self.largerPanel(
            sealedPanelBounds(in: raw.dark),
            sealedPanelBounds(in: raw.light)
        ), isLocalFrame(sealed) {
            candidates.append(SegmentFrameCandidate(finder: .sealedPocket, rect: sealed))
        }
        if let ink = inkStackBounds(dark: raw.dark, light: raw.light) {
            candidates.append(SegmentFrameCandidate(finder: .inkStack, rect: ink))
        }
        return candidates
    }

    /// Digit-row ink, not the canvas and not the larger glass blob. Prefer the
    /// stroke polarity. Fall back only when that bbox is missing or full-frame.
    private func inkStackBounds(dark: Mask, light: Mask) -> CGRect? {
        let darkRect = inkBounds(in: dark)
        let lightRect = inkBounds(in: light)
        if prefersDark(dark, light) {
            return darkRect ?? lightRect
        }
        return lightRect ?? darkRect
    }

    private func inkBounds(in mask: Mask) -> CGRect? {
        let bands = projectionBands(mask.rowSums, height: height)
        guard let first = bands.first, let last = bands.last, last.1 > first.0 else { return nil }
        var minX = width
        var maxX = -1
        let y1 = min(height, last.1)
        for y in first.0..<y1 {
            let row = y * width
            for x in 0..<width where mask.bits[row + x] {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
            }
        }
        guard maxX >= minX else { return nil }
        let rect = CGRect(x: minX, y: first.0, width: maxX - minX + 1, height: y1 - first.0)
        return isLocalFrame(rect) ? rect : nil
    }

    private func isLocalFrame(_ rect: CGRect) -> Bool {
        rect.width * rect.height > 64
            && rect.width < CGFloat(width) * 0.85
            && rect.height < CGFloat(height) * 0.85
    }

    private func mapRect(_ rect: CGRect, from analysis: GrayBuffer) -> CGRect {
        guard analysis.width != width || analysis.height != height else { return rect }
        let scaleX = CGFloat(width) / CGFloat(analysis.width)
        let scaleY = CGFloat(height) / CGFloat(analysis.height)
        return CGRect(
            x: rect.minX * scaleX,
            y: rect.minY * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )
    }

    private func sealedPanelBounds(in mask: Mask) -> CGRect? {
        let width = mask.width
        let height = mask.height
        let count = width * height
        guard width > 0, height > 0, mask.bits.count == count else { return nil }
        var outside = [Bool](repeating: false, count: count)
        var queue: [Int] = []
        func push(_ x: Int, _ y: Int) {
            guard x >= 0, y >= 0, x < width, y < height else { return }
            let index = y * width + x
            guard !mask.bits[index], !outside[index] else { return }
            outside[index] = true
            queue.append(index)
        }
        for x in 0..<width {
            push(x, 0)
            push(x, height - 1)
        }
        for y in 0..<height {
            push(0, y)
            push(width - 1, y)
        }
        var head = 0
        while head < queue.count {
            let index = queue[head]
            head += 1
            let x = index % width
            let y = index / width
            push(x - 1, y)
            push(x + 1, y)
            push(x, y - 1)
            push(x, y + 1)
        }
        var seen = [Bool](repeating: false, count: count)
        var bestArea = 0
        var bestMinX = 0
        var bestMinY = 0
        var bestMaxX = 0
        var bestMaxY = 0
        for start in 0..<count where !mask.bits[start] && !outside[start] && !seen[start] {
            var component = [start]
            seen[start] = true
            var compHead = 0
            let sx = start % width
            let sy = start / width
            var minX = sx
            var maxX = sx
            var minY = sy
            var maxY = sy
            while compHead < component.count {
                let index = component[compHead]
                compHead += 1
                let x = index % width
                let y = index / width
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
                for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
                    guard nx >= 0, ny >= 0, nx < width, ny < height else { continue }
                    let next = ny * width + nx
                    guard !mask.bits[next], !outside[next], !seen[next] else { continue }
                    seen[next] = true
                    component.append(next)
                }
            }
            if component.count > bestArea {
                bestArea = component.count
                bestMinX = minX
                bestMinY = minY
                bestMaxX = maxX
                bestMaxY = maxY
            }
        }
        // Counter holes inside an 8 are sealed too. Require a glass-sized
        // pocket that is still clearly smaller than a full-frame photo.
        let pocketW = bestMaxX - bestMinX + 1
        let pocketH = bestMaxY - bestMinY + 1
        guard bestArea >= max(400, count / 200) else { return nil }
        guard bestArea * 100 < count * 85 else { return nil }
        guard pocketW >= 40, pocketH >= 40 else { return nil }
        // A slow dark skirt stays non-ink, so the pocket bbox includes it
        // (#600). A sharp bezel is ink and is already outside this rect.
        let opened = droppingDarkMargin(
            minX: bestMinX,
            minY: bestMinY,
            maxX: bestMaxX,
            maxY: bestMaxY
        )
        let pad = max(12, min(opened.maxX - opened.minX + 1, opened.maxY - opened.minY + 1) / 16)
        let x0 = max(0, opened.minX - pad)
        let y0 = max(0, opened.minY - pad)
        let x1 = min(width - 1, opened.maxX + pad)
        let y1 = min(height - 1, opened.maxY + pad)
        let fitted = droppingDarkMargin(minX: x0, minY: y0, maxX: x1, maxY: y1)
        return CGRect(
            x: fitted.minX,
            y: fitted.minY,
            width: fitted.maxX - fitted.minX + 1,
            height: fitted.maxY - fitted.minY + 1
        )
    }

    /// Drop edges that are darker than three quarters of the interior. The
    /// bezel pad can pull that skirt back in, so callers run this again
    /// after padding.
    private func droppingDarkMargin(
        minX: Int,
        minY: Int,
        maxX: Int,
        maxY: Int
    ) -> (minX: Int, minY: Int, maxX: Int, maxY: Int) {
        var left = minX
        var top = minY
        var right = maxX
        var bottom = maxY
        guard right > left, bottom > top, right < width, bottom < height else {
            return (minX, minY, maxX, maxY)
        }
        let insetX = max(0, (right - left) / 4)
        let insetY = max(0, (bottom - top) / 4)
        let interior = rectMean(
            minX: left + insetX,
            minY: top + insetY,
            maxX: right - insetX,
            maxY: bottom - insetY
        )
        let limit = interior * 3 / 4
        // Vertical trim keeps the original width. Shrinking x here would
        // hide a dark top row behind the brighter glass in the middle.
        let rowLeft = left
        let rowRight = right
        func rowMean(_ y: Int) -> Int {
            var sum = 0
            let span = rowRight - rowLeft + 1
            for x in rowLeft...rowRight {
                sum += Int(pixels[y * width + x])
            }
            return sum / span
        }
        while bottom - top > 40, rowMean(top) < limit {
            top += 1
        }
        while bottom - top > 40, rowMean(bottom) < limit {
            bottom -= 1
        }
        func columnMean(_ x: Int) -> Int {
            var sum = 0
            let span = bottom - top + 1
            for y in top...bottom {
                sum += Int(pixels[y * width + x])
            }
            return sum / span
        }
        while right - left > 40, columnMean(left) < limit {
            left += 1
        }
        while right - left > 40, columnMean(right) < limit {
            right -= 1
        }
        return (left, top, right, bottom)
    }

    private func rectMean(minX: Int, minY: Int, maxX: Int, maxY: Int) -> Int {
        guard maxX >= minX, maxY >= minY else { return 0 }
        var sum = 0
        var count = 0
        for y in minY...maxY {
            for x in minX...maxX {
                sum += Int(pixels[y * width + x])
                count += 1
            }
        }
        guard count > 0 else { return 0 }
        return sum / count
    }

    static func readRows(
        in buffer: GrayBuffer,
        splittingRows: Bool = true,
        preferredPitch: PreferredDigitPitch? = nil,
        allowBandPitch: Bool = false,
        sampleBand: Int = 0,
        rowFinder: SegmentRowFinder? = nil,
        polarityRead: ((Bool) -> Void)? = nil
    ) -> [[Cell]] {
        let raw = buffer.masks()
        // A frame inside the crop seals the glass. Ink outside that glass is the bezel.
        let sealed = (dark: keepingInteriorInk(raw.dark), light: keepingInteriorInk(raw.light))
        // A dark bezel that does touch the crop edge would outline the glass as one zero.
        let masks = (dark: clearingBorderComponents(sealed.dark), light: clearingBorderComponents(sealed.light))
        let sealedCore = (dark: keepingInteriorInk(raw.darkCore), light: keepingInteriorInk(raw.lightCore))
        let cores = (dark: clearingBorderComponents(sealedCore.dark), light: clearingBorderComponents(sealedCore.light))
        // A glare line marks a full-width run of glass on the dark mask. That
        // one run hides the stroke columns, so the light glass looks like the
        // ink and every digit reads as 8 (`rescannedRowCrop`). Drop that glass
        // before choosing polarity. A dark bar stays; it is the stroke.
        let darkMask = withoutFullWidthGlass(masks.dark, pixels: buffer.pixels)
        let darkCore = withoutFullWidthGlass(cores.dark, pixels: buffer.pixels)
        let darkPreferred = prefersDark(darkMask, masks.light)
        let darkChoice = polarity(isDark: true, loose: darkMask, core: darkCore)
        let lightChoice = polarity(isDark: false, loose: masks.light, core: cores.light)
        let chosen: (isDark: Bool, glyphs: Mask, bandSource: Mask)
        let opened: Bool
        if darkChoice.opens != lightChoice.opens {
            // A sole open wins only when that polarity looks like ink. Glass
            // marked as light fills the panel and false-opens; taking it
            // over prefersDark collapses washed bezels to "8" / empty (#598).
            let openIsDark = darkChoice.opens
            if openIsDark == darkPreferred {
                chosen = openIsDark ? darkChoice.reading : lightChoice.reading
                opened = true
            } else if darkPreferred {
                let forced = polarity(
                    isDark: true,
                    loose: darkMask,
                    core: darkCore,
                    forceOpen: true
                )
                chosen = forced.reading
                opened = forced.opens
            } else {
                let forced = polarity(
                    isDark: false,
                    loose: masks.light,
                    core: cores.light,
                    forceOpen: true
                )
                chosen = forced.reading
                opened = forced.opens
            }
        } else if darkPreferred {
            chosen = darkChoice.reading
            opened = darkChoice.opens
        } else {
            chosen = lightChoice.reading
            opened = lightChoice.opens
        }
        let primaryIsDark = chosen.isDark
        polarityRead?(primaryIsDark)
        let glyphs = chosen.glyphs
        let bandSource = chosen.bandSource
        if buffer.width >= 1000 {
            let ink = glyphs.bits.filter { $0 }.count
            trace(
                "read \(buffer.width)x\(buffer.height) dark=\(primaryIsDark) opened=\(opened) ink=\(ink)\n"
            )
        }
        if let rowFinder {
            return finderRows(
                in: buffer,
                dark: masks.dark,
                light: masks.light,
                rowFinder: rowFinder,
                sampleBand: sampleBand,
                preferredPitch: preferredPitch
            )
        }
        // A two-pixel scratch through the row gap is not a digit row. Leaving
        // every ink pixel in the projection glues the rows (`rescannedRowCrop`
        // → `880`). The opened mask already uses this floor.
        let bandSums = digitRowSums(bandSource.rowSums)
        let foundBands = runs(bandSums)
        // Scratches between two washed rows keep a few pixels, so the gap never
        // hits zero. Split only when both sides are a full row of digits.
        let separated = (!opened && foundBands.count <= 1) ? rowGapBands(bandSource) : foundBands
        let solidBands = opened
            ? foundBands.filter { ($0.1 - $0.0) * 20 >= buffer.height }
            : foundBands
        let paintedMarks = buffer.extremeMarkMask()
        let measuredBands = opened ? solidBands : merge(foundBands, whenGapBelow: 0)
        let measured = measuredBands.map { band -> (band: (Int, Int), cells: [Cell]) in
            return (
                band,
                cells(
                    in: band,
                    mask: glyphs,
                    buffer: buffer,
                    bandIndex: 0,
                    darkInk: primaryIsDark,
                    preferredPitch: preferredPitch,
                    sampleBand: sampleBand
                )
            )
        }
        let tallHeights = measured.flatMap(\.cells).filter { $0.height > 0 }.map(\.height).sorted()
        let cellHeight = tallHeights.isEmpty ? 1 : tallHeights[tallHeights.count / 2]
        // Gap-glare / bezel specks are a few pixels tall. Left in the list they
        // chip the inter-row gap into pieces smaller than cellHeight/2, so merge
        // joins both digit rows and tallCrop never gets a per-row window (#591).
        let minBandHeight = max(6, cellHeight / 6)
        let substantiveBands = separated.filter { $0.1 - $0.0 >= minBandHeight }
        let bandsForSplit = substantiveBands.count >= 2 ? substantiveBands : separated
        // merge treats a zero limit as "pick a default", which would close
        // the gap this split just opened.
        // Merging heals a digit that glare split into pieces. Bands that each
        // read as a row of confident digits are rows, even when haze narrows
        // the gap below cellHeight/2 (`rescannedRowCrop` → `018-`) (#661).
        let bandsAreRows: Bool = {
            guard splittingRows, !opened, bandsForSplit.count >= 2 else { return false }
            let cleaned = clearingOverlongRows(
                glyphs,
                bands: bandsForSplit,
                pixels: buffer.pixels
            )
            return bandsForSplit.allSatisfy { raw in
                let band = trimmingSparseEdges(raw, mask: cleaned)
                let found = cells(
                    in: band,
                    mask: cleaned,
                    buffer: buffer,
                    bandIndex: 0,
                    darkInk: primaryIsDark,
                    preferredPitch: preferredPitch,
                    sampleBand: sampleBand
                )
                let rowHeight = band.1 - band.0
                let solid = found.filter { cell in
                    cell.character.isNumber && cell.confidence == 1
                        && cell.height * 10 >= rowHeight * 7
                }
                return solid.count >= 2 && solid.count * 2 > found.count
            }
        }()
        // Haze above a row shrinks the empty gap below half a cell, which is
        // the merge limit, but the two bands are still rows. A glare split
        // inside one digit is a thinner gap, or one piece is short. Keep the
        // rows; merge only that piece.
        let separatedRows = bandsForSplit.count >= 2 && zip(bandsForSplit, bandsForSplit.dropFirst()).allSatisfy { upper, lower in
            let gap = lower.0 - upper.1
            let upperHeight = upper.1 - upper.0
            let lowerHeight = lower.1 - lower.0
            let shorter = min(upperHeight, lowerHeight)
            let bothRows = upperHeight >= 40 && lowerHeight >= 40
                && upperHeight * 2 >= lowerHeight && lowerHeight * 2 >= upperHeight
            return bothRows && gap < max(1, cellHeight / 2) && gap * 10 >= shorter
        }
        let splitBands = opened
            ? merge(solidBands, whenGapBelow: max(2, buffer.height / 40))
            : (bandsForSplit.count > foundBands.count || bandsAreRows || separatedRows
                ? bandsForSplit
                : merge(bandsForSplit, whenGapBelow: max(1, cellHeight / 2)))
        // No seven-segment stroke runs further across than its row is tall.
        // A longer run is glare or chrome. Clear those rows, then peel the
        // haze they hid so the gap between rows stays a gap (#661).
        // A bright gap line also marks the glass under it. That veil is not
        // dark, but the halfway cut calls it ink and one row becomes one blob
        // (`rescannedRowCrop` → a line of 8s). The row crop has to start on
        // the digit bar, below the veil, or its window sees the line again.
        let cellGlyphs = opened
            ? glyphs
            : clearingOverlongRows(glyphs, bands: splitBands, pixels: buffer.pixels)
        let lineBands: [(Int, Int)]
        if !splittingRows, splitBands.count > 1 {
            let y0 = splitBands.map(\.0).min() ?? 0
            let y1 = splitBands.map(\.1).max() ?? buffer.height
            lineBands = y1 > y0 ? [(y0, y1)] : splitBands
        } else {
            lineBands = splitBands.compactMap { raw in
                let headed = trimmingGlareHead(raw, mask: glyphs, pixels: buffer.pixels)
                let peeled = trimmingSparseEdges(headed, mask: cellGlyphs)
                glareHeadNote += "head \(raw.0)-\(raw.1) -> \(headed.0)-\(headed.1) peel \(peeled.0)-\(peeled.1) dark=\(primaryIsDark) open=\(opened)\n"
                return peeled.1 > peeled.0 + 8 ? peeled : nil
            }
        }
        if buffer.width >= 1000 {
            let listed = lineBands.map { "\($0.0)-\($0.1)" }.joined(separator: ",")
            trace("bands \(listed)\n")
        }
        // The window is sized from the whole crop. Two rows make it wide
        // enough to mark the glass between digits. Read each row from a
        // crop of that row when that crop's window is actually narrower.
        // A window that fits inside a stroke drops the middle of the bar,
        // so a row that is already on the small window stays on this mask.
        if splittingRows, lineBands.count > 1 {
            let span = readingSpan(glyphs, bands: lineBands)
            let parentRadius = windowRadius(width: buffer.width, height: buffer.height)
            if buffer.width >= 1000 {
                trace("span \(String(describing: span)) radius \(parentRadius)\n")
            }
            var windowNarrows = true
            var rescanned: [[Cell]] = []
            let rowProfile = glyphs.rowSums
            // Known-good price crop is 380px tall. On haze-tall (photo) bands,
            // reach into the row gap so each window can sit on a price-like Y.
            // Short synthetic digit bands must not borrow that gap — gap glare
            // above each row (tallCrop) then joins into the crop and the read
            // collapses (got "8" on #591 combined).
            let priceBandHeight = 380
            let gapPad = max(24, priceBandHeight / 8)
            // Approach D: once a price-like row yields digit boxes, copy that
            // pitch into later rowcrops (volume) so wash bridges still cut.
            var rowPitch = preferredPitch
            for band in lineBands {
                let rawHeight = band.1 - band.0
                let searchBand: (Int, Int)
                if rawHeight + 16 > priceBandHeight {
                    searchBand = (
                        max(0, band.0 - gapPad),
                        min(buffer.height, band.1 + gapPad)
                    )
                } else {
                    searchBand = band
                }
                let tight = priceMatchedBand(
                    rowProfile,
                    in: searchBand,
                    targetHeight: priceBandHeight
                )
                // Synth short bands keep a few pixels of pad (pre-B geometry).
                // Photo / haze-tall windows already include gapPad in searchBand.
                let edgePad = rawHeight + 16 > priceBandHeight ? 0 : 4
                let y0 = max(0, tight.0 - edgePad)
                let y1 = min(buffer.height, tight.1 + edgePad)
                let sharedLeft = span?.0 ?? 0
                let sharedRight = span?.1 ?? buffer.width
                // Left edge scores digit stems in the ink band, not the gap
                // pad that the Y window may borrow above/below.
                let leftBand = (
                    max(band.0, tight.0),
                    min(band.1, tight.1)
                )
                let left = priceMatchedLeft(
                    glyphs,
                    band: leftBand.1 > leftBand.0 ? leftBand : band,
                    sharedLeft: sharedLeft,
                    sharedRight: sharedRight
                )
                let x0 = max(0, left - 8)
                let x1 = min(buffer.width, sharedRight + 8)
                let crop = buffer.cropped(x0: x0, y0: y0, x1: x1, y1: y1)
                guard crop.width > 8, crop.height > 8 else {
                    windowNarrows = false
                    break
                }
                let cropRadius = windowRadius(width: crop.width, height: crop.height)
                if parentRadius < cropRadius + 8 {
                    windowNarrows = false
                    break
                }
                let found = readRows(
                    in: crop,
                    splittingRows: false,
                    preferredPitch: rowPitch,
                    sampleBand: sampleBand
                ).flatMap { $0 }
                let shifted = found.map { $0.shifted(dx: x0, dy: y0) }
                if buffer.width >= 100 {
                    let pitchNote = rowPitch.map { " pitch \($0.body)x\($0.count)" } ?? ""
                    let line = "rowcrop \(x0),\(y0) \(crop.width)x\(crop.height) [\(String(shifted.map(\.character)))]\(pitchNote)\n"
                    glareHeadNote += line
                    trace(line)
                }
                if !shifted.isEmpty {
                    rescanned.append(shifted)
                }
                if rowPitch == nil {
                    let digits = found.filter { cell in
                        cell.character.isNumber && cell.height > 0
                    }.sorted { $0.minX < $1.minX }
                    if let body = median(digits.map(\.box.width)), body > 0, digits.count >= 2 {
                        let spacings = zip(digits, digits.dropFirst()).map { left, right in
                            right.box.midX - left.box.midX
                        }
                        let stride = median(spacings.filter { $0 > 0 }) ?? (body + max(1, body / 6))
                        rowPitch = PreferredDigitPitch(body: body, count: digits.count, stride: max(body, stride))
                    }
                }
            }
            if windowNarrows, !rescanned.isEmpty {
                return rescanned
            }
            // Rowcrop aborted (parent window already tight — digitPitch synth).
            // Copy pitch across top-level bands only — never inside rowcrops,
            // never during standingUp/deskew scoring (allowBandPitch false),
            // and only on small panels (tallCrop/gapGlare fixtures are larger).
            if allowBandPitch, buffer.width < 350, buffer.height < 350 {
                var bandPitch = preferredPitch
                return lineBands.compactMap { band -> [Cell]? in
                    let found = cells(
                        in: band,
                        mask: cellGlyphs,
                        buffer: buffer,
                        bandIndex: 0,
                        darkInk: primaryIsDark,
                        preferredPitch: bandPitch,
                        sampleBand: sampleBand
                    )
                    let marks = opened
                        ? []
                        : oppositeMarks(in: band, secondary: paintedMarks, existing: found, buffer: buffer, bandIndex: 0)
                    let dots = baselineDots(in: band, mask: glyphs, cells: found, width: buffer.width, bandIndex: 0)
                    var row = found + marks + dots
                    if bandPitch != nil {
                        row = pitchRowMarks(row, mask: glyphs, band: band, width: buffer.width)
                    }
                    if bandPitch == nil {
                        let digits = found.filter { cell in
                            cell.character.isNumber && cell.height > 0
                        }.sorted { $0.minX < $1.minX }
                        if let body = median(digits.map(\.box.width)), body > 0, digits.count >= 2 {
                            let spacings = zip(digits, digits.dropFirst()).map { left, right in
                                right.box.midX - left.box.midX
                            }
                            let stride = median(spacings.filter { $0 > 0 }) ?? (body + max(1, body / 6))
                            bandPitch = PreferredDigitPitch(
                                body: body,
                                count: digits.count,
                                stride: max(body, stride)
                            )
                        }
                    }
                    return row.isEmpty ? nil : row
                }
            }
        }
        return lineBands.compactMap { band -> [Cell]? in
            let found = cells(
                in: band,
                mask: cellGlyphs,
                buffer: buffer,
                bandIndex: 0,
                darkInk: primaryIsDark,
                preferredPitch: preferredPitch,
                sampleBand: sampleBand
            )
            let marks = opened
                ? []
                : oppositeMarks(in: band, secondary: paintedMarks, existing: found, buffer: buffer, bandIndex: 0)
            let dots = baselineDots(in: band, mask: glyphs, cells: found, width: buffer.width, bandIndex: 0)
            var row = found + marks + dots
            // Pitch volume often washes the glass above the real decimal, so
            // baselineDots misses it and a trailing noise mark can survive.
            // Keep only marks between digits; if none, place one in the
            // clearest inter-digit gap that still has baseline ink.
            if preferredPitch != nil {
                row = pitchRowMarks(row, mask: glyphs, band: band, width: buffer.width)
            }
            return row.isEmpty ? nil : row
        }
    }

    /// Prefer a decimal between digit boxes on pitch-driven rows. Drop marks
    /// that sit before the first digit or after the last.
    private static func pitchRowMarks(
        _ row: [Cell],
        mask: Mask,
        band: (Int, Int),
        width: Int
    ) -> [Cell] {
        let digits = row.filter { $0.character.isNumber && $0.height > 0 }
            .sorted { $0.minX < $1.minX }
        let other = row.filter { cell in
            !cell.character.isNumber && cell.character != "." && cell.character != ","
        }
        guard digits.count >= 2 else { return row }
        let firstDigit = digits[0].minX
        let lastDigit = digits[digits.count - 1].maxX
        let between = row.filter { cell in
            guard cell.character == "." || cell.character == "," else { return false }
            return cell.minX >= firstDigit && cell.maxX <= lastDigit
        }
        // Keep a real inter-digit mark. Inventing is only for washed X.xxx
        // volume (four digits) when the decimal was lost (#591 / Approach D).
        // Two-digit integer rows that inherit pitch must stay unmarked (#644).
        if !between.isEmpty {
            return (digits + other + between).sorted { $0.minX < $1.minX }
        }
        guard digits.count >= 4 else {
            return (digits + other).sorted { $0.minX < $1.minX }
        }
        // Pitch rows copy a price body onto washed volume (Approach D).
        // That volume is X.xxx units: place the mark in the first inter-digit
        // gap. Ink scoring mis-fired on this photo (max → 80.22, empty → 802.2,
        // non-flood → broke edgeStrip when the real dot itself looked "flooded").
        // Drop stale leading/trailing marks; do not invent stroke ink — only a
        // gap anchor.
        let digitHeight = median(digits.map(\.height)) ?? 0
        guard digitHeight > 8 else {
            return (digits + other).sorted { $0.minX < $1.minX }
        }
        let baseline = median(digits.map(\.maxY)) ?? band.1
        let top = max(band.0, baseline - max(4, digitHeight / 8))
        let bottom = min(mask.height, max(baseline, band.1))
        guard bottom > top else { return (digits + other).sorted { $0.minX < $1.minX } }
        let left = digits[0].maxX
        let right = digits[1].minX
        var placed = digits + other
        if right - left > 2 {
            let mid = (left + right) / 2
            let pad = max(1, (right - left) / 4)
            let box = PixelBox(
                minX: max(left, mid - pad),
                minY: top,
                maxX: min(right, mid + pad),
                maxY: bottom
            )
            trace("pitch marks place . @\(mid) first-gap \(left)-\(right)\n")
            placed.append(Cell(box: box, character: ".", confidence: 1, band: 0))
        }
        return placed.sorted { $0.minX < $1.minX }
    }
}

private func keepingInteriorInk(_ mask: Mask) -> Mask {
    let width = mask.width
    let height = mask.height
    let count = width * height
    guard width > 0, height > 0, mask.bits.count == count else { return mask }
    var outside = [Bool](repeating: false, count: count)
    var queue: [Int] = []
    func push(_ x: Int, _ y: Int) {
        guard x >= 0, y >= 0, x < width, y < height else { return }
        let index = y * width + x
        guard !mask.bits[index], !outside[index] else { return }
        outside[index] = true
        queue.append(index)
    }
    for x in 0..<width {
        push(x, 0)
        push(x, height - 1)
    }
    for y in 0..<height {
        push(0, y)
        push(width - 1, y)
    }
    var head = 0
    while head < queue.count {
        let index = queue[head]
        head += 1
        let x = index % width
        let y = index / width
        push(x - 1, y)
        push(x + 1, y)
        push(x, y - 1)
        push(x, y + 1)
    }
    var seen = [Bool](repeating: false, count: count)
    var bestArea = 0
    var bestMinX = 0
    var bestMinY = 0
    var bestMaxX = 0
    var bestMaxY = 0
    for start in 0..<count where !mask.bits[start] && !outside[start] && !seen[start] {
        var component = [start]
        seen[start] = true
        var compHead = 0
        let sx = start % width
        let sy = start / width
        var minX = sx
        var maxX = sx
        var minY = sy
        var maxY = sy
        while compHead < component.count {
            let index = component[compHead]
            compHead += 1
            let x = index % width
            let y = index / width
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
            for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
                guard nx >= 0, ny >= 0, nx < width, ny < height else { continue }
                let next = ny * width + nx
                guard !mask.bits[next], !outside[next], !seen[next] else { continue }
                seen[next] = true
                component.append(next)
            }
        }
        if component.count > bestArea {
            bestArea = component.count
            bestMinX = minX
            bestMinY = minY
            bestMaxX = maxX
            bestMaxY = maxY
        }
    }
    // Counters inside an 8 are sealed too. Only a glass-sized region counts.
    guard bestArea * 8 >= count else { return mask }
    var bits = mask.bits
    for index in bits.indices where bits[index] {
        let x = index % width
        let y = index / width
        if x < bestMinX || x > bestMaxX || y < bestMinY || y > bestMaxY {
            bits[index] = false
        }
    }
    return Mask(bits: bits, width: width, height: height)
}

private func clearingBorderComponents(_ mask: Mask) -> Mask {
    guard mask.width > 0, mask.height > 0 else { return mask }
    var bits = mask.bits
    let width = mask.width
    let height = mask.height
    var seen = [Bool](repeating: false, count: bits.count)
    func consider(_ start: Int) {
        guard bits[start], !seen[start] else { return }
        var queue = [start]
        seen[start] = true
        var head = 0
        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0
        while head < queue.count {
            let index = queue[head]
            head += 1
            let x = index % width
            let y = index / width
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
            let neighbors = [index - 1, index + 1, index - width, index + width]
            for next in neighbors where next >= 0 && next < bits.count {
                let nx = next % width
                let ny = next / width
                guard abs(nx - x) + abs(ny - y) == 1, bits[next], !seen[next] else { continue }
                seen[next] = true
                queue.append(next)
            }
        }
        let boxW = maxX - minX + 1
        let boxH = maxY - minY + 1
        // A bezel outlines the glass. A comma tail can touch the edge and stay,
        // including when the tail joins the bezel. Clear the frame, not the
        // stroke that runs inward past it.
        guard boxW * 2 > width, boxH * 2 > height else { return }
        let thickness = frameThickness(queue, width: width, height: height)
        for index in queue {
            let x = index % width
            let y = index / width
            let distance = min(x, y, width - 1 - x, height - 1 - y)
            if distance < thickness {
                bits[index] = false
            }
        }
    }
    for x in 0..<width {
        consider(x)
        consider((height - 1) * width + x)
    }
    for y in 0..<height {
        consider(y * width)
        consider(y * width + width - 1)
    }
    return clearingFullHeightStrips(Mask(bits: bits, width: width, height: height))
}

/// Clear ink that runs the full height of the crop when the glyphs do not.
///
/// A trimmed crop can keep a bezel's side edges as thin strips from the top
/// edge to the bottom edge. They are too narrow for the frame pass and read
/// as `1`. Digits on that crop leave glass above or below them, so a strip
/// that reaches both edges is taller than any digit. When other ink reaches
/// both edges too (a tight crop, where a digit's bars touch them), the strip
/// may be a stem and nothing is cleared. Only strips narrower than the
/// glyphs go: glass or a wash that fills the crop is wider.
private func clearingFullHeightStrips(_ mask: Mask) -> Mask {
    let width = mask.width
    let height = mask.height
    guard width > 0, height > 2 else { return mask }
    var seen = [Bool](repeating: false, count: mask.bits.count)
    var spanning: [(pixels: [Int], width: Int)] = []
    var others: [(minY: Int, maxY: Int, width: Int)] = []
    for start in mask.bits.indices where mask.bits[start] && !seen[start] {
        var queue = [start]
        seen[start] = true
        var head = 0
        var minY = height
        var maxY = 0
        var minX = width
        var maxX = 0
        while head < queue.count {
            let index = queue[head]
            head += 1
            let x = index % width
            let y = index / width
            minY = min(minY, y)
            maxY = max(maxY, y)
            minX = min(minX, x)
            maxX = max(maxX, x)
            for next in [index - 1, index + 1, index - width, index + width]
            where next >= 0 && next < mask.bits.count {
                guard abs(next % width - x) + abs(next / width - y) == 1,
                      mask.bits[next], !seen[next] else { continue }
                seen[next] = true
                queue.append(next)
            }
        }
        if minY == 0, maxY == height - 1 {
            spanning.append((queue, maxX - minX + 1))
        } else {
            others.append((minY, maxY, maxX - minX + 1))
        }
    }
    // A comma's tail can reach the bottom edge, so glass on either side is enough.
    guard !spanning.isEmpty,
          let top = others.map(\.minY).min(),
          let bottom = others.map(\.maxY).max(),
          top > 0 || bottom < height - 1
    else { return mask }
    // Glyph width: components at least half as tall as the tallest.
    let tallest = others.map { $0.maxY - $0.minY + 1 }.max() ?? 0
    let tall = others.filter { ($0.maxY - $0.minY + 1) * 2 >= tallest }
    guard let glyphWidth = median(tall.map(\.width)) else { return mask }
    var bits = mask.bits
    for component in spanning where component.width < glyphWidth {
        for index in component.pixels {
            bits[index] = false
        }
    }
    return Mask(bits: bits, width: width, height: height)
}


private func frameThickness(_ pixels: [Int], width: Int, height: Int) -> Int {
    let member = Set(pixels)
    var lengths: [Int] = []
    func run(_ x: Int, _ y: Int, _ dx: Int, _ dy: Int) {
        var length = 0
        var cx = x
        var cy = y
        while cx >= 0, cy >= 0, cx < width, cy < height, member.contains(cy * width + cx) {
            length += 1
            cx += dx
            cy += dy
        }
        if length > 0 {
            lengths.append(length)
        }
    }
    for x in 0..<width {
        if member.contains(x) { run(x, 0, 0, 1) }
        let bottom = (height - 1) * width + x
        if member.contains(bottom) { run(x, height - 1, 0, -1) }
    }
    for y in 0..<height {
        if member.contains(y * width) { run(0, y, 1, 0) }
        let right = y * width + width - 1
        if member.contains(right) { run(width - 1, y, -1, 0) }
    }
    guard !lengths.isEmpty else { return 0 }
    return lengths.sorted()[lengths.count / 2]
}

private func digitRowSums(_ sums: [Int]) -> [Int] {
    let peak = sums.max() ?? 0
    // A gap row on a washed LCD still holds a few core pixels. Digit rows
    // hold many more. Leaving the gap at sum > 0 joins the two lines.
    let floor = max(8, peak / 20)
    return sums.map { $0 >= floor ? $0 : 0 }
}

/// ssocr dynamic threshold window. A short crop stays tight. A tall crop
/// grows until the window would meet across the gap between digits.
///
/// Scale-4 square panels (~1100px) hit the 36px growing cap and bridge
/// digit gaps on the parent mask (#659 strokeSized). Cap those near the
/// scale-1 radius (7). Wide single-row crops separately floor the radius
/// at ~half a digit stroke (`height / 15`) so a scale-4 rowcrop does not
/// hollow 48px bars into stems (#659 thickStrokes).
private func windowRadius(width: Int, height: Int) -> Int {
    let shortSide = min(width, height)
    let grown = min(36, max(4, (shortSide - 96) / 24))
    // Nearly square and large → dense multi-row panel (not a wide rowcrop).
    // Rowcrops are much wider than tall (scale-4 ~2.8×). Landscape *two-row*
    // panels (paddedCanvas ~1.7×) must keep `grown` — a 1.5× gate floored
    // those and read garbage (#659 reopen).
    let wideRowMinAspect = 2
    let isWideRow = width > height * wideRowMinAspect
    if shortSide > 600, !isWideRow {
        return min(7, grown)
    }
    guard isWideRow else { return grown }
    // Scale-4 rowcrops (~360px+ tall, 48px strokes) need height/15 so bars
    // stay solid (#659). Scale-1 wide fixtures (filledInk ~200px / five-group
    // ~122px) must keep `grown` — flooring bridges digit gaps (#662 / #602).
    let scale4RowMinHeight = 280
    guard height > scale4RowMinHeight else { return grown }
    let strokeFloor = max(4, height / 15)
    return min(36, max(grown, strokeFloor))
}

/// Start the band on the digit bar when a bright line sits above it.
///
/// The line marks a full-width veil of glass. Haze and the scratch sit
/// above that veil; the bar is the first row with more than one dark run
/// as long as the band's own bar. A band with no such line is unchanged.
private func trimmingGlareHead(
    _ band: (Int, Int),
    mask: Mask,
    pixels: [UInt8]
) -> (Int, Int) {
    let width = mask.width
    let height = band.1 - band.0
    guard height > 8, width > 8, pixels.count == mask.bits.count else { return band }
    // The veil is a long run of glass. Its own minimum is that glass, so a
    // per-row quarter would call the whole run a stroke. The stroke is the
    // dark level that actually covers the band.
    var histogram = [Int](repeating: 0, count: 256)
    for y in band.0..<band.1 {
        let row = y * width
        for x in 0..<width where mask.bits[row + x] {
            histogram[Int(pixels[row + x])] += 1
        }
    }
    let needed = max(8, width / 10)
    var bandDark = 0
    var seen = 0
    for level in 0..<256 {
        seen += histogram[level]
        if seen >= needed {
            bandDark = level
            break
        }
    }
    let strokeCut = bandDark + inkMargin
    func darkRuns(_ y: Int) -> [(start: Int, length: Int)] {
        let row = y * width
        var runs: [(start: Int, length: Int)] = []
        var start = 0
        var length = 0
        for x in 0..<width {
            let dark = mask.bits[row + x] && Int(pixels[row + x]) <= strokeCut
            if dark {
                if length == 0 { start = x }
                length += 1
            } else if length > 0 {
                runs.append((start, length))
                length = 0
            }
        }
        if length > 0 { runs.append((start, length)) }
        return runs
    }
    var bar = 0
    for y in band.0..<band.1 {
        for run in darkRuns(y) where run.length > bar {
            bar = run.length
        }
    }
    guard bar >= 8 else { return band }
    let longEnough = bar * 3 / 4
    func isDigitRow(_ y: Int) -> Bool {
        let runs = darkRuns(y).filter { $0.length >= longEnough }
        if runs.count >= 2 { return true }
        guard let only = runs.first else { return false }
        return only.start > width / 8
    }
    var digit = band.0
    while digit < band.1, !isDigitRow(digit) {
        digit += 1
    }
    guard digit > band.0, digit < band.1, band.1 - digit > 8 else { return band }
    let hasGlare = (band.0..<digit).contains { y in
        rowIsHighlight(pixels, y: y, width: width)
            || rowIsLightVeil(mask, pixels: pixels, y: y, limit: height)
    }
    guard hasGlare else { return band }
    return (digit, band.1)
}

private func rowIsHighlight(_ pixels: [UInt8], y: Int, width: Int) -> Bool {
    guard width > 0, y >= 0, pixels.count >= (y + 1) * width else { return false }
    let row = y * width
    var bright = 0
    for x in 0..<width where pixels[row + x] >= extremeHighlight {
        bright += 1
    }
    return bright * 2 > width
}

/// Drop full-width rows of glass from a dark mask. The halfway cut marks
/// them beside a glare line, and one run then hides every stroke column.
/// The stroke level is the dark ink that actually covers the mask, so a
/// dark bar across the crop stays.
private func withoutFullWidthGlass(_ mask: Mask, pixels: [UInt8]) -> Mask {
    let width = mask.width
    guard width > 8, mask.height > 0, pixels.count == mask.bits.count else { return mask }
    var histogram = [Int](repeating: 0, count: 256)
    var inkCount = 0
    for index in mask.bits.indices where mask.bits[index] {
        histogram[Int(pixels[index])] += 1
        inkCount += 1
    }
    guard inkCount > 0 else { return mask }
    let needed = max(8, inkCount / 20)
    var stroke = 0
    var seen = 0
    for level in 0..<256 {
        seen += histogram[level]
        if seen >= needed {
            stroke = level
            break
        }
    }
    let cut = stroke + inkMargin
    let limit = width * 3 / 4
    var bits = mask.bits
    for y in 0..<mask.height {
        let row = y * width
        var longest = 0
        var run = 0
        var light = 0
        var count = 0
        for x in 0..<width {
            guard bits[row + x] else {
                run = 0
                continue
            }
            run += 1
            if run > longest { longest = run }
            count += 1
            if Int(pixels[row + x]) > cut { light += 1 }
        }
        guard longest > limit, count > 0, light * 2 > count else { continue }
        for x in 0..<width { bits[row + x] = false }
    }
    return Mask(bits: bits, width: width, height: mask.height)
}

/// A full-width run whose pixels are mid-gray, not the dark stroke. The
/// halfway cut marks the glass beside a glare line; a washed bar is dark.
private func rowIsLightVeil(_ mask: Mask, pixels: [UInt8], y: Int, limit: Int) -> Bool {
    let width = mask.width
    guard y >= 0, y < mask.height, pixels.count == mask.bits.count else { return false }
    let row = y * width
    var longest = 0
    var run = 0
    var minV = 255
    var maxV = 0
    var count = 0
    for x in 0..<width {
        if mask.bits[row + x] {
            run += 1
            if run > longest { longest = run }
            let pixel = Int(pixels[row + x])
            count += 1
            if pixel < minV { minV = pixel }
            if pixel > maxV { maxV = pixel }
        } else {
            run = 0
        }
    }
    guard longest > limit, count > 0 else { return false }
    let span = maxV - minV
    guard span > inkMargin else { return false }
    let quarter = minV + span / 4
    var dark = 0
    for x in 0..<width where mask.bits[row + x] && Int(pixels[row + x]) <= quarter {
        dark += 1
    }
    return dark * 2 < count
}

/// Drop sparse rows at the top and bottom of a band. Haze above a digit
/// is many short runs; a stroke holds most of the ink. A row or two of
/// edge noise stays.
private func trimmingSparseEdges(_ band: (Int, Int), mask: Mask) -> (Int, Int) {
    let width = mask.width
    guard band.1 - band.0 > 8 else { return band }
    func rowRuns(_ y: Int) -> [Int] {
        var lengths: [Int] = []
        var length = 0
        let row = y * width
        for x in 0..<width {
            if mask.bits[row + x] {
                length += 1
            } else if length > 0 {
                lengths.append(length)
                length = 0
            }
        }
        if length > 0 { lengths.append(length) }
        return lengths
    }
    let perRow = (band.0..<band.1).map(rowRuns)
    let weighted = perRow.flatMap { $0 }.flatMap { length in Array(repeating: length, count: length) }
    guard let typical = median(weighted), typical >= 3 else { return band }
    func sparse(_ index: Int) -> Bool {
        let lengths = perRow[index]
        guard !lengths.isEmpty else { return true }
        let longRuns = lengths.filter { $0 * 2 >= typical }.count
        let shortRuns = lengths.count - longRuns
        // A left scratch is one solid run. The rest of a haze row is specks.
        // A digit bar is one solid run with no specks, so the peel stops there.
        return longRuns == 0 || (longRuns == 1 && shortRuns > 4)
    }
    let limit = (band.1 - band.0) / 2
    var top = 0
    while top < limit, sparse(top) { top += 1 }
    var bottom = perRow.count
    while perRow.count - bottom < limit, bottom > top + 1, sparse(bottom - 1) { bottom -= 1 }
    let peeledTop = top >= 4 ? top : 0
    let peeledBottom = perRow.count - bottom >= 4 ? bottom : perRow.count
    return (band.0 + peeledTop, band.0 + peeledBottom)
}

/// Clear a short stripe of runs longer than the band is tall. That stripe
/// is glare or chrome, not a stroke. A bar that touches the band edge, or
/// a long run through the middle of the digits, stays.
private func clearingOverlongRows(
    _ mask: Mask,
    bands: [(Int, Int)],
    pixels: [UInt8]
) -> Mask {
    var bits = mask.bits
    let width = mask.width
    for band in bands {
        let limit = band.1 - band.0
        guard limit >= 20 else { continue }
        if pixels.count == mask.bits.count {
            for y in max(0, band.0)..<min(mask.height, band.1)
            where rowIsLightVeil(mask, pixels: pixels, y: y, limit: limit) {
                let row = y * width
                for x in 0..<width { bits[row + x] = false }
            }
        }
        var overlong: [Int] = []
        for y in max(0, band.0)..<min(mask.height, band.1) {
            let row = y * width
            var x = 0
            var longest = 0
            while x < width {
                guard bits[row + x] else { x += 1; continue }
                let start = x
                while x < width, bits[row + x] { x += 1 }
                longest = max(longest, x - start)
            }
            if longest > limit { overlong.append(y) }
        }
        guard let first = overlong.first, let last = overlong.last else { continue }
        guard (last - first + 1) * 4 <= limit else { continue }
        let inset = max(3, limit / 30)
        guard first > band.0 + inset, last < band.1 - 1 - inset else { continue }
        guard last < band.0 + limit / 3 || first > band.1 - limit / 3 else { continue }
        for y in first...last {
            let row = y * width
            for x in 0..<width { bits[row + x] = false }
        }
    }
    return Mask(bits: bits, width: width, height: mask.height)
}

/// Columns that hold digit ink and stay empty in the gap between rows.
/// A strip that is ink on that gap is the bezel edge, not a stroke.
private func readingSpan(_ mask: Mask, bands: [(Int, Int)]) -> (Int, Int)? {
    let width = mask.width
    let height = mask.height
    guard width > 0, height > 0, bands.count >= 2 else { return nil }
    let valleys = zip(bands, bands.dropFirst()).compactMap { pair -> (Int, Int)? in
        let top = pair.0.1
        let bottom = pair.1.0
        guard bottom > top else { return nil }
        return (top, bottom)
    }
    guard !valleys.isEmpty else { return nil }
    var keep = [Bool](repeating: false, count: width)
    var edgeColumn = [Bool](repeating: false, count: width)
    var columnInk = [Int](repeating: 0, count: width)
    for x in 0..<width {
        let edge = valleys.contains { valley in
            // A speck in the gap is not the bezel. The edge is ink through it.
            let limit = max(4, (valley.1 - valley.0) / 3)
            var count = 0
            for y in valley.0..<valley.1 where mask.bits[y * width + x] {
                count += 1
                if count > limit { return true }
            }
            return false
        }
        if edge {
            edgeColumn[x] = true
            continue
        }
        var ink = 0
        for band in bands {
            let y0 = max(0, band.0)
            let y1 = min(height, band.1)
            for y in y0..<y1 where mask.bits[y * width + x] {
                ink += 1
            }
        }
        if ink > 0 {
            keep[x] = true
            columnInk[x] = ink
        }
    }
    let active = keep.indices.filter { keep[$0] }
    guard let first = active.first else { return nil }
    // The hole between strokes grows with the row. A fixed 16px cap keeps
    // one cell of a tall row: scale-4 strokes sit 32px apart. A tenth of
    // the row joins that hole. A group gap is wider than this on the
    // small fixtures.
    let rowHeight = bands.map { max(0, $0.1 - $0.0) }.max() ?? height
    let gapLimit = max(8, rowHeight / 10)
    var runs: [(start: Int, end: Int, ink: Int)] = []
    var start = first
    var end = first
    var ink = columnInk[first]
    // A one- or two-pixel valley mark sits between strokes on a tall row
    // and was cutting the right-hand digits off the run. A real bezel is
    // wider than that.
    let bezelWidth = max(2, rowHeight / 100)
    for index in active.dropFirst() {
        var edgeCount = 0
        if index > end + 1 {
            for x in (end + 1)..<index where edgeColumn[x] {
                edgeCount += 1
            }
        }
        let crossesBezel = edgeCount > bezelWidth
        if index - end <= gapLimit, !crossesBezel {
            end = index
            ink += columnInk[index]
        } else {
            runs.append((start, end + 1, ink))
            start = index
            end = index
            ink = columnInk[index]
        }
    }
    runs.append((start, end + 1, ink))
    guard var best = runs.max(by: { $0.ink < $1.ink }) else { return nil }
    // A ramp that begins as a speck and climbs past a stroke-width hole is
    // the bezel, not another digit. The span stops on the last ink before
    // that hole. Stopping on the ramp itself lets the crop pad reach it.
    let hole = max(8, min(16, height / 40))
    var cursor = best.end - 1
    while cursor > best.start, columnInk[cursor] == 0 {
        cursor -= 1
    }
    let blobEnd = cursor
    while cursor > best.start, columnInk[cursor] > 0 {
        cursor -= 1
    }
    let blobStart = cursor + 1
    var gap = 0
    while cursor - gap > best.start, columnInk[cursor - gap] == 0 {
        gap += 1
    }
    if gap >= hole, blobEnd >= blobStart {
        let blobMax = (blobStart...blobEnd).reduce(0) { max($0, columnInk[$1]) }
        let rising = blobMax > columnInk[blobStart] * 4 && blobMax * 2 > rowHeight
        if rising {
            let cut = cursor - gap + 1
            if cut > best.start, cut < best.end {
                best.end = cut
            }
        }
    }
    let span = best.end - best.start
    guard span > max(12, height / 10) else { return nil }
    return (best.start, best.end)
}

/// When a row band is taller than a price crop, keep the densest window of
/// that height. Prefer a lower start among near-ties so top haze is dropped
/// and the crop lines up with a known-good price Y. Synthetic digit bands
/// that are already short are left alone.
private func priceMatchedBand(_ sums: [Int], in band: (Int, Int), targetHeight: Int) -> (Int, Int) {
    let y0 = max(0, band.0)
    let y1 = min(sums.count, band.1)
    let bandHeight = y1 - y0
    guard bandHeight > targetHeight + 16 else { return band }
    var bestStart = y0
    var bestInk = Int.min
    let lastStart = y1 - targetHeight
    var start = y0
    while start <= lastStart {
        var ink = 0
        for y in start..<(start + targetHeight) {
            ink += sums[y]
        }
        if ink > bestInk {
            bestInk = ink
            bestStart = start
        }
        start += 1
    }
    // Drop a little top haze. 5% overshoots into the gap (32.89); 1% leaves
    // the broken 3_.88 Y. 3% lands on the known-good price crop Y.
    let floorInk = bestInk * 97 / 100
    start = bestStart
    while start <= lastStart {
        var ink = 0
        for y in start..<(start + targetHeight) {
            ink += sums[y]
        }
        if ink >= floorInk {
            bestStart = start
        }
        start += 1
    }
    return (bestStart, bestStart + targetHeight)
}

/// Raise the left crop edge toward digit ink. Wide washed spans (pump crops)
/// pick the densest digit window; shorter synthetic spans only peel a thin
/// scratch prefix so edge-strip fixtures keep their leading digit.
private func priceMatchedLeft(
    _ mask: Mask,
    band: (Int, Int),
    sharedLeft: Int,
    sharedRight: Int
) -> Int {
    let spanWidth = sharedRight - sharedLeft
    if spanWidth > 800 {
        return priceMatchedLeftByDenseWindow(
            mask,
            band: band,
            sharedLeft: sharedLeft,
            sharedRight: sharedRight
        )
    }
    return priceMatchedLeftByScratchPrefix(
        mask,
        band: band,
        sharedLeft: sharedLeft,
        sharedRight: sharedRight
    )
}

private func priceMatchedLeftByDenseWindow(
    _ mask: Mask,
    band: (Int, Int),
    sharedLeft: Int,
    sharedRight: Int
) -> Int {
    let width = mask.width
    let y0 = max(0, band.0)
    let y1 = min(mask.height, band.1)
    let spanWidth = sharedRight - sharedLeft
    let bandHeight = max(1, y1 - y0)
    guard width > 0, y1 > y0, spanWidth > 48 else { return sharedLeft }
    var columnInk = [Int](repeating: 0, count: width)
    for x in sharedLeft..<min(width, sharedRight) {
        var ink = 0
        for y in y0..<y1 where mask.bits[y * width + x] {
            ink += 1
        }
        columnInk[x] = ink
    }
    // Thresholds are relative to the band's peak column. A left glare blob
    // often *is* the peak; digit stems sit well below it. Penalize near-peak
    // fills so the digit field wins. Window ~ price digit run width.
    let peak = (sharedLeft..<min(width, sharedRight)).map { columnInk[$0] }.max() ?? 0
    let speckFloor = max(2, bandHeight / 12)
    let solidFloor = max(speckFloor + 1, peak * 4 / 5)
    let stemHi = max(speckFloor + 1, peak * 11 / 20)
    let window = max(48, min(spanWidth - 24, max(spanWidth / 2, bandHeight * 5 / 2)))
    guard window + 24 < spanWidth, peak >= speckFloor else { return sharedLeft }
    func stemColumn(_ ink: Int) -> Bool {
        ink >= speckFloor && ink < stemHi
    }
    var bestStart = sharedLeft
    var bestScore = Int.min
    let lastStart = sharedRight - window
    let lead = min(64, max(24, window / 8))
    var start = sharedLeft
    while start <= lastStart {
        var leadStems = 0
        for x in start..<(start + lead) where stemColumn(columnInk[x]) {
            leadStems += 1
        }
        // Crop must open on digit ink, not empty margin or glare.
        if leadStems * 4 < lead {
            start += 1
            continue
        }
        var stems = 0
        var fat = 0
        for x in start..<(start + window) {
            let ink = columnInk[x]
            if ink >= solidFloor {
                fat += 1
            } else if stemColumn(ink) {
                stems += 1
            }
        }
        let score = stems - fat * 3
        if score > bestScore {
            bestScore = score
            bestStart = start
        }
        start += 1
    }
    guard bestStart > sharedLeft + 16, bestScore > 8 else { return sharedLeft }
    var lo = bestStart
    while lo > sharedLeft, stemColumn(columnInk[lo - 1]) {
        lo -= 1
    }
    // Price crops keep a short empty margin before the first stem.
    let margin = min(48, lo - sharedLeft)
    return lo - margin
}

private func priceMatchedLeftByScratchPrefix(
    _ mask: Mask,
    band: (Int, Int),
    sharedLeft: Int,
    sharedRight: Int
) -> Int {
    let width = mask.width
    let y0 = max(0, band.0)
    let y1 = min(mask.height, band.1)
    guard width > 0, y1 > y0, sharedRight > sharedLeft + 24 else { return sharedLeft }
    var columnInk = [Int](repeating: 0, count: width)
    for x in sharedLeft..<min(width, sharedRight) {
        var ink = 0
        for y in y0..<y1 where mask.bits[y * width + x] {
            ink += 1
        }
        columnInk[x] = ink
    }
    // Ignore haze specks: a digit stem covers a real fraction of the band.
    let minCol = max(2, (y1 - y0) / 8)
    let active = (sharedLeft..<min(width, sharedRight)).filter { columnInk[$0] >= minCol }
    guard active.count > 16 else { return sharedLeft }
    let totalInk = active.reduce(0) { $0 + columnInk[$1] }
    var dropped = 0
    var droppedInk = 0
    var index = 0
    let dropLimit = max(12, (y1 - y0) / 10)
    while index < active.count {
        let remaining = active.count - index
        let remainingInk = totalInk - droppedInk
        let gapBefore = index > 0 ? active[index] - active[index - 1] : 0
        // Intra-digit gaps are ≤8px; a left scratch sits farther left.
        if index > 0,
           gapBefore > 8,
           remaining * 5 >= active.count * 4,
           remainingInk * 5 >= totalInk * 4,
           active[index] > sharedLeft + 8,
           dropped * 4 <= remaining,
           dropped <= dropLimit,
           (active[index] - sharedLeft) * 4 <= (sharedRight - active[index]) {
            return active[index]
        }
        dropped += 1
        droppedInk += columnInk[active[index]]
        index += 1
        if dropped > dropLimit { break }
    }
    return sharedLeft
}

/// Ink rows. A gap thinner than a row separation (a punched scanline, a
/// cavity inside one glyph) is closed. Wider gaps stay, so one, two, and
/// three rows each keep their own count.
private func projectionBands(_ sums: [Int], height: Int) -> [(Int, Int)] {
    let peak = sums.max() ?? 0
    guard peak > 0, height > 0 else { return [(0, height)] }
    let floor = max(8, peak / 20)
    let found = runs(sums.map { $0 >= floor ? $0 : 0 })
    guard !found.isEmpty else { return [(0, height)] }
    return merge(found, whenGapBelow: max(6, height / 40))
}

/// Collapse every gap except the one nearest the middle into two bands.
/// One projection row stays one band. A tie keeps the upper gap.
private func pairBands(_ bands: [(Int, Int)], height: Int) -> [(Int, Int)] {
    guard bands.count >= 2 else { return bands }
    let mid = height / 2
    var best = 0
    var bestDistance = Int.max
    for index in 0..<(bands.count - 1) {
        let gapMid = (bands[index].1 + bands[index + 1].0) / 2
        let distance = abs(gapMid - mid)
        if distance < bestDistance {
            bestDistance = distance
            best = index
        }
    }
    return [
        (bands[0].0, bands[best].1),
        (bands[best + 1].0, bands[bands.count - 1].1)
    ]
}

/// Two digit rows joined by scratches. The valley has to sit between two
/// stretches that are each a full row; a cavity inside one digit does not.
private func rowGapBands(_ mask: Mask) -> [(Int, Int)] {
    let width = mask.width
    let height = mask.height
    guard width > 0, height > 40 else { return [(0, height)] }
    let columns = columnSums(mask, y0: 0, y1: height, width: width)
    let ceiling = height * 85 / 100
    let columnFloor = max(8, height / 40)
    var rows = [Int](repeating: 0, count: height)
    var used = 0
    for x in 0..<width where columns[x] >= columnFloor && columns[x] <= ceiling {
        used += 1
        let start = x
        for y in 0..<height where mask.bits[y * width + start] {
            rows[y] += 1
        }
    }
    guard used > width / 10 else { return [(0, height)] }
    let peak = rows.max() ?? 0
    guard peak > 0 else { return [(0, height)] }
    // peak/5 still counts the scratched gap as a digit row. peak/4 clears
    // that gap. A cavity inside one digit fails the side-length test below.
    let cut = max(8, peak / 4)
    let minSide = height / 4
    let minValley = max(6, height / 40)
    // A cavity inside a digit can pass the length test. The gap between two
    // rows is the deepest of those valleys, so only that one splits the crop.
    var bestValley = 0
    var bestEnd = 0
    var bestFloor = Int.max
    var y = 0
    while y < height {
        if rows[y] >= cut {
            y += 1
            continue
        }
        let valley = y
        var floor = rows[y]
        while y < height, rows[y] < cut {
            floor = min(floor, rows[y])
            y += 1
        }
        let above = valley
        let below = height - y
        let length = y - valley
        // A cavity inside the only row of digits is a large fraction of the
        // crop. The gap between two rows is a thin band.
        guard length >= minValley, length * 8 <= height else { continue }
        guard above >= minSide, below >= minSide, floor < bestFloor else { continue }
        // A glare line through one row leaves a short stub. Two rows are
        // about the same height.
        guard min(above, below) * 2 >= max(above, below) else { continue }
        bestFloor = floor
        bestValley = valley
        bestEnd = y
    }
    guard bestFloor < Int.max else { return [(0, height)] }
    return [(0, bestValley), (bestEnd, height)]
}

private func runs(_ sums: [Int]) -> [(Int, Int)] {
    var raw: [(Int, Int)] = []
    var start: Int?
    for (index, sum) in sums.enumerated() {
        if sum > 0 {
            if start == nil { start = index }
        } else if let open = start {
            raw.append((open, index))
            start = nil
        }
    }
    if let open = start {
        raw.append((open, sums.count))
    }
    return raw
}

private func merge(_ bands: [(Int, Int)], whenGapBelow limit: Int) -> [(Int, Int)] {
    guard let first = bands.first else { return [] }
    let split = limit > 0 ? limit : {
        let heights = bands.map { $0.1 - $0.0 }.sorted()
        let medianHeight = heights.isEmpty ? 1 : heights[(heights.count - 1) / 2]
        return max(1, medianHeight / 2)
    }()
    var merged = [first]
    for band in bands.dropFirst() {
        if band.0 - merged[merged.count - 1].1 < split {
            merged[merged.count - 1].1 = band.1
        } else {
            merged.append(band)
        }
    }
    return merged
}

private func polarity(
    isDark: Bool,
    loose: Mask,
    core: Mask,
    forceOpen: Bool = false
) -> (opens: Bool, reading: (isDark: Bool, glyphs: Mask, bandSource: Mask)) {
    let span = digitColumnSpan(core)
    // forceOpen: opposite polarity false-opened on glass (#598). Keep the
    // full core — clearing to the single heaviest column run drops a weaker
    // leading cluster on clean inverted panels (31 of 31.25 → ".25", #660).
    let limitedCore = forceOpen
        ? core
        : (span.map { cleared($0, mask: core) } ?? core)
    let looseTall = runs(loose.rowSums).map { $0.1 - $0.0 }.max() ?? 0
    let limitedTall = runs(limitedCore.rowSums).map { $0.1 - $0.0 }.max() ?? 0
    let fills = looseTall * 100 > loose.height * 70
    // Opened path is for multi-row washed panels where loose fills the gap.
    // A single-row panel's core often shows two mid-glyph bands with a tiny
    // valley; opening on that splits the digit and short rows go empty (#602).
    // Band floor follows typical core run height, not canvas height/8 — on an
    // 820px hand crop that floor was 102px and dropped real digit rows, so
    // open never fired and decode stayed on the loose mask (#602 / #600).
    let coreRuns = runs(limitedCore.rowSums)
    let typicalCore = median(coreRuns.map { $0.1 - $0.0 }.filter { $0 >= 8 }) ?? 0
    let digitFloor = max(8, typicalCore / 2)
    let coreBands = coreRuns.filter { $0.1 - $0.0 >= digitFloor }
    let coreGap = zip(coreBands, coreBands.dropFirst()).map { $1.0 - $0.1 }.max() ?? 0
    let shortestCore = coreBands.map { $0.1 - $0.0 }.min() ?? 0
    // Gap at least a quarter of the shorter digit-tall band (mid-glyph
    // valleys are much smaller). forceOpen still requires this — skipping
    // it opens single-row multi-group panels and digitColumnSpan keeps one
    // group ("2.22" on wideGap five-group) (#602 / #598).
    let minGapVsBand = 4
    let realRowGap = coreBands.count >= 2 && coreGap * minGapVsBand >= shortestCore
    let canOpen = forceOpen
        ? (span != nil && realRowGap)
        : (span != nil && fills && limitedTall * 2 < looseTall && realRowGap)
    guard canOpen else {
        return (false, (isDark, loose, loose))
    }
    // The loose mask still fills the gap inside the span. Row boundaries
    // stay on the thin core so gap specks are not thickened into a join.
    // Glyphs use a few pixels of thickness so the stroke is solid.
    let radius = max(2, core.height / 180)
    let thickCore = dilate(limitedCore, radius: radius)
    let thick: Mask
    if forceOpen {
        thick = thickCore
    } else if let span {
        thick = cleared(span, mask: thickCore)
    } else {
        return (false, (isDark, loose, loose))
    }
    return (true, (isDark, thick, limitedCore))
}

private func digitColumnSpan(_ mask: Mask) -> (Int, Int)? {
    let profile = columnProfile(mask)
    let sums = profile.sums
    // A low floor pulls in bezel columns and the rows become one band.
    // Stroke columns use the high floor. Faint digits to the right of that
    // run are added only while they stay a short stroke.
    let floor = max(12, mask.height / 18)
    let faintFloor = max(8, mask.height / 40)
    let runLimit = max(faintFloor + 1, mask.height / 4)
    let active = sums.indices.filter { index in
        let sum = sums[index]
        return sum >= floor && sum * 2 < mask.height
    }
    guard !active.isEmpty else { return nil }
    let gapLimit = max(8, mask.height / 10)
    var runs: [(start: Int, end: Int, ink: Int)] = []
    var start = active[0]
    var end = active[0]
    var ink = sums[active[0]]
    for index in active.dropFirst() {
        if index - end <= gapLimit {
            end = index
            ink += sums[index]
        } else {
            runs.append((start, end, ink))
            start = index
            end = index
            ink = sums[index]
        }
    }
    runs.append((start, end, ink))
    let wide = runs.filter { run in
        let span = run.end - run.start
        return span > mask.height / 10 && span * 100 < mask.width * 80
    }
    guard let best = wide.max(by: { $0.ink < $1.ink }) else { return nil }
    var extended = best.end
    var gap = 0
    var x = extended + 1
    while x < mask.width && gap <= 40 {
        let sum = sums[x]
        let faint = sum >= faintFloor && sum * 2 < mask.height && profile.longest[x] < runLimit
        if faint {
            extended = x
            gap = 0
        } else {
            gap += 1
        }
        x += 1
    }
    return (best.start, extended + 1)
}

private func dilate(_ mask: Mask, radius: Int) -> Mask {
    guard radius > 0, mask.width > 0, mask.height > 0 else { return mask }
    var bits = [Bool](repeating: false, count: mask.bits.count)
    for y in 0..<mask.height {
        let y0 = max(0, y - radius)
        let y1 = min(mask.height - 1, y + radius)
        for x in 0..<mask.width where mask.bits[y * mask.width + x] {
            let x0 = max(0, x - radius)
            let x1 = min(mask.width - 1, x + radius)
            for ny in y0...y1 {
                let start = ny * mask.width
                for nx in x0...x1 {
                    bits[start + nx] = true
                }
            }
        }
    }
    return Mask(bits: bits, width: mask.width, height: mask.height)
}

private func cleared(_ span: (Int, Int), mask: Mask) -> Mask {
    var bits = mask.bits
    for y in 0..<mask.height {
        let start = y * mask.width
        for x in 0..<span.0 {
            bits[start + x] = false
        }
        for x in span.1..<mask.width {
            bits[start + x] = false
        }
    }
    return Mask(bits: bits, width: mask.width, height: mask.height)
}

private func columnSums(_ mask: Mask, y0: Int, y1: Int, width: Int) -> [Int] {
    var sums = [Int](repeating: 0, count: width)
    let lower = max(0, y0)
    let upper = min(mask.height, y1)
    for y in lower..<upper {
        let start = y * width
        for x in 0..<width where mask.bits[start + x] {
            sums[x] += 1
        }
    }
    return sums
}

private func columnProfile(_ mask: Mask) -> (sums: [Int], longest: [Int]) {
    var sums = [Int](repeating: 0, count: mask.width)
    var longest = [Int](repeating: 0, count: mask.width)
    var current = [Int](repeating: 0, count: mask.width)
    for y in 0..<mask.height {
        let start = y * mask.width
        for x in 0..<mask.width {
            if mask.bits[start + x] {
                current[x] += 1
                sums[x] += 1
                if current[x] > longest[x] { longest[x] = current[x] }
            } else {
                current[x] = 0
            }
        }
    }
    return (sums, longest)
}

/// Digit geometry copied from a known-good price rowcrop.
private struct PreferredDigitPitch {
    var body: Int
    var count: Int
    /// Center-to-center step when known; otherwise body + a small gap.
    var stride: Int
}

/// How many digits fit in `width` at the copied center-to-center step.
private func digitCount(width: Int, stride: Int) -> Int {
    max(1, Int((Double(width) / Double(max(1, stride))).rounded()))
}

private func columnRuns(
    _ mask: Mask,
    y0: Int,
    y1: Int,
    width: Int,
    preferredPitch: PreferredDigitPitch? = nil
) -> [(Int, Int)] {
    let sums = columnSums(mask, y0: y0, y1: y1, width: width)
    let raw = runs(sums)
    let peaks = raw.map { span in (span.0..<span.1).map { sums[$0] }.max() ?? 0 }
    let tallest = peaks.max() ?? 0
    let digitWidths = zip(raw, peaks).compactMap { span, peak -> Int? in
        guard tallest > 0, peak * 2 >= tallest else { return nil }
        return span.1 - span.0
    }.sorted()
    let typical = digitWidths.isEmpty ? 0 : digitWidths[(digitWidths.count - 1) / 2]
    let bandHeight = max(1, y1 - y0)
    // Approach D: a preferred pitch copied from a known-good price row forces
    // digit-sized cuts. Without it, keep the existing valley path so clean
    // synthetics do not over-split.
    let copied = preferredPitch.map {
        PreferredDigitPitch(
            body: max(1, $0.body),
            count: max(2, $0.count),
            stride: max(max(1, $0.body), $0.stride)
        )
    }
    // When pitch-driving: cluster wide runs that are wash-bridged (gap under
    // body/10). Each cluster's digit count is its width over the copied
    // stride, not the price row's count, so a five-digit volume beside a
    // four-digit price stays five (#599). Anchor one window per raw run when
    // possible — only pitch-split a run that must hold more than one digit.
    // That keeps the photo's 380-555 0-run on its own ink instead of a
    // drifted body window. Without preferred pitch, valley.
    if let pitch = copied {
        let wideEnough = raw.filter { $0.1 - $0.0 > pitch.body / 2 }
        let bridgeLimit = max(2, pitch.body / 10)
        var clusters: [[(Int, Int)]] = []
        for run in wideEnough {
            if var last = clusters.last, let prev = last.last,
               run.0 - prev.1 >= 0, run.0 - prev.1 < bridgeLimit {
                last.append(run)
                clusters[clusters.count - 1] = last
            } else {
                clusters.append([run])
            }
        }
        if !clusters.isEmpty {
            var pieces: [(Int, Int)] = []
            for cluster in clusters {
                guard let first = cluster.first, let last = cluster.last else { continue }
                let clusterWidth = last.1 - first.0
                let share = digitCount(width: clusterWidth, stride: pitch.stride)
                pieces.append(contentsOf: packClusterRuns(cluster, share: share, sums: sums, pitch: pitch))
            }
            if let overallFirst = wideEnough.first, let overallLast = wideEnough.last {
                // A leading 1 (one stem) and its decimal sit left of the
                // first wide run; keep narrow runs up to two strides outside.
                let reach = pitch.stride * 2
                let extras = raw.filter { span in
                    if span.1 - span.0 > pitch.body / 2 { return false }
                    return span.0 >= overallFirst.0 - reach && span.1 <= overallLast.1
                        && !pieces.contains { span.0 >= $0.0 && span.1 <= $0.1 }
                }
                pieces.append(contentsOf: extras)
            }
            pieces.sort { $0.0 < $1.0 }
            if width >= 400 {
                let listed = raw.map { "\($0.0)-\($0.1)" }.joined(separator: ",")
                let packed = pieces.map { "\($0.0)-\($0.1)" }.joined(separator: ",")
                trace("pitch pack raw[\(listed)] → [\(packed)] body\(pitch.body)x\(pitch.count)\n")
            }
            return pieces
        }
    }
    let spans = raw
    return spans.flatMap { span in
        let spanWidth = span.1 - span.0
        // A digit is taller than it is wide. A 4 has no top or bottom bar, so
        // its ink band is shorter than the cell, and the old 0.7 ratio split
        // that one glyph at the crossbar. Two digits side by side are wider
        // than the band is tall — or wider than a copied price-row pitch.
        let widerThanADigit = spanWidth > bandHeight
        let widerThanCopied = copied.map { spanWidth > $0.body + $0.body / 4 } ?? false
        guard widerThanADigit || widerThanCopied || (typical > 0 && spanWidth > typical * 2) else {
            return [span]
        }
        if let pitch = copied {
            // Stride owns the split. The price row's digit count would pack a
            // longer washed row into too few windows (#599).
            let sized = PreferredDigitPitch(
                body: pitch.body,
                count: digitCount(width: spanWidth, stride: pitch.stride),
                stride: pitch.stride
            )
            return splitAtExpectedPitch(span, sums: sums, pitch: sized)
        }
        let peak = (span.0..<span.1).map { sums[$0] }.max() ?? 0
        // A horizontal bar is much thinner than a flooded stem. peak/5 cut the
        // bar and split one washed digit. The gap between digits still falls
        // through a lower floor; valleys catch a wash bridge above that floor.
        let floor = max(1, widerThanADigit ? peak / 15 : peak / 8)
        var pieces: [(Int, Int)] = []
        var start: Int?
        for x in span.0..<span.1 {
            if sums[x] >= floor {
                if start == nil { start = x }
            } else if let open = start {
                pieces.append((open, x))
                start = nil
            }
        }
        if let open = start {
            pieces.append((open, span.1))
        }
        let split = pieces.isEmpty ? [span] : pieces
        let joined = joiningBridgedPieces(split, mask: mask, y0: y0, y1: y1, bandHeight: bandHeight)
        return joined.flatMap { piece in
            splitAtDigitValleys(piece, sums: sums, bandHeight: bandHeight)
        }
    }
}

/// Assign `share` digit windows across the wide runs of one wash cluster.
/// Prefer one window per raw run (keeps single-digit ink bounds). Extra
/// slots go to the widest runs via right-pack splits.
private func packClusterRuns(
    _ runs: [(Int, Int)],
    share: Int,
    sums: [Int],
    pitch: PreferredDigitPitch
) -> [(Int, Int)] {
    guard !runs.isEmpty else { return [] }
    let body = max(1, pitch.body)
    let want = max(1, share)
    if want <= runs.count {
        // Too many runs for the share: keep the rightmost `want` (leading junk first).
        return Array(runs.suffix(want))
    }
    var runShare = Array(repeating: 1, count: runs.count)
    var extra = want - runs.count
    let widestFirst = runs.enumerated()
        .map { (index: $0.offset, width: $0.element.1 - $0.element.0) }
        .sorted { $0.width > $1.width }
    var cursor = 0
    while extra > 0, !widestFirst.isEmpty {
        runShare[widestFirst[cursor % widestFirst.count].index] += 1
        extra -= 1
        cursor += 1
    }
    // Prefer a pack body from single-digit runs in this cluster when they
    // are narrower than the copied price body — volume glyphs on the photo
    // sit under the price width and left-pack with 182 overshoots into wash.
    let singleWidths = runs.map { $0.1 - $0.0 }.filter {
        $0 > body / 2 && $0 <= body + body / 4
    }.sorted()
    let packBody: Int
    if singleWidths.isEmpty {
        packBody = body
    } else {
        packBody = singleWidths[(singleWidths.count - 1) / 2]
    }
    var pieces: [(Int, Int)] = []
    for (run, n) in zip(runs, runShare) {
        if n <= 1 {
            // Left-inset single-digit runs: wash bridges light false `f` on
            // the left stem scan and clip `c` on the right (pat 123 → 2/8 tie).
            let width = run.1 - run.0
            let lead = max(0, min(width / 8, max(2, packBody / 12)))
            let core = min(width - lead, packBody)
            let start = run.0 + lead
            pieces.append((start, min(run.1, start + max(2, core))))
        } else {
            // Peel leading wash only when the left edge is flat. A digit already
            // at run.0 (solid-gap synth fuse) must not lose its left stem.
            let needed = n * packBody
            func edgeStem(at x: Int) -> Int {
                let end = min(run.1, x + packBody)
                guard end - x >= max(2, packBody / 5) else { return -1 }
                let third = max(1, (end - x) / 3)
                let left = (x..<x + third).map { sums[$0] }.max() ?? 0
                let mid = (x + third..<x + 2 * third).map { sums[$0] }.max() ?? 0
                let right = (x + 2 * third..<end).map { sums[$0] }.max() ?? 0
                return left + right - mid / 2
            }
            let leftStem = edgeStem(at: run.0)
            let rightStem = edgeStem(at: max(run.0, run.1 - packBody))
            // Synth panel bodies are ~50px; photo pitch bodies are ~180px.
            // Stem peaks on photo volume turned leading 8 → 0 (0.022).
            let fusedSynth = leftStem >= 0
                && leftStem * 2 >= max(0, rightStem)
                && packBody <= 80
                && run.1 - run.0 >= needed
                && run.1 - run.0 <= needed + packBody
            // More windows than the price count means the extra width is
            // another digit. Right-packing that off drops the leading glyph
            // (28022 → 8022) (#599).
            let keepLeft = fusedSynth || n > pitch.count
            let trimmed: (Int, Int) = keepLeft
                ? run
                : (max(run.0, run.1 - needed), run.1)
            let local = PreferredDigitPitch(body: packBody, count: n, stride: pitch.stride)
            pieces.append(
                contentsOf: splitAtExpectedPitch(
                    trimmed,
                    sums: sums,
                    pitch: local,
                    preferStemPeaks: fusedSynth
                )
            )
        }
    }
    return pieces
}

/// Place `count` body-wide windows across a fused span. Pack from the right:
/// pump volume/price digits sit on the right of washed leading junk, and a
/// digit-hollow "decimal" column is not trustworthy for left/right splits.
/// Baseline dots still own the mark.
private func splitAtExpectedPitch(
    _ span: (Int, Int),
    sums: [Int],
    pitch: PreferredDigitPitch,
    preferStemPeaks: Bool = false
) -> [(Int, Int)] {
    let body = max(1, pitch.body)
    let count = max(2, pitch.count)
    let width = span.1 - span.0
    guard width > body + body / 4 else { return [span] }
    let inset = max(1, body / 12)
    func window(at x: Int) -> (Int, Int)? {
        let start = max(span.0, x + inset)
        let end = min(span.1, x + body - inset)
        guard end - start >= max(2, body / 5) else { return nil }
        return (start, end)
    }
    /// Left+right third peaks (stems) minus a flat mid — wash is flat; digits
    /// keep stem energy even when the gap is filled.
    func stemScore(from x: Int) -> Int {
        let end = min(span.1, x + body)
        guard end - x >= max(2, body / 5) else { return -1 }
        let third = max(1, (end - x) / 3)
        let left = (x..<x + third).map { sums[$0] }.max() ?? 0
        let mid = (x + third..<x + 2 * third).map { sums[$0] }.max() ?? 0
        let right = (x + 2 * third..<end).map { sums[$0] }.max() ?? 0
        return left + right - mid / 2
    }
    // Prefer a tight body step over price center-spacing: wash fills the
    // inter-digit gaps, so the copied stride overshoots the fused field.
    let needed = count * body
    let gap: Int
    if width >= needed, count > 1 {
        gap = (width - needed) / (count - 1)
    } else {
        gap = 0
    }
    let step = body + max(0, gap)
    // Solid-gap synthetics: left→right stem peaks. Photo keeps right-pack.
    if preferStemPeaks {
        let sample = max(1, body / 8)
        let minSep = body
        var peakStarts: [Int] = []
        var searchFrom = span.0
        var peaksOk = true
        for remaining in stride(from: count, through: 1, by: -1) {
            let latest = span.1 - body - (remaining - 1) * minSep
            guard latest >= searchFrom else { peaksOk = false; break }
            var bestX = searchFrom
            var bestScore = Int.min
            var x = searchFrom
            while x <= latest {
                let score = stemScore(from: x)
                if score > bestScore {
                    bestScore = score
                    bestX = x
                }
                x += sample
            }
            guard bestScore > 0 else { peaksOk = false; break }
            if remaining == count, bestX <= span.0 + body / 4 {
                bestX = span.0
            }
            peakStarts.append(bestX)
            searchFrom = bestX + minSep
        }
        if peaksOk, peakStarts.count == count {
            let pieces = peakStarts.compactMap { window(at: $0) }
            if width >= 400 {
                let listed = pieces.map { "\($0.0)-\($0.1)" }.joined(separator: ",")
                let scores = peakStarts.map { stemScore(from: $0) }
                trace("pitch peaks step~\(step) [\(listed)] stem\(scores)\n")
            }
            if pieces.count >= 2 { return pieces }
        }
    }
    // Right-pack: last window ends at span.1, earlier ones step left. Leading
    // wash/junk left of the pack is ignored instead of shifting every slot.
    var starts: [Int] = []
    var x = span.1 - body
    for _ in 0..<count {
        starts.append(max(span.0, x))
        x -= step
    }
    let ordered = starts.sorted()
    let pieces = ordered.compactMap { window(at: $0) }
    if width >= 400 {
        let listed = pieces.map { "\($0.0)-\($0.1)" }.joined(separator: ",")
        let scores = ordered.map { stemScore(from: $0) }
        trace("pitch right step\(step) [\(listed)] stem\(scores)\n")
    }
    return pieces.count >= 2 ? pieces : (pieces.isEmpty ? [span] : pieces)
}

/// Cut a span that still holds two digit peaks with a wash bridge between them.
private func splitAtDigitValleys(
    _ span: (Int, Int),
    sums: [Int],
    bandHeight: Int
) -> [(Int, Int)] {
    let digitWide = max(1, bandHeight / 2)
    let width = span.1 - span.0
    guard width > digitWide + digitWide / 3 else { return [span] }
    var cuts: [Int] = []
    var x = span.0 + digitWide / 2
    while x < span.1 - digitWide / 2 {
        let leftPeak = (span.0..<x).map { sums[$0] }.max() ?? 0
        let rightPeak = (x..<span.1).map { sums[$0] }.max() ?? 0
        let valley = sums[x]
        let deep = leftPeak > 0
            && rightPeak > 0
            && valley * 3 < leftPeak
            && valley * 3 < rightPeak
        if deep {
            cuts.append(x)
            x += digitWide * 2 / 3
        } else {
            x += 1
        }
    }
    guard !cuts.isEmpty else { return [span] }
    var pieces: [(Int, Int)] = []
    var start = span.0
    for cut in cuts {
        if cut > start { pieces.append((start, cut)) }
        start = cut
    }
    if span.1 > start { pieces.append((start, span.1)) }
    let kept = pieces.filter { $0.1 - $0.0 >= max(2, digitWide / 5) }
    return kept.isEmpty ? [span] : kept
}

/// A projection floor cuts the diagonal of a 2. The halves are still one stroke.
private func joiningBridgedPieces(
    _ pieces: [(Int, Int)],
    mask: Mask,
    y0: Int,
    y1: Int,
    bandHeight: Int
) -> [(Int, Int)] {
    guard var previous = pieces.first else { return [] }
    var merged: [(Int, Int)] = []
    // Both halves have to be narrower than a finished digit. The reflection
    // beside the 3 is as wide as a digit and must not be pulled in with it.
    // Two washed digits cut apart by the floor are each already ~digit-wide;
    // do not glue those back even when a thin bridge still connects them.
    let narrow = bandHeight / 2
    let digitWide = max(1, bandHeight / 2)
    let gapLimit = max(1, bandHeight / 8)
    for piece in pieces.dropFirst() {
        let gap = piece.0 - previous.1
        let leftWidth = previous.1 - previous.0
        let rightWidth = piece.1 - piece.0
        let combined = piece.1 - previous.0
        let bothFinished = leftWidth * 5 >= digitWide * 3 && rightWidth * 5 >= digitWide * 3
        let bridged = !bothFinished
            && leftWidth < narrow
            && rightWidth < narrow
            && combined < bandHeight
            && gap > 0
            && gap < gapLimit
            && strokeConnects(previous, piece, mask: mask, y0: y0, y1: y1)
        if bridged {
            previous.1 = piece.1
        } else {
            merged.append(previous)
            previous = piece
        }
    }
    merged.append(previous)
    return merged
}

private func strokeConnects(
    _ left: (Int, Int),
    _ right: (Int, Int),
    mask: Mask,
    y0: Int,
    y1: Int
) -> Bool {
    let width = mask.width
    let lower = max(0, y0)
    let upper = min(mask.height, y1)
    let xStart = max(0, left.0)
    let xEnd = min(width, right.1)
    guard xEnd > xStart, upper > lower else { return false }
    let span = xEnd - xStart
    var seen = [Bool](repeating: false, count: span * (upper - lower))
    func slot(_ x: Int, _ y: Int) -> Int { (y - lower) * span + (x - xStart) }
    var queue: [(Int, Int)] = []
    for y in lower..<upper {
        let row = y * width
        for x in max(xStart, left.0)..<min(xEnd, left.1) where mask.bits[row + x] {
            seen[slot(x, y)] = true
            queue.append((x, y))
        }
    }
    var head = 0
    while head < queue.count {
        let (x, y) = queue[head]
        head += 1
        if x >= right.0 && x < right.1 { return true }
        for ny in max(lower, y - 1)...min(upper - 1, y + 1) {
            for nx in max(xStart, x - 1)...min(xEnd - 1, x + 1) {
                let index = slot(nx, ny)
                if seen[index] || !mask.bits[ny * width + nx] { continue }
                seen[index] = true
                queue.append((nx, ny))
            }
        }
    }
    return false
}

private func tightBox(_ mask: Mask, x0: Int, x1: Int, y0: Int, y1: Int, width: Int) -> PixelBox {
    var minY = y1
    var maxY = y0
    let lower = max(0, y0)
    let upper = min(mask.height, y1)
    let left = max(0, x0)
    let right = min(width, x1)
    var counts = [Int](repeating: 0, count: max(0, upper - lower))
    for y in lower..<upper {
        let start = y * width
        var count = 0
        for x in left..<right where mask.bits[start + x] {
            count += 1
        }
        counts[y - lower] = count
    }
    let peak = counts.max() ?? 0
    // A reflection above the digit is a few pixels. It used to stretch the
    // box to the whole crop, and the segment windows then missed the glyph.
    let floor = max(1, peak / 5)
    for (offset, count) in counts.enumerated() where count >= floor {
        let y = lower + offset
        minY = min(minY, y)
        maxY = max(maxY, y + 1)
    }
    if minY >= maxY {
        return PixelBox(minX: left, minY: lower, maxX: right, maxY: upper)
    }
    return PixelBox(minX: left, minY: minY, maxX: right, maxY: maxY)
}

/// Row sums inside a column span. Used to pick the digit ink band.
private func rowInkSums(_ mask: Mask, x0: Int, x1: Int, y0: Int, y1: Int) -> (lower: Int, sums: [Int]) {
    let width = mask.width
    let lower = max(0, y0)
    let upper = min(mask.height, y1)
    let left = max(0, x0)
    let right = min(width, x1)
    guard upper > lower, right > left else { return (lower, []) }
    var sums = [Int](repeating: 0, count: upper - lower)
    for y in lower..<upper {
        let start = y * width
        var count = 0
        for x in left..<right where mask.bits[start + x] {
            count += 1
        }
        sums[y - lower] = count
    }
    return (lower, sums)
}

/// Vertical span of digit ink for segment sampling. Glare above the top bar
/// makes a box taller than a real digit (~2× width). Drop a short solid cap,
/// then keep the lower digit-tall slice. Boxes that already fit a digit are
/// left alone — shrinking them clips the top bar. A stem fills its narrow box
/// and is never treated as a glare cap.
///
/// `forceDigitTall`: pitch-driven volume boxes are often under 2× width yet
/// still carry wash above the glyph; still snap to the top bar / lower slice
/// so upper stem scans are not in the fringe.
private func densestInkBand(
    _ mask: Mask,
    box: PixelBox,
    width: Int,
    digitWidth: Int,
    forceDigitTall: Bool = false
) -> PixelBox {
    let profile = rowInkSums(mask, x0: box.minX, x1: box.maxX, y0: box.minY, y1: box.maxY)
    let sums = profile.sums
    let height = sums.count
    // Return the caller box on early exits (pre-#597). Replacing it with the
    // profile span broke washed bezel crops (#596). Bad-ROI Range safety is
    // foregroundCount's empty-scan guards, not rewriting these returns.
    guard height > 2 else { return box }
    // A one is a tall stem. Leave it alone; aspect math is for wide glyphs.
    if box.width * 4 < height {
        return box
    }
    // Cap by this box's width. A broken 3 can tighten narrowly; then the
    // median digit width decides whether it is still a normal-height glyph.
    let ownCap = max(8, box.width * 2)
    let narrow = digitWidth > 8 && box.width * 5 < digitWidth * 4
    let earlyCap = narrow ? max(ownCap, digitWidth * 2) : ownCap
    let slack = max(4, earlyCap / 12)
    // Price-like boxes are left alone. Snapping every wide glyph to a "top
    // bar" misreads the mid-row glare fixture as a colon. Pitch volume rows
    // opt in via forceDigitTall even when already under the aspect cap.
    if !forceDigitTall, height <= earlyCap + slack {
        return box
    }
    var start = 0
    var end = height
    // A top bar spans the interior, not the full cell. A glare cap fills it.
    let solid = max(2, box.width * 9 / 10)
    // A pitch row's real a/d bars span ~90% of the glyph box too. Peeling
    // them as "glare caps" turned row-two 5/6/7 into 4/4/1. Only the
    // price-like path (aspect-capped above) peels caps.
    while !forceDigitTall && start < height - 3 && sums[start] >= solid {
        start += 1
    }
    // A stem fills the box. A glare cap is a minority of the height.
    if start * 2 > height { start = 0 }
    while !forceDigitTall && end - start > 3 && sums[end - 1] >= solid {
        end -= 1
    }
    if (height - end) * 2 > height { end = height }
    // Washed glare above the top bar may not be solid. Snap to the strongest
    // center bar in the upper half so upper stem scans start on the glyph.
    let topBar = topBarRow(
        mask,
        box: box,
        width: width,
        from: start,
        to: min(end, start + max(1, (end - start) * 2 / 5))
    )
    if let topBar, topBar > start {
        start = max(start, topBar - max(1, box.width / 20))
    }
    var minY = profile.lower + start
    var maxY = profile.lower + end
    let remaining = maxY - minY
    if remaining <= ownCap + max(4, ownCap / 12) {
        return PixelBox(minX: box.minX, minY: minY, maxX: box.maxX, maxY: maxY)
    }
    let target = min(remaining, ownCap)
    // Pitch volume: keep the top-bar start and take a digit-tall window
    // downward. The old lower-slice path discarded the top bar we just
    // snapped to and could mint a false 2 (clipped c / wrong stem lines).
    if forceDigitTall {
        maxY = minY + target
    } else {
        minY = maxY - target
    }
    return PixelBox(minX: box.minX, minY: minY, maxX: box.maxX, maxY: maxY)
}

/// Row of the strongest center-span bar in [from, to). Glare that fills the
/// cell scores lower than a seven-segment top bar.
private func topBarRow(
    _ mask: Mask,
    box: PixelBox,
    width: Int,
    from: Int,
    to: Int
) -> Int? {
    let lower = max(0, box.minY)
    let left = max(0, box.minX)
    let right = min(width, box.maxX)
    let span = right - left
    guard span > 4, to > from else { return nil }
    let mid0 = left + span / 4
    let mid1 = right - span / 4
    var bestRow: Int?
    var bestScore = Int.min
    for offset in from..<to {
        let y = lower + offset
        guard y >= box.minY, y < box.maxY, y < mask.height else { continue }
        let row = y * width
        var center = 0
        var edge = 0
        for x in left..<mid0 where mask.bits[row + x] { edge += 1 }
        for x in mid0..<mid1 where mask.bits[row + x] { center += 1 }
        for x in mid1..<right where mask.bits[row + x] { edge += 1 }
        // A top bar lights the middle; a glare smear lights the edges too.
        let score = center * 2 - edge
        if score > bestScore {
            bestScore = score
            bestRow = offset
        }
    }
    guard bestScore > 0, let bestRow else { return nil }
    return bestRow
}

private func verticalRuns(_ mask: Mask, box: PixelBox, width: Int) -> [(Int, Int)] {
    var sums = [Int](repeating: 0, count: max(0, box.maxY - box.minY))
    for y in box.minY..<box.maxY {
        guard y >= 0, y < mask.height else { continue }
        var count = 0
        let start = y * width
        for x in max(0, box.minX)..<min(width, box.maxX) where mask.bits[start + x] {
            count += 1
        }
        sums[y - box.minY] = count
    }
    return runs(sums).map { ($0.0 + box.minY, $0.1 + box.minY) }
}

private let inkMargin = 14
/// A pale bar sits only a few counts under the wide average. The glare beside it does not.
private let paleBarMargin = 8
/// Same bound as `extremeMarkMask`: a painted gap line, not panel glass.
private let extremeHighlight: UInt8 = 252
private let solidCoverage: Float = 0.80

private func markIsInk(_ mask: Mask, box: PixelBox, width: Int, buffer: GrayBuffer, darkInk: Bool) -> Bool {
    coverage(mask, box: box, width: width) > 0.5 || inkFraction(buffer, box: box, darkInk: darkInk) > 0.5
}

private func inkFraction(_ buffer: GrayBuffer, box: PixelBox, darkInk: Bool) -> Float {
    var ink = 0
    var total = 0
    let left = max(0, box.minX)
    let right = min(buffer.width, box.maxX)
    let lower = max(0, box.minY)
    let upper = min(buffer.height, box.maxY)
    guard right > left, upper > lower else { return 0 }
    let surround = surroundingLevel(buffer, box: box)
    for y in lower..<upper {
        let start = y * buffer.width
        for x in left..<right {
            total += 1
            let pixel = Int(buffer.pixels[start + x])
            let countsAsInk = darkInk
                ? pixel + inkMargin < surround
                : pixel > surround + inkMargin
            if countsAsInk {
                ink += 1
            }
        }
    }
    return total == 0 ? 0 : Float(ink) / Float(total)
}

private func surroundingLevel(_ buffer: GrayBuffer, box: PixelBox) -> Int {
    var samples: [Int] = []
    func add(_ x: Int, _ y: Int) {
        guard x >= 0, y >= 0, x < buffer.width, y < buffer.height else { return }
        samples.append(Int(buffer.pixels[y * buffer.width + x]))
    }
    let left = box.minX - 1
    let right = box.maxX
    // Inverted / empty boxes must not trap `left...right` (#597).
    if left <= right {
        if box.minY - 1 >= 0 {
            for x in left...right { add(x, box.minY - 1) }
        }
        if box.maxY < buffer.height {
            for x in left...right { add(x, box.maxY) }
        }
    }
    if box.minY < box.maxY {
        for y in box.minY..<box.maxY {
            add(left, y)
            add(right, y)
        }
    }
    guard !samples.isEmpty else { return Int(buffer.cornerFill()) }
    return samples.sorted()[samples.count / 2]
}

private func coverage(_ mask: Mask, box: PixelBox, width: Int) -> Float {
    var ink = 0
    var total = 0
    let left = max(0, box.minX)
    let right = min(width, box.maxX)
    let lower = max(0, box.minY)
    let upper = min(mask.height, box.maxY)
    guard right > left, upper > lower else { return 0 }
    for y in lower..<upper {
        let start = y * width
        for x in left..<right {
            total += 1
            if mask.bits[start + x] { ink += 1 }
        }
    }
    return total == 0 ? 0 : Float(ink) / Float(total)
}

private func segmentIsLit(
    _ mask: Mask,
    x: Int,
    y: Int,
    length: Int,
    vertical: Bool,
    sampleBand: Int = 0
) -> Bool {
    let run = longestForegroundRun(
        mask, x: x, y: y, length: length, vertical: vertical, sampleBand: sampleBand
    )
    return run >= 2
}

/// Longest consecutive run on the scanline. With `sampleBand`, the longest
/// on any parallel line up to that many pixels either side, so a stroke
/// broken on the scanline itself still counts.
private func longestForegroundRun(
    _ mask: Mask,
    x: Int,
    y: Int,
    length: Int,
    vertical: Bool,
    sampleBand: Int = 0
) -> Int {
    if sampleBand > 0 {
        return (-sampleBand...sampleBand).map { offset in
            longestForegroundRun(
                mask,
                x: vertical ? x + offset : x,
                y: vertical ? y : y + offset,
                length: length,
                vertical: vertical
            )
        }.max() ?? 0
    }
    guard length > 0 else { return 0 }
    var best = 0
    var current = 0
    func consider(_ set: Bool) {
        if set {
            current += 1
            if current > best { best = current }
        } else {
            current = 0
        }
    }
    if vertical {
        guard x >= 0, x < mask.width else { return 0 }
        let start = max(0, y)
        let end = min(mask.height, y + length)
        guard start < end else { return 0 }
        for row in start..<end {
            consider(mask.bits[row * mask.width + x])
        }
    } else {
        guard y >= 0, y < mask.height else { return 0 }
        let start = max(0, x)
        let end = min(mask.width, x + length)
        guard start < end else { return 0 }
        let offset = y * mask.width
        for column in start..<end {
            consider(mask.bits[offset + column])
        }
    }
    return best
}

private func foregroundCount(
    _ mask: Mask,
    x: Int,
    y: Int,
    length: Int,
    vertical: Bool,
    sampleBand: Int = 0
) -> Int {
    if sampleBand > 0 {
        var count = 0
        if vertical {
            for dx in -sampleBand...sampleBand {
                count += foregroundCount(
                    mask,
                    x: x + dx,
                    y: y,
                    length: length,
                    vertical: true
                )
            }
        } else {
            for dy in -sampleBand...sampleBand {
                count += foregroundCount(
                    mask,
                    x: x,
                    y: y + dy,
                    length: length,
                    vertical: false
                )
            }
        }
        return count
    }
    guard length > 0 else { return 0 }
    var count = 0
    if vertical {
        guard x >= 0, x < mask.width else { return 0 }
        let start = max(0, y)
        let end = min(mask.height, y + length)
        // Bad / mismatched ROI can build a sample box past the mask
        // (frameTop + digitHeight). An empty scan is fine; trapping
        // `start..<end` with start > end is not (#597).
        guard start < end else { return 0 }
        for row in start..<end where mask.bits[row * mask.width + x] {
            count += 1
        }
    } else {
        guard y >= 0, y < mask.height else { return 0 }
        let start = max(0, x)
        let end = min(mask.width, x + length)
        guard start < end else { return 0 }
        let offset = y * mask.width
        for column in start..<end where mask.bits[offset + column] {
            count += 1
        }
    }
    return count
}

private func overlap(_ lhs: PixelBox, _ rhs: PixelBox) -> Int {
    let width = min(lhs.maxX, rhs.maxX) - max(lhs.minX, rhs.minX)
    let height = min(lhs.maxY, rhs.maxY) - max(lhs.minY, rhs.minY)
    guard width > 0, height > 0 else { return 0 }
    return width * height
}

private func median(_ values: [Int]) -> Int? {
    guard !values.isEmpty else { return nil }
    return values.sorted()[values.count / 2]
}

private func prefersDark(_ dark: Mask, _ light: Mask) -> Bool {
    // A halo is one fat run, so a two-to-one lead still wins. The glass split
    // by the strokes can have a few more runs than the strokes. When the
    // counts are that close, the thinner mask is the ink.
    let darkRuns = bandedColumnRuns(dark)
    let lightRuns = bandedColumnRuns(light)
    if darkRuns >= lightRuns * 2 { return true }
    if lightRuns >= darkRuns * 2 { return false }
    let darkInk = dark.rowSums.reduce(Int64(0)) { $0 + Int64($1) }
    let lightInk = light.rowSums.reduce(Int64(0)) { $0 + Int64($1) }
    return darkInk <= lightInk
}

private func bandedColumnRuns(_ mask: Mask) -> Int {
    runs(mask.rowSums).reduce(0) { total, band in
        let sums = columnSums(mask, y0: band.0, y1: band.1, width: mask.width)
        return total + runs(sums).count
    }
}

// MARK: - Lattice reader (photographed panels)
//
// Scale-relative reader for photographed seven-segment panels.
//
// Every size is measured from the panel itself: the analysis height, the
// stroke thickness of the segments, the digit height of each row and the
// digit pitch. Nothing is a fixed pixel count of the photo. Steps:
// 1. Fit the crop to a fixed analysis height.
// 2. Ink = relative black top-hat (dark features about a stroke wide).
//    Broad reflections and shadows are wider than the window; scratches and
//    reflection edges are thinner than a stroke and are dropped by shape.
// 3. Keep stroke-drawn pieces: inscribed thickness near the panel's stroke.
// 4. Undo rotation (from horizontal bars) and italic shear (from stems).
// 5. Rows: heights covered by several separate pieces at once.
// 6. Digits: a lattice fitted to the right edges of the tall pieces. Each
//    lattice cell is read by the ink share in each segment zone.
// 7. Decimal: baseline ink in the gap between two cells, empty above.


struct SevenSegmentLatticeReader {
    struct Cell {
        var character: Character
        var confidence: Float
        /// Bounds in source pixel coordinates (top-left origin).
        var minX: Double
        var minY: Double
        var maxX: Double
        var maxY: Double
    }

    /// Rows top to bottom, cells left to right. Empty when nothing reads.
    static func read(pixels: [UInt8], width: Int, height: Int, darkInk: Bool = true) -> [[Cell]] {
        guard width > 8, height > 8, pixels.count == width * height else { return [] }
        var reader = Reader(pixels: pixels, width: width, height: height, darkInk: darkInk)
        return reader.run()
    }

    /// True when every row has at least two digits and every digit matched a
    /// template exactly.
    static func isConfident(_ rows: [[Cell]]) -> Bool {
        !rows.isEmpty && rows.allSatisfy(isConfident(row:))
    }

    /// Two or more digits, every one read exactly, and no unknown cell.
    static func isConfident(row: [Cell]) -> Bool {
        let digits = row.filter { $0.character.isNumber }
        if digits.count < 2 { return false }
        if row.contains(where: { $0.character == "_" }) { return false }
        return !digits.contains(where: { $0.confidence < 1 })
    }
}

// MARK: - Implementation

private let analysisHeight = 360
private let topHatFractions: [Double] = [0.08, 0.12, 0.18]
private let thickMaximum = 1.8
private let rowCoverFraction = 0.3
private let bridgeStrokes = 0.3
private let holeMaximum = 0.5
private let snapFraction = 0.15
private let decimalAbove = 0.1

private struct BitMask {
    var bits: [Bool]
    var width: Int
    var height: Int

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        bits = [Bool](repeating: false, count: width * height)
    }

    subscript(x: Int, y: Int) -> Bool {
        get { bits[y * width + x] }
        set { bits[y * width + x] = newValue }
    }

    var inkFraction: Double {
        guard !bits.isEmpty else { return 0 }
        return Double(bits.lazy.filter { $0 }.count) / Double(bits.count)
    }
}

private struct Component {
    var label: Int
    var minX: Int
    var minY: Int
    var maxX: Int   // exclusive
    var maxY: Int   // exclusive
    var area: Int
    var width: Int { maxX - minX }
    var height: Int { maxY - minY }
}

private struct Reader {
    let pixels: [UInt8]
    let width: Int
    let height: Int
    let darkInk: Bool

    // Analysis-space transform, for mapping cells back to the source.
    private var scale = 1.0
    private var smallWidth = 0
    private var rotationDegrees = 0.0
    private var rotatedWidth = 0
    private var rotatedHeight = 0
    private var shearTangent = 0.0
    private var shearPad = 0

    init(pixels: [UInt8], width: Int, height: Int, darkInk: Bool) {
        self.pixels = pixels
        self.width = width
        self.height = height
        self.darkInk = darkInk
    }

    mutating func run() -> [[SevenSegmentLatticeReader.Cell]] {
        let h = analysisHeight
        scale = Double(h) / Double(height)
        smallWidth = max(1, Int((Double(width) * scale).rounded()))
        let small = boxResize(pixels, width: width, height: height, toWidth: smallWidth, toHeight: h)
        let smoothed = median3(small, width: smallWidth, height: h)

        // Each window size gives a candidate mask. The candidate whose read
        // ranks best wins (sure-row information, then all information), and
        // how segment-like its ink looks only breaks a tie: a mask can look
        // like strokes and still read worse.
        var candidates: [(mask: BitMask, stroke: Double, plain: Int, score: Int)] = []
        for fraction in topHatFractions {
            let contrast = topHat(smoothed, width: smallWidth, height: h, window: Int(Double(h) * fraction))
            let selected = contrast.filter { $0 > 0.03 }
            let cut = selected.count > 200 ? otsu(selected) : 0.2
            var raw = BitMask(width: smallWidth, height: h)
            let level = max(0.6 * cut, 0.07)
            for index in contrast.indices where contrast[index] > level {
                raw.bits[index] = true
            }
            let (kept, stroke) = clean(raw)
            guard stroke > 0 else { continue }
            candidates.append((kept, stroke, 1, segmentScore(kept, stroke: stroke)))
            // Glare washes part of a stroke below the cut while the rest of
            // it stays strong. Hysteresis keeps weak ink (half the cut, the
            // usual 2:1 ratio) only where it joins strong ink. It can also
            // grow into the faint unlit segments of a dark panel, so a
            // grown mask wins only when it reads strictly better.
            let grown = hysteresis(contrast, strong: raw, weak: level / 2)
            if grown.bits != raw.bits {
                let (regrown, restroke) = clean(grown)
                if restroke > 0 {
                    candidates.append((regrown, restroke, 0, segmentScore(regrown, stroke: restroke)))
                }
            }
        }
        var best: (key: (Int, Int, Int, Int), rows: [[SevenSegmentLatticeReader.Cell]])?
        for candidate in candidates {
            let rows = readRows(candidate.mask, stroke: candidate.stroke)
            let rank = SevenSegmentLatticeReader.rank(rows)
            let key = (rank.0, rank.1, candidate.plain, candidate.score)
            if let current = best, key <= current.key { continue }
            best = (key, rows)
        }
        return best?.rows ?? []
    }

    /// Undo rotation and shear, then read each row band. Sets the transform
    /// used to map cells back to the source.
    private mutating func readRows(_ cleaned: BitMask, stroke: Double) -> [[SevenSegmentLatticeReader.Cell]] {
        var mask = cleaned
        rotationDegrees = rotation(of: mask)
        if rotationDegrees != 0 {
            mask = rotate(mask, degrees: rotationDegrees, expand: true)
        }
        rotatedWidth = mask.width
        rotatedHeight = mask.height
        let shear = stemShear(mask)
        mask = deshear(mask, degrees: shear)

        var rows: [[SevenSegmentLatticeReader.Cell]] = []
        for band in rowBands(mask, stroke: stroke) {
            let cells = readBand(mask, top: band.0, bottom: band.1, stroke: stroke)
            if cells.contains(where: { $0.character.isNumber }) {
                rows.append(cells)
            }
        }
        return rows
    }

    // MARK: Ink

    private func topHat(_ gray: [UInt8], width w: Int, height h: Int, window: Int) -> [Double] {
        let k = max(3, window | 1)
        var values = gray.map { Double(darkInk ? $0 : 255 - $0) }
        let dilated = slidingExtreme(values, width: w, height: h, size: k, maximum: true)
        let closed = slidingExtreme(dilated, width: w, height: h, size: k, maximum: false)
        for index in values.indices {
            let level = closed[index]
            let value = (level - values[index]) / max(level, 8)
            values[index] = min(1, max(0, value))
        }
        return values
    }

    private func clean(_ measured: BitMask) -> (BitMask, Double) {
        let raw = clearingBorderBands(measured)
        let (labels, components) = label(raw)
        let h = Double(analysisHeight)
        let big = components.filter { Double($0.area) >= (h * 0.015) * (h * 0.015) }
        guard !big.isEmpty else { return (BitMask(width: raw.width, height: raw.height), 0) }
        let thick = thicknesses(raw, labels: labels, count: components.count)
        func th(_ c: Component) -> Double { thick[c.label] }
        let longish = big.filter { Double(max($0.width, $0.height)) >= 3 * th($0) }
        let pool = longish.count >= 3 ? longish : big
        let stroke = weightedMedian(pool.map { (th($0), Double(max($0.width, $0.height))) })
        var keep = Set<Int>()
        for c in big {
            let touches = c.minY == 0 || c.minX == 0 || c.maxY == raw.height || c.maxX == raw.width
            if touches && (Double(c.height) > 0.5 * Double(raw.height)
                || Double(c.width) > 0.3 * Double(raw.width)
                || Double(c.area) < stroke * stroke * 2) {
                continue
            }
            if Double(c.height) > 0.85 * Double(raw.height) || Double(c.width) > 0.6 * Double(raw.width) { continue }
            if th(c) < 0.45 * stroke || th(c) > thickMaximum * stroke { continue }
            let fill = Double(c.area) / Double(c.width * c.height)
            if fill < 0.18 { continue }
            keep.insert(c.label)
        }
        var out = BitMask(width: raw.width, height: raw.height)
        for index in labels.indices where labels[index] > 0 && keep.contains(labels[index]) {
            out.bits[index] = true
        }
        return (out, stroke)
    }

    /// `strong` grown through 8-connected pixels whose contrast is above `weak`.
    private func hysteresis(_ contrast: [Double], strong: BitMask, weak: Double) -> BitMask {
        var out = strong
        var queue = strong.bits.indices.filter { strong.bits[$0] }
        let w = strong.width, h = strong.height
        var head = 0
        while head < queue.count {
            let index = queue[head]
            head += 1
            let x = index % w, y = index / w
            for dy in -1...1 {
                for dx in -1...1 where dx != 0 || dy != 0 {
                    let nx = x + dx, ny = y + dy
                    guard nx >= 0, ny >= 0, nx < w, ny < h else { continue }
                    let next = ny * w + nx
                    guard !out.bits[next], contrast[next] > weak else { continue }
                    out.bits[next] = true
                    queue.append(next)
                }
            }
        }
        return out
    }

    private func segmentScore(_ mask: BitMask, stroke: Double) -> Int {
        guard stroke > 0 else { return 0 }
        let (labels, components) = label(mask)
        let thick = thicknesses(mask, labels: labels, count: components.count)
        var total = 0
        for c in components {
            let t = thick[c.label]
            if t >= 0.6 * stroke, t <= 1.6 * stroke, Double(max(c.width, c.height)) >= 2 * t {
                total += c.area
            }
        }
        return total
    }

    // MARK: Geometry

    private func rotation(of mask: BitMask) -> Double {
        if let bars = barRotation(mask) {
            return abs(bars) >= 1 ? bars : 0
        }
        func sharpness(_ degrees: Double) -> Double {
            let turned = degrees == 0 ? mask : rotate(mask, degrees: degrees, expand: false)
            var sum = 0.0
            var squares = 0.0
            for y in 0..<turned.height {
                var row = 0.0
                for x in 0..<turned.width where turned[x, y] { row += 1 }
                sum += row
                squares += row * row
            }
            return squares / max(1, sum * sum)
        }
        let base = sharpness(0)
        var best = (0.0, base)
        var degrees = -15.0
        while degrees <= 15.0001 {
            let value = sharpness(degrees)
            if value > best.1 { best = (degrees, value) }
            degrees += 0.5
        }
        return best.1 > base * 1.10 ? best.0 : 0
    }

    /// Median orientation of long horizontal-ish bars (a/g/d segments).
    private func barRotation(_ mask: BitMask) -> Double? {
        let (labels, components) = label(mask)
        var angles: [(Double, Double)] = []
        for c in components where c.area >= 30 {
            var sx = 0.0, sy = 0.0, sxx = 0.0, syy = 0.0, sxy = 0.0, n = 0.0
            for y in c.minY..<c.maxY {
                for x in c.minX..<c.maxX where labels[y * mask.width + x] == c.label {
                    let fx = Double(x), fy = Double(y)
                    sx += fx; sy += fy; sxx += fx * fx; syy += fy * fy; sxy += fx * fy; n += 1
                }
            }
            let mx = sx / n, my = sy / n
            let cxx = sxx / n - mx * mx, cyy = syy / n - my * my, cxy = sxy / n - mx * my
            let trace = cxx + cyy
            let det = cxx * cyy - cxy * cxy
            let disc = max(0, trace * trace / 4 - det)
            let big = trace / 2 + disc.squareRoot()
            let small = trace / 2 - disc.squareRoot()
            if big < 6 * max(small, 1e-6) { continue }
            var angle = 0.5 * atan2(2 * cxy, cxx - cyy) * 180 / .pi
            if angle > 90 { angle -= 180 }
            if angle < -90 { angle += 180 }
            if abs(angle) <= 20 { angles.append((angle, n)) }
        }
        guard angles.count >= 3 else { return nil }
        // Image y grows downward; a bar rising to the right has a negative
        // angle here. Rotating by that angle levels it (scipy convention).
        return weightedMedian(angles)
    }

    /// Italic slant from the right edges of tall pieces. Separate stems and
    /// merged whole digits both keep the b/c stems on their right edge.
    private func stemShear(_ mask: BitMask) -> Double {
        let (labels, components) = label(mask)
        var angles: [(Double, Double)] = []
        for c in components {
            if Double(c.height) < Double(analysisHeight) * 0.06 || Double(c.height) < 1.3 * Double(c.width) { continue }
            var ys: [Double] = []
            var xs: [Double] = []
            for y in c.minY..<c.maxY {
                var right = -1
                for x in c.minX..<c.maxX where labels[y * mask.width + x] == c.label { right = x }
                if right >= 0 {
                    ys.append(Double(y - c.minY))
                    xs.append(Double(right - c.minX))
                }
            }
            guard ys.count >= 8, var line = fitLine(ys, xs) else { continue }
            for _ in 0..<2 {
                let keep = ys.indices.filter { xs[$0] - (line.0 * ys[$0] + line.1) > -0.25 * Double(c.width) }
                if keep.count < 8 { break }
                guard let refit = fitLine(keep.map { ys[$0] }, keep.map { xs[$0] }) else { break }
                line = refit
            }
            angles.append((atan(-line.0) * 180 / .pi, Double(c.height)))
        }
        guard angles.count >= 2 else { return 0 }
        let value = weightedMedian(angles)
        return (-3...15).contains(value) ? value : 0
    }

    private mutating func deshear(_ mask: BitMask, degrees: Double) -> BitMask {
        guard abs(degrees) >= 0.5 else {
            shearTangent = 0
            shearPad = 0
            return mask
        }
        let t = tan(degrees * .pi / 180)
        let pad = Int(abs(t) * Double(mask.height)) + 2
        // Positive slant moves upper rows left (toward -t*h); negative slant
        // moves them right. Only the first needs a left margin.
        let shift = t > 0 ? pad : 0
        shearTangent = t
        shearPad = shift
        var out = BitMask(width: mask.width + pad, height: mask.height)
        for y in 0..<mask.height {
            for x in 0..<mask.width where mask[x, y] {
                let shifted = Int((Double(x) + Double(y - mask.height) * t).rounded()) + shift
                if shifted >= 0, shifted < out.width { out[shifted, y] = true }
            }
        }
        return close(out)
    }

    // MARK: Rows and cells

    private func rowBands(_ mask: BitMask, stroke: Double) -> [(Int, Int)] {
        let (_, components) = label(mask)
        guard !components.isEmpty else { return [] }
        var cover = [Double](repeating: 0, count: mask.height)
        for c in components {
            for y in c.minY..<c.maxY { cover[y] += 1 }
        }
        let peak = cover.max() ?? 0
        let found = runs(cover.map { $0 >= max(2, rowCoverFraction * peak) })
        // Glare can wash the lower half of a row so fewer pieces cover it,
        // and the cover dips inside the digits. A digit's stroke crosses
        // that dip from the middle of one run to the middle of the next; a
        // stray reflection only pokes from one row into the gap below it.
        // Join runs that one piece reaches past the middle of both.
        // Displays drawn as separate segments leave a hairline gap between
        // upper and lower stems; it is thinner than a stroke, and a gap
        // between rows is wider. Join runs closer than a stroke too.
        var bands: [(Int, Int)] = []
        for run in found {
            if let previous = bands.last, Double(run.0 - previous.1) < stroke || components.contains(where: { piece in
                piece.minY < (previous.0 + previous.1) / 2 && piece.maxY > (run.0 + run.1) / 2
            }) {
                bands[bands.count - 1].1 = run.1
            } else {
                bands.append(run)
            }
        }
        let minimum = Double(analysisHeight) * 0.08
        let tallest = bands.map { $0.1 - $0.0 }.max() ?? 0
        return bands.filter { Double($0.1 - $0.0) >= max(minimum, Double(tallest) * 0.35) }
    }

    private func trimBand(_ band: BitMask, stroke: Double) -> (Int, Int) {
        let columns = columnHasInk(band, rows: 0..<band.height)
        let bridged = close1D(columns, size: max(1, Int(stroke * 0.6)) | 1)
        var tops: [Int] = []
        var bottoms: [Int] = []
        for (x0, x1) in runs(bridged) {
            guard let span = inkRows(band, x0: x0, x1: x1) else { continue }
            if Double(span.1 - span.0) >= 0.6 * Double(band.height) {
                tops.append(span.0)
                bottoms.append(span.1)
            }
        }
        guard !tops.isEmpty else { return (0, band.height) }
        tops.sort()
        bottoms.sort()
        let bottom = bottoms.count % 2 == 1 ? bottoms[(bottoms.count - 1) / 2] : bottoms[bottoms.count / 2]
        return (tops[tops.count / 2], bottom)
    }

    private func readBand(_ mask: BitMask, top: Int, bottom: Int, stroke: Double) -> [SevenSegmentLatticeReader.Cell] {
        let whole = crop(mask, y0: top, y1: bottom)
        let (t0, t1) = trimBand(whole, stroke: stroke)
        let pad = max(1, Int(stroke * 0.3))
        let bandTop = max(0, t0 - pad)
        let band = crop(whole, y0: bandTop, y1: min(whole.height, t1 + pad))
        let dh = Double(band.height)
        let upperRows = 0..<Int(dh * 0.72)
        let bridged = close1D(columnHasInk(band, rows: upperRows), size: max(1, Int(stroke * bridgeStrokes)) | 1)

        var tall: [(x0: Int, x1: Int)] = []
        for (x0, x1) in runs(bridged) {
            guard let span = inkRows(band, x0: x0, x1: x1) else { continue }
            if Double(span.1 - span.0) >= 0.6 * dh { tall.append((x0, x1)) }
        }
        guard !tall.isEmpty else { return [] }
        let wide = tall.map { Double($0.x1 - $0.x0) }.filter { $0 >= 0.35 * dh && $0 <= 0.8 * dh }
        let w = wide.isEmpty ? 0.5 * dh : median(wide)

        var edges: [Double] = []
        for piece in tall {
            let pw = Double(piece.x1 - piece.x0)
            let n = pw > 1.45 * w ? max(1, Int((pw / (w * 1.15)).rounded())) : 1
            for j in 0..<n { edges.append(Double(piece.x0) + Double(j + 1) * pw / Double(n)) }
        }
        edges.sort()

        var stride = 1.3 * w
        var phase = edges.first ?? 0
        if edges.count >= 2 {
            var best = -Double.infinity
            var s = w
            while s < 1.9 * w {
                var p = 0.0
                let phaseStep = max(1, s / 30)
                while p < s {
                    var hits = 0.0
                    var error = 0.0
                    for e in edges {
                        let k = ((e - p) / s).rounded()
                        let miss = abs(e - p - k * s)
                        error += miss
                        if miss < 0.18 * w { hits += 1 }
                    }
                    let fit = hits - 0.002 * error / w
                    if fit > best {
                        best = fit
                        stride = s
                        phase = p
                    }
                    p += phaseStep
                }
                s += max(1, w / 40)
            }
        }

        struct Slot { var character: Character; var confidence: Float; var x0: Int; var x1: Int; var bottom: Int }
        var cells: [Slot] = []
        let first = (edges.first ?? 0) - 0.5 * stride
        let last = (edges.last ?? 0) + 0.5 * stride
        let k0 = Int(((first - phase) / stride).rounded(.down))
        let k1 = Int(((last - phase) / stride).rounded(.up))
        for k in k0...max(k0, k1) {
            var r = phase + Double(k) * stride
            if let near = edges.filter({ abs($0 - r) < 0.25 * w }).min(by: { abs($0 - r) < abs($1 - r) }) {
                r = near
            }
            let x0 = Int((r - w).rounded())
            let x1 = Int(r.rounded())
            if x1 <= 0 || x0 >= band.width { continue }
            let cx0 = max(0, x0)
            let cx1 = min(band.width, x1)
            guard cx1 > cx0 else { continue }
            if inkShare(band, x0: cx0, x1: cx1, y0: 0, y1: band.height) < 0.03 { continue }
            let upper = columnHasInk(band, rows: upperRows, x0: cx0, x1: cx1)
            guard let firstInk = upper.firstIndex(of: true), let lastInk = upper.lastIndex(of: true) else { continue }
            guard let rowsSpan = inkRows(band, x0: cx0, x1: cx1) else { continue }
            if Double(rowsSpan.1 - rowsSpan.0) < 0.55 * dh { continue }
            let span = Double(lastInk - firstInk + 1)
            let offset = Double(firstInk)
            if span < 0.42 * w && offset > 0.45 * w {
                cells.append(Slot(character: "1", confidence: 1, x0: x0, x1: x1, bottom: band.height))
                continue
            }
            // A few pixels of lattice error move ink into the wrong zone.
            // Try small shifts. A higher confidence wins. An exact template
            // does not stop the search: the box can match a digit that is
            // one vertical stem short of the glyph, and a nearby shift
            // lights that stem. A different template does not replace it.
            let reach = Int(snapFraction * w)
            let step = max(1, Int(w / 16))
            let shifts = Swift.stride(from: -reach, through: reach, by: step).sorted { (abs($0), $0) < (abs($1), $1) }
            var chosen: (Character, Float, Int, Int, SevenSegmentPattern, Int)?
            for dx in shifts {
                let a = x0 + dx, b = x1 + dx
                let lo = max(0, a), hi = min(band.width, b)
                guard hi > lo else { continue }
                let limits = slotInkBottom(band, x0: lo, x1: hi, stroke: stroke)
                let glyph = readDigit(band, x0: lo, x1: hi, bottom: limits.zone)
                let better = chosen == nil
                    || glyph.1 > chosen!.1
                    || (glyph.1 > 0 && glyph.1 == chosen!.1 && addsOneVerticalStem(glyph.2, over: chosen!.4))
                if better { chosen = (glyph.0, glyph.1, a, b, glyph.2, limits.ink) }
            }
            guard let pick = chosen else { continue }
            cells.append(Slot(character: pick.0, confidence: pick.1, x0: pick.2, x1: pick.3, bottom: pick.5))
        }

        // A row's digits sit on consecutive lattice points.
        if !cells.isEmpty {
            var groups: [[Slot]] = [[cells[0]]]
            for cell in cells.dropFirst() {
                let gap = Double(cell.x1 - groups[groups.count - 1].last!.x1) / stride
                if gap > 1.6 { groups.append([cell]) } else { groups[groups.count - 1].append(cell) }
            }
            cells = groups.max { lhs, rhs in
                let l = lhs.filter { $0.character != "_" }.count
                let r = rhs.filter { $0.character != "_" }.count
                return l != r ? l < r : lhs.count < rhs.count
            } ?? []
        }
        while let head = cells.first, head.character == "_", head.confidence == 0 { cells.removeFirst() }
        while let tail = cells.last, tail.character == "_", tail.confidence == 0 { cells.removeLast() }

        // Decimal: baseline ink between two cells, with empty glass above.
        var marks: [(above: Double, x: Double)] = []
        // The band can hang into the next row. When it does, the dot sits
        // on the shortest glyph's baseline. A band that already ends on the
        // ink keeps the old strip.
        let shortest = cells.map(\.bottom).min() ?? band.height
        let baseline = band.height - shortest > max(2, Int(stroke)) ? shortest : band.height
        let stripTop = Int(Double(baseline) * 0.74)
        let upperLimit = Int(Double(baseline) * 0.6)
        for (left, right) in zip(cells, cells.dropFirst()) {
            let g0 = max(0, Int(Double(left.x1) - 0.08 * w))
            let g1 = min(band.width, Int(Double(right.x0) + 0.12 * w))
            guard g1 > g0 else { continue }
            var candidate: [Bool] = []
            var highs: [Int] = []
            for x in g0..<g1 {
                var low = 0
                var high = 0
                for y in stripTop..<baseline where band[x, y] { low += 1 }
                for y in 0..<upperLimit where band[x, y] { high += 1 }
                highs.append(high)
                candidate.append(Double(low) >= max(1, 0.35 * stroke) && Double(high) <= decimalAbove * Double(baseline))
            }
            guard let longest = runs(candidate).max(by: { ($0.1 - $0.0) < ($1.1 - $1.0) }) else { continue }
            if Double(longest.1 - longest.0) < 0.4 * stroke { continue }
            let above = Double(highs[longest.0..<longest.1].reduce(0, +)) / Double(longest.1 - longest.0) / Double(baseline)
            marks.append((above, Double(g0) + Double(longest.0 + longest.1) / 2))
        }
        // One decimal per row: the gap with the emptiest glass above its dot.
        let mark = marks.min { $0.above < $1.above }

        var placed: [(Character, Float, Double, Double)] = cells.map {
            ($0.character, $0.confidence, Double($0.x0), Double($0.x1))
        }
        if let mark {
            placed.append((".", 1, mark.x - stroke / 2, mark.x + stroke / 2))
        }
        placed.sort { ($0.2 + $0.3) < ($1.2 + $1.3) }
        while placed.first?.0 == "." { placed.removeFirst() }
        while placed.last?.0 == "." { placed.removeLast() }

        let y0 = Double(top + bandTop)
        let y1 = y0 + dh
        return placed.map { item in
            let box = sourceBox(x0: item.2, x1: item.3, y0: item.0 == "." ? y0 + dh * 0.74 : y0, y1: y1)
            return SevenSegmentLatticeReader.Cell(
                character: item.0, confidence: item.1,
                minX: box.0, minY: box.1, maxX: box.2, maxY: box.3
            )
        }
    }

    private func readDigit(_ band: BitMask, x0: Int, x1: Int, bottom: Int) -> (Character, Float, SevenSegmentPattern) {
        let limit = min(band.height, max(bottom, 1))
        let h = Double(limit)
        let w = Double(x1 - x0)
        func share(_ fx0: Double, _ fx1: Double, _ fy0: Double, _ fy1: Double) -> Double {
            let ya = Int(fy0 * h), yb = max(Int(fy1 * h), ya + 1)
            let xa = x0 + Int(fx0 * w), xb = max(x0 + Int(fx1 * w), xa + 1)
            return inkShare(band, x0: xa, x1: min(xb, band.width), y0: ya, y1: min(yb, limit))
        }
        let holes = (share(0.32, 0.68, 0.2, 0.38) + share(0.32, 0.68, 0.62, 0.8)) / 2
        if holes > holeMaximum {
            return ("_", 0, [])
        }
        let zones: [(SevenSegmentPattern, Double)] = [
            (.a, share(0.3, 0.7, 0, 0.16)),
            (.b, share(0.7, 1, 0.18, 0.4)),
            (.c, share(0.7, 1, 0.6, 0.82)),
            (.d, share(0.3, 0.7, 0.84, 1)),
            (.e, share(0, 0.3, 0.6, 0.82)),
            (.f, share(0, 0.3, 0.18, 0.4)),
            (.g, share(0.3, 0.7, 0.42, 0.58))
        ]
        let top = zones.map(\.1).max() ?? 0
        var pattern = SevenSegmentPattern()
        let cut = max(0.22, 0.4 * top)
        for (segment, value) in zones where value > cut {
            pattern.formUnion(segment)
        }
        let read = SevenSegmentLatticeReader.digit(for: pattern)
        return (read.0, read.1, pattern)
    }

    /// The shift lights exactly one vertical stem the current box left dark,
    /// and turns none off. That is a stem that sat just outside its zone,
    /// not a different digit.
    private func addsOneVerticalStem(_ current: SevenSegmentPattern, over previous: SevenSegmentPattern) -> Bool {
        let added = current.subtracting(previous)
        let vertical: SevenSegmentPattern = [.b, .c, .e, .f]
        return previous.subtracting(current).isEmpty
            && added.subtracting(vertical).isEmpty
            && added.rawValue.nonzeroBitCount == 1
    }

    // MARK: Coordinates

    /// Map an analysis-space box (after rotation and shear) to the source.
    private func sourceBox(x0: Double, x1: Double, y0: Double, y1: Double) -> (Double, Double, Double, Double) {
        let corners = [(x0, y0), (x1, y0), (x0, y1), (x1, y1)].map { point -> (Double, Double) in
            // Undo shear.
            let x = point.0 - Double(shearPad) - (point.1 - Double(rotatedHeight)) * shearTangent
            let y = point.1
            // Undo rotation (expanded canvas around the centre).
            var sx = x, sy = y
            if rotationDegrees != 0 {
                let radians = rotationDegrees * .pi / 180
                let dx = x - Double(rotatedWidth) / 2
                let dy = y - Double(rotatedHeight) / 2
                sx = cos(radians) * dx - sin(radians) * dy + Double(smallWidth) / 2
                sy = sin(radians) * dx + cos(radians) * dy + Double(analysisHeight) / 2
            }
            return (sx / scale, sy / scale)
        }
        let xs = corners.map(\.0), ys = corners.map(\.1)
        return (
            max(0, xs.min()!), max(0, ys.min()!),
            min(Double(width), xs.max()!), min(Double(height), ys.max()!)
        )
    }
}

extension SevenSegmentLatticeReader {
    private static let patterns: [(Character, SevenSegmentPattern)] = [
        ("0", [.a, .b, .c, .d, .e, .f]), ("1", [.b, .c]), ("2", [.a, .b, .d, .e, .g]),
        ("3", [.a, .b, .c, .d, .g]), ("4", [.b, .c, .f, .g]), ("5", [.a, .c, .d, .f, .g]),
        ("6", [.a, .c, .d, .e, .f, .g]), ("7", [.a, .b, .c]), ("8", [.a, .b, .c, .d, .e, .f, .g]),
        ("9", [.a, .b, .c, .d, .f, .g]), ("-", [.g]),
        // Common font variants: 6 and 9 without their tails, 7 with a left stem.
        ("6", [.c, .d, .e, .f, .g]), ("9", [.a, .b, .c, .f, .g]), ("7", [.a, .b, .c, .f])
    ]

    /// Exact template, else the one character whose templates are one
    /// segment away, else "_".
    fileprivate static func digit(for pattern: SevenSegmentPattern) -> (Character, Float) {
        if let exact = patterns.first(where: { $0.1 == pattern }) { return (exact.0, 1) }
        let near = Set(patterns.filter { ($0.1.rawValue ^ pattern.rawValue).nonzeroBitCount == 1 }.map(\.0))
        if near.count == 1, let only = near.first { return (only, 6 / 7) }
        return ("_", 0)
    }
}


// MARK: - Locating the panel in a full frame

extension SevenSegmentLatticeReader {
    /// Read, then read again from a tight box around the rows found. A loose
    /// crop shrinks the digits in the fixed analysis height; decimals suffer
    /// first. Cells are in this image's pixel coordinates.
    ///
    /// Panels show dark digits on light glass or light digits on dark glass,
    /// so both polarities are read and the better read wins (dark on a tie).
    static func readRefined(pixels: [UInt8], width: Int, height: Int) -> [[Cell]] {
        let dark = readRefined(pixels: pixels, width: width, height: height, darkInk: true)
        let light = readRefined(pixels: pixels, width: width, height: height, darkInk: false)
        return rank(light) > rank(dark) ? light : dark
    }

    private static func readRefined(pixels: [UInt8], width: Int, height: Int, darkInk: Bool) -> [[Cell]] {
        let first = read(pixels: pixels, width: width, height: height, darkInk: darkInk)
        guard let box = rowsBox(first, width: width, height: height) else { return first }
        let (x0, y0, x1, y1) = box
        if x0 == 0, y0 == 0, x1 == width, y1 == height { return first }
        let tight = cropped(pixels, width: width, x0: x0, y0: y0, x1: x1, y1: y1)
        let second = read(pixels: tight, width: x1 - x0, height: y1 - y0, darkInk: darkInk)
            .map { row in row.map { $0.offset(dx: Double(x0), dy: Double(y0)) } }
        return rank(second) >= rank(first) ? second : first
    }

    /// Find the digit panel in a whole photo: clusters of stroke-like ink are
    /// candidates, and the candidate that reads best wins. Cells are in the
    /// full image's pixel coordinates.
    static func locateAndRead(pixels: [UInt8], width: Int, height: Int) -> [[Cell]] {
        var best: [[Cell]] = []
        for box in candidateBoxes(pixels: pixels, width: width, height: height) {
            let (x0, y0, x1, y1) = box
            guard x1 - x0 >= 16, y1 - y0 >= 16 else { continue }
            let crop = cropped(pixels, width: width, x0: x0, y0: y0, x1: x1, y1: y1)
            let rows = readRefined(pixels: crop, width: x1 - x0, height: y1 - y0)
                .map { row in row.map { $0.offset(dx: Double(x0), dy: Double(y0)) } }
            if best.isEmpty || rank(rows) > rank(best) { best = rows }
        }
        return best
    }

    /// Glyphs that carry information: digits other than 1 (stray stems read
    /// as 1), less unknown cells.
    static func quality(_ rows: [[Cell]]) -> Int {
        let cells = rows.flatMap { $0 }
        return cells.filter { $0.character.isNumber && $0.character != "1" }.count
            - cells.filter { $0.character == "_" }.count
    }

    /// Confidence is judged row by row: a sure read of one row says nothing
    /// about another. First the information in rows that read surely on
    /// their own, then the information in every row. A confident "1.1" from
    /// elsewhere in the frame no longer outranks a panel read with one sure
    /// row of real digits and one unsure row.
    static func rank(_ rows: [[Cell]]) -> (Int, Int) {
        (quality(rows.filter(isConfident(row:))), quality(rows))
    }

    private static func rowsBox(_ rows: [[Cell]], width: Int, height: Int) -> (Int, Int, Int, Int)? {
        let digits = rows.flatMap { $0 }.filter { $0.character.isNumber }
        guard !digits.isEmpty else { return nil }
        let heights = digits.map { $0.maxY - $0.minY }.sorted()
        let dh = heights[heights.count / 2]
        let all = rows.flatMap { $0 }
        let x0 = Int(max(0, (all.map(\.minX).min() ?? 0) - 0.6 * dh))
        let y0 = Int(max(0, (all.map(\.minY).min() ?? 0) - 0.5 * dh))
        let x1 = Int(min(Double(width), (all.map(\.maxX).max() ?? 0) + 0.6 * dh))
        let y1 = Int(min(Double(height), (all.map(\.maxY).max() ?? 0) + 0.5 * dh))
        guard x1 - x0 >= 16, y1 - y0 >= 16 else { return nil }
        return (x0, y0, x1, y1)
    }

    /// Candidate panel boxes, most stroke ink first, at most eight. Strokes
    /// are looked for in both polarities: dark digits on light glass and
    /// light digits on dark glass.
    private static func candidateBoxes(pixels: [UInt8], width: Int, height: Int) -> [(Int, Int, Int, Int)] {
        let scale = 900.0 / Double(max(width, height))
        let sw = max(1, Int((Double(width) * scale).rounded()))
        let sh = max(1, Int((Double(height) * scale).rounded()))
        let dark = median3(boxResize(pixels, width: width, height: height, toWidth: sw, toHeight: sh), width: sw, height: sh)
        let short = Double(min(sw, sh))
        var found: [(area: Int, box: (Double, Double, Double, Double))] = []
        for small in [dark, dark.map { 255 - $0 }] {
        for fraction in [0.012, 0.02, 0.032] {
            let stroke = max(2, short * fraction)
            let k = Int(stroke * 2.4) | 1
            let values = small.map(Double.init)
            let closed = slidingExtreme(slidingExtreme(values, width: sw, height: sh, size: k, maximum: true),
                                        width: sw, height: sh, size: k, maximum: false)
            var contrast = [Double](repeating: 0, count: values.count)
            for i in values.indices { contrast[i] = min(1, max(0, (closed[i] - values[i]) / max(closed[i], 8))) }
            let selected = contrast.filter { $0 > 0.03 }
            let cut = selected.count > 200 ? otsu(selected) : 0.2
            var ink = BitMask(width: sw, height: sh)
            for i in contrast.indices where contrast[i] > max(0.6 * cut, 0.08) { ink.bits[i] = true }
            let (labels, components) = label(ink)
            guard !components.isEmpty else { continue }
            let thick = thicknesses(ink, labels: labels, count: components.count)
            var segment = BitMask(width: sw, height: sh)
            var keep = Set<Int>()
            for c in components {
                let t = thick[c.label]
                let longest = Double(max(c.width, c.height))
                if t >= 0.5 * stroke, t <= 2 * stroke, longest >= 2.2 * t, longest <= 14 * stroke { keep.insert(c.label) }
            }
            for i in labels.indices where labels[i] > 0 && keep.contains(labels[i]) { segment.bits[i] = true }
            let grown = slidingExtreme(segment.bits.map { $0 ? 1.0 : 0.0 }, width: sw, height: sh,
                                       sizeX: Int(stroke * 5) | 1, sizeY: Int(stroke * 3) | 1, maximum: true)
            var joined = BitMask(width: sw, height: sh)
            for i in grown.indices where grown[i] > 0 { joined.bits[i] = true }
            let (clusterLabels, clusters) = label(joined)
            var pieces = [Set<Int>](repeating: [], count: clusters.count + 1)
            var area = [Int](repeating: 0, count: clusters.count + 1)
            let (segmentLabels, _) = label(segment)
            for i in segmentLabels.indices where segmentLabels[i] > 0 {
                let cluster = clusterLabels[i]
                pieces[cluster].insert(segmentLabels[i])
                area[cluster] += 1
            }
            for c in clusters {
                guard pieces[c.label].count >= 4 else { continue }
                guard Double(c.height) >= 4 * stroke, Double(c.width) >= 6 * stroke else { continue }
                found.append((area[c.label], (
                    Double(c.minX) / scale, Double(c.minY) / scale, Double(c.maxX) / scale, Double(c.maxY) / scale
                )))
            }
        }
        }
        found.sort { $0.area > $1.area }
        var boxes: [(Double, Double, Double, Double)] = []
        for item in found {
            let (x0, y0, x1, y1) = item.box
            let bw = x1 - x0, bh = y1 - y0
            let box = (max(0, x0 - 0.12 * bw), max(0, y0 - 0.25 * bh),
                       min(Double(width), x1 + 0.12 * bw), min(Double(height), y1 + 0.25 * bh))
            if boxes.contains(where: { overlapRatio($0, box) > 0.6 }) { continue }
            boxes.append(box)
            if boxes.count >= 8 { break }
        }
        return boxes.map { (Int($0.0), Int($0.1), Int($0.2.rounded(.up)), Int($0.3.rounded(.up))) }
    }
}

extension SevenSegmentLatticeReader.Cell {
    fileprivate func offset(dx: Double, dy: Double) -> Self {
        var moved = self
        moved.minX += dx; moved.maxX += dx
        moved.minY += dy; moved.maxY += dy
        return moved
    }
}

private func overlapRatio(_ a: (Double, Double, Double, Double), _ b: (Double, Double, Double, Double)) -> Double {
    let ix = max(0, min(a.2, b.2) - max(a.0, b.0)), iy = max(0, min(a.3, b.3) - max(a.1, b.1))
    let inter = ix * iy
    let union = (a.2 - a.0) * (a.3 - a.1) + (b.2 - b.0) * (b.3 - b.1) - inter
    return union > 0 ? inter / union : 0
}

private func cropped(_ pixels: [UInt8], width: Int, x0: Int, y0: Int, x1: Int, y1: Int) -> [UInt8] {
    var out: [UInt8] = []
    out.reserveCapacity((x1 - x0) * (y1 - y0))
    for y in y0..<y1 { out.append(contentsOf: pixels[(y * width + x0)..<(y * width + x1)]) }
    return out
}

// MARK: - Raster helpers

private func boxResize(_ source: [UInt8], width: Int, height: Int, toWidth: Int, toHeight: Int) -> [UInt8] {
    // Area-weighted (box) resampling: each output pixel averages the source
    // area it covers. Separable: rows, then columns.
    func weights(_ from: Int, _ to: Int) -> [[(Int, Double)]] {
        let ratio = Double(from) / Double(to)
        return (0..<to).map { i in
            let a = Double(i) * ratio, b = Double(i + 1) * ratio
            var list: [(Int, Double)] = []
            var j = Int(a)
            while Double(j) < b, j < from {
                let lo = max(a, Double(j)), hi = min(b, Double(j + 1))
                if hi > lo { list.append((j, (hi - lo) / ratio)) }
                j += 1
            }
            return list
        }
    }
    let wx = weights(width, toWidth)
    let wy = weights(height, toHeight)
    var horizontal = [Double](repeating: 0, count: toWidth * height)
    for y in 0..<height {
        let row = y * width
        for x in 0..<toWidth {
            var sum = 0.0
            for (j, weight) in wx[x] { sum += Double(source[row + j]) * weight }
            horizontal[y * toWidth + x] = sum
        }
    }
    var out = [UInt8](repeating: 0, count: toWidth * toHeight)
    for y in 0..<toHeight {
        for x in 0..<toWidth {
            var sum = 0.0
            for (j, weight) in wy[y] { sum += horizontal[j * toWidth + x] * weight }
            out[y * toWidth + x] = UInt8(min(255, max(0, sum.rounded())))
        }
    }
    return out
}

private func median3(_ source: [UInt8], width: Int, height: Int) -> [UInt8] {
    var out = source
    var window = [UInt8](repeating: 0, count: 9)
    for y in 0..<height {
        for x in 0..<width {
            var n = 0
            for dy in -1...1 {
                let yy = min(height - 1, max(0, y + dy))
                for dx in -1...1 {
                    let xx = min(width - 1, max(0, x + dx))
                    window[n] = source[yy * width + xx]
                    n += 1
                }
            }
            window.sort()
            out[y * width + x] = window[4]
        }
    }
    return out
}

/// Square max (or min) filter of odd `size`, clipped at the borders.
private func slidingExtreme(_ values: [Double], width: Int, height: Int, size: Int, maximum: Bool) -> [Double] {
    slidingExtreme(values, width: width, height: height, sizeX: size, sizeY: size, maximum: maximum)
}

/// Rectangular max (or min) filter of odd sizes, clipped at the borders.
private func slidingExtreme(
    _ values: [Double], width: Int, height: Int, sizeX: Int, sizeY: Int, maximum: Bool
) -> [Double] {
    func pass(_ input: [Double], count: Int, lines: Int, radius: Int, index: (Int, Int) -> Int) -> [Double] {
        var output = input
        var deque = [Int](repeating: 0, count: count)
        for line in 0..<lines {
            var head = 0, tail = 0
            var next = 0
            for i in 0..<count {
                let upper = min(count - 1, i + radius)
                while next <= upper {
                    let v = input[index(line, next)]
                    while tail > head {
                        let w = input[index(line, deque[tail - 1])]
                        if maximum ? (w <= v) : (w >= v) { tail -= 1 } else { break }
                    }
                    deque[tail] = next
                    tail += 1
                    next += 1
                }
                while deque[head] < i - radius { head += 1 }
                output[index(line, i)] = input[index(line, deque[head])]
            }
        }
        return output
    }
    let rows = pass(values, count: width, lines: height, radius: sizeX / 2) { line, i in line * width + i }
    return pass(rows, count: height, lines: width, radius: sizeY / 2) { line, i in i * width + line }
}

private func otsu(_ values: [Double]) -> Double {
    guard let low = values.min(), let high = values.max(), high > low else { return values.first ?? 0 }
    let bins = 128
    var histogram = [Double](repeating: 0, count: bins)
    let span = (high - low) / Double(bins)
    for v in values {
        histogram[min(bins - 1, Int((v - low) / span))] += 1
    }
    let centers = (0..<bins).map { low + (Double($0) + 0.5) * span }
    let total = histogram.reduce(0, +)
    let totalMass = zip(histogram, centers).reduce(0) { $0 + $1.0 * $1.1 }
    var weight = 0.0, mass = 0.0
    var best = -1.0, cut = low
    for i in 0..<bins {
        weight += histogram[i]
        mass += histogram[i] * centers[i]
        let rest = total - weight
        guard weight > 0, rest > 0 else { continue }
        let mean1 = mass / weight
        let mean2 = (totalMass - mass) / rest
        let between = weight * rest * (mean1 - mean2) * (mean1 - mean2)
        if between > best {
            best = between
            cut = low + Double(i + 1) * span
        }
    }
    return cut
}

/// 4-connected labels (0 = background) and component bounds, labels from 1.
private func label(_ mask: BitMask) -> ([Int], [Component]) {
    let w = mask.width, h = mask.height
    var labels = [Int](repeating: 0, count: w * h)
    var components: [Component] = []
    var stack: [Int] = []
    var next = 0
    for start in 0..<(w * h) where mask.bits[start] && labels[start] == 0 {
        next += 1
        var c = Component(label: next, minX: start % w, minY: start / w, maxX: start % w + 1, maxY: start / w + 1, area: 0)
        labels[start] = next
        stack.append(start)
        while let index = stack.popLast() {
            let x = index % w, y = index / w
            c.area += 1
            c.minX = min(c.minX, x); c.maxX = max(c.maxX, x + 1)
            c.minY = min(c.minY, y); c.maxY = max(c.maxY, y + 1)
            if x > 0, mask.bits[index - 1], labels[index - 1] == 0 { labels[index - 1] = next; stack.append(index - 1) }
            if x + 1 < w, mask.bits[index + 1], labels[index + 1] == 0 { labels[index + 1] = next; stack.append(index + 1) }
            if y > 0, mask.bits[index - w], labels[index - w] == 0 { labels[index - w] = next; stack.append(index - w) }
            if y + 1 < h, mask.bits[index + w], labels[index + w] == 0 { labels[index + w] = next; stack.append(index + w) }
        }
        components.append(c)
    }
    return (labels, components)
}

/// Twice the largest inscribed distance per component (stroke thickness).
/// Exact Euclidean distance transform (Felzenszwalb–Huttenlocher), with the
/// area outside the mask counted as background.
private func thicknesses(_ mask: BitMask, labels: [Int], count: Int) -> [Double] {
    let w = mask.width + 2, h = mask.height + 2
    let infinity = 1e20
    var grid = [Double](repeating: 0, count: w * h)
    for y in 0..<mask.height {
        for x in 0..<mask.width where mask[x, y] {
            grid[(y + 1) * w + x + 1] = infinity
        }
    }
    func transform(_ f: [Double]) -> [Double] {
        let n = f.count
        var d = [Double](repeating: 0, count: n)
        var v = [Int](repeating: 0, count: n)
        var z = [Double](repeating: 0, count: n + 1)
        var k = 0
        z[0] = -infinity; z[1] = infinity
        for q in 1..<n {
            var s = ((f[q] + Double(q * q)) - (f[v[k]] + Double(v[k] * v[k]))) / Double(2 * q - 2 * v[k])
            while s <= z[k] {
                k -= 1
                s = ((f[q] + Double(q * q)) - (f[v[k]] + Double(v[k] * v[k]))) / Double(2 * q - 2 * v[k])
            }
            k += 1
            v[k] = q
            z[k] = s
            z[k + 1] = infinity
        }
        k = 0
        for q in 0..<n {
            while z[k + 1] < Double(q) { k += 1 }
            let dq = Double(q - v[k])
            d[q] = dq * dq + f[v[k]]
        }
        return d
    }
    for x in 0..<w {
        let column = (0..<h).map { grid[$0 * w + x] }
        let done = transform(column)
        for y in 0..<h { grid[y * w + x] = done[y] }
    }
    for y in 0..<h {
        let row = Array(grid[(y * w)..<(y * w + w)])
        let done = transform(row)
        for x in 0..<w { grid[y * w + x] = done[x] }
    }
    var best = [Double](repeating: 0, count: count + 1)
    for y in 0..<mask.height {
        for x in 0..<mask.width {
            let l = labels[y * mask.width + x]
            if l > 0 { best[l] = max(best[l], grid[(y + 1) * w + x + 1]) }
        }
    }
    return best.map { 2 * $0.squareRoot() }
}

/// Bezel and glass edges run along the crop border and can join the digits
/// beside them into one piece. For each piece that touches the border,
/// clear the band along the border as deep as that piece's ink runs in
/// from it (the median run). A bar along the edge goes; digits that start
/// further in stay.
private func clearingBorderBands(_ mask: BitMask) -> BitMask {
    let (labels, components) = label(mask)
    let w = mask.width, h = mask.height
    var runs = [[Int]](repeating: [], count: components.count + 1)
    func walk(_ x: Int, _ y: Int, _ dx: Int, _ dy: Int) {
        let l = labels[y * w + x]
        guard l > 0 else { return }
        var length = 0
        var cx = x, cy = y
        while cx >= 0, cy >= 0, cx < w, cy < h, labels[cy * w + cx] == l {
            length += 1
            cx += dx
            cy += dy
        }
        runs[l].append(length)
    }
    for x in 0..<w {
        walk(x, 0, 0, 1)
        walk(x, h - 1, 0, -1)
    }
    for y in 0..<h {
        walk(0, y, 1, 0)
        walk(w - 1, y, -1, 0)
    }
    var depth = [Int](repeating: 0, count: components.count + 1)
    for l in runs.indices where !runs[l].isEmpty {
        let sorted = runs[l].sorted()
        depth[l] = sorted[sorted.count / 2]
    }
    guard depth.contains(where: { $0 > 0 }) else { return mask }
    var out = mask
    for y in 0..<h {
        for x in 0..<w {
            let l = labels[y * w + x]
            guard l > 0, depth[l] > 0 else { continue }
            if min(x, y, w - 1 - x, h - 1 - y) < depth[l] { out[x, y] = false }
        }
    }
    return out
}

/// Nearest-neighbour rotation about the centre (scipy.ndimage.rotate order 0).
private func rotate(_ mask: BitMask, degrees: Double, expand: Bool) -> BitMask {
    let radians = degrees * .pi / 180
    let c = cos(radians), s = sin(radians)
    let w = Double(mask.width), h = Double(mask.height)
    let outW = expand ? Int((abs(w * c) + abs(h * s)).rounded()) : mask.width
    let outH = expand ? Int((abs(w * s) + abs(h * c)).rounded()) : mask.height
    var out = BitMask(width: max(1, outW), height: max(1, outH))
    let ocx = Double(outW) / 2, ocy = Double(outH) / 2
    for y in 0..<out.height {
        for x in 0..<out.width {
            let dx = Double(x) + 0.5 - ocx, dy = Double(y) + 0.5 - ocy
            let sx = Int((c * dx - s * dy + w / 2).rounded(.down))
            let sy = Int((s * dx + c * dy + h / 2).rounded(.down))
            if sx >= 0, sy >= 0, sx < mask.width, sy < mask.height, mask[sx, sy] { out[x, y] = true }
        }
    }
    return out
}

/// Binary closing with a 3×3 cross, one iteration.
private func close(_ mask: BitMask) -> BitMask {
    func step(_ m: BitMask, dilate: Bool) -> BitMask {
        var out = m
        for y in 0..<m.height {
            for x in 0..<m.width {
                var values = [m[x, y]]
                if x > 0 { values.append(m[x - 1, y]) } else if !dilate { values.append(false) }
                if x + 1 < m.width { values.append(m[x + 1, y]) } else if !dilate { values.append(false) }
                if y > 0 { values.append(m[x, y - 1]) } else if !dilate { values.append(false) }
                if y + 1 < m.height { values.append(m[x, y + 1]) } else if !dilate { values.append(false) }
                out[x, y] = dilate ? values.contains(true) : !values.contains(false)
            }
        }
        return out
    }
    return step(step(mask, dilate: true), dilate: false)
}

private func close1D(_ line: [Bool], size: Int) -> [Bool] {
    let radius = size / 2
    guard radius > 0 else { return line }
    let n = line.count
    var dilated = [Bool](repeating: false, count: n)
    for i in 0..<n where line[i] {
        for j in max(0, i - radius)...min(n - 1, i + radius) { dilated[j] = true }
    }
    var out = [Bool](repeating: false, count: n)
    for i in 0..<n {
        var all = true
        for j in (i - radius)...(i + radius) {
            if j < 0 || j >= n || !dilated[j] { all = false; break }
        }
        out[i] = all
    }
    return out
}

private func crop(_ mask: BitMask, y0: Int, y1: Int) -> BitMask {
    let top = max(0, y0), bottom = min(mask.height, max(top, y1))
    var out = BitMask(width: mask.width, height: bottom - top)
    for y in top..<bottom {
        for x in 0..<mask.width { out[x, y - top] = mask[x, y] }
    }
    return out
}

private func columnHasInk(_ mask: BitMask, rows: Range<Int>, x0: Int = 0, x1: Int? = nil) -> [Bool] {
    let end = x1 ?? mask.width
    let ys = max(0, rows.lowerBound)..<min(mask.height, rows.upperBound)
    return (x0..<end).map { x in ys.contains { mask[x, $0] } }
}

/// Exclusive end of this glyph's own ink, plus the same pad the band keeps
/// under a stroke. Glass under a bar has no later run, so the end is the
/// bar. A hole of a few rows is a broken stroke: the ink below it stays in
/// the box. Cutting at that hole turns a whole row into threes. The top
/// stays put.
private func slotInkBottom(_ mask: BitMask, x0: Int, x1: Int, stroke: Double) -> (zone: Int, ink: Int) {
    let xa = max(0, x0), xb = min(mask.width, x1)
    guard xb > xa else { return (mask.height, mask.height) }
    var inkRow = [Bool](repeating: false, count: mask.height)
    for y in 0..<mask.height {
        var count = 0
        for x in xa..<xb where mask[x, y] {
            count += 1
            if count == 2 { inkRow[y] = true; break }
        }
    }
    let bridge = 2
    var y = 0
    while y < inkRow.count {
        if inkRow[y] { y += 1; continue }
        let start = y
        while y < inkRow.count, !inkRow[y] { y += 1 }
        if start > 0, y < inkRow.count, y - start <= bridge {
            for index in start..<y { inkRow[index] = true }
        }
    }
    var runs: [(Int, Int)] = []
    var runStart: Int?
    for index in 0...inkRow.count {
        let on = index < inkRow.count && inkRow[index]
        if on, runStart == nil { runStart = index }
        if !on, let start = runStart {
            runs.append((start, index))
            runStart = nil
        }
    }
    guard let longest = runs.max(by: { lhs, rhs in
        let left = lhs.1 - lhs.0, right = rhs.1 - rhs.0
        return left != right ? left < right : lhs.0 > rhs.0
    }) else { return (mask.height, mask.height) }
    let pad = max(1, Int(stroke * 0.3))
    let strokeRows = max(2, Int(stroke))
    let nextRun = runs.filter { run in
        run.0 >= longest.1 && run.1 - run.0 > strokeRows
    }.min { $0.0 < $1.0 }
    let next = nextRun?.0 ?? mask.height
    // A short piece below a few empty rows is still this glyph. A tall empty
    // tail means the run ended early. Drop only a short hang of glass under
    // a bar that already reaches the baseline.
    let reachesBaseline = longest.1 > mask.height * 2 / 3
    let tail = mask.height - longest.1
    let modestGlass = tail > pad && tail < mask.height / 5
    guard reachesBaseline && modestGlass else {
        return (mask.height, mask.height)
    }
    return (min(longest.1 + pad, next), longest.1)
}

private func inkRows(_ mask: BitMask, x0: Int, x1: Int) -> (Int, Int)? {
    var first: Int?
    var last = 0
    for y in 0..<mask.height {
        var any = false
        for x in max(0, x0)..<min(mask.width, x1) where mask[x, y] { any = true; break }
        if any {
            if first == nil { first = y }
            last = y + 1
        }
    }
    return first.map { ($0, last) }
}

private func inkShare(_ mask: BitMask, x0: Int, x1: Int, y0: Int, y1: Int) -> Double {
    let xa = max(0, x0), xb = min(mask.width, x1), ya = max(0, y0), yb = min(mask.height, y1)
    guard xb > xa, yb > ya else { return 0 }
    var ink = 0
    for y in ya..<yb {
        for x in xa..<xb where mask[x, y] { ink += 1 }
    }
    return Double(ink) / Double((xb - xa) * (yb - ya))
}

private func runs(_ on: [Bool]) -> [(Int, Int)] {
    var result: [(Int, Int)] = []
    var start: Int?
    for (i, value) in on.enumerated() {
        if value, start == nil { start = i }
        if !value, let s = start { result.append((s, i)); start = nil }
    }
    if let s = start { result.append((s, on.count)) }
    return result
}

/// Least-squares x = slope * y + intercept.
private func fitLine(_ ys: [Double], _ xs: [Double]) -> (Double, Double)? {
    let n = Double(ys.count)
    let sy = ys.reduce(0, +), sx = xs.reduce(0, +)
    let syy = ys.reduce(0) { $0 + $1 * $1 }
    let sxy = zip(ys, xs).reduce(0) { $0 + $1.0 * $1.1 }
    let denominator = n * syy - sy * sy
    guard denominator != 0 else { return nil }
    let slope = (n * sxy - sx * sy) / denominator
    return (slope, (sx - slope * sy) / n)
}

private func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    guard !sorted.isEmpty else { return 0 }
    let mid = sorted.count / 2
    return sorted.count % 2 == 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2
}

private func weightedMedian(_ pairs: [(Double, Double)]) -> Double {
    let sorted = pairs.sorted { $0.0 < $1.0 }
    let total = sorted.reduce(0) { $0 + $1.1 }
    var running = 0.0
    for (value, weight) in sorted {
        running += weight
        if running >= total / 2 { return value }
    }
    return sorted.last?.0 ?? 0
}

// MARK: - Live Photo frames

extension SevenSegmentOCR {
    /// Decode a Live Photo: its key photo plus frames from the paired video.
    ///
    /// Reflections move between frames while the digits stay, so each row is
    /// voted across the key photo and the frames.
    ///
    /// Every image gets the full single-photo decode, panel search included.
    /// (Cropping each frame to the key photo's region was faster but lost
    /// rows the key read had missed.) Images decode in parallel. The key
    /// photo is sharper than the video frames, so its read counts twice and
    /// wins a tied row.
    ///
    /// `localizeDigitPanel` is passed to each single-photo decode. Leave it
    /// on for whole Live Photo frames; turn it off for frames that are
    /// already cropped to the panel.
    ///
    /// Confidence is the smallest share of the vote that any row won. Boxes
    /// come from the one read that agrees with the most winning rows, so
    /// they share that image's coordinates.
    public static func decode(
        frames: [CGImage],
        keyFrame: CGImage? = nil,
        deskewMaximumDegrees: Double = 3,
        localizeDigitPanel: Bool = true
    ) -> OCRResult {
        let images = (keyFrame.map { [$0] } ?? []) + frames
        guard !images.isEmpty else { return OCRResult(extractedText: "", confidence: 0) }
        let reads = FrameReads(images: images)
        DispatchQueue.concurrentPerform(iterations: images.count) { index in
            let read = decode(
                cgImage: reads.images[index],
                deskewMaximumDegrees: deskewMaximumDegrees,
                localizeDigitPanel: localizeDigitPanel
            )
            reads.store(read, at: index)
        }
        var votes: [FrameVote] = []
        for (index, result) in reads.results.enumerated() {
            guard let result else { continue }
            let isKey = keyFrame != nil && index == 0
            votes.append(FrameVote(result: result, weight: isKey ? 2 : 1, isKey: isKey))
        }
        let fallback = votes.first?.result ?? OCRResult(extractedText: "", confidence: 0)
        return voted(votes, fallback: fallback)
    }

    /// Per-row majority among reads that agree on the row count.
    ///
    /// Rows are compared without spaces, and the winner keeps the spacing of
    /// a read that voted for it. Well-formed rows (digits, one decimal mark
    /// at most, three-digit groups) outvote the rest; a row that no read got well-formed
    /// (an unknown cell, a colon) is voted among all reads instead.
    /// A tied row goes to the key photo's read, then to the reads with more
    /// total confidence.
    private static func voted(_ votes: [FrameVote], fallback: OCRResult) -> OCRResult {
        var rowCounts: [Int: Double] = [:]
        for vote in votes where !vote.rows.isEmpty {
            rowCounts[vote.rows.count, default: 0] += vote.weight
        }
        // On a tie, more rows: a read that found both rows beats one that lost a row.
        guard let count = rowCounts.max(by: { $0.value < $1.value || ($0.value == $1.value && $0.key < $1.key) })?.key
        else { return fallback }
        let voters = votes.filter { $0.rows.count == count }
        var winners: [String] = []
        var shares: [Double] = []
        for index in 0..<count {
            let wellFormed = voters.filter { isWellFormedRow(FrameVote.normalized($0.rows[index])) }
            let ballots = wellFormed.isEmpty ? voters : wellFormed
            var tally: [String: RowTally] = [:]
            var order: [String] = []
            for vote in ballots {
                let row = vote.rows[index]
                let key = FrameVote.normalized(row)
                if tally[key] == nil { order.append(key) }
                var entry = tally[key] ?? RowTally(text: row)
                entry.weight += vote.weight
                entry.hasKey = entry.hasKey || vote.isKey
                entry.confidence += Double(vote.result.confidence)
                tally[key] = entry
            }
            let total = ballots.reduce(0) { $0 + $1.weight }
            // `order` is first-seen (key photo first), so max keeps the earliest on a full tie.
            guard let best = order.compactMap({ tally[$0] }).max(by: { $0.ranksBelow($1) }), total > 0
            else { return fallback }
            winners.append(best.text)
            shares.append(best.weight / total)
        }
        let text = winners.joined(separator: "\n")
        let (boxes, texts) = boxesFollowingVote(voters, winners: winners, shares: shares)
        return OCRResult(
            extractedText: text,
            confidence: Float(shares.min() ?? 0),
            boundingBoxes: boxes,
            textTypes: text.isEmpty ? [:] : [.number: text],
            recognizedTexts: texts
        )
    }

    /// Digits with at most one decimal mark, and group separators of the
    /// other kind before it ("1,234.56", "1.234,56", "1,234,567"). A row
    /// with marks of one kind only is one decimal or all separators. Every
    /// separator is followed by exactly three digits.
    static func isWellFormedRow(_ row: String) -> Bool {
        guard let first = row.first, let last = row.last, first.isNumber, last.isNumber,
              row.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," }) else { return false }
        let groups = row.split(whereSeparator: { !$0.isNumber }).map(\.count)
        let marks = row.filter { !$0.isNumber }
        guard let separator = marks.first, marks.count > 1 else { return true }
        let decimal = marks.last != separator
        // Marks before the last one must all be the separator kind.
        guard marks.dropLast().allSatisfy({ $0 == separator }) else { return false }
        let leading = groups[0]
        let grouped = decimal ? groups.dropFirst().dropLast() : groups.dropFirst()
        return leading <= 3 && grouped.allSatisfy { $0 == 3 }
    }

    /// Boxes and fragments from the read that agrees with the most winning
    /// rows (the key photo first). A row that read got wrong becomes one
    /// fragment with the winning text over that row's boxes.
    private static func boxesFollowingVote(
        _ voters: [FrameVote],
        winners: [String],
        shares: [Double]
    ) -> ([CGRect], [OCRRecognizedText]) {
        let wanted = winners.map(FrameVote.normalized)
        func agreement(_ vote: FrameVote) -> Int {
            zip(vote.rows.map(FrameVote.normalized), wanted).filter { $0 == $1 }.count
        }
        // Earliest wins a tie, so the key photo is preferred.
        guard var base = voters.first else { return ([], []) }
        for vote in voters.dropFirst() where agreement(vote) > agreement(base) {
            base = vote
        }
        let baseRows = base.rows.map(FrameVote.normalized)
        guard let groups = rowGroups(base.result.recognizedTexts, rows: baseRows) else {
            // Fragments do not line up with rows; keep them only when they say the same.
            return baseRows == wanted ? (base.result.boundingBoxes, base.result.recognizedTexts) : (base.result.boundingBoxes, [])
        }
        var texts: [OCRRecognizedText] = []
        for (index, group) in groups.enumerated() {
            if baseRows[index] == wanted[index] {
                texts += group
                continue
            }
            let union = group.map(\.boundingBox).reduce(CGRect.null) { $0.union($1) }
            texts.append(
                OCRRecognizedText(
                    text: winners[index],
                    boundingBox: union.isNull ? .zero : union,
                    confidence: Float(shares[index]),
                    role: .segment
                )
            )
        }
        return (texts.map(\.boundingBox), texts)
    }

    /// Split fragments into rows by their text, in reading order. Nil when
    /// they do not spell the rows exactly.
    private static func rowGroups(_ fragments: [OCRRecognizedText], rows: [String]) -> [[OCRRecognizedText]]? {
        var groups: [[OCRRecognizedText]] = []
        var next = 0
        for row in rows {
            var spelled = ""
            var group: [OCRRecognizedText] = []
            while spelled.count < row.count, next < fragments.count {
                group.append(fragments[next])
                spelled += FrameVote.normalized(fragments[next].text)
                next += 1
            }
            guard spelled == row, !group.isEmpty else { return nil }
            groups.append(group)
        }
        return next == fragments.count ? groups : nil
    }
}

/// One image's read and its weight in the vote.
private struct FrameVote {
    let result: OCRResult
    let weight: Double
    let isKey: Bool
    let rows: [String]

    init(result: OCRResult, weight: Double, isKey: Bool) {
        self.result = result
        self.weight = weight
        self.isKey = isKey
        rows = result.extractedText.isEmpty ? [] : result.extractedText.components(separatedBy: "\n")
    }

    static func normalized(_ row: String) -> String {
        row.replacingOccurrences(of: " ", with: "")
    }
}

/// Votes for one spelling of a row.
private struct RowTally {
    let text: String
    var weight = 0.0
    var hasKey = false
    var confidence = 0.0

    func ranksBelow(_ other: RowTally) -> Bool {
        if weight != other.weight { return weight < other.weight }
        if hasKey != other.hasKey { return !hasKey }
        if confidence != other.confidence { return confidence < other.confidence }
        return false
    }
}

/// Reads written from concurrent decodes.
private final class FrameReads: @unchecked Sendable {
    let images: [CGImage]
    private var stored: [OCRResult?]
    private let lock = NSLock()

    init(images: [CGImage]) {
        self.images = images
        stored = Array(repeating: nil, count: images.count)
    }

    var results: [OCRResult?] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func store(_ result: OCRResult, at index: Int) {
        lock.lock()
        stored[index] = result
        lock.unlock()
    }
}

/// A test probe value that concurrent decodes may write.
private final class LockedProbe: @unchecked Sendable {
    private var stored: Int?
    private let lock = NSLock()

    var value: Int? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }
        set {
            lock.lock()
            stored = newValue
            lock.unlock()
        }
    }
}
