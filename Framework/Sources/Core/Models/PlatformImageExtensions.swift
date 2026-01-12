//
//  PlatformImageExtensions.swift
//  SixLayerFramework
//
//  Enhanced PlatformImage extensions for photo processing and manipulation
//

import Foundation
import SwiftUI
import CoreGraphics
#if canImport(CoreImage)
import CoreImage
#endif

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Enhanced PlatformImage Extensions

public extension PlatformImage {
    
    /// Resize image to target size while maintaining aspect ratio
    func resized(to targetSize: CGSize) -> PlatformImage {
        // Handle empty or invalid sizes
        guard targetSize.width > 0 && targetSize.height > 0 else {
            return self
        }
        
        // Handle empty images
        guard !self.isEmpty else {
            return self
        }
        
        #if os(iOS)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            self.uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return PlatformImage(uiImage: resizedImage)
        #elseif os(macOS)
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        self.nsImage.draw(in: NSRect(origin: .zero, size: targetSize))
        resizedImage.unlockFocus()
        return PlatformImage(nsImage: resizedImage)
        #endif
    }
    
    /// Crop image to specified rectangle
    func cropped(to rect: CGRect) -> PlatformImage {
        // Handle invalid crop rectangles
        guard rect.width > 0 && rect.height > 0 else {
            return self
        }
        
        // Handle empty images
        guard !self.isEmpty else {
            return self
        }
        
        #if os(iOS)
        // Clamp rect to image bounds
        let imageSize = self.size
        let clampedRect = CGRect(
            x: max(0, min(rect.origin.x, imageSize.width)),
            y: max(0, min(rect.origin.y, imageSize.height)),
            width: min(rect.width, imageSize.width - max(0, rect.origin.x)),
            height: min(rect.height, imageSize.height - max(0, rect.origin.y))
        )
        
        guard clampedRect.width > 0 && clampedRect.height > 0,
              let cgImage = self.uiImage.cgImage?.cropping(to: clampedRect) else {
            return self
        }
        let croppedImage = UIImage(cgImage: cgImage)
        return PlatformImage(uiImage: croppedImage)
        #elseif os(macOS)
        // Clamp rect to image bounds
        let imageSize = self.size
        let clampedRect = CGRect(
            x: max(0, min(rect.origin.x, imageSize.width)),
            y: max(0, min(rect.origin.y, imageSize.height)),
            width: min(rect.width, imageSize.width - max(0, rect.origin.x)),
            height: min(rect.height, imageSize.height - max(0, rect.origin.y))
        )
        
        guard clampedRect.width > 0 && clampedRect.height > 0 else {
            return self
        }
        
        let croppedImage = NSImage(size: clampedRect.size)
        croppedImage.lockFocus()
        self.nsImage.draw(at: .zero, from: clampedRect, operation: .copy, fraction: 1.0)
        croppedImage.unlockFocus()
        return PlatformImage(nsImage: croppedImage)
        #endif
    }
    
