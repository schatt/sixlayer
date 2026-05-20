//
//  PlatformOCRLayoutDecisionLayer2.swift
//  SixLayerFramework
//
//  Layer 2: OCR Layout Decision Functions
//  Cross-platform layout decisions for OCR operations
//

import SwiftUI
import Foundation

// MARK: - Layer 2: OCR Layout Decision Functions

/// Determine optimal OCR layout based on context and device capabilities
public func platformOCRLayout_L2(
    context: OCRContext,
    capabilities: OCRDeviceCapabilities? = nil
) -> OCRLayout {
    // Get device capabilities if not provided
    let deviceCapabilities = capabilities ?? getCurrentOCRDeviceCapabilities()
    
    // Determine max image size based on device capabilities
    let maxImageSize = determineMaxImageSize(
        context: context,
        capabilities: deviceCapabilities
    )
    
    // Determine recommended image size based on text types
    let recommendedImageSize = determineRecommendedImageSize(
        textTypes: context.textTypes,
        maxSize: maxImageSize
    )
    
    // Determine processing mode based on context and capabilities
    let processingMode = determineProcessingMode(
        context: context,
        capabilities: deviceCapabilities
    )
    
    // Create UI configuration based on context
    let uiConfiguration = createUIConfiguration(
        context: context,
        capabilities: deviceCapabilities
    )
    
    return OCRLayout(
        maxImageSize: maxImageSize,
        recommendedImageSize: recommendedImageSize,
        processingMode: processingMode,
        uiConfiguration: uiConfiguration
    )
}

/// Determine OCR layout for specific document type
public func platformDocumentOCRLayout_L2(
    documentType: DocumentType,
    context: OCRContext,
    capabilities: OCRDeviceCapabilities? = nil
) -> OCRLayout {
    // Get device capabilities if not provided
    let deviceCapabilities = capabilities ?? getCurrentOCRDeviceCapabilities()
    
    // Determine document-specific requirements
    let documentRequirements = getDocumentRequirements(documentType)
    
    // Adjust context based on document requirements
    let adjustedContext = adjustContextForDocument(
        context: context,
        requirements: documentRequirements
    )
    
    // Use standard layout determination with adjusted context
    return platformOCRLayout_L2(
        context: adjustedContext,
        capabilities: deviceCapabilities
    )
}

/// Determine OCR layout for receipt processing
public func platformReceiptOCRLayout_L2(
    context: OCRContext,
    capabilities: OCRDeviceCapabilities? = nil
) -> OCRLayout {
    // Receipt-specific context adjustments
    let receiptContext = OCRContext(
        textTypes: [.price, .number, .date, .general],
        language: context.language,
        confidenceThreshold: max(context.confidenceThreshold, 0.85),
        allowsEditing: context.allowsEditing,
        maxImageSize: context.maxImageSize,
        extractionHints: context.extractionHints,
        requiredFields: context.requiredFields,
        extractionMode: context.extractionMode,
        entityName: context.entityName,
        fieldRanges: context.fieldRanges,
        fieldAverages: context.fieldAverages,
        strictVisionTextTypeFiltering: context.strictVisionTextTypeFiltering,
        visionMinimumTextHeight: context.visionMinimumTextHeight
    )
    
    // Use document layout for receipts
    return platformDocumentOCRLayout_L2(
        documentType: .receipt,
        context: receiptContext,
        capabilities: capabilities
    )
}

/// Determine OCR layout for business card processing
public func platformBusinessCardOCRLayout_L2(
    context: OCRContext,
    capabilities: OCRDeviceCapabilities? = nil
) -> OCRLayout {
    // Business card-specific context adjustments
    let businessCardContext = OCRContext(
        textTypes: [.email, .phone, .address, .general],
        language: context.language,
        confidenceThreshold: context.confidenceThreshold,
        allowsEditing: context.allowsEditing,
        maxImageSize: context.maxImageSize,
        extractionHints: context.extractionHints,
        requiredFields: context.requiredFields,
        extractionMode: context.extractionMode,
        entityName: context.entityName,
        fieldRanges: context.fieldRanges,
        fieldAverages: context.fieldAverages,
        strictVisionTextTypeFiltering: context.strictVisionTextTypeFiltering,
        visionMinimumTextHeight: context.visionMinimumTextHeight
    )
    
    // Use document layout for business cards
    return platformDocumentOCRLayout_L2(
        documentType: .businessCard,
        context: businessCardContext,
        capabilities: capabilities
    )
}

