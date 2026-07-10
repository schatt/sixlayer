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
    private enum ExamplePane: String, Hashable, CaseIterable, Sendable {
        case item1
        case item2
        case item3
    }

    @State private var navState = PlatformAppNavigationTopLevelState<ExamplePane>(deviceType: .current)

    private let descriptors: [AppNavigationPaneDescriptor<ExamplePane>] = [
        .init(id: .item1, titleKey: "Sidebar Item 1", systemImage: "1.circle"),
        .init(id: .item2, titleKey: "Sidebar Item 2", systemImage: "2.circle"),
        .init(id: .item3, titleKey: "Sidebar Item 3", systemImage: "3.circle")
    ]

    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("App Navigation (adaptive sidebar + Detail)")
                .font(.headline)

            platformPresentManagedAppNavigation_L1(
                state: $navState,
                descriptors: descriptors
            ) { selected in
                Text(selected.map { "Detail: \($0.rawValue)" } ?? "Detail Content")
                    .padding()
            }
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
