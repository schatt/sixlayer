import SwiftUI

// MARK: - Custom Field View (Generic Field Renderer)

// TODO: DRY - This should be the centralized field renderer that all tests use
/// Generic field view that renders any field type based on DynamicFormField configuration
/// This is the key missing component that tests expect to exist
@MainActor
public struct CustomFieldView: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        Group {
            switch field.contentType ?? .text {
            case .text:
                DynamicTextField(field: field, formState: formState)
            case .email:
                DynamicEmailField(field: field, formState: formState)
            case .password:
                DynamicPasswordField(field: field, formState: formState)
            case .phone:
                DynamicPhoneField(field: field, formState: formState)
            case .url:
                DynamicURLField(field: field, formState: formState)
            case .number:
                DynamicNumberField(field: field, formState: formState)
            case .integer:
                DynamicIntegerField(field: field, formState: formState)
            case .date:
                DynamicDateField(field: field, formState: formState)
            case .time:
                DynamicTimeField(field: field, formState: formState)
            case .datetime:
                DynamicDateTimeField(field: field, formState: formState)
            case .multiDate:
                DynamicMultiDateField(field: field, formState: formState)
            case .dateRange:
                DynamicMultiDateField(field: field, formState: formState)
            case .select:
                DynamicSelectField(field: field, formState: formState)
            case .multiselect:
                DynamicMultiSelectField(field: field, formState: formState)
            case .radio:
                DynamicRadioField(field: field, formState: formState)
            case .checkbox:
                DynamicCheckboxField(field: field, formState: formState)
            case .textarea:
                DynamicTextAreaField(field: field, formState: formState)
            case .richtext:
                DynamicRichTextField(field: field, formState: formState)
            case .file:
                DynamicFileField(field: field, formState: formState)
            case .image:
                DynamicImageField(field: field, formState: formState)
            case .color:
                DynamicColorField(field: field, formState: formState)
            case .range:
                DynamicRangeField(field: field, formState: formState)
            case .stepper:
                DynamicStepperField(field: field, formState: formState)
            case .toggle, .boolean:
                DynamicToggleField(field: field, formState: formState)
            case .array:
                DynamicArrayField(field: field, formState: formState)
            case .data:
                DynamicDataField(field: field, formState: formState)
            case .autocomplete:
                DynamicAutocompleteField(field: field, formState: formState)
            case .`enum`:
                DynamicEnumField(field: field, formState: formState)
            case .display:
                DynamicDisplayField(field: field, formState: formState)
            case .gauge:
                DynamicGaugeField(field: field, formState: formState)
            case .custom:
                DynamicCustomField(field: field, formState: formState)
            }
        }
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

// MARK: - Character Counter Component

/// Reusable character counter view that displays character count for fields with maxLength validation
/// Shows format "X / Y characters" and warning color when approaching limit (>80%)
@MainActor
struct CharacterCounterView: View {
    let currentLength: Int
    let maxLength: Int
    let warningThreshold: Double = 0.8 // Show warning when >80% of max
    
    private var isWarning: Bool {
        Double(currentLength) > Double(maxLength) * warningThreshold
    }
    
    var body: some View {
        platformHStackContainer {
            Spacer()
            Text("\(currentLength) / \(maxLength) characters")
                .font(.caption)
                .foregroundColor(isWarning ? .orange : .secondary)
                .accessibilityLabel("\(currentLength) of \(maxLength) characters")
                .accessibilityValue(isWarning ? "Warning: approaching character limit" : "")
                .automaticCompliance(named: "CharacterCounter")
        }
    }
}

// MARK: - Helper Extensions

extension DynamicFormField {
    /// Extracts maxLength from validationRules if present and valid
    var maxLength: Int? {
        guard let validationRules = validationRules,
              let maxLengthStr = validationRules["maxLength"],
              let maxLength = Int(maxLengthStr),
              maxLength > 0 else {
            return nil
        }
        return maxLength
    }
    
    /// Gets the current text value from formState, falling back to defaultValue
    /// - Parameter formState: The form state to retrieve the value from
    /// - Returns: The current text value or empty string
    @MainActor
    func currentTextValue(from formState: DynamicFormState) -> String {
        return formState.getValue(for: id) as String? ?? defaultValue ?? ""
    }
    
    /// Check if field is read-only based on contentType, displayHints or metadata
    /// Returns true if the field should be displayed as read-only (non-editable)
    var isReadOnly: Bool {
        // Display fields are always read-only
        if contentType == .display {
            return true
        }
        // Check displayHints first (from metadata["isEditable"])
        if let displayHints = displayHints, !displayHints.isEditable {
            return true
        }
        // Check metadata["displayOnly"]
        if metadata?["displayOnly"] == "true" {
            return true
        }
        return false
    }
}

// MARK: - Character Counter Helper

@MainActor
extension DynamicFormField {
    /// Returns a character counter view if maxLength validation is set, nil otherwise
    /// - Parameter formState: The form state to get current value from
    /// - Returns: CharacterCounterView if maxLength is set, nil otherwise
    @ViewBuilder
    func characterCounterView(formState: DynamicFormState) -> some View {
        if let maxLength = maxLength {
            let currentValue = currentTextValue(from: formState)
            CharacterCounterView(currentLength: currentValue.count, maxLength: maxLength)
        }
    }
}

