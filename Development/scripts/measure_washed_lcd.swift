#!/usr/bin/env swift
// Measure the washed-LCD dark mask (#591).
//
// The pump photos stay in schatt/CarManager. Do not copy them into this repo.
// Another machine with that checkout can rerun:
//
//   swift Development/scripts/measure_washed_lcd.swift <photo.jpg> [x y w h]
//
// Omit the crop to use the whole image. The scenario 1 photo is 4032×3024.
// A hand-sized crop of its glass, including the dark bezel, is
// x=775 y=785 w=2390 h=1130.
//
// 8.7.0 used a 41-pixel window and a corner ceiling. On that crop the corners
// were 111, 113, 123, 169, so the ceiling was 114 while the glass was about
// 160–220 and digit cores were about 45–140.
//
// This script counts seeds of the current mask: 14 levels under the local
// mean, and under 93% of that mean. The window is max(21, min(side)/8), odd,
// with no cap. It then grows same-level ink and reports whether a sealed
// glass is large enough to drop the ink outside it. A downscaled mask is
// written to build/washed-lcd-mask.png (kept ink black, dropped ink dark
// gray, sealed glass light gray, outside white).

import CoreGraphics
import Foundation
import ImageIO

let args = CommandLine.arguments
guard args.count == 2 || args.count == 6 else {
    fputs("usage: measure_washed_lcd.swift <image> [x y w h]\n", stderr)
    exit(2)
}

let url = URL(fileURLWithPath: args[1])
guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fputs("unreadable image\n", stderr)
    exit(1)
}

let fullW = image.width
let fullH = image.height
let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: fullW * fullH)
defer { pointer.deallocate() }
guard let context = CGContext(
    data: pointer,
    width: fullW,
    height: fullH,
    bitsPerComponent: 8,
    bytesPerRow: fullW,
    space: CGColorSpaceCreateDeviceGray(),
    bitmapInfo: CGImageAlphaInfo.none.rawValue
) else {
    fputs("no gray context\n", stderr)
    exit(1)
}
context.interpolationQuality = .none
context.draw(image, in: CGRect(x: 0, y: 0, width: fullW, height: fullH))

let cropX: Int
let cropY: Int
let cropW: Int
let cropH: Int
if args.count == 6 {
    cropX = Int(args[2]) ?? 0
    cropY = Int(args[3]) ?? 0
    cropW = Int(args[4]) ?? fullW
    cropH = Int(args[5]) ?? fullH
} else {
    cropX = 0
    cropY = 0
    cropW = fullW
    cropH = fullH
}
guard cropX >= 0, cropY >= 0, cropW > 0, cropH > 0,
      cropX + cropW <= fullW, cropY + cropH <= fullH else {
    fputs("crop is outside \(fullW)x\(fullH)\n", stderr)
    exit(1)
}

var pixels = [UInt8](repeating: 0, count: cropW * cropH)
for y in 0..<cropH {
    for x in 0..<cropW {
        pixels[y * cropW + x] = pointer[(cropY + y) * fullW + (cropX + x)]
    }
}

let corners = [
    pixels[0],
    pixels[cropW - 1],
    pixels[(cropH - 1) * cropW],
    pixels[pixels.count - 1]
].sorted()
let cornerBackground = Int(corners[corners.count / 2])
let cornerCeiling = cornerBackground * 93 / 100
let margin = 14
var window = max(21, min(cropW, cropH) / 8)
if window % 2 == 0 { window += 1 }
let radius = window / 2

let stride = cropW + 1
var table = [UInt64](repeating: 0, count: stride * (cropH + 1))
for y in 1...cropH {
    var row = UInt64(0)
    for x in 1...cropW {
        row += UInt64(pixels[(y - 1) * cropW + (x - 1)])
        table[y * stride + x] = table[(y - 1) * stride + x] + row
    }
}

func regionSum(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int) -> UInt64 {
    let bottomRight = table[y1 * stride + x1]
    let above = table[y0 * stride + x1]
    let left = table[y1 * stride + x0]
    let corner = table[y0 * stride + x0]
    return bottomRight &- above &- left &+ corner
}

