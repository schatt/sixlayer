//
//  OCROverlaySheetModifier.swift
//  SixLayerFramework
//
//  OCR Overlay Sheet Modifier
//  Implements Issue #22: Feature Request: OCR Overlay Sheet Modifier
//
//  Provides a convenient way to present OCROverlayView in a sheet with
//  proper configuration, toolbar, and cross-platform support.
//

import SwiftUI

// MARK: - OCR Overlay Sheet Modifier

/// View modifier for presenting OCR overlay in a sheet
/// Implements Issue #22: OCR Overlay Sheet Modifier
public struct OCROverlaySheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let ocrResult: OCRResult?
    let ocrImage: PlatformImage?
    let configuration: OCROverlayConfiguration?
    let onTextEdit: ((String, CGRect) -> Void)?
    let onTextDelete: ((CGRect) -> Void)?
    
    public init(
        isPresented: Binding<Bool>,
        ocrResult: OCRResult?,
        ocrImage: PlatformImage?,
        configuration: OCROverlayConfiguration? = nil,
        onTextEdit: ((String, CGRect) -> Void)? = nil,
        onTextDelete: ((CGRect) -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.ocrResult = ocrResult
        self.ocrImage = ocrImage
        self.configuration = configuration
        self.onTextEdit = onTextEdit
        self.onTextDelete = onTextDelete
    }
    
    public func body(content: Content) -> some View {
        content
            .platformSheet_L4(
                isPresented: $isPresented,
                onDismiss: nil,
                sizes: [.large],
                dragIndicator: .automatic
            ) {
                sheetContent
            }
    }
    
    @ViewBuilder
    private var sheetContent: some View {
        if let result = ocrResult, let image = ocrImage {
            // Show OCR overlay with result and image
            OCROverlayView(
                image: image,
                result: result,
                configuration: configuration ?? OCROverlayConfiguration(),
                onTextEdit: onTextEdit ?? { _, _ in },
                onTextDelete: onTextDelete ?? { _ in }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    let i18n = InternationalizationService()
                    Button(i18n.localizedString(for: "SixLayerFramework.button.done")) {
                        isPresented = false
                    }
                }
            }
            .automaticCompliance(named: "OCROverlaySheet")
        } else {
            // Show error state when result or image is nil
            errorStateView
        }
    }
    
    @ViewBuilder
    private var errorStateView: some View {
        let i18n = InternationalizationService()
        
        platformVStackContainer(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(i18n.localizedString(for: "SixLayerFramework.ocr.overlay.unavailable"))
                .font(.headline)
            
            if ocrResult == nil && ocrImage == nil {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.overlay.bothRequired"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if ocrResult == nil {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.overlay.resultMissing"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.overlay.imageMissing"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                let i18n = InternationalizationService()
                Button(i18n.localizedString(for: "SixLayerFramework.button.done")) {
                    isPresented = false
                }
            }
        }
        .automaticCompliance(named: "OCROverlaySheetError")
    }
}

// MARK: - View Extension

public extension View {
    /// Present OCR overlay in a sheet with toolbar and proper configuration
    /// Implements Issue #22: OCR Overlay Sheet Modifier
    ///
    /// This modifier provides a convenient way to present `OCROverlayView` in a sheet
    /// with cross-platform support, toolbar with Done button, and proper error handling.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control sheet presentation
    ///   - ocrResult: Optional OCR result to display
    ///   - ocrImage: Optional image that was processed
    ///   - configuration: Optional overlay configuration (uses defaults if nil)
    ///   - onTextEdit: Optional callback when text is edited
    ///   - onTextDelete: Optional callback when text is deleted
    /// - Returns: View with OCR overlay sheet modifier applied
    func ocrOverlaySheet(
        isPresented: Binding<Bool>,
        ocrResult: OCRResult?,
        ocrImage: PlatformImage?,
        configuration: OCROverlayConfiguration? = nil,
        onTextEdit: ((String, CGRect) -> Void)? = nil,
        onTextDelete: ((CGRect) -> Void)? = nil
    ) -> some View {
        modifier(OCROverlaySheetModifier(
            isPresented: isPresented,
            ocrResult: ocrResult,
            ocrImage: ocrImage,
            configuration: configuration,
            onTextEdit: onTextEdit,
            onTextDelete: onTextDelete
        ))
    }
}