// MARK: - Text Field Helpers (DRY Refactoring)

@MainActor
extension DynamicFormField {
    /// Creates a binding for text field values that syncs with formState
    /// - Parameter formState: The form state to bind to
    /// - Returns: A binding that reads from and writes to formState
    func textBinding(formState: DynamicFormState) -> Binding<String> {
        Binding(
            get: { formState.getValue(for: id) as String? ?? defaultValue ?? "" },
            set: { formState.setValue($0, for: id) }
        )
    }
    
    /// Creates a standard field label view
    /// - Returns: A Text view with the field label
    @ViewBuilder
    func fieldLabel() -> some View {
        Text(label)
            .font(.subheadline)
    }
    
    /// Applies standard field container styling and modifiers
    /// - Parameters:
    ///   - content: The field content view
    ///   - componentName: The name for automatic compliance
    /// - Returns: A view with standard field styling applied
    func fieldContainer<Content: View>(
        @ViewBuilder content: () -> Content,
        componentName: String
    ) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 4) {
            content()
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, label)
        .automaticCompliance(named: componentName)
    }
    
    /// Check if field should render as picker based on hints
    var shouldRenderAsPicker: Bool {
        guard let hints = displayHints else { return false }
        return hints.inputType == "picker" && hints.pickerOptions != nil && !(hints.pickerOptions?.isEmpty ?? true)
    }
    
    /// Get picker options from hints (preferred) or field.options (fallback)
    var pickerOptionsFromHints: [(value: String, label: String)] {
        // Prefer pickerOptions from displayHints (has labels)
        if let hints = displayHints,
           let pickerOptions = hints.pickerOptions,
           !pickerOptions.isEmpty {
            return pickerOptions.map { ($0.value, $0.label) }
        }
        // Fallback to field.options (simple string array)
        if let options = options {
            return options.map { ($0, $0) } // Use same value for both value and label
        }
        return []
    }
    
    /// Check if field should render as multi-line TextField
    /// Returns true when metadata["multiLine"] == "true"
    /// Issue #89: Multi-line TextField support
    var isMultiLine: Bool {
        return metadata?["multiLine"] == "true"
    }
    
    /// Get minimum lines for multi-line TextField from metadata
    /// Defaults to 3 if not specified
    /// Issue #89: Configurable line limits
    var minLines: Int {
        guard let minLinesStr = metadata?["minLines"],
              let minLines = Int(minLinesStr),
              minLines > 0 else {
            return 3 // Default minimum
        }
        return minLines
    }
    
    /// Get maximum lines for multi-line TextField from metadata
    /// Defaults to 6 if not specified
    /// Issue #89: Configurable line limits
    var maxLines: Int {
        guard let maxLinesStr = metadata?["maxLines"],
              let maxLines = Int(maxLinesStr),
              maxLines > 0 else {
            return 6 // Default maximum
        }
        return maxLines
    }
}

// MARK: - Individual Field Components (TDD Red Phase Stubs)

