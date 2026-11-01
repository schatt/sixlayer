//
//  OCRExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 OCR functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework

struct Layer1OCRExamples: View {
    @State private var ocrResult: OCRDisambiguationResult?
    
    @State private var visualCorrectionResult: OCRResult?
    @State private var structuredDataResult: OCRResult?
    @State private var lastExportedLabelSummary: String?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 24) {
            ExampleSection(title: "OCR with Disambiguation") {
                OCRDisambiguationExamples(result: $ocrResult)
            }
            
            ExampleSection(title: "OCR with Visual Correction") {
                OCRVisualCorrectionExamples(result: $visualCorrectionResult)
            }
            
            ExampleSection(title: "Extract Structured Data") {
                ExtractStructuredDataExamples(result: $structuredDataResult)
            }

            ExampleSection(title: "Display OCR Label Harness (#609)") {
                DisplayOCRLabelHarnessExample(lastExportSummary: $lastExportedLabelSummary)
            }
        }
        .padding()
        .platformFrame()
    }
}

struct OCRDisambiguationExamples: View {
    @Binding var result: OCRDisambiguationResult?
    @State private var testImage: PlatformImage?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("OCR with Disambiguation")
                .font(.headline)
            
            if let image = testImage {
                platformOCRWithDisambiguation_L1(
                    image: image,
                    context: OCRContext(),
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
            if let uiImage = UIImage(systemName: "doc.text") {
                testImage = PlatformImage(uiImage: uiImage)
            }
            #elseif os(macOS)
            if let nsImage = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil) {
                testImage = PlatformImage(nsImage: nsImage)
            }
            #endif
        }
    }
}

struct OCRVisualCorrectionExamples: View {
    @Binding var result: OCRResult?
    @State private var testImage: PlatformImage?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("OCR with Visual Correction")
                .font(.headline)
            
            if let image = testImage {
                platformOCRWithVisualCorrection_L1(
                    image: image,
                    context: OCRContext(),
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
            #if os(iOS)
            if let uiImage = UIImage(systemName: "doc.text") {
                testImage = PlatformImage(uiImage: uiImage)
            }
            #elseif os(macOS)
            if let nsImage = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil) {
                testImage = PlatformImage(nsImage: nsImage)
            }
            #endif
        }
    }
}

struct ExtractStructuredDataExamples: View {
    @Binding var result: OCRResult?
    @State private var testImage: PlatformImage?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Extract Structured Data")
                .font(.headline)
            
            if let image = testImage {
                platformExtractStructuredData_L1(
                    image: image,
                    context: OCRContext(),
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
            #if os(iOS)
            if let uiImage = UIImage(systemName: "doc.text") {
                testImage = PlatformImage(uiImage: uiImage)
            }
            #elseif os(macOS)
            if let nsImage = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil) {
                testImage = PlatformImage(nsImage: nsImage)
            }
            #endif
        }
    }
}

struct DisplayOCRLabelHarnessExample: View {
    @Binding var lastExportSummary: String?

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Display OCR Label Harness")
                .font(.headline)

            platformDisplayOCRLabelHarness_L1 { package in
                lastExportSummary = "\(package.rows.count) row(s): "
                    + package.rows.map(\.confirmedText).joined(separator: " | ")
            }
            .frame(minHeight: 420)

            if let lastExportSummary {
                Text("Last export: \(lastExportSummary)")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
