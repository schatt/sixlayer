import SwiftUI

// MARK: - Layer 2: Photo Layout Decision Engine

/// Determine optimal photo layout based on purpose and context
public func determineOptimalPhotoLayout_L2(
    purpose: PhotoPurpose,
    context: PhotoContext
) -> PlatformSize {
    let availableSpace = context.availableSpace
    let screenSize = context.screenSize
    let _ = context.deviceCapabilities
    
    // Base layout calculations
    let baseWidth = min(availableSpace.width, screenSize.width * 0.8)
    let baseHeight = min(availableSpace.height, screenSize.height * 0.6)
    
    // Adjust based on photo purpose
    switch purpose {
    case .general, .preview:
        // General photos benefit from wider aspect ratio
        return PlatformSize(
            width: baseWidth,
            height: baseWidth * 0.6 // 5:3 aspect ratio
        )
        
    case .document:
        // Documents are typically portrait
        return PlatformSize(
            width: baseWidth * 0.7,
            height: baseHeight
        )
        
    case .reference:
        // Reference photos are typically square thumbnails
        let size = min(baseWidth, baseHeight) * 0.6
        return PlatformSize(width: size, height: size)
        
    case .profile:
        // Profile photos are typically square
        let size = min(baseWidth, baseHeight) * 0.5
        return PlatformSize(width: size, height: size)
        
    case .thumbnail:
        // Thumbnails are small square images
        let size = min(baseWidth, baseHeight) * 0.3
        return PlatformSize(width: size, height: size)
        
    default:
        // Custom purposes default to general behavior
        return PlatformSize(
            width: baseWidth,
            height: baseWidth * 0.6
        )
    }
}

/// Determine photo capture strategy based on purpose and context
public func determinePhotoCaptureStrategy_L2(
    purpose: PhotoPurpose,
    context: PhotoContext
) -> PhotoCaptureStrategy {
    let preferences = context.userPreferences
    let capabilities = context.deviceCapabilities
    
    // Check device capabilities first
    let hasCamera = capabilities.hasCamera
    let hasPhotoLibrary = capabilities.hasPhotoLibrary
    
    // If only one option is available, use it
    if hasCamera && !hasPhotoLibrary {
        return .camera
    } else if !hasCamera && hasPhotoLibrary {
        return .photoLibrary
    } else if !hasCamera && !hasPhotoLibrary {
        // Fallback to photo library (user can select from files)
        return .photoLibrary
    }
    
    // Both options available - use user preferences
    switch preferences.preferredSource {
    case .camera:
        return .camera
    case .photoLibrary:
        return .photoLibrary
    case .both:
        // Prioritize camera when both options are available
        if hasCamera {
            return .camera
        } else {
            // Fallback to photo library if camera not available
            return .photoLibrary
        }
    }
}

// MARK: - Layout Optimization Helpers

/// Calculate optimal image size for display
public func calculateOptimalImageSize(
    for purpose: PhotoPurpose,
    in availableSpace: CGSize,
    maxResolution: CGSize = CGSize(width: 4096, height: 4096)
) -> PlatformSize {
    let layout = determineOptimalPhotoLayout_L2(
        purpose: purpose,
        context: PhotoContext(
            screenSize: availableSpace,
            availableSpace: availableSpace,
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
    )
    
    // Ensure we don't exceed maximum resolution
    let finalWidth = min(layout.width, Double(maxResolution.width))
    let finalHeight = min(layout.height, Double(maxResolution.height))
    
    return PlatformSize(width: finalWidth, height: finalHeight)
}

/// Determine if image should be cropped for purpose
public func shouldCropImage(
    for purpose: PhotoPurpose,
    imageSize: CGSize,
    targetSize: CGSize
) -> Bool {
    let aspectRatio = imageSize.width / imageSize.height
    let targetAspectRatio = targetSize.width / targetSize.height
    
    // Allow some tolerance for aspect ratio differences
    let tolerance: CGFloat = 0.1
    
    switch purpose {
    case .general, .document, .preview:
        // These purposes benefit from specific aspect ratios
        return abs(aspectRatio - targetAspectRatio) > tolerance
    case .reference, .profile, .thumbnail:
        // These are typically square or flexible
        return false
    default:
        // Custom purposes default to general behavior (flexible)
        return false
    }
}
