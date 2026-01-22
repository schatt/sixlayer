//
//  ButtonTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for Button accessibility identifier test
//

import SwiftUI
import SixLayerFramework

struct ButtonTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Button Test View")
                .font(.headline)
                .automaticCompliance()
            
            // Button with automatic compliance
            Button("Test Button") {
                // Action
            }
            .automaticCompliance(identifierElementType: "Button")
        }
        .padding()
        .navigationTitle("Button Test")
    }
}
