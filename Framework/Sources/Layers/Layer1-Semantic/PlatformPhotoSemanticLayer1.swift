import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Layer 1: Semantic Photo Functions

/// Cross-platform semantic photo capture interface
/// Provides intelligent photo capture based on purpose and context
/// Note: Requires @MainActor because it calls main-actor isolated L4 methods
@ViewBuilder
@MainActor
public func platformPhotoCapture_L1(
    purpose: PhotoPurpose,
    context: PhotoContext,
    onImageCaptured: @escaping (PlatformImage) -> Void
) -> some View {
    // Determine the best capture strategy based on purpose and context
    let strategy = selectPhotoCaptureStrategy_L3(purpose: purpose, context: context)
    
    switch strategy {
    case .camera:
        // Use camera interface for direct capture
        PlatformPhotoComponentsLayer4.platformCameraInterface_L4(onImageCaptured: onImageCaptured)
            .automaticCompliance()
    case .photoLibrary:
        // Use photo library picker
        PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: onImageCaptured)
            .automaticCompliance()
    case .both:
        // Provide both options
        VStack {
            PlatformPhotoComponentsLayer4.platformCameraInterface_L4(onImageCaptured: onImageCaptured)
                .automaticCompliance()
            PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: onImageCaptured)
                .automaticCompliance()
        }
        .automaticCompliance()
    }
}

/// Cross-platform semantic photo selection interface
/// Provides intelligent photo selection based on purpose and context
/// Note: Requires @MainActor because it calls main-actor isolated L4 methods
@ViewBuilder
@MainActor
public func platformPhotoSelection_L1(
    purpose: PhotoPurpose,
    context: PhotoContext,
    onImageSelected: @escaping (PlatformImage) -> Void
) -> some View {
    // Determine optimal layout for selection interface
    let layout = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
    
    // Use photo picker with optimized layout
    PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: onImageSelected)
        .frame(width: layout.width, height: layout.height)
        .automaticCompliance()
}

/// Cross-platform semantic photo display interface
/// Provides intelligent photo display based on purpose and context
/// Note: Requires @MainActor because it calls main-actor isolated L4 methods
@ViewBuilder
@MainActor
public func platformPhotoDisplay_L1(
    purpose: PhotoPurpose,
    context: PhotoContext,
    image: PlatformImage?
) -> some View {
    // Determine optimal display strategy
    let _ = selectPhotoDisplayStrategy_L3(purpose: purpose, context: context)
    
    // Determine optimal layout
    let layout = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
    
    // Create display with semantic styling
    PlatformPhotoComponentsLayer4.platformPhotoDisplay_L4(
        image: image,
        style: displayStyleForPurpose(purpose)
    )
    .frame(width: layout.width, height: layout.height)
    .automaticCompliance()
}

// MARK: - Custom View Support

/// Cross-platform semantic photo capture interface with custom camera view wrapper
/// Allows custom UI wrappers around the core photo capture functionality
///
/// - Parameters:
///   - purpose: The purpose of the photo capture
///   - context: The photo context
///   - onImageCaptured: Callback when image is captured
///   - customCameraView: Optional view builder that wraps the camera interface with custom styling
/// - Returns: A view presenting the photo capture interface with optional custom wrapper
public func platformPhotoCapture_L1<CameraContent: View>(
    purpose: PhotoPurpose,
    context: PhotoContext,
    onImageCaptured: @escaping (PlatformImage) -> Void,
    customCameraView: ((AnyView) -> CameraContent)? = nil
) -> some View {
    // Determine the best capture strategy based on purpose and context
    let strategy = selectPhotoCaptureStrategy_L3(purpose: purpose, context: context)
    
    let baseView: AnyView
    switch strategy {
    case .camera:
        // Use camera interface for direct capture
        baseView = AnyView(PlatformPhotoComponentsLayer4.platformCameraInterface_L4(onImageCaptured: onImageCaptured)
            .automaticCompliance())
    case .photoLibrary:
        // Use photo library picker
        baseView = AnyView(PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: onImageCaptured)
            .automaticCompliance())
    case .both:
        // Provide both options
        baseView = AnyView(VStack {
            PlatformPhotoComponentsLayer4.platformCameraInterface_L4(onImageCaptured: onImageCaptured)
                .automaticCompliance()
            PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: onImageCaptured)
                .automaticCompliance()
        }
        .automaticCompliance())
    }
    
    // Apply custom wrapper if provided, otherwise return default
    if let customWrapper = customCameraView {
        return AnyView(customWrapper(baseView))
    } else {
        return baseView
    }
}

