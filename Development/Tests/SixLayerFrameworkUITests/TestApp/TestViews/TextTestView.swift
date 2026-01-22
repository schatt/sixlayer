//
//  TextTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for Text accessibility identifier test
//

import SwiftUI
import SixLayerFramework

struct TextTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Text Test View")
                .font(.headline)
                .automaticCompliance()
            
            // Text view with automatic compliance
            Text("Test Content")
                .automaticCompliance()
        }
        .padding()
        .navigationTitle("Text Test")
    }
}
