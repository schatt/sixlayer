import SwiftUI
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

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
            case .number, .decimal:
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
        .automaticComplianceForDynamicFormField(field)
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

    /// Segment used for accessibility identifiers and as the default localization key base (Issue #194).
    ///
    /// Resolution: metadata `accessibilityIdentifierName` (non-empty) if set; otherwise `sanitizeLabelText(label)`;
    /// if that is empty, `id`.
    public var effectiveAccessibilityIdentifierSegment: String {
        if let raw = metadata?["accessibilityIdentifierName"] {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        let sanitized = sanitizeLabelText(label)
        if !sanitized.isEmpty { return sanitized }
        return id
    }
    
    /// Creates a placeholder for the field label when used inside field components.
    /// Parent (DynamicFormFieldView) owns the single visible label (Issue #189). Use this so a11y still gets label via environment/identifierName.
    @ViewBuilder
    func fieldLabel() -> some View {
        EmptyView()
    }
    
    /// Applies standard field container styling and modifiers
    /// - Parameters:
    ///   - content: The field content view
    ///   - componentName: The name for automatic compliance
    /// - Returns: A view with standard field styling applied
    func fieldContainer<Content: View>(
        @ViewBuilder content: @escaping () -> Content,
        componentName: String
    ) -> some View {
        DynamicFormFieldStandardContainer(field: self, componentName: componentName, content: content)
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

// MARK: - Field container shell (Issue #194)

@MainActor
struct DynamicFormFieldStandardContainer<Content: View>: View {
    let field: DynamicFormField
    let componentName: String
    private let content: () -> Content
    @Environment(\.dynamicFormFieldResolvedDisplayLabel) private var resolvedDisplayLabel

    init(field: DynamicFormField, componentName: String, @ViewBuilder content: @escaping () -> Content) {
        self.field = field
        self.componentName = componentName
        self.content = content
    }

    var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 4) {
            content()
        }
        .padding()
        .environment(\.accessibilityIdentifierLabel, resolvedDisplayLabel ?? field.label)
        .automaticCompliance(named: componentName)
    }
}

// MARK: - Dynamic form field automatic compliance (#194)

@MainActor
extension View {
    /// Applies `automaticCompliance` using the field’s accessibility / localization segment as `identifierName` (Issue #194).
    func automaticComplianceForDynamicFormField(
        _ field: DynamicFormField,
        identifierElementType: String? = nil,
        identifierLabel: String? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityTraits: AccessibilityTraits? = nil,
        accessibilityValue: String? = nil,
        accessibilitySortPriority: Double? = nil
    ) -> some View {
        automaticCompliance(
            identifierName: field.effectiveAccessibilityIdentifierSegment,
            identifierElementType: identifierElementType,
            identifierLabel: identifierLabel,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            accessibilityTraits: accessibilityTraits,
            accessibilityValue: accessibilityValue,
            accessibilitySortPriority: accessibilitySortPriority
        )
    }
}

// MARK: - Localization Key Helpers

/// Role for field-localized strings (label, placeholder, help text, etc.).
public enum FieldLocalizationRole: String, Sendable {
    case label
    case placeholder
    case help
    case accessibilityLabel
    case accessibilityHint
}

@MainActor
extension DynamicFormField {
    /// Resolve the base localization key for this field.
    ///
    /// Resolution priority (highest first):
    /// 1. Explicit `localizationKeyBaseOverride` parameter (non-empty)
    /// 2. Metadata `localizationKeyBase` (non-empty)
    /// 3. Explicit `accessibilityId` parameter (non-empty), else `effectiveAccessibilityIdentifierSegment`
    /// 4. `id` if the segment is empty
    ///
    /// An optional `namespace` (e.g. model or screen name) is prepended when provided.
    public func localizationBaseKey(
        namespace: String? = nil,
        localizationKeyBaseOverride: String? = nil,
        accessibilityId: String? = nil
    ) -> String {
        let metadataBase = metadata?["localizationKeyBase"]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 }

