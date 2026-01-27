//
//  Layer3ExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 3 strategy selection functions
//  Issue #165
//

import SwiftUI
import SixLayerFramework

struct Layer3ExamplesView: View {
    var body: some View {
        ScrollView {
            platformVStack(alignment: .leading, spacing: 24) {
                ExampleSection(title: "OCR Strategy Selection") {
                    OCRStrategyExamples()
                }
            }
            .padding()
            .automaticCompliance(named: "Layer3ExamplesView")
        }
        .navigationTitle("Layer 3 Examples")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct OCRStrategyExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 3 functions select optimal strategies for OCR operations based on text types, document types, and platform capabilities.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // General OCR Strategy
            ExampleCard(title: "General OCR Strategy", description: "platformOCRStrategy_L3") {
                GeneralOCRStrategyExample()
            }
            
            // Document OCR Strategy
            ExampleCard(title: "Document OCR Strategy", description: "platformDocumentOCRStrategy_L3") {
                DocumentOCRStrategyExample()
            }
            
            // Receipt OCR Strategy
            ExampleCard(title: "Receipt OCR Strategy", description: "platformReceiptOCRStrategy_L3") {
                ReceiptOCRStrategyExample()
            }
            
            // Business Card OCR Strategy
            ExampleCard(title: "Business Card OCR Strategy", description: "platformBusinessCardOCRStrategy_L3") {
                BusinessCardOCRStrategyExample()
            }
            
            // Invoice OCR Strategy
            ExampleCard(title: "Invoice OCR Strategy", description: "platformInvoiceOCRStrategy_L3") {
                InvoiceOCRStrategyExample()
            }
            
            // Optimal OCR Strategy
            ExampleCard(title: "Optimal OCR Strategy", description: "platformOptimalOCRStrategy_L3") {
                OptimalOCRStrategyExample()
            }
            
            // Batch OCR Strategy
            ExampleCard(title: "Batch OCR Strategy", description: "platformBatchOCRStrategy_L3") {
                BatchOCRStrategyExample()
            }
        }
        .automaticCompliance(named: "OCRStrategyExamples")
    }
}

struct GeneralOCRStrategyExample: View {
    @State private var strategy: OCRStrategy?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Calculate Strategy") {
                strategy = platformOCRStrategy_L3(
                    textTypes: [.general, .number, .date],
                    platform: .current
                )
            }
            
            if let strategy = strategy {
                StrategyDetailsView(strategy: strategy)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .automaticCompliance(named: "GeneralOCRStrategyExample")
    }
}

struct DocumentOCRStrategyExample: View {
    @State private var strategy: OCRStrategy?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Calculate Document Strategy") {
                strategy = platformDocumentOCRStrategy_L3(
                    documentType: .general,
                    platform: .current
                )
            }
            
            if let strategy = strategy {
                StrategyDetailsView(strategy: strategy)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .automaticCompliance(named: "DocumentOCRStrategyExample")
    }
}

struct ReceiptOCRStrategyExample: View {
    @State private var strategy: OCRStrategy?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Calculate Receipt Strategy") {
                strategy = platformReceiptOCRStrategy_L3(platform: .current)
            }
            
            if let strategy = strategy {
                StrategyDetailsView(strategy: strategy)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .automaticCompliance(named: "ReceiptOCRStrategyExample")
    }
}

struct BusinessCardOCRStrategyExample: View {
    @State private var strategy: OCRStrategy?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Calculate Business Card Strategy") {
                strategy = platformBusinessCardOCRStrategy_L3(platform: .current)
            }
            
            if let strategy = strategy {
                StrategyDetailsView(strategy: strategy)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .automaticCompliance(named: "BusinessCardOCRStrategyExample")
    }
}

struct InvoiceOCRStrategyExample: View {
    @State private var strategy: OCRStrategy?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Calculate Invoice Strategy") {
                strategy = platformInvoiceOCRStrategy_L3(platform: .current)
            }
            
            if let strategy = strategy {
                StrategyDetailsView(strategy: strategy)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .automaticCompliance(named: "InvoiceOCRStrategyExample")
    }
}

struct OptimalOCRStrategyExample: View {
    @State private var strategy: OCRStrategy?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Calculate Optimal Strategy") {
                strategy = platformOptimalOCRStrategy_L3(
                    textTypes: [.price, .number, .date],
                    confidenceThreshold: 0.85,
                    platform: .current
                )
            }
            
            if let strategy = strategy {
                StrategyDetailsView(strategy: strategy)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .automaticCompliance(named: "OptimalOCRStrategyExample")
    }
}

struct BatchOCRStrategyExample: View {
    @State private var strategy: OCRStrategy?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Calculate Batch Strategy") {
                strategy = platformBatchOCRStrategy_L3(
                    textTypes: [.general, .number],
                    batchSize: 10,
                    platform: .current
                )
            }
            
            if let strategy = strategy {
                StrategyDetailsView(strategy: strategy)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .automaticCompliance(named: "BatchOCRStrategyExample")
    }
}

struct StrategyDetailsView: View {
    let strategy: OCRStrategy
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 8) {
            Text("Strategy Details")
                .font(.headline)
            
            Text("Processing Mode: \(strategy.processingMode.displayName)")
                .font(.caption)
            
            Text("Neural Engine: \(strategy.requiresNeuralEngine ? "Required" : "Not Required")")
                .font(.caption)
            
            Text("Supported Languages: \(strategy.supportedLanguages.count)")
                .font(.caption)
            
            if strategy.estimatedProcessingTime > 0 {
                Text("Estimated Time: \(String(format: "%.2f", strategy.estimatedProcessingTime))s")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.platformBackground)
        .cornerRadius(8)
        .automaticCompliance(named: "StrategyDetailsView")
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
        .automaticCompliance(named: "ExampleSection")
    }
}

private struct ExampleCard<Content: View>: View {
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
        .automaticCompliance(named: "ExampleCard")
    }
}
