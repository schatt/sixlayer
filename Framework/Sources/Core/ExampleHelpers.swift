//
//  ExampleHelpers.swift
//  SixLayerFramework
//
//  Example project-specific UI helper functions
//  This demonstrates how to extend the framework for your specific needs
//

import SwiftUI

// MARK: - Example Project-Specific UI Helpers

/// Example of a project-specific card component that uses the 6-layer framework
public struct ExampleProjectCard: View {
    private let title: String
    private let subtitle: String?
    private let content: AnyView
    private let action: (() -> Void)?
    
    public init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> some View,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = AnyView(content())
        self.action = action
    }
    
    /// Convenience initializer that takes project data
    public init(project: ExampleProjectData) {
        self.title = project.title
        self.subtitle = project.description
        self.content = AnyView(
            platformVStackContainer(alignment: .leading, spacing: 8) {
                Text("Status: \(project.status.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("ID: \(project.id)")
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
        )
        self.action = nil
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 12) {
            platformVStackContainer(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let action = action {
                Button("Action") {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .automaticCompliance(named: "ExampleProjectCard")
    }
}

/// Example of a project-specific list view that uses the 6-layer framework
public struct ExampleProjectList<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    private let content: (Item) -> Content
    
    public init(
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.content = content
    }
    
    public var body: some View {
        platformLazyVStackContainer(spacing: 16) {
            ForEach(items) { item in
                content(item)
            }
        }
        .padding()
        .automaticCompliance(named: "ExampleProjectList")
    }
}

/// Example of a project-specific form field that uses the 6-layer framework
public struct ExampleProjectFormField: View {
    private let label: String
    private let placeholder: String
    @Binding private var text: String
    
    public init(
        label: String,
        placeholder: String,
        text: Binding<String>
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
    }
    
    /// Convenience initializer that takes form field data
    public init(field: FormFieldData) {
        self.label = field.label
        self.placeholder = field.placeholder
        self._text = Binding.constant(field.value)
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $text)
                .platformTextFieldStyle()
        }
        .automaticCompliance(named: "ExampleProjectFormField")
    }
}

// MARK: - Example Usage Extensions

public extension View {
    /// Example extension that adds project-specific styling
    func exampleProjectStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
    }
}

// MARK: - Example Data Models

/// Example of project-specific data that can be used with the helpers
public struct ExampleProjectItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let isActive: Bool
    
    public init(title: String, description: String, isActive: Bool = false) {
        self.title = title
        self.description = description
        self.isActive = isActive
    }
}

/// Example project data model for testing
public struct ExampleProjectData: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let status: ProjectStatus
    
    public init(id: String, title: String, description: String, status: ProjectStatus) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
    }
}

/// Project status enum
public enum ProjectStatus: String, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case pending = "pending"
}

/// Form field data model for testing
public struct FormFieldData {
    public let label: String
    public let placeholder: String
    public let value: String
    
    public init(label: String, placeholder: String, value: String) {
        self.label = label
        self.placeholder = placeholder
        self.value = value
    }
}

// MARK: - Example Preview

#if ENABLE_PREVIEWS
#Preview {
    platformVStackContainer(spacing: 20) {
        ExampleProjectCard(
            title: "Example Card",
            subtitle: "This is a subtitle"
        ) {
            Text("This is the content of the card. It demonstrates how to use the 6-layer framework with custom UI components.")
        } action: {
            print("Card action tapped")
        }
        
        ExampleProjectFormField(
            label: "Example Field",
            placeholder: "Enter text here",
            text: .constant("")
        )
        
        ExampleProjectList(
            items: [
                ExampleProjectItem(title: "Item 1", description: "Description 1"),
                ExampleProjectItem(title: "Item 2", description: "Description 2", isActive: true)
            ]
        ) { item in
            HStack {
                platformVStackContainer(alignment: .leading) {
                    Text(item.title)
                        .fontWeight(.medium)
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if item.isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
            .exampleProjectStyle()
        }
    }
    .padding()
}
#endif