        let passedOverride = localizationKeyBaseOverride
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 }

        let effectiveOverride = passedOverride ?? metadataBase

        let segment: String
        if let accessibilityId {
            let trimmed = accessibilityId.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                segment = trimmed
            } else {
                segment = effectiveAccessibilityIdentifierSegment
            }
        } else {
            segment = effectiveAccessibilityIdentifierSegment
        }

        let base: String
        if let o = effectiveOverride, !o.isEmpty {
            base = o
        } else if !segment.isEmpty {
            base = segment
        } else {
            base = id
        }

        if let namespace, !namespace.isEmpty {
            let ns = namespace.trimmingCharacters(in: .whitespacesAndNewlines)
            return ns.isEmpty ? base : "\(ns).\(base)"
        } else {
            return base
        }
    }
    
    /// Build a localization key for a specific role (label, placeholder, etc.).
    ///
    /// This is a pure helper and does not hit bundles; callers inject their own resolver.
    public func localizationKey(
        role: FieldLocalizationRole,
        namespace: String? = nil,
        localizationKeyBaseOverride: String? = nil,
        accessibilityId: String? = nil
    ) -> String {
        let base = localizationBaseKey(
            namespace: namespace,
            localizationKeyBaseOverride: localizationKeyBaseOverride,
            accessibilityId: accessibilityId
        )
        return "\(base).\(role.rawValue)"
    }
    
    /// Resolve a localized string for this field and role using a provided resolver closure.
    ///
    /// - Parameters:
    ///   - role: The logical role for the string (label, placeholder, etc.).
    ///   - resolver: Function that maps a localization key to a localized string.
    ///   - namespace: Optional namespace prefix (e.g. model or screen name).
    ///   - localizationKeyBaseOverride: Optional explicit base key override.
    ///   - accessibilityId: Optional accessibility identifier to use as default base key.
    ///   - fallback: Fallback string to use when resolver returns the key unchanged.
    /// - Returns: Localized string, or `fallback` when no translation is found.
    public func resolveLocalizedString(
        role: FieldLocalizationRole,
        resolver: (String) -> String,
        namespace: String? = nil,
        localizationKeyBaseOverride: String? = nil,
        accessibilityId: String? = nil,
        fallback: String?
    ) -> String? {
        let key = localizationKey(
            role: role,
            namespace: namespace,
            localizationKeyBaseOverride: localizationKeyBaseOverride,
            accessibilityId: accessibilityId
        )
        let value = resolver(key)
        // If resolver returns the key itself, treat it as "not localized" and fall back.
        if value == key {
            return fallback
        }
        return value
    }

    /// Resolved display string for SwiftUI when an optional resolver is injected (Issue #194).
    ///
    /// When `resolver` is `nil`, returns `fallback` so existing forms behave unchanged.
    public func resolvedLocalizedDisplayString(
        role: FieldLocalizationRole,
        resolver: DynamicFormFieldLocalizationResolver?,
        namespace: String?,
        fallback: String
    ) -> String {
        guard let resolver else { return fallback }
        return resolveLocalizedString(
            role: role,
            resolver: resolver.lookup,
            namespace: namespace,
            localizationKeyBaseOverride: nil,
            accessibilityId: nil,
            fallback: fallback
        ) ?? fallback
    }

    /// Placeholder text with optional key-based localization (`base.placeholder`).
    public func resolvedPlaceholderDisplay(
        frameworkDefault: String,
        resolver: DynamicFormFieldLocalizationResolver?,
        namespace: String?
    ) -> String {
        let fallback = placeholder ?? frameworkDefault
        return resolvedLocalizedDisplayString(
            role: .placeholder,
            resolver: resolver,
            namespace: namespace,
            fallback: fallback
        )
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
    @Environment(\.dynamicFormFieldLocalizationResolver) private var localizationResolver
    @Environment(\.dynamicFormLocalizationNamespace) private var localizationNamespace

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
        let pickerLabel = field.resolvedPlaceholderDisplay(
            frameworkDefault: i18n.placeholderSelect(),
            resolver: localizationResolver,
            namespace: localizationNamespace
        )

        // Prefer pickerOptions from displayHints (PickerOption type) for platformPicker (no AnyView — Issue 178)
        if let hints = field.displayHints,
           let pickerOptions = hints.pickerOptions,
           !pickerOptions.isEmpty {
            platformPicker(
                label: pickerLabel,
                selection: field.textBinding(formState: formState),
                options: pickerOptions,
                pickerName: "DynamicSelectField"
            )
        } else if let options = field.options, !options.isEmpty {
            // Fallback to field.options (String array) - convert to PickerOption
            let pickerOptions = options.map { PickerOption(value: $0, label: $0) }
            platformPicker(
                label: pickerLabel,
                selection: field.textBinding(formState: formState),
                options: pickerOptions,
                pickerName: "DynamicSelectField"
            )
        } else {
            // Fallback to text field if no options
            textFieldView
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
        let placeholderText = field.resolvedPlaceholderDisplay(
            frameworkDefault: i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterText"),
            resolver: localizationResolver,
            namespace: localizationNamespace
        )
        TextField(placeholderText, text: field.textBinding(formState: formState))
            .platformTextFieldStyle()
            .focused($isFocused)
            .onSubmit {
                // Move focus to next field on Enter/Return (Issue #81)
                formState.focusNextField(from: field.id)
            }
            .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
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
        let placeholderText = field.resolvedPlaceholderDisplay(
            frameworkDefault: i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterText"),
            resolver: localizationResolver,
            namespace: localizationNamespace
        )
        TextField(
            placeholderText,
            text: field.textBinding(formState: formState),
            axis: .vertical
        )
        .platformTextFieldStyle()
        .lineLimit(field.minLines...field.maxLines)
        .focused($isFocused)
        .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
    }
    
    /// TextEditor fallback for older OS versions
    @ViewBuilder
    private var multiLineTextEditorFallback: some View {
        #if os(tvOS)
        EmptyView().platformTextEditor(text: field.textBinding(formState: formState), prompt: "")
            .frame(minHeight: CGFloat(field.minLines * 20))
            .border(Color.gray.opacity(0.2))
            .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
        #elseif os(watchOS)
        TextField("", text: field.textBinding(formState: formState), axis: .vertical)
            .platformTextFieldStyle()
            .lineLimit(field.minLines...field.maxLines)
            .frame(minHeight: CGFloat(field.minLines * 20))
            .border(Color.gray.opacity(0.2))
            .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
        #else
        TextEditor(text: field.textBinding(formState: formState))
            .frame(minHeight: CGFloat(field.minLines * 20))
            .border(Color.gray.opacity(0.2))
            .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
        #endif
    }
}

