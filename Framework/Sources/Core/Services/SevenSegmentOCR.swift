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

    fileprivate static func match(_ pattern: SevenSegmentPattern) -> (character: Character, confidence: Float)? {
        if pattern.rawValue == 0 {
            return nil
        }
        let scored = templates.map { (character: $0.0, distance: ($0.1 ^ pattern.rawValue).nonzeroBitCount) }
        guard let best = scored.map(\.distance).min() else { return nil }
        let winners = scored.filter { $0.distance == best }
        guard winners.count == 1, let winner = winners.first else {
            return ("_", 0)
        }
        if best == 0 {
            return (winner.character, 1)
        }
        return (winner.character, Float(7 - best) / 7)
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
        let limit = Int(max(0, maximumDegrees).rounded(.down))
        guard limit > 0 else { return buffer }
        let small = buffer.fitted(maxSide: 280)
        let uprightScore = score(small)
        var bestAngle = 0
        var bestScore = uprightScore
        for angle in -limit...limit where angle != 0 {
            let value = score(small.rotated(degrees: Double(angle)))
            if value > bestScore {
                bestScore = value
                bestAngle = angle
            }
        }
        if bestAngle == 0 || uprightScore * 100 >= bestScore * 98 {
            return buffer
        }
        return buffer.rotated(degrees: Double(bestAngle))
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
        let digitWidth = median(tall.map(\.width)) ?? digitHeight
        let baseline = median(tall.map(\.maxY)) ?? band.1
        let frameTop = median(tall.map(\.minY)) ?? band.0
        return boxes.compactMap { box in
            classify(
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
        }
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
        if box.height * 100 >= digitHeight * 55, box.width * 100 <= box.height * 30 {
            return Cell(box: box, character: "1", confidence: 1, band: bandIndex)
        }
        if box.height * 100 >= digitHeight * 50,
           box.width * 100 >= digitHeight * 40,
           (coverage(mask, box: box, width: width) > 0.62 || inkFraction(buffer, box: box, darkInk: darkInk) > 0.62) {
            return nil
        }
        if box.height * 100 < digitHeight * 45, box.width * 100 < digitHeight * 30 {
            guard inkFraction(buffer, box: box, darkInk: darkInk) > 0.5 else { return nil }
            let comma = box.maxY > baseline + max(2, digitHeight / 12)
            return Cell(box: box, character: comma ? "," : ".", confidence: 1, band: bandIndex)
        }
        let frame = PixelBox(
            minX: box.midX - max(digitWidth, box.width) / 2,
            minY: frameTop,
            maxX: box.midX + max(digitWidth, box.width) / 2,
            maxY: frameTop + max(digitHeight, 1)
        )
        if box.height * 100 < digitHeight * 70, coverage(mask, box: frame, width: width) > 0.62 {
            return nil
        }
        let pattern = sample(mask, box: box.height * 100 < digitHeight * 70 ? frame : box, width: width)
        guard let glyph = SevenSegmentGlyph.match(pattern) else { return nil }
        return Cell(box: box, character: glyph.character, confidence: glyph.confidence, band: bandIndex)
    }

    private static func sample(_ mask: Mask, box: PixelBox, width: Int) -> SevenSegmentPattern {
        let windows: [(SevenSegmentPattern, Double, Double, Double, Double)] = [
            (.a, 0.22, 0.00, 0.78, 0.16),
            (.b, 0.72, 0.16, 1.00, 0.40),
            (.c, 0.72, 0.60, 1.00, 0.86),
            (.d, 0.22, 0.84, 0.78, 1.00),
            (.e, 0.00, 0.60, 0.28, 0.86),
            (.f, 0.00, 0.16, 0.28, 0.40),
            (.g, 0.28, 0.42, 0.72, 0.58)
        ]
        return windows.reduce(into: SevenSegmentPattern()) { pattern, window in
            if regionCoverage(mask, box: box, width: width, window: window) > 0.30 {
                pattern.formUnion(window.0)
            }
        }
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

    private func masks() -> (dark: Mask, light: Mask) {
        let window = oddWindow(min(width, height))
        let radius = window / 2
        let table = integral(pixels, width: width, height: height)
        var dark = [Bool](repeating: false, count: pixels.count)
        var light = [Bool](repeating: false, count: pixels.count)
        let margin = 14
        let background = Int(cornerFill())
        let brightCeiling = background * 93 / 100
        for y in 0..<height {
            for x in 0..<width {
                let x0 = max(0, x - radius)
                let y0 = max(0, y - radius)
                let x1 = min(width, x + radius + 1)
                let y1 = min(height, y + radius + 1)
                let area = (x1 - x0) * (y1 - y0)
                let sum = regionSum(table, width: width, x0: x0, y0: y0, x1: x1, y1: y1)
                let mean = Int(sum / UInt64(max(area, 1)))
                let pixel = Int(pixels[y * width + x])
                let index = y * width + x
                // A glare band lifts the background next to it, so those
                // still-background pixels fall just under the local mean.
                // Dark ink stays below most of that background.
                dark[index] = pixel + margin < mean && pixel < brightCeiling
                light[index] = pixel > mean + margin
            }
        }
        return (Mask(bits: dark, width: width, height: height), Mask(bits: light, width: width, height: height))
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
        let masks = buffer.masks()
        let primaryIsDark = prefersDark(masks.dark, masks.light)
        let primary = primaryIsDark ? masks.dark : masks.light
        let paintedMarks = buffer.extremeMarkMask()
        let mergedBands = merge(runs(primary.rowSums), whenGapBelow: 0)
        let measured = mergedBands.map { band -> (band: (Int, Int), cells: [Cell]) in
            (band, cells(in: band, mask: primary, buffer: buffer, bandIndex: 0, darkInk: primaryIsDark))
        }
        let tallHeights = measured.flatMap(\.cells).filter { $0.height > 0 }.map(\.height).sorted()
        let cellHeight = tallHeights.isEmpty ? 1 : tallHeights[tallHeights.count / 2]
        let splitBands = merge(runs(primary.rowSums), whenGapBelow: max(1, cellHeight / 2))
        return splitBands.compactMap { band -> [OCRRecognizedText]? in
            let found = cells(in: band, mask: primary, buffer: buffer, bandIndex: 0, darkInk: primaryIsDark)
            let marks = oppositeMarks(in: band, secondary: paintedMarks, existing: found, buffer: buffer, bandIndex: 0)
            let texts = recognizedGroups(found + marks, width: buffer.width, height: buffer.height)
            return texts.isEmpty ? nil : texts
        }
    }
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
    return raw.flatMap { span in
        let spanWidth = span.1 - span.0
        guard typical > 0, spanWidth > typical * 2 else { return [span] }
        let peak = (span.0..<span.1).map { sums[$0] }.max() ?? 0
        let floor = max(1, peak / 8)
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
        return pieces.isEmpty ? [span] : pieces
    }
}

private func tightBox(_ mask: Mask, x0: Int, x1: Int, y0: Int, y1: Int, width: Int) -> PixelBox {
    var minY = y1
    var maxY = y0
    let lower = max(0, y0)
    let upper = min(mask.height, y1)
    let left = max(0, x0)
    let right = min(width, x1)
    for y in lower..<upper {
        let start = y * width
        var hit = false
        for x in left..<right where mask.bits[start + x] {
            hit = true
            break
        }
        if hit {
            minY = min(minY, y)
            maxY = max(maxY, y + 1)
        }
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

private func inkFraction(_ buffer: GrayBuffer, box: PixelBox, darkInk: Bool) -> Float {
    var ink = 0
    var total = 0
    let left = max(0, box.minX)
    let right = min(buffer.width, box.maxX)
    let lower = max(0, box.minY)
    let upper = min(buffer.height, box.maxY)
    guard right > left, upper > lower else { return 0 }
    let background = Int(buffer.cornerFill())
    for y in lower..<upper {
        let start = y * buffer.width
        for x in left..<right {
            total += 1
            let pixel = Int(buffer.pixels[start + x])
            let countsAsInk = darkInk
                ? pixel * 2 < background
                : pixel * 2 > background + 255
            if countsAsInk {
                ink += 1
            }
        }
    }
    return total == 0 ? 0 : Float(ink) / Float(total)
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

private func regionCoverage(
    _ mask: Mask,
    box: PixelBox,
    width: Int,
    window: (SevenSegmentPattern, Double, Double, Double, Double)
) -> Float {
    let x0 = box.minX + Int((window.1 * Double(box.width)).rounded(.down))
    let y0 = box.minY + Int((window.2 * Double(box.height)).rounded(.down))
    let x1 = box.minX + Int((window.3 * Double(box.width)).rounded(.up))
    let y1 = box.minY + Int((window.4 * Double(box.height)).rounded(.up))
    return coverage(mask, box: PixelBox(minX: x0, minY: y0, maxX: max(x0 + 1, x1), maxY: max(y0 + 1, y1)), width: width)
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
    // More column runs inside each row. A connected halo is one fat run, so
    // ink-per-run selects the halo and the digits disappear.
    let darkRuns = bandedColumnRuns(dark)
    let lightRuns = bandedColumnRuns(light)
    if darkRuns != lightRuns {
        return darkRuns > lightRuns
    }
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

private func oddWindow(_ side: Int) -> Int {
    var window = max(21, side / 8)
    if window % 2 == 0 { window += 1 }
    return min(window, 41)
}

private func integral(_ pixels: [UInt8], width: Int, height: Int) -> [UInt64] {
    let stride = width + 1
    var table = [UInt64](repeating: 0, count: stride * (height + 1))
    for y in 1...height {
        var row = UInt64(0)
        for x in 1...width {
            row += UInt64(pixels[(y - 1) * width + (x - 1)])
            table[y * stride + x] = table[(y - 1) * stride + x] + row
        }
    }
    return table
}

private func regionSum(_ table: [UInt64], width: Int, x0: Int, y0: Int, x1: Int, y1: Int) -> UInt64 {
    let stride = width + 1
    let bottomRight = table[y1 * stride + x1]
    let above = table[y0 * stride + x1]
    let left = table[y1 * stride + x0]
    let corner = table[y0 * stride + x0]
    // Either subtracted corner can exceed the partial difference. The region sum
    // itself stays inside UInt64; wrapping keeps that sum without trapping.
    return bottomRight &- above &- left &+ corner
}
