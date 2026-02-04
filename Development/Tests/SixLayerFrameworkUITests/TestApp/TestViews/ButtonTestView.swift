//
//  ButtonTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for Button accessibility identifier test
//

import SwiftUI
import SixLayerFramework

struct ButtonTestView: View {
    var onBackToMain: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        platformVStack(spacing: 20) {
            platformText("Button Test View")
                .font(.headline)
                .automaticCompliance()
            
            // Button with automatic compliance - explicit id so identifier is SixLayer.main.ui.testButton.Button
            platformButton(label: "Test Button", id: "testButton") {
                // Action
            }
            
            // Back to main page button
            platformButton("Back to Main") {
                if let action = onBackToMain { action() } else { dismiss() }
            }
            .accessibilityIdentifier("back-to-main-button")
        }
        .padding()
        .platformFrame()
        .navigationTitle("Button Test")
    }
}
