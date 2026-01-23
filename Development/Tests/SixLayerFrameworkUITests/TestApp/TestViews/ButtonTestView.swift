//
//  ButtonTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for Button accessibility identifier test
//

import SwiftUI
import SixLayerFramework

struct ButtonTestView: View {
    let onBackToMain: () -> Void
    
    var body: some View {
        platformVStack(spacing: 20) {
            platformText("Button Test View")
                .font(.headline)
                .automaticCompliance()
            
            // Button with automatic compliance - using platformButton
            platformButton("Test Button") {
                // Action
            }
            .automaticCompliance(identifierName: "testButton", identifierElementType: "Button")
            
            // Back to main page button
            platformButton("Back to Main") {
                onBackToMain()
            }
            .accessibilityIdentifier("back-to-main-button")
        }
        .padding()
        .navigationTitle("Button Test")
    }
}
