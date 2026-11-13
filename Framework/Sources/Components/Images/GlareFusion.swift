//
//  GlareFusion.swift
//  SixLayerFramework
//
//  Combine the frames of a Live Photo so glare, which moves between frames
//  while the display does not, drops out before seven-segment OCR (#673).
//

import CoreGraphics
import Foundation
import Vision
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum GlareFusion {
    /// The per-pixel median of `frames`, each aligned to the middle frame.
    ///
    /// Glare sits on a different part of the display in each frame, so at any
    /// pixel most frames show the display itself and the median picks that.
    /// The median needs no assumption about which is brighter, the glare or
    /// the digits, so it works for dark-on-light and light-on-dark displays.
    ///
    /// Frames that are not the most common size are ignored. A frame
    /// that cannot be registered is used where it lies. Nil for no frames; a
    /// single frame is returned as it is.
    public static func fuse(frames: [PlatformImage]) -> PlatformImage? {
        let decoded = frames.compactMap(cgImage(of:))
        guard let common = commonSize(of: decoded) else { return nil }
        let same = decoded.filter { $0.width == common.width && $0.height == common.height }
        let reference = same[same.count / 2]
        guard same.count > 1 else { return PlatformImage(cgImage: reference) }

        let width = reference.width
        let height = reference.height
        var layers: [Layer] = []
        for frame in same {
            let transform = frame === reference ? .identity : translation(of: frame, to: reference)
            if let layer = Layer(frame, transform: transform) { layers.append(layer) }
        }
        guard let fused = median(of: layers, width: width, height: height) else {
            return PlatformImage(cgImage: reference)
        }
        return PlatformImage(cgImage: fused)
    }

    /// The size most frames share; the earliest such size on a tie.
    private static func commonSize(of images: [CGImage]) -> (width: Int, height: Int)? {
        var counts: [[Int]: Int] = [:]
        var order: [[Int]] = []
        for image in images {
            let key = [image.width, image.height]
            if counts[key] == nil { order.append(key) }
            counts[key, default: 0] += 1
        }
        guard let top = counts.values.max(), let size = order.first(where: { counts[$0] == top }) else { return nil }
        return (size[0], size[1])
    }

    // MARK: Alignment

    /// The shift that lays `floating` over `reference`, or identity when
    /// Vision cannot find one. A shift that moves the frame by a quarter of
    /// its size is treated as a failed registration: hand shake never does.
    private static func translation(of floating: CGImage, to reference: CGImage) -> CGAffineTransform {
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: floating)
        do {
            try VNImageRequestHandler(cgImage: reference).perform([request])
        } catch {
            return .identity
        }
        guard let result = request.results?.first as? VNImageTranslationAlignmentObservation else {
            return .identity
        }
        let shift = result.alignmentTransform
        let limit = 0.25 * Double(min(reference.width, reference.height))
        guard abs(shift.tx) <= limit, abs(shift.ty) <= limit else { return .identity }
        return shift
    }

    // MARK: Median

    /// One frame drawn into reference coordinates as RGBA. Pixels the shifted
    /// frame does not cover are transparent and take no part in the median.
    private struct Layer {
        var rgba: [UInt8]

        init?(_ image: CGImage, transform: CGAffineTransform) {
            let width = image.width
            let height = image.height
            var buffer = [UInt8](repeating: 0, count: width * height * 4)
            let drawn = buffer.withUnsafeMutableBytes { raw -> Bool in
                guard let context = CGContext(
                    data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8,
                    bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ) else { return false }
                // Whole-pixel shifts only: interpolating would invent edge pixels.
                context.interpolationQuality = .none
                context.concatenate(transform)
                context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                return true
            }
            guard drawn else { return nil }
            rgba = buffer
        }
    }

    private static func median(of layers: [Layer], width: Int, height: Int) -> CGImage? {
        guard let base = layers.first else { return nil }
        var out = base.rgba
        var samples = [UInt8](repeating: 0, count: layers.count)
        for pixel in 0..<(width * height) {
            let offset = pixel * 4
            for channel in 0..<3 {
                var count = 0
                for layer in layers where layer.rgba[offset + 3] == 255 {
                    samples[count] = layer.rgba[offset + channel]
                    count += 1
                }
                guard count > 0 else { continue }
                out[offset + channel] = middle(of: &samples, count: count)
            }
            out[offset + 3] = 255
        }
        return out.withUnsafeMutableBytes { raw -> CGImage? in
            CGContext(
                data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )?.makeImage()
        }
    }

    /// Median of the first `count` samples; the mean of the two middle ones
    /// when `count` is even.
    private static func middle(of samples: inout [UInt8], count: Int) -> UInt8 {
        // Insertion sort: count is the number of frames, a handful.
        for i in 1..<max(count, 1) {
            let value = samples[i]
            var j = i - 1
            while j >= 0, samples[j] > value {
                samples[j + 1] = samples[j]
                j -= 1
            }
            samples[j + 1] = value
        }
        if count % 2 == 1 { return samples[count / 2] }
        return UInt8((Int(samples[count / 2 - 1]) + Int(samples[count / 2]) + 1) / 2)
    }

    // MARK: Platform boundary

    private static func cgImage(of image: PlatformImage) -> CGImage? {
        #if os(iOS)
        return image.uiImage.cgImage
        #elseif os(macOS)
        return image.nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return nil
        #endif
    }
}
