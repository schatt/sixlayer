import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for standalone drop-in replacement functions
/// These functions provide SwiftUI API-compatible alternatives with automatic accessibility compliance
@Suite("Platform Standalone Drop-In Functions", HostedViewTestIsolationTrait())
struct PlatformStandaloneDropInTests {
    
    // MARK: - platformTextField Tests
    
    @Test @MainActor func testPlatformTextField_Basic() {
        let text = State(initialValue: "")
        let placeholder = "Enter name"
        let view = platformTextField(placeholder, text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformTextField_WithAxis() {
        let text = State(initialValue: "")
        let placeholder = "Enter description"
        let view = platformTextField(placeholder, text: text.projectedValue, axis: .vertical)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformTextField_TextBinding() {
        let text = State(initialValue: "Initial value")
        let placeholder = "Enter text"
        let view = platformTextField(placeholder, text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
        #expect(text.wrappedValue == "Initial value")
    }
    
    // MARK: - platformSecureField Tests
    
    @Test @MainActor func testPlatformSecureField_Basic() {
        let password = State(initialValue: "")
        let placeholder = "Enter password"
        let view = platformSecureField(placeholder, text: password.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformSecureField_TextBinding() {
        let password = State(initialValue: "secret123")
        let placeholder = "Enter password"
        let view = platformSecureField(placeholder, text: password.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
        #expect(password.wrappedValue == "secret123")
    }
    
    // MARK: - platformToggle Tests
    
    @Test @MainActor func testPlatformToggle_Basic() {
        let isEnabled = State(initialValue: false)
        let label = "Enable notifications"
        let view = platformToggle(label, isOn: isEnabled.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformToggle_InitialState() {
        let isEnabled = State(initialValue: true)
        let label = "Enabled"
        let view = platformToggle(label, isOn: isEnabled.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
        #expect(isEnabled.wrappedValue == true)
    }
    
    @Test @MainActor func testPlatformToggle_StateChange() {
        let isEnabled = State(initialValue: false)
        let label = "Toggle me"
        let view = platformToggle(label, isOn: isEnabled.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    // MARK: - platformForm Tests
    
    @Test @MainActor func testPlatformForm_Basic() {
        let content = Text("Form content")
        let view = platformForm {
            content
        }
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformForm_WithMultipleFields() {
        let name = State(initialValue: "")
        let email = State(initialValue: "")
        let enabled = State(initialValue: false)
        let view = platformForm {
            platformTextField("Name", text: name.projectedValue)
            platformTextField("Email", text: email.projectedValue)
            platformToggle("Enabled", isOn: enabled.projectedValue)
        }
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformForm_EmptyContent() {
        let view = platformForm {
            EmptyView()
        }
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    // MARK: - platformTextEditor Tests
    
    @Test @MainActor func testPlatformTextEditor_Basic() {
        let text = State(initialValue: "")
        let prompt = "Enter description"
        let view = platformTextEditor(prompt, text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformTextEditor_WithInitialText() {
        let text = State(initialValue: "Initial text")
        let prompt = "Enter description"
        let view = platformTextEditor(prompt, text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
        #expect(text.wrappedValue == "Initial text")
    }
    
    @Test @MainActor func testPlatformTextEditor_TextBinding() {
        let text = State(initialValue: "")
        let prompt = "Enter text"
        let view = platformTextEditor(prompt, text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformTextEditor_StrictDropIn_TextOnly() {
        let text = State(initialValue: "")
        let view = platformTextEditor(text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testStandaloneFunctions_WorkTogether() {
        let name = State(initialValue: "")
        let password = State(initialValue: "")
        let description = State(initialValue: "")
        let enabled = State(initialValue: false)
        let view = platformForm {
            platformTextField("Name", text: name.projectedValue)
            platformSecureField("Password", text: password.projectedValue)
            platformTextEditor("Description", text: description.projectedValue)
            platformToggle("Enabled", isOn: enabled.projectedValue)
        }
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testStandaloneFunctions_AccessibilityCompliance() {
        let text = State(initialValue: "")
        let textField = platformTextField("Enter text", text: text.projectedValue)
        let secureField = platformSecureField("Enter password", text: text.projectedValue)
        let toggle = platformToggle("Enable", isOn: .constant(true))
        let form = platformForm {
            textField
        }
        let editor = platformTextEditor("Enter description", text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(textField))
        #expect(PlatformContainerStructureAssertions.isHostable(secureField))
        #expect(PlatformContainerStructureAssertions.isHostable(toggle))
        #expect(PlatformContainerStructureAssertions.isHostable(form))
        #expect(PlatformContainerStructureAssertions.isHostable(editor))
    }
    
    // MARK: - Backward Compatibility Tests
    
    @Test @MainActor func testBackwardCompatibility_ExtensionMethodsStillWork() {
        let text = State(initialValue: "")
        let isOn = State(initialValue: false)
        let textField = EmptyView().platformTextField(text: text.projectedValue, prompt: "Enter text")
        let secureField = EmptyView().platformSecureTextField(text: text.projectedValue, prompt: "Enter password")
        let toggle = EmptyView().platformToggle(isOn: isOn.projectedValue) { Text("Label") }
        let form = EmptyView().platformFormContainer {
            Text("Content")
        }
        let editor = EmptyView().platformTextEditor(text: text.projectedValue, prompt: "Enter text")
        #expect(PlatformContainerStructureAssertions.isHostable(textField))
        #expect(PlatformContainerStructureAssertions.isHostable(secureField))
        #expect(PlatformContainerStructureAssertions.isHostable(toggle))
        #expect(PlatformContainerStructureAssertions.isHostable(form))
        #expect(PlatformContainerStructureAssertions.isHostable(editor))
    }

    // MARK: - platformFormContainer ownership (Issue #218)

    /// `platformFormContainer` must host a `Form` on every platform (no nested `Form` in app code).
    @Test @MainActor
    func testPlatformFormContainer_OwnsForm() {
        let view = EmptyView().platformFormContainer {
            Text("FormOwnedMarker")
        }
        #expect(
            PlatformContainerStructureAssertions.containsForm(view),
            "platformFormContainer should wrap content in Form"
        )
    }

    // MARK: - platformSectionContainer vs platformGroupedInsetContainer (Issue #220)

    @Test @MainActor
    func testPlatformSectionContainerNoHeader_UsesSectionInsidePlatformFormContainer() {
        let view = EmptyView().platformFormContainer {
            platformSectionContainer {
                Text("SectionRowMarker220")
            }
        }
        #expect(
            PlatformContainerStructureAssertions.containsSection(view),
            "no-header platformSectionContainer should use Section inside platformFormContainer"
        )
    }

    @Test @MainActor
    func testPlatformGroupedInsetContainer_IsVStackInsetNotSection() {
        let view = EmptyView().platformGroupedInsetContainer {
            Text("InsetMarker220")
        }
        #expect(
            PlatformContainerStructureAssertions.containsVStackWithoutSection(view),
            "platformGroupedInsetContainer should use VStack for inset grouping without Section"
        )
    }
    
    // MARK: - Label Parameter Tests (Issue #155)
    
    @Test @MainActor func testPlatformTextField_WithLabelParameter() {
        let text = State(initialValue: "")
        let placeholder = "Enter name"
        let label = "Full name"
        let view = platformTextField(label: label, prompt: placeholder, text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformTextField_WithLabelParameter_BackwardCompatible() {
        let text = State(initialValue: "")
        let placeholder = "Enter name"
        let view = platformTextField(placeholder, text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformTextField_WithAxisAndLabel() {
        let text = State(initialValue: "")
        let placeholder = "Enter description"
        let label = "Description field"
        let view = platformTextField(label: label, prompt: placeholder, text: text.projectedValue, axis: .vertical)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformSecureField_WithLabelParameter() {
        let password = State(initialValue: "")
        let placeholder = "Enter password"
        let label = "Password field"
        let view = platformSecureField(label: label, prompt: placeholder, text: password.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformToggle_WithLabelParameter() {
        let isEnabled = State(initialValue: false)
        let label = "Enable notifications"
        let view = platformToggle(label: label, isOn: isEnabled.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformTextEditor_WithLabelParameter() {
        let text = State(initialValue: "")
        let prompt = "Enter description"
        let label = "Description editor"
        let view = platformTextEditor(label: label, prompt: prompt, text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformButton_WithLabelParameter() {
        let label = "Save document"
        let view = platformButton(label: label) { }
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    // MARK: - LocalizedStringKey and Text Support Tests
    
    @Test @MainActor func testPlatformTextField_WithLocalizedStringKey() {
        let text = State(initialValue: "")
        let label = LocalizedStringKey("field.name")
        let view = platformTextField(label: label, prompt: "Enter name", text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformTextField_WithTextLabel() {
        let text = State(initialValue: "")
        let label = Text("Full name")
        let view = platformTextField(label: label, prompt: "Enter name", text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformButton_WithLocalizedStringKey() {
        let label = LocalizedStringKey("button.save")
        let view = platformButton(label: label) { }
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
    
    @Test @MainActor func testPlatformButton_WithTextLabel() {
        let label = Text("Save document")
        let view = platformButton(label: label) { }
        #expect(PlatformContainerStructureAssertions.isHostable(view))
    }
}
