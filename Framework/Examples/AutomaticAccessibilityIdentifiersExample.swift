import SwiftUI
import SixLayerFramework

/**
 * Automatic Accessibility Identifiers Example
 * 
 * This example demonstrates how SixLayer framework automatically generates
 * accessibility identifiers for views, making UI testing easier without
 * requiring manual identifier assignment.
 * 
 * IMPORTANT: The framework now automatically detects your app's namespace!
 * No manual configuration required in most cases.
 * 
 * Example App setup (minimal):
 * ```swift
 * @main
 * struct MyApp: App {
 *     init() {
 *         // Optional: Only configure if you want to override defaults
 *         let config = AccessibilityIdentifierConfig.shared
 *         config.enableAutoIDs = true
 *         // config.namespace = "MyApp" // Now optional - auto-detected!
 *         config.mode = .automatic
 *     }
 *     
 *     var body: some Scene {
 *         WindowGroup {
 *             ContentView()
 *                 .enableGlobalAutomaticCompliance()
 *         }
 *     }
 * }
 * ```
 * 
 * Automatic Namespace Detection:
 * - Real Apps: Detects app name from Bundle.main (e.g., "MyApp")
 * - Test Environment: Uses "SixLayer" for framework tests
 * - Fallback: Uses "app" if detection fails
 * - Override: You can still set custom namespace if needed
 */

struct AutomaticAccessibilityIdentifiersExample: View {
    
    // Sample data
    let users = [
        User(id: "user-1", name: "Alice", role: "Developer"),
        User(id: "user-2", name: "Bob", role: "Designer"),
        User(id: "user-3", name: "Charlie", role: "Manager")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Example 1: Basic automatic identifiers
                VStack(alignment: .leading, spacing: 8) {
                    Text("Example 1: Basic Automatic Identifiers")
                        .font(.headline)
                    
                    Text("These buttons will automatically get identifiers like:")
                    Text("• MyApp.main.element.save-1234")
                    Text("• MyApp.main.element.cancel-5678")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Save") { }
                    Button("Cancel") { }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Example 2: Layer 1 function with automatic identifiers
                VStack(alignment: .leading, spacing: 8) {
                    Text("Example 2: Layer 1 Function")
                        .font(.headline)
                    
                    Text("Layer 1 functions automatically include accessibility identifiers:")
                    Text("• MyApp.list.item.user-1")
                    Text("• MyApp.list.item.user-2")
                    Text("• MyApp.list.item.user-3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // This will automatically get accessibility identifiers
                    platformPresentItemCollection_L1(
                        items: users,
                        hints: PresentationHints(
                            dataType: .generic,
                            presentationPreference: .list,
                            complexity: .simple,
                            context: .list,
                            customPreferences: [:]
                        )
                    )
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // Example 3: Manual override
                VStack(alignment: .leading, spacing: 8) {
                    Text("Example 3: Manual Override")
                        .font(.headline)
                    
                    Text("Manual identifiers always override automatic ones:")
                    Text("• custom-save-button")
                    Text("• custom-cancel-button")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Save") { }
                        .platformAccessibilityIdentifier("custom-save-button")
                    
                    Button("Cancel") { }
                        .platformAccessibilityIdentifier("custom-cancel-button")
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                // Example 4: Opt-out
                VStack(alignment: .leading, spacing: 8) {
                    Text("Example 4: Opt-out")
                        .font(.headline)
                    
                    Text("Views can opt out of automatic identifiers:")
                    Text("• No automatic identifier assigned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Decorative Button") { }
                        .disableAutomaticAccessibilityIdentifiers()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Automatic Accessibility Identifiers")
        }
        // This applies automatic identifiers to the entire view hierarchy
        .automaticCompliance()
    }
}

// MARK: - Configuration Example

struct AccessibilityIdentifierConfigurationExample: View {
    
    @State private var enableAutoIDs = true
    @State private var namespace = "" // Empty means use auto-detection
    @State private var mode: AccessibilityIdentifierMode = .automatic
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Global Configuration")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Automatic IDs", isOn: $enableAutoIDs)
                    .onChange(of: enableAutoIDs) { newValue in
                        Task { @MainActor in
                            AccessibilityIdentifierConfig.shared.enableAutoIDs = newValue
                        }
                    }
                
                VStack(alignment: .leading) {
                    Text("Namespace: \(namespace.isEmpty ? "Auto-detected" : namespace)")
                    TextField("Namespace (leave empty for auto-detection)", text: $namespace)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: namespace) { newValue in
                            Task { @MainActor in
                                if newValue.isEmpty {
                                    // Reset to auto-detection
                                    AccessibilityIdentifierConfig.shared.resetToDefaults()
                                } else {
                                    AccessibilityIdentifierConfig.shared.namespace = newValue
                                }
                            }
                        }
                }
                
                VStack(alignment: .leading) {
                    Text("Generation Mode")
                    Picker("Mode", selection: $mode) {
                        Text("Automatic").tag(AccessibilityIdentifierMode.automatic)
                        Text("Semantic").tag(AccessibilityIdentifierMode.semantic)
                        Text("Minimal").tag(AccessibilityIdentifierMode.minimal)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: mode) { newValue in
                        Task { @MainActor in
                            AccessibilityIdentifierConfig.shared.mode = newValue
                        }
                    }
                }
            }
            
            Text("Current Configuration:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Enable Auto IDs: \(enableAutoIDs ? "Yes" : "No")")
                Text("• Namespace: \(namespace.isEmpty ? "Auto-detected" : namespace)")
                Text("• Mode: \(mode.rawValue)")
                Text("• Description: \(mode.description)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Test Data

struct User: Identifiable {
    let id: String
    let name: String
    let role: String
}

// MARK: - Preview

#Preview {
    AutomaticAccessibilityIdentifiersExample()
}

#Preview("Configuration") {
    AccessibilityIdentifierConfigurationExample()
}
