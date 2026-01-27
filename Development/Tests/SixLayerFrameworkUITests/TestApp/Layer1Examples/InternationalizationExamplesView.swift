//
//  InternationalizationExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 internationalization functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework

struct Layer1InternationalizationExamples: View {
    @State private var textValue = ""
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 24) {
            ExampleSection(title: "Localized Content") {
                LocalizedContentExamples()
            }
            
            ExampleSection(title: "Localized Text") {
                LocalizedTextExamples()
            }
            
            ExampleSection(title: "Localized Numbers & Currency") {
                LocalizedNumberExamples()
            }
            
            ExampleSection(title: "Localized String") {
                LocalizedStringExamples()
            }
            
            ExampleSection(title: "Localized Dates & Time") {
                LocalizedDateExamples()
            }
            
            ExampleSection(title: "RTL Containers") {
                RTLContainerExamples()
            }
            
            ExampleSection(title: "Localized Form Fields") {
                LocalizedFormFieldExamples(text: $textValue)
            }
        }
        .padding()
    }
}

struct LocalizedContentExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Localized Content")
                .font(.headline)
            
            platformPresentLocalizedContent_L1(
                content: platformVStack {
                    Text("Localized Content")
                        .font(.headline)
                    Text("This content respects locale settings")
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

struct LocalizedTextExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Localized Text")
                .font(.headline)
            
            platformPresentLocalizedText_L1(
                text: "Hello, World!"
            )
            .frame(height: 50)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct LocalizedNumberExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Localized Numbers & Currency")
                .font(.headline)
            
            platformVStack(alignment: .leading, spacing: 8) {
                platformPresentLocalizedNumber_L1(number: 1234.56)
                platformPresentLocalizedCurrency_L1(amount: 99.99)
                platformPresentLocalizedPercentage_L1(value: 0.75)
                platformPresentLocalizedPlural_L1(word: "item", count: 5)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct LocalizedStringExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Localized String")
                .font(.headline)
            
            platformPresentLocalizedString_L1(
                key: "Hello, World!",
                hints: InternationalizationHints()
            )
            .frame(height: 50)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct LocalizedDateExamples: View {
    let now = Date()
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Localized Dates & Time")
                .font(.headline)
            
            platformVStack(alignment: .leading, spacing: 8) {
                platformPresentLocalizedDate_L1(date: now)
                platformPresentLocalizedTime_L1(date: now)
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct RTLContainerExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("RTL Containers")
                .font(.headline)
            
            platformVStack(alignment: .leading, spacing: 8) {
                platformRTLContainer_L1(
                    content: Text("RTL Container")
                )
                
                platformRTLHStack_L1 {
                    Text("Item 1")
                    Text("Item 2")
                    Text("Item 3")
                }
                
                platformRTLVStack_L1 {
                    Text("Row 1")
                    Text("Row 2")
                }
                
                platformRTLZStack_L1 {
                    Text("ZStack Content")
                }
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct LocalizedFormFieldExamples: View {
    @Binding var text: String
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Localized Form Fields")
                .font(.headline)
            
            platformVStack(alignment: .leading, spacing: 8) {
                platformLocalizedTextField_L1(
                    title: "Name",
                    text: $text
                )
                
                platformLocalizedSecureField_L1(
                    title: "Password",
                    text: $text
                )
                
                platformLocalizedTextEditor_L1(
                    title: "Notes",
                    text: $text
                )
                .frame(height: 100)
            }
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
