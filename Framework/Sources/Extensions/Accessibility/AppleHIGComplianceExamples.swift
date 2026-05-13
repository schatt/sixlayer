import Foundation
import SwiftUI

// MARK: - Apple HIG Compliance Examples

/// Examples demonstrating automatic Apple HIG compliance
public struct AppleHIGComplianceExamples {
    
    // MARK: - Basic Usage Examples
    
    /// Example of a button with automatic Apple HIG compliance
    @MainActor
    public static func compliantButton() -> some View {
        Button("Save") {
            // Save action
        }
        .appleHIGCompliant() // Automatically applies all Apple HIG compliance
    }
    
    /// Example of a form with automatic accessibility
    @MainActor
    public static func accessibleForm() -> some View {
        VStack(spacing: 16) {
            TextField("Name", text: .constant(""))
                .automaticAccessibility()
            
            TextField("Email", text: .constant(""))
                .automaticAccessibility()
            
            Button("Submit") {
                // Submit action
            }
            .appleHIGCompliant()
        }
        .padding()
    }
    
    /// Example of a list with platform-specific patterns
    @MainActor
    public static func platformSpecificList() -> some View {
        List {
            ForEach(0..<10) { index in
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Item \(index)")
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(index)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .platformPatterns() // Applies platform-specific patterns
            }
        }
        .appleHIGCompliant()
    }
    
    // MARK: - Advanced Examples
    
    /// Example of a complex view with all compliance features
    @MainActor
    public static func complexCompliantView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header with proper typography
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage your preferences")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .visualConsistency() // Applies visual consistency
                
                // Settings sections
                VStack(spacing: 16) {
                    SettingsSection(
                        title: "Appearance",
                        items: [
                            SettingsItem(title: "Dark Mode", isToggle: true),
                            SettingsItem(title: "Accent Color", isToggle: false)
                        ]
                    )
                    
                    SettingsSection(
                        title: "Accessibility",
                        items: [
                            SettingsItem(title: "VoiceOver", isToggle: true),
                            SettingsItem(title: "High Contrast", isToggle: true)
                        ]
                    )
                }
                .appleHIGCompliant()
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        // Cancel action
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save") {
                        // Save action
                    }
                    .buttonStyle(.borderedProminent)
                }
                .interactionPatterns() // Applies interaction patterns
            }
            .padding()
            .navigationTitle("Settings")
            .platformNavigationTitleDisplayMode_L4(.large)
        }
        .appleHIGCompliant()
    }
    
    // MARK: - Platform-Specific Examples
    
    /// iOS-specific example with navigation and haptics
    @MainActor
    public static func iOSCompliantView() -> some View {
        NavigationView {
            VStack {
                Text("iOS Optimized View")
                    .font(.title)
                    .padding()
                
                Button("Tap for Haptic Feedback") {
                    // Haptic feedback is automatically applied
                }
                .appleHIGCompliant()
                
                List {
                    ForEach(0..<5) { index in
                        NavigationLink(destination: Text("Detail \(index)")) {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Item \(index)")
                                Spacer()
                            }
                        }
                    }
                }
                .appleHIGCompliant()
            }
            .navigationTitle("iOS View")
        }
    }
    
    /// macOS-specific example with window patterns
    @MainActor
    public static func macOSCompliantView() -> some View {
        VStack {
            Text("macOS Optimized View")
                .font(.title)
                .padding()
            
            Button("Click for Sound Feedback") {
                // Sound feedback is automatically applied
            }
            .appleHIGCompliant()
            
            List {
                ForEach(0..<5) { index in
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Item \(index)")
                        Spacer()
                    }
                    .platformHoverEffect { _ in
                        // Hover state is automatically applied
                    }
                }
            }
            .appleHIGCompliant()
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Supporting Views

/// Settings section for examples
public struct SettingsSection: View {
    let title: String
    let items: [SettingsItem]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(items, id: \.title) { item in
                    SettingsItemView(item: item)
                }
            }
        }
        .padding()
        .background(.gray)
        .cornerRadius(12)
        .shadow(radius: 2)
        .automaticCompliance(named: "SettingsSection")
    }
}

