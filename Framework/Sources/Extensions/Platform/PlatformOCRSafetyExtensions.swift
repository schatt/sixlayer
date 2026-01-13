//
//  PlatformOCRSafetyExtensions.swift
//  SixLayerFramework
//
//  Safe Vision framework integration with availability checks and fallbacks
//

import Foundation
import SwiftUI

#if canImport(Vision)
import Vision
#endif

// MARK: - Vision Availability Types

/// Information about Vision framework availability
public struct VisionAvailabilityInfo {
    public let platform: String
    public let isAvailable: Bool
    public let minVersion: String
    public let isCompatible: Bool
    
    public init(platform: String, isAvailable: Bool, minVersion: String, isCompatible: Bool) {
        self.platform = platform
        self.isAvailable = isAvailable
        self.minVersion = minVersion
        self.isCompatible = isCompatible
    }
}

/// Safe OCR result that handles both success and fallback cases
public enum SafeOCRResult {
    case success(OCRResult)
    case fallback(OCRResult)
    case unavailable(Error)
}

// MARK: - Vision Availability Functions

/// Check if Vision framework is available on current platform
public func isVisionFrameworkAvailable() -> Bool {
    #if canImport(Vision)
    #if os(iOS)
    if #available(iOS 11.0, *) {
        return true
    } else {
        return false
    }
    #elseif os(macOS)
    if #available(macOS 10.15, *) {
        return true
    } else {
        return false
    }
    #else
    return false
    #endif
    #else
    return false
    #endif
}

/// Get detailed Vision framework availability information
public func getVisionAvailabilityInfo() -> VisionAvailabilityInfo {
    #if os(iOS)
    let platform = "iOS"
    let minVersion = "11.0"
    #if canImport(Vision)
    let isAvailable: Bool
    let isCompatible: Bool
    if #available(iOS 11.0, *) {
        isAvailable = true
        isCompatible = true
    } else {
        isAvailable = false
        isCompatible = false
    }
    #else
    let isAvailable = false
    let isCompatible = false
    #endif
    #elseif os(macOS)
    let platform = "macOS"
    let minVersion = "10.15"
    #if canImport(Vision)
    let isAvailable: Bool
    let isCompatible: Bool
    if #available(macOS 10.15, *) {
        isAvailable = true
        isCompatible = true
    } else {
        isAvailable = false
        isCompatible = false
    }
    #else
    let isAvailable = false
    let isCompatible = false
    #endif
    #else
    let platform = "Unknown"
    let minVersion = "N/A"
    let isAvailable = false
    let isCompatible = false
    #endif
    
    return VisionAvailabilityInfo(
        platform: platform,
        isAvailable: isAvailable,
        minVersion: minVersion,
        isCompatible: isCompatible
    )
}

/// Check if Vision OCR is specifically available
public func isVisionOCRAvailable() -> Bool {
    return isVisionFrameworkAvailable()
}


// MARK: - Safe Vision OCR View

#if canImport(Vision)
struct SafeVisionOCRView: View {
    let image: PlatformImage
    let context: OCRContext
    let strategy: OCRStrategy
    let onResult: (OCRResult) -> Void
    let onError: (Error) -> Void
    
    @State private var isProcessing = false
    @State private var result: OCRResult?
    @State private var error: Error?
    
    var body: some View {
        let i18n = InternationalizationService()
        return Group {
            if isProcessing {
                ProgressView(i18n.localizedString(for: "SixLayerFramework.ocr.processingOCR"))
                    .progressViewStyle(CircularProgressViewStyle())
            } else if result != nil {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.complete"))
                    .foregroundColor(.secondary)
            } else if let error = error {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.error") + ": \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.readyToProcess"))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            performSafeOCR()
        }
        .automaticCompliance(named: "SafeVisionOCRView")
    }
    
    private func performSafeOCR() {
        guard isVisionOCRAvailable() else {
            onError(OCRError.visionUnavailable)
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let result = try await performVisionOCR()
                await MainActor.run {
                    self.result = result
                    self.isProcessing = false
                    onResult(result)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isProcessing = false
                    onError(error)
                }
            }
        }
    }
    