/// Email field component
/// TDD RED PHASE: This is a stub implementation for testing
@MainActor
public struct DynamicEmailField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @FocusState private var isFocused: Bool
    @Environment(\.dynamicFormFieldLocalizationResolver) private var localizationResolver
    @Environment(\.dynamicFormLocalizationNamespace) private var localizationNamespace

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        let i18n = InternationalizationService()
        let placeholderText = field.resolvedPlaceholderDisplay(
            frameworkDefault: i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterEmail"),
            resolver: localizationResolver,
            namespace: localizationNamespace
        )
        return field.fieldContainer(content: {
            field.fieldLabel()

            TextField(placeholderText, text: field.textBinding(formState: formState))
                .platformTextFieldStyle()
                #if os(iOS)
                .keyboardType(UIKeyboardType.emailAddress)
                #endif
                .focused($isFocused)
                .onSubmit {
                    // Move focus to next field on Enter/Return (Issue #81)
                    formState.focusNextField(from: field.id)
                }
                .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            
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
    @Environment(\.dynamicFormFieldLocalizationResolver) private var localizationResolver
    @Environment(\.dynamicFormLocalizationNamespace) private var localizationNamespace

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        let i18n = InternationalizationService()
        let placeholderText = field.resolvedPlaceholderDisplay(
            frameworkDefault: i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterPassword"),
            resolver: localizationResolver,
            namespace: localizationNamespace
        )
        return field.fieldContainer(content: {
            field.fieldLabel()

            SecureField(placeholderText, text: field.textBinding(formState: formState))
                .platformTextFieldStyle()
                .focused($isFocused)
                .onSubmit {
                    // Move focus to next field on Enter/Return (Issue #81)
                    formState.focusNextField(from: field.id)
                }
                .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            
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
                .platformTextFieldStyle()
                #if os(iOS)
                .keyboardType(UIKeyboardType.phonePad)
                #endif
                .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            
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
        let value = urlValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return (nil, false)
        }
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil else {
            return (nil, false)
        }
        return (url, true)
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
                .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
        } else {
            Text(urlValue.isEmpty ? "—" : urlValue)
                .foregroundColor(.secondary)
                .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
        }
    }
    
    /// Editable input view: TextField with URL keyboard type
    @ViewBuilder
    private var editableURLView: some View {
        let i18n = InternationalizationService()
        VStack(alignment: .leading, spacing: 4) {
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterURL"), text: field.textBinding(formState: formState))
                .platformTextFieldStyle()
                #if os(iOS)
                .keyboardType(UIKeyboardType.URL)
                #endif
                .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            
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
        field.fieldContainer(content: {
            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterNumber"), text: field.numericTextBinding(formState: formState))
            .platformTextFieldStyle()
            #if os(iOS)
            .keyboardType(UIKeyboardType.decimalPad)
            #endif
            .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
        }, componentName: "DynamicNumberField")
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
        field.fieldContainer(content: {
            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterInteger"), text: field.numericTextBinding(formState: formState))
            .platformTextFieldStyle()
            #if os(iOS)
            .keyboardType(UIKeyboardType.numberPad)
            #endif
            .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
        }, componentName: "DynamicIntegerField")
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
            EmptyView().platformStepperInput(
                label: field.label,
                value: value,
                in: range,
                step: step
            )
            .dynamicFormFieldVoiceOverLabel(field)
            .automaticComplianceForDynamicFormField(
                field,
                identifierElementType: "Stepper",
                accessibilityValue: step.truncatingRemainder(dividingBy: 1.0) == 0.0
                    ? "\(Int(value.wrappedValue))"
                    : String(format: "%.2f", value.wrappedValue)
            )

            // Show current value - use appropriate format based on step size
            Text(step.truncatingRemainder(dividingBy: 1.0) == 0.0 
                 ? "\(Int(value.wrappedValue))" 
                 : String(format: "%.2f", value.wrappedValue))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .dynamicFormFieldAccessibilityLabel(field)
        .automaticCompliance(named: "DynamicStepperField")
    }
}

/// Date field component; reads and writes `Date` (or interoperable stored values) in ``DynamicFormState``.
@MainActor
public struct DynamicDateField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    private var selectedDate: Binding<Date> {
        Binding(
            get: {
                DynamicFormStoredDateValue.date(fromStoredValue: formState.fieldValues[field.id]) ?? Date()
            },
            set: { formState.setValue($0, for: field.id) }
        )
    }

    public var body: some View {
        let i18n = InternationalizationService()

        return platformVStackContainer(alignment: .leading) {
            #if os(tvOS)
            if DynamicFormStoredDateValue.date(fromStoredValue: formState.fieldValues[field.id]) != nil {
                EmptyView().platformDateInput(
                    selection: selectedDate,
                    label: field.placeholder ?? i18n.placeholderSelectDate()
                )
                .automaticComplianceForDynamicFormField(field)
            } else {
                Text(field.placeholder ?? i18n.placeholderSelectDate())
                    .foregroundStyle(.secondary)
                    .automaticComplianceForDynamicFormField(field)
            }
            #else
            DatePicker(
                field.placeholder ?? i18n.placeholderSelectDate(),
                selection: selectedDate,
                displayedComponents: .date
            )
            .automaticComplianceForDynamicFormField(field)
            #endif
        }
        .padding()
        .dynamicFormFieldAccessibilityLabel(field) // Issue #194: resolved label when localized
        .automaticCompliance(named: "DynamicDateField")
    }
}

