import SwiftUI
import Foundation

#if os(iOS)
import UIKit
import AVFoundation
#elseif os(macOS)
import AppKit
import AVFoundation
#endif

// MARK: - Field Action Scanning Helpers

/// Helper view for barcode scanning workflow in field actions
/// Presents image picker, processes barcode, and returns result
@MainActor
public struct FieldActionBarcodeScanner: View {
    @Binding var isPresented: Bool
    let onResult: (String?) -> Void
    let onError: (Error) -> Void
    let hint: String?
    let supportedTypes: [BarcodeType]?
    
    @State private var showImagePicker = false
    @State private var isProcessing = false
    
    public init(
        isPresented: Binding<Bool>,
        onResult: @escaping (String?) -> Void,
        onError: @escaping (Error) -> Void,
        hint: String?,
        supportedTypes: [BarcodeType]?
    ) {
        self._isPresented = isPresented
        self.onResult = onResult
        self.onError = onError
        self.hint = hint
        self.supportedTypes = supportedTypes
    }
    
    public var body: some View {
        EmptyView()
            .sheet(isPresented: $showImagePicker) {
                UnifiedImagePicker { image in
                    Task {
                        await processBarcode(image: image)
                    }
                }
            }
            .onAppear {
                showImagePicker = true
            }
    }
    
    private func processBarcode(image: PlatformImage) async {
        isProcessing = true
        
        do {
            let context = BarcodeContext(
                supportedBarcodeTypes: supportedTypes ?? [.qrCode, .code128],
                confidenceThreshold: 0.8
            )
            
            let service = BarcodeServiceFactory.create()
            let result = try await service.processImage(image, context: context)
            
            if let firstBarcode = result.barcodes.first {
                isPresented = false
                onResult(firstBarcode.payload)
            } else {
                isPresented = false
                onError(NSError(
                    domain: "FieldAction",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No barcode found in image"]
                ))
            }
        } catch {
            isPresented = false
            onError(error)
        }
        
        isProcessing = false
    }
}

/// Helper view for OCR scanning workflow in field actions
/// Presents image picker, processes OCR, and returns result
/// Supports configurable photo sources: camera, photo library, or both
@MainActor
public struct FieldActionOCRScanner: View {
    @Binding var isPresented: Bool
    let onResult: (String?) -> Void
    let onError: (Error) -> Void
    let hint: String?
    let validationTypes: [TextType]?
    let allowedSources: PhotoSource
    
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showSourceSelection = false
    @State private var isProcessing = false
    
    public init(
        isPresented: Binding<Bool>,
        onResult: @escaping (String?) -> Void,
        onError: @escaping (Error) -> Void,
        hint: String?,
        validationTypes: [TextType]?,
        allowedSources: PhotoSource = .both
    ) {
        self._isPresented = isPresented
        self.onResult = onResult
        self.onError = onError
        self.hint = hint
        self.validationTypes = validationTypes
        self.allowedSources = allowedSources
    }
    
    public var body: some View {
        EmptyView()
            .sheet(isPresented: $showImagePicker) {
                UnifiedImagePicker { image in
                    Task {
                        await processOCR(image: image)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                #if os(iOS)
                SystemCameraPicker { image in
                    Task {
                        await processOCR(image: image)
                    }
                }
                #else
                // macOS camera interface
                PlatformPhotoComponentsLayer4.platformCameraInterface_L4 { image in
                    Task {
                        await processOCR(image: image)
                    }
                }
                #endif
            }
            .confirmationDialog(
                sourceSelectionTitle,
                isPresented: $showSourceSelection,
                titleVisibility: .visible
            ) {
                // Only show camera option if camera is available
                if checkCameraAvailability() {
                    Button(cameraButtonTitle) {
                        showCamera = true
                    }
                }
                Button(photoLibraryButtonTitle) {
                    showImagePicker = true
                }
                Button(cancelButtonTitle, role: .cancel) {
                    isPresented = false
                }
            }
            .onAppear {
                // Check device capabilities
                let hasCamera = checkCameraAvailability()
                let hasPhotoLibrary = true // Photo library is generally always available
                
                // Determine which UI to show based on allowedSources and device capabilities
                switch allowedSources {
                case .camera:
                    if hasCamera {
                        showCamera = true
                    } else {
                        // Fallback to photo library if camera not available
                        showImagePicker = true
                    }
                case .photoLibrary:
                    showImagePicker = true
                case .both:
                    if hasCamera && hasPhotoLibrary {
                        // Both available - show selection dialog
                        showSourceSelection = true
                    } else if hasCamera {
                        // Only camera available
                        showCamera = true
                    } else {
                        // Only photo library available (or neither, but photo library is fallback)
                        showImagePicker = true
                    }
                }
            }
    }
    
    // MARK: - Device Capability Detection
    
    /// Check if camera is available on the current device
    private func checkCameraAvailability() -> Bool {
        #if os(iOS)
        return UIImagePickerController.isSourceTypeAvailable(.camera)
        #elseif os(macOS)
        // On macOS, check if any video capture device is available
        if #available(macOS 14.0, *) {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .external],
                mediaType: .video,
                position: .unspecified
            )
            return !discoverySession.devices.isEmpty
        } else {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
                mediaType: .video,
                position: .unspecified
            )
            return !discoverySession.devices.isEmpty
        }
        #else
        return false
        #endif
    }
    
    // MARK: - Computed Properties for Localization
    
    private var sourceSelectionTitle: String {
        let i18n = InternationalizationService()
        return i18n.localizedString(for: "SixLayerFramework.ocr.selectSource")
    }
    
    private var cameraButtonTitle: String {
        let i18n = InternationalizationService()
        return i18n.localizedString(for: "SixLayerFramework.ocr.camera")
    }
    
    private var photoLibraryButtonTitle: String {
        let i18n = InternationalizationService()
        return i18n.localizedString(for: "SixLayerFramework.ocr.photoLibrary")
    }
    
    private var cancelButtonTitle: String {
        let i18n = InternationalizationService()
        return i18n.localizedString(for: "SixLayerFramework.common.cancel")
    }
    
    // MARK: - OCR Processing
    
    private func processOCR(image: PlatformImage) async {
        isProcessing = true
        
        do {
            let textTypes = validationTypes ?? [.general]
            let context = OCRContext(
                textTypes: textTypes,
                language: .english,
                extractionHints: [:],
                extractionMode: .automatic,
                entityName: nil
            )
            
            let service = OCRService()
            let strategy = OCRStrategy(
                supportedTextTypes: textTypes,
                supportedLanguages: [.english],
                processingMode: .standard,
                requiresNeuralEngine: false,
                estimatedProcessingTime: 1.0
            )
            
            let result = try await service.processImage(image, context: context, strategy: strategy)
            
            // Extract text from result
            let extractedText = result.extractedText
            
            isPresented = false
            onResult(extractedText)
        } catch {
            isPresented = false
            onError(error)
        }
        
        isProcessing = false
    }
}