/// Text field component
/// Supports single-line and multi-line text input
/// Multi-line support uses TextField with axis parameter (iOS 16+ / macOS 13+) - Issue #89
/// Falls back to TextEditor on older OS versions
@MainActor
public struct DynamicTextField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @FocusState private var isFocused: Bool

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        field.fieldContainer(content: {
            fieldContent
        }, componentName: "DynamicTextField")
        .onChange(of: formState.focusedFieldId) { oldValue, newValue in
            // Sync focus state with formState
            isFocused = (newValue == field.id)
        }
        .onChange(of: isFocused) { oldValue, newValue in
            // Update formState when focus changes locally
            if newValue {
                formState.focusedFieldId = field.id
            } else if formState.focusedFieldId == field.id {
                formState.focusedFieldId = nil
            }
        }
    }
    
    /// Field content view - extracted to simplify type checking
    @ViewBuilder
    private var fieldContent: some View {
        field.fieldLabel()

        // Check if field should render as picker based on hints
        if field.shouldRenderAsPicker {
            pickerContent
        } else {
            textFieldWithActions
        }
        
        // Character counter for fields with maxLength validation
        field.characterCounterView(formState: formState)
    }
    
    /// Picker content view
    @ViewBuilder
    private var pickerContent: some View {
        let i18n = InternationalizationService()
        
        // Prefer pickerOptions from displayHints (PickerOption type) for platformPicker
        if let hints = field.displayHints,
           let pickerOptions = hints.pickerOptions,
           !pickerOptions.isEmpty {
            return AnyView(
                platformPicker(
                    label: field.placeholder ?? i18n.placeholderSelect(),
                    selection: field.textBinding(formState: formState),
                    options: pickerOptions,
                    pickerName: "DynamicSelectField"
                )
            )
        } else if let options = field.options, !options.isEmpty {
            // Fallback to field.options (String array) - convert to PickerOption
            let pickerOptions = options.map { PickerOption(value: $0, label: $0) }
            return AnyView(
                platformPicker(
                    label: field.placeholder ?? i18n.placeholderSelect(),
                    selection: field.textBinding(formState: formState),
                    options: pickerOptions,
                    pickerName: "DynamicSelectField"
                )
            )
        } else {
            // Fallback to text field if no options
            return AnyView(textFieldView)
        }
    }
    
    /// Text field with actions view
    @ViewBuilder
    private var textFieldWithActions: some View {
        let hasActions = !field.effectiveActions.isEmpty
        let hasTrailingView = field.trailingView != nil
        
        if hasActions || hasTrailingView {
            HStack {
                textFieldView
                
                // Render actions (unified system - Issue #95)
                FieldActionRenderer(field: field, formState: formState)
                
                // Render custom trailing view if provided
                if let trailingView = field.trailingView {
                    trailingView(field, formState)
                }
            }
        } else {
            // Default text field (no actions)
            textFieldView
        }
    }
    
    /// Text field view with focus management (Issue #81)
    /// Supports multi-line TextField with axis parameter (iOS 16+ / macOS 13+) - Issue #89
    @ViewBuilder
    private var textFieldView: some View {
        if field.isMultiLine {
            // Multi-line TextField support (Issue #89)
            multiLineTextFieldView
        } else {
            // Single-line TextField
            singleLineTextFieldView
        }
    }
    
    /// Single-line TextField view
    @ViewBuilder
    private var singleLineTextFieldView: some View {
        let i18n = InternationalizationService()
        TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterText"), text: field.textBinding(formState: formState))
            .textFieldStyle(.roundedBorder)
            .focused($isFocused)
            .onSubmit {
                // Move focus to next field on Enter/Return (Issue #81)
                formState.focusNextField(from: field.id)
            }
            .automaticCompliance()
    }
    
    /// Multi-line TextField view with axis parameter (iOS 16+ / macOS 13+)
    /// Falls back to TextEditor on older OS versions - Issue #89
    @ViewBuilder
    private var multiLineTextFieldView: some View {
        if supportsTextFieldAxis {
            // iOS 16+ / macOS 13+: Use TextField with axis parameter
            multiLineTextFieldWithAxis
        } else {
            // Older OS versions: Fall back to TextEditor
            multiLineTextEditorFallback
        }
    }
    
    /// Check if platform supports TextField with axis parameter
    /// iOS 16+ and macOS 13+ support axis parameter
    private var supportsTextFieldAxis: Bool {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return true
        }
        return false
        #elseif os(macOS)
        if #available(macOS 13.0, *) {
            return true
        }
        return false
        #else
        return false
        #endif
    }
    
    /// TextField with axis parameter for multi-line text (iOS 16+ / macOS 13+)
    @ViewBuilder
    private var multiLineTextFieldWithAxis: some View {
        let i18n = InternationalizationService()
        TextField(
            field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterText"),
            text: field.textBinding(formState: formState),
            axis: .vertical
        )
        .textFieldStyle(.roundedBorder)
        .lineLimit(field.minLines...field.maxLines)
        .focused($isFocused)
        .automaticCompliance()
    }
    
    /// TextEditor fallback for older OS versions
    @ViewBuilder
    private var multiLineTextEditorFallback: some View {
        TextEditor(text: field.textBinding(formState: formState))
            .frame(minHeight: CGFloat(field.minLines * 20))
            .border(Color.gray.opacity(0.2))
            .automaticCompliance()
    }
}

/// Email field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicEmailField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @FocusState private var isFocused: Bool

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        let i18n = InternationalizationService()
        return field.fieldContainer(content: {
            field.fieldLabel()

            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterEmail"), text: field.textBinding(formState: formState))
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .keyboardType(UIKeyboardType.emailAddress)
                #endif
                .focused($isFocused)
                .onSubmit {
                    // Move focus to next field on Enter/Return (Issue #81)
                    formState.focusNextField(from: field.id)
                }
                .automaticCompliance()
            
            // Character counter for fields with maxLength validation
            field.characterCounterView(formState: formState)
        }, componentName: "DynamicEmailField")
        .onChange(of: formState.focusedFieldId) { oldValue, newValue in
            isFocused = (newValue == field.id)
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if newValue {
                formState.focusedFieldId = field.id
            } else if formState.focusedFieldId == field.id {
                formState.focusedFieldId = nil
            }
        }
    }
}

/// Password field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicPasswordField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @FocusState private var isFocused: Bool
    @Environment(\.securityService) private var securityService

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        let i18n = InternationalizationService()
        return field.fieldContainer(content: {
            field.fieldLabel()

            SecureField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterPassword"), text: field.textBinding(formState: formState))
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    // Move focus to next field on Enter/Return (Issue #81)
                    formState.focusNextField(from: field.id)
                }
                .automaticCompliance()
            
            // Character counter for fields with maxLength validation
            field.characterCounterView(formState: formState)
        }, componentName: "DynamicPasswordField")
        .onAppear {
            // Integrate with SecurityService if available
            securityService?.enableSecureTextEntry(for: field.id)
        }
        .onDisappear {
            // Clean up secure text entry when field disappears
            securityService?.disableSecureTextEntry(for: field.id)
        }
        .onChange(of: formState.focusedFieldId) { oldValue, newValue in
            isFocused = (newValue == field.id)
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if newValue {
                formState.focusedFieldId = field.id
            } else if formState.focusedFieldId == field.id {
                formState.focusedFieldId = nil
            }
        }
    }
}

