//
//  PlatformOCRComponentsLayer4.swift
//  SixLayerFramework
//
//  Layer 4: OCR Component Implementation (DEPRECATED)
//  Cross-platform OCR components using Vision framework
//  This file is deprecated - use OCRService instead
//

import Foundation
import SwiftUI

#if canImport(Vision)
import Vision
#endif

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Layer 4: OCR Component Implementation (DEPRECATED)

/// Cross-platform OCR implementation using Vision framework
/// 
/// **DEPRECATED**: Use `OCRService.processImage()` instead
@available(*, deprecated, message: "Use OCRService.processImage() instead")
@ViewBuilder
public func platformOCRImplementation_L4(
    image: PlatformImage,
    context: OCRContext,
    strategy: OCRStrategy,
    onResult: @escaping (OCRResult) -> Void
) -> some View {
    // Return empty view and call result asynchronously
    EmptyView()
        .onAppear {
            let fallbackResult = OCRResult(
                extractedText: "OCR implementation failed: Use OCRService.processImage() instead",
                confidence: 0.0,
                boundingBoxes: [],
                textTypes: [:],
                processingTime: 0.0,
                language: context.language
            )
            onResult(fallbackResult)
        }
        .automaticCompliance()
}

/// Cross-platform text extraction implementation
/// 
/// **DEPRECATED**: Use `OCRService.processImage()` instead
@available(*, deprecated, message: "Use OCRService.processImage() instead")
@ViewBuilder
public func platformTextExtraction_L4(
    image: PlatformImage,
    context: OCRContext,
    layout: OCRLayout,
    strategy: OCRStrategy,
    onResult: @escaping (OCRResult) -> Void
) -> some View {
    // Return empty view and call result asynchronously
    EmptyView()
        .onAppear {
            let fallbackResult = OCRResult(
                extractedText: "Text extraction failed: Use OCRService.processImage() instead",
                confidence: 0.0,
                boundingBoxes: [],
                textTypes: [:],
                processingTime: 0.0,
                language: context.language
            )
            onResult(fallbackResult)
        }
        .automaticCompliance(named: "platformTextExtraction_L4")
}

/// Cross-platform text recognition implementation
/// 
/// **DEPRECATED**: Use `OCRService.processImage()` instead
@available(*, deprecated, message: "Use OCRService.processImage() instead")
@ViewBuilder
public func platformTextRecognition_L4(
    image: PlatformImage,
    options: TextRecognitionOptions,
    onResult: @escaping (OCRResult) -> Void
) -> some View {
    // Return empty view and call result asynchronously
    EmptyView()
        .onAppear {
            let fallbackResult = OCRResult(
                extractedText: "Text recognition failed: Use OCRService.processImage() instead",
                confidence: 0.0,
                boundingBoxes: [],
                textTypes: [:],
                processingTime: 0.0,
                language: .english
            )
            onResult(fallbackResult)
        }
        .automaticCompliance(named: "platformTextRecognition_L4")
}

// MARK: - Migration Notice

/// This file has been deprecated in favor of the new OCR service architecture.
/// 
/// **New Usage:**
/// ```swift
/// let service = OCRServiceFactory.create()
/// let result = try await service.processImage(image, context: context, strategy: strategy)
/// ```
/// 
/// **Benefits of New Architecture:**
/// - Proper separation of business logic from UI
/// - Testable with unit tests
/// - Modern async/await patterns
/// - Better error handling
/// - Improved performance