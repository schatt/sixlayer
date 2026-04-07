//
//  PlatformSettingsContainerExample.swift
//  SixLayerFramework
//
//  Example usage of platformSettingsContainer_L4
//  Demonstrates device-aware settings container that adapts to iPad, iPhone, and macOS
//  Implements Issue #58: Add platformSettingsContainer_L4 for Settings Views (Layer 4)
//  For the managed flow (Issue #209), see Framework/docs/ManagedPlatformSettingsFlowGuide.md
//  and ManagedPlatformSettingsFlowGuideExampleTests.swift.
//

import SwiftUI
import SixLayerFramework

// MARK: - Example: Basic Settings View

/// Example settings view that automatically adapts to device type
struct ExampleSettingsView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var selectedCategory: String? = nil
    
    var body: some View {
        EmptyView()
            .platformSettingsContainer_L4(
                columnVisibility: $columnVisibility,
                selectedCategory: $selectedCategory
            ) {
                // Sidebar: List of settings categories
                SettingsCategoryListView(selectedCategory: $selectedCategory)
            } detail: {
                // Detail: Settings for selected category
                SettingsDetailView(category: selectedCategory)
            }
    }
}

// MARK: - Example: Settings Category List (Sidebar)

/// Example sidebar view showing settings categories
struct SettingsCategoryListView: View {
    @Binding var selectedCategory: String?
    
    let categories = [
        "General",
        "Privacy",
        "Notifications",
        "Display",
        "Storage",
        "About"
    ]
    
    var body: some View {
        List(categories, id: \.self) { category in
            Button(action: {
                selectedCategory = category
            }) {
                HStack {
                    Image(systemName: iconForCategory(category))
                    Text(category)
                    Spacer()
                }
            }
        }
        .navigationTitle("Settings")
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "General": return "gear"
        case "Privacy": return "hand.raised.fill"
        case "Notifications": return "bell.fill"
        case "Display": return "display"
        case "Storage": return "externaldrive.fill"
        case "About": return "info.circle.fill"
        default: return "folder.fill"
        }
    }
}

// MARK: - Example: Settings Detail View

/// Example detail view showing settings for a selected category
struct SettingsDetailView: View {
    let category: String?
    
    var body: some View {
        if let category = category {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(category) Settings")
                        .font(.largeTitle)
                        .padding()
                    
                    // Example settings content
                    VStack(alignment: .leading, spacing: 16) {
                        SettingRow(title: "Setting 1", value: "Value 1")
                        SettingRow(title: "Setting 2", value: "Value 2")
                        SettingRow(title: "Setting 3", value: "Value 3")
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle(category)
        } else {
            Text("Select a category from the sidebar")
                .foregroundColor(.secondary)
                .padding()
        }
    }
}

// MARK: - Example: Setting Row Component

/// Example setting row component
struct SettingRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Example: iPhone-Specific Usage

/// Example showing iPhone-specific behavior with category selection
struct iPhoneSettingsExample: View {
    @State private var selectedCategory: String? = nil
    
    var body: some View {
        EmptyView()
            .platformSettingsContainer_L4(
                selectedCategory: $selectedCategory
            ) {
                // Sidebar shown when selectedCategory is nil
                List {
                    Button("General") {
                        selectedCategory = "general"
                    }
                    Button("Privacy") {
                        selectedCategory = "privacy"
                    }
                    Button("Notifications") {
                        selectedCategory = "notifications"
                    }
                }
                .navigationTitle("Settings")
            } detail: {
                // Detail shown when selectedCategory is set
                if let category = selectedCategory {
                    SettingsDetailView(category: category)
                } else {
                    Text("Select a category")
                        .foregroundColor(.secondary)
                }
            }
    }
}

// MARK: - Example: iPad/macOS Usage with Column Visibility

/// Example showing iPad/macOS usage with column visibility control
struct iPadMacOSSettingsExample: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var selectedCategory: String? = "General"
    
    var body: some View {
        EmptyView()
            .platformSettingsContainer_L4(
                columnVisibility: $columnVisibility
            ) {
                // Sidebar always visible on iPad/macOS
                SettingsCategoryListView(selectedCategory: $selectedCategory)
            } detail: {
                // Detail pane
                SettingsDetailView(category: selectedCategory)
            }
    }
}

// MARK: - Example: Minimal Usage (No Bindings)

/// Example showing minimal usage without bindings
struct MinimalSettingsExample: View {
    var body: some View {
        EmptyView()
            .platformSettingsContainer_L4 {
                // Sidebar
                List {
                    Text("Category 1")
                    Text("Category 2")
                    Text("Category 3")
                }
                .navigationTitle("Settings")
            } detail: {
                // Detail
                Text("Settings Detail")
                    .padding()
            }
    }
}

// MARK: - Preview

#Preview("Settings View") {
    ExampleSettingsView()
}

#Preview("iPhone Settings") {
    iPhoneSettingsExample()
}

#Preview("iPad/macOS Settings") {
    iPadMacOSSettingsExample()
}

#Preview("Minimal Settings") {
    MinimalSettingsExample()
}
