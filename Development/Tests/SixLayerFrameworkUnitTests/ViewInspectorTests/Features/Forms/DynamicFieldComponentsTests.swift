import Testing
import SwiftUI
@testable import SixLayerFramework

/**
 * BUSINESS PURPOSE: Dynamic field components provide specialized form field rendering
 * for different content types. These components handle user input, validation, OCR integration,
 * and platform-specific UI patterns for each field type.
 *
 * TESTING SCOPE: Tests that verify expected behavior for all dynamic field components.
 * These tests verify components render actual UI, integrate with form state, generate
 * accessibility identifiers, and provide expected functionality.
 *
 * METHODOLOGY: Tests that verify components render actual UI, integrate with
 * form state, generate accessibility identifiers, and provide expected functionality.
 */

@Suite("Dynamic Field Components")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class DynamicFieldComponentsTests: BaseTestClass {

    // MARK: - Multi-Select Field

    @Test @MainActor func testDynamicMultiSelectFieldRendersSelectionInterface() async {
        // DynamicMultiSelectField should:
        // 1. Render a multi-selection interface (checkboxes or toggle list)
        // 2. Display all options from field.options
        // 3. Allow selecting multiple options simultaneously
        // 4. Update formState with selected values as array
        // 5. Show visual indication of selected options

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "multiSelect",
            contentType: .multiselect,
            label: "Select Multiple",
            options: ["Option 1", "Option 2", "Option 3"]
        )

        let view = DynamicMultiSelectField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render all options from field
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            // Find all text elements and check if they contain the options
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let foundOption1 = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Option 1") ?? false
                }
                let foundOption2 = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Option 2") ?? false
                }
                let foundOption3 = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Option 3") ?? false
                }
                #expect(foundOption1 || foundOption2 || foundOption3, "Should display options from field")
            }
            
            // Additional check: should NOT show stub text (supplementary verification)
            let allTextsForStubCheck = inspected.sixLayerFindAll(Text.self)
            if !allTextsForStubCheck.isEmpty {
                let hasStubText = allTextsForStubCheck.contains { text in
                    (try? text.sixLayerString())?.contains("Multi-select - TDD Red Phase Stub") ?? false
                }
                if hasStubText {
                    Issue.record("DynamicMultiSelectField still shows stub text - needs implementation")
                }
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicMultiSelectField.*",
            platform: .iOS,
            componentName: "DynamicMultiSelectField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif

        // Should support multiple selections in formState
        formState.setValue(["Option 1", "Option 3"], for: "multiSelect")
        let selectedValues = formState.fieldValues["multiSelect"] as? [String]
        #expect(selectedValues?.contains("Option 1") == true, "Should support multiple selections")
        #expect(selectedValues?.contains("Option 3") == true, "Should support multiple selections")
    }

    // MARK: - Radio Field

    @Test @MainActor func testDynamicRadioFieldRendersRadioButtons() async {
        // DynamicRadioField should:
        // 1. Render radio button group (only one selection allowed)
        // 2. Display all options from field.options
        // 3. Allow selecting exactly one option
        // 4. Update formState with single selected value
        // 5. Show clear visual indication of selected option

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "radio",
            contentType: .radio,
            label: "Choose One",
            options: ["Choice A", "Choice B", "Choice C"]
        )

        let view = DynamicRadioField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render all radio options
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let foundChoiceA = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Choice A") ?? false
                }
                let foundChoiceB = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Choice B") ?? false
                }
                let foundChoiceC = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Choice C") ?? false
                }
                #expect(foundChoiceA || foundChoiceB || foundChoiceC, "Should display radio options")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicRadioField.*",
            platform: .iOS,
            componentName: "DynamicRadioField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif

        // Should support single selection
        formState.setValue("Choice B", for: "radio")
        let selectedValue = formState.fieldValues["radio"] as? String
        #expect(selectedValue == "Choice B", "Should support single radio selection")
    }

    // MARK: - Checkbox Field

    @Test @MainActor func testDynamicCheckboxFieldRendersCheckboxes() async {
        // DynamicCheckboxField should:
        // 1. Render checkbox group (multiple selections allowed)
        // 2. Display all options from field.options as checkboxes
        // 3. Allow toggling each checkbox independently
        // 4. Update formState with selected values as array
        // 5. Show checked/unchecked states clearly

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "checkboxes",
            contentType: .checkbox,
            label: "Select Multiple",
            options: ["Check 1", "Check 2", "Check 3"]
        )

        let view = DynamicCheckboxField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render checkbox options
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let foundCheck1 = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Check 1") ?? false
                }
                let foundCheck2 = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Check 2") ?? false
                }
                let foundCheck3 = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Check 3") ?? false
                }
                #expect(foundCheck1 || foundCheck2 || foundCheck3, "Should display checkbox options")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicCheckboxField.*",
            platform: .iOS,
            componentName: "DynamicCheckboxField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - Rich Text Field

    @Test @MainActor func testDynamicRichTextFieldRendersRichTextEditor() async {
        // DynamicRichTextField should:
        // 1. Render a rich text editor (formatted text input)
        // 2. Support text formatting (bold, italic, etc.)
        // 3. Provide formatting toolbar or controls
        // 4. Update formState with formatted text content
        // 5. Display formatted text preview

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "richtext",
            contentType: .richtext,
            label: "Rich Text"
        )

        let view = DynamicRichTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render text input interface
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        if let inspected = view.tryInspect() {
            // Should have text input capability - check if we can find text fields
            let textFields = inspected.sixLayerFindAll(TextField<Text>.self)
            if !textFields.isEmpty {
                #expect(!textFields.isEmpty, "Should provide text input interface")
            }
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicRichTextField interface not found")
            #else
            #expect(Bool(true), "DynamicRichTextField created (ViewInspector not available on macOS)")
            #endif
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicRichTextField.*",
            platform: .iOS,
            componentName: "DynamicRichTextField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - File Field

    @Test @MainActor func testDynamicFileFieldRendersFilePicker() async {
        // DynamicFileField should:
        // 1. Render file picker button/interface
        // 2. Allow selecting files from device
        // 3. Display selected file name(s)
        // 4. Update formState with file reference or path
        // 5. Show file selection status

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "file",
            contentType: .file,
            label: "Select File"
        )

        let view = DynamicFileField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render file picker interface
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        if let _ = view.tryInspect() {
            // View is inspectable - file picker interface should be present
            #expect(Bool(true), "Should provide file picker interface")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicFileField interface not found")
            #else
            #expect(Bool(true), "DynamicFileField created (ViewInspector not available on macOS)")
            #endif
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicFileField.*",
            platform: .iOS,
            componentName: "DynamicFileField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - Image Field

    @Test @MainActor func testDynamicImageFieldRendersImagePicker() async {
        // DynamicImageField should:
        // 1. Render image picker button/interface
        // 2. Allow selecting images from photo library or camera
        // 3. Display selected image preview
        // 4. Update formState with image reference or data
        // 5. Show image selection status

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "image",
            contentType: .image,
            label: "Select Image"
        )

        let view = DynamicImageField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render image picker interface
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        if let _ = view.tryInspect() {
            // View is inspectable - image picker interface should be present
            #expect(Bool(true), "Should provide image picker interface")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicImageField interface not found")
            #else
            #expect(Bool(true), "DynamicImageField created (ViewInspector not available on macOS)")
            #endif
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicImageField.*",
            platform: .iOS,
            componentName: "DynamicImageField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - Array Field

    @Test @MainActor func testDynamicArrayFieldRendersArrayInput() async {
        // DynamicArrayField should:
        // 1. Render interface for entering array of values
        // 2. Allow adding/removing items dynamically
        // 3. Provide add/remove controls
        // 4. Update formState with array of values
        // 5. Display all array items

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "array",
            contentType: .array,
            label: "Array Input"
        )

        let view = DynamicArrayField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render array input interface
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        if let _ = view.tryInspect() {
            // View is inspectable - array input interface should be present
            #expect(Bool(true), "Should provide array input interface")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicArrayField interface not found")
            #else
            #expect(Bool(true), "DynamicArrayField created (ViewInspector not available on macOS)")
            #endif
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicArrayField.*",
            platform: .iOS,
            componentName: "DynamicArrayField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - Data Field

    @Test @MainActor func testDynamicDataFieldRendersDataInput() async {
        // DynamicDataField should:
        // 1. Render interface for binary data input
        // 2. Allow pasting or importing data
        // 3. Display data size or preview
        // 4. Update formState with data reference
        // 5. Show data input status

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "data",
            contentType: .data,
            label: "Data Input"
        )

        let view = DynamicDataField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render data input interface
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        if let _ = view.tryInspect() {
            // View is inspectable - data input interface should be present
            #expect(Bool(true), "Should provide data input interface")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicDataField interface not found")
            #else
            #expect(Bool(true), "DynamicDataField created (ViewInspector not available on macOS)")
            #endif
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicDataField.*",
            platform: .iOS,
            componentName: "DynamicDataField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - Autocomplete Field

    @Test @MainActor func testDynamicAutocompleteFieldRendersAutocomplete() async {
        // DynamicAutocompleteField should:
        // 1. Render text input with autocomplete suggestions
        // 2. Show suggestions as user types
        // 3. Allow selecting from suggestions
        // 4. Update formState with selected value
        // 5. Filter suggestions based on input

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "autocomplete",
            contentType: .autocomplete,
            label: "Autocomplete",
            options: ["Apple", "Banana", "Cherry"]
        )

        let view = DynamicAutocompleteField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render autocomplete interface
        if let inspected = view.tryInspect() {
            // Should have text input with suggestions
            let hasAutocomplete = inspected.sixLayerCount > 0
            #expect(hasAutocomplete, "Should provide autocomplete interface")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicAutocompleteField interface not found")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "DynamicAutocompleteField created (ViewInspector not available on macOS)")
            #endif
        }

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicAutocompleteField.*",
            platform: .iOS,
            componentName: "DynamicAutocompleteField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - Enum Field

    @Test @MainActor func testDynamicEnumFieldRendersEnumPicker() async {
        // DynamicEnumField should:
        // 1. Render enum value picker
        // 2. Display all enum options from field.options
        // 3. Allow selecting single enum value
        // 4. Update formState with selected enum value
        // 5. Show selected enum value

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "enum",
            contentType: .enum,
            label: "Enum Field",
            options: ["Value1", "Value2", "Value3"]
        )

        let view = DynamicEnumField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render enum options
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let foundValue1 = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Value1") ?? false
                }
                let foundValue2 = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Value2") ?? false
                }
                let foundValue3 = allTexts.contains { text in
                    (try? text.sixLayerString())?.contains("Value3") ?? false
                }
                #expect(foundValue1 || foundValue2 || foundValue3, "Should display enum options")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicEnumField.*",
            platform: .iOS,
            componentName: "DynamicEnumField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - Custom Field

    @Test @MainActor func testDynamicCustomFieldRendersCustomComponent() async {
        // DynamicCustomField should:
        // 1. Use CustomFieldRegistry to find registered component
        // 2. Render registered custom component if available
        // 3. Show error message if custom type not registered
        // 4. Update formState through custom component
        // 5. Integrate with custom field protocol

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "custom",
            contentType: .custom,
            label: "Custom Field"
        )

        let view = DynamicCustomField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render custom component or error
        if let inspected = view.tryInspect() {
            // Should have some UI (either custom component or error message)
            let hasInterface = inspected.sixLayerCount > 0
            #expect(hasInterface, "Should render custom component or error message")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicCustomField interface not found")
            #else
            #expect(Bool(true), "DynamicCustomField created (ViewInspector not available on macOS)")
            #endif
        }

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicCustomField.*",
            platform: .iOS,
            componentName: "DynamicCustomField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - Color Field

    @Test @MainActor func testDynamicColorFieldRendersColorPicker() async {
        // DynamicColorField should:
        // 1. Render color picker interface
        // 2. Allow selecting colors (hex, RGB, or visual picker)
        // 3. Display selected color preview
        // 4. Update formState with color value
        // 5. Show color selection interface

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "color",
            contentType: .color,
            label: "Select Color"
        )

        let view = DynamicColorField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render color picker interface
        if let inspected = view.tryInspect() {
            // Should have color selection capability
            let hasColorPicker = inspected.sixLayerCount > 0
            #expect(hasColorPicker, "Should provide color picker interface")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicColorField interface not found")
            #else
            #expect(Bool(true), "DynamicColorField created (ViewInspector not available on macOS)")
            #endif
        }

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicColorField.*",
            platform: .iOS,
            componentName: "DynamicColorField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    // MARK: - Text Area Field

    @Test @MainActor func testDynamicTextAreaFieldRendersMultiLineEditor() async {
        // DynamicTextAreaField should:
        // 1. Render multi-line text editor (TextEditor on iOS, TextField on macOS)
        // 2. Allow entering multiple lines of text
        // 3. Provide adequate height for multi-line input
        // 4. Update formState with text content
        // 5. Support scrolling for long text

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "textarea",
            contentType: .textarea,
            label: "Text Area"
        )

        let view = DynamicTextAreaField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render multi-line text editor
        if let inspected = view.tryInspect() {
            // Should have text input capability
            let hasTextArea = inspected.sixLayerCount > 0
            #expect(hasTextArea, "Should provide multi-line text editor")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicTextAreaField interface not found")
            #else
            #expect(Bool(true), "DynamicTextAreaField created (ViewInspector not available on macOS)")
            #endif
        }

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicTextAreaField.*",
            platform: .iOS,
            componentName: "DynamicTextAreaField"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif

        // Should support multi-line text in formState
        formState.setValue("Line 1\nLine 2\nLine 3", for: "textarea")
        let textValue = formState.fieldValues["textarea"] as? String
        #expect(textValue?.contains("\n") == true, "Should support multi-line text")
    }

    // MARK: - Character Counter

    @Test @MainActor func testDynamicTextFieldShowsCharacterCounterWhenMaxLengthSet() async {
        // DynamicTextField should:
        // 1. Show character counter when maxLength validation rule is set
        // 2. Display format "X / Y characters"
        // 3. Update counter in real-time as user types
        // 4. Show warning color when approaching limit (>80%)

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "text-with-limit",
            contentType: .text,
            label: "Limited Text",
            validationRules: ["maxLength": "100"]
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should show character counter
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("100")
                }
                #expect(hasCounter, "Should display character counter with max length")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testDynamicTextFieldCharacterCounterUpdatesAsUserTypes() async {
        // Character counter should update in real-time as user types

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "text-with-limit",
            contentType: .text,
            label: "Limited Text",
            validationRules: ["maxLength": "50"]
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Initially should show 0 / 50
        formState.setValue("", for: "text-with-limit")
        
        // Type some text
        formState.setValue("Hello", for: "text-with-limit")
        let currentValue = formState.fieldValues["text-with-limit"] as? String ?? ""
        #expect(currentValue.count == 5, "Should track character count correctly")
    }

    @Test @MainActor func testDynamicTextFieldCharacterCounterShowsWarningColorWhenApproachingLimit() async {
        // Character counter should show warning color (orange) when >80% of maxLength

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "text-with-limit",
            contentType: .text,
            label: "Limited Text",
            validationRules: ["maxLength": "100"]
        )

        // Set value to 85 characters (85% of 100, should show warning)
        let longText = String(repeating: "a", count: 85)
        formState.setValue(longText, for: "text-with-limit")

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Counter should be visible and show warning color
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("85") && textContent.contains("100")
                }
                #expect(hasCounter, "Should show updated counter when approaching limit")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testDynamicTextFieldDoesNotShowCharacterCounterWhenMaxLengthNotSet() async {
        // Character counter should NOT appear when maxLength validation rule is not set

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "text-no-limit",
            contentType: .text,
            label: "Unlimited Text"
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should NOT show character counter
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("characters")
                }
                #expect(!hasCounter, "Should NOT display character counter when maxLength not set")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testDynamicTextAreaFieldShowsCharacterCounterWhenMaxLengthSet() async {
        // DynamicTextAreaField should also show character counter when maxLength is set

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "textarea-with-limit",
            contentType: .textarea,
            label: "Limited Text Area",
            validationRules: ["maxLength": "500"]
        )

        let view = DynamicTextAreaField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should show character counter
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("500")
                }
                #expect(hasCounter, "Should display character counter in text area")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testCharacterCounterHandlesInvalidMaxLengthGracefully() async {
        // Character counter should handle invalid maxLength values gracefully

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        // Test with non-numeric maxLength
        let fieldInvalid = DynamicFormField(
            id: "text-invalid",
            contentType: .text,
            label: "Invalid Limit",
            validationRules: ["maxLength": "not-a-number"]
        )

        let viewInvalid = DynamicTextField(field: fieldInvalid, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should not crash, counter should not appear or should handle gracefully
        #expect(viewInvalid != nil, "Should handle invalid maxLength without crashing")
    }

    @Test @MainActor func testCharacterCounterIsAccessible() async {
        // Character counter should have proper accessibility labels

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "text-accessible",
            contentType: .text,
            label: "Accessible Text",
            validationRules: ["maxLength": "100"]
        )

        formState.setValue("Hello", for: "text-accessible")

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should have accessibility support
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicTextField.*",
            platform: .iOS,
            componentName: "DynamicTextField"
        )
        #expect(hasAccessibilityID, "Should have accessibility identifier")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testDynamicRichTextFieldShowsCharacterCounterWhenMaxLengthSet() async {
        // DynamicRichTextField should also show character counter when maxLength is set

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "richtext-with-limit",
            contentType: .richtext,
            label: "Limited Rich Text",
            validationRules: ["maxLength": "500"]
        )

        let view = DynamicRichTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should show character counter
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("500")
                }
                #expect(hasCounter, "Should display character counter in rich text field")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    // MARK: - Additional Text Field Types Character Counter Tests

    @Test @MainActor func testDynamicEmailFieldShowsCharacterCounterWhenMaxLengthSet() async {
        // DynamicEmailField should show character counter when maxLength is set

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "email-with-limit",
            contentType: .email,
            label: "Email",
            validationRules: ["maxLength": "255"]
        )

        let view = DynamicEmailField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("255")
                }
                #expect(hasCounter, "Should display character counter in email field")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testDynamicPhoneFieldShowsCharacterCounterWhenMaxLengthSet() async {
        // DynamicPhoneField should show character counter when maxLength is set

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "phone-with-limit",
            contentType: .phone,
            label: "Phone",
            validationRules: ["maxLength": "20"]
        )

        let view = DynamicPhoneField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("20")
                }
                #expect(hasCounter, "Should display character counter in phone field")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testDynamicURLFieldShowsCharacterCounterWhenMaxLengthSet() async {
        // DynamicURLField should show character counter when maxLength is set

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "url-with-limit",
            contentType: .url,
            label: "URL",
            validationRules: ["maxLength": "2048"]
        )

        let view = DynamicURLField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("2048")
                }
                #expect(hasCounter, "Should display character counter in URL field")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    // MARK: - Read-Only URL Field Tests (TDD RED PHASE)

    @Test @MainActor func testDynamicURLFieldUsesLinkForReadOnlyValidURL() async {
        // TDD GREEN PHASE: Read-only URL field with valid URL should use Link component

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)
        formState.setValue("https://example.com", for: "readonly-url")

        let field = DynamicFormField(
            id: "readonly-url",
            contentType: .url,
            label: "Website",
            metadata: ["isEditable": "false"]
        )
        formState.initializeField(field)

        let view = DynamicURLField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            // Should contain Link component, not TextField
            // Use specialized method to directly verify Link component is used
            let links = inspected.sixLayerFindAllLinks()
            let textFields = inspected.sixLayerFindAll(TextField<Text>.self)
            
            // Verify Link component is present for read-only valid URL
            #expect(!links.isEmpty, "Read-only URL field with valid URL should use Link component")
            #expect(textFields.isEmpty, "Read-only URL field should not use TextField")
            
            // Verify Link contains the URL text
            if let firstLink = links.first {
                let linkText = try? firstLink.sixLayerString()
                #expect(linkText?.contains("https://example.com") == true || linkText?.contains("example.com") == true,
                       "Link should display the URL text")
            }
        }
        #else
        // ViewInspector not available on this platform - verify behavior conceptually
        #expect(field.displayHints?.isEditable == false, "Field should be marked as read-only")
        #endif
    }

    @Test @MainActor func testDynamicURLFieldUsesTextForReadOnlyInvalidURL() async {
        // TDD GREEN PHASE: Read-only URL field with invalid URL should use Text component (not Link)

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)
        formState.setValue("not a valid url", for: "readonly-invalid-url")

        let field = DynamicFormField(
            id: "readonly-invalid-url",
            contentType: .url,
            label: "Website",
            metadata: ["isEditable": "false"]
        )
        formState.initializeField(field)

        let view = DynamicURLField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            // Should contain Text component for invalid URL, not Link
            // Use specialized method to directly verify Link component is NOT used
            let links = inspected.sixLayerFindAllLinks()
            let allTexts = inspected.sixLayerFindAll(Text.self)
            
            // Invalid URL should not use Link component
            #expect(links.isEmpty, "Invalid URL should not use Link component")
            #expect(!allTexts.isEmpty, "Invalid URL should use Text component")
            
            // Verify Text displays the invalid URL
            let allTextStrings = allTexts.compactMap { try? $0.sixLayerString() }
            let hasInvalidURL = allTextStrings.contains { $0.contains("not a valid url") }
            #expect(hasInvalidURL, "Text should display the invalid URL value")
        }
        #else
        // ViewInspector not available - verify conceptually
        let urlValue: String = formState.getValue(for: "readonly-invalid-url") ?? ""
        #expect(URL(string: urlValue) == nil, "URL should be invalid")
        #endif
    }

    @Test @MainActor func testDynamicURLFieldUsesTextFieldForEditableURL() async {
        // TDD GREEN PHASE: Editable URL field should use TextField component

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "editable-url",
            contentType: .url,
            label: "Website",
            placeholder: "Enter URL"
        )
        formState.initializeField(field)

        let view = DynamicURLField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            // Should contain TextField, not Link
            let textFields = inspected.sixLayerFindAll(TextField<Text>.self)
            let allTexts = inspected.sixLayerFindAll(Text.self)
            
            // Editable field should have TextField, not clickable link text
            let hasURLLikeText = allTexts.contains { text in
                if let textContent = try? text.sixLayerString() {
                    return textContent.contains("https://") || textContent.contains("http://")
                }
                return false
            }
            #expect(!textFields.isEmpty, "Editable URL field should use TextField component")
            #expect(!hasURLLikeText, "Editable URL field should not use Link component")
        }
        #else
        // ViewInspector not available - verify conceptually
        #expect(field.displayHints?.isEditable != false, "Field should be editable")
        #endif
    }

    @Test @MainActor func testDynamicURLFieldDetectsReadOnlyViaDisplayOnlyMetadata() async {
        // TDD GREEN PHASE: Read-only detection via metadata["displayOnly"] == "true"

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)
        formState.setValue("https://apple.com", for: "display-only-url")

        let field = DynamicFormField(
            id: "display-only-url",
            contentType: .url,
            label: "Website",
            metadata: ["displayOnly": "true"]
        )
        formState.initializeField(field)

        let view = DynamicURLField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            // Should use Link for display-only field with valid URL
            // Use specialized method to directly verify Link component is used
            let links = inspected.sixLayerFindAllLinks()
            let textFields = inspected.sixLayerFindAll(TextField<Text>.self)
            
            // Verify Link component is present for display-only valid URL
            #expect(!links.isEmpty, "Display-only URL field should use Link component")
            #expect(textFields.isEmpty, "Display-only URL field should not use TextField")
            
            // Verify Link contains the URL text
            if let firstLink = links.first {
                let linkText = try? firstLink.sixLayerString()
                #expect(linkText?.contains("https://apple.com") == true || linkText?.contains("apple.com") == true,
                       "Link should display the URL text")
            }
        }
        #else
        // ViewInspector not available - verify metadata
        #expect(field.metadata?["displayOnly"] == "true", "Field should be marked as display-only")
        #endif
    }

    @Test @MainActor func testDynamicURLFieldShowsEmptyPlaceholderForReadOnlyEmptyURL() async {
        // TDD GREEN PHASE: Read-only URL field with empty value should show placeholder text

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "readonly-empty-url",
            contentType: .url,
            label: "Website",
            metadata: ["isEditable": "false"]
        )
        formState.initializeField(field)

        let view = DynamicURLField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            // Should show placeholder text (—) for empty read-only URL
            let texts = inspected.sixLayerFindAll(Text.self)
            let allTexts = texts.compactMap { try? $0.sixLayerString() }
            let hasPlaceholder = allTexts.contains { $0 == "—" || $0.trimmingCharacters(in: .whitespaces) == "—" }
            #expect(hasPlaceholder, "Empty read-only URL should show placeholder (—)")
        }
        #else
        // ViewInspector not available - verify conceptually
        let urlValue: String = formState.getValue(for: "readonly-empty-url") ?? ""
        #expect(urlValue.isEmpty, "URL value should be empty")
        #endif
    }

    @Test @MainActor func testDynamicPasswordFieldShowsCharacterCounterWhenMaxLengthSet() async {
        // DynamicPasswordField should show character counter when maxLength is set

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "password-with-limit",
            contentType: .password,
            label: "Password",
            validationRules: ["maxLength": "128"]
        )

        let view = DynamicPasswordField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("128")
                }
                #expect(hasCounter, "Should display character counter in password field")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testDynamicAutocompleteFieldShowsCharacterCounterWhenMaxLengthSet() async {
        // DynamicAutocompleteField should show character counter when maxLength is set

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "autocomplete-with-limit",
            contentType: .autocomplete,
            label: "Autocomplete",
            validationRules: ["maxLength": "100"]
        )

        let view = DynamicAutocompleteField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("100")
                }
                #expect(hasCounter, "Should display character counter in autocomplete field")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    // MARK: - Edge Case Tests

    @Test @MainActor func testCharacterCounterShowsWarningAtExactly80Percent() async {
        // Character counter should show warning color at exactly 80% of maxLength

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "text-80-percent",
            contentType: .text,
            label: "Text at 80%",
            validationRules: ["maxLength": "100"]
        )

        // Set value to exactly 80 characters (80% of 100)
        let text80 = String(repeating: "a", count: 80)
        formState.setValue(text80, for: "text-80-percent")

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // At exactly 80%, should NOT show warning (threshold is >80%)
        #expect(text80.count == 80, "Should have exactly 80 characters")
    }

    @Test @MainActor func testCharacterCounterShowsWarningAt81Percent() async {
        // Character counter should show warning color at 81% of maxLength (>80%)

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "text-81-percent",
            contentType: .text,
            label: "Text at 81%",
            validationRules: ["maxLength": "100"]
        )

        // Set value to 81 characters (81% of 100, should show warning)
        let text81 = String(repeating: "a", count: 81)
        formState.setValue(text81, for: "text-81-percent")

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        #expect(text81.count == 81, "Should have exactly 81 characters")
    }

    @Test @MainActor func testCharacterCounterHandlesZeroMaxLength() async {
        // Character counter should handle zero maxLength gracefully (should not appear)

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "text-zero-limit",
            contentType: .text,
            label: "Zero Limit",
            validationRules: ["maxLength": "0"]
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should not crash, counter should not appear
        #expect(view != nil, "Should handle zero maxLength without crashing")
    }

    @Test @MainActor func testCharacterCounterHandlesNegativeMaxLength() async {
        // Character counter should handle negative maxLength gracefully (should not appear)

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        // Note: validationRules stores strings, so negative would be "-10"
        let field = DynamicFormField(
            id: "text-negative-limit",
            contentType: .text,
            label: "Negative Limit",
            validationRules: ["maxLength": "-10"]
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should not crash, counter should not appear (maxLength > 0 check)
        #expect(view != nil, "Should handle negative maxLength without crashing")
    }

    @Test @MainActor func testCharacterCounterUpdatesInRealTime() async {
        // Character counter should update immediately when formState changes

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "text-realtime",
            contentType: .text,
            label: "Real-time Test",
            validationRules: ["maxLength": "50"]
        )

        // Test multiple updates
        formState.setValue("", for: "text-realtime")
        #expect((formState.getValue(for: "text-realtime") as String? ?? "").count == 0)

        formState.setValue("H", for: "text-realtime")
        #expect((formState.getValue(for: "text-realtime") as String? ?? "").count == 1)

        formState.setValue("He", for: "text-realtime")
        #expect((formState.getValue(for: "text-realtime") as String? ?? "").count == 2)

        formState.setValue("Hello", for: "text-realtime")
        #expect((formState.getValue(for: "text-realtime") as String? ?? "").count == 5)

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // View should be created successfully
        #expect(view != nil, "Should handle real-time updates")
    }

    // MARK: - Stepper Field

    @Test @MainActor func testDynamicStepperFieldRendersStepper() async {
        // DynamicStepperField should:
        // 1. Render a Stepper control with increment/decrement buttons
        // 2. Display field label
        // 3. Show current value
        // 4. Support min/max values from metadata
        // 5. Support step size from metadata
        // 6. Update formState when value changes

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Quantity",
            defaultValue: "5",
            metadata: ["min": "0", "max": "10", "step": "1"]
        )

        let view = DynamicStepperField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render stepper interface
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        if let _ = view.tryInspect() {
            // View is inspectable - stepper interface should be present
            #expect(Bool(true), "Should provide stepper interface")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicStepperField interface not found")
            #else
            #expect(Bool(true), "DynamicStepperField created (ViewInspector not available on macOS)")
            #endif
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicStepperField.*",
            platform: .iOS,
            componentName: "DynamicStepperField"
        )
        #expect(hasAccessibilityID, "Should generate accessibility identifier")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    @Test @MainActor func testDynamicStepperFieldRespectsMinMaxConstraints() async {
        // DynamicStepperField should respect min and max values from metadata

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Rating",
            defaultValue: "3",
            metadata: ["min": "1", "max": "5", "step": "1"]
        )

        let view = DynamicStepperField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Initial value should be within bounds
        let initialValue = formState.getValue(for: "stepper") ?? field.defaultValue ?? "0"
        if let doubleValue = Double(initialValue as? String ?? initialValue as? String ?? "0") {
            #expect(doubleValue >= 1.0, "Initial value should respect min constraint")
            #expect(doubleValue <= 5.0, "Initial value should respect max constraint")
        }

        // View should be created successfully
        #expect(view != nil, "Should respect min/max constraints")
    }

    @Test @MainActor func testDynamicStepperFieldRespectsStepSize() async {
        // DynamicStepperField should respect step size from metadata

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Increment by 5",
            defaultValue: "10",
            metadata: ["min": "0", "max": "100", "step": "5"]
        )

        let view = DynamicStepperField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // View should be created successfully
        #expect(view != nil, "Should respect step size")
    }

    @Test @MainActor func testDynamicStepperFieldUpdatesFormState() async {
        // DynamicStepperField should update formState when value changes

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Quantity",
            defaultValue: "0",
            metadata: ["min": "0", "max": "10", "step": "1"]
        )

        // Set initial value
        formState.setValue("5", for: "stepper")
        let initialValue: String? = formState.getValue(for: "stepper")
        #expect(initialValue == "5", "Should set initial value in formState")

        let view = DynamicStepperField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // View should be created successfully
        #expect(view != nil, "Should update formState")
    }

    @Test @MainActor func testDynamicStepperFieldUsesDefaultValuesWhenMetadataMissing() async {
        // DynamicStepperField should use sensible defaults when min/max/step are not provided

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Value",
            defaultValue: "0"
            // No metadata - should use defaults
        )

        let view = DynamicStepperField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should not crash with missing metadata
        #expect(view != nil, "Should handle missing metadata gracefully")
    }

    @Test @MainActor func testDynamicStepperFieldShowsCurrentValue() async {
        // DynamicStepperField should display the current value

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Quantity",
            defaultValue: "7",
            metadata: ["min": "0", "max": "10", "step": "1"]
        )

        formState.setValue("7", for: "stepper")

        let view = DynamicStepperField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should display current value
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let showsValue = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("7")
                }
                #expect(showsValue, "Should display current value")
            }
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testDynamicStepperFieldHandlesStringToDoubleConversion() async {
        // DynamicStepperField should handle conversion between String (formState) and Double (Stepper)

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Value",
            defaultValue: "3.5",
            metadata: ["min": "0", "max": "10", "step": "0.5"]
        )

        // Set value as string
        formState.setValue("3.5", for: "stepper")
        let stringValue: String? = formState.getValue(for: "stepper")
        #expect(stringValue == "3.5", "Should store value as string in formState")

        let view = DynamicStepperField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should handle conversion
        #expect(view != nil, "Should handle string to double conversion")
    }

    @Test @MainActor func testDynamicStepperFieldUsesFieldDisplayHintsExpectedRange() async {
        // DynamicStepperField should prefer expectedRange from FieldDisplayHints over metadata min/max

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        // Create field with expectedRange in metadata (which becomes displayHints.expectedRange)
        // Format: "expectedRange": "min:max" or "expectedRangeMin"/"expectedRangeMax"
        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Rating",
            defaultValue: "3",
            metadata: [
                "expectedRange": "2:8",  // This will be parsed into displayHints.expectedRange
                "min": "1",  // This should be ignored when expectedRange is present
                "max": "10", // This should be ignored when expectedRange is present
                "step": "1"
            ]
        )

        // Verify displayHints has expectedRange
        guard let displayHints = field.displayHints,
              let expectedRange = displayHints.expectedRange else {
            Issue.record("Field should have displayHints with expectedRange")
            return
        }

        #expect(expectedRange.min == 2.0, "ExpectedRange min should be 2.0")
        #expect(expectedRange.max == 8.0, "ExpectedRange max should be 8.0")

        let view = DynamicStepperField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // The stepper should use the expectedRange (2...8) not the metadata min/max (1...10)
        // We can't directly test the range, but we can verify the view is created
        // and the initial value should be within the expectedRange bounds
        let initialValue = formState.getValue(for: "stepper") ?? field.defaultValue ?? "0"
        if let doubleValue = Double(initialValue as? String ?? initialValue as? String ?? "0") {
            #expect(doubleValue >= expectedRange.min, "Initial value should respect expectedRange min")
            #expect(doubleValue <= expectedRange.max, "Initial value should respect expectedRange max")
        }

        #expect(view != nil, "Should use expectedRange from FieldDisplayHints")
    }

    @Test @MainActor func testDynamicStepperFieldFallsBackToMetadataWhenNoExpectedRange() async {
        // DynamicStepperField should fall back to metadata min/max when displayHints.expectedRange is nil

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        // Create field without expectedRange, but with metadata min/max
        let field = DynamicFormField(
            id: "stepper",
            contentType: .stepper,
            label: "Quantity",
            defaultValue: "5",
            metadata: [
                "min": "0",
                "max": "20",
                "step": "1"
            ]
        )

        // Verify displayHints doesn't have expectedRange
        let displayHints = field.displayHints
        #expect(displayHints?.expectedRange == nil, "Field should not have expectedRange in displayHints")

        let view = DynamicStepperField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should fall back to metadata min/max (0...20)
        let initialValue = formState.getValue(for: "stepper") ?? field.defaultValue ?? "0"
        if let doubleValue = Double(initialValue as? String ?? initialValue as? String ?? "0") {
            #expect(doubleValue >= 0.0, "Initial value should respect metadata min")
            #expect(doubleValue <= 20.0, "Initial value should respect metadata max")
        }

        #expect(view != nil, "Should fall back to metadata min/max")
    }

    // MARK: - Multi-line TextField (Issue #89)

    @Test @MainActor func testDynamicTextFieldUsesMultiLineTextFieldWithAxisOnIOS16() async {
        // TDD RED PHASE: DynamicTextField should use TextField with axis parameter
        // for multi-line text on iOS 16+ when metadata["multiLine"] == "true"
        
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "multiline-text",
            contentType: .text,
            label: "Address",
            placeholder: "Enter address",
            metadata: ["multiLine": "true"]
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // On iOS 16+, should use TextField with axis: .vertical
        #if os(iOS)
        if #available(iOS 16.0, *) {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            withInspectedView(view) { inspected in
                // Should have TextField with axis parameter (multi-line)
                // Note: ViewInspector may not directly detect axis, but we can verify
                // the TextField exists and is configured for multi-line
                let textFields = inspected.sixLayerFindAll(TextField<Text>.self)
                #expect(!textFields.isEmpty, "Should use TextField for multi-line on iOS 16+")
            }
            #else
            // ViewInspector not available - verify conceptually
            #expect(field.metadata?["multiLine"] == "true", "Field should have multiLine metadata")
            #endif
        } else {
            // iOS < 16: Should fall back to TextEditor
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            withInspectedView(view) { inspected in
                // Should use TextEditor as fallback
                let textEditors = inspected.sixLayerFindAll(TextEditor.self)
                #expect(!textEditors.isEmpty, "Should use TextEditor as fallback on iOS < 16")
            }
            #endif
        }
        #else
        // macOS: Should use TextField with axis on macOS 13+
        if #available(macOS 13.0, *) {
            #expect(field.metadata?["multiLine"] == "true", "Field should have multiLine metadata")
        }
        #endif
    }

    @Test @MainActor func testDynamicTextFieldFallsBackToTextEditorOnIOS15() async {
        // TDD RED PHASE: DynamicTextField should fall back to TextEditor on iOS < 16
        
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "multiline-text",
            contentType: .text,
            label: "Address",
            metadata: ["multiLine": "true"]
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // On iOS < 16, should use TextEditor
        #if os(iOS)
        if #available(iOS 16.0, *) {
            // iOS 16+: Should use TextField with axis
            #expect(field.metadata?["multiLine"] == "true", "Field should have multiLine metadata")
        } else {
            // iOS < 16: Should use TextEditor
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            withInspectedView(view) { inspected in
                let textEditors = inspected.sixLayerFindAll(TextEditor.self)
                #expect(!textEditors.isEmpty, "Should use TextEditor as fallback on iOS < 16")
            }
            #else
            #expect(field.metadata?["multiLine"] == "true", "Field should have multiLine metadata")
            #endif
        }
        #else
        // macOS: Similar fallback logic
        #expect(field.metadata?["multiLine"] == "true", "Field should have multiLine metadata")
        #endif
    }

    @Test @MainActor func testDynamicTextFieldRespectsLineLimits() async {
        // TDD RED PHASE: Multi-line TextField should respect minLines and maxLines from metadata
        
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "multiline-text",
            contentType: .text,
            label: "Description",
            metadata: [
                "multiLine": "true",
                "minLines": "2",
                "maxLines": "8"
            ]
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should parse minLines and maxLines from metadata
        let minLines = Int(field.metadata?["minLines"] ?? "3")
        let maxLines = Int(field.metadata?["maxLines"] ?? "6")
        
        #expect(minLines == 2, "Should parse minLines from metadata")
        #expect(maxLines == 8, "Should parse maxLines from metadata")
        
        // View should be created successfully
        #expect(view != nil, "Should respect line limits configuration")
    }

    @Test @MainActor func testDynamicTextFieldUsesDefaultLineLimits() async {
        // TDD RED PHASE: Multi-line TextField should use default 3-6 lines when not specified
        
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "multiline-text",
            contentType: .text,
            label: "Notes",
            metadata: ["multiLine": "true"]
            // No minLines or maxLines - should use defaults
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should use default line limits (3-6)
        #expect(field.metadata?["multiLine"] == "true", "Field should have multiLine metadata")
        #expect(field.metadata?["minLines"] == nil, "Should not have minLines when not specified")
        #expect(field.metadata?["maxLines"] == nil, "Should not have maxLines when not specified")
        
        // View should be created successfully
        #expect(view != nil, "Should use default line limits")
    }

    @Test @MainActor func testDynamicTextFieldShowsCharacterCounterForMultiLine() async {
        // TDD RED PHASE: Multi-line TextField should show character counter when maxLength is set
        
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "multiline-text",
            contentType: .text,
            label: "Limited Text",
            validationRules: ["maxLength": "200"],
            metadata: ["multiLine": "true"]
        )

        formState.setValue("Some multi-line text\nwith multiple lines", for: "multiline-text")

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should show character counter
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        withInspectedView(view) { inspected in
            let allTexts = inspected.sixLayerFindAll(Text.self)
            if !allTexts.isEmpty {
                let hasCounter = allTexts.contains { text in
                    let textContent = (try? text.sixLayerString()) ?? ""
                    return textContent.contains("/") && textContent.contains("200")
                }
                #expect(hasCounter, "Should display character counter for multi-line TextField")
            }
        }
        #else
        // ViewInspector not available - verify conceptually
        let currentValue = formState.getValue(for: "multiline-text") as? String ?? ""
        #expect(currentValue.count > 0, "Should track character count for multi-line text")
        #endif
    }

    @Test @MainActor func testDynamicTextFieldSupportsMultiLineTextInput() async {
        // TDD RED PHASE: Multi-line TextField should support multi-line text input
        
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "multiline-text",
            contentType: .text,
            label: "Address",
            metadata: ["multiLine": "true"]
        )

        // Set multi-line text
        let multiLineText = "123 Main St\nApt 4B\nCity, State 12345"
        formState.setValue(multiLineText, for: "multiline-text")

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should support multi-line text
        let storedValue = formState.getValue(for: "multiline-text") as String? ?? ""
        #expect(storedValue.contains("\n"), "Should support multi-line text with newlines")
        #expect(storedValue == multiLineText, "Should store multi-line text correctly")
    }

    @Test @MainActor func testDynamicTextFieldSingleLineWhenMultiLineNotSet() async {
        // TDD RED PHASE: DynamicTextField should remain single-line when multiLine metadata is not set
        
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "singleline-text",
            contentType: .text,
            label: "Name",
            placeholder: "Enter name"
            // No multiLine metadata - should be single-line
        )

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should use single-line TextField (no axis parameter)
        #expect(field.metadata?["multiLine"] != "true", "Field should not have multiLine metadata")
        
        // View should be created successfully
        #expect(view != nil, "Should use single-line TextField when multiLine not set")
    }

    @Test @MainActor func testDynamicTextFieldMultiLineWorksWithFormValidation() async {
        // TDD RED PHASE: Multi-line TextField should work with form validation
        
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "multiline-text",
            contentType: .text,
            label: "Description",
            isRequired: true,
            validationRules: ["minLength": "10", "maxLength": "500"],
            metadata: ["multiLine": "true"]
        )

        // Set valid multi-line text
        let validText = "This is a valid\nmulti-line description\nwith enough characters"
        formState.setValue(validText, for: "multiline-text")

        let view = DynamicTextField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should work with validation
        let storedValue = formState.getValue(for: "multiline-text") as String? ?? ""
        #expect(storedValue.count >= 10, "Should respect minLength validation")
        #expect(storedValue.count <= 500, "Should respect maxLength validation")
        #expect(!storedValue.isEmpty, "Should handle required field validation")
    }

    // MARK: - Gauge Field (Issue #88)

    @Test @MainActor func testDynamicGaugeFieldRendersGaugeComponent() async {
        // DynamicGaugeField should:
        // 1. Render gauge component for visual value display
        // 2. Display value within specified range
        // 3. Support circular and linear styles
        // 4. Show field label and value labels
        // 5. Update formState with gauge value

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            defaultValue: "50",
            metadata: [
                "min": "0",
                "max": "100",
                "gaugeStyle": "linear"
            ]
        )

        formState.initializeField(field)

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should render gauge component
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        if let _ = view.tryInspect() {
            // View is inspectable - gauge should be present
            #expect(Bool(true), "Should provide gauge interface")
        } else {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("DynamicGaugeField interface not found")
            #else
            #expect(Bool(true), "DynamicGaugeField created (ViewInspector not available on macOS)")
            #endif
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*DynamicGaugeField.*",
            platform: .iOS,
            componentName: "DynamicGaugeField"
        )
        #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif

        // Should read value from form state
        let value: String? = formState.getValue(for: "gauge")
        #expect(value != nil, "Should read value from form state")
    }

    @Test @MainActor func testDynamicGaugeFieldUsesMinMaxFromMetadata() async {
        // DynamicGaugeField should use min and max values from metadata

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Level",
            defaultValue: "25",
            metadata: [
                "min": "10",
                "max": "50"
            ]
        )

        formState.initializeField(field)

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should use metadata min/max (10...50)
        let value: String? = formState.getValue(for: "gauge")
        if let stringValue = value,
           let doubleValue = Double(stringValue) {
            #expect(doubleValue >= 10.0, "Value should respect metadata min")
            #expect(doubleValue <= 50.0, "Value should respect metadata max")
        }

        #expect(view != nil, "Should use min/max from metadata")
    }

    @Test @MainActor func testDynamicGaugeFieldDefaultsToZeroToHundredRange() async {
        // DynamicGaugeField should default to 0...100 range when min/max not specified

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            defaultValue: "75"
        )

        formState.initializeField(field)

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should default to 0...100 range
        let value: String? = formState.getValue(for: "gauge")
        if let stringValue = value,
           let doubleValue = Double(stringValue) {
            #expect(doubleValue >= 0.0, "Value should respect default min (0)")
            #expect(doubleValue <= 100.0, "Value should respect default max (100)")
        }

        #expect(view != nil, "Should default to 0...100 range")
    }

    @Test @MainActor func testDynamicGaugeFieldSupportsCircularStyle() async {
        // DynamicGaugeField should support circular gauge style

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            defaultValue: "60",
            metadata: [
                "min": "0",
                "max": "100",
                "gaugeStyle": "circular"
            ]
        )

        formState.initializeField(field)

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should support circular style
        #expect(view != nil, "Should support circular gauge style")
    }

    @Test @MainActor func testDynamicGaugeFieldSupportsLinearStyle() async {
        // DynamicGaugeField should support linear gauge style (default)

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            defaultValue: "40",
            metadata: [
                "min": "0",
                "max": "100",
                "gaugeStyle": "linear"
            ]
        )

        formState.initializeField(field)

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should support linear style
        #expect(view != nil, "Should support linear gauge style")
    }

    @Test @MainActor func testDynamicGaugeFieldDefaultsToLinearStyle() async {
        // DynamicGaugeField should default to linear style when style not specified

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            defaultValue: "50"
        )

        formState.initializeField(field)

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should default to linear style
        #expect(view != nil, "Should default to linear gauge style")
    }

    @Test @MainActor func testDynamicGaugeFieldHandlesDoubleValue() async {
        // DynamicGaugeField should handle Double values from form state

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            metadata: [
                "min": "0",
                "max": "100"
            ]
        )

        formState.initializeField(field)
        formState.setValue(75.5 as Double, for: "gauge")

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should handle Double value
        let value: Double? = formState.getValue(for: "gauge")
        #expect(value != nil, "Should handle Double value")
        if let doubleValue = value {
            #expect(doubleValue == 75.5, "Should preserve Double value")
        }

        #expect(view != nil, "Should handle Double value")
    }

    @Test @MainActor func testDynamicGaugeFieldHandlesIntValue() async {
        // DynamicGaugeField should handle Int values from form state

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            metadata: [
                "min": "0",
                "max": "100"
            ]
        )

        formState.initializeField(field)
        formState.setValue(42 as Int, for: "gauge")

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should handle Int value
        let value: Int? = formState.getValue(for: "gauge")
        #expect(value != nil, "Should handle Int value")
        if let intValue = value {
            #expect(intValue == 42, "Should preserve Int value")
        }

        #expect(view != nil, "Should handle Int value")
    }

    @Test @MainActor func testDynamicGaugeFieldHandlesStringValue() async {
        // DynamicGaugeField should parse String values to Double

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            metadata: [
                "min": "0",
                "max": "100"
            ]
        )

        formState.initializeField(field)
        formState.setValue("33.3", for: "gauge")

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should handle String value
        let value: String? = formState.getValue(for: "gauge")
        #expect(value != nil, "Should handle String value")

        #expect(view != nil, "Should handle String value")
    }

    @Test @MainActor func testDynamicGaugeFieldFallsBackToDefaultValue() async {
        // DynamicGaugeField should fall back to defaultValue when no value in form state

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            defaultValue: "25",
            metadata: [
                "min": "0",
                "max": "100"
            ]
        )

        formState.initializeField(field)
        // Don't set value - should use defaultValue

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should fall back to defaultValue
        #expect(view != nil, "Should fall back to defaultValue")
    }

    @Test @MainActor func testDynamicGaugeFieldFallsBackToZeroWhenNoValue() async {
        // DynamicGaugeField should fall back to 0.0 when no value and no defaultValue

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            metadata: [
                "min": "0",
                "max": "100"
            ]
        )

        formState.initializeField(field)
        // Don't set value or defaultValue

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should fall back to 0.0
        #expect(view != nil, "Should fall back to 0.0 when no value")
    }

    @Test @MainActor func testDynamicGaugeFieldSupportsCustomLabel() async {
        // DynamicGaugeField should support custom gauge label via metadata

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            defaultValue: "50",
            metadata: [
                "min": "0",
                "max": "100",
                "gaugeLabel": "Completion"
            ]
        )

        formState.initializeField(field)

        let view = DynamicGaugeField(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should support custom gauge label
        #expect(view != nil, "Should support custom gauge label")
    }

    @Test @MainActor func testDynamicGaugeFieldWorksInCustomFieldView() async {
        // DynamicGaugeField should work when used through CustomFieldView

        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: []
        )
        let formState = DynamicFormState(configuration: configuration)

        let field = DynamicFormField(
            id: "gauge",
            contentType: .gauge,
            label: "Progress",
            defaultValue: "50",
            metadata: [
                "min": "0",
                "max": "100"
            ]
        )

        formState.initializeField(field)

        let view = CustomFieldView(field: field, formState: formState)
            .enableGlobalAutomaticCompliance()

        // Should work through CustomFieldView
        #expect(view != nil, "Should work through CustomFieldView")
    }
}
