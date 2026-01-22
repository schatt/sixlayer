//
//  NavigationExamplesView.swift
//  SixLayerFrameworkRealUITests
//
//  Examples of Layer 1 navigation functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework

struct NavigationExamplesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ExampleSection(title: "Navigation Stack") {
                NavigationStackExamples()
            }
            
            ExampleSection(title: "App Navigation") {
                AppNavigationExamples()
            }
        }
        .padding()
    }
}

struct NavigationStackExamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic Navigation Stack")
                .font(.headline)
            
            platformPresentNavigationStack_L1 {
                VStack {
                    Text("Navigation Content")
                        .font(.headline)
                    Text("This is a navigation stack example")
                }
                .padding()
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct AppNavigationExamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Navigation (Sidebar + Detail)")
                .font(.headline)
            
            platformPresentAppNavigation_L1(
                sidebarContent: {
                    List {
                        Text("Sidebar Item 1")
                        Text("Sidebar Item 2")
                        Text("Sidebar Item 3")
                    }
                },
                detailContent: {
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
