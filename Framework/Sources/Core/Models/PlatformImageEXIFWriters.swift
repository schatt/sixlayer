//
//  PlatformImageEXIFWriters.swift
//  SixLayerFramework
//
//  EXIF writer APIs on `PlatformImage.exif`.
//  Implements GitHub Issue #275.
//
//  Writers re-encode the container using `CGImageDestination`. When the source
//  `PlatformImage` was constructed from `Data` (#274), pixels are copied via
//  `CGImageDestinationAddImageFromSource` — no JPEG quantization on a re-tag,
//  and unrelated metadata (TIFF, IPTC, EXIF auxiliary) is preserved. Bitmap-only
//  sources fall back to a fresh JPEG bitmap encode (best-effort).
//
//  Default container format is `PlatformImageEXIFConfig.current.defaultWriteFormat`
//  (HEIC by default). Default-path writers fall back to JPEG when HEIC encoding
//  is unavailable on the host runtime; format-explicit overloads respect the
//  caller's choice and return `nil` on failure.
//

import Foundation
import CoreLocation
import CoreGraphics

#if canImport(ImageIO)
import ImageIO
#endif

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if canImport(ImageIO) && canImport(CoreLocation)

// MARK: - Writer API

public extension PlatformImageEXIF {

    /// Returns a new `PlatformImage` whose container metadata has the given GPS
    /// location written into the EXIF GPS dictionary. Pass `nil` to remove the
    /// GPS dictionary. Encodes using `PlatformImageEXIFConfig.current.defaultWriteFormat`.
    /// Returns `nil` only if the encode fails entirely.
    func with(gpsLocation: CLLocation?) -> PlatformImage? {
        return write(gpsMerge: Self.gpsMerge(for: gpsLocation),
                     captureDateMerge: .noChange,
                     orientationWrite: .noChange,
                     stripDictionaries: [],
                     format: nil)
    }

    /// Returns a new `PlatformImage` whose EXIF capture timestamp fields
    /// (`DateTimeOriginal` / `DateTimeDigitized`) are set from `captureDate`, or
    /// removed when `captureDate` is `nil`. Encodes using
    /// `PlatformImageEXIFConfig.current.defaultWriteFormat`.
    func with(captureDate: Date?) -> PlatformImage? {
        return write(gpsMerge: .noChange,
                     captureDateMerge: Self.captureDateMerge(for: captureDate),
                     orientationWrite: .noChange,
                     stripDictionaries: [],
                     format: nil)
    }

    /// Returns a new `PlatformImage` whose container stores the given EXIF
    /// orientation tag at the top level (`kCGImagePropertyOrientation`).
    func with(orientation: CGImagePropertyOrientation) -> PlatformImage? {
        return write(gpsMerge: .noChange,
                     captureDateMerge: .noChange,
                     orientationWrite: .set(orientation),
                     stripDictionaries: [],
                     format: nil)
    }

    /// Privacy-forward: returns a new `PlatformImage` with the GPS dictionary
    /// removed and all other metadata preserved.
    func strippingGPS() -> PlatformImage? {
        return write(gpsMerge: .removeKey,
                     captureDateMerge: .noChange,
                     orientationWrite: .noChange,
                     stripDictionaries: [],
                     format: nil)
    }

    /// Privacy-forward: returns a new `PlatformImage` with **all** known
    /// container metadata dictionaries removed (EXIF, TIFF, GPS, IPTC,
    /// EXIF auxiliary, JFIF, PNG, 8BIM, and common maker-note dictionaries).
    func strippingAll() -> PlatformImage? {
        return write(gpsMerge: .removeKey,
                     captureDateMerge: .noChange,
                     orientationWrite: .noChange,
                     stripDictionaries: Self.allMetadataDictionaryKeys,
                     format: nil)
    }

    // MARK: - Format-explicit overloads

    /// Format-explicit variant of `with(gpsLocation:)`. Encodes using `format`
    /// regardless of `PlatformImageEXIFConfig`; returns `nil` on encode failure.
    func with(gpsLocation: CLLocation?, as format: ImageFormat) -> PlatformImage? {
        return write(gpsMerge: Self.gpsMerge(for: gpsLocation),
                     captureDateMerge: .noChange,
                     orientationWrite: .noChange,
                     stripDictionaries: [],
                     format: format)
    }

