//
//  UnifiedImagePicker.swift
//  SixLayerFramework
//
//  Unified cross-platform image picker that provides a single API
//  for both iOS and macOS, returning PlatformImage consistently.
//
//  This is the core unified API - the whole point of our framework.
//

import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#if canImport(PhotosUI)
import PhotosUI
#endif
#elseif os(macOS)
import AppKit
#endif

/// Unified cross-platform image picker
/// Provides a single API that works identically on iOS and macOS
/// Always returns PlatformImage (never platform-specific types)
public struct UnifiedImagePicker: View {
    let onImageSelected: (PlatformImage) -> Void
    
    nonisolated public init(onImageSelected: @escaping (PlatformImage) -> Void) {
        self.onImageSelected = onImageSelected
    }
    
    public var body: some View {
        Group {
            #if os(iOS)
            iOSImagePicker(onImageSelected: onImageSelected)
            #elseif os(macOS)
            macOSImagePicker(onImageSelected: onImageSelected)
            #else
            let i18n = InternationalizationService()
            Text(i18n.localizedString(for: "SixLayerFramework.imagePicker.notAvailable"))
            #endif
        }
        .automaticCompliance(named: "UnifiedImagePicker")
    }
}

// MARK: - iOS Implementation

#if os(iOS)
private struct iOSImagePicker: View {
    let onImageSelected: (PlatformImage) -> Void
    
    var body: some View {
        if #available(iOS 14.0, *) {
            ModernImagePicker(onImageSelected: onImageSelected)
        } else {
            LegacyImagePicker(onImageSelected: onImageSelected)
        }
    }
}

// MARK: - Modern PHPickerViewController Implementation (iOS 14+)

@available(iOS 14.0, *)
private struct ModernImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (PlatformImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> ModernCoordinator {
        ModernCoordinator(self)
    }
    
    class ModernCoordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ModernImagePicker
        
        init(_ parent: ModernImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else {
                return
            }
            
            // Load the image from the result
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    // Capture the UIImage before crossing concurrency boundary
                    guard let uiImage = object as? UIImage else {
                        return
                    }
                    Task { @MainActor in
                        guard let self = self else {
                            return
                        }
                        // System boundary conversion: UIImage → PlatformImage
                        let platformImage = PlatformImage(uiImage)
                        self.parent.onImageSelected(platformImage)
                    }
                }
            }
        }
        
        // For testing
        func simulateImageSelection(_ image: PlatformImage) {
            parent.onImageSelected(image)
        }
    }
}

// MARK: - Legacy UIImagePickerController Implementation (iOS 13)

private struct LegacyImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (PlatformImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> LegacyCoordinator {
        LegacyCoordinator(self)
    }
    
    class LegacyCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LegacyImagePicker
        
        init(_ parent: LegacyImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // System boundary conversion: UIImage → PlatformImage
            if let uiImage = info[.originalImage] as? UIImage {
                let platformImage = PlatformImage(uiImage)
                parent.onImageSelected(platformImage)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        // For testing
        @MainActor
        func simulateImageSelection(_ image: PlatformImage) {
            parent.onImageSelected(image)
        }
    }
}
#endif

// MARK: - macOS Implementation

#if os(macOS)
private struct macOSImagePicker: NSViewControllerRepresentable {
    let onImageSelected: (PlatformImage) -> Void
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        let i18n = InternationalizationService()
        let button = NSButton(title: i18n.localizedString(for: "SixLayerFramework.button.chooseImage"), target: context.coordinator, action: #selector(Coordinator.chooseImage))
        button.bezelStyle = .rounded
        controller.view = button
        return controller
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, @unchecked Sendable {
        let parent: macOSImagePicker
        
        init(_ parent: macOSImagePicker) {
            self.parent = parent
        }
        
        @MainActor
        @objc func chooseImage() {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [
                .jpeg,
                .png,
                .gif,
                .bmp,
                .tiff,
                .heic,
                .heif,
                .webP
            ]
            
            if let window = NSApplication.shared.keyWindow {
                panel.beginSheetModal(for: window) { [weak self] response in
                    Task { @MainActor in
                        if response == .OK, let url = panel.url {
                            self?.handleFileSelection(url: url)
                        }
                    }
                }
            } else {
                let response = panel.runModal()
                if response == .OK, let url = panel.url {
                    handleFileSelection(url: url)
                }
            }
        }
        
        @MainActor
        func handleFileSelection(url: URL) {
            // System boundary conversion: File URL → Data → PlatformImage
            platformSecurityScopedAccess(url: url) { accessibleURL in
                guard let data = try? Data(contentsOf: accessibleURL),
                      let platformImage = PlatformImage(data: data) else {
                    return
                }
                
                parent.onImageSelected(platformImage)
            }
        }
        
        // For testing
        @MainActor
        func simulateImageSelection(_ image: PlatformImage) {
            parent.onImageSelected(image)
        }
    }
}
#endif

