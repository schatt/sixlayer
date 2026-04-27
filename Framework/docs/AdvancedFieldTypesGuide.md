# Advanced Field Types Guide

## Overview

The Advanced Field Types system provides a comprehensive set of sophisticated form input components that extend beyond basic text fields. These components follow the six-layer architecture principles and integrate seamlessly with the dynamic form system.

## Features

### 🎨 Rich Text Editor
- **Formatting Capabilities** - Bold, italic, underline, bullet lists, numbered lists
- **Platform-Specific Implementation** - Native iOS UITextView with macOS fallback
- **Real-time Preview** - Toggle between editing and preview modes
- **Accessibility Support** - Full VoiceOver integration

### 📅 Date/Time Pickers
- **Date Picker** - Select dates with compact picker interface
- **Time Picker** - Select times with hour and minute precision
- **DateTime Picker** - Combined date and time selection
- **MultiDate Picker** (iOS 16+) - Select multiple individual dates from calendar
- **Date Range Picker** - Select date ranges (start and end dates)
- **Automatic Formatting** - Proper date/time string formatting
- **Value Persistence** - Integration with form state management
- **Fallback Support** - Graceful degradation for older iOS versions and macOS

### `DynamicFormState` date contracts (CustomFieldView vs advanced pickers)

Two intentional storage shapes exist; do not mix them for the same field without conversion:

| Path | Views | Stored value |
|------|--------|----------------|
| **Dynamic form / `CustomFieldView`** | `DynamicDateField`, `DynamicTimeField`, `DynamicDateTimeField` | Prefer `Date` in `fieldValues[fieldId]`. `DynamicFormStoredDateValue` also parses legacy `String` (ISO-8601 or the same medium/short formats below) and `TimeInterval`. |
| **Advanced composable pickers** | `DatePickerField`, `TimePickerField`, `DateTimePickerField` in `AdvancedFieldTypes.swift` | Localized **medium / short** `String` values (see formatters in those types). |

Hosts that migrate between paths should normalize at the boundary (parse to `Date` or serialize to the string format) so pickers and submit payloads stay consistent.

### 🔍 Autocomplete Field
- **Smart Filtering** - Intelligent suggestion filtering with prefix matching
- **Sorted Results** - Prioritized suggestions (exact matches first)
- **Real-time Updates** - Dynamic suggestion list updates
- **Keyboard Navigation** - Full keyboard support for accessibility

### 📁 File Upload Field
- **Drag & Drop Support** - Native drag and drop functionality
- **File Type Validation** - Configurable allowed file types
- **File Size Limits** - Optional maximum file size enforcement
- **Visual Feedback** - Clear upload area with drag state indicators
- **File Management** - Individual file removal and status display

### 🔧 Custom Field Components
- **Registry System** - Dynamic registration of custom field types
- **Protocol-Based** - Clean protocol for custom field implementation
- **Fallback Support** - Graceful degradation for unknown field types
- **Extensibility** - Easy addition of new field types

### 🎯 Native Type Support (v3.1.0+)
- **Integer Fields** - Native `Int` support with number pad keyboard
- **Image Fields** - Cross-platform image handling with mock types
- **URL Fields** - Native `URL` support with URL keyboard type
- **Array Fields** - Native array support for collections
- **Data Fields** - Native `Data` support for binary content
- **Enum Fields** - Native enum support with picker interface
- **Type Safety** - Full compile-time type checking
- **Cross-Platform** - Consistent behavior across iOS, macOS, and other platforms

### 🔢 Stepper Field (v6.0.0+)
- **Increment/Decrement Controls** - Native SwiftUI Stepper with +/- buttons
- **Range Configuration** - Supports min/max values via `FieldDisplayHints.expectedRange` or metadata
- **Step Size** - Configurable increment/decrement step size
- **Value Display** - Shows current value with appropriate formatting (integer or decimal)
- **Form State Integration** - Seamless integration with `DynamicFormState`
- **Accessibility** - Full VoiceOver support with proper labels and hints

## Architecture

### Layer 1: Semantic - Field Types
```swift
public enum DynamicFieldType: String, CaseIterable, Hashable {
    case richtext = "richtext"
    case autocomplete = "autocomplete"
    case file = "file"
    case date = "date"
    case time = "time"
    // Native Type Support (v3.1.0+)
    case integer = "integer"      // High Priority: Native Int support
    case image = "image"          // High Priority: Native image support
    case url = "url"              // High Priority: Native URL support
    case array = "array"          // Medium Priority: Native array support
    case data = "data"            // Medium Priority: Native Data support
    case `enum` = "enum"          // Low Priority: Native enum support
    case stepper = "stepper"      // Increment/decrement control (v6.0.0+)
    case datetime = "datetime"
    case custom = "custom"
    // ... other field types
}
```