/// Time field component; reads and writes `Date` in ``DynamicFormState`` (time-of-day uses the date’s clock components).
@MainActor
public struct DynamicTimeField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    private var selectedTime: Binding<Date> {
        Binding(
            get: {
                DynamicFormStoredDateValue.date(fromStoredValue: formState.fieldValues[field.id]) ?? Date()
            },
            set: { formState.setValue($0, for: field.id) }
        )
    }

    public var body: some View {
        let i18n = InternationalizationService()

        return platformVStackContainer(alignment: .leading) {
            #if os(tvOS)
            if DynamicFormStoredDateValue.date(fromStoredValue: formState.fieldValues[field.id]) != nil {
                EmptyView().platformTimeInput(
                    selection: selectedTime,
                    label: field.placeholder ?? i18n.placeholderSelectTime()
                )
                .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            } else {
                Text(field.placeholder ?? i18n.placeholderSelectTime())
                    .foregroundStyle(.secondary)
                    .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            }
            #else
            DatePicker(
                field.placeholder ?? i18n.placeholderSelectTime(),
                selection: selectedTime,
                displayedComponents: .hourAndMinute
            )
            .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            #endif
        }
        .padding()
        .dynamicFormFieldAccessibilityLabel(field) // Issue #194: resolved label when localized
        .automaticComplianceForDynamicFormField(field)
    }
}

