//
//  PlatformImageEXIFWriters.swift
//  SixLayerFramework
//
//  EXIF writer APIs on `PlatformImage.exif`.
//  Implements GitHub Issue #275.
//
//  STUB ONLY (red phase): writer methods are declared with their final
//  signatures and return nil so tests compile and fail at runtime for the
//  correct reason. Green phase implements the real CGImageDestination
//  round-trip with HEIC default and explicit-format overloads.
//

import Foundation
import CoreLocation

#if canImport(ImageIO)
import ImageIO
#endif

#if canImport(ImageIO) && canImport(CoreLocation)

// MARK: - Writer API (stubs)

public extension PlatformImageEXIF {

    /// Returns a new `PlatformImage` whose container metadata has the given GPS
    /// location written into the EXIF GPS dictionary, encoded using
    /// `PlatformImageEXIFConfig.current.defaultWriteFormat`. Pass `nil` to
    /// remove the GPS dictionary.
    /// Returns `nil` if the encode fails or the source cannot be read.
    func with(gpsLocation: CLLocation?) -> PlatformImage? {
        return nil
    }

    /// Returns a new `PlatformImage` whose container metadata has the given
    /// EXIF DateTimeOriginal field replaced. Pass `nil` to remove it.
    func with(captureDate: Date?) -> PlatformImage? {
        return nil
    }

    /// Returns a new `PlatformImage` whose container metadata has the given
    /// EXIF orientation tag written.
    func with(orientation: CGImagePropertyOrientation) -> PlatformImage? {
        return nil
    }

    /// Privacy-forward: returns a new `PlatformImage` with the GPS dictionary
    /// removed and all other EXIF / TIFF / IPTC dictionaries preserved.
    func strippingGPS() -> PlatformImage? {
        return nil
    }

    /// Privacy-forward: returns a new `PlatformImage` with **all** container
    /// metadata removed (EXIF, TIFF, GPS, IPTC, etc.).
    func strippingAll() -> PlatformImage? {
        return nil
    }

    // MARK: - Format-explicit overloads

    /// Format-explicit variant of `with(gpsLocation:)`. Encodes the result
    /// using the supplied `format` regardless of `PlatformImageEXIFConfig`.
    func with(gpsLocation: CLLocation?, as format: ImageFormat) -> PlatformImage? {
        return nil
    }

    /// Format-explicit variant of `strippingGPS()`.
    func strippingGPS(as format: ImageFormat) -> PlatformImage? {
        return nil
    }

    /// Format-explicit variant of `strippingAll()`.
    func strippingAll(as format: ImageFormat) -> PlatformImage? {
        return nil
    }
}

#endif
