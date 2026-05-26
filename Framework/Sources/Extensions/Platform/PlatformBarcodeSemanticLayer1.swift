//
//  PlatformBarcodeSemanticLayer1.swift
//  SixLayerFramework
//
//  Layer 1: Semantic Barcode Scanning Functions
//  Cross-platform barcode scanning intent interfaces
//

import SwiftUI
import Foundation

// MARK: - Layer 1: Semantic Barcode Scanning Functions

/// Cross-platform semantic barcode scanning intent interface
/// Provides intelligent barcode detection with result handling
@ViewBuilder
@MainActor
public func platformScanBarcode_L1(
    image: PlatformImage,
    context: BarcodeContext,
    onResult: @escaping (BarcodeResult) -> Void
) -> some View {
    BarcodeScanningWrapper(
        image: image,
        context: context,
        onResult: onResult
    )
    .environment(\.accessibilityIdentifierName, "platformScanBarcode_L1")
    .automaticAccessibility()
    .automaticCompliance()
}

// MARK: - Test Helper Functions

/// Direct barcode processing function for testing (bypasses SwiftUI view lifecycle)
public func processBarcodeForTesting(
    image: PlatformImage,
    context: BarcodeContext,
    onResult: @escaping @Sendable (BarcodeResult) -> Void
) {
    Task {
        do {
            let service = BarcodeServiceFactory.create()
            let result = try await service.processImage(image, context: context)
            await MainActor.run {
                onResult(result)
            }
        } catch {
            // Create a fallback result for testing
            let fallbackResult = BarcodeResult(
                barcodes: [],
                confidence: 0.0,
                processingTime: 0.0
            )
            await MainActor.run {
                onResult(fallbackResult)
            }
        }
    }
}

// MARK: - Barcode Scanning Wrapper

/// Internal wrapper view that handles barcode scanning processing
private struct BarcodeScanningWrapper: View {
    let image: PlatformImage
    let context: BarcodeContext
    let onResult: (BarcodeResult) -> Void
    
    @State private var isProcessing = false
    @State private var barcodeResult: BarcodeResult?
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            if isProcessing {
                processingView
            } else if let error = errorMessage {
                errorView(error)
            } else if let result = barcodeResult {
                resultView(result)
            } else {
                initialView
            }
        }
        .automaticCompliance()
        .onAppear {
            // Process image when view appears (only if not already processing)
            if !isProcessing && barcodeResult == nil && errorMessage == nil {
                processImage()
            }
        }
    }
    
    // MARK: - Processing View
    
    private var processingView: some View {
        platformVStackContainer(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Scanning Barcode...")
                .font(.headline)
            
            Text("Analyzing image for barcode detection")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        platformVStackContainer(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .platformDecorativeIconFont(designSize: 48)
                .foregroundColor(.red)
            
            Text("Barcode Scanning Error")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            let i18n = InternationalizationService()
            Button(i18n.localizedString(for: "SixLayerFramework.button.retry")) {
                processImage()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Result View
    
    private func resultView(_ result: BarcodeResult) -> some View {
        platformVStackContainer(spacing: 16) {
            if result.hasBarcodes {
                Image(systemName: "checkmark.circle.fill")
                    .platformDecorativeIconFont(designSize: 48)
                    .foregroundColor(.green)
                
                Text("Barcode Detected")
                    .font(.headline)
                
                Text("Found \(result.barcodes.count) barcode(s)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Display barcode information
                ForEach(Array(result.barcodes.enumerated()), id: \.offset) { index, barcode in
                    platformVStackContainer(alignment: .leading, spacing: 4) {
                        Text("Barcode \(index + 1):")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(barcode.payload)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Type: \(barcode.barcodeType.displayName)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            } else {
                Image(systemName: "barcode.viewfinder")
                    .platformDecorativeIconFont(designSize: 48)
                    .foregroundColor(.blue)
                
                Text("No Barcode Found")
                    .font(.headline)
                
                Text("No barcodes were detected in the image")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button("Scan Again") {
                processImage()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Initial View
    
    private var initialView: some View {
        platformVStackContainer(spacing: 16) {
            Image(systemName: "barcode.viewfinder")
                .platformDecorativeIconFont(designSize: 48)
                .foregroundColor(.blue)
            
            Text("Ready to Scan")
                .font(.headline)
            
            Text("Tap to start barcode scanning")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Scanning") {
                processImage()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Processing Logic
    
    private func processImage() {
        isProcessing = true
        errorMessage = nil
        barcodeResult = nil
        
        Task {
            do {
                let service = BarcodeServiceFactory.create()
                let result = try await service.processImage(image, context: context)
                
                await MainActor.run {
                    self.isProcessing = false
                    self.barcodeResult = result
                    self.onResult(result)
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