/// Date-and-time field component; reads and writes `Date` in ``DynamicFormState``.
@MainActor
public struct DynamicDateTimeField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    private var selectedDateTime: Binding<Date> {
        Binding(
            get: {
                DynamicFormStoredDateValue.date(fromStoredValue: formState.fieldValues[field.id]) ?? Date()
            },
            set: { formState.setValue($0, for: field.id) }
        )
    }

    public var body: some View {
        let i18n = InternationalizationService()

        return platformVStackContainer(alignment: .leading) {
            #if os(tvOS)
            if DynamicFormStoredDateValue.date(fromStoredValue: formState.fieldValues[field.id]) != nil {
                EmptyView().platformDateTimeInput(
                    selection: selectedDateTime,
                    label: field.placeholder ?? i18n.placeholderSelectDateTime()
                )
                .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            } else {
                Text(field.placeholder ?? i18n.placeholderSelectDateTime())
                    .foregroundStyle(.secondary)
                    .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            }
            #else
            DatePicker(
                field.placeholder ?? i18n.placeholderSelectDateTime(),
                selection: selectedDateTime
            )
            .automaticComplianceForDynamicFormField(field, identifierElementType: "TextField")
            #endif
        }
        .padding()
        .dynamicFormFieldAccessibilityLabel(field) // Issue #194: resolved label when localized
        .automaticComplianceForDynamicFormField(field)
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
        .dynamicFormFieldAccessibilityLabel(field)
        .automaticComplianceForDynamicFormField(field)
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
        field.fieldContainer(content: {
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
        }, componentName: "DynamicMultiSelectField")
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
        field.fieldContainer(content: {
            if let options = field.options, !options.isEmpty {
                #if os(macOS)
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
        }, componentName: "DynamicRadioField")
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
        field.fieldContainer(content: {
            if let options = field.options, !options.isEmpty {
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
            } else {
                Toggle(isOn: Binding(
                    get: {
                        if let value: Any = formState.getValue(for: field.id) {
                            if let boolValue = value as? Bool { return boolValue }
                            if let stringValue = value as? String {
                                return stringValue.lowercased() == "true" || stringValue == "1"
                            }
                        }
                        return field.defaultValue?.lowercased() == "true" || field.defaultValue == "1"
                    },
                    set: { formState.setValue($0, for: field.id) }
                )) {
                    Text(field.label)
                }
                .automaticComplianceForDynamicFormField(field, identifierElementType: "Toggle")
            }
        }, componentName: "DynamicCheckboxField")
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
            #if os(iOS)
            TextEditor(text: field.textBinding(formState: formState))
                .frame(minHeight: 100)
                .border(Color.gray.opacity(0.2))
                .automaticCompliance(named: "RichTextEditor")
            #else
            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterText"), text: field.textBinding(formState: formState))
                .platformTextFieldStyle()
                .frame(minHeight: 100)
                .automaticCompliance(named: "RichTextEditor")
            #endif
            
            // Character counter for fields with maxLength validation
            field.characterCounterView(formState: formState)
        }, componentName: "DynamicRichTextField")
    }
}