    /// Apply compression for specific use case
    func compressed(for purpose: PhotoPurpose, quality: Double = 0.8) -> Data? {
        #if os(iOS)
        return self.uiImage.jpegData(compressionQuality: CGFloat(quality))
        #elseif os(macOS)
        guard let tiffData = self.nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            return nil
        }
        return jpegData
        #endif
    }
    
    /// Create thumbnail version
    func thumbnail(size: CGSize) -> PlatformImage {
        return self.resized(to: size)
    }
    
    /// Apply basic image processing for OCR
    func optimizedForOCR() -> PlatformImage {
        // For now, return the original image
        // In a real implementation, this would apply contrast enhancement, noise reduction, etc.
        return self
    }
    
    /// Get image metadata
    var metadata: ImageMetadata {
        #if os(iOS)
        let size = self.uiImage.size
        let data = self.uiImage.pngData() ?? Data()
        let format: ImageFormat = data.count > 0 ? .png : .unknown
        return ImageMetadata(
            size: PlatformSize(size),
            fileSize: data.count,
            format: format,
            hasAlpha: true
        )
        #elseif os(macOS)
        let size = self.nsImage.size
        let data = self.nsImage.tiffRepresentation ?? Data()
        let format: ImageFormat = data.count > 0 ? .tiff : .unknown
        return ImageMetadata(
            size: PlatformSize(size),
            fileSize: data.count,
            format: format,
            hasAlpha: true
        )
        #endif
    }
    
    /// Check if image meets minimum requirements for purpose
    func meetsRequirements(for purpose: PhotoPurpose) -> Bool {
        let metadata = self.metadata
        
        // Basic requirements check
        guard metadata.size.width > 0 && metadata.size.height > 0 else {
            return false
        }
        
        // Purpose-specific requirements
        switch purpose {
        case .general, .preview:
            return metadata.size.width >= 200 && metadata.size.height >= 200
        case .document:
            return metadata.size.width >= 400 && metadata.size.height >= 300
        case .reference, .profile, .thumbnail:
            return metadata.size.width >= 100 && metadata.size.height >= 100
        }
    }
    
    // size property is now defined in PlatformTypes.swift
    
    // MARK: - Phase 3: Export Methods
    
    /// Export image to PNG format
    /// Phase 3: Implements Issue #33
    func exportPNG() -> Data? {
        #if os(iOS)
        return self.uiImage.pngData()
        #elseif os(macOS)
        guard let tiffData = self.nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData
        #else
        return nil
        #endif
    }
    
    /// Export image to JPEG format
    /// Phase 3: Implements Issue #33
    func exportJPEG(quality: Double = 0.8) -> Data? {
        #if os(iOS)
        return self.uiImage.jpegData(compressionQuality: CGFloat(quality))
        #elseif os(macOS)
        guard let tiffData = self.nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            return nil
        }
        return jpegData
        #else
        return nil
        #endif
    }
    
    /// Export image to JPEG format (convenience method without quality parameter)
    /// Phase 3: Implements Issue #33
    func exportJPEG() -> Data? {
        return exportJPEG(quality: 0.8)
    }
    
    /// Export image to JPEG format (alias for exportJPEG)
    /// Phase 3: Implements Issue #33
    func exportJPG(quality: Double = 0.8) -> Data? {
        return exportJPEG(quality: quality)
    }
    
    /// Export image to bitmap format
    /// Phase 3: Implements Issue #33
    func exportBitmap() -> Data? {
        #if os(iOS)
        return self.uiImage.pngData()
        #elseif os(macOS)
        return self.nsImage.tiffRepresentation
        #else
        return nil
        #endif
    }
    
    // MARK: - Phase 3: Image Processing Methods
    
    /// Rotate image by specified angle in degrees
    /// Phase 3: Implements Issue #33
    func rotated(by angle: Double) -> PlatformImage {
        guard !self.isEmpty else {
            return self
        }
        
        #if os(iOS)
        let radians = angle * .pi / 180.0
        let rotatedSize = CGSize(
            width: abs(self.size.width * cos(radians)) + abs(self.size.height * sin(radians)),
            height: abs(self.size.width * sin(radians)) + abs(self.size.height * cos(radians))
        )
        
        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        let rotatedImage = renderer.image { context in
            context.cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.cgContext.rotate(by: CGFloat(radians))
            context.cgContext.translateBy(x: -self.size.width / 2, y: -self.size.height / 2)
            self.uiImage.draw(at: .zero)
        }
        return PlatformImage(uiImage: rotatedImage)
        #elseif os(macOS)
        let radians = angle * .pi / 180.0
        let rotatedSize = CGSize(
            width: abs(self.size.width * cos(radians)) + abs(self.size.height * sin(radians)),
            height: abs(self.size.width * sin(radians)) + abs(self.size.height * cos(radians))
        )
        
        let rotatedImage = NSImage(size: rotatedSize)
        rotatedImage.lockFocus()
        let context = NSGraphicsContext.current?.cgContext
        context?.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context?.rotate(by: CGFloat(radians))
        context?.translateBy(x: -self.size.width / 2, y: -self.size.height / 2)
        self.nsImage.draw(in: NSRect(origin: .zero, size: self.size))
        rotatedImage.unlockFocus()
        return PlatformImage(nsImage: rotatedImage)
        #else
        return self
        #endif
    }
    
    // MARK: - Phase 3: Core Image Helper Methods
    
    #if canImport(CoreImage)
    /// Convert PlatformImage to CIImage for processing
    /// Phase 3: Implements Issue #33
    private func toCIImage() -> CIImage? {
        #if os(iOS)
        return CIImage(image: self.uiImage)
        #elseif os(macOS)
        return CIImage(data: self.nsImage.tiffRepresentation ?? Data())
        #else
        return nil
        #endif
    }
    
    /// Apply Core Image filter and convert back to PlatformImage
    /// Phase 3: Implements Issue #33
    private func applyCIFilter(_ filter: CIFilter?, extent: CGRect? = nil) -> PlatformImage {
        guard let filter = filter,
              let outputImage = filter.outputImage else {
            return self
        }
        
        let renderExtent = extent ?? outputImage.extent
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(outputImage, from: renderExtent) else {
            return self
        }
        
        #if os(iOS)
        // Preserve original point-based size by keeping the original scale and orientation.
        // Using a scale of 1.0 here would inflate size to raw pixel dimensions (e.g. 300x300 for a @3x 100x100 image).
        let uiImage = UIImage(
            cgImage: cgImage,
            scale: self.uiImage.scale,
            orientation: self.uiImage.imageOrientation
        )
        return PlatformImage(uiImage: uiImage)
        #elseif os(macOS)
        // On macOS we already pass the logical size explicitly.
        return PlatformImage(cgImage: cgImage, size: self.size)
        #else
        return self
        #endif
    }
    
    /// Apply color controls filter (brightness, contrast, saturation)
    /// Phase 3: Implements Issue #33
    private func applyColorControls(brightness: Double? = nil, contrast: Double? = nil, saturation: Double? = nil) -> PlatformImage {
        guard !self.isEmpty,
              let ciImage = toCIImage() else {
            return self
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        if let brightness = brightness {
            filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        }
        if let contrast = contrast {
            filter?.setValue(contrast, forKey: kCIInputContrastKey)
        }
        if let saturation = saturation {
            filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        }
        
        return applyCIFilter(filter, extent: ciImage.extent)
    }
    #endif
    
    /// Adjust image brightness
    /// Phase 3: Implements Issue #33
    /// - Parameter amount: Brightness adjustment (-1.0 to 1.0, where 0.0 is no change)
    func adjustedBrightness(by amount: Double) -> PlatformImage {
        #if canImport(CoreImage)
        return applyColorControls(brightness: amount)
        #else
        return self
        #endif
    }
    
    /// Adjust image contrast
    /// Phase 3: Implements Issue #33
    /// - Parameter amount: Contrast adjustment (typically 0.0 to 2.0, where 1.0 is no change)
    func adjustedContrast(by amount: Double) -> PlatformImage {
        #if canImport(CoreImage)
        return applyColorControls(contrast: amount)
        #else
        return self
        #endif
    }
    
    /// Adjust image saturation
    /// Phase 3: Implements Issue #33
    /// - Parameter amount: Saturation adjustment (typically 0.0 to 2.0, where 1.0 is no change)
    func adjustedSaturation(by amount: Double) -> PlatformImage {
        #if canImport(CoreImage)
        return applyColorControls(saturation: amount)
        #else
        return self
        #endif
    }
    
    // MARK: - Phase 3: Filter Types
    
    /// Image filter types for Phase 3
    /// Phase 3: Implements Issue #33
    enum ImageFilter {
        case grayscale
        case blur(radius: Double)
        case sepia
    }
    
    /// Apply image filter
    /// Phase 3: Implements Issue #33
    func applyingFilter(_ filter: ImageFilter) -> PlatformImage {
        guard !self.isEmpty else {
            return self
        }
        
        #if canImport(CoreImage)
        guard let ciImage = toCIImage() else {
            return self
        }
        
        let filteredImage: CIImage?
        switch filter {
        case .grayscale:
            let filter = CIFilter(name: "CIColorMonochrome")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(CIColor.gray, forKey: kCIInputColorKey)
            filter?.setValue(1.0, forKey: kCIInputIntensityKey)
            filteredImage = filter?.outputImage
            
        case .blur(let radius):
            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(radius, forKey: kCIInputRadiusKey)
            if let output = filter?.outputImage {
                // Crop back to original extent to maintain size
                filteredImage = output.cropped(to: ciImage.extent)
            } else {
                filteredImage = nil
            }
            
        case .sepia:
            let filter = CIFilter(name: "CISepiaTone")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(0.8, forKey: kCIInputIntensityKey)
            filteredImage = filter?.outputImage
        }
        
        guard let outputImage = filteredImage else {
            return self
        }
        
        // Convert filtered CIImage back to PlatformImage using original extent
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            return self
        }
        
        #if os(iOS)
        // Preserve original logical size by honoring the original scale and orientation.
        let uiImage = UIImage(
            cgImage: cgImage,
            scale: self.uiImage.scale,
            orientation: self.uiImage.imageOrientation
        )
        return PlatformImage(uiImage: uiImage)
        #elseif os(macOS)
        return PlatformImage(cgImage: cgImage, size: self.size)
        #else
        return self
        #endif
        #else
        return self
        #endif
    }
    
    // MARK: - Phase 3: Image Properties
    
    /// Image properties structure for Phase 3
    /// Phase 3: Implements Issue #33
    struct ImageProperties {
        let width: CGFloat
        let height: CGFloat
        let size: CGSize
        let colorSpace: String?
        let pixelFormat: String?
        
        init(width: CGFloat, height: CGFloat, size: CGSize, colorSpace: String? = nil, pixelFormat: String? = nil) {
            self.width = width
            self.height = height
            self.size = size
            self.colorSpace = colorSpace
            self.pixelFormat = pixelFormat
        }
    }
    
    /// Get image properties
    /// Phase 3: Implements Issue #33
    var properties: ImageProperties {
        let size = self.size
        
        #if os(iOS)
        var colorSpaceName: String? = nil
        var pixelFormatName: String? = nil
        
        if let cgImage = self.uiImage.cgImage {
            if let colorSpace = cgImage.colorSpace {
                colorSpaceName = String(describing: colorSpace)
            }
            pixelFormatName = "\(cgImage.bitsPerPixel) bits per pixel, \(cgImage.bitsPerComponent) bits per component"
        }
        
        return ImageProperties(
            width: size.width,
            height: size.height,
            size: size,
            colorSpace: colorSpaceName,
            pixelFormat: pixelFormatName
        )
        #elseif os(macOS)
        var colorSpaceName: String? = nil
        var pixelFormatName: String? = nil
        
        if let cgImage = self.nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            if let colorSpace = cgImage.colorSpace {
                colorSpaceName = String(describing: colorSpace)
            }
            pixelFormatName = "\(cgImage.bitsPerPixel) bits per pixel, \(cgImage.bitsPerComponent) bits per component"
        }
        
        return ImageProperties(
            width: size.width,
            height: size.height,
            size: size,
            colorSpace: colorSpaceName,
            pixelFormat: pixelFormatName
        )
        #else
        return ImageProperties(
            width: size.width,
            height: size.height,
            size: size,
            colorSpace: nil,
            pixelFormat: nil
        )
        #endif
    }
}

