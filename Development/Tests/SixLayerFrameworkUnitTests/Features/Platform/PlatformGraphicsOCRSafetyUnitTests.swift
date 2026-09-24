//
//  PlatformGraphicsOCRSafetyUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for PlatformGraphics + PlatformOCRSafety (#513).
//

import CoreGraphics
import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform Graphics + OCR Safety (#513)")
struct PlatformGraphicsOCRSafetyUnitTests {

    // MARK: - VisionAvailabilityInfo / availability probes

    @Test func visionAvailabilityInfo_storesInitializerFields() {
        let info = VisionAvailabilityInfo(
            platform: "iOS",
            isAvailable: true,
            minVersion: "11.0",
            isCompatible: true
        )
        #expect(info.platform == "iOS")
        #expect(info.isAvailable)
        #expect(info.minVersion == "11.0")
        #expect(info.isCompatible)
    }

    @Test func getVisionAvailabilityInfo_matchesHostPlatform() {
        let info = getVisionAvailabilityInfo()
        #if os(iOS)
        // Deliberate red (#513): wrong platform label until green
        #expect(info.platform == "watchOS")
        #expect(info.minVersion == "11.0")
        #expect(info.isAvailable)
        #expect(info.isCompatible)
        #elseif os(macOS)
        #expect(info.platform == "macOS")
        #expect(info.minVersion == "10.15")
        #expect(info.isAvailable)
        #expect(info.isCompatible)
        #else
        #expect(info.platform == "Unknown")
        #expect(!info.isAvailable)
        #endif
    }

    @Test func isVisionOCRAvailable_matchesFrameworkAvailability() {
        #expect(isVisionOCRAvailable() == isVisionFrameworkAvailable())
    }

    @Test func safeOCRResult_casesCarryPayload() {
        let ocr = OCRResult(extractedText: "hi", confidence: 0.9, boundingBoxes: [])
        let success = SafeOCRResult.success(ocr)
        let fallback = SafeOCRResult.fallback(ocr)
        if case .success(let s) = success {
            #expect(s.extractedText == "hi")
        } else {
            Issue.record("expected success case")
        }
        if case .fallback(let f) = fallback {
            #expect(f.confidence == 0.9)
        } else {
            Issue.record("expected fallback case")
        }
    }

    // MARK: - CGContext Color fill

    @Test func cgContext_fillRectWithColorWritesOpaquePixels() {
        let width = 4
        let height = 4
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        pixels.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress,
                  let ctx = CGContext(
                    data: base,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                  ) else {
                Issue.record("failed to create CGContext")
                return
            }
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height), with: .red)
        }

        // Premultiplied last: R,G,B,A — filled red must leave non-zero alpha
        let alpha = pixels[3]
        #expect(alpha > 0, "fill(with:) must write opaque pixels for .red")
    }
}
