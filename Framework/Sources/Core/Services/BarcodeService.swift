//
//  BarcodeService.swift
//  SixLayerFramework
//
//  Barcode Service - Business Logic Layer
//  Proper separation of concerns with async/await patterns
//

import Foundation
import SwiftUI

// watchOS ships a Vision module without barcode request APIs (#493; same gate as OCRService).
#if canImport(Vision) && !os(watchOS)
import Vision
#endif

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Barcode Service Protocol

/// Protocol defining barcode service capabilities
public protocol BarcodeServiceProtocol: Sendable {
    /// Process an image for barcode detection
    func processImage(
        _ image: PlatformImage,
        context: BarcodeContext
    ) async throws -> BarcodeResult
    
    /// Check if barcode scanning is available on current platform
    var isAvailable: Bool { get }
    
    /// Get platform-specific barcode scanning capabilities
    var capabilities: BarcodeCapabilities { get }
}

// MARK: - Barcode Service Implementation

/// Main barcode service implementation
public class BarcodeService: BarcodeServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    public var isAvailable: Bool {
        return isVisionBarcodeAvailable()
    }
    
    public var capabilities: BarcodeCapabilities {
        return getBarcodeCapabilities()
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Process an image for barcode detection
    public func processImage(
        _ image: PlatformImage,
        context: BarcodeContext
    ) async throws -> BarcodeResult {
        
        guard isAvailable else {
            throw BarcodeError.visionUnavailable
        }
        
        guard let cgImage = getCGImage(from: image) else {
            throw BarcodeError.invalidImage
        }
        
        return try await performVisionBarcodeDetection(
            cgImage: cgImage,
            context: context
        )
    }
    
    // MARK: - Private Methods
    
    private func performVisionBarcodeDetection(
        cgImage: CGImage,
        context: BarcodeContext
    ) async throws -> BarcodeResult {
        
        #if canImport(Vision) && !os(watchOS)
        #if os(iOS)
        guard #available(iOS 11.0, *) else {
            throw BarcodeError.unsupportedPlatform
        }
        #elseif os(macOS)
        guard #available(macOS 10.15, *) else {
            throw BarcodeError.unsupportedPlatform
        }
        #elseif os(visionOS)
        guard #available(visionOS 1.0, *) else {
            throw BarcodeError.unsupportedPlatform
        }
        #endif
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNBarcodeObservation] else {
                    // No barcodes found - return empty result
                    let emptyResult = BarcodeResult(
                        barcodes: [],
                        confidence: 0.0,
                        processingTime: 0.0
                    )
                    continuation.resume(returning: emptyResult)
                    return
                }
                
                let result = self.processVisionBarcodeResults(
                    observations: observations,
                    context: context
                )
                continuation.resume(returning: result)
            }
            
            // Configure request based on context
            configureVisionBarcodeRequest(request, context: context)
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: BarcodeError.processingFailed)
            }
        }
        #else
        throw BarcodeError.visionUnavailable
        #endif
    }
    
    #if canImport(Vision) && !os(watchOS)
    @available(iOS 11.0, macOS 10.15, visionOS 1.0, *)
    private func configureVisionBarcodeRequest(
        _ request: VNDetectBarcodesRequest,
        context: BarcodeContext
    ) {
        // Configure supported symbologies
        var symbologies: [VNBarcodeSymbology] = []
        for barcodeType in context.supportedBarcodeTypes {
            if let symbology = barcodeType.vnSymbology {
                symbologies.append(symbology)
            }
        }
        
        if !symbologies.isEmpty {
            request.symbologies = symbologies
        }
    }
    
    @available(iOS 11.0, macOS 10.15, visionOS 1.0, *)
    private func processVisionBarcodeResults(
        observations: [VNBarcodeObservation],
        context: BarcodeContext
    ) -> BarcodeResult {
        
        var barcodes: [Barcode] = []
        var totalConfidence: Float = 0.0
        let startTime = Date()
        
        for observation in observations {
            // Check confidence threshold
            guard observation.confidence >= context.confidenceThreshold else {
                continue
            }
            
            // Get payload string
            guard let payloadString = observation.payloadStringValue else {
                continue
            }
            
            // Convert VNBarcodeSymbology to BarcodeType
            let barcodeType = convertSymbologyToBarcodeType(observation.symbology)
            
            // Create barcode object
            let barcode = Barcode(
                payload: payloadString,
                barcodeType: barcodeType,
                boundingBox: observation.boundingBox,
                confidence: observation.confidence
            )
            
            barcodes.append(barcode)
            totalConfidence += observation.confidence
        }
        
        // Calculate average confidence
        let averageConfidence = barcodes.isEmpty ? 0.0 : totalConfidence / Float(barcodes.count)
        let processingTime = Date().timeIntervalSince(startTime)
        
        return BarcodeResult(
            barcodes: barcodes,
            confidence: averageConfidence,
            processingTime: processingTime
        )
    }
    
    @available(iOS 11.0, macOS 10.15, visionOS 1.0, *)
    private func convertSymbologyToBarcodeType(_ symbology: VNBarcodeSymbology) -> BarcodeType {
        // Handle all known symbologies
        if symbology == .ean8 { return .ean8 }
        if symbology == .ean13 { return .ean13 }
        if symbology == .upce { return .upcE }
        if symbology == .code128 { return .code128 }
        if symbology == .code39 { return .code39 }
        if symbology == .code93 { return .code93 }
        if symbology == .i2of5 { return .interleaved2of5 }
        if symbology == .itf14 { return .itf14 }
        if symbology == .qr { return .qrCode }
        if symbology == .dataMatrix { return .dataMatrix }
        if symbology == .pdf417 { return .pdf417 }
        if symbology == .aztec { return .aztec }
        
        // Handle msiPlessey if available (iOS 17.0+, macOS 14.0+)
        #if os(iOS)
        if #available(iOS 17.0, *) {
            if symbology == .msiPlessey { return .msiPlessey }
        }
        #elseif os(macOS)
        if #available(macOS 14.0, *) {
            if symbology == .msiPlessey { return .msiPlessey }
        }
        #endif
        
        // Fallback to QR code for unknown types
        return .qrCode
    }
    #endif
    
    private func getCGImage(from image: PlatformImage) -> CGImage? {
        #if os(iOS)
        return image.uiImage.cgImage
        #elseif os(macOS)
        return image.nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return nil
        #endif
    }
    
    private func isVisionBarcodeAvailable() -> Bool {
        #if canImport(Vision) && !os(watchOS)
        #if os(iOS)
        if #available(iOS 11.0, *) {
            return true
        }
        #elseif os(macOS)
        if #available(macOS 10.15, *) {
            return true
        }
        #elseif os(visionOS)
        if #available(visionOS 1.0, *) {
            return true
        }
        #endif
        #endif
        return false
    }
    
    private func getBarcodeCapabilities() -> BarcodeCapabilities {
        #if canImport(Vision) && !os(watchOS)
        #if os(iOS)
        if #available(iOS 11.0, *) {
            return BarcodeCapabilities(
                supportsVision: true,
                supportedBarcodeTypes: BarcodeType.allCases,
                maxImageSize: CGSize(width: 4096, height: 4096),
                processingTimeEstimate: 1.0
            )
        }
        #elseif os(macOS)
        if #available(macOS 10.15, *) {
            return BarcodeCapabilities(
                supportsVision: true,
                supportedBarcodeTypes: BarcodeType.allCases,
                maxImageSize: CGSize(width: 8192, height: 8192),
                processingTimeEstimate: 0.8
            )
        }
        #elseif os(visionOS)
        if #available(visionOS 1.0, *) {
            return BarcodeCapabilities(
                supportsVision: true,
                supportedBarcodeTypes: BarcodeType.allCases,
                maxImageSize: CGSize(width: 4096, height: 4096),
                processingTimeEstimate: 1.0
            )
        }
        #endif
        #endif
        
        return BarcodeCapabilities(
            supportsVision: false,
            supportedBarcodeTypes: [],
            maxImageSize: .zero,
            processingTimeEstimate: 0.0
        )
    }
}

// MARK: - Barcode Service Factory

/// Factory for creating barcode services
public class BarcodeServiceFactory {
    
    /// Create a barcode service instance
    public static func create() -> BarcodeServiceProtocol {
        return BarcodeService()
    }
}
