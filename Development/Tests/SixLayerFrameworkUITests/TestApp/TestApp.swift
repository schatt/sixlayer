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
            // Configure accessibility identifier generation after app is fully loaded
            // This avoids static initialization order issues that can cause dyld_start crashes
            // The framework must be fully initialized before accessing singletons
            guard !isConfigured else { return }
            isConfigured = true
            
            let config = AccessibilityIdentifierConfig.shared
            config.namespace = "SixLayer"
            config.mode = .automatic
            config.enableAutoIDs = true
            config.globalAutomaticAccessibilityIdentifiers = true  // Enable via config (no environment variable - removed in Issue #160)
            
            // Skip animations in UI testing mode for faster execution
            if ProcessInfo.processInfo.environment["XCUI_TESTING"] == "1" {
                // Additional optimizations for UI testing mode can go here
            }
        }
    }
}
