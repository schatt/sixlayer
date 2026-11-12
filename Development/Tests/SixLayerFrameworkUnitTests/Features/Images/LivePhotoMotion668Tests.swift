import Testing
import Foundation
import AVFoundation
import CoreGraphics
import CoreVideo
@testable import SixLayerFramework

//
//  LivePhotoMotion668Tests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Live Photos carry ~3 s of video. Several frames of one shot let
//  seven-segment OCR fuse away glare that moves between frames (#668).
//
//  TESTING SCOPE:
//  - Frame extraction from a movie: count, order, spread, bad input
//  - Picker selection: motion is only requested when the flag is on,
//    and a failed movie load still delivers the still image
//

@Suite("Live Photo motion (#668)")
struct LivePhotoMotion668Tests {

    // MARK: Frame extraction

    @Test func framesAreEvenlySpacedOldestFirst() async throws {
        let movie = try await TestMovie.grayRamp(frameCount: 30, framesPerSecond: 30)
        defer { try? FileManager.default.removeItem(at: movie) }

        let frames = try await LivePhotoFrames.frames(fromMovieAt: movie, count: 5)

        try #require(frames.count == 5)
        let levels = frames.map { TestMovie.meanGray($0) }
        // The ramp brightens every frame, so evenly spaced frames from oldest
        // to newest must be strictly brighter each time, first near black and
        // last near white.
        for (earlier, later) in zip(levels, levels.dropFirst()) {
            #expect(later > earlier + 20, "levels \(levels)")
        }
        #expect(levels.first! < 40, "levels \(levels)")
        #expect(levels.last! > 200, "levels \(levels)")
    }

    @Test func framesKeepTheMovieSize() async throws {
        let movie = try await TestMovie.grayRamp(frameCount: 10, framesPerSecond: 30)
        defer { try? FileManager.default.removeItem(at: movie) }

        let frames = try await LivePhotoFrames.frames(fromMovieAt: movie, count: 2)

        try #require(frames.count == 2)
        #expect(frames.allSatisfy { Int($0.size.width) == TestMovie.width && Int($0.size.height) == TestMovie.height })
    }

    @Test func zeroCountReadsNothing() async throws {
        let movie = try await TestMovie.grayRamp(frameCount: 10, framesPerSecond: 30)
        defer { try? FileManager.default.removeItem(at: movie) }

        let frames = try await LivePhotoFrames.frames(fromMovieAt: movie, count: 0)

        #expect(frames.isEmpty)
    }

    @Test func missingMovieThrows() async {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("no-such-live-photo-\(UUID().uuidString).mov")

        await #expect(throws: (any Error).self) {
            _ = try await LivePhotoFrames.frames(fromMovieAt: missing, count: 3)
        }
    }

    // MARK: Picker selection

    @Test func flagOffNeverAsksForMotion() async {
        let still = TestMovie.solidImage(gray: 128)
        var asked = false

        let selection = await PlatformPhotoSelection.resolve(
            image: still,
            includeLivePhotoMotion: false,
            loadLivePhotoMovie: {
                asked = true
                return URL(fileURLWithPath: "/tmp/should-not-be-used.mov")
            }
        )

        #expect(!asked)
        #expect(selection.livePhotoMovieURL == nil)
        #expect(selection.image.size == still.size)
    }

    @Test func flagOnCarriesTheMovie() async {
        let still = TestMovie.solidImage(gray: 128)
        let movie = URL(fileURLWithPath: "/tmp/live-photo-motion.mov")

        let selection = await PlatformPhotoSelection.resolve(
            image: still,
            includeLivePhotoMotion: true,
            loadLivePhotoMovie: { movie }
        )

        #expect(selection.livePhotoMovieURL == movie)
        #expect(selection.image.size == still.size)
    }

    @Test func flagOnWithoutMotionStillDeliversTheImage() async {
        let still = TestMovie.solidImage(gray: 128)

        let selection = await PlatformPhotoSelection.resolve(
            image: still,
            includeLivePhotoMotion: true,
            loadLivePhotoMovie: { nil }
        )

        #expect(selection.livePhotoMovieURL == nil)
        #expect(selection.image.size == still.size)
    }
}

// MARK: - Test movie

/// Writes a short H.264 movie whose frames step from black to white.
enum TestMovie {
    static let width = 64
    static let height = 48

    static func grayRamp(frameCount: Int, framesPerSecond: Int32) async throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("live-photo-668-\(UUID().uuidString).mov")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        writer.startSession(atSourceTime: .zero)

        for index in 0..<frameCount {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 1_000_000)
            }
            let level = UInt8(frameCount <= 1 ? 0 : index * 255 / (frameCount - 1))
            let buffer = try pixelBuffer(gray: level)
            let time = CMTime(value: CMTimeValue(index), timescale: framesPerSecond)
            guard adaptor.append(buffer, withPresentationTime: time) else {
                throw writer.error ?? CocoaError(.fileWriteUnknown)
            }
        }
        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        return url
    }

    private static func pixelBuffer(gray: UInt8) throws -> CVPixelBuffer {
        var made: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &made)
        guard let buffer = made else { throw CocoaError(.fileWriteUnknown) }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let base = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        for y in 0..<height {
            for x in 0..<width {
                let pixel = base + y * rowBytes + x * 4
                pixel[0] = gray
                pixel[1] = gray
                pixel[2] = gray
                pixel[3] = 255
            }
        }
        return buffer
    }

    static func solidImage(gray: UInt8) -> PlatformImage {
        let space = CGColorSpaceCreateDeviceGray()
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width, space: space, bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        context.setFillColor(gray: CGFloat(gray) / 255, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return PlatformImage(cgImage: context.makeImage()!)
    }

    /// Mean luminance 0–255 of the image's centre.
    static func meanGray(_ image: PlatformImage) -> Double {
        #if os(macOS)
        let cgImage = image.nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        let cgImage = image.uiImage.cgImage
        #endif
        guard let cgImage else { return -1 }
        let w = 8, h = 8
        var pixels = [UInt8](repeating: 0, count: w * h)
        let context = CGContext(
            data: &pixels, width: w, height: h, bitsPerComponent: 8,
            bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        return Double(pixels.reduce(0) { $0 + Int($1) }) / Double(pixels.count)
    }
}