    private func performVisionOCR() async throws -> OCRResult {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = getCGImage(from: image) else {
                continuation.resume(throwing: OCRError.invalidImage)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let result = processVisionResults(observations, context: context)
                continuation.resume(returning: result)
            }
            
            // Configure request based on strategy
            configureVisionRequest(request, strategy: strategy)
            
            // Perform request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func configureVisionRequest(_ request: VNRecognizeTextRequest, strategy: OCRStrategy) {
        request.recognitionLevel = strategy.processingMode == .neural ? .accurate : .fast
        request.usesLanguageCorrection = true
        request.recognitionLanguages = strategy.supportedLanguages.map { $0.rawValue }
    }
    
    private func processVisionResults(_ observations: [VNRecognizedTextObservation], context: OCRContext) -> OCRResult {
        var extractedText = ""
        var boundingBoxes: [CGRect] = []
        var textTypes: [TextType: String] = [:]
        var totalConfidence: Float = 0.0
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let text = topCandidate.string
            let confidence = topCandidate.confidence
            
            extractedText += text + "\n"
            totalConfidence += confidence
            
            if context.textTypes.contains(.price) && isPrice(text) {
                textTypes[.price] = text
            }
            if context.textTypes.contains(.date) && isDate(text) {
                textTypes[.date] = text
            }
            if context.textTypes.contains(.email) && isEmail(text) {
                textTypes[.email] = text
            }
            if context.textTypes.contains(.phone) && isPhone(text) {
                textTypes[.phone] = text
            }
            if context.textTypes.contains(.number) && isNumber(text) {
                textTypes[.number] = text
            }
            
            if context.textTypes.contains(.general) && textTypes.isEmpty {
                textTypes[.general] = text
            }
            
            // Convert bounding box to image coordinates
            let boundingBox = observation.boundingBox
            let imageSize = CGSize(width: image.size.width, height: image.size.height)
            let convertedBox = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))
            boundingBoxes.append(convertedBox)
        }
        
        let averageConfidence = observations.isEmpty ? 0.0 : totalConfidence / Float(observations.count)
        
        return OCRResult(
            extractedText: extractedText.trimmingCharacters(in: .whitespacesAndNewlines),
            confidence: averageConfidence,
            boundingBoxes: boundingBoxes,
            textTypes: textTypes,
            processingTime: 0.0,
            language: context.language
        )
    }
}
#endif

// MARK: - Fallback OCR View

struct FallbackOCRView: View {
    let image: PlatformImage
    let context: OCRContext
    let strategy: OCRStrategy
    let onResult: (OCRResult) -> Void
    let onError: (Error) -> Void
    
