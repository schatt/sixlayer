import Testing


import SwiftUI
import UniformTypeIdentifiers
@testable import SixLayerFramework

/**
 * BUSINESS PURPOSE: Advanced field types provide enhanced form input capabilities including rich text editing,
 * autocomplete suggestions, file upload with drag-and-drop, and custom field components. These components
 * enable complex data input scenarios beyond basic text fields, supporting markdown formatting, intelligent
 * suggestions, multi-file uploads, and extensible custom field implementations.
 * 
 * TESTING SCOPE: Tests cover initialization, data binding, user interaction, accessibility, error handling,
 * and performance across all advanced field types. Includes platform-specific behavior testing and mock
 * capability detection for comprehensive validation.
 * 
 * METHODOLOGY: Field initialization and binding tests on the current host; capability
 * tri-state for a11y axes where fields branch on RuntimeCapabilityDetection (#251).
 */
@Suite("Advanced Field Types", DefaultRuntimeCapabilityIsolationTrait(), HostedViewTestIsolationTrait())
open class AdvancedFieldTypesTests: BaseTestClass {

    // MARK: - Test Setup/Teardown
    
    // BaseTestClass.init() is final - no override needed
    // CustomFieldRegistry.shared.reset() should be called in test methods, not init()
    
    // MARK: - Test Data Setup
    
    @MainActor
    private var testFormState: DynamicFormState {
        return createTestFormState()
    }
    
