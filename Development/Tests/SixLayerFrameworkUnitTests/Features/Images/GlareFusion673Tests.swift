import Testing
import Foundation
import CoreGraphics
@testable import SixLayerFramework

//
//  GlareFusion673Tests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Glare moves between the frames of a Live Photo while the display does
//  not, so a per-pixel median of aligned frames removes it (#673).
//
//  TESTING SCOPE:
//  - Moving glare is removed, for dark-on-light and light-on-dark displays
//  - Frames shifted by hand shake are aligned first
//  - Degenerate input (none, one, mismatched sizes) never throws or crashes
//

@Suite("Glare fusion (#673)")
struct GlareFusion673Tests {

    // MARK: Glare removal

    @Test func movingGlareIsRemovedFromDarkOnLight() throws {
        let clean = Scene(background: 200, ink: 40)
        let frames = (0..<5).map { clean.image(glareAt: Scene.glareSpots[$0]) }

        let fused = try #require(GlareFusion.fuse(frames: frames))

        #expect(Scene.maxDifference(fused, clean.image()) <= 2)
        for frame in frames {
            #expect(Scene.maxDifference(frame, clean.image()) > 50, "a single frame must still show glare")
        }
    }

    @Test func movingGlareIsRemovedFromLightOnDark() throws {
        let clean = Scene(background: 30, ink: 220)
        let frames = (0..<5).map { clean.image(glareAt: Scene.glareSpots[$0]) }

        let fused = try #require(GlareFusion.fuse(frames: frames))

        #expect(Scene.maxDifference(fused, clean.image()) <= 2)
    }

    // MARK: Alignment

    @Test func shiftedFramesAreAlignedBeforeTheMedian() throws {
        let clean = Scene(background: 200, ink: 40)
        let shifts = [(0, 0), (3, -2), (-2, 3), (4, 1), (-3, -3)]
        let frames = zip(0..<5, shifts).map { index, shift in
            clean.image(glareAt: Scene.glareSpots[index], shiftedBy: shift)
        }
        // The middle frame is the reference, so the fused image sits where it does.
        let reference = clean.image(shiftedBy: shifts[2])

        let fused = try #require(GlareFusion.fuse(frames: frames))

        #expect(
            Scene.maxDifference(fused, reference, margin: 10) <= 2,
            "unaligned frames would blur the digit edges and leave glare"
        )
    }

    // MARK: Degenerate input

    @Test func noFramesGiveNothing() {
        #expect(GlareFusion.fuse(frames: []) == nil)
    }

    @Test func oneFrameComesBackUnchanged() throws {
        let clean = Scene(background: 200, ink: 40)
        let frame = clean.image(glareAt: Scene.glareSpots[0])

        let fused = try #require(GlareFusion.fuse(frames: [frame]))

        #expect(Scene.maxDifference(fused, frame) == 0)
    }

    @Test func framesOfAnotherSizeAreIgnored() throws {
        let clean = Scene(background: 200, ink: 40)
        var frames = (0..<3).map { clean.image(glareAt: Scene.glareSpots[$0]) }
        frames.insert(Scene(background: 90, ink: 10, width: 40, height: 30).image(), at: 0)

        let fused = try #require(GlareFusion.fuse(frames: frames))

        #expect(Int(fused.size.width) == Scene.defaultWidth)
        #expect(Int(fused.size.height) == Scene.defaultHeight)
    }
}

// MARK: - Synthetic scene

/// Three static bars on a plain background, with an optional glare disc.
struct Scene {
    static let defaultWidth = 96
    static let defaultHeight = 64
    /// Centres that do not overlap, so any pixel is glared in at most one frame.
    static let glareSpots: [(Int, Int)] = [(20, 20), (48, 32), (76, 20), (30, 48), (66, 48)]

    let background: UInt8
    let ink: UInt8
    var width = Scene.defaultWidth
    var height = Scene.defaultHeight

    init(background: UInt8, ink: UInt8, width: Int = Scene.defaultWidth, height: Int = Scene.defaultHeight) {
        self.background = background
        self.ink = ink
        self.width = width
        self.height = height
    }

    func pixels(glareAt glare: (Int, Int)? = nil, shiftedBy shift: (Int, Int) = (0, 0)) -> [UInt8] {
        var out = [UInt8](repeating: background, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let sx = x - shift.0
                let sy = y - shift.1
                // Bars: a tall one, a wide one and a small square, so the scene has
                // corners in both directions for registration to lock onto.
                let inBar = (14..<24).contains(sx) && (10..<54).contains(sy)
                    || (34..<80).contains(sx) && (12..<22).contains(sy)
                    || (50..<62).contains(sx) && (34..<52).contains(sy)
                if inBar { out[y * width + x] = ink }
                if let glare {
                    let dx = x - glare.0, dy = y - glare.1
                    if dx * dx + dy * dy <= 8 * 8 { out[y * width + x] = 255 }
                }
            }
        }
        return out
    }

    func image(glareAt glare: (Int, Int)? = nil, shiftedBy shift: (Int, Int) = (0, 0)) -> PlatformImage {
        let data = pixels(glareAt: glare, shiftedBy: shift)
        let provider = CGDataProvider(data: Data(data) as CFData)!
        let cgImage = CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )!
        return PlatformImage(cgImage: cgImage)
    }

    static func gray(_ image: PlatformImage) -> (pixels: [UInt8], width: Int, height: Int)? {
        #if os(macOS)
        let cgImage = image.nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        let cgImage = image.uiImage.cgImage
        #endif
        guard let cgImage else { return nil }
        let w = cgImage.width, h = cgImage.height
        var pixels = [UInt8](repeating: 0, count: w * h)
        let context = CGContext(
            data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        return (pixels, w, h)
    }

    /// Largest gray difference, ignoring `margin` pixels at every edge.
    static func maxDifference(_ a: PlatformImage, _ b: PlatformImage, margin: Int = 0) -> Int {
        guard let left = gray(a), let right = gray(b),
              left.width == right.width, left.height == right.height else { return Int.max }
        var largest = 0
        for y in margin..<(left.height - margin) {
            for x in margin..<(left.width - margin) {
                let i = y * left.width + x
                largest = max(largest, abs(Int(left.pixels[i]) - Int(right.pixels[i])))
            }
        }
        return largest
    }
}
