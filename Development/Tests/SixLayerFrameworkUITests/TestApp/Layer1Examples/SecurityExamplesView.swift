//
//  SecurityExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 security functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework

struct Layer1SecurityExamples: View {
    @State private var secureText = ""
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 24) {
            ExampleSection(title: "Secure Content") {
                SecureContentExamples()
            }
            
            ExampleSection(title: "Secure Text Field") {
                SecureTextFieldExamples(text: $secureText)
            }
            
            ExampleSection(title: "Privacy Indicator") {
                PrivacyIndicatorExamples()
            }
        }
        .padding()
    }
}

struct SecureContentExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Secure Content Presentation")
                .font(.headline)
            
            platformPresentSecureContent_L1(
                content: platformVStack {
                    Text("Secure Content")
                        .font(.headline)
                    Text("This content is protected")
                }
                .padding()
            )
            .frame(height: 150)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct SecureTextFieldExamples: View {
    @Binding var text: String
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Secure Text Field")
                .font(.headline)
            
            platformPresentSecureTextField_L1(
                title: "Password",
                text: $text
            )
            .frame(height: 100)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct PrivacyIndicatorExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Privacy Indicator")
                .font(.headline)
            
            platformShowPrivacyIndicator_L1(
                type: .camera,
                isActive: true
            )
            
            Text("Note: Privacy indicator is shown via system APIs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

private struct ExampleSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
            
            content()
        }
    }
}
