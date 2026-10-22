// Decode a washed LCD with SevenSegmentOCR (#591).
//
// The pump photos stay in schatt/CarManager. Do not copy them into this repo.
// Build the framework, then compile this file against it from the repo root:
//
//   swiftc -O -F build/derived/Build/Products/Debug -framework SixLayerFramework \
//     -o build/decode_washed_lcd Development/scripts/decode_washed_lcd.swift
//   DYLD_FRAMEWORK_PATH=build/derived/Build/Products/Debug \
//     build/decode_washed_lcd <photo.jpg> [x y w h]
//
// Omit the crop to use the whole image. Scenario 1 hand crop:
//   x=775 y=785 w=2390 h=1130

import CoreGraphics
import Foundation
import ImageIO
import SixLayerFramework

let args = CommandLine.arguments
guard args.count == 2 || args.count == 6 else {
    fputs("usage: decode_washed_lcd <image> [x y w h]\n", stderr)
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
let cropX: Int
let cropY: Int
let cropW: Int
let cropH: Int
if args.count == 6 {
    cropX = Int(args[2]) ?? -1
    cropY = Int(args[3]) ?? -1
    cropW = Int(args[4]) ?? -1
    cropH = Int(args[5]) ?? -1
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

var pixels = [UInt8](repeating: 0, count: cropW * cropH)
for y in 0..<cropH {
    for x in 0..<cropW {
        pixels[y * cropW + x] = pointer[(cropY + y) * fullW + (cropX + x)]
    }
}
let data = Data(pixels) as CFData
guard let provider = CGDataProvider(data: data),
      let gray = CGImage(
        width: cropW,
        height: cropH,
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        bytesPerRow: cropW,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
      ) else {
    fputs("could not wrap crop\n", stderr)
    exit(1)
}

let started = Date()
let result = SevenSegmentOCR.decode(cgImage: gray)
let seconds = Date().timeIntervalSince(started)
print("image \(fullW)x\(fullH) crop \(cropX),\(cropY) \(cropW)x\(cropH) \(String(format: "%.2f", seconds))s")
print("confidence \(result.confidence)")
print("---")
print(result.extractedText)
print("---")
for item in result.recognizedTexts {
    let box = item.boundingBox
    print("\(item.role) \(item.confidence) \(item.text) @\(box.minX),\(box.minY) \(box.width)x\(box.height)")
}