    @State private var isProcessing = false
    @State private var result: OCRResult?
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isProcessing {
                ProgressView("Processing OCR (Fallback)...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if result != nil {
                Text("OCR Complete (Fallback)")
                    .foregroundColor(.secondary)
            } else if let error = error {
                Text("OCR Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else {
                Text("Ready for OCR (Fallback)")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            performFallbackOCR()
        }
        .automaticCompliance(named: "FallbackOCRView")
    }
    
    private func performFallbackOCR() {
        isProcessing = true
        
        Task {
            do {
                let result = try await performMockOCR()
                await MainActor.run {
                    self.result = result
                    self.isProcessing = false
                    onResult(result)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isProcessing = false
                    onError(error)
                }
            }
        }
    }
    
    private func performMockOCR() async throws -> OCRResult {
        // Create mock result immediately (no artificial delay needed for mock/stub code)
        let mockText = generateMockText(for: context)
        let mockBoundingBoxes = generateMockBoundingBoxes(for: mockText)
        let mockTextTypes = generateMockTextTypes(for: mockText, context: context)
        
        return OCRResult(
            extractedText: mockText,
            confidence: 0.7, // Lower confidence for fallback
            boundingBoxes: mockBoundingBoxes,
            textTypes: mockTextTypes,
            processingTime: 1.0,
            language: context.language
        )
    }
    
    private func generateMockText(for context: OCRContext) -> String {
        var text = ""
        
        for textType in context.textTypes {
            switch textType {
            case .price:
                text += "$29.99\n"
            case .date:
                text += "01/15/2025\n"
            case .email:
                text += "user@example.com\n"
            case .phone:
                text += "(555) 123-4567\n"
            case .number:
                text += "12345\n"
            case .general:
                text += "Sample text content\n"
            case .address:
                text += "123 Main St, City, State 12345\n"
            case .url:
                text += "https://example.com\n"
            case .name:
                text += "John Doe\n"
            case .idNumber:
                text += "ID#: ABC123456\n"
            case .stationName:
                text += "Station: Shell Gas\n"
            case .total:
                text += "Total: $45.67\n"
            case .vendor:
                text += "From: Acme Corp\n"
            case .expiryDate:
                text += "Exp: 12/31/2025\n"
            case .quantity:
                text += "Qty: 5\n"
            case .unit:
                text += "gal\n"
            case .currency:
                text += "USD\n"
            case .percentage:
                text += "15%\n"
            case .postalCode:
                text += "12345\n"
            case .state:
                text += "CA\n"
            case .country:
                text += "USA\n"
            }
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func generateMockBoundingBoxes(for text: String) -> [CGRect] {
        let lines = text.components(separatedBy: .newlines)
        var boxes: [CGRect] = []
        
        for (index, line) in lines.enumerated() {
            let y = CGFloat(index) * 30.0
            let width = CGFloat(line.count) * 10.0
            let height = 25.0
            boxes.append(CGRect(x: 10, y: y, width: width, height: height))
        }
        
        return boxes
    }
    
    private func generateMockTextTypes(for text: String, context: OCRContext) -> [TextType: String] {
        var textTypes: [TextType: String] = [:]
        
        for textType in context.textTypes {
            switch textType {
            case .price:
                textTypes[.price] = "$29.99"
            case .date:
                textTypes[.date] = "01/15/2025"
            case .email:
                textTypes[.email] = "user@example.com"
            case .phone:
                textTypes[.phone] = "(555) 123-4567"
            case .number:
                textTypes[.number] = "12345"
            case .general:
                textTypes[.general] = "Sample text content"
            case .address:
                textTypes[.address] = "123 Main St, City, State 12345"
            case .url:
                textTypes[.url] = "https://example.com"
            case .name:
                textTypes[.name] = "John Doe"
            case .idNumber:
                textTypes[.idNumber] = "ABC123456"
            case .stationName:
                textTypes[.stationName] = "Shell Gas"
            case .total:
                textTypes[.total] = "$45.67"
            case .vendor:
                textTypes[.vendor] = "Acme Corp"
            case .expiryDate:
                textTypes[.expiryDate] = "12/31/2025"
            case .quantity:
                textTypes[.quantity] = "5"
            case .unit:
                textTypes[.unit] = "gal"
            case .currency:
                textTypes[.currency] = "USD"
            case .percentage:
                textTypes[.percentage] = "15%"
            case .postalCode:
                textTypes[.postalCode] = "12345"
            case .state:
                textTypes[.state] = "CA"
            case .country:
                textTypes[.country] = "USA"
            }
        }
        
        return textTypes
    }
}

// MARK: - Helper Functions

/// Get CGImage from PlatformImage
private func getCGImage(from image: PlatformImage) -> CGImage? {
    #if os(iOS)
    return image.uiImage.cgImage
    #elseif os(macOS)
    return image.nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
    #else
    return nil
    #endif
}

// MARK: - Text Type Detection Helpers

private func isPrice(_ text: String) -> Bool {
    let pricePattern = #"\$?\d+\.?\d*"#
    return text.range(of: pricePattern, options: .regularExpression) != nil
}

private func isDate(_ text: String) -> Bool {
    let datePattern = #"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}"#
    return text.range(of: datePattern, options: .regularExpression) != nil
}

private func isEmail(_ text: String) -> Bool {
    let emailPattern = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
    return text.range(of: emailPattern, options: .regularExpression) != nil
}

private func isPhone(_ text: String) -> Bool {
    let phonePattern = #"\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"#
    return text.range(of: phonePattern, options: .regularExpression) != nil
}

private func isNumber(_ text: String) -> Bool {
    let numberPattern = #"\d+"#
    return text.range(of: numberPattern, options: .regularExpression) != nil
}

// MARK: - Migration Notice

/// This file has been deprecated in favor of the new OCR service architecture.
/// OCR errors are now defined in OCRService.swift
