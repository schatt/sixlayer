//
//  PlatformImageEXIF.swift
//  SixLayerFramework
//
//  EXIF metadata accessor for PlatformImage
//  Implements GitHub Issue #21: PlatformImage EXIF GPS Location Extraction
//

import Foundation
import CoreLocation

#if canImport(ImageIO)
import ImageIO
#endif

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - PlatformImage EXIF Accessor

#if canImport(ImageIO) && canImport(CoreLocation)
/// EXIF metadata accessor for PlatformImage
/// Provides clean, cross-platform access to image EXIF metadata
public struct PlatformImageEXIF {
    // Module-internal so writer extensions in companion files can read the
    // wrapped image and its `originalEncodedData` (Issue #275). Not part of
    // the public API surface.
    internal let image: PlatformImage
    
    public init(image: PlatformImage) {
        self.image = image
    }
    
    /// Extract GPS location from image EXIF metadata
    /// Returns nil if image has no GPS metadata or if extraction fails
    public var gpsLocation: CLLocation? {
        guard let imageData = extractImageData() else {
            return nil
        }
        
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }
        
        guard let gpsData = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            return nil
        }
        
        return extractLocation(from: gpsData)
    }
    
    /// Check if image has GPS location metadata
    public var hasGPSLocation: Bool {
        return gpsLocation != nil
    }
    
    // MARK: - Private Helper Methods
    
    /// Extract image data for EXIF parsing.
    /// When \`PlatformImage\` was created from \`init?(data:)\`, uses those bytes so \`CGImageSource\` sees the original container metadata (GPS, TIFF tags, etc.).
    /// Otherwise re-encodes the decoded bitmap as JPEG (best-effort): that path typically strips EXIF because the encoder writes a fresh container (Issue #274).
    private func extractImageData() -> Data? {
        if let data = image.originalEncodedData {
            return data
        }
        #if os(iOS)
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
    
    /// Extract CLLocation from GPS EXIF data dictionary
    private func extractLocation(from gpsData: [String: Any]) -> CLLocation? {
        // Extract latitude
        guard let latitude = extractCoordinate(from: gpsData, key: kCGImagePropertyGPSLatitude as String, refKey: kCGImagePropertyGPSLatitudeRef as String) else {
            return nil
        }
        
        // Extract longitude
        guard let longitude = extractCoordinate(from: gpsData, key: kCGImagePropertyGPSLongitude as String, refKey: kCGImagePropertyGPSLongitudeRef as String) else {
            return nil
        }
        
        // Extract altitude (optional)
        let altitude = extractAltitude(from: gpsData)
        
        // Extract horizontal accuracy (optional)
        let horizontalAccuracy = extractHorizontalAccuracy(from: gpsData)
        
        // Extract timestamp (optional)
        let timestamp = extractTimestamp(from: gpsData)
        
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude ?? 0.0,
            horizontalAccuracy: horizontalAccuracy ?? -1.0,
            verticalAccuracy: -1.0,
            timestamp: timestamp ?? Date()
        )
    }
    
    /// Extract coordinate (latitude or longitude) from GPS EXIF data
    /// Handles both decimal degrees and degrees/minutes/seconds formats
    private func extractCoordinate(from gpsData: [String: Any], key: String, refKey: String) -> Double? {
        guard let coordinateValue = gpsData[key] else {
            return nil
        }
        
        var coordinate: Double = 0.0
        
        // Handle decimal degrees format (most common)
        if let decimalValue = coordinateValue as? Double {
            coordinate = decimalValue
        } else if let decimalValue = coordinateValue as? Int {
            coordinate = Double(decimalValue)
        }
        // Handle rational number format (degrees/minutes/seconds)
        else if let rationalValue = coordinateValue as? [String: Any],
                let degrees = rationalValue["Degrees"] as? Double,
                let minutes = rationalValue["Minutes"] as? Double,
                let seconds = rationalValue["Seconds"] as? Double {
            coordinate = degrees + (minutes / 60.0) + (seconds / 3600.0)
        } else {
            return nil
        }
        
        // Apply hemisphere reference (N/S for latitude, E/W for longitude)
        if let ref = gpsData[refKey] as? String {
            if ref.uppercased() == "S" || ref.uppercased() == "W" {
                coordinate = -coordinate
            }
        }
        
        return coordinate
    }
    
    /// Extract altitude from GPS EXIF data
    private func extractAltitude(from gpsData: [String: Any]) -> Double? {
        guard let altitudeValue = gpsData[kCGImagePropertyGPSAltitude as String] else {
            return nil
        }
        
        var altitude: Double = 0.0
        
        if let decimalValue = altitudeValue as? Double {
            altitude = decimalValue
        } else if let decimalValue = altitudeValue as? Int {
            altitude = Double(decimalValue)
        } else {
            return nil
        }
        
        // Apply altitude reference (0 = above sea level, 1 = below sea level)
        if let ref = gpsData[kCGImagePropertyGPSAltitudeRef as String] as? Int, ref == 1 {
            altitude = -altitude
        }
        
        return altitude
    }
    
    /// Extract horizontal accuracy from GPS EXIF data
    private func extractHorizontalAccuracy(from gpsData: [String: Any]) -> Double? {
        guard let accuracyValue = gpsData[kCGImagePropertyGPSHPositioningError as String] else {
            return nil
        }
        
        if let decimalValue = accuracyValue as? Double {
            return decimalValue
        } else if let decimalValue = accuracyValue as? Int {
            return Double(decimalValue)
        }
        
        return nil
    }
    
    /// Extract timestamp from GPS EXIF data
    private func extractTimestamp(from gpsData: [String: Any]) -> Date? {
        // GPS timestamp is typically in format: "YYYY:MM:DD HH:MM:SS"
        guard let dateString = gpsData[kCGImagePropertyGPSDateStamp as String] as? String,
              let timeString = gpsData[kCGImagePropertyGPSTimeStamp as String] as? String else {
            return nil
        }
        
        let dateTimeString = "\(dateString) \(timeString)"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        return formatter.date(from: dateTimeString)
    }
}

// MARK: - PlatformImage Extension

public extension PlatformImage {
    /// Access EXIF metadata for this image
    var exif: PlatformImageEXIF {
        return PlatformImageEXIF(image: self)
    }
}

#else
// Fallback implementation for platforms without ImageIO/CoreLocation
public struct PlatformImageEXIF {
    // Module-internal so writer extensions in companion files can read the
    // wrapped image and its `originalEncodedData` (Issue #275). Not part of
    // the public API surface.
    internal let image: PlatformImage
    
    public init(image: PlatformImage) {
        self.image = image
    }
    
    public var gpsLocation: CLLocation? {
        return nil
    }
    
    public var hasGPSLocation: Bool {
        return false
    }
}

public extension PlatformImage {
    var exif: PlatformImageEXIF {
        return PlatformImageEXIF(image: self)
    }
}
#endif