### Layer 2: Decision - Field Configuration
```swift
public struct DynamicFormField {
    public let id: String
    public let type: DynamicFieldType
    public let label: String
    public let placeholder: String?
    public let options: [String]?
    public let metadata: [String: Any]?
}
```

### Layer 3: Strategy - Field Selection
The system automatically selects the appropriate field component based on the field type, with fallback mechanisms for unknown types.

### Layer 4: Implementation - Field Components
- **RichTextEditorField** - Rich text editing with formatting
- **AutocompleteField** - Smart suggestion-based input
- **EnhancedFileUploadField** - Drag & drop file upload
- **DatePickerField** - Date selection
- **TimePickerField** - Time selection
- **DateTimePickerField** - Combined date/time selection
- **CustomFieldView** - Custom field component wrapper

### Layer 5: Performance
- **Efficient Rendering** - Optimized SwiftUI rendering
- **Memory Management** - Proper state management with @StateObject
- **Lazy Loading** - On-demand component initialization

### Layer 6: Platform
- **Cross-Platform** - iOS and macOS support
- **Native Components** - Platform-specific implementations where beneficial
- **Accessibility** - Full accessibility support across platforms

## Usage Examples

### Rich Text Editor

```swift
let field = DynamicFormField(
    id: "content",
    type: .richtext,
    label: "Article Content",
    placeholder: "Write your article here..."
)

RichTextEditorField(field: field, formState: formState)
```

### Date/Time Pickers

```swift
// Date picker
let dateField = DynamicFormField(
    id: "birthDate",
    type: .date,
    label: "Birth Date",
    placeholder: "Select your birth date"
)

// Time picker
let timeField = DynamicFormField(
    id: "meetingTime",
    type: .time,
    label: "Meeting Time",
    placeholder: "Select meeting time"
)

// DateTime picker
let dateTimeField = DynamicFormField(
    id: "eventDateTime",
    type: .datetime,
    label: "Event Date & Time",
    placeholder: "Select event date and time"
)

// MultiDate picker (iOS 16+) - Select multiple dates
let multiDateField = DynamicFormField(
    id: "availableDates",
    contentType: .multiDate,
    label: "Available Dates",
    placeholder: "Select multiple dates"
)

// Date range picker - Select start and end dates
let dateRangeField = DynamicFormField(
    id: "eventRange",
    contentType: .dateRange,
    label: "Event Date Range",
    placeholder: "Select start and end dates"
)
```

### Autocomplete Field

```swift
let field = DynamicFormField(
    id: "country",
    type: .autocomplete,
    label: "Country",
    placeholder: "Type to search countries..."
)

AutocompleteField(
    field: field,
    formState: formState,
    suggestions: ["United States", "Canada", "United Kingdom", "Australia"]
)
```

### File Upload Field

```swift
let field = DynamicFormField(
    id: "attachments",
    type: .file,
    label: "Upload Files",
    placeholder: "Select files to upload"
)

EnhancedFileUploadField(
    field: field,
    formState: formState,
    allowedTypes: [.image, .pdf, .text],
    maxFileSize: 10 * 1024 * 1024 // 10MB
)
```

### Stepper Field

```swift
// Using metadata for min/max/step
let field = DynamicFormField(
    id: "quantity",
    contentType: .stepper,
    label: "Quantity",
    defaultValue: "1",
    metadata: [
        "min": "0",
        "max": "100",
        "step": "1"
    ]
)

// Using FieldDisplayHints.expectedRange (preferred)
let fieldWithHints = DynamicFormField(
    id: "rating",
    contentType: .stepper,
    label: "Rating",
    defaultValue: "3",
    metadata: [
        "expectedRange": "1:5",  // min:max format
        "step": "1"
    ]
)

DynamicStepperField(field: field, formState: formState)
```

**Configuration Options:**
- **Range**: Use `FieldDisplayHints.expectedRange` (preferred) or `metadata["min"]`/`metadata["max"]` (fallback)
- **Step Size**: Configure via `metadata["step"]` (default: 1.0)
- **Default Value**: Set via `defaultValue` parameter
- **Formatting**: Automatically formats as integer when step is whole number, decimal otherwise

### Custom Field Components