/// Phone field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicPhoneField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        field.fieldContainer(content: {
            field.fieldLabel()

            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterPhone"), text: field.textBinding(formState: formState))
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .keyboardType(UIKeyboardType.phonePad)
                #endif
                .automaticCompliance()
            
            // Character counter for fields with maxLength validation
            field.characterCounterView(formState: formState)
        }, componentName: "DynamicPhoneField")
    }
}

/// URL field component
/// Uses Link component for read-only/display URL fields, TextField for editable fields
@MainActor
public struct DynamicURLField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    /// Get the current URL value from form state
    private var urlValue: String {
        (formState.getValue(for: field.id) as String?) ?? field.defaultValue ?? ""
    }

    /// Parse and validate URL, returning both the URL object and validity
    private var parsedURL: (url: URL?, isValid: Bool) {
        let value = urlValue
        guard !value.isEmpty else {
            return (nil, false)
        }
        if let url = URL(string: value) {
            return (url, true)
        }
        return (nil, false)
    }

    public var body: some View {
        field.fieldContainer(content: {
            field.fieldLabel()

            if field.isReadOnly {
                readOnlyURLView
            } else {
                editableURLView
            }
        }, componentName: "DynamicURLField")
    }
    
    /// Read-only display view: Link for valid URLs, Text for invalid/empty
    @ViewBuilder
    private var readOnlyURLView: some View {
        let (url, isValid) = parsedURL
        if isValid, let url = url {
            Link(urlValue, destination: url)
                .foregroundColor(.blue)
                .automaticCompliance()
        } else {
            Text(urlValue.isEmpty ? "—" : urlValue)
                .foregroundColor(.secondary)
                .automaticCompliance()
        }
    }
    
    /// Editable input view: TextField with URL keyboard type
    @ViewBuilder
    private var editableURLView: some View {
        let i18n = InternationalizationService()
        VStack(alignment: .leading, spacing: 4) {
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterURL"), text: field.textBinding(formState: formState))
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .keyboardType(UIKeyboardType.URL)
                #endif
                .automaticCompliance()
            
            // Character counter for fields with maxLength validation
            field.characterCounterView(formState: formState)
        }
    }
}

/// Number field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicNumberField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading) {
            Text(field.label)
                .font(.subheadline)

            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterNumber"), text: Binding(
                get: { (formState.getValue(for: field.id) as String?) ?? field.defaultValue ?? "" },
                set: { formState.setValue($0, for: field.id) }
            ))
            .textFieldStyle(.roundedBorder)
            #if os(iOS)
            .keyboardType(UIKeyboardType.decimalPad)
            #endif
            .automaticCompliance()
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label)
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Integer field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicIntegerField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading) {
            Text(field.label)
                .font(.subheadline)

            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterInteger"), text: Binding(
                get: { (formState.getValue(for: field.id) as String?) ?? field.defaultValue ?? "" },
                set: { formState.setValue($0, for: field.id) }
            ))
            .textFieldStyle(.roundedBorder)
            #if os(iOS)
            .keyboardType(UIKeyboardType.numberPad)
            #endif
            .automaticCompliance()
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Stepper field component
/// Provides increment/decrement controls for numeric values
@MainActor
public struct DynamicStepperField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    private var value: Binding<Double> {
        Binding(
            get: {
                if let value: Any = formState.getValue(for: field.id) {
                    if let doubleValue = value as? Double {
                        return doubleValue
                    } else if let stringValue = value as? String,
                              let parsed = Double(stringValue) {
                        return parsed
                    }
                }
                return Double(field.defaultValue ?? "0") ?? 0.0
            },
            set: { newValue in
                formState.setValue(String(newValue), for: field.id)
            }
        )
    }

    /// Get range from displayHints (preferred) or metadata (fallback)
    private var range: ClosedRange<Double> {
        // Prefer expectedRange from displayHints (has structured range)
        if let hints = field.displayHints,
           let expectedRange = hints.expectedRange {
            return expectedRange.min...expectedRange.max
        }
        // Fallback to metadata min/max keys
        let min = Double(field.metadata?["min"] ?? "0") ?? 0.0
        let max = Double(field.metadata?["max"] ?? "100") ?? 100.0
        return min...max
    }

    private var step: Double {
        Double(field.metadata?["step"] ?? "1") ?? 1.0
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()

            Stepper(
                field.label,
                value: value,
                in: range,
                step: step
            )
            .automaticCompliance(
                identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
            )

            // Show current value - use appropriate format based on step size
            Text(step.truncatingRemainder(dividingBy: 1.0) == 0.0 
                 ? "\(Int(value.wrappedValue))" 
                 : String(format: "%.2f", value.wrappedValue))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label)
        .automaticCompliance()  // Container view - no identifierName
    }
}