    /// Format-explicit variant of `with(captureDate:)`.
    func with(captureDate: Date?, as format: ImageFormat) -> PlatformImage? {
        return write(gpsMerge: .noChange,
                     captureDateMerge: Self.captureDateMerge(for: captureDate),
                     orientationWrite: .noChange,
                     stripDictionaries: [],
                     format: format)
    }

    /// Format-explicit variant of `with(orientation:)`.
    func with(orientation: CGImagePropertyOrientation, as format: ImageFormat) -> PlatformImage? {
        return write(gpsMerge: .noChange,
                     captureDateMerge: .noChange,
                     orientationWrite: .set(orientation),
                     stripDictionaries: [],
                     format: format)
    }

    /// Format-explicit variant of `strippingGPS()`.
    func strippingGPS(as format: ImageFormat) -> PlatformImage? {
        return write(gpsMerge: .removeKey,
                     captureDateMerge: .noChange,
                     orientationWrite: .noChange,
                     stripDictionaries: [],
                     format: format)
    }

    /// Format-explicit variant of `strippingAll()`.
    func strippingAll(as format: ImageFormat) -> PlatformImage? {
        return write(gpsMerge: .removeKey,
                     captureDateMerge: .noChange,
                     orientationWrite: .noChange,
                     stripDictionaries: Self.allMetadataDictionaryKeys,
                     format: format)
    }
}

// MARK: - Private implementation

private extension PlatformImageEXIF {

    /// Value type used to express "set GPS dictionary to X" vs "remove GPS dictionary".
    /// Optionals would conflate "no change" with "remove"; this is explicit.
    enum GPSMerge {
        case noChange
        case removeKey
        case set([String: Any])
    }

    /// EXIF capture date merge for `with(captureDate:)`.
    enum CaptureDateMerge {
        case noChange
        case remove
        case set(Date)
    }

    /// Top-level EXIF orientation write.
    enum OrientationWrite {
        case noChange
        case set(CGImagePropertyOrientation)
    }

    /// Top-level metadata dictionary keys removed by `strippingAll()`.
    static var allMetadataDictionaryKeys: [CFString] {
        return [
            kCGImagePropertyExifDictionary,
            kCGImagePropertyTIFFDictionary,
            kCGImagePropertyGPSDictionary,
            kCGImagePropertyIPTCDictionary,
            kCGImagePropertyExifAuxDictionary,
            kCGImagePropertyJFIFDictionary,
            kCGImagePropertyPNGDictionary,
            kCGImageProperty8BIMDictionary,
            kCGImagePropertyMakerAppleDictionary,
            kCGImagePropertyMakerCanonDictionary,
            kCGImagePropertyMakerNikonDictionary,
            kCGImagePropertyMakerMinoltaDictionary,
            kCGImagePropertyMakerFujiDictionary,
            kCGImagePropertyMakerOlympusDictionary,
            kCGImagePropertyMakerPentaxDictionary
        ]
    }

    /// Resolves a `GPSMerge` for an optional `CLLocation`: `nil` means
    /// "remove the GPS dictionary", non-nil means "set it to the EXIF-shape
    /// dictionary derived from the location".
    static func gpsMerge(for location: CLLocation?) -> GPSMerge {
        guard let location else { return .removeKey }
        return .set(gpsDictionary(from: location))
    }

    static func captureDateMerge(for date: Date?) -> CaptureDateMerge {
        guard let date else { return .remove }
        return .set(date)
    }

    /// EXIF `DateTimeOriginal` / `DateTimeDigitized` string (`yyyy:MM:dd HH:mm:ss`, UTC).
    static func exifDateTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    /// Build the EXIF GPS top-level dictionary value for the given `CLLocation`.
    static func gpsDictionary(from location: CLLocation) -> [String: Any] {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        var dict: [String: Any] = [
            kCGImagePropertyGPSLatitude as String: abs(lat),
            kCGImagePropertyGPSLatitudeRef as String: lat >= 0 ? "N" : "S",
            kCGImagePropertyGPSLongitude as String: abs(lon),
            kCGImagePropertyGPSLongitudeRef as String: lon >= 0 ? "E" : "W"
        ]
        if location.verticalAccuracy >= 0 || location.altitude != 0 {
            dict[kCGImagePropertyGPSAltitude as String] = abs(location.altitude)
            dict[kCGImagePropertyGPSAltitudeRef as String] = location.altitude >= 0 ? 0 : 1
        }
        if location.horizontalAccuracy >= 0 {
            dict[kCGImagePropertyGPSHPositioningError as String] = location.horizontalAccuracy
        }
        return dict
    }

