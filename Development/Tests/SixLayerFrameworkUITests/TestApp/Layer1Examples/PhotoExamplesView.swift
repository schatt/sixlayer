//
//  PhotoExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 photo functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework

struct Layer1PhotoExamples: View {
    @State private var capturedImage: PlatformImage?
    @State private var selectedImage: PlatformImage?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 24) {
            ExampleSection(title: "Photo Capture") {
                PhotoCaptureExamples(capturedImage: $capturedImage)
            }
            
            ExampleSection(title: "Photo Selection") {
                PhotoSelectionExamples(selectedImage: $selectedImage)
            }
            
            ExampleSection(title: "Photo Display") {
                PhotoDisplayExamples(image: capturedImage ?? selectedImage)
            }
        }
        .padding()
    }
}

struct PhotoCaptureExamples: View {
    @Binding var capturedImage: PlatformImage?
    
    private var photoContext: PhotoContext {
        PhotoContext(
            screenSize: CGSize(width: 375, height: 667),
            availableSpace: CGSize(width: 375, height: 667),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
    }
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Photo Capture")
                .font(.headline)
            
            platformPhotoCapture_L1(
                purpose: .general,
                context: photoContext,
                onImageCaptured: { image in
                    capturedImage = image
                }
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct PhotoSelectionExamples: View {
    @Binding var selectedImage: PlatformImage?
    
    private var photoContext: PhotoContext {
        PhotoContext(
            screenSize: CGSize(width: 375, height: 667),
            availableSpace: CGSize(width: 375, height: 667),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
    }
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Photo Selection")
                .font(.headline)
            
            platformPhotoSelection_L1(
                purpose: .general,
                context: photoContext,
                onImageSelected: { image in
                    selectedImage = image
                }
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct PhotoDisplayExamples: View {
    let image: PlatformImage?
    
    private var photoContext: PhotoContext {
        PhotoContext(
            screenSize: CGSize(width: 375, height: 667),
            availableSpace: CGSize(width: 375, height: 667),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
    }
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Photo Display")
                .font(.headline)
            
            platformPhotoDisplay_L1(
                purpose: .general,
                context: photoContext,
                image: image
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

private struct ExampleSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
            
            content()
        }
    }
}