// MARK: - Helper Functions

/// Get current device capabilities for OCR
private func getCurrentOCRDeviceCapabilities() -> OCRDeviceCapabilities {
    #if os(iOS)
    return OCRDeviceCapabilities(
        hasVisionFramework: true,
        hasNeuralEngine: hasNeuralEngine(),
        maxImageSize: CGSize(width: 4000, height: 4000),
        supportedLanguages: [.english, .spanish, .french, .german],
        processingPower: hasNeuralEngine() ? .neural : .high
    )
    #elseif os(macOS)
    return OCRDeviceCapabilities(
        hasVisionFramework: true,
        hasNeuralEngine: false,
        maxImageSize: CGSize(width: 8000, height: 8000),
        supportedLanguages: [.english, .spanish, .french, .german],
        processingPower: .high
    )
    #else
    return OCRDeviceCapabilities(
        hasVisionFramework: false,
        hasNeuralEngine: false,
        maxImageSize: CGSize(width: 2000, height: 2000),
        supportedLanguages: [.english],
        processingPower: .low
    )
    #endif
}

/// Check if device has Neural Engine
private func hasNeuralEngine() -> Bool {
    #if os(iOS)
    // Check for Neural Engine availability
    return ProcessInfo.processInfo.processorCount >= 6
    #else
    return false
    #endif
}

/// Determine maximum image size based on context and capabilities
private func determineMaxImageSize(
    context: OCRContext,
    capabilities: OCRDeviceCapabilities
) -> CGSize {
    // Start with device capabilities
    var maxSize = capabilities.maxImageSize
    
    // Adjust based on context requirements
    if let contextMaxSize = context.maxImageSize {
        maxSize = CGSize(
            width: min(maxSize.width, contextMaxSize.width),
            height: min(maxSize.height, contextMaxSize.height)
        )
    }
    
    // Adjust based on text types
    if context.textTypes.contains(.price) || context.textTypes.contains(.number) {
        // Numbers need more width
        maxSize.width = max(maxSize.width, 1200)
    }
    
    if context.textTypes.contains(.address) {
        // Addresses need more height
        maxSize.height = max(maxSize.height, 1200)
    }
    
    return maxSize
}

/// Determine recommended image size based on text types
private func determineRecommendedImageSize(
    textTypes: [TextType],
    maxSize: CGSize
) -> CGSize {
    // Base recommended size
    var recommendedSize = CGSize(width: 1000, height: 1000)
    
    // Adjust based on text types
    if textTypes.contains(.price) || textTypes.contains(.number) {
        recommendedSize.width = max(recommendedSize.width, 1200)
    }
    
    if textTypes.contains(.address) {
        recommendedSize.height = max(recommendedSize.height, 1200)
    }
    
    if textTypes.contains(.date) {
        recommendedSize.width = max(recommendedSize.width, 800)
        recommendedSize.height = max(recommendedSize.height, 600)
    }
    
    // Ensure recommended size doesn't exceed max size
    recommendedSize.width = min(recommendedSize.width, maxSize.width)
    recommendedSize.height = min(recommendedSize.height, maxSize.height)
    
    return recommendedSize
}

/// Determine processing mode based on context and capabilities
private func determineProcessingMode(
    context: OCRContext,
    capabilities: OCRDeviceCapabilities
) -> OCRProcessingMode {
    // If neural engine is available and needed, use neural mode
    if capabilities.hasNeuralEngine && requiresNeuralEngine(context) {
        return .neural
    }
    
    // If high confidence is required, use accurate mode
    if context.confidenceThreshold > 0.9 {
        return .accurate
    }
    
    // If processing power is high, use standard mode
    if capabilities.processingPower == .high || capabilities.processingPower == .neural {
        return .standard
    }
    
    // Default to fast mode for lower-end devices
    return .fast
}

/// Check if neural engine is required for the context
private func requiresNeuralEngine(_ context: OCRContext) -> Bool {
    // Neural engine is beneficial for price and date recognition
    return context.textTypes.contains(.price) || 
           context.textTypes.contains(.date) ||
           context.confidenceThreshold > 0.9
}

