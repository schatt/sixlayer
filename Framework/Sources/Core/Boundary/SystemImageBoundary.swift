//
//  SystemImageBoundary.swift
//  SixLayerFramework
//
//  System boundary layer that handles conversion between platform-specific image types
//  and PlatformImage. This is where the "currency exchange" happens.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// System boundary layer for image conversion
/// This is where UIImage/NSImage → PlatformImage conversion happens
@MainActor
public class SystemImageBoundary {
    
    #if os(iOS)
    /// Convert UIImage to PlatformImage at system boundary
    public static func convertUIImageToPlatformImage(_ uiImage: UIImage) -> PlatformImage {
        return PlatformImage(uiImage: uiImage)
    }
    
    /// Convert UIImagePickerController result to PlatformImage
    public static func convertPickerResult(_ info: [UIImagePickerController.InfoKey: Any]) -> PlatformImage? {
        guard let uiImage = info[.originalImage] as? UIImage else { return nil }
        return convertUIImageToPlatformImage(uiImage)
    }
    #endif
    
    #if os(macOS)
    /// Convert NSImage to PlatformImage at system boundary
    public static func convertNSImageToPlatformImage(_ nsImage: NSImage) -> PlatformImage {
        return PlatformImage(nsImage: nsImage)
    }
    
    /// Convert NSImagePicker result to PlatformImage
    public static func convertPickerResult(_ nsImage: NSImage?) -> PlatformImage? {
        guard let nsImage = nsImage else { return nil }
        return convertNSImageToPlatformImage(nsImage)
    }
    #endif
}

/// Platform-specific image picker wrappers that handle system boundary conversion
#if os(iOS)
public struct SystemImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (PlatformImage) -> Void
    
    public init(onImageSelected: @escaping (PlatformImage) -> Void) {
        self.onImageSelected = onImageSelected
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SystemImagePicker
        
        init(_ parent: SystemImagePicker) {
            self.parent = parent
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // System boundary conversion: UIImage → PlatformImage
            if let platformImage = SystemImageBoundary.convertPickerResult(info) {
                parent.onImageSelected(platformImage)
            }
            if shouldDismissSystemImagePickerAfterSelection(
                presentingViewController: picker.presentingViewController
            ) {
                picker.dismiss(animated: true)
            }
        }
    }
}

public struct SystemCameraPicker: UIViewControllerRepresentable {
    let onImageCaptured: (PlatformImage) -> Void
    
    public init(onImageCaptured: @escaping (PlatformImage) -> Void) {
        self.onImageCaptured = onImageCaptured
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SystemCameraPicker
        
        init(_ parent: SystemCameraPicker) {
            self.parent = parent
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // System boundary conversion: UIImage → PlatformImage
            if let platformImage = SystemImageBoundary.convertPickerResult(info) {
                parent.onImageCaptured(platformImage)
            }
            if shouldDismissSystemImagePickerAfterSelection(
                presentingViewController: picker.presentingViewController
            ) {
                picker.dismiss(animated: true)
            }
        }
    }
}
#endif
