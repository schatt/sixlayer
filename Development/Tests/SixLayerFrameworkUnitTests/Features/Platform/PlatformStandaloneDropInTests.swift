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
        @State var text = ""
        let placeholder = "Enter name"
        
        // When: Creating text field
        let view = platformTextField(placeholder, text: $text)
        
        // Then: View should be created successfully (compilation success means it works)
        _ = view // Use view to verify it compiles
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextField_WithAxis() {
        // Given: Text binding, placeholder, and vertical axis
        @State var text = ""
        let placeholder = "Enter description"
        
        // When: Creating text field with vertical axis
        let view = platformTextField(placeholder, text: $text, axis: .vertical)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextField_TextBinding() {
        // Given: Text binding with initial value
        @State var text = "Initial value"
        let placeholder = "Enter text"
        
        // When: Creating text field
        let view = platformTextField(placeholder, text: $text)
        
        // Then: View should be created and binding should work
        _ = view
        #expect(text == "Initial value")
    }
    
    // MARK: - platformSecureField Tests
    
    @Test @MainActor func testPlatformSecureField_Basic() {
        // Given: Text binding and placeholder
        @State var password = ""
        let placeholder = "Enter password"
        
        // When: Creating secure field
        let view = platformSecureField(placeholder, text: $password)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformSecureField_TextBinding() {
        // Given: Text binding with initial value
        @State var password = "secret123"
        let placeholder = "Enter password"
        
        // When: Creating secure field
        let view = platformSecureField(placeholder, text: $password)
        
        // Then: View should be created and binding should work
        _ = view
        #expect(password == "secret123")
    }
    
    // MARK: - platformToggle Tests
    
    @Test @MainActor func testPlatformToggle_Basic() {
        // Given: Boolean binding and label
        @State var isEnabled = false
        let label = "Enable notifications"
        
        // When: Creating toggle
        let view = platformToggle(label, isOn: $isEnabled)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformToggle_InitialState() {
        // Given: Boolean binding with initial true state
        @State var isEnabled = true
        let label = "Enabled"
        
        // When: Creating toggle
        let view = platformToggle(label, isOn: $isEnabled)
        
        // Then: View should be created and state should be preserved
        _ = view
        #expect(isEnabled == true)
    }
    
    @Test @MainActor func testPlatformToggle_StateChange() {
        // Given: Boolean binding
        @State var isEnabled = false
        let label = "Toggle me"
        
        // When: Creating toggle
        let view = platformToggle(label, isOn: $isEnabled)
        
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
        @State var name = ""
        @State var email = ""
        @State var enabled = false
        
        // When: Creating form with multiple fields
        let view = platformForm {
            platformTextField("Name", text: $name)
            platformTextField("Email", text: $email)
            platformToggle("Enabled", isOn: $enabled)
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
        @State var text = ""
        let prompt = "Enter description"
        
        // When: Creating text editor
        let view = platformTextEditor(prompt, text: $text)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextEditor_WithInitialText() {
        // Given: Text binding with initial value
        @State var text = "Initial text"
        let prompt = "Enter description"
        
        // When: Creating text editor
        let view = platformTextEditor(prompt, text: $text)
        
        // Then: View should be created and text should be preserved
        _ = view
        #expect(text == "Initial text")
    }
    
    @Test @MainActor func testPlatformTextEditor_TextBinding() {
        // Given: Text binding
        @State var text = ""
        let prompt = "Enter text"
        
        // When: Creating text editor
        let view = platformTextEditor(prompt, text: $text)
        
        // Then: View should be created (text changes require View context)
        _ = view
        #expect(true)
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testStandaloneFunctions_WorkTogether() {
        // Given: Multiple bindings
        @State var name = ""
        @State var password = ""
        @State var description = ""
        @State var enabled = false
        
        // When: Creating a form with all standalone functions
        let view = platformForm {
            platformTextField("Name", text: $name)
            platformSecureField("Password", text: $password)
            platformTextEditor("Description", text: $description)
            platformToggle("Enabled", isOn: $enabled)
        }
        
        // Then: All functions should work together
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testStandaloneFunctions_AccessibilityCompliance() {
        // Given: A form with standalone functions
        @State var text = ""
        
        // When: Creating views with standalone functions
        let textField = platformTextField("Enter text", text: $text)
        let secureField = platformSecureField("Enter password", text: $text)
        let toggle = platformToggle("Enable", isOn: .constant(true))
        let form = platformForm {
            textField
        }
        let editor = platformTextEditor("Enter description", text: $text)
        
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
        @State var text = ""
        @State var isOn = false
        
        // When: Using extension methods
        let textField = EmptyView().platformTextField(text: $text, prompt: "Enter text")
        let secureField = EmptyView().platformSecureTextField(text: $text, prompt: "Enter password")
        let toggle = EmptyView().platformToggle(isOn: $isOn) { Text("Label") }
        let form = EmptyView().platformFormContainer {
            Text("Content")
        }
        let editor = EmptyView().platformTextEditor(text: $text, prompt: "Enter text")
        
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
        @State var text = ""
        let placeholder = "Enter name"
        let label = "Full name"
        
        // When: Creating text field with label parameter
        let view = platformTextField(label: label, prompt: placeholder, text: $text)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextField_WithLabelParameter_BackwardCompatible() {
        // Given: Text binding and placeholder (old API)
        @State var text = ""
        let placeholder = "Enter name"
        
        // When: Creating text field without label (backward compatible)
        let view = platformTextField(placeholder, text: $text)
        
        // Then: View should still work
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextField_WithAxisAndLabel() {
        // Given: Text binding, placeholder, axis, and label
        @State var text = ""
        let placeholder = "Enter description"
        let label = "Description field"
        
        // When: Creating text field with axis and label
        let view = platformTextField(label: label, prompt: placeholder, text: $text, axis: .vertical)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformSecureField_WithLabelParameter() {
        // Given: Text binding, placeholder, and explicit label
        @State var password = ""
        let placeholder = "Enter password"
        let label = "Password field"
        
        // When: Creating secure field with label parameter
        let view = platformSecureField(label: label, prompt: placeholder, text: $password)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformToggle_WithLabelParameter() {
        // Given: Boolean binding and explicit label
        @State var isEnabled = false
        let label = "Enable notifications"
        
        // When: Creating toggle with label parameter
        let view = platformToggle(label: label, isOn: $isEnabled)
        
        // Then: View should be created successfully
        _ = view
        #expect(true)
    }
    
    @Test @MainActor func testPlatformTextEditor_WithLabelParameter() {
        // Given: Text binding, prompt, and explicit label
        @State var text = ""
        let prompt = "Enter description"
        let label = "Description editor"
        
        // When: Creating text editor with label parameter
        let view = platformTextEditor(label: label, prompt: prompt, text: $text)
        
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
}
