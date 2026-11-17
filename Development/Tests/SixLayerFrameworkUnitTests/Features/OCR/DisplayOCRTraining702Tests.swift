//
//  DisplayOCRTraining702Tests.swift
//  SixLayerFrameworkUnitTests
//
//  #702: Display OCR Training UX — quiet stderr traces, async decode,
//  row-draw feedback, side-by-side layout preference.
//

import CoreGraphics
import Foundation
import Testing
@testable import SixLayerFramework

@Suite("Display OCR Training UX (#702)")
struct DisplayOCRTraining702Tests {

    // MARK: - stderr traces

    @Test func sevenSegmentTraceDisabledByDefault() {
        SevenSegmentOCRTrace.resetToEnvironmentDefault()
        #expect(SevenSegmentOCRTrace.isEnabled == false || ProcessInfo.processInfo.environment["SIXLAYER_SSOCR_TRACE"] == "1")
        // Default process (no env) must be quiet.
        if ProcessInfo.processInfo.environment["SIXLAYER_SSOCR_TRACE"] != "1" {
            #expect(SevenSegmentOCRTrace.isEnabled == false)
        }
    }

    @Test func sevenSegmentTraceRespectsEnabledFlag() {
        final class Sink: @unchecked Sendable {
            var lines: [String] = []
        }
        let sink = Sink()
        let previous = SevenSegmentOCRTrace.isEnabled
        let previousWriter = SevenSegmentOCRTrace.writer
        defer {
            SevenSegmentOCRTrace.isEnabled = previous
            SevenSegmentOCRTrace.writer = previousWriter
        }
        SevenSegmentOCRTrace.writer = { sink.lines.append($0) }

        SevenSegmentOCRTrace.isEnabled = false
        SevenSegmentOCRTrace.emit("quiet\n")
        #expect(sink.lines.isEmpty)

        SevenSegmentOCRTrace.isEnabled = true
        SevenSegmentOCRTrace.emit("loud\n")
        #expect(sink.lines == ["loud\n"])
    }

    // MARK: - row draw feedback

    @Test @MainActor func addRowBoxWithoutPanelSetsNeedsPanelStatus() {
        let session = DisplayOCRTrainingSession()
        let image = makeTinyGrayImage()
        session.load(cgImage: image, sourceName: "probe")
        session.drawMode = .row
        let ok = session.addRowBox(DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.4, height: 0.2))
        #expect(ok == false)
        #expect(session.status == .needsPanel)
        #expect(session.rowBoxes.isEmpty)
    }

    @Test @MainActor func applyDrawRowWithoutPanelSetsNeedsPanelStatus() {
        let session = DisplayOCRTrainingSession()
        let image = makeTinyGrayImage()
        session.load(cgImage: image, sourceName: "probe")
        session.drawMode = .row
        let ok = session.applyDraw(
            containerRect: CGRect(x: 10, y: 10, width: 80, height: 40),
            containerSize: CGSize(width: 200, height: 200)
        )
        #expect(ok == false)
        #expect(session.status == .needsPanel)
    }

    // MARK: - async decode

    @Test @MainActor func startDecodeSetsDecodingThenCompletesOffMainThread() async {
        let session = DisplayOCRTrainingSession()
        let image = makeTinyGrayImage()
        session.load(cgImage: image, sourceName: "probe")
        session.useFullFramePanel()
        await session.waitForSuggestion()

        session.startDecode()
        #expect(session.status == .decoding || session.status == .decoded || session.status == .decodeFailed)

        await session.waitForDecode()
        #expect(session.decodeRanOnMainThread == false)
        #expect(session.status == .decoded || session.status == .decodeFailed || session.status == .needsPanel)
    }

    // MARK: - layout preference

    @Test func trainingViewPrefersSideBySideImagePaneOnMac() {
        #if os(macOS)
        #expect(DisplayOCRTrainingLayout.prefersSideBySideImagePane == true)
        #else
        #expect(DisplayOCRTrainingLayout.prefersSideBySideImagePane == false)
        #endif
    }
}

private func makeTinyGrayImage() -> CGImage {
    let width = 32
    let height = 32
    var pixels = [UInt8](repeating: 200, count: width * height)
    let data = CFDataCreateMutable(nil, pixels.count)!
    CFDataAppendBytes(data, &pixels, pixels.count)
    let provider = CGDataProvider(data: data)!
    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        bytesPerRow: width,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
}