```swift
// Define custom field component
struct CustomSliderField: CustomFieldComponent {
    let field: DynamicFormField
    let formState: DynamicFormState
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(field.label)
                .font(.headline)
            
            Slider(value: Binding(
                get: { Double(formState.getValue(for: field.id) ?? "0") ?? 0 },
                set: { formState.setValue(String($0), for: field.id) }
            ), in: 0...100)
        }
    }
}

// Register custom field
CustomFieldRegistry.shared.register("slider", component: CustomSliderField.self)
```

## API Reference

### RichTextEditorField

```swift
public struct RichTextEditorField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    
    public var body: some View
}
```

**Features:**
- Toggle between editing and preview modes
- Rich text formatting toolbar
- Platform-specific text editor implementation
- Accessibility support

### DatePickerField

```swift
public struct DatePickerField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var selectedDate = Date()
    
    public var body: some View
}
```

### DynamicStepperField

```swift
public struct DynamicStepperField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    
    public var body: some View
}
```

**Features:**
- Prefers `FieldDisplayHints.expectedRange` for min/max configuration
- Falls back to `metadata["min"]` and `metadata["max"]` when `expectedRange` is not available
- Configurable step size via `metadata["step"]`
- Automatic value formatting (integer vs decimal based on step size)
- Full accessibility support with automatic identifier generation
- Real-time form state updates

**Features:**
- Compact date picker interface
- Automatic date formatting
- Form state integration
- Accessibility labels and hints

### TimePickerField

```swift
public struct TimePickerField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var selectedTime = Date()
    
    public var body: some View
}
```

**Features:**
- Hour and minute selection
- Time formatting
- Form state integration
- Accessibility support

### DateTimePickerField

```swift
public struct DateTimePickerField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var selectedDateTime = Date()
    
    public var body: some View
}
```

**Features:**
- Combined date and time selection
- Comprehensive formatting
- Form state integration
- Accessibility support

### AutocompleteField

```swift
public struct AutocompleteField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    let suggestions: [String]
    
    public var body: some View
}
```

**Features:**
- Smart suggestion filtering
- Prefix matching prioritization
- Real-time updates
- Keyboard navigation

### EnhancedFileUploadField

```swift
public struct EnhancedFileUploadField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    let allowedTypes: [UTType]
    let maxFileSize: Int64?
    
    public var body: some View
}
```

**Features:**
- Drag and drop support
- File type validation
- File size limits
- Visual feedback
- File management

### CustomFieldView

```swift
public struct CustomFieldView: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    
    public var body: some View
}
```

**Features:**
- Registry-based component lookup
- Fallback to text field
- Extensible architecture

## Accessibility

All Advanced Field Types include comprehensive accessibility support:

### VoiceOver Integration
- **Accessibility Labels** - Descriptive labels for screen readers
- **Accessibility Hints** - Clear instructions for interaction
- **Accessibility Values** - Current values and states
- **Keyboard Navigation** - Full keyboard support

### Example Accessibility Implementation
```swift
DatePicker(...)
    .accessibilityLabel("Date picker for \(field.label)")
    .accessibilityHint("Tap to select a date")
```

## Performance Considerations

### Efficient Rendering
- **SwiftUI Optimization** - Minimal redraws and efficient state management
- **Lazy Loading** - Components are created only when needed
- **Memory Management** - Proper cleanup and state management

### File Upload Performance
- **Asynchronous Processing** - Non-blocking file handling
- **Size Validation** - Early validation to prevent large file processing
- **Type Checking** - Efficient file type validation

### Autocomplete Performance
- **Smart Filtering** - Efficient suggestion filtering algorithms
- **Debounced Updates** - Prevents excessive filtering operations
- **Sorted Results** - Optimized suggestion ordering

## Testing

The Advanced Field Types system includes comprehensive test coverage:

### Test Categories
- **Unit Tests** - Individual component testing
- **Integration Tests** - Form state integration
- **Accessibility Tests** - VoiceOver and keyboard support
- **Performance Tests** - Large dataset handling
- **Error Handling Tests** - Edge cases and error scenarios

### Test Coverage
- **32 test cases** covering all functionality
- **100% component coverage** for all field types
- **Accessibility validation** for all components
- **Performance testing** for large datasets

## Best Practices

### Field Configuration
1. **Use Appropriate Types** - Select the right field type for your data
2. **Provide Clear Labels** - Use descriptive labels and placeholders
3. **Set Validation Rules** - Configure appropriate validation for each field
4. **Consider Accessibility** - Ensure all fields are accessible

