//
//  BarcodeExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 barcode scanning functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework

struct Layer1BarcodeExamples: View {
    @State private var barcodeResult: BarcodeResult?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 24) {
            ExampleSection(title: "Barcode Scanning") {
                BarcodeScanningExamples(result: $barcodeResult)
            }
        }
        .padding()
    }
}

struct BarcodeScanningExamples: View {
    @Binding var result: BarcodeResult?
    @State private var testImage: PlatformImage?
    
    private var barcodeContext: BarcodeContext {
        BarcodeContext(
            supportedBarcodeTypes: [.qrCode, .code128, .ean13],
            confidenceThreshold: 0.8,
            allowsMultipleBarcodes: true
        )
    }
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Barcode Scanning")
                .font(.headline)
            
            if let image = testImage {
                platformScanBarcode_L1(
                    image: image,
                    context: barcodeContext,
                    onResult: { result in
                        self.result = result
                    }
                )
                .frame(height: 300)
            } else {
                Text("No test image available")
                    .foregroundColor(.secondary)
                    .frame(height: 300)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .onAppear {
            // Create a placeholder image for testing
            // In real usage, this would come from camera or photo picker
            #if os(iOS)
            if let uiImage = UIImage(systemName: "barcode") {
                testImage = PlatformImage(uiImage: uiImage)
            }
            #elseif os(macOS)
            if let nsImage = NSImage(systemSymbolName: "barcode", accessibilityDescription: nil) {
                testImage = PlatformImage(nsImage: nsImage)
            }
            #endif
        }
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
