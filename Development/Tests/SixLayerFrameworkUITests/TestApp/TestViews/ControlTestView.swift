//
//  ControlTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for control button accessibility identifier test
//

import SwiftUI
import SixLayerFramework

struct ControlTestView: View {
    let onBackToMain: () -> Void
    
    var body: some View {
        // Control test uses plain SwiftUI - this is the baseline test
        // that verifies XCUITest infrastructure works before testing framework
        VStack(spacing: 20) {
            Text("Control Test View")
                .font(.headline)
            
            // Control test: Standard SwiftUI button with direct accessibilityIdentifier
            // This verifies XCUITest can find identifiers before testing our modifier
            Button("Control Button") {
                // Action
            }
            .accessibilityIdentifier("control-test-button")
            
            // Back to main page button
            Button("Back to Main") {
                onBackToMain()
            }
            .accessibilityIdentifier("back-to-main-button")
        }
        .padding()
        .navigationTitle("Control Test")
    }
}
