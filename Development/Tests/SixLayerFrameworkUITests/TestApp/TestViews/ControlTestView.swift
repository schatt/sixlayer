//
//  ControlTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for control button accessibility identifier test
//

import SwiftUI
import SixLayerFramework

struct ControlTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Control Test View")
                .font(.headline)
                .automaticCompliance()
            
            // Control test: Standard SwiftUI button with direct accessibilityIdentifier
            // This verifies XCUITest can find identifiers before testing our modifier
            Button("Control Button") {
                // Action
            }
            .accessibilityIdentifier("control-test-button")
        }
        .padding()
        .navigationTitle("Control Test")
    }
}