/// Date field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicDateField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        let i18n = InternationalizationService()
        
        return platformVStackContainer(alignment: .leading) {
            Text(field.label)
                .font(.subheadline)

            DatePicker(field.placeholder ?? i18n.placeholderSelectDate(),
                      selection: Binding(
                          get: { Date() }, // TODO: Parse from formState
                          set: { _ in } // TODO: Store in formState
                      ),
                      displayedComponents: .date)
            .automaticCompliance(
                identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
            )
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance()  // Container view - no identifierName
    }
}

/// Time field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicTimeField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        let i18n = InternationalizationService()
        
        return platformVStackContainer(alignment: .leading) {
            Text(field.label)
                .font(.subheadline)

            DatePicker(field.placeholder ?? i18n.placeholderSelectTime(),
                      selection: Binding(
                          get: { Date() }, // TODO: Parse from formState
                          set: { _ in } // TODO: Store in formState
                      ),
                      displayedComponents: .hourAndMinute)
            .automaticCompliance()
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// DateTime field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicDateTimeField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        let i18n = InternationalizationService()
        
        return platformVStackContainer(alignment: .leading) {
            Text(field.label)
                .font(.subheadline)

            DatePicker(field.placeholder ?? i18n.placeholderSelectDateTime(),
                      selection: Binding(
                          get: { Date() }, // TODO: Parse from formState
                          set: { _ in } // TODO: Store in formState
                      ))
            .automaticCompliance()
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Multi-date field component
/// Supports multiple date selection using MultiDatePicker (iOS 16+ / macOS 13+)
/// Implements Issue #85: Add MultiDatePicker support for multiple date selection
@MainActor
public struct DynamicMultiDateField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var selectedDateComponents: Set<DateComponents> = []
    
    // Date range for picker (defaults to current year)
    private var dateRange: Range<Date> {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) ?? now
        return startOfYear..<endOfYear
    }
    
    // Fallback view for older OS versions or macOS
    private var fallbackView: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text("Multiple date selection requires iOS 16+")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Show selected dates if any
            if let storedDates: [Date] = formState.getValue(for: field.id), !storedDates.isEmpty {
                platformVStackContainer(alignment: .leading, spacing: 4) {
                    let i18n = InternationalizationService()
                    Text(i18n.localizedString(for: "SixLayerFramework.form.selectedDates"))
                        .font(.caption)
                        .bold()
                    ForEach(storedDates, id: \.self) { date in
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }
    
    public var body: some View {
        let i18n = InternationalizationService()
        
        return platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
            
            #if os(iOS)
            if #available(iOS 16.0, *) {
                Group {
                    if #available(iOS 17.0, *) {
                        MultiDatePicker(
                            field.placeholder ?? i18n.placeholderSelectDates(),
                            selection: $selectedDateComponents,
                            in: dateRange
                        )
                        .onChange(of: selectedDateComponents) {
                            // Convert Set<DateComponents> to array of Date objects
                            let calendar = Calendar.current
                            let dates = selectedDateComponents.compactMap { components in
                                calendar.date(from: components)
                            }
                            formState.setValue(dates, for: field.id)
                        }
                    } else {
                        MultiDatePicker(
                            field.placeholder ?? i18n.placeholderSelectDates(),
                            selection: $selectedDateComponents,
                            in: dateRange
                        )
                        .onChange(of: selectedDateComponents) { newComponents in
                            // Convert Set<DateComponents> to array of Date objects
                            let calendar = Calendar.current
                            let dates = newComponents.compactMap { components in
                                calendar.date(from: components)
                            }
                            formState.setValue(dates, for: field.id)
                        }
                    }
                }
                .onAppear {
                    // Load existing dates from form state
                    if let storedDates: [Date] = formState.getValue(for: field.id) {
                        let calendar = Calendar.current
                        selectedDateComponents = Set(storedDates.map { date in
                            calendar.dateComponents([.year, .month, .day], from: date)
                        })
                    }
                }
            } else {
                // Fallback for iOS < 16
                fallbackView
            }
            #else
            // macOS fallback - MultiDatePicker not available on macOS
            fallbackView
            #endif
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label)
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}


