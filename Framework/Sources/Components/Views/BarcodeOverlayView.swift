//
//  BarcodeOverlayView.swift
//  SixLayerFramework
//
//  Barcode Overlay View - Visual interface for barcode scanning results
//

import SwiftUI

/// Barcode Overlay View - Visual interface for barcode scanning results
public struct BarcodeOverlayView: View {
    let image: PlatformImage
    let result: BarcodeResult
    let configuration: BarcodeOverlayConfiguration
    let onBarcodeSelect: (Barcode) -> Void
    
    public init(
        image: PlatformImage,
        result: BarcodeResult,
        configuration: BarcodeOverlayConfiguration = BarcodeOverlayConfiguration(),
        onBarcodeSelect: @escaping (Barcode) -> Void = { _ in }
    ) {
        self.image = image
        self.result = result
        self.configuration = configuration
        self.onBarcodeSelect = onBarcodeSelect
    }
    
    public var body: some View {
        let i18n = InternationalizationService()
        return platformVStackContainer(spacing: 16) {
            // Display image with barcode overlay
            ZStack {
                image.platformImageView()
                    .resizable()
                    .scaledToFit()
                    .automaticCompliance(named: "BarcodeImage")
                
                // Overlay bounding boxes if configured
                if configuration.showBoundingBoxes {
                    ForEach(Array(result.barcodes.enumerated()), id: \.offset) { index, barcode in
                        BarcodeBoundingBoxView(
                            barcode: barcode,
                            configuration: configuration,
                            onTap: {
                                onBarcodeSelect(barcode)
                            }
                        )
                    }
                }
            }
            
            // Display detected barcodes
            if result.hasBarcodes {
                platformVStackContainer(alignment: .leading, spacing: 12) {
                    Text(i18n.localizedString(for: "SixLayerFramework.barcode.detectedBarcodes"))
                        .font(.headline)
                        .automaticCompliance(named: "DetectedBarcodesLabel")
                    
                    ForEach(Array(result.barcodes.enumerated()), id: \.offset) { index, barcode in
                        BarcodeInfoView(
                            barcode: barcode,
                            index: index,
                            configuration: configuration
                        )
                        .onTapGesture {
                            onBarcodeSelect(barcode)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                platformVStackContainer(spacing: 8) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.platformFixedSystem(size: 32)) // overlay chrome: fixed size by design
                        .foregroundColor(.secondary)
                    
                    Text(i18n.localizedString(for: "SixLayerFramework.barcode.noBarcodesDetected"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(i18n.localizedString(for: "SixLayerFramework.barcode.tryDifferentImage"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .automaticCompliance(named: "NoBarcodesMessage")
            }
            
            // Show confidence score
            if configuration.showConfidenceIndicators && result.hasBarcodes {
                let confidencePercent = Int(result.confidence * 100)
                Text(i18n.localizedString(for: "SixLayerFramework.barcode.confidence", arguments: [String(confidencePercent)]))
                    .font(.caption)
                    .foregroundColor(confidenceColor(result.confidence))
                    .automaticCompliance(named: "ConfidenceScore")
            }
        }
        .padding()
        .automaticCompliance(named: "BarcodeOverlayView")
    }
    
    // MARK: - Helper Methods
    
    private func confidenceColor(_ confidence: Float) -> Color {
        if confidence >= configuration.highConfidenceThreshold {
            return .green
        } else if confidence >= configuration.lowConfidenceThreshold {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Barcode Bounding Box View

/// View for displaying a barcode's bounding box overlay
private struct BarcodeBoundingBoxView: View {
    let barcode: Barcode
    let configuration: BarcodeOverlayConfiguration
    let onTap: () -> Void
    
    var body: some View {
        // Note: In a real implementation, this would overlay the bounding box on the image
        // For now, this is a placeholder that would need GeometryReader to position correctly
        Rectangle()
            .stroke(configuration.highlightColor, lineWidth: 2)
            .background(
                Rectangle()
                    .fill(configuration.highlightColor.opacity(0.2))
            )
            .onTapGesture {
                onTap()
            }
            .automaticCompliance(named: "BarcodeBoundingBox")
    }
}

// MARK: - Barcode Info View

/// View for displaying barcode information
private struct BarcodeInfoView: View {
    let barcode: Barcode
    let index: Int
    let configuration: BarcodeOverlayConfiguration
    
    var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 4) {
            platformHStackContainer {
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.barcode.barcodeNumber", arguments: [String(index + 1)]))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if configuration.showConfidenceIndicators {
                    Text("\(Int(barcode.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(confidenceColor(barcode.confidence))
                }
            }
            
            if configuration.showBarcodeType {
                Text("Type: \(barcode.barcodeType.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if configuration.showPayload {
                #if os(tvOS) || os(watchOS)
                Text(barcode.payload)
                    .font(.body)
                    .automaticCompliance(named: "BarcodePayload")
                #else
                Text(barcode.payload)
                    .font(.body)
                    .platformTextSelection(.enabled)
                    .automaticCompliance(named: "BarcodePayload")
                #endif
            }
        }
        .padding(.vertical, 4)
        .automaticCompliance(named: "BarcodeInfo")
    }
    
    private func confidenceColor(_ confidence: Float) -> Color {
        if confidence >= configuration.highConfidenceThreshold {
            return .green
        } else if confidence >= configuration.lowConfidenceThreshold {
            return .orange
        } else {
            return .red
        }
    }
}
