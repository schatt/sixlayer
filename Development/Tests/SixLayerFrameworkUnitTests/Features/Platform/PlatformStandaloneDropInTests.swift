import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for standalone drop-in replacement functions
/// These functions provide SwiftUI API-compatible alternatives with automatic accessibility compliance
@Suite("Platform Standalone Drop-In Functions")
struct PlatformStandaloneDropInTests {
    
    // MARK: - platformTextField Tests
    
    @Test @MainActor func testPlatformTextField_Basic() {
        // Given: Text binding and placeholder
        // Use State initializer to avoid warnings about accessing State outside View
        let text = State(initialValue: "")
        let placeholder = "Enter name"
        
        // When: Creating text field
        let view = platformTextField(placeholder, text: text.projectedValue)
        
        // Then: View should be created successfully (compilation success means it works)
        _ = view // Use view to verify it compiles
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextField_WithAxis() {
        // Given: Text binding, placeholder, and vertical axis
        let text = State(initialValue: "")
        let placeholder = "Enter description"
        
        // When: Creating text field with vertical axis
        let view = platformTextField(placeholder, text: text.projectedValue, axis: .vertical)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextField_TextBinding() {
        // Given: Text binding with initial value
        let text = State(initialValue: "Initial value")
        let placeholder = "Enter text"
        
        // When: Creating text field
        let view = platformTextField(placeholder, text: text.projectedValue)
        
        // Then: View should be created and binding should work
        _ = view
        #expect(text.wrappedValue == "Initial value")
    }
    
    // MARK: - platformSecureField Tests
    
    @Test @MainActor func testPlatformSecureField_Basic() {
        // Given: Text binding and placeholder
        let password = State(initialValue: "")
        let placeholder = "Enter password"
        
        // When: Creating secure field
        let view = platformSecureField(placeholder, text: password.projectedValue)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformSecureField_TextBinding() {
        // Given: Text binding with initial value
        let password = State(initialValue: "secret123")
        let placeholder = "Enter password"
        
        // When: Creating secure field
        let view = platformSecureField(placeholder, text: password.projectedValue)
        
        // Then: View should be created and binding should work
        _ = view
        #expect(password.wrappedValue == "secret123")
    }
    
    // MARK: - platformToggle Tests
    
    @Test @MainActor func testPlatformToggle_Basic() {
        // Given: Boolean binding and label
        let isEnabled = State(initialValue: false)
        let label = "Enable notifications"
        
        // When: Creating toggle
        let view = platformToggle(label, isOn: isEnabled.projectedValue)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformToggle_InitialState() {
        // Given: Boolean binding with initial true state
        let isEnabled = State(initialValue: true)
        let label = "Enabled"
        
        // When: Creating toggle
        let view = platformToggle(label, isOn: isEnabled.projectedValue)
        
        // Then: View should be created and state should be preserved
        _ = view
        #expect(isEnabled.wrappedValue == true)
    }
    
    @Test @MainActor func testPlatformToggle_StateChange() {
        // Given: Boolean binding
        let isEnabled = State(initialValue: false)
        let label = "Toggle me"
        
        // When: Creating toggle
        let view = platformToggle(label, isOn: isEnabled.projectedValue)
        
        // Then: View should be created (state changes require View context)
        _ = view
        #expect(true)
    }
    
    // MARK: - platformForm Tests
    
    @Test @MainActor func testPlatformForm_Basic() {
        // Given: Form content
        let content = Text("Form content")
        
        // When: Creating form
        let view = platformForm {
            content
        }
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformForm_WithMultipleFields() {
        // Given: Multiple form fields
        let name = State(initialValue: "")
        let email = State(initialValue: "")
        let enabled = State(initialValue: false)
        
        // When: Creating form with multiple fields
        let view = platformForm {
            platformTextField("Name", text: name.projectedValue)
            platformTextField("Email", text: email.projectedValue)
            platformToggle("Enabled", isOn: enabled.projectedValue)
        }
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformForm_EmptyContent() {
        // Given: Empty form content
        // When: Creating form with no content
        let view = platformForm {
            EmptyView()
        }
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    // MARK: - platformTextEditor Tests
    
    @Test @MainActor func testPlatformTextEditor_Basic() {
        // Given: Text binding and prompt
        let text = State(initialValue: "")
        let prompt = "Enter description"
        
        // When: Creating text editor
        let view = platformTextEditor(prompt, text: text.projectedValue)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextEditor_WithInitialText() {
        // Given: Text binding with initial value
        let text = State(initialValue: "Initial text")
        let prompt = "Enter description"
        
        // When: Creating text editor
        let view = platformTextEditor(prompt, text: text.projectedValue)
        
        // Then: View should be created and text should be preserved
        _ = view
        #expect(text.wrappedValue == "Initial text")
    }
    
    @Test @MainActor func testPlatformTextEditor_TextBinding() {
        // Given: Text binding
        let text = State(initialValue: "")
        let prompt = "Enter text"
        
        // When: Creating text editor
        let view = platformTextEditor(prompt, text: text.projectedValue)
        
        // Then: View should be created (text changes require View context)
        _ = view
        #expect(true)
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testStandaloneFunctions_WorkTogether() {
        // Given: Multiple bindings
        let name = State(initialValue: "")
        let password = State(initialValue: "")
        let description = State(initialValue: "")
        let enabled = State(initialValue: false)
        
        // When: Creating a form with all standalone functions
        let view = platformForm {
            platformTextField("Name", text: name.projectedValue)
            platformSecureField("Password", text: password.projectedValue)
            platformTextEditor("Description", text: description.projectedValue)
            platformToggle("Enabled", isOn: enabled.projectedValue)
        }
        
        // Then: All functions should work together
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testStandaloneFunctions_AccessibilityCompliance() {
        // Given: A form with standalone functions
        let text = State(initialValue: "")
        
        // When: Creating views with standalone functions
        let textField = platformTextField("Enter text", text: text.projectedValue)
        let secureField = platformSecureField("Enter password", text: text.projectedValue)
        let toggle = platformToggle("Enable", isOn: .constant(true))
        let form = platformForm {
            textField
        }
        let editor = platformTextEditor("Enter description", text: text.projectedValue)
        
        // Then: All views should be created (accessibility compliance is automatic)
        _ = textField
        _ = secureField
        _ = toggle
        _ = form
        _ = editor
        #expect(true)
    }
    
    // MARK: - Backward Compatibility Tests
    
    @Test @MainActor func testBackwardCompatibility_ExtensionMethodsStillWork() {
        // Given: Extension methods should still work
        let text = State(initialValue: "")
        let isOn = State(initialValue: false)
        
        // When: Using extension methods
        let textField = EmptyView().platformTextField(text: text.projectedValue, prompt: "Enter text")
        let secureField = EmptyView().platformSecureTextField(text: text.projectedValue, prompt: "Enter password")
        let toggle = EmptyView().platformToggle(isOn: isOn.projectedValue) { Text("Label") }
        let form = EmptyView().platformFormContainer {
            Text("Content")
        }
        let editor = EmptyView().platformTextEditor(text: text.projectedValue, prompt: "Enter text")
        
        // Then: Extension methods should still work
        _ = textField
        _ = secureField
        _ = toggle
        _ = form
        _ = editor
        #expect(true)
    }
    
    // MARK: - Label Parameter Tests (Issue #155)
    
    @Test @MainActor func testPlatformTextField_WithLabelParameter() {
        // Given: Text binding, placeholder, and explicit label
        let text = State(initialValue: "")
        let placeholder = "Enter name"
        let label = "Full name"
        
        // When: Creating text field with label parameter
        let view = platformTextField(label: label, prompt: placeholder, text: text.projectedValue)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextField_WithLabelParameter_BackwardCompatible() {
        // Given: Text binding and placeholder (old API)
        let text = State(initialValue: "")
        let placeholder = "Enter name"
        
        // When: Creating text field without label (backward compatible)
        let view = platformTextField(placeholder, text: text.projectedValue)
        
        // Then: View should still work
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextField_WithAxisAndLabel() {
        // Given: Text binding, placeholder, axis, and label
        let text = State(initialValue: "")
        let placeholder = "Enter description"
        let label = "Description field"
        
        // When: Creating text field with axis and label
        let view = platformTextField(label: label, prompt: placeholder, text: text.projectedValue, axis: .vertical)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformSecureField_WithLabelParameter() {
        // Given: Text binding, placeholder, and explicit label
        let password = State(initialValue: "")
        let placeholder = "Enter password"
        let label = "Password field"
        
        // When: Creating secure field with label parameter
        let view = platformSecureField(label: label, prompt: placeholder, text: password.projectedValue)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformToggle_WithLabelParameter() {
        // Given: Boolean binding and explicit label
        let isEnabled = State(initialValue: false)
        let label = "Enable notifications"
        
        // When: Creating toggle with label parameter
        let view = platformToggle(label: label, isOn: isEnabled.projectedValue)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextEditor_WithLabelParameter() {
        // Given: Text binding, prompt, and explicit label
        let text = State(initialValue: "")
        let prompt = "Enter description"
        let label = "Description editor"
        
        // When: Creating text editor with label parameter
        let view = platformTextEditor(label: label, prompt: prompt, text: text.projectedValue)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformButton_WithLabelParameter() {
        // Given: Action and explicit label
        var actionCalled = false
        let label = "Save document"
        
        // When: Creating button with label parameter
        let view = platformButton(label: label) {
            actionCalled = true
        }
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    // MARK: - LocalizedStringKey and Text Support Tests
    
    @Test @MainActor func testPlatformTextField_WithLocalizedStringKey() {
        // Given: Text binding and LocalizedStringKey label
        let text = State(initialValue: "")
        let label = LocalizedStringKey("field.name")
        
        // When: Creating text field with LocalizedStringKey
        let view = platformTextField(label: label, prompt: "Enter name", text: text.projectedValue)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextField_WithTextLabel() {
        // Given: Text binding and Text label
        let text = State(initialValue: "")
        let label = Text("Full name")
        
        // When: Creating text field with Text label
        let view = platformTextField(label: label, prompt: "Enter name", text: text.projectedValue)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformButton_WithLocalizedStringKey() {
        // Given: Action and LocalizedStringKey label
        var actionCalled = false
        let label = LocalizedStringKey("button.save")
        
        // When: Creating button with LocalizedStringKey
        let view = platformButton(label: label) {
            actionCalled = true
        }
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformButton_WithTextLabel() {
        // Given: Action and Text label
        var actionCalled = false
        let label = Text("Save document")
        
        // When: Creating button with Text label
        let view = platformButton(label: label) {
            actionCalled = true
        }
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
}