### Custom Field Development
1. **Follow Protocols** - Implement CustomFieldComponent protocol
2. **Handle State** - Properly integrate with form state management
3. **Add Accessibility** - Include accessibility labels and hints
4. **Test Thoroughly** - Write comprehensive tests for custom fields

### Performance Optimization
1. **Use Lazy Loading** - Load components only when needed
2. **Optimize Rendering** - Minimize unnecessary redraws
3. **Handle Large Datasets** - Implement efficient filtering and pagination
4. **Memory Management** - Properly clean up resources

## Native Type Usage Examples

### Integer Fields
```swift
// Create an integer field
let ageField = DynamicFormField(
    id: "age",
    type: .integer,
    label: "Age",
    placeholder: "Enter your age"
)

// Use with form state
let formState = DynamicFormState()
formState.setValue(25, for: "age")
let age: Int? = formState.getValue(for: "age")
```

### Image Fields
```swift
// Create an image field
let profileField = DynamicFormField(
    id: "profilePhoto",
    type: .image,
    label: "Profile Photo"
)

// Use with mock image types for cross-platform compatibility
let mockImage = MockImage(id: "profile-123", data: imageData)
formState.setValue(mockImage, for: "profilePhoto")
let image: MockImage? = formState.getValue(for: "profilePhoto")
```

### URL Fields
```swift
// Create a URL field
let websiteField = DynamicFormField(
    id: "website",
    type: .url,
    label: "Website",
    placeholder: "https://example.com"
)

// Use with mock URL types
let mockURL = MockURL("https://example.com")
formState.setValue(mockURL, for: "website")
let url: MockURL? = formState.getValue(for: "website")
```

### Array Fields
```swift
// Create an array field
let tagsField = DynamicFormField(
    id: "tags",
    type: .array,
    label: "Tags"
)

// Use with arrays
let tags = ["swift", "ios", "ui"]
formState.setValue(tags, for: "tags")
let retrievedTags: [String]? = formState.getValue(for: "tags")
```

### Data Fields
```swift
// Create a data field
let fileField = DynamicFormField(
    id: "fileData",
    type: .data,
    label: "File Data"
)

// Use with Data
let fileData = Data("file content".utf8)
formState.setValue(fileData, for: "fileData")
let retrievedData: Data? = formState.getValue(for: "fileData")
```

### Enum Fields
```swift
// Create an enum field
let statusField = DynamicFormField(
    id: "status",
    type: .enum,
    label: "Status",
    options: ["active", "inactive", "pending"]
)

// Use with enum types
let status = MockUserStatus.active
formState.setValue(status, for: "status")
let retrievedStatus: MockUserStatus? = formState.getValue(for: "status")
```

## Troubleshooting

### Common Issues

**Rich Text Editor not formatting:**
- Ensure the field type is set to `.richtext`
- Check that the form state is properly connected
- Verify platform-specific implementation is available

**Date picker not saving values:**
- Check date formatting in the onChange handler
- Verify form state integration
- Ensure proper date formatter configuration

**File upload not working:**
- Verify allowed file types are properly configured
- Check file size limits
- Ensure drag and drop area is properly configured

**Autocomplete suggestions not showing:**
- Verify suggestions array is not empty
- Check filtering logic
- Ensure showSuggestions state is properly managed

### Debug Tips
1. **Check Form State** - Verify values are being saved correctly
2. **Test Accessibility** - Use VoiceOver to test accessibility
3. **Validate Input** - Ensure input validation is working
4. **Monitor Performance** - Use Instruments to check performance

## Future Enhancements

### Planned Features
- **Advanced Rich Text** - More formatting options and styles
- **File Preview** - Thumbnail previews for uploaded files
- **Advanced Validation** - More sophisticated validation rules
- **Theme Support** - Customizable field appearance
- **Animation Support** - Smooth transitions and animations

### Extension Points
- **Custom Validators** - Pluggable validation system
- **Custom Renderers** - Alternative rendering implementations
- **Custom Themes** - Styling and appearance customization
- **Custom Behaviors** - Field-specific behavior customization

## Conclusion

The Advanced Field Types system provides a comprehensive, accessible, and performant solution for complex form input requirements. By following the six-layer architecture and implementing proper testing, the system ensures reliability and maintainability while providing a great user experience.

The system is designed to be extensible, allowing developers to add custom field types while maintaining consistency with the existing architecture. With comprehensive accessibility support and performance optimizations, the Advanced Field Types system is ready for production use.
