//
//  NavigationExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 navigation functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework

struct Layer1NavigationExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 24) {
            ExampleSection(title: "Navigation Stack") {
                NavigationStackExamples()
            }
            
            ExampleSection(title: "App Navigation") {
                AppNavigationExamples()
            }
        }
        .padding()
        .platformFrame()
    }
}

struct NavigationStackExamples: View {
    let hints = PresentationHints(
        dataType: .generic,
        presentationPreference: .navigation,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Basic Navigation Stack")
                .font(.headline)
            
            platformPresentNavigationStack_L1(
                content: platformVStack {
                    Text("Navigation Content")
                        .font(.headline)
                    Text("This is a navigation stack example")
                }
                .padding(),
                hints: hints
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct AppNavigationExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("App Navigation (Sidebar + Detail)")
                .font(.headline)
            
            platformPresentAppNavigation_L1(
                sidebar: {
                    List {
                        Text("Sidebar Item 1")
                        Text("Sidebar Item 2")
                        Text("Sidebar Item 3")
                    }
                },
                detail: {
                    Text("Detail Content")
                        .padding()
                }
            )
            .frame(height: 300)
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