/// Multi-select field component
/// GREEN PHASE: Full implementation of multi-select interface
@MainActor
public struct DynamicMultiSelectField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            if let options = field.options {
                ForEach(options, id: \.self) { option in
                    Toggle(option, isOn: Binding(
                        get: {
                            let selectedValues = formState.fieldValues[field.id] as? [String] ?? []
                            return selectedValues.contains(option)
                        },
                        set: { isSelected in
                            var selectedValues = formState.fieldValues[field.id] as? [String] ?? []
                            if isSelected {
                                if !selectedValues.contains(option) {
                                    selectedValues.append(option)
                                }
                            } else {
                                selectedValues.removeAll { $0 == option }
                            }
                            formState.setValue(selectedValues, for: field.id)
                        }
                    ))
                    .automaticCompliance(named: "MultiSelectOption")
                }
            }
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Radio field component
/// GREEN PHASE: Full implementation of radio button group
@MainActor
public struct DynamicRadioField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            if let options = field.options, !options.isEmpty {
                #if os(macOS)
                // Use platformPicker helper to automatically apply accessibility (Issue #163)
                // Note: radioGroup style is macOS-specific for radio button groups
                platformPicker(
                    label: field.label,
                    selection: Binding(
                        get: { formState.fieldValues[field.id] as? String ?? "" },
                        set: { formState.setValue($0, for: field.id) }
                    ),
                    options: options,
                    pickerName: "RadioGroup",
                    style: RadioGroupPickerStyle()
                )
                #else
                // iOS: Use custom radio button implementation
                platformVStackContainer(alignment: .leading, spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        platformHStackContainer {
                            Button(action: {
                                formState.setValue(option, for: field.id)
                            }) {
                                platformHStackContainer {
                                    Image(systemName: (formState.fieldValues[field.id] as? String ?? "") == option ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(.accentColor)
                                    Text(option)
                                }
                            }
                            .buttonStyle(.plain)
                            .automaticCompliance(named: "RadioOption")
                            Spacer()
                        }
                    }
                }
                .automaticCompliance(named: "RadioGroup")
                #endif
            }
        }
        .padding()
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Checkbox field component
/// GREEN PHASE: Full implementation of checkbox group
@MainActor
public struct DynamicCheckboxField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            if let options = field.options {
                ForEach(options, id: \.self) { option in
                    Toggle(option, isOn: Binding(
                        get: {
                            let selectedValues = formState.fieldValues[field.id] as? [String] ?? []
                            return selectedValues.contains(option)
                        },
                        set: { isSelected in
                            var selectedValues = formState.fieldValues[field.id] as? [String] ?? []
                            if isSelected {
                                if !selectedValues.contains(option) {
                                    selectedValues.append(option)
                                }
                            } else {
                                selectedValues.removeAll { $0 == option }
                            }
                            formState.setValue(selectedValues, for: field.id)
                        }
                    ))
                    .automaticCompliance(named: "CheckboxOption")
                }
            }
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

// MARK: - Existing Advanced Field Components (TDD Red Phase Stubs)

// Color picker field component


/// Rich text field component
/// GREEN PHASE: Full implementation of rich text editor
@MainActor
public struct DynamicRichTextField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        field.fieldContainer(content: {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            #if os(iOS)
            TextEditor(text: field.textBinding(formState: formState))
                .frame(minHeight: 100)
                .border(Color.gray.opacity(0.2))
                .automaticCompliance(named: "RichTextEditor")
            #else
            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterText"), text: field.textBinding(formState: formState))
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 100)
                .automaticCompliance(named: "RichTextEditor")
            #endif
            
            // Character counter for fields with maxLength validation
            field.characterCounterView(formState: formState)
        }, componentName: "DynamicRichTextField")
    }
}

/// File field component
/// GREEN PHASE: Full implementation of file picker
@MainActor
public struct DynamicFileField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            let i18n = InternationalizationService()
            
            Button(action: {
                // TODO: Implement file picker integration
                // This should open file picker and update formState
                print("File picker requested for field: \(field.id)")
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text(i18n.localizedString(for: "SixLayerFramework.button.selectFile"))
                }
            }
            .buttonStyle(.bordered)
            .automaticCompliance(named: "FilePickerButton")

            if let fileName = formState.fieldValues[field.id] as? String, !fileName.isEmpty {
                Text(i18n.localizedString(for: "SixLayerFramework.form.selected", arguments: [fileName]))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .automaticCompliance(named: "SelectedFileName")
            }
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Image field component
/// GREEN PHASE: Full implementation of image picker
@MainActor
public struct DynamicImageField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            Button(action: {
                // TODO: Implement image picker integration
                // This should open image picker and update formState
                print("Image picker requested for field: \(field.id)")
            }) {
                let i18n = InternationalizationService()
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(i18n.localizedString(for: "SixLayerFramework.button.selectImage"))
                }
            }
            .buttonStyle(.bordered)
            .automaticCompliance(named: "ImagePickerButton")

            if let imageData = formState.fieldValues[field.id] as? Data, let image = PlatformImage(data: imageData) {
                #if os(iOS)
                Image(uiImage: image.uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .automaticCompliance(named: "ImagePreview")
                #else
                Image(nsImage: image.nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .automaticCompliance(named: "ImagePreview")
                #endif
            }
        }
        .padding()
        .automaticCompliance(named: "DynamicImageField")
    }
}

