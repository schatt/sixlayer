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

/// Content view that can be configured to display different test views
/// Optimized for fast XCUITest execution with early accessibility setup
struct TestAppContentView: View {
    @State private var testViewType: TestViewType = .text
    @State private var isConfigured = false
    
    enum TestViewType: String, CaseIterable {
        case text = "Text"
        case button = "Button"
        case control = "Control"
    }
    
    // Pre-configure environment values to avoid onAppear delays
    private let globalAccessibilityEnabled = true
    
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
        
        // Enable debug logging in UI testing mode
        if ProcessInfo.processInfo.environment["XCUI_TESTING"] == "1" {
            config.enableDebugLogging = true
        }
    }
    
    var body: some View {
        // Simplified view hierarchy for faster rendering and accessibility tree building
        VStack {
            // Control test: Standard SwiftUI button with direct accessibilityIdentifier
            // This verifies XCUITest can find identifiers before testing our modifier
            // Place it first so it's always visible
            Button("Control Button") {
                // Action
            }
            .accessibilityIdentifier("control-test-button")
            .padding()
            
            Picker("Test View", selection: $testViewType) {
                ForEach(TestViewType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                        .tag(type)
                        .accessibilityIdentifier(type.rawValue)
                        .accessibility(label: Text(type.rawValue)) // Also add label (needed for VoiceOver and may help XCUITest)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("test-view-picker")
            .accessibility(label: Text("Test View")) // Also add label at picker level (as per Stack Overflow answer)
            .padding()
            
            // Use Group to avoid deep nesting while maintaining view switching
            Group {
                switch testViewType {
                case .text:
                    Text("Test Content")
                        .automaticCompliance()
                case .button:
                    Button("Test Button") {
                        // Action
                    }
                    .automaticCompliance(identifierElementType: "Button")
                case .control:
                    // Control view (already shown above, but include here for picker consistency)
                    Text("Control view selected")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Mark as configured (config was already set in init())
            // This is just for tracking - actual config happens in init() to ensure
            // namespace is set before view body evaluation
            guard !isConfigured else { return }
            isConfigured = true
        }
    }
}
