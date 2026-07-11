//
//  NavigationExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 navigation functions
//  Issue #166
//
//  #316: optional `-L1Section=navStack|appNav` mounts one section (App Navigation
//  SplitView otherwise dominates the a11y tree and hides the stack id).
//

import SwiftUI
import SixLayerFramework

struct Layer1NavigationExamples: View {
    /// `-L1Section=navStack|appNav`
    private var focusedSection: String? {
        guard let raw = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("-L1Section=") })?
            .split(separator: "=", maxSplits: 1)
            .last
        else { return nil }
        let name = String(raw)
        return name.isEmpty ? nil : name
    }

    private func shows(_ section: String) -> Bool {
        guard let focusedSection else { return true }
        return focusedSection.compare(section, options: [.caseInsensitive]) == .orderedSame
    }

    var body: some View {
        platformVStack(alignment: .leading, spacing: 24) {
            if shows("navStack") {
                Text("L1_Section_NavStack")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("L1_Section_NavStack")
                ExampleSection(title: "Navigation Stack") {
                    NavigationStackExamples()
                }
            }

            if shows("appNav") {
                Text("L1_Section_AppNav")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("L1_Section_AppNav")
                ExampleSection(title: "App Navigation") {
                    AppNavigationExamples()
                }
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
