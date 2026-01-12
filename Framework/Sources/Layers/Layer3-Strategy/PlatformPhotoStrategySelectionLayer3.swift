import SwiftUI

// MARK: - Layer 3: Photo Strategy Selection

/// Select optimal photo capture strategy based on purpose and context
public func selectPhotoCaptureStrategy_L3(
    purpose: PhotoPurpose,
    context: PhotoContext
) -> PhotoCaptureStrategy {
    let preferences = context.userPreferences
    let capabilities = context.deviceCapabilities
    let _ = context.screenSize
    
    // Check device capabilities
    let hasCamera = capabilities.hasCamera
    let hasPhotoLibrary = capabilities.hasPhotoLibrary
    
    // If device doesn't support both, return what's available
    if !hasCamera && !hasPhotoLibrary {
        return .photoLibrary // Fallback to file selection
    } else if hasCamera && !hasPhotoLibrary {
        return .camera
    } else if !hasCamera && hasPhotoLibrary {
        return .photoLibrary
    }
    
    // Both available - use intelligent selection
    let strategy = determinePhotoCaptureStrategy_L2(purpose: purpose, context: context)
    
    // Override with user preferences if they conflict with optimal strategy
    switch preferences.preferredSource {
    case .camera:
        return hasCamera ? .camera : .photoLibrary
    case .photoLibrary:
        return hasPhotoLibrary ? .photoLibrary : .camera
    case .both:
        return strategy
    }
}

/// Select optimal photo display strategy based on purpose and context
public func selectPhotoDisplayStrategy_L3(
    purpose: PhotoPurpose,
    context: PhotoContext
) -> PhotoDisplayStrategy {
    let availableSpace = context.availableSpace
    let screenSize = context.screenSize
    
    // Calculate space utilization
    let spaceUtilization = (availableSpace.width * availableSpace.height) / (screenSize.width * screenSize.height)
    
    // Determine strategy based on purpose and available space
    switch purpose {
    case .general:
        // General photos benefit from aspect fit
        return spaceUtilization > 0.3 ? .aspectFit : .thumbnail
        
    case .document:
        // Documents need full size for readability
        return spaceUtilization > 0.2 ? .fullSize : .aspectFit
        
    case .reference:
        // Reference photos are typically thumbnails
        return .thumbnail
        
    case .profile:
        // Profile photos are typically rounded
        return .rounded
        
    case .thumbnail:
        // Thumbnails are always thumbnails
        return .thumbnail
        
    case .preview:
        // Previews need to be readable
        return spaceUtilization > 0.25 ? .aspectFit : .thumbnail
    }
}

// MARK: - Strategy Optimization Helpers

/// Determine if photo editing should be available
public func shouldEnablePhotoEditing(
    for purpose: PhotoPurpose,
    context: PhotoContext
) -> Bool {
    let preferences = context.userPreferences
    let capabilities = context.deviceCapabilities
    
    // Check if editing is supported and allowed
    guard capabilities.supportsEditing && preferences.allowEditing else {
        return false
    }
    
    // Determine based on purpose
    switch purpose {
    case .general, .profile:
        // These benefit from basic editing (crop, rotate)
        return true
    case .document:
        // Documents should remain unedited for authenticity
        return false
    case .reference:
        // Reference photos can benefit from basic editing
        return true
    case .thumbnail, .preview:
        // Thumbnails and previews typically don't need editing
        return false
    }
}

/// Determine optimal compression quality for purpose
public func optimalCompressionQuality(
    for purpose: PhotoPurpose,
    context: PhotoContext
) -> Double {
    let preferences = context.userPreferences
    let baseQuality = preferences.compressionQuality
    
    // Adjust quality based on purpose
    switch purpose {
    case .general, .profile:
        // High quality for visual appeal
        return min(baseQuality + 0.1, 1.0)
        
    case .document:
        // High quality for text readability
        return min(baseQuality + 0.15, 1.0)
        
    case .reference:
        // Standard quality for reference photos
        return baseQuality
        
    case .thumbnail:
        // Lower quality for thumbnails (smaller file size)
        return max(baseQuality - 0.2, 0.5)
        
    case .preview:
        // Medium quality for previews
        return baseQuality
    }
}

/// Determine if photo should be automatically optimized
public func shouldAutoOptimize(
    for purpose: PhotoPurpose,
    context: PhotoContext
) -> Bool {
    // Auto-optimize based on purpose
    switch purpose {
    case .document:
        // Auto-optimize documents for text recognition
        return true
    case .general, .profile, .reference, .thumbnail, .preview:
        // Let user decide for these
        return false
    }
}