/// Cross-platform semantic photo selection interface with custom picker view wrapper
/// Allows custom UI wrappers around the core photo selection functionality
///
/// - Parameters:
///   - purpose: The purpose of the photo selection
///   - context: The photo context
///   - onImageSelected: Callback when image is selected
///   - customPickerView: Optional view builder that wraps the picker interface with custom styling
/// - Returns: A view presenting the photo selection interface with optional custom wrapper
public func platformPhotoSelection_L1<PickerContent: View>(
    purpose: PhotoPurpose,
    context: PhotoContext,
    onImageSelected: @escaping (PlatformImage) -> Void,
    customPickerView: ((AnyView) -> PickerContent)? = nil
) -> some View {
    // Determine optimal layout for selection interface
    let layout = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
    
    // Create base picker view
    let basePickerView = AnyView(PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: onImageSelected)
        .frame(width: layout.width, height: layout.height)
        .automaticCompliance())
    
    // Apply custom wrapper if provided, otherwise return default
    if let customWrapper = customPickerView {
        return AnyView(customWrapper(basePickerView))
    } else {
        return basePickerView
    }
}

/// Cross-platform semantic photo display interface with custom display view wrapper
/// Allows custom UI wrappers around the core photo display functionality
///
/// - Parameters:
///   - purpose: The purpose of the photo display
///   - context: The photo context
///   - image: The image to display (optional)
///   - customDisplayView: Optional view builder that wraps the display interface with custom styling
/// - Returns: A view presenting the photo display interface with optional custom wrapper
public func platformPhotoDisplay_L1<DisplayContent: View>(
    purpose: PhotoPurpose,
    context: PhotoContext,
    image: PlatformImage?,
    customDisplayView: ((AnyView) -> DisplayContent)? = nil
) -> some View {
    // Determine optimal display strategy
    let _ = selectPhotoDisplayStrategy_L3(purpose: purpose, context: context)
    
    // Determine optimal layout
    let layout = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
    
    // Create base display view
    let baseDisplayView = AnyView(PlatformPhotoComponentsLayer4.platformPhotoDisplay_L4(
        image: image,
        style: displayStyleForPurpose(purpose)
    )
    .frame(width: layout.width, height: layout.height)
    .automaticCompliance())
    
    // Apply custom wrapper if provided, otherwise return default
    if let customWrapper = customDisplayView {
        return AnyView(customWrapper(baseDisplayView))
    } else {
        return baseDisplayView
    }
}

// MARK: - Helper Functions

/// Determine display style based on photo purpose
private func displayStyleForPurpose(_ purpose: PhotoPurpose) -> PhotoDisplayStyle {
    switch purpose {
    case .vehiclePhoto:
        return .aspectFit
    case .fuelReceipt, .pumpDisplay, .odometer:
        return .fullSize
    case .maintenance, .expense, .document:
        return .thumbnail
    case .profile:
        return .rounded
    }
}

/// Photo capture strategy enum
public enum PhotoCaptureStrategy: String, CaseIterable {
    case camera = "camera"
    case photoLibrary = "photo_library"
    case both = "both"
}

/// Photo display strategy enum
public enum PhotoDisplayStrategy: String, CaseIterable {
    case thumbnail = "thumbnail"
    case fullSize = "full_size"
    case aspectFit = "aspect_fit"
    case aspectFill = "aspect_fill"
    case rounded = "rounded"
}
