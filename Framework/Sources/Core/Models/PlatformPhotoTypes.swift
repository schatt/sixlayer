//
//  PlatformPhotoTypes.swift
//  SixLayerFramework
//
//  Photo-related types and enums for cross-platform photo functionality
//

import Foundation
import SwiftUI

// MARK: - Photo Purpose Types

/// Represents different purposes for photos in applications
/// Generic, domain-agnostic purposes that work for any application
/// 
/// Projects can extend this by creating custom instances:
/// ```swift
/// extension PhotoPurpose {
///     static let vehiclePhoto = PhotoPurpose.general
///     static let fuelReceipt = PhotoPurpose.document
///     static let customPurpose = PhotoPurpose(identifier: "custom")
/// }
/// ```
public struct PhotoPurpose: Hashable, Sendable {
    /// Unique identifier for the photo purpose
    public let identifier: String
    
    /// Create a custom photo purpose with the given identifier
    /// - Parameter identifier: Unique string identifier for the purpose
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    // MARK: - Built-in Purposes
    
    /// General purpose photos
    public static let general = PhotoPurpose(identifier: "general")
    
    /// Document photos (receipts, forms, etc.)
    public static let document = PhotoPurpose(identifier: "document")
    
    /// Profile/avatar photos
    public static let profile = PhotoPurpose(identifier: "profile")
    
    /// Reference photos (maintenance, expense tracking, etc.)
    public static let reference = PhotoPurpose(identifier: "reference")
    
    /// Thumbnail/preview images
    public static let thumbnail = PhotoPurpose(identifier: "thumbnail")
    
    /// UI preview images
    public static let preview = PhotoPurpose(identifier: "preview")
    
    // MARK: - Built-in Purpose Collection
    
    /// All built-in photo purposes
    public static let allBuiltIn: [PhotoPurpose] = [
        .general,
        .document,
        .profile,
        .reference,
        .thumbnail,
        .preview
    ]
}

// MARK: - PhotoPurpose CustomStringConvertible

extension PhotoPurpose: CustomStringConvertible {
    public var description: String {
        return identifier
    }
}

// MARK: - Photo Context

/// Context information for photo operations
public struct PhotoContext {
    public let screenSize: PlatformSize
    public let availableSpace: PlatformSize
    public let userPreferences: PhotoPreferences
    public let deviceCapabilities: PhotoDeviceCapabilities
    
    public init(
        screenSize: PlatformSize,
        availableSpace: PlatformSize,
        userPreferences: PhotoPreferences,
        deviceCapabilities: PhotoDeviceCapabilities
    ) {
        self.screenSize = screenSize
        self.availableSpace = availableSpace
        self.userPreferences = userPreferences
        self.deviceCapabilities = deviceCapabilities
    }
    
    /// Convenience initializer that accepts CGSize and converts to PlatformSize
    public init(
        screenSize: CGSize,
        availableSpace: CGSize,
        userPreferences: PhotoPreferences,
        deviceCapabilities: PhotoDeviceCapabilities
    ) {
        self.screenSize = PlatformSize(screenSize)
        self.availableSpace = PlatformSize(availableSpace)
        self.userPreferences = userPreferences
        self.deviceCapabilities = deviceCapabilities
    }
}

// MARK: - Photo Preferences

/// User preferences for photo operations
public struct PhotoPreferences {
    public let preferredSource: PhotoSource
    public let allowEditing: Bool
    public let compressionQuality: Double
    public let maxImageSize: PlatformSize?
    
    public init(
        preferredSource: PhotoSource = .both,
        allowEditing: Bool = true,
        compressionQuality: Double = 0.8,
        maxImageSize: PlatformSize? = nil
    ) {
        self.preferredSource = preferredSource
        self.allowEditing = allowEditing
        self.compressionQuality = compressionQuality
        self.maxImageSize = maxImageSize
    }
}

// MARK: - Photo Source

/// Available photo sources
public enum PhotoSource: String, CaseIterable {
    case camera = "camera"
    case photoLibrary = "photo_library"
    case both = "both"
}

// MARK: - Photo Fallback Options

/// Fallback options when no photo is available
public enum PhotoFallback: String, CaseIterable {
    case systemIcon = "system_icon"
    case placeholder = "placeholder"
    case none = "none"
}

// MARK: - Photo Display Style

/// Different styles for displaying photos
public enum PhotoDisplayStyle: String, CaseIterable {
    case thumbnail = "thumbnail"
    case fullSize = "full_size"
    case aspectFit = "aspect_fit"
    case aspectFill = "aspect_fill"
    case rounded = "rounded"
}

// MARK: - Device Capabilities

/// Information about device capabilities for photo operations
public struct PhotoDeviceCapabilities {
    public let hasCamera: Bool
    public let hasPhotoLibrary: Bool
    public let supportsEditing: Bool
    public let maxImageResolution: PlatformSize
    
    public init(
        hasCamera: Bool = true,
        hasPhotoLibrary: Bool = true,
        supportsEditing: Bool = true,
        maxImageResolution: PlatformSize = PlatformSize(width: 4096, height: 4096)
    ) {
        self.hasCamera = hasCamera
        self.hasPhotoLibrary = hasPhotoLibrary
        self.supportsEditing = supportsEditing
        self.maxImageResolution = maxImageResolution
    }
}

// MARK: - Image Metadata

/// Metadata information about an image
public struct ImageMetadata {
    public let size: PlatformSize
    public let fileSize: Int
    public let format: ImageFormat
    public let hasAlpha: Bool
    public let colorSpace: String?
    
    public init(
        size: PlatformSize,
        fileSize: Int,
        format: ImageFormat,
        hasAlpha: Bool,
        colorSpace: String? = nil
    ) {
        self.size = size
        self.fileSize = fileSize
        self.format = format
        self.hasAlpha = hasAlpha
        self.colorSpace = colorSpace
    }
}

// MARK: - Image Format

/// Supported image formats
public enum ImageFormat: String {
    case jpeg = "jpeg"
    case png = "png"
    case heic = "heic"
    case tiff = "tiff"
    case unknown = "unknown"
}

// MARK: - Platform Keyboard Type

/// Cross-platform keyboard types
public enum PlatformKeyboardType: String, CaseIterable {
    case `default` = "default"
    case asciiCapable = "asciiCapable"
    case numbersAndPunctuation = "numbersAndPunctuation"
    case URL = "URL"
    case numberPad = "numberPad"
    case phonePad = "phonePad"
    case namePhonePad = "namePhonePad"
    case emailAddress = "emailAddress"
    case decimalPad = "decimalPad"
    case twitter = "twitter"
    case webSearch = "webSearch"
}

// MARK: - Platform Text Field Style

/// Cross-platform text field styles
public enum PlatformTextFieldStyle: String, CaseIterable {
    case defaultStyle = "default"
    case roundedBorder = "rounded_border"
    case plain = "plain"
    case secure = "secure"
}

// MARK: - Platform Location Authorization Status

/// Cross-platform location authorization status
public enum PlatformLocationAuthorizationStatus: String, CaseIterable {
    case notDetermined = "not_determined"
    case denied = "denied"
    case restricted = "restricted"
    case authorizedWhenInUse = "authorized_when_in_use" // iOS only
    case authorizedAlways = "authorized_always"
    case authorized = "authorized" // macOS equivalent
}
