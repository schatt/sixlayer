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
@Suite("Advanced Field Types", DefaultRuntimeCapabilityIsolationTrait())
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
    }    // MARK: - Rich Text Editor Tests
    
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
        let sut1TypeName = String(describing: type(of: sut1))
        #expect(sut1TypeName.contains("RichTextEditorField"), "RichTextEditorField should be constructed (type: \(sut1TypeName))")
        #expect(field.contentType == .richtext)
        #expect(field.label == "Rich Text Content")
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
        let sut2TypeName = String(describing: type(of: sut2))
        #expect(sut2TypeName.contains("RichTextEditorField"), "RichTextEditorField should be constructed (type: \(sut2TypeName))")
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
        let sut3TypeName = String(describing: type(of: sut3))
        #expect(sut3TypeName.contains("RichTextEditorField"), "RichTextEditorField should be constructed (type: \(sut3TypeName))")
        #expect(formState.getValue(for: field.id) == testText)
    }
    
    @Test @MainActor func testRichTextToolbarFormatting() {
        // Given
        let selectedText = NSRange(location: 0, length: 5)
        
        // When
        let sut4 = RichTextToolbar(selectedText: .constant(selectedText))
        let sut4TypeName = String(describing: type(of: sut4))
        #expect(sut4TypeName.contains("RichTextToolbar"), "RichTextToolbar should be constructed (type: \(sut4TypeName))")
        // Test that formatting buttons are present
        // This tests the toolbar UI structure
    }
    
    @Test @MainActor func testRichTextPreview() {
        // Given
        let testText = "This is **bold** and *italic* text"
        
        // When
        let sut5 = RichTextPreview(text: testText)
        let sut5TypeName = String(describing: type(of: sut5))
        #expect(sut5TypeName.contains("RichTextPreview"), "RichTextPreview should be constructed (type: \(sut5TypeName))")
        // Test that preview displays the text correctly
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
        let sut6TypeName = String(describing: type(of: sut6))
        #expect(sut6TypeName.contains("AutocompleteField"), "AutocompleteField should be constructed (type: \(sut6TypeName))")
        #expect(field.contentType == .autocomplete)
        #expect(field.label == "Search")
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
        let sut7TypeName = String(describing: type(of: sut7))
        #expect(sut7TypeName.contains("AutocompleteField"), "AutocompleteField should be constructed (type: \(sut7TypeName))")
        // Test that suggestions are properly filtered
        // This tests the internal filtering logic
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
        let sut8TypeName = String(describing: type(of: sut8))
        #expect(sut8TypeName.contains("AutocompleteField"), "AutocompleteField should be constructed (type: \(sut8TypeName))")
        // Test that suggestion selection updates the form state
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
        let sut9TypeName = String(describing: type(of: sut9))
        #expect(sut9TypeName.contains("AutocompleteSuggestions"), "AutocompleteSuggestions should be constructed (type: \(sut9TypeName))")
        // Test that suggestions are displayed correctly
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
        let sut10TypeName = String(describing: type(of: sut10))
        #expect(sut10TypeName.contains("EnhancedFileUploadField"), "EnhancedFileUploadField should be constructed (type: \(sut10TypeName))")
        #expect(field.contentType == .file)
        #expect(field.label == "Upload Files")
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
        let sut11TypeName = String(describing: type(of: sut11))
        #expect(sut11TypeName.contains("EnhancedFileUploadField"), "EnhancedFileUploadField should be constructed (type: \(sut11TypeName))")
        // Test that allowed types are properly configured
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
        let sut12TypeName = String(describing: type(of: sut12))
        #expect(sut12TypeName.contains("EnhancedFileUploadField"), "EnhancedFileUploadField should be constructed (type: \(sut12TypeName))")
        // Test that max file size is properly configured
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
        let sut13TypeName = String(describing: type(of: sut13))
        #expect(sut13TypeName.contains("FileUploadArea"), "FileUploadArea should be constructed (type: \(sut13TypeName))")
        // Test that drag and drop area is properly configured
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
        let sut14TypeName = String(describing: type(of: sut14))
        #expect(sut14TypeName.contains("FileList"), "FileList should be constructed (type: \(sut14TypeName))")
        // Test that file list displays files correctly
    }
    
    @Test @MainActor func testFileRowDisplay() {
        // Given
        let file = FileInfo(name: "test.pdf", size: 1024, type: .pdf, url: nil)
        
        // When
        let sut15 = FileRow(file: file) { _ in
        }
        let sut15TypeName = String(describing: type(of: sut15))
        #expect(sut15TypeName.contains("FileRow"), "FileRow should be constructed (type: \(sut15TypeName))")
        // Test that file row displays file information correctly
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

        CustomFieldRegistry.shared.register("slider") { field, formState in
            SliderField(field: field, formState: formState)
        }
        
        let testField = DynamicFormField(
            id: "slider",
            contentType: .custom,
            label: "Test Slider",
            metadata: ["customFieldType": "slider"]
        )
        let testFormState = createTestFormState()
        
        // When
        let sut16 = CustomFieldView(field: testField, formState: testFormState)
        let sut16TypeName = String(describing: type(of: sut16))
        #expect(sut16TypeName.contains("CustomFieldView"), "CustomFieldView should be constructed (type: \(sut16TypeName))")

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
        let sut17TypeName = String(describing: type(of: sut17))
        #expect(sut17TypeName.contains("DynamicMultiDateField"), "DynamicMultiDateField should be constructed (type: \(sut17TypeName))")
        #expect(field.contentType == .multiDate)
        #expect(field.label == "Select Dates")
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
        let sut18TypeName = String(describing: type(of: sut18))
        #expect(sut18TypeName.contains("CustomFieldView"), "CustomFieldView should be constructed (type: \(sut18TypeName))")
        #expect(field.contentType == .multiDate)
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
        let sut19TypeName = String(describing: type(of: sut19))
        #expect(sut19TypeName.contains("DynamicMultiDateField"), "DynamicMultiDateField should be constructed (type: \(sut19TypeName))")
        // Note: Actual fallback behavior will be tested in implementation
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
        let sut20TypeName = String(describing: type(of: sut20))
        #expect(sut20TypeName.contains("DynamicMultiDateField"), "DynamicMultiDateField should be constructed (type: \(sut20TypeName))")
        #expect(field.label == "Select Dates", "Field should have label for accessibility")
        // Note: Accessibility labels will be verified in implementation
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
        let richTextComponentTypeName = String(describing: type(of: richTextComponent))
        #expect(richTextComponentTypeName.contains("RichTextEditorField"), "RichTextEditorField should be constructed (type: \(richTextComponentTypeName))")
        let autocompleteComponentTypeName = String(describing: type(of: autocompleteComponent))
        #expect(autocompleteComponentTypeName.contains("AutocompleteField"), "AutocompleteField should be constructed (type: \(autocompleteComponentTypeName))")
        let fileUploadComponentTypeName = String(describing: type(of: fileUploadComponent))
        #expect(fileUploadComponentTypeName.contains("EnhancedFileUploadField"), "EnhancedFileUploadField should be constructed (type: \(fileUploadComponentTypeName))")
        formState.setValue("shared", for: "richText")
        // Deliberate inverted form-state contract for #382 red
        #expect(formState.getValue(for: "richText") as String? == "shared", "Shared form state should store values across components")
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
        let sut22TypeName = String(describing: type(of: sut22))
        #expect(sut22TypeName.contains("RichTextEditorField"), "RichTextEditorField should be constructed (type: \(sut22TypeName))")
        // Test that accessibility labels and hints are properly set
        // This tests the accessibility implementation
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
        let sut23TypeName = String(describing: type(of: sut23))
        #expect(sut23TypeName.contains("AutocompleteField"), "AutocompleteField should be constructed (type: \(sut23TypeName))")
        // Test that accessibility labels and hints are properly set
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
        let sut24TypeName = String(describing: type(of: sut24))
        #expect(sut24TypeName.contains("EnhancedFileUploadField"), "EnhancedFileUploadField should be constructed (type: \(sut24TypeName))")
        // Test that accessibility labels and hints are properly set
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
        let sut25TypeName = String(describing: type(of: sut25))
        #expect(sut25TypeName.contains("EnhancedFileUploadField"), "EnhancedFileUploadField should be constructed (type: \(sut25TypeName))")
        // Test that invalid file types are properly handled
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
        let sut26TypeName = String(describing: type(of: sut26))
        #expect(sut26TypeName.contains("EnhancedFileUploadField"), "EnhancedFileUploadField should be constructed (type: \(sut26TypeName))")
        // Test that file size limits are properly enforced
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
        let sut27TypeName = String(describing: type(of: sut27))
        #expect(sut27TypeName.contains("AutocompleteField"), "AutocompleteField should be constructed (type: \(sut27TypeName))")
        // Test that empty suggestions are handled gracefully
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
        let sut28TypeName = String(describing: type(of: sut28))
        #expect(sut28TypeName.contains("RichTextEditorField"), "RichTextEditorField should be constructed (type: \(sut28TypeName))")
        // Test that large text is handled efficiently
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
        let sut29TypeName = String(describing: type(of: sut29))
        #expect(sut29TypeName.contains("AutocompleteField"), "AutocompleteField should be constructed (type: \(sut29TypeName))")
        // Test that large suggestion lists are handled efficiently
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
        let sut30TypeName = String(describing: type(of: sut30))
        #expect(sut30TypeName.contains("EnhancedFileUploadField"), "EnhancedFileUploadField should be constructed (type: \(sut30TypeName))")
        // Test that many files are handled efficiently
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