var seeds = 0
var cornerWouldDrop = 0
var rowsWithInk = 0
for y in 0..<cropH {
    var rowInk = 0
    for x in 0..<cropW {
        let x0 = max(0, x - radius)
        let y0 = max(0, y - radius)
        let x1 = min(cropW, x + radius + 1)
        let y1 = min(cropH, y + radius + 1)
        let area = (x1 - x0) * (y1 - y0)
        let sum = regionSum(x0, y0, x1, y1)
        let mean = Int(sum / UInt64(max(area, 1)))
        let pixel = Int(pixels[y * cropW + x])
        let localCeiling = mean * 93 / 100
        let seed = pixel + margin < mean && pixel < localCeiling
        if seed && pixel >= cornerCeiling { cornerWouldDrop += 1 }
        if seed {
            seeds += 1
            rowInk += 1
        }
    }
    if rowInk > 0 { rowsWithInk += 1 }
}

print("image \(fullW)x\(fullH) crop \(cropX),\(cropY) \(cropW)x\(cropH)")
print("corners \(corners.map(String.init).joined(separator: ","))")
print("corner background \(cornerBackground) old ceiling \(cornerCeiling)")
print("window \(window) margin \(margin)")
print("seeds \(seeds)")
print("seeds the corner ceiling would drop \(cornerWouldDrop)")
print("rows with ink \(rowsWithInk)")

let sameInk = 4
var dark = [Bool](repeating: false, count: pixels.count)
var reach = [Bool](repeating: false, count: pixels.count)
for y in 0..<cropH {
    for x in 0..<cropW {
        let x0 = max(0, x - radius)
        let y0 = max(0, y - radius)
        let x1 = min(cropW, x + radius + 1)
        let y1 = min(cropH, y + radius + 1)
        let area = (x1 - x0) * (y1 - y0)
        let sum = regionSum(x0, y0, x1, y1)
        let mean = Int(sum / UInt64(max(area, 1)))
        let pixel = Int(pixels[y * cropW + x])
        let index = y * cropW + x
        let underGlass = pixel < mean * 93 / 100
        dark[index] = underGlass && pixel + margin < mean
        reach[index] = underGlass
    }
}
var grown = dark
var growQueue: [(index: Int, level: Int)] = []
for index in dark.indices where dark[index] {
    growQueue.append((index, Int(pixels[index])))
}
var growHead = 0
while growHead < growQueue.count {
    let current = growQueue[growHead]
    growHead += 1
    let x = current.index % cropW
    let y = current.index / cropW
    for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
        guard nx >= 0, ny >= 0, nx < cropW, ny < cropH else { continue }
        let next = ny * cropW + nx
        let level = Int(pixels[next])
        guard reach[next], !grown[next], abs(level - current.level) <= sameInk else { continue }
        grown[next] = true
        growQueue.append((next, current.level))
    }
}

var outside = [Bool](repeating: false, count: pixels.count)
var borderQueue: [Int] = []
func pushOutside(_ x: Int, _ y: Int) {
    guard x >= 0, y >= 0, x < cropW, y < cropH else { return }
    let index = y * cropW + x
    guard !grown[index], !outside[index] else { return }
    outside[index] = true
    borderQueue.append(index)
}
for x in 0..<cropW {
    pushOutside(x, 0)
    pushOutside(x, cropH - 1)
}
for y in 0..<cropH {
    pushOutside(0, y)
    pushOutside(cropW - 1, y)
}
var borderHead = 0
while borderHead < borderQueue.count {
    let index = borderQueue[borderHead]
    borderHead += 1
    let x = index % cropW
    let y = index / cropW
    pushOutside(x - 1, y)
    pushOutside(x + 1, y)
    pushOutside(x, y - 1)
    pushOutside(x, y + 1)
}