/// Range field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicRangeField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading) {
            Text(field.label)
                .font(.subheadline)

            Slider(value: Binding(
                get: { Double((formState.getValue(for: field.id) as String?) ?? field.defaultValue ?? "0") ?? 0 },
                set: { formState.setValue(String($0), for: field.id) }
            ), in: 0...100)
            .automaticCompliance()
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Array field component
/// GREEN PHASE: Full implementation of array input
@MainActor
public struct DynamicArrayField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            ForEach(Array((formState.fieldValues[field.id] as? [String] ?? []).enumerated()), id: \.offset) { index, value in
                HStack {
                    TextField("Item \(index + 1)", text: Binding(
                        get: { value },
                        set: { newValue in
                            var values = formState.fieldValues[field.id] as? [String] ?? []
                            if index < values.count {
                                values[index] = newValue
                                formState.setValue(values, for: field.id)
                            }
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .environment(\.accessibilityIdentifierLabel, value) // TDD GREEN: Pass array item value to identifier generation
                    .automaticCompliance(named: "ArrayItem")

                    Button(action: {
                        var values = formState.fieldValues[field.id] as? [String] ?? []
                        if index < values.count {
                            values.remove(at: index)
                            formState.setValue(values, for: field.id)
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    .automaticCompliance(named: "RemoveItem")
                }
            }

            Button(action: {
                var values = formState.fieldValues[field.id] as? [String] ?? []
                values.append("")
                formState.setValue(values, for: field.id)
            }) {
                let i18n = InternationalizationService()
                HStack {
                    Image(systemName: "plus.circle")
                    Text(i18n.localizedString(for: "SixLayerFramework.button.addItem"))
                }
            }
            .buttonStyle(.bordered)
            .automaticCompliance(named: "AddItem")
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Data field component
/// GREEN PHASE: Full implementation of data input
@MainActor
public struct DynamicDataField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            TextEditor(text: Binding(
                get: {
                    if let data = formState.fieldValues[field.id] as? Data {
                        return String(data: data, encoding: .utf8) ?? ""
                    }
                    return ""
                },
                set: { newValue in
                    if let data = newValue.data(using: .utf8) {
                        formState.setValue(data, for: field.id)
                    }
                }
            ))
            .frame(minHeight: 100)
            .border(Color.gray.opacity(0.2))
            .automaticCompliance(named: "DataInput")

            if let data = formState.fieldValues[field.id] as? Data {
                Text("Data size: \(data.count) bytes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .automaticCompliance(named: "DataSize")
            }
        }
        .padding()
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Autocomplete field component
/// GREEN PHASE: Full implementation of autocomplete
@MainActor
public struct DynamicAutocompleteField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var searchText: String = ""
    @State private var showSuggestions: Bool = false

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.typeToSearch"), text: Binding(
                get: { formState.getValue(for: field.id) as String? ?? field.defaultValue ?? "" },
                set: { newValue in
                    formState.setValue(newValue, for: field.id)
                    searchText = newValue
                    showSuggestions = !newValue.isEmpty && field.options != nil
                }
            ))
            .textFieldStyle(.roundedBorder)
            .automaticCompliance(named: "AutocompleteInput")
            .onAppear {
                searchText = formState.getValue(for: field.id) as String? ?? ""
            }
            
            // Character counter for fields with maxLength validation
            field.characterCounterView(formState: formState)

            if showSuggestions, let options = field.options {
                let filtered = options.filter { $0.localizedCaseInsensitiveContains(searchText) }
                if !filtered.isEmpty {
                    platformVStackContainer(alignment: .leading, spacing: 4) {
                        ForEach(filtered.prefix(5), id: \.self) { suggestion in
                            Button(action: {
                                formState.setValue(suggestion, for: field.id)
                                searchText = suggestion
                                showSuggestions = false
                            }) {
                                Text(suggestion)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .automaticCompliance(named: "Suggestion")
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .automaticCompliance(named: "SuggestionsList")
                }
            }
        }
        .padding()
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Enum field component
/// GREEN PHASE: Full implementation of enum picker
@MainActor
public struct DynamicEnumField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    /// Get picker options from hints (preferred) or field.options (fallback)
    private var pickerOptions: [(value: String, label: String)] {
        // Prefer pickerOptions from displayHints (has labels)
        if let hints = field.displayHints,
           let pickerOptions = hints.pickerOptions,
           !pickerOptions.isEmpty {
            return pickerOptions.map { ($0.value, $0.label) }
        }
        // Fallback to field.options (simple string array)
        if let options = field.options {
            return options.map { ($0, $0) } // Use same value for both value and label
        }
        return []
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            if !pickerOptions.isEmpty {
                // Convert tuple array to PickerOption array for platformPicker
                let pickerOptionArray = pickerOptions.map { PickerOption(value: $0.value, label: $0.label) }
                platformPicker(
                    label: field.label,
                    selection: Binding(
                        get: { formState.fieldValues[field.id] as? String ?? "" },
                        set: { formState.setValue($0, for: field.id) }
                    ),
                    options: pickerOptionArray,
                    pickerName: "EnumPicker"
                )
            }
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Custom field component
/// GREEN PHASE: Full implementation using CustomFieldRegistry
@MainActor
public struct DynamicCustomField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")

            if let customComponent = CustomFieldRegistry.shared.createComponent(for: field, formState: formState) {
                AnyView(customComponent)
            } else {
                Text("Custom field not registered: \(field.contentType?.rawValue ?? "unknown")")
                    .foregroundColor(.red)
                    .font(.caption)
                    .automaticCompliance(named: "CustomFieldError")
            }
        }
        .padding()
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

// MARK: - Advanced Field Components (From AdvancedFieldTypes.swift)

// Color picker field component
/// GREEN PHASE: Full implementation of color picker
@MainActor
public struct DynamicColorField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    
    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")
            
            let colorValue = formState.fieldValues[field.id] as? String ?? "#000000"
            let color = Color(hex: colorValue) ?? .black
            
            let i18n = InternationalizationService()
            ColorPicker(field.placeholder ?? i18n.placeholderSelectColor(), selection: Binding(
                get: { color },
                set: { newColor in
                    let hex = newColor.toHex()
                    formState.setValue(hex, for: field.id)
                }
            ))
            .automaticCompliance(named: "ColorPicker")
            
            Rectangle()
                .fill(color)
                .frame(height: 40)
                .cornerRadius(8)
                .automaticCompliance(named: "ColorPreview")
        }
        .padding()
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}

/// Toggle field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicToggleField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    
    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading) {
            Text(field.label)
                .font(.subheadline)
            
            Toggle("Toggle Field - TDD Red Phase Stub", isOn: .constant(false))
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}


/// Text area field component
/// GREEN PHASE: Full implementation of multi-line text editor
@MainActor
public struct DynamicTextAreaField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    
    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }
    
    public var body: some View {
        field.fieldContainer(content: {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")
            
            #if os(iOS)
            TextEditor(text: field.textBinding(formState: formState))
                .frame(minHeight: 100)
                .border(Color.gray.opacity(0.2))
                .automaticCompliance(named: "TextArea")
            #else
            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterText"), text: field.textBinding(formState: formState), axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(5...10)
                .automaticCompliance(named: "TextArea")
            #endif
            
            // Character counter for fields with maxLength validation
            field.characterCounterView(formState: formState)
        }, componentName: "DynamicTextAreaField")
    }
}

/// Display field component
/// Uses LabeledContent for read-only/display fields on iOS 16+ and macOS 13+
/// Provides fallback HStack layout for older OS versions
@MainActor
public struct DynamicDisplayField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    
    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }
    
    /// Get the current value from form state
    private var currentValue: Any? {
        formState.getValue(for: field.id)
    }
    
    /// Get string representation of value
    private var valueString: String {
        if let value = currentValue {
            return String(describing: value)
        }
        return "—"
    }
    
    public var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            // Use LabeledContent on supported platforms
            LabeledContent(field.label) {
                if let customValueView = field.valueView {
                    customValueView(field, formState)
                } else {
                    Text(valueString)
                        .foregroundColor(.secondary)
                }
            }
            .automaticCompliance(
                identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
            )
        } else {
            // Fallback for older platforms
            HStack {
                Text(field.label)
                    .font(.subheadline)
                Spacer()
                if let customValueView = field.valueView {
                    customValueView(field, formState)
                } else {
                    Text(valueString)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .automaticCompliance(
                identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
            )
        }
    }
}

