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
    fileprivate static func nearest(_ pattern: SevenSegmentPattern) -> (character: Character, distance: Int)? {
        if pattern.rawValue == 0 { return nil }
        var bestDistance = Int.max
        var winner: (Character, Int)?
        var tied = false
        for template in templates {
            let distance = (template.1 ^ pattern.rawValue).nonzeroBitCount
            if distance < bestDistance {
                bestDistance = distance
                winner = (template.0, distance)
                tied = false
            } else if distance == bestDistance {
                tied = true
            }
        }
        return tied ? nil : winner
    }

    fileprivate static func match(_ pattern: SevenSegmentPattern) -> (character: Character, confidence: Float)? {
        if pattern.rawValue == 0 { return nil }
        guard let found = nearest(pattern) else { return ("_", 0) }
        if found.distance == 0 { return (found.character, 1) }
        return (found.character, Float(7 - found.distance) / 7)
    }
}

public enum SevenSegmentOCR {
    public static func decode(cgImage: CGImage, deskewMaximumDegrees: Double = 3) -> OCRResult {
        guard let gray = GrayBuffer.read(cgImage) else {
            return OCRResult(extractedText: "", confidence: 0)
        }
        let upright = GrayBuffer.deskew(gray, maximumDegrees: deskewMaximumDegrees)
        let fragments = GrayBuffer.fragments(in: upright)
        let lines = fragments.map { row in row.map(\.text).joined(separator: "  ") }
        let extracted = lines.joined(separator: "\n")
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
        let turned = standingUp(buffer)
        let limit = Int(max(0, maximumDegrees).rounded(.down))
        guard limit > 0 else { return turned }
        let small = turned.fitted(maxSide: 280)
        let uprightScore = score(small)
        let uprightConfidence = readConfidence(small)
        var bestAngle = 0
        var bestScore = uprightScore
        for angle in -limit...limit where angle != 0 {
            let turnedSample = small.rotated(degrees: Double(angle))
            let value = score(turnedSample)
            // A tilt that lights an extra segment is a worse read, even when
            // the row sums vary more.
            if value > bestScore, readConfidence(turnedSample) >= uprightConfidence {
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

    /// Lowest cell confidence. A tilt that only adds row-sum noise scores
    /// higher and still reads worse; deskew keeps the surer angle.
    private static func readConfidence(_ buffer: GrayBuffer) -> Float {
        let cells = readRows(in: buffer).flatMap { $0 }
        guard !cells.isEmpty else { return 0 }
        return cells.map(\.confidence).min() ?? 0
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
        // A small tilt still belongs to the fine deskew. Speck rows on a
        // sideways sample read as a few wide glyphs and must not spin an
        // upright panel. A real quarter turn is mostly digits.
        let glyphs = scores[bestTurns].text.filter { $0 != "/" }
        let numbers = glyphs.filter(\.isNumber).count
        let mostlyNumbers = !glyphs.isEmpty && numbers * 2 > glyphs.count
        let enough = mostlyNumbers && scores[bestTurns].wideDigits >= max(scores[0].wideDigits + 2, 4)
        guard enough else { return buffer }
        return buffer.rotated(degrees: Double(bestTurns * 90))
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
        let rows = readRows(in: buffer)
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
        darkInk: Bool
    ) -> [Cell] {
        let columns = columnRuns(mask, y0: band.0, y1: band.1, width: buffer.width)
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
        let digitWidth = median(tall.map(\.width)) ?? digitHeight
        return boxes.compactMap { box in
            let cell = classify(
                box,
                mask: mask,
                width: buffer.width,
                digitHeight: digitHeight,
                digitWidth: digitWidth,
                baseline: baseline,
                frameTop: frameTop,
                bandIndex: bandIndex,
                buffer: buffer,
                darkInk: darkInk
            )
            if buffer.width >= 1000 {
                let pattern = sample(mask, box: box, width: buffer.width)
                let cover = coverage(mask, box: box, width: buffer.width)
                let name = cell.map { String($0.character) } ?? "drop"
                fputs(
                    "cell \(name) box \(box.minX),\(box.minY) \(box.width)x\(box.height) pat \(pattern.rawValue) cov \(cover) h \(digitHeight)\n",
                    stderr
                )
            }
            return cell
        }
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
        let baseline = median(existing.map(\.maxY)) ?? band.1
        let minimum = max(1, digitHeight / 20)
        let expanded = (max(0, band.0 - digitHeight / 2), min(buffer.height, band.1 + digitHeight / 2))
        let columns = columnRuns(secondary, y0: expanded.0, y1: expanded.1, width: buffer.width)
        return columns.compactMap { span -> Cell? in
            let box = tightBox(secondary, x0: span.0, x1: span.1, y0: expanded.0, y1: expanded.1, width: buffer.width)
            guard box.width >= minimum, box.height >= minimum else { return nil }
            guard box.width < digitHeight * 30 / 100, box.height < digitHeight * 55 / 100 else { return nil }
            if existing.contains(where: { overlap($0.box, box) > 0 }) { return nil }
            let comma = box.maxY > baseline + max(2, digitHeight / 12)
            return Cell(box: box, character: comma ? "," : ".", confidence: 1, band: bandIndex)
        }
    }

    private static func classify(
        _ box: PixelBox,
        mask: Mask,
        width: Int,
        digitHeight: Int,
        digitWidth: Int,
        baseline: Int,
        frameTop: Int,
        bandIndex: Int,
        buffer: GrayBuffer,
        darkInk: Bool
    ) -> Cell? {
        let vertical = verticalRuns(mask, box: box, width: width)
        let splitGap = vertical.count == 2 ? vertical[1].0 - vertical[0].1 : 0
        let shorterRun = vertical.count == 2
            ? min(vertical[0].1 - vertical[0].0, vertical[1].1 - vertical[1].0)
            : 0
        let colonGap = vertical.count == 2 && splitGap >= shorterRun
        if colonGap,
           box.width * 100 <= box.height * 30,
           vertical.allSatisfy({ $0.1 - $0.0 < digitHeight * 45 / 100 }) {
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
                    frameTop: frameTop,
                    bandIndex: bandIndex,
                    buffer: buffer,
                    darkInk: darkInk
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
            let comma = box.maxY > baseline + max(2, digitHeight / 12)
            return Cell(box: box, character: comma ? "," : ".", confidence: 1, band: bandIndex)
        }
        let frame = PixelBox(
            minX: box.midX - max(digitWidth, box.width) / 2,
            minY: frameTop,
            maxX: box.midX + max(digitWidth, box.width) / 2,
            maxY: frameTop + max(digitHeight, 1)
        )
        if box.height * 100 < digitHeight * 70, coverage(mask, box: frame, width: width) > solidCoverage {
            return nil
        }
        // A reflection beside the digits is wider than a glyph. A digit is taller than it is wide.
        if box.height * 100 >= digitHeight * 50, box.width * 5 > box.height * 4 {
            return nil
        }
        let sampledBox = box.height * 100 < digitHeight * 70 ? frame : box
        let pattern = sample(mask, box: sampledBox, width: width)
        guard let glyph = SevenSegmentGlyph.match(pattern) else { return nil }
        return Cell(box: box, character: glyph.character, confidence: glyph.confidence, band: bandIndex)
    }

    /// Six scanlines, as ssocr does. The center column is split into thirds
    /// for the top, middle, and bottom bars. Lines a quarter down from the
    /// top and a quarter up from the bottom are split into halves for the
    /// stems. One foreground pixel lights a segment.
    private static func sample(_ mask: Mask, box: PixelBox, width: Int) -> SevenSegmentPattern {
        let boxWidth = box.width
        let boxHeight = box.height
        guard boxWidth > 1, boxHeight > 2, width > 0 else { return [] }
        var pattern = SevenSegmentPattern()
        let midX = box.minX + boxWidth / 2
        let third = max(1, boxHeight / 3)
        if foregroundCount(mask, x: midX, y: box.minY, length: third, vertical: true) > 0 {
            pattern.formUnion(.a)
        }
        if foregroundCount(mask, x: midX, y: box.minY + third, length: third, vertical: true) > 0 {
            pattern.formUnion(.g)
        }
        let lower = box.minY + third * 2
        if foregroundCount(mask, x: midX, y: lower, length: max(1, box.maxY - lower), vertical: true) > 0 {
            pattern.formUnion(.d)
        }
        let quarter = box.minY + boxHeight / 4
        let threeQuarters = box.minY + (boxHeight * 3) / 4
        let half = boxWidth / 2
        let right = max(1, box.maxX - (midX + 1))
        if foregroundCount(mask, x: box.minX, y: quarter, length: half, vertical: false) > 0 {
            pattern.formUnion(.f)
        }
        if foregroundCount(mask, x: midX + 1, y: quarter, length: right, vertical: false) > 0 {
            pattern.formUnion(.b)
        }
        if foregroundCount(mask, x: box.minX, y: threeQuarters, length: half, vertical: false) > 0 {
            pattern.formUnion(.e)
        }
        if foregroundCount(mask, x: midX + 1, y: threeQuarters, length: right, vertical: false) > 0 {
            pattern.formUnion(.c)
        }
        return pattern
    }

    fileprivate static func group(_ cells: [Cell]) -> [[Cell]] {
        guard !cells.isEmpty else { return [] }
        let ordered = cells.sorted { $0.minX < $1.minX }
        guard ordered.count > 1 else { return [ordered] }
        let gaps = zip(ordered, ordered.dropFirst()).map { max(0, $1.minX - $0.maxX) }
        let middle = median(gaps) ?? 0
        let tallest = ordered.map(\.height).max() ?? 1
        let pitches = ordered.filter { cell in
            cell.height * 100 >= tallest * 55 && !isMark(cell.character)
        }.map(\.box.width)
        let pitch = median(pitches) ?? 0
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
        // local maximum. A wider cut marks the glass beside a glared stroke.
        // A short crop (the glare fixture is 122 on its short side) stays at
        // the tight window. A larger crop opens toward a washed stroke, and
        // the cap stays under a scaled stroke so the bezel does not swallow it.
        let shortSide = min(width, height)
        let radius = min(36, max(4, (shortSide - 96) / 8))
        let range = localRange(radius: radius)
        var dark = [Bool](repeating: false, count: pixels.count)
        var light = [Bool](repeating: false, count: pixels.count)
        for index in pixels.indices {
            let pixel = Int(pixels[index])
            let low = range.low[index]
            let high = range.high[index]
            guard high - low > inkMargin else { continue }
            let mid = low + (high - low) / 2
            dark[index] = pixel < mid && pixel + inkMargin <= high
            light[index] = pixel > mid && pixel >= low + inkMargin
        }
        let darkMask = Mask(bits: dark, width: width, height: height)
        let lightMask = Mask(bits: light, width: width, height: height)
        return (darkMask, lightMask, darkMask, lightMask)
    }

    /// Min and max inside a square window. A square window separates into a
    /// horizontal pass and a vertical pass.
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
                for sample in x0...x1 {
                    let level = Int(pixels[row + sample])
                    if level < low { low = level }
                    if level > high { high = level }
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
                for sample in y0...y1 {
                    let index = sample * width + x
                    if horizontalLow[index] < columnLow { columnLow = horizontalLow[index] }
                    if horizontalHigh[index] > columnHigh { columnHigh = horizontalHigh[index] }
                }
                let index = y * width + x
                low[index] = columnLow
                high[index] = columnHigh
            }
        }
        return (low, high)
    }

    private func fitted(maxSide: Int) -> GrayBuffer {
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

    fileprivate func extremeMarkMask() -> Mask {
        Mask(
            bits: pixels.map { $0 <= 10 || $0 >= 252 },
            width: width,
            height: height
        )
    }
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
}

private func recognizedGroups(_ cells: [Cell], width: Int, height: Int) -> [OCRRecognizedText] {
    let pieces = GrayBuffer.group(cells)
    return pieces.map { group in
        let text = String(group.map(\.character))
        let confidence = group.map(\.confidence).min() ?? 0
        let minX = group.map(\.minX).min() ?? 0
        let maxX = group.map(\.maxX).max() ?? 0
        let minY = group.map(\.minY).min() ?? 0
        let maxY = group.map(\.maxY).max() ?? 0
        return OCRRecognizedText(
            text: text,
            boundingBox: CGRect(
                x: CGFloat(minX) / CGFloat(width),
                y: 1 - CGFloat(maxY) / CGFloat(height),
                width: CGFloat(max(1, maxX - minX)) / CGFloat(width),
                height: CGFloat(max(1, maxY - minY)) / CGFloat(height)
            ),
            confidence: confidence,
            role: .segment
        )
    }
}

private extension GrayBuffer {
    static func fragments(in buffer: GrayBuffer) -> [[OCRRecognizedText]] {
        readRows(in: buffer).compactMap { row in
            let texts = recognizedGroups(row, width: buffer.width, height: buffer.height)
            return texts.isEmpty ? nil : texts
        }
    }

    static func readRows(in buffer: GrayBuffer) -> [[Cell]] {
        let raw = buffer.masks()
        // A frame inside the crop seals the glass. Ink outside that glass is the bezel.
        let sealed = (dark: keepingInteriorInk(raw.dark), light: keepingInteriorInk(raw.light))
        // A dark bezel that does touch the crop edge would outline the glass as one zero.
        let masks = (dark: clearingBorderComponents(sealed.dark), light: clearingBorderComponents(sealed.light))
        let sealedCore = (dark: keepingInteriorInk(raw.darkCore), light: keepingInteriorInk(raw.lightCore))
        let cores = (dark: clearingBorderComponents(sealedCore.dark), light: clearingBorderComponents(sealedCore.light))
        let darkChoice = polarity(isDark: true, loose: masks.dark, core: cores.dark)
        let lightChoice = polarity(isDark: false, loose: masks.light, core: cores.light)
        let chosen: (isDark: Bool, glyphs: Mask, bandSource: Mask)
        if darkChoice.opens != lightChoice.opens {
            chosen = darkChoice.opens ? darkChoice.reading : lightChoice.reading
        } else if prefersDark(masks.dark, masks.light) {
            chosen = darkChoice.reading
        } else {
            chosen = lightChoice.reading
        }
        let primaryIsDark = chosen.isDark
        let glyphs = chosen.glyphs
        let bandSource = chosen.bandSource
        let opened = darkChoice.opens || lightChoice.opens
        if buffer.width >= 1000 {
            let ink = glyphs.bits.filter { $0 }.count
            fputs(
                "read \(buffer.width)x\(buffer.height) dark=\(primaryIsDark) opened=\(opened) ink=\(ink)\n",
                stderr
            )
        }
        let bandSums = opened ? digitRowSums(bandSource.rowSums) : bandSource.rowSums
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
            return (band, cells(in: band, mask: glyphs, buffer: buffer, bandIndex: 0, darkInk: primaryIsDark))
        }
        let tallHeights = measured.flatMap(\.cells).filter { $0.height > 0 }.map(\.height).sorted()
        let cellHeight = tallHeights.isEmpty ? 1 : tallHeights[tallHeights.count / 2]
        // merge treats a zero limit as "pick a default", which would close
        // the gap this split just opened.
        let splitBands = opened
            ? merge(solidBands, whenGapBelow: max(2, buffer.height / 40))
            : (separated.count > foundBands.count
                ? separated
                : merge(separated, whenGapBelow: max(1, cellHeight / 2)))
        if buffer.width >= 1000 {
            let listed = splitBands.map { "\($0.0)-\($0.1)" }.joined(separator: ",")
            fputs("bands \(listed)\n", stderr)
        }
        return splitBands.compactMap { band -> [Cell]? in
            let found = cells(
                in: band,
                mask: glyphs,
                buffer: buffer,
                bandIndex: 0,
                darkInk: primaryIsDark
            )
            let marks = opened
                ? []
                : oppositeMarks(in: band, secondary: paintedMarks, existing: found, buffer: buffer, bandIndex: 0)
            let dots = baselineDots(in: band, mask: glyphs, cells: found, width: buffer.width, bandIndex: 0)
            let row = found + marks + dots
            return row.isEmpty ? nil : row
        }
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
    core: Mask
) -> (opens: Bool, reading: (isDark: Bool, glyphs: Mask, bandSource: Mask)) {
    let span = digitColumnSpan(core)
    let limitedCore = span.map { cleared($0, mask: core) } ?? core
    let looseTall = runs(loose.rowSums).map { $0.1 - $0.0 }.max() ?? 0
    let limitedTall = runs(limitedCore.rowSums).map { $0.1 - $0.0 }.max() ?? 0
    let fills = looseTall * 100 > loose.height * 70
    guard let span, fills, limitedTall * 2 < looseTall else {
        return (false, (isDark, loose, loose))
    }
    // The loose mask still fills the gap inside the span. Row boundaries
    // stay on the thin core so gap specks are not thickened into a join.
    // Glyphs use a few pixels of thickness so the stroke is solid.
    let radius = max(2, core.height / 180)
    let thick = cleared(span, mask: dilate(limitedCore, radius: radius))
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

private func columnRuns(_ mask: Mask, y0: Int, y1: Int, width: Int) -> [(Int, Int)] {
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
    return raw.flatMap { span in
        let spanWidth = span.1 - span.0
        // A digit is taller than it is wide. A 4 has no top or bottom bar, so
        // its ink band is shorter than the cell, and the old 0.7 ratio split
        // that one glyph at the crossbar. Two digits side by side are wider
        // than the band is tall.
        let widerThanADigit = spanWidth > bandHeight
        guard widerThanADigit || (typical > 0 && spanWidth > typical * 2) else { return [span] }
        let peak = (span.0..<span.1).map { sums[$0] }.max() ?? 0
        // A horizontal bar is much thinner than a flooded stem. peak/5 cut the
        // bar and split one washed digit. The gap between digits still falls
        // through a lower floor.
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
        return joiningBridgedPieces(split, mask: mask, y0: y0, y1: y1, bandHeight: bandHeight)
    }
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
    let narrow = bandHeight / 2
    let gapLimit = max(1, bandHeight / 8)
    for piece in pieces.dropFirst() {
        let gap = piece.0 - previous.1
        let leftWidth = previous.1 - previous.0
        let rightWidth = piece.1 - piece.0
        let combined = piece.1 - previous.0
        let bridged = leftWidth < narrow
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
    if box.minY - 1 >= 0 {
        for x in left...right { add(x, box.minY - 1) }
    }
    if box.maxY < buffer.height {
        for x in left...right { add(x, box.maxY) }
    }
    for y in box.minY..<box.maxY {
        add(left, y)
        add(right, y)
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

private func foregroundCount(
    _ mask: Mask,
    x: Int,
    y: Int,
    length: Int,
    vertical: Bool
) -> Int {
    guard length > 0 else { return 0 }
    var count = 0
    if vertical {
        guard x >= 0, x < mask.width else { return 0 }
        let start = max(0, y)
        let end = min(mask.height, y + length)
        for row in start..<end where mask.bits[row * mask.width + x] {
            count += 1
        }
    } else {
        guard y >= 0, y < mask.height else { return 0 }
        let start = max(0, x)
        let end = min(mask.width, x + length)
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
