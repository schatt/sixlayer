//
//  Layer2ExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 2 layout decision functions
//  Issue #165
//

import SwiftUI
import SixLayerFramework

struct Layer2ExamplesView: View {
    var body: some View {
        ScrollView {
            platformVStack(alignment: .leading, spacing: 24) {
                ExampleSection(title: "OCR Layout Decisions") {
                    OCRLayoutExamples()
                }
            }
            .padding()
        }
        .navigationTitle("Layer 2 Examples")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct OCRLayoutExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 2 functions determine optimal layouts for OCR operations based on context and device capabilities.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // General OCR Layout
            ExampleCard(title: "General OCR Layout", description: "platformOCRLayout_L2") {
                GeneralOCRLayoutExample()
            }
            
            // Document OCR Layout
            ExampleCard(title: "Document OCR Layout", description: "platformDocumentOCRLayout_L2") {
                DocumentOCRLayoutExample()
            }
            
            // Receipt OCR Layout
            ExampleCard(title: "Receipt OCR Layout", description: "platformReceiptOCRLayout_L2") {
                ReceiptOCRLayoutExample()
            }
            
            // Business Card OCR Layout
            ExampleCard(title: "Business Card OCR Layout", description: "platformBusinessCardOCRLayout_L2") {
                BusinessCardOCRLayoutExample()
            }
        }
    }
}

struct GeneralOCRLayoutExample: View {
    @State private var layout: OCRLayout?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            let context = OCRContext(
                textTypes: [.general, .number, .date],
                language: .english,
                confidenceThreshold: 0.8,
                allowsEditing: true,
                maxImageSize: CGSize(width: 2000, height: 2000)
            )
            
            platformButton("Calculate Layout") {
                layout = platformOCRLayout_L2(context: context)
            }
            
            if let layout = layout {
                LayoutDetailsView(layout: layout)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct DocumentOCRLayoutExample: View {
    @State private var layout: OCRLayout?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            let context = OCRContext(
                textTypes: [.general, .number, .date],
                language: .english,
                confidenceThreshold: 0.85,
                allowsEditing: true,
                maxImageSize: CGSize(width: 3000, height: 4000)
            )
            
            platformButton("Calculate Document Layout") {
                layout = platformDocumentOCRLayout_L2(
                    documentType: .document,
                    context: context
                )
            }
            
            if let layout = layout {
                LayoutDetailsView(layout: layout)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct ReceiptOCRLayoutExample: View {
    @State private var layout: OCRLayout?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            let context = OCRContext(
                textTypes: [.price, .number, .date],
                language: .english,
                confidenceThreshold: 0.85,
                allowsEditing: true,
                maxImageSize: CGSize(width: 2000, height: 2000)
            )
            
            platformButton("Calculate Receipt Layout") {
                layout = platformReceiptOCRLayout_L2(context: context)
            }
            
            if let layout = layout {
                LayoutDetailsView(layout: layout)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct BusinessCardOCRLayoutExample: View {
    @State private var layout: OCRLayout?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            let context = OCRContext(
                textTypes: [.email, .phone, .address],
                language: .english,
                confidenceThreshold: 0.8,
                allowsEditing: true,
                maxImageSize: CGSize(width: 2000, height: 2000)
            )
            
            platformButton("Calculate Business Card Layout") {
                layout = platformBusinessCardOCRLayout_L2(context: context)
            }
            
            if let layout = layout {
                LayoutDetailsView(layout: layout)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct LayoutDetailsView: View {
    let layout: OCRLayout
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 8) {
            Text("Layout Details")
                .font(.headline)
            
            Text("Max Image Size: \(Int(layout.maxImageSize.width)) × \(Int(layout.maxImageSize.height))")
                .font(.caption)
            
            Text("Recommended Size: \(Int(layout.recommendedImageSize.width)) × \(Int(layout.recommendedImageSize.height))")
                .font(.caption)
            
            Text("Processing Mode: \(layout.processingMode.displayName)")
                .font(.caption)
        }
        .padding()
        .background(Color.platformBackground)
        .cornerRadius(8)
    }
}

struct ExampleCard<Content: View>: View {
    let title: String
    let description: String
    let content: () -> Content
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            content()
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
    }
}

struct ExampleSection<Content: View>: View {
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