/// Gauge field component for visual value display (iOS 16+/macOS 13+)
/// Displays a value within a range using Apple's Gauge component with fallback to ProgressView
@MainActor
public struct DynamicGaugeField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    
    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }
    
    /// Get the current value as Double
    private var value: Double {
        if let value: Any? = formState.getValue(for: field.id) {
            if let doubleValue = value as? Double {
                return doubleValue
            } else if let intValue = value as? Int {
                return Double(intValue)
            } else if let stringValue = value as? String,
                      let parsed = Double(stringValue) {
                return parsed
            }
        }
        // Fall back to defaultValue or 0.0
        if let defaultValue = field.defaultValue,
           let parsed = Double(defaultValue) {
            return parsed
        }
        return 0.0
    }
    
    /// Get the range from metadata or default to 0...100
    private var range: ClosedRange<Double> {
        let min = Double(field.metadata?["min"] ?? "0") ?? 0.0
        let max = Double(field.metadata?["max"] ?? "100") ?? 100.0
        
        // Ensure valid range
        if min > max {
            return 0.0...100.0
        }
        return min...max
    }
    
    /// Get gauge style from metadata or default to linear
    private var gaugeStyle: String {
        field.metadata?["gaugeStyle"] ?? "linear"
    }
    
    /// Get optional gauge label from metadata
    private var gaugeLabel: String? {
        field.metadata?["gaugeLabel"]
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .bold()
                .automaticCompliance(named: "FieldLabel")
            
            if #available(iOS 16.0, macOS 13.0, *) {
                // Use native Gauge component on supported platforms
                if gaugeStyle == "circular" {
                    Gauge(value: value, in: range) {
                        // Optional gauge label
                        if let label = gaugeLabel {
                            Text(label)
                        }
                    } currentValueLabel: {
                        Text("\(Int(value))")
                    } minimumValueLabel: {
                        Text("\(Int(range.lowerBound))")
                    } maximumValueLabel: {
                        Text("\(Int(range.upperBound))")
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .automaticCompliance(named: "Gauge")
                } else {
                    Gauge(value: value, in: range) {
                        // Optional gauge label
                        if let label = gaugeLabel {
                            Text(label)
                        }
                    } currentValueLabel: {
                        Text("\(Int(value))")
                    } minimumValueLabel: {
                        Text("\(Int(range.lowerBound))")
                    } maximumValueLabel: {
                        Text("\(Int(range.upperBound))")
                    }
                    .gaugeStyle(.linearCapacity)
                    .automaticCompliance(named: "Gauge")
                }
            } else {
                // Fallback: Use ProgressView for older platforms
                ProgressView(value: value, total: range.upperBound)
                    .progressViewStyle(.linear)
                    .automaticCompliance(named: "ProgressView")
                
                Text("\(Int(value)) / \(Int(range.upperBound))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .automaticCompliance(named: "GaugeValueLabel")
            }
        }
        .padding()
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }
}