/// File field component; uses SwiftUI `fileImporter` on iOS, macOS, and visionOS (``platformFileImporter``).
@MainActor
public struct DynamicFileField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var showFileImporter = false

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        let i18n = InternationalizationService()
        return platformVStackContainer(alignment: .leading, spacing: 8) {
            #if os(iOS) || os(macOS) || os(visionOS)
            Button(action: { showFileImporter = true }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text(i18n.localizedString(for: "SixLayerFramework.button.selectFile"))
                }
            }
            .buttonStyle(.bordered)
            .automaticCompliance(named: "FilePickerButton")
            #else
            Text(i18n.localizedString(for: "SixLayerFramework.imagePicker.notAvailable"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .automaticCompliance(named: "FilePickerUnavailable")
            #endif

            if let storedPath = formState.fieldValues[field.id] as? String, !storedPath.isEmpty {
                let displayName = URL(fileURLWithPath: storedPath).lastPathComponent
                Text(i18n.localizedString(for: "SixLayerFramework.form.selected", arguments: [displayName]))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .automaticCompliance(named: "SelectedFileName")
            }
        }
        .padding()
        .dynamicFormFieldAccessibilityLabel(field) // Issue #194: resolved label when localized
        .automaticComplianceForDynamicFormField(field)
        #if os(iOS) || os(macOS) || os(visionOS)
        .platformFileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false,
            onCompletion: { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        let path = try dynamicFormCopyImportedFileToCachesDirectory(from: url)
                        formState.setValue(path, for: field.id)
                    } catch {
                        // Selection failed (e.g. copy); leave existing value unchanged.
                    }
                case .failure:
                    break
                }
            }
        )
        #endif
    }
}

