//
//  DataPresentationExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 data presentation functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework

/// Examples of data presentation functions for Layer 1
struct Layer1DataPresentationExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 24) {
            // Item Collection Examples
            ExampleSection(title: "Item Collection") {
                ItemCollectionExamples()
            }
            
            // Numeric Data Examples
            ExampleSection(title: "Numeric Data") {
                NumericDataExamples()
            }
            
            // Form Data Examples
            ExampleSection(title: "Form Data") {
                FormDataExamples()
            }
            
            // Media Data Examples
            ExampleSection(title: "Media Data") {
                MediaDataExamples()
            }
            
            // Hierarchical Data Examples
            ExampleSection(title: "Hierarchical Data") {
                HierarchicalDataExamples()
            }
            
            // Temporal Data Examples
            ExampleSection(title: "Temporal Data") {
                TemporalDataExamples()
            }
            
            // Content Examples
            ExampleSection(title: "Content & Basic Values") {
                ContentExamples()
            }
            
            // Settings Examples
            ExampleSection(title: "Settings") {
                SettingsExamples()
            }
            
            // Responsive Card Examples
            ExampleSection(title: "Responsive Card") {
                ResponsiveCardExamples()
            }
        }
        .padding()
    }
}

// MARK: - Item Collection Examples

struct ItemCollectionExamples: View {
    struct TestItem: Identifiable {
        let id = UUID()
        let name: String
        let description: String
    }
    
    let testItems = [
        TestItem(name: "Item 1", description: "First test item"),
        TestItem(name: "Item 2", description: "Second test item"),
        TestItem(name: "Item 3", description: "Third test item")
    ]
    
    let hints = PresentationHints(
        dataType: .generic,
        presentationPreference: .list,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Basic Item Collection")
                .font(.headline)
            
            platformPresentItemCollection_L1(
                items: testItems,
                hints: hints,
                onItemSelected: { item in
                    print("Selected: \(item.name)")
                }
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Numeric Data Examples

struct NumericDataExamples: View {
    let numericData = [
        GenericNumericData(value: 1250.50, label: "Sales", unit: "USD"),
        GenericNumericData(value: 42, label: "Orders", unit: "count"),
        GenericNumericData(value: 15.5, label: "Growth", unit: "%")
    ]
    
    let hints = PresentationHints(
        dataType: .numeric,
        presentationPreference: .card,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Numeric Data Presentation")
                .font(.headline)
            
            platformPresentNumericData_L1(
                data: numericData,
                hints: hints
            )
            .frame(height: 150)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Form Data Examples

struct FormDataExamples: View {
    @State private var textValue = ""
    
    let hints = PresentationHints(
        dataType: .form,
        presentationPreference: .form,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Form Data Presentation")
                .font(.headline)
            
            platformPresentFormData_L1(
                field: DynamicFormField(
                    id: "test_field",
                    contentType: .text,
                    label: "Test Field",
                    defaultValue: textValue
                ),
                hints: hints
            )
            .frame(height: 100)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Media Data Examples

struct MediaDataExamples: View {
    let mediaItems: [GenericMediaItem] = [
        GenericMediaItem(
            title: "Sample Image",
            url: nil,
            thumbnail: nil
        )
    ]
    
    let hints = PresentationHints(
        dataType: .media,
        presentationPreference: .grid,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Media Data Presentation")
                .font(.headline)
            
            platformPresentMediaData_L1(
                media: mediaItems,
                hints: hints
            )
            .frame(height: 150)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Hierarchical Data Examples

struct HierarchicalDataExamples: View {
    let hierarchicalItems: [GenericHierarchicalItem] = [
        GenericHierarchicalItem(
            title: "Parent Item",
            level: 0,
            children: [
                GenericHierarchicalItem(title: "Child 1", level: 1, children: []),
                GenericHierarchicalItem(title: "Child 2", level: 1, children: [])
            ]
        )
    ]
    
    let hints = PresentationHints(
        dataType: .hierarchical,
        presentationPreference: .list,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Hierarchical Data Presentation")
                .font(.headline)
            
            platformPresentHierarchicalData_L1(
                items: hierarchicalItems,
                hints: hints
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Temporal Data Examples

struct TemporalDataExamples: View {
    let temporalItems: [GenericTemporalItem] = [
        GenericTemporalItem(
            title: "Event 1",
            date: Date(),
            duration: 3600
        ),
        GenericTemporalItem(
            title: "Event 2",
            date: Date().addingTimeInterval(86400),
            duration: 1800
        )
    ]
    
    let hints = PresentationHints(
        dataType: .temporal,
        presentationPreference: .list,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Temporal Data Presentation")
                .font(.headline)
            
            platformPresentTemporalData_L1(
                items: temporalItems,
                hints: hints
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Content Examples

struct ContentExamples: View {
    let hints = PresentationHints(
        dataType: .generic,
        presentationPreference: .card,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Content Presentation")
                .font(.headline)
            
            platformPresentContent_L1(
                content: Text("Sample content"),
                hints: hints
            )
            
            Divider()
            
            Text("Basic Value Presentation")
                .font(.headline)
            
            platformPresentBasicValue_L1(
                value: 42,
                hints: hints
            )
            
            Divider()
            
            Text("Basic Array Presentation")
                .font(.headline)
            
            platformPresentBasicArray_L1(
                array: [1, 2, 3, 4, 5],
                hints: hints
            )
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Settings Examples

struct SettingsExamples: View {
    let settings: [SettingsSectionData] = [
        SettingsSectionData(
            title: "General",
            items: [
                SettingsItemData(key: "setting1", title: "Setting 1", type: .toggle, value: true),
                SettingsItemData(key: "setting2", title: "Setting 2", type: .text, value: "Value")
            ]
        )
    ]
    
    let hints = PresentationHints(
        dataType: .generic,
        presentationPreference: .list,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Settings Presentation")
                .font(.headline)
            
            platformPresentSettings_L1(
                settings: settings,
                hints: hints
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Responsive Card Examples

struct ResponsiveCardExamples: View {
    let hints = PresentationHints(
        dataType: .generic,
        presentationPreference: .card,
        complexity: .simple
    )
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Responsive Card")
                .font(.headline)
            
            platformResponsiveCard_L1(
                content: {
                    platformVStack(alignment: .leading) {
                        Text("Card Title")
                            .font(.headline)
                        Text("Card content goes here")
                            .font(.body)
                    }
                },
                hints: hints
            )
            .frame(height: 150)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

private struct ExampleSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            content
        }
    }
}
