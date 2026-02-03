//
//  TestApp.swift
//  SixLayerFrameworkUITests
//
//  Minimal test app for XCUITest to test accessibility identifiers
//

import SwiftUI
import SixLayerFramework

/// Minimal test app that displays views for XCUITest testing
@main
struct TestApp: App {
    init() {
        // Configuration is now done in TestAppContentView.onAppear to avoid
        // static initialization order issues that can cause dyld_start crashes.
        // The framework must be fully loaded before accessing singletons.
    }
    
    var body: some Scene {
        WindowGroup {
            TestAppContentView()
        }
    }
}

/// Content view with navigation-based test view selection
/// Optimized for fast XCUITest execution with early accessibility setup
struct TestAppContentView: View {
    @State private var selectedTest: TestView? = nil
    @State private var showLayer1Examples = false
    @State private var selectedCategory: TestCategory? = nil
    @State private var isConfigured = false
    
    enum TestView: String, CaseIterable, Identifiable {
        case control = "Control Test"
        case text = "Text Test"
        case button = "Button Test"
        case platformPicker = "Platform Picker Test"
        case basicCompliance = "Basic Compliance Test"
        case identifierEdgeCase = "Identifier Edge Case"
        case detailView = "Detail View Test"
        
        var id: String { rawValue }
    }
    
    enum TestCategory: String, CaseIterable, Identifiable {
        case dataPresentation = "Data Presentation"
        case navigation = "Navigation"
        case photos = "Photos"
        case security = "Security"
        case ocr = "OCR"
        case notifications = "Notifications"
        case internationalization = "Internationalization"
        case dataAnalysis = "Data Analysis"
        case barcode = "Barcode"
        
        var id: String { rawValue }
    }
    
    // Configure accessibility identifier generation in initializer
    // This ensures namespace is set before view body is evaluated
    // Safe because we're not accessing during App.init() static initialization
    init() {
        // Configure accessibility identifier generation
        // This is safe here because we're in a view initializer, not App.init()
        let config = AccessibilityIdentifierConfig.shared
        config.namespace = "SixLayer"
        config.mode = .automatic
        config.enableAutoIDs = true
        config.globalAutomaticAccessibilityIdentifiers = true
        config.includeComponentNames = true
        config.includeElementTypes = true
        config.enableUITestIntegration = true  // CRITICAL: Enables "main.ui" format for stable identifiers
        
        // Enable debug logging unconditionally for debugging identifierName issue
        // TODO: Revert to conditional after fixing identifierName bug
        config.enableDebugLogging = true
    }
    
    var body: some View {
        NavigationStack {
            if let selected = selectedTest {
                // Navigate to specific test view
                testView(for: selected)
            } else {
                // Launch page with buttons
                launchPage
            }
        }
        .onAppear {
            // Mark as configured (config was already set in init())
            guard !isConfigured else { return }
            isConfigured = true
        }
    }
    
    // MARK: - Launch Page
    
    private var launchPage: some View {
        List {
            Section("Accessibility Tests") {
                ForEach(TestView.allCases) { testView in
                    Button(testView.rawValue) {
                        selectedTest = testView
                    }
                    .accessibilityIdentifier("test-view-\(testView.id)")
                }
            }
            
            Section("Layer 1 Examples (Issue #166)") {
                Button(showLayer1Examples ? "Hide Layer 1 Examples" : "Show Layer 1 Examples") {
                    showLayer1Examples.toggle()
                }
                .accessibilityIdentifier("layer1-examples-toggle")
                
                if showLayer1Examples {
                    layer1ExamplesView
                }
            }
            
            Section("Layer 2 Examples (Issue #165)") {
                NavigationLink("Layer 2 Layout Examples") {
                    Layer2ExamplesView()
                }
                .accessibilityIdentifier("layer2-examples-link")
            }
            
            Section("Layer 3 Examples (Issue #165)") {
                NavigationLink("Layer 3 Strategy Examples") {
                    Layer3ExamplesView()
                }
                .accessibilityIdentifier("layer3-examples-link")
            }
            
            Section("Layer 4 Examples (Issue #165)") {
                NavigationLink("Layer 4 Component Examples") {
                    Layer4ExamplesView()
                }
                .accessibilityIdentifier("layer4-examples-link")
            }
            
            Section("Layer 5 Examples (Issue #165)") {
                NavigationLink("Layer 5 Optimization Examples") {
                    Layer5ExamplesView()
                }
                .accessibilityIdentifier("layer5-examples-link")
            }
            
            Section("Layer 6 Examples (Issue #165)") {
                NavigationLink("Layer 6 System Examples") {
                    Layer6ExamplesView()
                }
                .accessibilityIdentifier("layer6-examples-link")
            }
        }
        .navigationTitle("UI Test Views")
    }
    
    // MARK: - Test Views
    
    @ViewBuilder
    private func testView(for test: TestView) -> some View {
        switch test {
        case .control:
            ControlTestView(onBackToMain: { selectedTest = nil })
        case .text:
            TextTestView(onBackToMain: { selectedTest = nil })
        case .button:
            ButtonTestView(onBackToMain: { selectedTest = nil })
        case .platformPicker:
            PlatformPickerTestView(onBackToMain: { selectedTest = nil })
        case .basicCompliance:
            BasicComplianceTestView(onBackToMain: { selectedTest = nil })
        case .identifierEdgeCase:
            IdentifierEdgeCaseTestView(onBackToMain: { selectedTest = nil })
        case .detailView:
            DetailViewTestView(onBackToMain: { selectedTest = nil })
        }
    }
    
    // MARK: - Layer 1 Examples View
    
    @ViewBuilder
    private var layer1ExamplesView: some View {
        // Use plain SwiftUI for launch page - framework types tested in individual test views
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Layer 1 Examples (Issue #166)")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                // Category picker - plain SwiftUI for launch page
                Picker("Category", selection: $selectedCategory) {
                    Text("Select Category").tag(nil as TestCategory?)
                    ForEach(TestCategory.allCases) { category in
                        Text(category.rawValue).tag(category as TestCategory?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.bottom)
                
                // Show selected category examples
                if let category = selectedCategory {
                    switch category {
                    case .dataPresentation:
                        Layer1DataPresentationExamples()
                    case .navigation:
                        Layer1NavigationExamples()
                    case .photos:
                        Layer1PhotoExamples()
                    case .security:
                        Layer1SecurityExamples()
                    case .ocr:
                        Layer1OCRExamples()
                    case .notifications:
                        Layer1NotificationExamples()
                    case .internationalization:
                        Layer1InternationalizationExamples()
                    case .dataAnalysis:
                        Layer1DataAnalysisExamples()
                    case .barcode:
                        Layer1BarcodeExamples()
                    }
                } else {
                    Text("Select a Layer 1 category to view examples")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
    }
}
