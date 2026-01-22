//
//  TextTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for Text accessibility identifier test
//

import SwiftUI
import SixLayerFramework

struct TextTestView: View {
    let onBackToMain: () -> Void
    
    var body: some View {
        platformVStack(spacing: 20) {
            platformText("Text Test View")
                .font(.headline)
                .automaticCompliance()
            
            // Text view with automatic compliance
            platformText("Test Content")
                .automaticCompliance()
            
            // Back to main page button
            platformButton("Back to Main") {
                onBackToMain()
            }
            .accessibilityIdentifier("back-to-main-button")
        }
        .padding()
        .navigationTitle("Text Test")
    }
}
