//
//  PlatformDataScannerTypes.swift
//  SixLayerFramework
//
//  Public configuration for VisionKit live text / barcode capture (Issue #252).
//  Cross-platform types; iOS VisionKit wiring lives in PlatformDataScannerLiveContainer_iOS.swift.
//

import Foundation
import SwiftUI

#if os(iOS) && canImport(VisionKit)
import VisionKit
#endif

// MARK: - Errors

/// Errors surfaced by the live data scanner session (Issue #252).
public enum PlatformDataScannerError: Error, Sendable, Equatable {
    /// No live `DataScannerViewController` is attached yet (e.g. before appear or after teardown).
    case scannerNotAttached
    /// The current OS / build does not support the VisionKit live scanner.
    case platformUnsupported
}

// MARK: - Presentation

/// How the host intends to present the live data scanner (Issue #252).
public enum PlatformDataScannerPresentationStyle: Sendable, Hashable, Equatable {
    case sheet
    case fullScreenCover
}

// MARK: - Quality

/// Maps to `DataScannerViewController.QualityLevel` on supported platforms.
public enum PlatformDataScannerQualityLevel: Sendable, Hashable, Equatable {
    case fast
    case balanced
    case accurate
}

// MARK: - Recognized data (portable surface)

/// Portable text filter for structured Live Text fields (mirrors common VisionKit text content types).
public enum PlatformDataScannerTextContentFilter: Sendable, Hashable, Equatable {
    case plain
    case url
    case emailAddress
    case telephoneNumber
    case flightNumber
    case shipmentTrackingNumber
    case fullStreetAddress
}

/// Portable barcode symbology subset for configuration (maps to `VNBarcodeSymbology` on iOS).
public enum PlatformDataScannerBarcodeSymbology: String, Sendable, Hashable, Equatable, CaseIterable {
    case qr
    case code128
    case ean13
    case ean8
    case pdf417
    case aztec
    case dataMatrix
    case upce
    case code39
    case itf14
}

/// What the live scanner should look for in the camera feed.
public enum PlatformDataScannerDataKind: Hashable, Sendable, Equatable {
    /// Unstructured text; optional BCP-47 language hints (e.g. `["en-US"]`).
    case plainText(languages: [String]? = nil)
    /// Structured text (URLs, phone numbers, etc.).
    case filteredText(PlatformDataScannerTextContentFilter, languages: [String]? = nil)
    /// Machine-readable codes; empty set means “common default” on the platform bridge.
    case barcode(symbologies: Set<PlatformDataScannerBarcodeSymbology>)
}

// MARK: - Recognized items (callbacks)

/// Payload after a person interacts with recognized content.
public enum PlatformDataScannerRecognizedPayload: Sendable, Hashable, Equatable {
    case text(transcript: String)
    case barcode(payload: String)
}

/// A tracked region in the live view (stable identity for add/update/remove callbacks).
public struct PlatformDataScannerTrackedItem: Sendable, Hashable, Equatable, Identifiable {
    public let id: UUID
    public let payload: PlatformDataScannerRecognizedPayload

    public init(id: UUID, payload: PlatformDataScannerRecognizedPayload) {
        self.id = id
        self.payload = payload
    }
}

// MARK: - Session control (start / stop / photo)

/// Programmatic control of an active live scanner session (Issue #252).
/// The iOS VisionKit representable assigns the underlying controller when the scanner appears.
@MainActor
public final class PlatformDataScannerSessionController: Sendable {
    /// Weak reference to platform scanner VC; set by the framework on iOS when supported.
    internal weak var liveScannerViewController: AnyObject?

    public init() {}

    #if os(iOS) && canImport(VisionKit)
    @available(iOS 16.0, *)
    internal func attachLiveScanner(_ controller: DataScannerViewController) {
        liveScannerViewController = controller
    }
    #endif

    /// Starts VisionKit scanning when a controller is attached (Issue #252).
    @MainActor
    public func startScanning() throws {
        #if os(iOS) && canImport(VisionKit)
        if #available(iOS 16.0, *) {
            guard let controller = liveScannerViewController as? DataScannerViewController else {
                throw PlatformDataScannerError.scannerNotAttached
            }
            try controller.startScanning()
            return
        }
        #endif
        throw PlatformDataScannerError.platformUnsupported
    }

    /// Stops VisionKit scanning when a controller is attached.
    @MainActor
    public func stopScanning() {
        #if os(iOS) && canImport(VisionKit)
        if #available(iOS 16.0, *) {
            guard let controller = liveScannerViewController as? DataScannerViewController else { return }
            controller.stopScanning()
        }
        #endif
    }

    /// Captures a high-resolution still from the active scanner (VisionKit).
    @MainActor
    public func capturePhoto() async throws -> PlatformImage {
        #if os(iOS) && canImport(VisionKit)
        if #available(iOS 16.0, *) {
            guard let controller = liveScannerViewController as? DataScannerViewController else {
                throw PlatformDataScannerError.scannerNotAttached
            }
            let image = try await controller.capturePhoto()
            return PlatformImage(image)
        }
        #endif
        throw PlatformDataScannerError.platformUnsupported
    }
}

// MARK: - Configuration

/// Full configuration for live text / barcode scanning (Issue #252).
public struct PlatformDataScannerConfiguration: Sendable, Hashable, Equatable {
    public var recognizedDataTypes: Set<PlatformDataScannerDataKind>
    public var qualityLevel: PlatformDataScannerQualityLevel
    public var recognizesMultipleItems: Bool
    public var isHighlightingEnabled: Bool
    public var isGuidanceEnabled: Bool
    public var isPinchToZoomEnabled: Bool
    public var isHighFrameRateTrackingEnabled: Bool
    public var regionOfInterest: CGRect?
    public var presentationStyle: PlatformDataScannerPresentationStyle

    public init(
        recognizedDataTypes: Set<PlatformDataScannerDataKind>,
        qualityLevel: PlatformDataScannerQualityLevel = .balanced,
        recognizesMultipleItems: Bool = true,
        isHighlightingEnabled: Bool = true,
        isGuidanceEnabled: Bool = true,
        isPinchToZoomEnabled: Bool = true,
        isHighFrameRateTrackingEnabled: Bool = false,
        regionOfInterest: CGRect? = nil,
        presentationStyle: PlatformDataScannerPresentationStyle = .sheet
    ) {
        self.recognizedDataTypes = recognizedDataTypes
        self.qualityLevel = qualityLevel
        self.recognizesMultipleItems = recognizesMultipleItems
        self.isHighlightingEnabled = isHighlightingEnabled
        self.isGuidanceEnabled = isGuidanceEnabled
        self.isPinchToZoomEnabled = isPinchToZoomEnabled
        self.isHighFrameRateTrackingEnabled = isHighFrameRateTrackingEnabled
        self.regionOfInterest = regionOfInterest
        self.presentationStyle = presentationStyle
    }

    /// Sensible defaults: plain text + QR; balanced quality; multi-item; system guidance and highlights on.
    public static var `default`: PlatformDataScannerConfiguration {
        PlatformDataScannerConfiguration(
            recognizedDataTypes: [
                .plainText(languages: nil),
                .barcode(symbologies: [.qr])
            ]
        )
    }
}
