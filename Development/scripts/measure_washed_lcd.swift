#!/usr/bin/env swift
// Measure why SevenSegmentOCR drops washed LCD ink (#591).
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
// Measured on that crop, 2026-10-22:
//   corners 111, 113, 123, 169 → corner background 123, ceiling 114
//   glass behind the digits is about 160–220
//   digit cores are about 45–140, so many of them are darker than the glass
//   and still brighter than the corner ceiling
//
// The script counts pixels the 8.7.0 mask would keep. "Ceiling rejected" means
// the pixel is darker than its local mean by the margin, and brighter than
// cornerFill * 93/100. Those are the digits the corner gate drops.

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
let background = Int(corners[corners.count / 2])
let ceiling = background * 93 / 100
let margin = 14
var window = max(21, min(cropW, cropH) / 8)
if window % 2 == 0 { window += 1 }
window = min(window, 41)
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

var marked = 0
var marginHits = 0
var ceilingRejected = 0
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
        let darker = pixel + margin < mean
        if darker { marginHits += 1 }
        if darker && pixel >= ceiling { ceilingRejected += 1 }
        if darker && pixel < ceiling {
            marked += 1
            rowInk += 1
        }
    }
    if rowInk > 0 { rowsWithInk += 1 }
}

print("image \(fullW)x\(fullH) crop \(cropX),\(cropY) \(cropW)x\(cropH)")
print("corners \(corners.map(String.init).joined(separator: ","))")
print("corner background \(background) ceiling \(ceiling) window \(window) margin \(margin)")
print("margin hits \(marginHits)")
print("ceiling rejected \(ceilingRejected)")
print("marked \(marked)")
print("rows with ink \(rowsWithInk)")
