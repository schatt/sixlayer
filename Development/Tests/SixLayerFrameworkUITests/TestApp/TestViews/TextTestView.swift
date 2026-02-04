//
//  TextTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for Text accessibility identifier test
//

import SwiftUI
import SixLayerFramework

struct TextTestView: View {
    var onBackToMain: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        platformVStack(spacing: 20) {
            platformText("Text Test View")
                .font(.headline)
                .automaticCompliance()
            
            // Text view with automatic compliance
            platformText("Test Content")
                .automaticCompliance(identifierName: "testText")
            
            // Back to main page button
            platformButton("Back to Main") {
                if let action = onBackToMain { action() } else { dismiss() }
            }
            .accessibilityIdentifier("back-to-main-button")
        }
        .padding()
        .platformFrame()
        .navigationTitle("Text Test")
    }
}
