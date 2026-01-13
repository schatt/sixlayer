import SwiftUI
import SixLayerFramework

/**
 * Accessibility Identifier Debugging Example
 * 
 * This example demonstrates how to debug and inspect automatically generated
 * accessibility identifiers using the built-in debugging capabilities.
 */

struct AccessibilityIdentifierDebuggingExample: View {
    
    @State private var enableDebugLogging = false
    @State private var debugLog = "No identifiers generated yet."
    
    // Sample data
    let users = [
        User(id: "user-1", name: "Alice", role: "Developer"),
        User(id: "user-2", name: "Bob", role: "Designer"),
        User(id: "user-3", name: "Charlie", role: "Manager")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Debug Controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Debug Controls")
                        .font(.headline)
                    
                    Toggle("Enable Debug Logging", isOn: $enableDebugLogging)
                        .onChange(of: enableDebugLogging) { newValue in
                            Task { @MainActor in
                                AccessibilityIdentifierConfig.shared.enableDebugLogging = newValue
                            }
                        }
                    
                    HStack {
                        Button("Refresh Log") {
                            Task { @MainActor in
                                debugLog = AccessibilityIdentifierConfig.shared.getDebugLog()
                            }
                        }
                        
                        Button("Clear Log") {
                            Task { @MainActor in
                                AccessibilityIdentifierConfig.shared.clearDebugLog()
                                debugLog = "Log cleared."
                            }
                        }
                        
                        Button("Print to Console") {
                            Task { @MainActor in
                                AccessibilityIdentifierConfig.shared.printDebugLog()
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // Debug Log Display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated IDs Log")
                        .font(.headline)
                    
                    ScrollView {
                        Text(debugLog)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(4)
                    }
                    .frame(maxHeight: 200)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Test Views
                VStack(alignment: .leading, spacing: 12) {
                    Text("Test Views")
                        .font(.headline)
                    
                    Text("These views will generate accessibility identifiers:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Basic buttons
                    HStack {
                        Button("Save") { }
                        Button("Cancel") { }
                        Button("Delete") { }
                    }
                    
                    // Layer 1 function
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
                    
                    // Manual override example
                    Button("Manual Override") { }
                        .platformAccessibilityIdentifier("custom-manual-button")
                    
                    // Opt-out example
                    Button("Opt Out") { }
                        .disableAutomaticAccessibilityIdentifiers()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                // Configuration Display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Configuration")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Namespace: \(AccessibilityIdentifierConfig.shared.namespace)")
                        Text("• Mode: \(AccessibilityIdentifierConfig.shared.mode.rawValue)")
                        Text("• Auto IDs Enabled: \(AccessibilityIdentifierConfig.shared.enableAutoIDs ? "Yes" : "No")")
                        Text("• Debug Logging: \(AccessibilityIdentifierConfig.shared.enableDebugLogging ? "Yes" : "No")")
                        Text("• Collision Detection: \(AccessibilityIdentifierConfig.shared.enableCollisionDetection ? "Yes" : "No")")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Accessibility ID Debugging")
        }
        .onAppear {
            // Initialize debug logging state
            enableDebugLogging = AccessibilityIdentifierConfig.shared.enableDebugLogging
        }
        // Apply automatic identifiers to the entire view hierarchy
        .automaticCompliance()
    }
}

// MARK: - Advanced Debugging View

struct AdvancedDebuggingView: View {
    
    @State private var testString = "Hello World"
    @State private var testNumber = 42
    @State private var testObject = TestObject()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Advanced Debugging")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Test Different Object Types")
                    .font(.headline)
                
                TextField("Test String", text: $testString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Stepper("Test Number: \(testNumber)", value: $testNumber)
                
                Button("Generate Test IDs") {
                    Task { @MainActor in
                        let generator = AccessibilityIdentifierGenerator()
                        
                        // Test different object types
                        let stringID = generator.generateID(for: testString, role: "text", context: "input")
                        let numberID = generator.generateID(for: testNumber, role: "number", context: "input")
                        let objectID = generator.generateID(for: testObject, role: "object", context: "test")
                        
                        print("Generated IDs:")
                        print("String: \(stringID)")
                        print("Number: \(numberID)")
                        print("Object: \(objectID)")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Collision Detection Test")
                    .font(.headline)
                
                Button("Test Collision Detection") {
                    Task { @MainActor in
                        let generator = AccessibilityIdentifierGenerator()
                        let config = AccessibilityIdentifierConfig.shared
                        
                        // Generate some IDs
                        let id1 = generator.generateID(for: "test", role: "button", context: "ui")
                        let id2 = generator.generateID(for: "test", role: "button", context: "ui")
                        
                        let collision1 = generator.checkForCollision(id1)
                        let collision2 = generator.checkForCollision("nonexistent-id")
                        
                        print("Collision Detection Results:")
                        print("ID '\(id1)' collision: \(collision1)")
                        print("ID 'nonexistent-id' collision: \(collision2)")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Test Data

struct TestObject {
    let id = "test-object-123"
    let name = "Test Object"
}

// MARK: - Preview

#Preview {
    AccessibilityIdentifierDebuggingExample()
}

#Preview("Advanced Debugging") {
    AdvancedDebuggingView()
}