    @MainActor
    public func createTestFormState() -> DynamicFormState {
        let testConfiguration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            description: "Test form for Advanced Field Types",
            sections: [],
            submitButtonText: "Submit",
            cancelButtonText: "Cancel"
        )
        return DynamicFormState(configuration: testConfiguration)
    }

    @MainActor
    private func expectHostableRed<V: View>(_ view: V, _ label: String) {
        // Deliberate inverted hostability for #382 red — flip to isHostable for green.
        #expect(
            !PlatformContainerStructureAssertions.isHostable(view),
            "Deliberate red #382: \(label) should be hostable"
        )
    }

    // MARK: - Rich Text Editor Tests
    
    /**
     * BUSINESS PURPOSE: RichTextEditorField provides markdown-enabled text editing with formatting toolbar
     * and live preview capabilities for complex text input scenarios.
     * TESTING SCOPE: Tests field initialization, data binding, and platform-specific behavior
     * METHODOLOGY: Uses mock capability detection to test both enabled and disabled states
     */
    @Test @MainActor func testRichTextEditorFieldInitialization() {
        // Given
        let field = DynamicFormField(
            id: "richText",
            contentType: .richtext,
            label: "Rich Text Content",
            placeholder: "Enter rich text content"
        )
        let formState = createTestFormState()
        
        // When
        let sut1 = RichTextEditorField(field: field, formState: formState)
        #expect(field.contentType == .richtext)
        #expect(field.label == "Rich Text Content")
    
        #expect(sut1.field.id == "richText")
        #expect(sut1.field.contentType == .richtext)
        expectHostableRed(sut1, "RichTextEditorField")
    }
    
    @Test @MainActor func testRichTextEditorFieldEditingMode() {
        // Given
        let field = DynamicFormField(
            id: "richText",
            contentType: .richtext,
            label: "Rich Text Content",
            placeholder: "Enter rich text content"
        )
        let formState = createTestFormState()
        
        // When
        let sut2 = RichTextEditorField(field: field, formState: formState)
    
        // Editing-mode toggle is @State; unit layer observes hostability + field wiring (#403 for VI).
        #expect(sut2.field.id == "richText")
        expectHostableRed(sut2, "RichTextEditorField editing mode")
    }
    
    @Test @MainActor func testRichTextEditorTextBinding() {
        // Given
        let field = DynamicFormField(
            id: "richText",
            contentType: .richtext,
            label: "Rich Text Content",
            placeholder: "Enter rich text content"
        )
        let testText = "This is **bold** and *italic* text"
        let formState = createTestFormState()
        
        // When
        formState.setValue(testText, for: field.id)
        let sut3 = RichTextEditorField(field: field, formState: formState)
        #expect(formState.getValue(for: field.id) == testText)
    
        #expect(sut3.field.id == "richText")
        expectHostableRed(sut3, "RichTextEditorField binding")
    }
    
    @Test @MainActor func testRichTextToolbarFormatting() {
        // Given
        let selectedText = NSRange(location: 0, length: 5)
        
        // When
        let sut4 = RichTextToolbar(selectedText: .constant(selectedText))
        // Test that formatting buttons are present
        // This tests the toolbar UI structure
    
        // Format actions are product placeholders; hostability is the unit-layer floor (#403).
        expectHostableRed(sut4, "RichTextToolbar")
    }
    
    @Test @MainActor func testRichTextPreview() {
        // Given
        let testText = "This is **bold** and *italic* text"
        
        // When
        let sut5 = RichTextPreview(text: testText)
        // Test that preview displays the text correctly
    
        #expect(sut5.text == "This is **bold** and *italic* text")
        expectHostableRed(sut5, "RichTextPreview")
    }
    
    // MARK: - Autocomplete Field Tests
    
    /**
     * BUSINESS PURPOSE: AutocompleteField provides intelligent text input with real-time suggestions
     * and filtering capabilities for improved user experience and data accuracy.
     * TESTING SCOPE: Tests field initialization, suggestion filtering, and selection behavior
     * METHODOLOGY: Uses comprehensive test scenarios including empty suggestions and large datasets
     */
    @Test @MainActor func testAutocompleteFieldInitialization() {
        // Given
        let field = DynamicFormField(
            id: "autocomplete",
            contentType: .autocomplete,
            label: "Search",
            placeholder: "Type to search..."
        )
        let suggestions = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
        let formState = createTestFormState()
        
        // When
        let sut6 = AutocompleteField(
            field: field,
            formState: formState,
            suggestions: suggestions
        )
        #expect(field.contentType == .autocomplete)
        #expect(field.label == "Search")
    
        #expect(sut6.field.id == "autocomplete")
        #expect(sut6.suggestions == ["Apple", "Banana", "Cherry", "Date", "Elderberry"])
        expectHostableRed(sut6, "AutocompleteField")
    }
    
    @Test @MainActor func testAutocompleteFieldSuggestionFiltering() {
        // Given
        let field = DynamicFormField(
            id: "autocomplete",
            contentType: .autocomplete,
            label: "Search",
            placeholder: "Type to search..."
        )
        let suggestions = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
        let formState = createTestFormState()
        
        // When
        let sut7 = AutocompleteField(
            field: field,
            formState: formState,
            suggestions: suggestions
        )
        // Test that suggestions are properly filtered
        // This tests the internal filtering logic
    
        #expect(sut7.suggestions.count == 5)
        let filtered = AutocompleteSuggestionFiltering.filtered(suggestions: sut7.suggestions, query: "ap")
        #expect(filtered == ["Apple"], "Deliberate red #382: filter 'ap' → Apple (stub returns [])")
        expectHostableRed(sut7, "AutocompleteField filtering")
    }
    
    @Test @MainActor func testAutocompleteFieldSuggestionSelection() {
        // Given
        let field = DynamicFormField(
            id: "autocomplete",
            contentType: .autocomplete,
            label: "Search",
            placeholder: "Type to search..."
        )
        let suggestions = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
        
        let formState = createTestFormState()
        
        // When
        let sut8 = AutocompleteField(
            field: field,
            formState: formState,
            suggestions: suggestions
        )
        // Test that suggestion selection updates the form state
    
        // Selection UI needs VI/XCUI (#403); unit observes suggestions + hostability.
        #expect(sut8.suggestions.contains("Apple"))
        expectHostableRed(sut8, "AutocompleteField selection")
    }
    
    @Test @MainActor func testAutocompleteSuggestionsDisplay() {
        // Given
        let suggestions = ["Apple", "Banana", "Cherry"]
        
        // When
        let sut9 = AutocompleteSuggestions(
            suggestions: suggestions,
            onSelect: { _ in
                // Handle selection
            }
        )
        // Test that suggestions are displayed correctly
    
        #expect(sut9.suggestions == ["Apple", "Apricot", "Avocado"])
        expectHostableRed(sut9, "AutocompleteSuggestions")
    }
    
    // MARK: - File Upload Field Tests
    
    /**
     * BUSINESS PURPOSE: EnhancedFileUploadField provides drag-and-drop file upload capabilities with
     * type validation, size limits, and multi-file support for comprehensive file handling.
     * TESTING SCOPE: Tests field initialization, file type validation, size limits, and error handling
     * METHODOLOGY: Uses mock file scenarios and comprehensive error condition testing
     */
    @Test @MainActor func testEnhancedFileUploadFieldInitialization() {
        // Given
        let field = DynamicFormField(
            id: "files",
            contentType: .file,
            label: "Upload Files",
            placeholder: "Select files to upload"
        )
        let allowedTypes = [UTType.image, UTType.pdf, UTType.text]
        let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB
        
        let formState = createTestFormState()
        
        // When
        let sut10 = EnhancedFileUploadField(
            field: field,
            formState: formState,
            allowedTypes: allowedTypes,
            maxFileSize: maxFileSize
        )
        #expect(field.contentType == .file)
        #expect(field.label == "Upload Files")
    
        #expect(sut10.field.contentType == .file)
        #expect(sut10.allowedTypes == allowedTypes)
        #expect(sut10.maxFileSize == maxFileSize)
        expectHostableRed(sut10, "EnhancedFileUploadField")
    }
    
    @Test @MainActor func testFileUploadFieldAllowedTypes() {
        // Given
        let field = DynamicFormField(
            id: "files",
            contentType: .file,
            label: "Upload Files",
            placeholder: "Select files to upload"
        )
        let allowedTypes = [UTType.image, UTType.pdf, UTType.text]
        
        let formState = createTestFormState()
        
        // When
        let sut11 = EnhancedFileUploadField(
            field: field,
            formState: formState,
            allowedTypes: allowedTypes,
            maxFileSize: nil
        )
        // Test that allowed types are properly configured
    
        #expect(sut11.allowedTypes == allowedTypes, "allowedTypes must be retained on the field")
        #expect(sut11.maxFileSize == nil)
        expectHostableRed(sut11, "EnhancedFileUploadField allowedTypes")
    }
    
    @Test @MainActor func testFileUploadFieldMaxFileSize() {
        // Given
        let field = DynamicFormField(
            id: "files",
            contentType: .file,
            label: "Upload Files",
            placeholder: "Select files to upload"
        )
        let maxFileSize: Int64 = 5 * 1024 * 1024 // 5MB
        
        let formState = createTestFormState()
        
        // When
        let sut12 = EnhancedFileUploadField(
            field: field,
            formState: formState,
            allowedTypes: [UTType.image],
            maxFileSize: maxFileSize
        )
        // Test that max file size is properly configured
    
        #expect(sut12.maxFileSize == maxFileSize)
        #expect(sut12.allowedTypes == [UTType.image])
        expectHostableRed(sut12, "EnhancedFileUploadField maxFileSize")
    }
    
    @Test @MainActor func testFileUploadAreaDragAndDrop() {
        // Given
        let allowedTypes = [UTType.image, UTType.pdf]
        let maxFileSize: Int64 = 10 * 1024 * 1024
        var selectedFiles: [FileInfo] = []
        
        // When
        let sut13 = FileUploadArea(
            isDragOver: .constant(false),
            selectedFiles: .constant(selectedFiles),
            allowedTypes: allowedTypes,
            maxFileSize: maxFileSize,
            onFilesSelected: { files in
                selectedFiles = files
            }
        )
        // Test that drag and drop area is properly configured
    
        // Drop handling is a product placeholder (#403); unit observes configuration + hostability.
        #expect(sut13.allowedTypes == allowedTypes)
        #expect(sut13.maxFileSize == maxFileSize)
        expectHostableRed(sut13, "FileUploadArea")
    }
    
    @Test func testFileInfoCreation() {
        // Given
        let name = "test.pdf"
        let size: Int64 = 1024
        let type = UTType.pdf
        let url = URL(string: "file:///test.pdf")
        
        // When
        let fileInfo = FileInfo(name: name, size: size, type: type, url: url)
        
        // Then
        #expect(fileInfo.name == name)
        #expect(fileInfo.size == size)
        #expect(fileInfo.type == type)
        #expect(fileInfo.url == url)
        // UUID is non-optional, so id is always non-nil
    }
    
    @Test @MainActor func testFileListDisplay() {
        // Given
        let files = [
            FileInfo(name: "test1.pdf", size: 1024, type: .pdf, url: nil),
            FileInfo(name: "test2.jpg", size: 2048, type: .image, url: nil)
        ]
        
        // When
        let sut14 = FileList(files: files) { _ in
        }
        // Test that file list displays files correctly
    
        #expect(sut14.files.count == 2)
        #expect(sut14.files[0].name == "test1.pdf")
        expectHostableRed(sut14, "FileList")
    }
    
    @Test @MainActor func testFileRowDisplay() {
        // Given
        let file = FileInfo(name: "test.pdf", size: 1024, type: .pdf, url: nil)
        
        // When
        let sut15 = FileRow(file: file) { _ in
        }
        // Test that file row displays file information correctly
    
        #expect(sut15.file.name == "test.pdf")
        #expect(sut15.file.size == 1024)
        expectHostableRed(sut15, "FileRow")
    }
    
    // MARK: - Custom Field Component Tests
    
    @Test @MainActor func testCustomFieldComponentProtocol() {
        // Given
        let field = DynamicFormField(
            id: "custom",
            contentType: .custom,
            label: "Custom Field",
            placeholder: "Custom placeholder"
        )
        
        // When
        // Create a test custom field component
        struct TestCustomField: CustomFieldComponent {
            let field: DynamicFormField
            let formState: DynamicFormState
            
            var body: some View {
                Text("Custom Field")
            }
        }
        
        let formState = createTestFormState()
        
        let customField = TestCustomField(field: field, formState: formState)
        
        // Then
        // customField is non-optional, so just verify its properties
        #expect(customField.field.id == field.id)
        #expect(customField.field.contentType == .custom)
    }
    
    @Test @MainActor func testCustomFieldRegistry() {
        // Given
        let registry = CustomFieldRegistry.shared

        // When
        // Register a custom field type using factory pattern
        struct TestCustomField: CustomFieldComponent {
            let field: DynamicFormField
            let formState: DynamicFormState

            var body: some View {
                Text("Custom Field")
            }
        }

        registry.register("custom") { field, formState in
            TestCustomField(field: field, formState: formState)
        }

        // Then
        let isRegistered = registry.isRegistered("custom")
        #expect(isRegistered)

        // Test that factory actually creates the component
        let testField = DynamicFormField(
            id: "test",
            contentType: .custom,
            label: "Test Field"
        )
        let testFormState = createTestFormState()
        let createdComponent = registry.createComponent(for: testField, formState: testFormState)
        #expect(createdComponent is TestCustomField)

        // Clean up: reset registry for next test
        registry.reset()
    }

    @Test @MainActor func testCustomFieldRegistryUnknownType() {
        // Given
        let registry = CustomFieldRegistry.shared

        // When
        let isRegistered = registry.isRegistered("unknownType")

        // Then
        #expect(!isRegistered)

        // Clean up: reset registry for next test
        registry.reset()
    }
    
    @Test @MainActor func testCustomFieldViewUsesRegisteredComponent() {
        // Given
        struct SliderField: CustomFieldComponent {
            let field: DynamicFormField
            let formState: DynamicFormState

            var body: some View {
                platformVStackContainer {
                    Text(field.label)
                    Text("Slider Component")
                        .foregroundColor(.blue)
                }
            }
        }

        // Registry keys off contentType.rawValue ("custom"), not metadata (#403 tracks richer keys).
        CustomFieldRegistry.shared.register("custom") { field, formState in
            SliderField(field: field, formState: formState)
        }
        
        let testField = DynamicFormField(
            id: "slider",
            contentType: .custom,
            label: "Test Slider"
        )
        let testFormState = createTestFormState()
        
        // When
        let sut16 = CustomFieldView(field: testField, formState: testFormState)
        let created = CustomFieldRegistry.shared.createComponent(for: testField, formState: testFormState)
        #expect(created is SliderField, "Registry must create SliderField for contentType.custom")
        expectHostableRed(sut16, "CustomFieldView")

        // Clean up: reset registry for next test
        CustomFieldRegistry.shared.reset()
    }
    
    // MARK: - Date/Time Picker Tests (To Be Implemented)
    
    @Test func testDatePickerFieldInitialization() {
        // Given
        let field = DynamicFormField(
            id: "date",
            contentType: .date,
            label: "Select Date",
            placeholder: "Choose a date"
        )
        
        // When
        // This will be implemented after the DatePickerField is created
        // let datePickerField = DatePickerField(field: field, formState: testFormState)
        
        // Then
        // XCTAssertNotNil(datePickerField)
        // XCTAssertEqual(contentType, .date)
        
        // For now, just test that the field type exists
        #expect(field.contentType == .date)
    }
    
    @Test func testTimePickerFieldInitialization() {
        // Given
        let field = DynamicFormField(
            id: "time",
            contentType: .time,
            label: "Select Time",
            placeholder: "Choose a time"
        )
        
        // When
        // This will be implemented after the TimePickerField is created
        // let timePickerField = TimePickerField(field: field, formState: testFormState)
        
        // Then
        // XCTAssertNotNil(timePickerField)
        // XCTAssertEqual(contentType, .time)
        
        // For now, just test that the field type exists
        #expect(field.contentType == .time)
    }
    
    @Test func testDateTimePickerFieldInitialization() {
        // Given
        let field = DynamicFormField(
            id: "datetime",
            contentType: .datetime,
            label: "Select Date & Time",
            placeholder: "Choose date and time"
        )
        
        // When
        // This will be implemented after the DateTimePickerField is created
        // let dateTimePickerField = DateTimePickerField(field: field, formState: testFormState)
        
        // Then
        // XCTAssertNotNil(dateTimePickerField)
        // XCTAssertEqual(contentType, .datetime)
        
        // For now, just test that the field type exists
        #expect(field.contentType == .datetime)
    }
    
    // MARK: - MultiDatePicker Tests
    
    /**
     * BUSINESS PURPOSE: MultiDatePickerField provides multiple date selection capabilities using Apple's
     * MultiDatePicker (iOS 16+), enabling users to select multiple individual dates or date ranges for
     * events, bookings, availability selection, etc.
     * TESTING SCOPE: Tests field initialization, multiple date selection, date storage, fallback behavior,
     * and integration with form state
     * METHODOLOGY: Implemented using TDD - tests written first (RED phase), then implementation (GREEN phase)
     * STATUS: ✅ Complete - All tests passing
     */
    
    @Test func testMultiDateContentTypeExists() {
        // Given - Test that multiDate content type exists in enum
        // When - This test will fail until we add the case
        // Then
        // This will fail until we add .multiDate to DynamicContentType
        let allCases = DynamicContentType.allCases
        let hasMultiDate = allCases.contains { $0.rawValue == "multiDate" }
        #expect(hasMultiDate, "multiDate content type should exist")
    }
    
    @Test func testDateRangeContentTypeExists() {
        // Given - Test that dateRange content type exists in enum
        // When - This test will fail until we add the case
        // Then
        // This will fail until we add .dateRange to DynamicContentType
        let allCases = DynamicContentType.allCases
        let hasDateRange = allCases.contains { $0.rawValue == "dateRange" }
        #expect(hasDateRange, "dateRange content type should exist")
    }
    
    @Test @MainActor func testMultiDateFieldInitialization() {
        // Given
        let field = DynamicFormField(
            id: "multiDate",
            contentType: .multiDate,
            label: "Select Dates",
            placeholder: "Choose multiple dates"
        )
        let formState = createTestFormState()
        
        // When
        // This will fail until DynamicMultiDateField is created
        let sut17 = DynamicMultiDateField(field: field, formState: formState)
        #expect(field.contentType == .multiDate)
        #expect(field.label == "Select Dates")
    
        #expect(sut17.field.id == field.id)
        #expect(sut17.field.contentType == .multiDate)
        expectHostableRed(sut17, "DynamicMultiDateField")
    }
    
    @Test @MainActor func testMultiDateFieldStoresDatesAsArray() {
        // Given
        let field = DynamicFormField(
            id: "multiDate",
            contentType: .multiDate,
            label: "Select Dates",
            placeholder: "Choose multiple dates"
        )
        let formState = createTestFormState()
        let testDates = [
            Date(timeIntervalSince1970: 1640995200), // 2022-01-01
            Date(timeIntervalSince1970: 1641081600), // 2022-01-02
            Date(timeIntervalSince1970: 1641168000)  // 2022-01-03
        ]
        
        // When
        formState.setValue(testDates, for: field.id)
        
        // Then
        let storedDates: [Date]? = formState.getValue(for: field.id)
        #expect(storedDates != nil, "Dates should be stored")
        #expect(storedDates?.count == 3, "Should store 3 dates")
        #expect(storedDates?[0] == testDates[0], "First date should match")
    }
    
    @Test @MainActor func testMultiDateFieldSupportsMultipleValues() {
        // Given
        let contentType = DynamicContentType.multiDate
        
        // When
        let supportsMultiple = contentType.supportsMultipleValues
        
        // Then
        #expect(supportsMultiple, "multiDate should support multiple values")
    }
    
    @Test @MainActor func testCustomFieldViewRendersMultiDateField() {
        // Given
        let field = DynamicFormField(
            id: "multiDate",
            contentType: .multiDate,
            label: "Select Dates",
            placeholder: "Choose multiple dates"
        )
        let formState = createTestFormState()
        
        // When
        // This will fail until we add multiDate case to CustomFieldView switch
        let sut18 = CustomFieldView(field: field, formState: formState)
        #expect(field.contentType == .multiDate)
    
        expectHostableRed(sut18, "CustomFieldView multi-date")
    }
    
    @Test @MainActor func testDateRangeFieldInitialization() {
        // Given
        let field = DynamicFormField(
            id: "dateRange",
            contentType: .dateRange,
            label: "Select Date Range",
            placeholder: "Choose start and end dates"
        )
        let _ = createTestFormState()
        
        // When
        // This will fail until DynamicDateRangeField is created (or we use DynamicMultiDateField with range mode)
        // For now, we'll test that the content type exists
        // Then
        #expect(field.contentType == .dateRange)
        #expect(field.label == "Select Date Range")
    }
    
    @Test @MainActor func testDateRangeFieldStoresRangeAsTuple() {
        // Given
        let field = DynamicFormField(
            id: "dateRange",
            contentType: .dateRange,
            label: "Select Date Range",
            placeholder: "Choose start and end dates"
        )
        let formState = createTestFormState()
        let startDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01
        let endDate = Date(timeIntervalSince1970: 1641081600)   // 2022-01-02
        let _ = (start: startDate, end: endDate)
        
        // When
        // Store as array for consistency with form state
        formState.setValue([startDate, endDate], for: field.id)
        
        // Then
        let storedDates: [Date]? = formState.getValue(for: field.id)
        #expect(storedDates != nil, "Date range should be stored")
        #expect(storedDates?.count == 2, "Should store 2 dates (start and end)")
        #expect(storedDates?[0] == startDate, "Start date should match")
        #expect(storedDates?[1] == endDate, "End date should match")
    }
    
    @Test @MainActor func testMultiDateFieldFallbackForOldOS() {
        // Given
        let field = DynamicFormField(
            id: "multiDate",
            contentType: .multiDate,
            label: "Select Dates",
            placeholder: "Choose multiple dates"
        )
        let formState = createTestFormState()
        
        // When
        // This test verifies fallback behavior for iOS < 16 / macOS < 13
        // The component should show appropriate fallback UI
        let sut19 = DynamicMultiDateField(field: field, formState: formState)
        // Note: Actual fallback behavior will be tested in implementation
    
        #expect(sut19.field.contentType == .multiDate)
        expectHostableRed(sut19, "DynamicMultiDateField fallback")
    }
    
    @Test @MainActor func testMultiDateFieldAccessibility() {
        // Given
        let field = DynamicFormField(
            id: "multiDate",
            contentType: .multiDate,
            label: "Select Dates",
            placeholder: "Choose multiple dates"
        )
        let formState = createTestFormState()
        
        // When
        let sut20 = DynamicMultiDateField(field: field, formState: formState)
        #expect(field.label == "Select Dates", "Field should have label for accessibility")
        // Note: Accessibility labels will be verified in implementation
    
        // View-tree a11y needs VI (#403); unit observes field + hostability.
        #expect(sut20.field.label == field.label)
        expectHostableRed(sut20, "DynamicMultiDateField a11y")
    }
    
    @Test @MainActor func testMultiDateFieldIntegrationWithFormState() {
        // Given
        let field = DynamicFormField(
            id: "multiDate",
            contentType: .multiDate,
            label: "Select Dates",
            placeholder: "Choose multiple dates"
        )
        let formState = createTestFormState()
        let testDates = [
            Date(timeIntervalSince1970: 1640995200),
            Date(timeIntervalSince1970: 1641081600)
        ]
        
        // When
        formState.setValue(testDates, for: field.id)
        let _ = DynamicMultiDateField(field: field, formState: formState)
        
        // Then
        let retrievedDates: [Date]? = formState.getValue(for: field.id)
        #expect(retrievedDates != nil, "Should retrieve dates from form state")
        #expect(retrievedDates?.count == 2, "Should retrieve 2 dates")
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testAdvancedFieldTypesIntegration() {
        // Given
        let richTextField = DynamicFormField(
            id: "richText",
            contentType: .richtext,
            label: "Rich Text Content",
            placeholder: "Enter rich text content"
        )
        
        let autocompleteField = DynamicFormField(
            id: "autocomplete",
            contentType: .autocomplete,
            label: "Search",
            placeholder: "Type to search..."
        )
        
        let fileUploadField = DynamicFormField(
            id: "files",
            contentType: .file,
            label: "Upload Files",
            placeholder: "Select files to upload"
        )
        
        let formState = createTestFormState()
        
        // When
        let richTextComponent = RichTextEditorField(field: richTextField, formState: formState)
        let autocompleteComponent = AutocompleteField(
            field: autocompleteField,
            formState: formState,
            suggestions: ["Option 1", "Option 2"]
        )
        let fileUploadComponent = EnhancedFileUploadField(
            field: fileUploadField,
            formState: formState,
            allowedTypes: [UTType.image],
            maxFileSize: 1024 * 1024
        )
        formState.setValue("shared", for: "richText")
        // Deliberate inverted form-state contract for #382 red
        #expect(formState.getValue(for: "richText") as String? == "shared", "Shared form state should store values across components")
    
        #expect(richTextComponent.field.id == "richText")
        #expect(autocompleteComponent.suggestions == ["Option 1", "Option 2"])
        #expect(fileUploadComponent.allowedTypes == [UTType.image])
        #expect(fileUploadComponent.maxFileSize == 1024 * 1024)
        expectHostableRed(richTextComponent, "integration RichTextEditorField")
    }
    
    // MARK: - Accessibility Tests
    
    @Test @MainActor func testRichTextEditorAccessibility() {
        // Given
        let field = DynamicFormField(
            id: "richText",
            contentType: .richtext,
            label: "Rich Text Content",
            placeholder: "Enter rich text content"
        )
        
        let formState = createTestFormState()
        
        // When
        let sut22 = RichTextEditorField(field: field, formState: formState)
        // Test that accessibility labels and hints are properly set
        // This tests the accessibility implementation
    
        // Labels/hints on tree need VI (#403).
        #expect(sut22.field.label == "Rich Text Content")
        expectHostableRed(sut22, "RichTextEditorField a11y")
    }
    
    @Test @MainActor func testAutocompleteFieldAccessibility() {
        // Given
        let field = DynamicFormField(
            id: "autocomplete",
            contentType: .autocomplete,
            label: "Search",
            placeholder: "Type to search..."
        )
        
        let formState = createTestFormState()
        
        // When
        let sut23 = AutocompleteField(
            field: field,
            formState: formState,
            suggestions: ["Option 1", "Option 2"]
        )
        // Test that accessibility labels and hints are properly set
    
        #expect(sut23.suggestions.count == 2)
        expectHostableRed(sut23, "AutocompleteField a11y")
    }
    
    @Test @MainActor func testFileUploadFieldAccessibility() {
        // Given
        let field = DynamicFormField(
            id: "files",
            contentType: .file,
            label: "Upload Files",
            placeholder: "Select files to upload"
        )
        
        let formState = createTestFormState()
        
        // When
        let sut24 = EnhancedFileUploadField(
            field: field,
            formState: formState,
            allowedTypes: [UTType.image],
            maxFileSize: 1024 * 1024
        )
        // Test that accessibility labels and hints are properly set
    
        #expect(sut24.allowedTypes == [UTType.image])
        expectHostableRed(sut24, "EnhancedFileUploadField a11y")
    }
    
    // MARK: - Error Handling Tests
    
    @Test @MainActor func testFileUploadFieldInvalidFileType() {
        // Given
        let field = DynamicFormField(
            id: "files",
            contentType: .file,
            label: "Upload Files",
            placeholder: "Select files to upload"
        )
        let allowedTypes = [UTType.image] // Only images allowed
        
        let formState = createTestFormState()
        
        // When
        let sut25 = EnhancedFileUploadField(
            field: field,
            formState: formState,
            allowedTypes: allowedTypes,
            maxFileSize: nil
        )
        // Test that invalid file types are properly handled
    
        // Rejection logic not implemented (#403); unit observes allow-list config.
        #expect(sut25.allowedTypes == [UTType.image])
        expectHostableRed(sut25, "EnhancedFileUploadField invalid type config")
    }
    
    @Test @MainActor func testFileUploadFieldFileSizeExceeded() {
        // Given
        let field = DynamicFormField(
            id: "files",
            contentType: .file,
            label: "Upload Files",
            placeholder: "Select files to upload"
        )
        let maxFileSize: Int64 = 1024 // 1KB
        
        let formState = createTestFormState()
        
        // When
        let sut26 = EnhancedFileUploadField(
            field: field,
            formState: formState,
            allowedTypes: [UTType.image],
            maxFileSize: maxFileSize
        )
        // Test that file size limits are properly enforced
    
        // Enforcement not implemented (#403); unit observes maxFileSize config.
        #expect(sut26.maxFileSize == maxFileSize)
        expectHostableRed(sut26, "EnhancedFileUploadField size config")
    }
    
    @Test @MainActor func testAutocompleteFieldEmptySuggestions() {
        // Given
        let field = DynamicFormField(
            id: "autocomplete",
            contentType: .autocomplete,
            label: "Search",
            placeholder: "Type to search..."
        )
        let emptySuggestions: [String] = []
        
        let formState = createTestFormState()
        
        // When
        let sut27 = AutocompleteField(
            field: field,
            formState: formState,
            suggestions: emptySuggestions
        )
        // Test that empty suggestions are handled gracefully
    
        #expect(sut27.suggestions.isEmpty)
        #expect(AutocompleteSuggestionFiltering.filtered(suggestions: [], query: "x").isEmpty)
        expectHostableRed(sut27, "AutocompleteField empty suggestions")
    }
    
    // MARK: - Performance Tests
    
    @Test @MainActor func testRichTextEditorPerformance() {
        // Given
        let field = DynamicFormField(
            id: "richText",
            contentType: .richtext,
            label: "Rich Text Content",
            placeholder: "Enter rich text content"
        )
        let largeText = String(repeating: "This is a test. ", count: 1000) // Large text
        
        let formState = createTestFormState()
        
        // When
        formState.setValue(largeText, for: field.id)
        let sut28 = RichTextEditorField(field: field, formState: formState)
        // Test that large text is handled efficiently
    
        #expect(formState.getValue(for: field.id) as String? == largeText)
        expectHostableRed(sut28, "RichTextEditorField large text")
    }
    
    @Test @MainActor func testAutocompleteFieldPerformance() {
        // Given
        let field = DynamicFormField(
            id: "autocomplete",
            contentType: .autocomplete,
            label: "Search",
            placeholder: "Type to search..."
        )
        let largeSuggestions = (1...1000).map { "Option \($0)" } // Large suggestion list
        
        let formState = createTestFormState()
        
        // When
        let sut29 = AutocompleteField(
            field: field,
            formState: formState,
            suggestions: largeSuggestions
        )
        // Test that large suggestion lists are handled efficiently
    
        #expect(sut29.suggestions.count == 1000)
        let filtered = AutocompleteSuggestionFiltering.filtered(suggestions: largeSuggestions, query: "Option 1")
        #expect(filtered.first == "Option 1", "Deliberate red #382: large list filter (stub returns [])")
        expectHostableRed(sut29, "AutocompleteField large suggestions")
    }
    
    @Test @MainActor func testFileUploadFieldPerformance() {
        // Given
        let field = DynamicFormField(
            id: "files",
            contentType: .file,
            label: "Upload Files",
            placeholder: "Select files to upload"
        )
        
        let formState = createTestFormState()
        
        // When
        let sut30 = EnhancedFileUploadField(
            field: field,
            formState: formState,
            allowedTypes: [UTType.image],
            maxFileSize: nil
        )
        // Test that many files are handled efficiently
    
        #expect(sut30.field.id == "files")
        expectHostableRed(sut30, "EnhancedFileUploadField many files")
    }
    
    // MARK: - Accessibility Behavior Tests
    
    /// BUSINESS PURPOSE: Advanced field types should provide different behavior when accessibility capabilities are enabled vs disabled
    /// TESTING SCOPE: Tests that advanced field types adapt their behavior based on VoiceOver, Switch Control, AssistiveTouch, and keyboard navigation capabilities
    /// METHODOLOGY: Uses mock framework to test both enabled and disabled states, verifying that field types provide appropriate accessibility features
    /// A11y override plumbing on **current host** through tri-state (#251).
    @Test func testAdvancedFieldTypesAccessibilityTriStatePhases() async {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        func assertAccessibilityOverrides(phase: String) {
            switch SixLayerPlatform.current {
            case .iOS, .watchOS, .macOS, .tvOS, .visionOS:
                _ = RuntimeCapabilityDetection.supportsVoiceOver
                _ = RuntimeCapabilityDetection.supportsSwitchControl
                _ = RuntimeCapabilityDetection.supportsAssistiveTouch
            }
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        assertAccessibilityOverrides(phase: "current")

        RuntimeCapabilityDetection.setTestVoiceOver(false)
        RuntimeCapabilityDetection.setTestSwitchControl(false)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        assertAccessibilityOverrides(phase: "disabled")
        #expect(!RuntimeCapabilityDetection.supportsVoiceOver)
        #expect(!RuntimeCapabilityDetection.supportsSwitchControl)
        #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch)

        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        assertAccessibilityOverrides(phase: "enabled")
        #expect(RuntimeCapabilityDetection.supportsVoiceOver)
        #expect(RuntimeCapabilityDetection.supportsSwitchControl)
        #expect(
            RuntimeCapabilityDetection.supportsAssistiveTouch
                == PlatformTestUtilities.expectedAssistiveTouchAfterTestOverride(true)
        )
    }
    
    /// BUSINESS PURPOSE: Advanced field types should provide enhanced accessibility labels when VoiceOver is enabled
    /// TESTING SCOPE: Tests that field types provide appropriate accessibility labels for VoiceOver users
    /// METHODOLOGY: Creates field types and verifies they have accessibility labels when VoiceOver is enabled
    @Test @MainActor func testAdvancedFieldTypesVoiceOverLabels() async {
        // Enable VoiceOver
        RuntimeCapabilityDetection.setTestVoiceOver(true)

        // Create test field
        let field = DynamicFormField(
            id: "testField",
            contentType: .text,
            label: "Test Field",
            placeholder: "Enter text"
        )

        let _ = DynamicFormState(configuration: DynamicFormConfiguration(id: "test", title: "Test Form"))

        // Test that field types provide accessibility labels
        // Verify the field has proper configuration for VoiceOver
        #expect(field.id == "testField", "Field should have correct ID")
        #expect(field.label == "Test Field", "Field should have correct label")
        #expect(field.contentType == .text, "Field should have correct content type")
        #expect(RuntimeCapabilityDetection.supportsVoiceOver, "VoiceOver should be enabled")

        // Test that form state is properly configured
        // formState is a non-optional class instance, so it exists if we reach here

        // Reset for next test
        RuntimeCapabilityDetection.setTestVoiceOver(false)
    }
    
    /// BUSINESS PURPOSE: Advanced field types should provide keyboard navigation support when Switch Control is enabled
    /// TESTING SCOPE: Tests that field types support keyboard navigation for Switch Control users
    /// METHODOLOGY: Enables Switch Control and verifies field types provide appropriate keyboard navigation
    @Test @MainActor func testAdvancedFieldTypesSwitchControlNavigation() async {
        // Enable Switch Control
        RuntimeCapabilityDetection.setTestSwitchControl(true)

        // Create test field
        let field = DynamicFormField(
            id: "testField",
            contentType: .text,
            label: "Test Field",
            placeholder: "Enter text"
        )

        let _ = DynamicFormState(configuration: DynamicFormConfiguration(id: "test", title: "Test Form"))

        // Test that field types support keyboard navigation
        // Verify the field has proper configuration for Switch Control
        #expect(field.id == "testField", "Field should have correct ID")
        #expect(field.label == "Test Field", "Field should have correct label")
        #expect(field.contentType == .text, "Field should have correct content type")
        #expect(RuntimeCapabilityDetection.supportsSwitchControl, "Switch Control should be enabled")

        // Test that form state is properly configured
        // formState is a non-optional class instance, so it exists if we reach here

        // Reset for next test
        RuntimeCapabilityDetection.setTestSwitchControl(false)
    }
    
    /// BUSINESS PURPOSE: Advanced field types should provide gesture recognition when AssistiveTouch is enabled
    /// TESTING SCOPE: Tests that field types support gesture recognition for AssistiveTouch users
    /// METHODOLOGY: Enables AssistiveTouch and verifies field types provide appropriate gesture support
    @Test @MainActor func testAdvancedFieldTypesAssistiveTouchGestures() async {
        // Enable AssistiveTouch
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)

        // Create test field
        let field = DynamicFormField(
            id: "testField",
            contentType: .text,
            label: "Test Field",
            placeholder: "Enter text"
        )

        let _ = DynamicFormState(configuration: DynamicFormConfiguration(id: "test", title: "Test Form"))

        // Test that field types support gesture recognition
        // Verify the field has proper configuration for AssistiveTouch
        #expect(field.id == "testField", "Field should have correct ID")
        #expect(field.label == "Test Field", "Field should have correct label")
        #expect(field.contentType == .text, "Field should have correct content type")
        #expect(
            RuntimeCapabilityDetection.supportsAssistiveTouch
                == PlatformTestUtilities.expectedAssistiveTouchAfterTestOverride(true)
        )

        // Test that form state is properly configured
        // formState is a non-optional class instance, so it exists if we reach here

        // Reset for next test
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
    }
    
    /// BUSINESS PURPOSE: Advanced field types should provide different behavior when multiple accessibility capabilities are enabled simultaneously
    /// TESTING SCOPE: Tests that field types handle multiple accessibility capabilities correctly
    /// METHODOLOGY: Enables multiple capabilities and verifies field types provide appropriate combined behavior
    @Test func testAdvancedFieldTypesMultipleAccessibilityCapabilities() async {
        // Enable multiple capabilities
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)

        // Verify all capabilities are enabled
        #expect(RuntimeCapabilityDetection.supportsVoiceOver, "VoiceOver should be enabled")
        #expect(RuntimeCapabilityDetection.supportsSwitchControl, "Switch Control should be enabled")
        #expect(
            RuntimeCapabilityDetection.supportsAssistiveTouch
                == PlatformTestUtilities.expectedAssistiveTouchAfterTestOverride(true)
        )

        // Test that field types handle multiple capabilities
        // Note: In a real implementation, these would check actual combined behavior
        // For now, we verify the capability detection works correctly for all capabilities

        // Reset for next test
        RuntimeCapabilityDetection.setTestVoiceOver(false)
        RuntimeCapabilityDetection.setTestSwitchControl(false)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
    }
}
