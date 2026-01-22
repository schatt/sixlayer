//
//  Layer1ExamplesApp.swift
//  SixLayerFrameworkRealUITests
//
//  RealUI test app for Layer 1 platform*_L1 functions
//  Provides examples of all Layer 1 functions for accessibility testing
//
//  Issue #166: Complete accessibility for Layer 1 platform* methods
//

import SwiftUI
import SixLayerFramework

/// Main app for Layer 1 examples
/// Organized by category for easy navigation
@main
struct Layer1ExamplesApp: App {
    var body: some Scene {
        WindowGroup {
            Layer1ExamplesContentView()
        }
    }
}

/// Content view with category navigation
struct Layer1ExamplesContentView: View {
    @State private var selectedCategory: Layer1Category = .dataPresentation
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with categories
            List(Layer1Category.allCases, selection: $selectedCategory) { category in
                NavigationLink(value: category) {
                    Label(category.displayName, systemImage: category.icon)
                }
            }
            .navigationTitle("Layer 1 Examples")
        } detail: {
            // Detail view with examples for selected category
            Layer1CategoryDetailView(category: selectedCategory)
        }
    }
}

/// Categories for organizing Layer 1 examples
enum Layer1Category: String, CaseIterable, Identifiable {
    case dataPresentation = "data_presentation"
    case navigation = "navigation"
    case photos = "photos"
    case security = "security"
    case ocr = "ocr"
    case notifications = "notifications"
    case internationalization = "internationalization"
    case dataAnalysis = "data_analysis"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dataPresentation: return "Data Presentation"
        case .navigation: return "Navigation"
        case .photos: return "Photos"
        case .security: return "Security"
        case .ocr: return "OCR"
        case .notifications: return "Notifications"
        case .internationalization: return "Internationalization"
        case .dataAnalysis: return "Data Analysis"
        }
    }
    
    var icon: String {
        switch self {
        case .dataPresentation: return "list.bullet.rectangle"
        case .navigation: return "arrow.triangle.branch"
        case .photos: return "photo"
        case .security: return "lock.shield"
        case .ocr: return "doc.text.viewfinder"
        case .notifications: return "bell"
        case .internationalization: return "globe"
        case .dataAnalysis: return "chart.bar"
        }
    }
}

/// Detail view for a category showing all examples
struct Layer1CategoryDetailView: View {
    let category: Layer1Category
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(category.displayName)
                    .font(.largeTitle)
                    .padding()
                
                switch category {
                case .dataPresentation:
                    DataPresentationExamplesView()
                case .navigation:
                    NavigationExamplesView()
                case .photos:
                    PhotoExamplesView()
                case .security:
                    SecurityExamplesView()
                case .ocr:
                    OCRExamplesView()
                case .notifications:
                    NotificationExamplesView()
                case .internationalization:
                    InternationalizationExamplesView()
                case .dataAnalysis:
                    DataAnalysisExamplesView()
                }
            }
        }
        .navigationTitle(category.displayName)
    }
}