var seenGlass = [Bool](repeating: false, count: pixels.count)
var bestArea = 0
var bestMinX = 0
var bestMinY = 0
var bestMaxX = 0
var bestMaxY = 0
for start in 0..<pixels.count where !grown[start] && !outside[start] && !seenGlass[start] {
    var component = [start]
    seenGlass[start] = true
    var compHead = 0
    var minX = start % cropW
    var maxX = minX
    var minY = start / cropW
    var maxY = minY
    while compHead < component.count {
        let index = component[compHead]
        compHead += 1
        let x = index % cropW
        let y = index / cropW
        minX = min(minX, x)
        maxX = max(maxX, x)
        minY = min(minY, y)
        maxY = max(maxY, y)
        for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
            guard nx >= 0, ny >= 0, nx < cropW, ny < cropH else { continue }
            let next = ny * cropW + nx
            guard !grown[next], !outside[next], !seenGlass[next] else { continue }
            seenGlass[next] = true
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

let count = pixels.count
let keepsGlass = bestArea * 8 >= count
var kept = grown
var dropped = 0
if keepsGlass {
    for index in kept.indices where kept[index] {
        let x = index % cropW
        let y = index / cropW
        if x < bestMinX || x > bestMaxX || y < bestMinY || y > bestMaxY {
            kept[index] = false
            dropped += 1
        }
    }
}

var seenInk = [Bool](repeating: false, count: pixels.count)
var components: [(area: Int, minX: Int, minY: Int, maxX: Int, maxY: Int)] = []
for start in 0..<pixels.count where kept[start] && !seenInk[start] {
    var queue = [start]
    seenInk[start] = true
    var head = 0
    var minX = start % cropW
    var maxX = minX
    var minY = start / cropW
    var maxY = minY
    while head < queue.count {
        let index = queue[head]
        head += 1
        let x = index % cropW
        let y = index / cropW
        minX = min(minX, x)
        maxX = max(maxX, x)
        minY = min(minY, y)
        maxY = max(maxY, y)
        for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
            guard nx >= 0, ny >= 0, nx < cropW, ny < cropH else { continue }
            let next = ny * cropW + nx
            guard kept[next], !seenInk[next] else { continue }
            seenInk[next] = true
            queue.append(next)
        }
    }
    components.append((queue.count, minX, minY, maxX, maxY))
}
components.sort { $0.area > $1.area }

let grownInk = grown.filter { $0 }.count
let outsideCount = outside.filter { $0 }.count
print("grown ink \(grownInk)")
print("outside non-ink \(outsideCount)")
print("best sealed area \(bestArea) box \(bestMinX),\(bestMinY) \(bestMaxX - bestMinX + 1)x\(bestMaxY - bestMinY + 1)")
print("keeps glass \(keepsGlass) dropped ink \(dropped)")
print("components \(components.count)")
for component in components.prefix(8) {
    let w = component.maxX - component.minX + 1
    let h = component.maxY - component.minY + 1
    print("component \(component.area) @\(component.minX),\(component.minY) \(w)x\(h)")
}

func largestSealed(in ink: [Bool]) -> (area: Int, minX: Int, minY: Int, maxX: Int, maxY: Int) {
    var reached = [Bool](repeating: false, count: ink.count)
    var queue: [Int] = []
    func push(_ x: Int, _ y: Int) {
        guard x >= 0, y >= 0, x < cropW, y < cropH else { return }
        let index = y * cropW + x
        guard !ink[index], !reached[index] else { return }
        reached[index] = true
        queue.append(index)
    }
    for x in 0..<cropW {
        push(x, 0)
        push(x, cropH - 1)
    }
    for y in 0..<cropH {
        push(0, y)
        push(cropW - 1, y)
    }
    var head = 0
    while head < queue.count {
        let index = queue[head]
        head += 1
        let x = index % cropW
        let y = index / cropW
        push(x - 1, y)
        push(x + 1, y)
        push(x, y - 1)
        push(x, y + 1)
    }
    var seen = [Bool](repeating: false, count: ink.count)
    var best = (area: 0, minX: 0, minY: 0, maxX: 0, maxY: 0)
    for start in 0..<ink.count where !ink[start] && !reached[start] && !seen[start] {
        var component = [start]
        seen[start] = true
        var compHead = 0
        var minX = start % cropW
        var maxX = minX
        var minY = start / cropW
        var maxY = minY
        while compHead < component.count {
            let index = component[compHead]
            compHead += 1
            let x = index % cropW
            let y = index / cropW
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
            for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
                guard nx >= 0, ny >= 0, nx < cropW, ny < cropH else { continue }
                let next = ny * cropW + nx
                guard !ink[next], !reached[next], !seen[next] else { continue }
                seen[next] = true
                component.append(next)
            }
        }
        if component.count > best.area {
            best = (component.count, minX, minY, maxX, maxY)
        }
    }
    return best
}

