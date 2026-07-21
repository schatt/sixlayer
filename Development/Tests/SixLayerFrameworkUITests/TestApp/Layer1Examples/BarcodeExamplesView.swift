//
//  BarcodeExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 barcode scanning functions
//  Issue #166 / #369 — do not auto-start platformScanBarcode_L1 (.task → Vision hang).
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
        .platformFrame()
        .overlay(alignment: .topLeading) {
            Text("L1_Section_BarcodeScanning")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("L1_Section_BarcodeScanning")
                .padding(8)
                .allowsHitTesting(false)
        }
    }
}

struct BarcodeScanningExamples: View {
    @Binding var result: BarcodeResult?
    /// Explicit image only — no onAppear placeholder that would mount `platformScanBarcode_L1` and hang XCUI (#369).
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
                    .accessibilityIdentifier("L1_Barcode_NoTestImage")
                    .frame(height: 300)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

private struct ExampleSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
            content
        }
    }
}