/// Create UI configuration based on context and capabilities
private func createUIConfiguration(
    context: OCRContext,
    capabilities: OCRDeviceCapabilities
) -> OCRUIConfiguration {
    // Determine if we should show confidence
    let showConfidence = context.confidenceThreshold < 0.8
    
    // Determine if we should show bounding boxes
    let showBoundingBoxes = context.textTypes.count > 1 || 
                           context.textTypes.contains(.price) ||
                           context.textTypes.contains(.date)
    
    // Determine theme based on system preferences
    let theme = determineOptimalTheme()
    
    return OCRUIConfiguration(
        showProgress: true,
        showConfidence: showConfidence,
        showBoundingBoxes: showBoundingBoxes,
        allowEditing: context.allowsEditing,
        theme: theme
    )
}

/// Determine optimal theme for OCR UI
private func determineOptimalTheme() -> OCRTheme {
    #if os(iOS)
    // Use system theme on iOS
    return .system
    #elseif os(macOS)
    // Use system theme on macOS
    return .system
    #else
    // Default to light theme on other platforms
    return .light
    #endif
}

/// Get document-specific requirements
private func getDocumentRequirements(_ documentType: DocumentType) -> DocumentRequirements {
    switch documentType {
    case .receipt:
        return DocumentRequirements(
            minConfidence: 0.85,
            requiresBoundingBoxes: true,
            preferredImageSize: CGSize(width: 1200, height: 800),
            processingMode: .accurate
        )
    case .invoice:
        return DocumentRequirements(
            minConfidence: 0.9,
            requiresBoundingBoxes: true,
            preferredImageSize: CGSize(width: 1600, height: 1200),
            processingMode: .accurate
        )
    case .businessCard:
        return DocumentRequirements(
            minConfidence: 0.8,
            requiresBoundingBoxes: false,
            preferredImageSize: CGSize(width: 800, height: 500),
            processingMode: .standard
        )
    case .form:
        return DocumentRequirements(
            minConfidence: 0.85,
            requiresBoundingBoxes: true,
            preferredImageSize: CGSize(width: 1200, height: 1600),
            processingMode: .neural
        )
    case .license, .passport:
        return DocumentRequirements(
            minConfidence: 0.9,
            requiresBoundingBoxes: true,
            preferredImageSize: CGSize(width: 1000, height: 600),
            processingMode: .neural
        )
    case .general:
        return DocumentRequirements(
            minConfidence: 0.8,
            requiresBoundingBoxes: false,
            preferredImageSize: CGSize(width: 1000, height: 1000),
            processingMode: .standard
        )
    case .fuelReceipt:
        return DocumentRequirements(
            minConfidence: 0.85,
            requiresBoundingBoxes: true,
            preferredImageSize: CGSize(width: 1200, height: 800),
            processingMode: .accurate
        )
    case .idDocument:
        return DocumentRequirements(
            minConfidence: 0.9,
            requiresBoundingBoxes: true,
            preferredImageSize: CGSize(width: 800, height: 500),
            processingMode: .accurate
        )
    case .medicalRecord:
        return DocumentRequirements(
            minConfidence: 0.9,
            requiresBoundingBoxes: true,
            preferredImageSize: CGSize(width: 1200, height: 1600),
            processingMode: .accurate
        )
    case .legalDocument:
        return DocumentRequirements(
            minConfidence: 0.9,
            requiresBoundingBoxes: true,
            preferredImageSize: CGSize(width: 1200, height: 1600),
            processingMode: .accurate
        )
    }
}

/// Adjust context based on document requirements
private func adjustContextForDocument(
    context: OCRContext,
    requirements: DocumentRequirements
) -> OCRContext {
    return OCRContext(
        textTypes: context.textTypes,
        language: context.language,
        confidenceThreshold: max(context.confidenceThreshold, requirements.minConfidence),
        allowsEditing: context.allowsEditing,
        maxImageSize: context.maxImageSize ?? requirements.preferredImageSize,
        extractionHints: context.extractionHints,
        requiredFields: context.requiredFields,
        extractionMode: context.extractionMode,
        entityName: context.entityName,
        fieldRanges: context.fieldRanges,
        fieldAverages: context.fieldAverages,
        strictVisionTextTypeFiltering: context.strictVisionTextTypeFiltering,
        visionMinimumTextHeight: context.visionMinimumTextHeight
    )
}

// MARK: - Supporting Types

/// Document-specific requirements
private struct DocumentRequirements {
    let minConfidence: Float
    let requiresBoundingBoxes: Bool
    let preferredImageSize: CGSize
    let processingMode: OCRProcessingMode
}