/// Settings item for examples
public struct SettingsItem {
    let title: String
    let isToggle: Bool
}

/// Settings item view
public struct SettingsItemView: View {
    let item: SettingsItem
    @State private var isToggled = false
    
    public var body: some View {
        HStack {
            Text(item.title)
                .font(.body)
            
            Spacer()
            
            if item.isToggle {
                Toggle("", isOn: $isToggled)
                    .labelsHidden()
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .appleHIGCompliant()
        .automaticCompliance(named: "SettingsItemView")
    }
}

// MARK: - Integration Examples

/// Example of integrating with existing framework components
public struct FrameworkIntegrationExample: View {
    @State private var formData = SampleFormData()
    
    public var body: some View {
        NavigationView {
            VStack {
                // Use existing framework components with Apple HIG compliance
                IntelligentFormView.generateForm(
                    for: SampleFormData.self,
                    initialData: formData,
                    onSubmit: { data in
                        // Handle form submission
                    }
                )
                .appleHIGCompliant() // Apply Apple HIG compliance
                
                // MARK: - DEPRECATED: SimpleFormView uses GenericFormField which has been deprecated
                // TODO: Replace with DynamicFormView using DynamicFormField
                Text("Form functionality temporarily disabled - needs DynamicFormField migration")
                    .foregroundColor(.secondary)
                    .padding()
                .appleHIGCompliant() // Apply Apple HIG compliance
            }
            .navigationTitle("Framework Integration")
        }
        .automaticCompliance(named: "FrameworkIntegrationExample")
    }
    
    private func createFormFields() -> [DynamicFormField] {
        // Note: This is a simplified example - in real usage, you'd need to manage state properly
        // For demonstration purposes, we'll create fields with default values
        
        return [
            DynamicFormField(
                id: "name",
                contentType: .textarea,
                label: "Name",
                placeholder: "Enter your name"
            ),
            createEmailField(),
            DynamicFormField(
                id: "age",
                contentType: .number,
                label: "Age",
                placeholder: "Enter your age"
            )
        ]
    }
    
    private func createEmailField() -> DynamicFormField {
        return DynamicFormField(
            id: "email",
            textContentType: .emailAddress,
            label: "Email",
            placeholder: "Enter your email"
        )
    }
    
    private func createFormHints() -> PresentationHints {
        return PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .moderate,
            context: .create
        )
    }
}

/// Sample form data for examples
public struct SampleFormData: Codable {
    var name: String = ""
    var email: String = ""
    var age: Int = 0
}

// MARK: - Usage Documentation

/// Documentation for using Apple HIG compliance
public struct AppleHIGComplianceDocumentation {
    
    /// Basic usage example
    public static let basicUsage = """
    // Apply Apple HIG compliance to any view
    Button("Save") { saveData() }
        .appleHIGCompliant()
    
    // The framework automatically adds:
    // - Accessibility labels and hints
    // - Platform-appropriate styling
    // - Proper touch targets
    // - VoiceOver support
    // - Keyboard navigation
    // - High contrast support
    // - Platform-specific interactions
    """
    
    /// Advanced usage example
    public static let advancedUsage = """
    // Apply specific compliance features
    VStack {
        TextField("Name", text: $name)
            .automaticAccessibility()
        
        Button("Submit") { submit() }
            .platformPatterns()
        
        List(items) { item in
            ItemRow(item: item)
        }
        .visualConsistency()
    }
    .appleHIGCompliant() // Apply comprehensive compliance
    """
    
    /// Platform-specific usage
    public static let platformSpecificUsage = """
    // iOS gets navigation stacks and haptic feedback
    // macOS gets window patterns and keyboard shortcuts
    // All platforms get appropriate accessibility features
    
    NavigationView {
        ContentView()
            .appleHIGCompliant()
    }
    """
}