var dilated = grown
for radius in 1...24 {
    var next = dilated
    for y in 0..<cropH {
        for x in 0..<cropW where dilated[y * cropW + x] {
            if x > 0 { next[y * cropW + x - 1] = true }
            if x + 1 < cropW { next[y * cropW + x + 1] = true }
            if y > 0 { next[(y - 1) * cropW + x] = true }
            if y + 1 < cropH { next[(y + 1) * cropW + x] = true }
        }
    }
    dilated = next
    if radius == 1 || radius == 2 || radius % 4 == 0 {
        let sealed = largestSealed(in: dilated)
        let w = sealed.area == 0 ? 0 : sealed.maxX - sealed.minX + 1
        let h = sealed.area == 0 ? 0 : sealed.maxY - sealed.minY + 1
        let glass = sealed.area * 8 >= count
        print("dilate \(radius) sealed \(sealed.area) @\(sealed.minX),\(sealed.minY) \(w)x\(h) glass \(glass)")
    }
}

var columnInk = [Int](repeating: 0, count: cropW)
for index in grown.indices where grown[index] {
    columnInk[index % cropW] += 1
}
for percent in [95, 85, 70, 50] {
    var rowInk = [Int](repeating: 0, count: cropH)
    var keptColumns = 0
    for x in 0..<cropW where columnInk[x] * 100 < cropH * percent {
        keptColumns += 1
        for y in 0..<cropH where grown[y * cropW + x] {
            rowInk[y] += 1
        }
    }
    func bands(where floor: Int) -> [(Int, Int, Int)] {
        var found: [(Int, Int, Int)] = []
        var start: Int?
        var peak = 0
        for y in 0..<cropH {
            if rowInk[y] >= floor {
                if start == nil { start = y }
                peak = max(peak, rowInk[y])
            } else if let open = start {
                found.append((open, y, peak))
                start = nil
                peak = 0
            }
        }
        if let open = start { found.append((open, cropH, peak)) }
        return found
    }
    for floor in [1, 40, 120] {
        let found = bands(where: floor)
        let described = found.map { "\($0.0)-\($0.1) peak \($0.2)" }.joined(separator: " | ")
        print("drop columns >= \(percent)% ink, floor \(floor), kept \(keptColumns), bands \(found.count): \(described)")
    }
}

let centerX0 = cropW / 5
let centerX1 = cropW * 4 / 5
print("central columns \(centerX0)-\(centerX1)")
var bandY = 0
while bandY < cropH {
    let bandEnd = min(cropH, bandY + 40)
    var loose = 0
    var strict = 0
    for y in bandY..<bandEnd {
        for x in centerX0..<centerX1 {
            let index = y * cropW + x
            if grown[index] { loose += 1 }
            let x0 = max(0, x - radius)
            let y0 = max(0, y - radius)
            let x1 = min(cropW, x + radius + 1)
            let y1 = min(cropH, y + radius + 1)
            let area = (x1 - x0) * (y1 - y0)
            let mean = Int(regionSum(x0, y0, x1, y1) / UInt64(max(area, 1)))
            let pixel = Int(pixels[index])
            if pixel + 40 < mean && pixel < mean * 80 / 100 { strict += 1 }
        }
    }
    print("y \(bandY)-\(bandEnd) loose \(loose) strict \(strict)")
    bandY += 40
}

let scale = 4
let outW = max(1, (cropW + scale - 1) / scale)
let outH = max(1, (cropH + scale - 1) / scale)
var preview = [UInt8](repeating: 255, count: outW * outH)
for y in 0..<cropH {
    for x in 0..<cropW {
        let index = y * cropW + x
        let value: UInt8
        if kept[index] {
            value = 0
        } else if grown[index] {
            value = 70
        } else if !outside[index] {
            value = 180
        } else {
            value = 255
        }
        let out = (y / scale) * outW + (x / scale)
        if value < preview[out] { preview[out] = value }
    }
}
try? FileManager.default.createDirectory(atPath: "build", withIntermediateDirectories: true)
let previewURL = URL(fileURLWithPath: "build/washed-lcd-mask.png")
if let provider = CGDataProvider(data: Data(preview) as CFData),
   let cg = CGImage(
    width: outW,
    height: outH,
    bitsPerComponent: 8,
    bitsPerPixel: 8,
    bytesPerRow: outW,
    space: CGColorSpaceCreateDeviceGray(),
    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
    provider: provider,
    decode: nil,
    shouldInterpolate: false,
    intent: .defaultIntent
   ),
   let destination = CGImageDestinationCreateWithURL(previewURL as CFURL, "public.png" as CFString, 1, nil) {
    CGImageDestinationAddImage(destination, cg, nil)
    if CGImageDestinationFinalize(destination) {
        print("mask \(previewURL.path) \(outW)x\(outH)")
    }
}