    /// Resolve the encoded source data we can hand to `CGImageSource`.
    /// Prefers `originalEncodedData` (lossless) and falls back to a JPEG
    /// re-encode of the in-memory bitmap (best-effort).
    func sourceData() -> Data? {
        if let data = image.originalEncodedData {
            return data
        }
        #if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
        return image.uiImage.jpegData(compressionQuality: 1.0)
        #elseif os(macOS)
        guard let tiffData = image.nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 1.0]) else {
            return nil
        }
        return jpegData
        #else
        return nil
        #endif
    }

    /// Core write path: copy pixels from `sourceData` into a new container of
    /// `format`, applying the requested metadata changes. When `format` is
    /// `nil`, uses `PlatformImageEXIFConfig.current.defaultWriteFormat` and
    /// falls back to JPEG on HEIC encode failure.
    func write(gpsMerge: GPSMerge,
               captureDateMerge: CaptureDateMerge,
               orientationWrite: OrientationWrite,
               stripDictionaries: [CFString],
               format: ImageFormat?) -> PlatformImage? {
        guard let source = sourceData() else { return nil }
        let primary = format ?? PlatformImageEXIFConfig.current.defaultWriteFormat
        if let bytes = Self.encode(source: source,
                                   format: primary,
                                   gpsMerge: gpsMerge,
                                   captureDateMerge: captureDateMerge,
                                   orientationWrite: orientationWrite,
                                   stripDictionaries: stripDictionaries) {
            return PlatformImage(data: bytes)
        }
        // Default-path fallback: try JPEG when HEIC (or whatever default) fails.
        if format == nil && primary != .jpeg {
            if let bytes = Self.encode(source: source,
                                       format: .jpeg,
                                       gpsMerge: gpsMerge,
                                       captureDateMerge: captureDateMerge,
                                       orientationWrite: orientationWrite,
                                       stripDictionaries: stripDictionaries) {
                return PlatformImage(data: bytes)
            }
        }
        return nil
    }

    /// Encode `source` into `format`, applying the GPS merge and removing the
    /// given top-level dictionaries. Uses `CGImageDestinationAddImageFromSource`
    /// so pixels are copied losslessly when the source was a real container.
    static func encode(source: Data,
                       format: ImageFormat,
                       gpsMerge: GPSMerge,
                       captureDateMerge: CaptureDateMerge,
                       orientationWrite: OrientationWrite,
                       stripDictionaries: [CFString]) -> Data? {
        guard let imageSource = CGImageSourceCreateWithData(source as CFData, nil) else { return nil }
        guard let utiString = uti(for: format) else { return nil }
        let mutable = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutable,
                                                                 utiString as CFString,
                                                                 1,
                                                                 nil) else { return nil }
        // Build merge dict. `kCFNull` removes a key from the destination.
        var merge: [String: Any] = [:]
        switch gpsMerge {
        case .noChange: break
        case .removeKey:
            merge[kCGImagePropertyGPSDictionary as String] = kCFNull
        case .set(let dict):
            merge[kCGImagePropertyGPSDictionary as String] = dict
        }
        for key in stripDictionaries {
            merge[key as String] = kCFNull
        }
        switch orientationWrite {
        case .noChange: break
        case .set(let orientation):
            merge[kCGImagePropertyOrientation as String] = orientation.rawValue
        }
        switch captureDateMerge {
        case .noChange: break
        case .remove:
            // Nested `kCFNull` removes EXIF sub-keys when Image I/O merges dictionaries.
            merge[kCGImagePropertyExifDictionary as String] = [
                kCGImagePropertyExifDateTimeOriginal as String: kCFNull,
                kCGImagePropertyExifDateTimeDigitized as String: kCFNull
            ]
        case .set(let date):
            let dateString = exifDateTimeString(from: date)
            merge[kCGImagePropertyExifDictionary as String] = [
                kCGImagePropertyExifDateTimeOriginal as String: dateString,
                kCGImagePropertyExifDateTimeDigitized as String: dateString
            ]
        }
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, merge as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutable as Data
    }

    /// Maps an `ImageFormat` to a CoreGraphics-recognized UTI string.
    /// Returns `nil` for `.unknown`.
    static func uti(for format: ImageFormat) -> String? {
        switch format {
        case .jpeg: return "public.jpeg"
        case .png:  return "public.png"
        case .heic: return "public.heic"
        case .tiff: return "public.tiff"
        case .unknown: return nil
        }
    }
}

#endif
