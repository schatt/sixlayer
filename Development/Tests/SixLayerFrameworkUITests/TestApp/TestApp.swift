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
    var body: some Scene {
        WindowGroup {
            TestAppContentView()
        }
    }
}

/// Content view that can be configured to display different test views
struct TestAppContentView: View {
    @State private var testViewType: TestViewType = .text
    
    enum TestViewType: String, CaseIterable {
        case text = "Text"
        case button = "Button"
    }
    
    var body: some View {
        VStack {
            Picker("Test View", selection: $testViewType) {
                ForEach(TestViewType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Group {
                switch testViewType {
                case .text:
                    Text("Test Content")
                        .automaticCompliance()
                        .environment(\.globalAutomaticAccessibilityIdentifiers, true)
                case .button:
                    Button("Test Button") {
                        // Action
                    }
                    .automaticCompliance()
                    .environment(\.globalAutomaticAccessibilityIdentifiers, true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Configure accessibility identifier generation
            let config = AccessibilityIdentifierConfig.shared
            config.namespace = "SixLayer"
            config.mode = .automatic
            config.enableAutoIDs = true
        }
    }
}