/// Image field component; presents ``UnifiedImagePicker`` in a sheet on iOS and macOS.
@MainActor
public struct DynamicImageField: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var showImagePickerSheet = false

    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }

    public var body: some View {
        let i18n = InternationalizationService()
        return platformVStackContainer(alignment: .leading, spacing: 8) {
            #if os(iOS) || os(macOS)
            Button(action: { showImagePickerSheet = true }) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(i18n.localizedString(for: "SixLayerFramework.button.selectImage"))
                }
            }
            .buttonStyle(.bordered)
            .automaticCompliance(named: "ImagePickerButton")
            #else
            Text(i18n.localizedString(for: "SixLayerFramework.imagePicker.notAvailable"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .automaticCompliance(named: "ImagePickerUnavailable")
            #endif

            if let imageData = formState.fieldValues[field.id] as? Data, let image = PlatformImage(data: imageData) {
                image.platformImageView()
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .automaticCompliance(named: "ImagePreview")
            }
        }
        .padding()
        .automaticCompliance(named: "DynamicImageField")
        #if os(iOS) || os(macOS)
        .sheet(isPresented: $showImagePickerSheet) {
            UnifiedImagePicker { platformImage in
                if let data = platformImage.exportJPEG(quality: 0.85) {
                    formState.setValue(data, for: field.id)
                }
                showImagePickerSheet = false
            }
        }
        #endif
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
            let sliderValue = Binding(
                get: { Double((formState.getValue(for: field.id) as String?) ?? field.defaultValue ?? "0") ?? 0 },
                set: { formState.setValue(String($0), for: field.id) }
            )
            #if os(tvOS)
            // Slider is unavailable on tvOS; Layer 4 maps range to a read-only progress indicator.
            EmptyView().platformRangeInput(value: sliderValue, in: 0...100)
                .progressViewStyle(.linear)
                .automaticCompliance(
                    identifierElementType: "Slider",
                    accessibilityValue: "\(Int(sliderValue.wrappedValue)) percent"
                )
            #else
            Slider(value: sliderValue, in: 0...100)
                .automaticCompliance(
                    identifierElementType: "Slider",
                    accessibilityValue: "\(Int(sliderValue.wrappedValue)) percent"  // Issue #165: Current value with range context
                )
            #endif
        }
        .padding()
        .dynamicFormFieldAccessibilityLabel(field) // Issue #194: resolved label when localized
        .automaticComplianceForDynamicFormField(field)
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
                    .platformTextFieldStyle()
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
        .dynamicFormFieldAccessibilityLabel(field) // Issue #194: resolved label when localized
        .automaticComplianceForDynamicFormField(field)
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
            let dataTextBinding = Binding(
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
            )

            #if os(tvOS)
            EmptyView().platformTextEditor(text: dataTextBinding, prompt: "")
                .frame(minHeight: 100)
                .border(Color.gray.opacity(0.2))
                .automaticCompliance(named: "DataInput")
            #elseif os(watchOS)
            TextField("", text: dataTextBinding, axis: .vertical)
                .platformTextFieldStyle()
                .lineLimit(4...24)
                .frame(minHeight: 100)
                .border(Color.gray.opacity(0.2))
                .automaticCompliance(named: "DataInput")
            #else
            TextEditor(text: dataTextBinding)
                .frame(minHeight: 100)
                .border(Color.gray.opacity(0.2))
                .automaticCompliance(named: "DataInput")
            #endif

            if let data = formState.fieldValues[field.id] as? Data {
                Text("Data size: \(data.count) bytes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .automaticCompliance(named: "DataSize")
            }
        }
        .padding()
        .automaticComplianceForDynamicFormField(field)
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

            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.typeToSearch"), text: Binding(
                get: { formState.getValue(for: field.id) as String? ?? field.defaultValue ?? "" },
                set: { newValue in
                    formState.setValue(newValue, for: field.id)
                    searchText = newValue
                    showSuggestions = !newValue.isEmpty && field.options != nil
                }
            ))
            .platformTextFieldStyle()
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
        .automaticComplianceForDynamicFormField(field)
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
        .dynamicFormFieldAccessibilityLabel(field) // Issue #194: resolved label when localized
        .automaticComplianceForDynamicFormField(field)
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

            if let customComponent = CustomFieldRegistry.shared.createComponent(for: field, formState: formState) {
                // any CustomFieldComponent existential must be wrapped for ViewBuilder
                AnyView(customComponent)
            } else {
                Text("Custom field not registered: \(field.contentType?.rawValue ?? "unknown")")
                    .foregroundColor(.red)
                    .font(.caption)
                    .automaticCompliance(named: "CustomFieldError")
            }
        }
        .padding()
        .automaticComplianceForDynamicFormField(field)
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
            let colorValue = formState.fieldValues[field.id] as? String ?? "#000000"
            let color = Color(hex: colorValue) ?? .black
            
            let i18n = InternationalizationService()
            let colorSelection = Binding(
                get: { color },
                set: { newColor in
                    let hex = newColor.toHex()
                    formState.setValue(hex, for: field.id)
                }
            )

            #if os(tvOS)
            EmptyView().platformColorInput(
                label: field.placeholder ?? i18n.placeholderSelectColor(),
                selection: colorSelection
            )
            .automaticCompliance(named: "ColorPicker")
            Text(colorValue)
                .font(.caption)
                .foregroundStyle(.secondary)
            #elseif os(watchOS)
            WatchOSHexWheelPicker(
                label: field.placeholder ?? i18n.placeholderSelectColor(),
                hex: Binding(
                    get: { formState.fieldValues[field.id] as? String ?? "#000000" },
                    set: { formState.setValue($0, for: field.id) }
                )
            )
            .automaticCompliance(named: "ColorPicker")
            #else
            ColorPicker(field.placeholder ?? i18n.placeholderSelectColor(), selection: colorSelection)
                .automaticCompliance(named: "ColorPicker")
            #endif

            Rectangle()
                .fill(color)
                .frame(height: 40)
                .cornerRadius(8)
                .automaticCompliance(named: "ColorPreview")
        }
        .padding()
        .automaticComplianceForDynamicFormField(field)
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
    
    private var isOn: Binding<Bool> {
        Binding(
            get: {
                if let value: Any = formState.getValue(for: field.id) {
                    if let boolValue = value as? Bool {
                        return boolValue
                    } else if let stringValue = value as? String {
                        return stringValue.lowercased() == "true" || stringValue == "1"
                    }
                }
                return field.defaultValue?.lowercased() == "true" || field.defaultValue == "1" || false
            },
            set: { newValue in
                formState.setValue(String(newValue), for: field.id)
            }
        )
    }
    
    public var body: some View {
        field.fieldContainer(content: {
            Toggle(isOn: isOn) {
                Text(field.label)
            }
            .dynamicFormFieldVoiceOverLabel(field)
            .automaticComplianceForDynamicFormField(
                field,
                identifierElementType: "Toggle",
                accessibilityValue: generateAccessibilityValueForToggle(isOn: isOn.wrappedValue)
            )
        }, componentName: "DynamicToggleField")
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
            #if os(iOS)
            TextEditor(text: field.textBinding(formState: formState))
                .frame(minHeight: 100)
                .border(Color.gray.opacity(0.2))
                .automaticCompliance(named: "TextArea")
            #else
            let i18n = InternationalizationService()
            TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterText"), text: field.textBinding(formState: formState), axis: .vertical)
                .platformTextFieldStyle()
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
            // Use LabeledContent on supported platforms (label shown by parent — Issue #189)
            LabeledContent("") {
                if let customValueView = field.valueView {
                    customValueView(field, formState)
                } else {
                    Text(valueString)
                        .foregroundColor(.secondary)
                }
            }
            .dynamicFormFieldVoiceOverLabel(field)
            .automaticComplianceForDynamicFormField(field)
        } else {
            // Fallback for older platforms
            HStack {
                Spacer()
                if let customValueView = field.valueView {
                    customValueView(field, formState)
                } else {
                    Text(valueString)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .dynamicFormFieldVoiceOverLabel(field)
            .automaticComplianceForDynamicFormField(field)
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
            #if !os(tvOS)
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
            #else
            // tvOS: Gauge is unavailable; use ProgressView fallback unconditionally.
            ProgressView(value: value, total: range.upperBound)
                .progressViewStyle(.linear)
                .automaticCompliance(named: "ProgressView")

            Text("\(Int(value)) / \(Int(range.upperBound))")
                .font(.caption)
                .foregroundColor(.secondary)
                .automaticCompliance(named: "GaugeValueLabel")
            #endif
        }
        .padding()
        .automaticComplianceForDynamicFormField(field)
    }
}

// MARK: - Dynamic form file import helper

/// Copies a security-scoped import URL into the app caches directory and returns the destination file path string.
@MainActor
private func dynamicFormCopyImportedFileToCachesDirectory(from sourceURL: URL) throws -> String {
    try platformSecurityScopedAccess(url: sourceURL) { scoped in
        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "SixLayerFramework.DynamicFileField", code: 1, userInfo: nil)
        }
        let destURL = cachesURL.appendingPathComponent("SixLayerDynamicForm-\(UUID().uuidString)-\(scoped.lastPathComponent)")
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.copyItem(at: scoped, to: destURL)
        return destURL.path
    }
}