// MARK: - Platform-Specific Image Extensions for Conversion

#if os(iOS)
public extension UIImage {
    /// Conversion from PlatformImage to UIImage (iOS only)
    /// This enables the currency exchange model: PlatformImage → UIImage at system boundary
    /// When leaving the framework (system boundary), convert PlatformImage → UIImage
    /// Note: Since PlatformImage wraps UIImage, we can't add a true convenience initializer,
    /// but this static method provides similar functionality
    static func from(_ platformImage: PlatformImage) -> UIImage {
        return platformImage.uiImage
    }
}
#elseif os(macOS)
public extension NSImage {
    /// Conversion from PlatformImage to NSImage (macOS only)
    /// This enables the currency exchange model: PlatformImage → NSImage at system boundary
    /// When leaving the framework (system boundary), convert PlatformImage → NSImage
    /// Note: Since PlatformImage wraps NSImage, we can't add a true convenience initializer,
    /// but this static method provides similar functionality
    static func from(_ platformImage: PlatformImage) -> NSImage {
        return platformImage.nsImage
    }
}
#endif

// MARK: - SwiftUI Image Extension

public extension Image {
    /// Create a SwiftUI Image from a PlatformImage
    init(platformImage: PlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage.uiImage)
        #elseif os(macOS)
        self.init(nsImage: platformImage.nsImage)
        #else
        self.init(systemName: "photo")
        #endif
    }
}
