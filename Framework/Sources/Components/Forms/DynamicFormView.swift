import SwiftUI
#if canImport(CoreData)
import CoreData
#endif
#if canImport(SwiftData)
import SwiftData
#endif

// MARK: - Dynamic Form View

/// Main dynamic form view component
/// GREEN PHASE: Full implementation of dynamic form rendering
/// 
/// **Entity Creation (New Object Creation)**:
/// If `modelName` is provided and hints are fully declarative, the form can automatically
/// create entities (Core Data or SwiftData) from collected form values on submit.
/// 
/// **How it works:**
/// 1. Form collects values as user types (existing behavior)
/// 2. On submit: If `modelName` is provided, creates entity from form values
/// 3. Calls `onEntityCreated` with the created entity (if provided)
/// 4. Always calls `onSubmit` with dictionary of values (backward compatible)
///
/// **Requirements:**
/// - **Core Data**: Works automatically when `modelName` is provided. Entity is created using
///   `NSEntityDescription.insertNewObject` and values are set via KVC.
/// - **SwiftData**: Requires `entityType` parameter to be provided for entity creation.
///   If not provided, only dictionary is returned (backward compatible).
@MainActor
public struct DynamicFormView: View {
    let configuration: DynamicFormConfiguration
    let onSubmit: ([String: Any]) -> Void
    let onEntityCreated: ((Any) -> Void)?
    let onError: ((Error) -> Void)?
    let entityType: Any.Type?
    @StateObject private var formState: DynamicFormState
    
    // Batch OCR state (Issue #83)
    @State private var showImagePicker = false
    @State private var isProcessingOCR = false
    @State private var ocrError: String?
    
    // Environment contexts
    #if canImport(CoreData)
    @Environment(\.managedObjectContext) private var managedObjectContext
    #endif
    
    #if canImport(SwiftData)
    @available(macOS 14.0, iOS 17.0, *)
    @Environment(\.modelContext) private var modelContext: ModelContext
    #endif

    /// Initialize DynamicFormView
    /// - Parameters:
    ///   - configuration: Form configuration with fields and optional modelName
    ///   - onSubmit: Callback with dictionary of form values (always called)
    ///   - onEntityCreated: Optional callback with created entity (called if modelName provided and entity created)
    ///   - onError: Optional callback for errors (called if entity creation or save fails)
    ///   - entityType: Optional SwiftData entity type (required for SwiftData entity creation)
    public init(
        configuration: DynamicFormConfiguration,
        onSubmit: @escaping ([String: Any]) -> Void,
        onEntityCreated: ((Any) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil,
        entityType: Any.Type? = nil
    ) {
        self.onSubmit = onSubmit
        self.onEntityCreated = onEntityCreated
        self.onError = onError
        self.entityType = entityType
        
        // Auto-load hints if modelName provided (Issue #71)
        let effectiveConfiguration = configuration.applyingHints()
        
        // Store effective configuration (with hints applied if applicable)
        self.configuration = effectiveConfiguration
        _formState = StateObject(wrappedValue: DynamicFormState(configuration: effectiveConfiguration))
    }

    public var body: some View {
        ScrollViewReader { proxy in
            platformVStackContainer(spacing: 20) {
                // Form title
                Text(configuration.title)
                    .font(.headline)
                    .automaticCompliance(named: "FormTitle")

                // Form description if present
                if let description = configuration.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .automaticCompliance(named: "FormDescription")
                }

                // Progress indicator (Issue #82)
                if configuration.showProgress {
                    FormProgressIndicator(progress: formState.formProgress)
                }

                // Validation summary - shows all errors at once
                if formState.hasValidationErrors {
                    FormValidationSummary(
                        formState: formState,
                        configuration: configuration,
                        onErrorTap: { fieldId in
                            // Scroll to the field with animation
                            withAnimation {
                                proxy.scrollTo(fieldId, anchor: .center)
                            }
                        }
                    )
                }

                // Show batch OCR button if any fields support OCR
                if !configuration.getOCREnabledFields().isEmpty {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            if isProcessingOCR {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.viewfinder")
                            }
                            let i18n = InternationalizationService()
                            Text(isProcessingOCR ? i18n.localizedString(for: "SixLayerFramework.ocr.processing") : i18n.localizedString(for: "SixLayerFramework.ocr.scanDocument"))
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isProcessingOCR)
                    .accessibilityLabel("Scan document to fill multiple fields")
                    .accessibilityHint("Takes a photo and automatically fills all OCR-enabled fields")
                    .automaticCompliance(named: "BatchOCRButton")
                    .sheet(isPresented: $showImagePicker) {
                        UnifiedImagePicker { image in
                            processBatchOCR(image: image)
                        }
                    }
                    
                    // Show OCR error if any
                    if let error = ocrError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }

                // Render form sections
                ForEach(configuration.sections) { section in
                    DynamicFormSectionView(section: section, formState: formState)
                }

                Spacer()

                // Submit button
                Button(action: {
                    handleSubmit()
                }) {
                    Text(configuration.submitButtonText)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .automaticCompliance(named: "SubmitButton")
            }
            .padding()
            .environment(\.accessibilityIdentifierLabel, configuration.title) // TDD GREEN: Pass label to identifier generation
            .automaticCompliance(
                identifierName: sanitizeLabelText(configuration.title)  // Auto-generate identifierName from form title
            )
            .onAppear {
                // Load draft if it exists (Issue #80)
                if formState.loadDraft() {
                    // Draft was loaded - form state is already updated
                }
                // Start auto-save timer
                formState.startAutoSave()
            }
            .onDisappear {
                // Save draft when form disappears (Issue #80)
                formState.saveDraft()
                // Stop auto-save timer
                formState.stopAutoSave()
            }
            .onChange(of: formState.isDirty) {
                // Trigger debounced save when form becomes dirty (Issue #80)
                if formState.isDirty {
                    formState.triggerDebouncedSave()
                }
            }
        }
    }
    
    /// Process batch OCR: extract structured data and populate form fields (Issue #83)
    private func processBatchOCR(image: PlatformImage) {
        isProcessingOCR = true
        ocrError = nil
        showImagePicker = false
        
        Task {
            do {
                // Build OCR context from form configuration
                let ocrEnabledFields = configuration.getOCREnabledFields()
                
                // Collect all text types from OCR-enabled fields
                var textTypes: Set<TextType> = []
                for field in ocrEnabledFields {
                    if let validationTypes = field.ocrValidationTypes {
                        textTypes.formUnion(validationTypes)
                    } else {
                        // Default to general if no specific types
                        textTypes.insert(.general)
                    }
                }
                
                // Build extraction hints from field identifiers
                var extractionHints: [String: String] = [:]
                for field in ocrEnabledFields {
                    let fieldId = field.ocrFieldIdentifier ?? field.id
                    if let ocrHint = field.ocrHint {
                        // Use ocrHint as a simple pattern if provided
                        extractionHints[fieldId] = ocrHint
                    }
                }
                
                // Create OCR context
                let context = OCRContext(
                    textTypes: Array(textTypes),
                    language: .english, // TODO: Make configurable
                    extractionHints: extractionHints.isEmpty ? [:] : extractionHints,
                    extractionMode: .automatic,
                    entityName: configuration.modelName // Use modelName for hints file loading
                )
                
                // Process structured extraction (includes calculation groups)
                let service = OCRService()
                let result = try await service.processStructuredExtraction(image, context: context)
                
                // Populate form fields from structuredData
                await MainActor.run {
                    for (fieldId, value) in result.structuredData {
                        formState.setValue(value, for: fieldId)
                    }
                    
                    isProcessingOCR = false
                }
            } catch {
                await MainActor.run {
                    isProcessingOCR = false
                    ocrError = "OCR processing failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Handle form submission: validate, create entity if modelName provided, then call callbacks
    private func handleSubmit() {
        // Clear draft when form is successfully submitted (Issue #80)
        formState.clearDraft()
        
        // Always call onSubmit with dictionary (backward compatible)
        onSubmit(formState.fieldValues)
        
        // If modelName is provided, try to create entity
        guard let modelName = configuration.modelName else { return }
        
        // Validate form before entity creation
        if !formState.isValid {
            // Focus first error field (Issue #81)
            formState.focusFirstError()
            
            let validationError = NSError(
                domain: "DynamicFormView",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Form validation failed. Please fix errors before submitting.",
                    "fieldErrors": formState.fieldErrors
                ]
            )
            onError?(validationError)
            return
        }
        
        // Try to create Core Data entity
        #if canImport(CoreData)
        do {
            let entity = try createCoreDataEntity(entityName: modelName, values: formState.fieldValues)
            onEntityCreated?(entity)
            return
        } catch {
            onError?(error)
            return
        }
        #elseif canImport(SwiftData)
        // Try to create SwiftData entity (requires entityType)
        // Only used when CoreData is not available
        if #available(macOS 14.0, iOS 17.0, *) {
            if let entityType = entityType {
                do {
                    let entity = try createSwiftDataEntity(entityType: entityType, values: formState.fieldValues)
                    onEntityCreated?(entity)
                    return
                } catch {
                    onError?(error)
                    return
                }
            }
        }
        #endif
    }
    
    #if canImport(CoreData)
    /// Create Core Data entity from form values
    /// DRY: Uses shared EntityCreationUtilities
    /// - Throws: Error if entity creation or save fails
    private func createCoreDataEntity(entityName: String, values: [String: Any]) throws -> NSManagedObject {
        let context = managedObjectContext
        
        // Load hints to get type information (for filtering hidden fields)
        let hintsLoader = FileBasedDataHintsLoader()
        let hintsResult = hintsLoader.loadHintsResult(for: entityName)
        let fieldHints = hintsResult.fieldHints
        
        // Use shared utility (now throws on error)
        return try EntityCreationUtilities.createCoreDataEntity(
            entityName: entityName,
            values: values,
            context: context,
            fieldHints: fieldHints
        )
    }
    #endif
    
    #if canImport(SwiftData)
    /// Create SwiftData entity from form values using Codable
    /// DRY: Uses shared EntityCreationUtilities
    /// - Throws: Error if entity creation or save fails
    @available(macOS 14.0, iOS 17.0, *)
    private func createSwiftDataEntity(entityType: Any.Type, values: [String: Any]) throws -> Any {
        let context = modelContext
        
        // Load hints to get type information (for filtering hidden fields)
        let hintsLoader = FileBasedDataHintsLoader()
        let hintsResult = hintsLoader.loadHintsResult(for: configuration.modelName ?? "")
        let fieldHints = hintsResult.fieldHints
        
        // Use shared utility (now throws on error)
        return try EntityCreationUtilities.createSwiftDataEntity(
            entityType: entityType,
            values: values,
            context: context,
            fieldHints: fieldHints
        )
    }
    #endif
}

// MARK: - Dynamic Form Section View

/// Section view for dynamic forms
/// REFACTOR: Now uses layoutStyle from section to apply proper field layout
/// GREEN PHASE: Implements collapsible sections using DisclosureGroup
@MainActor
public struct DynamicFormSectionView: View {
    let section: DynamicFormSection
    @ObservedObject var formState: DynamicFormState

    public init(section: DynamicFormSection, formState: DynamicFormState) {
        self.section = section
        self.formState = formState
    }
    
    /// Binding to section collapsed state from formState
    private var isExpanded: Binding<Bool> {
        Binding(
            get: { !formState.isSectionCollapsed(section.id) },
            set: { newValue in
                if newValue != !formState.isSectionCollapsed(section.id) {
                    formState.toggleSection(section.id)
                }
            }
        )
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 16) {
            if section.isCollapsible {
                // Use DisclosureGroup for collapsible sections
                DisclosureGroup(isExpanded: isExpanded) {
                    // Section description if present (shown when expanded)
                    if let description = section.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .automaticCompliance(named: "SectionDescription")
                    }
                    
                    // Render fields using section's layoutStyle
                    fieldLayoutView
                } label: {
                    // Section title as disclosure label
                    Text(section.title)
                        .font(.title3)
                        .bold()
                        .automaticCompliance(named: "SectionTitle")
                }
                .accessibilityLabel("\(section.title), \(isExpanded.wrappedValue ? "expanded" : "collapsed") section")
                .accessibilityHint("Double tap to \(isExpanded.wrappedValue ? "collapse" : "expand") this section")
            } else {
                // Non-collapsible sections render normally
                // Section title
                Text(section.title)
                    .font(.title3)
                    .bold()
                    .automaticCompliance(named: "SectionTitle")

                // Section description if present
                if let description = section.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .automaticCompliance(named: "SectionDescription")
                }

                // Render fields using section's layoutStyle (hint, not commandment - framework adapts)
                fieldLayoutView
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .environment(\.accessibilityIdentifierLabel, section.title)
        .automaticCompliance(
            identifierName: sanitizeLabelText(section.title)  // Auto-generate identifierName from section title
        )
    }
    
    // MARK: - DRY: Field Layout Helper
    
    /// Filtered list of visible fields based on visibility conditions
    private var visibleFields: [DynamicFormField] {
        section.fields.filter { field in
            field.visibilityCondition?(formState) ?? true
        }
    }
    
    @ViewBuilder
    private var fieldLayoutView: some View {
        let layoutStyle = section.layoutStyle ?? .vertical // Default to vertical
        
        switch layoutStyle {
        case .vertical, .standard, .compact, .spacious:
            // Vertical stack (default)
            platformVStackContainer(spacing: 16) {
                ForEach(visibleFields) { field in
                    DynamicFormFieldView(field: field, formState: formState)
                        .transition(.opacity)
                }
            }
            
        case .horizontal:
            // Horizontal layout (2 columns)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(visibleFields) { field in
                    DynamicFormFieldView(field: field, formState: formState)
                        .transition(.opacity)
                }
            }
            
        case .grid:
            // Grid layout (adaptive columns)
            let columns = min(3, max(1, Int(sqrt(Double(visibleFields.count)))))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 16) {
                ForEach(visibleFields) { field in
                    DynamicFormFieldView(field: field, formState: formState)
                        .transition(.opacity)
                }
            }
            
        case .adaptive:
            // Adaptive: choose layout based on field count
            if visibleFields.count <= 4 {
                platformVStackContainer(spacing: 16) {
                    ForEach(visibleFields) { field in
                        DynamicFormFieldView(field: field, formState: formState)
                            .transition(.opacity)
                    }
                }
            } else if visibleFields.count <= 8 {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(visibleFields) { field in
                        DynamicFormFieldView(field: field, formState: formState)
                            .transition(.opacity)
                    }
                }
            } else {
                let columns = min(3, max(1, Int(sqrt(Double(visibleFields.count)))))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 16) {
                    ForEach(visibleFields) { field in
                        DynamicFormFieldView(field: field, formState: formState)
                            .transition(.opacity)
                    }
                }
            }
        }
    }
}

// MARK: - Dynamic Form Field View

/// Field view for dynamic forms
/// GREEN PHASE: Full implementation of dynamic field rendering
/// Issue #79: Added field-level help tooltips/info buttons for field descriptions
@MainActor
public struct DynamicFormFieldView: View {
    let field: DynamicFormField
    @ObservedObject var formState: DynamicFormState
    @State private var showHelpPopover = false
    
    public init(field: DynamicFormField, formState: DynamicFormState) {
        self.field = field
        self.formState = formState
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            // Field label with required indicator and info button
            platformHStackContainer(spacing: 4) {
                Text(field.label)
                    .font(.subheadline)
                    .bold()
                if field.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                // Info button for field description (Issue #79)
                if let description = field.description {
                    Button(action: {
                        showHelpPopover.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Help for \(field.label)")
                    .accessibilityHint(description)
                    #if os(macOS)
                    .help(description) // macOS native tooltip on hover
                    #endif
                    .platformPopover_L4(
                        isPresented: $showHelpPopover,
                        attachmentAnchor: .point(.top),
                        arrowEdge: .bottom
                    ) {
                        platformVStackContainer(alignment: .leading, spacing: 8) {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: 300)
                        }
                    }
                }
            }
            .automaticCompliance(named: "FieldLabel")
            .accessibilityLabel(field.isRequired ? "\(field.label), required" : field.label)

            // Field description is now shown in popover/tooltip, not as plain text (Issue #79)
            // This saves vertical space and reduces form clutter

            // Field input based on type
            fieldInputView()

            // Validation errors
            if let errors = formState.fieldErrors[field.id], !errors.isEmpty {
                ForEach(errors, id: \.self) { error in
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .environment(\.accessibilityIdentifierLabel, error) // TDD GREEN: Pass error text to identifier generation
                        .automaticCompliance(named: "FieldError")
                }
            }
        }
        .id(field.id) // Add ID for ScrollViewReader scrolling
        .environment(\.accessibilityIdentifierLabel, field.label) // TDD GREEN: Pass label to identifier generation
        .automaticCompliance(
            identifierName: sanitizeLabelText(field.label)  // Auto-generate identifierName from field label
        )
    }

    @ViewBuilder
    private func fieldInputView() -> some View {
        // DRY: Use CustomFieldView to render all field types consistently
        // This ensures all field types (multiselect, richtext, file, image, array, data, autocomplete, enum, color, etc.)
        // are properly supported through the individual field components we implemented
        CustomFieldView(field: field, formState: formState)
    }
}

// MARK: - Form Validation Summary

/// Validation summary view showing all form errors at once
/// Issue #78: Add form validation summary view showing all errors at once
@MainActor
public struct FormValidationSummary: View {
    @ObservedObject var formState: DynamicFormState
    let configuration: DynamicFormConfiguration
    @State private var isExpanded = true
    let onErrorTap: ((String) -> Void)?
    
    public init(
        formState: DynamicFormState,
        configuration: DynamicFormConfiguration,
        onErrorTap: ((String) -> Void)? = nil
    ) {
        self.formState = formState
        self.configuration = configuration
        self.onErrorTap = onErrorTap
    }
    
    public var body: some View {
        let allErrors = formState.allErrors(with: configuration)
        let errorCount = formState.errorCount
        
        if !allErrors.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                platformVStackContainer(alignment: .leading, spacing: 12) {
                    ForEach(Array(allErrors.enumerated()), id: \.offset) { index, error in
                        Button(action: {
                            onErrorTap?(error.fieldId)
                        }) {
                            platformHStackContainer(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                
                                platformVStackContainer(alignment: .leading, spacing: 4) {
                                    Text(error.fieldLabel)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(error.message)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(error.fieldLabel): \(error.message)")
                        .accessibilityHint("Tap to navigate to this field")
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text("\(errorCount) validation error\(errorCount == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
            .automaticCompliance(named: "FormValidationSummary")
            .accessibilityLabel("Validation summary: \(errorCount) error\(errorCount == 1 ? "" : "s")")
            .accessibilityHint("Expand to see all validation errors")
        }
    }
}

// MARK: - Form Progress Indicator (Issue #82)

/// Progress indicator for form completion
/// Shows completion percentage and "X of Y fields completed" text
public struct FormProgressIndicator: View {
    let progress: FormProgress
    
    public init(progress: FormProgress) {
        self.progress = progress
    }
    
    public var body: some View {
        let i18n = InternationalizationService()
        // Format string expects: %d of %d field%@
        // Compute formatted text outside ViewBuilder to avoid type issues
        let formatKey = "SixLayerFramework.form.progressFields"
        let format = i18n.localizedString(for: formatKey)
        let plural = progress.total == 1 ? "" : "s"
        let formattedText: String = {
            // Check if format string was found (not just the key returned)
            if format != formatKey && format.contains("%d") {
                // Format string found and has integer placeholders - use variadic arguments with Int
                return String(format: format, progress.completed, progress.total, plural)
            } else {
                // Fallback if format string is missing or incorrect - use string interpolation
                return "\(progress.completed) of \(progress.total) field\(plural)"
            }
        }()
        
        return platformVStackContainer(alignment: .leading, spacing: 8) {
            platformHStackContainer {
                Text(i18n.localizedString(for: "SixLayerFramework.form.progress"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress.percentage)
                .progressViewStyle(.linear)
                .tint(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .automaticCompliance(named: "FormProgressIndicator")
        .accessibilityLabel("Form progress: \(Int(progress.percentage * 100)) percent complete, \(progress.completed) of \(progress.total) required fields filled")
        .accessibilityValue("\(progress.completed) of \(progress.total) fields completed")
    }
}

// MARK: - Form Wizard View

/// Wizard-style form view
/// GREEN PHASE: Full implementation of multi-step wizard interface
@MainActor
public struct FormWizardView<Content: View, Navigation: View>: View {
    let steps: [FormWizardStep]
    let content: (FormWizardStep, FormWizardState) -> Content
    let navigation: (FormWizardState, @escaping () -> Void, @escaping () -> Void, @escaping () -> Void) -> Navigation
    
    @StateObject private var wizardState: FormWizardState
    
    public init(
        steps: [FormWizardStep],
        @ViewBuilder content: @escaping (FormWizardStep, FormWizardState) -> Content,
        @ViewBuilder navigation: @escaping (FormWizardState, @escaping () -> Void, @escaping () -> Void, @escaping () -> Void) -> Navigation
    ) {
        self.steps = steps
        self.content = content
        self.navigation = navigation
        _wizardState = StateObject(wrappedValue: FormWizardState())
    }
    
    public var body: some View {
        platformVStackContainer(spacing: 20) {
            // Step progress indicator
            if steps.count > 1 {
                HStack {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        Circle()
                            .fill(index <= wizardState.currentStepIndex ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < wizardState.currentStepIndex ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding()
                .automaticCompliance(named: "StepProgress")
            }
            
            // Current step content
            if wizardState.currentStepIndex < steps.count {
                let currentStep = steps[wizardState.currentStepIndex]
                content(currentStep, wizardState)
                    .automaticCompliance(named: "StepContent")
            }
            
            Spacer()
            
            // Navigation controls
            navigation(
                wizardState,
                { _ = wizardState.nextStep() },
                { _ = wizardState.previousStep() },
                { /* Finish action - can be handled by parent */ }
            )
            .automaticCompliance(named: "NavigationControls")
        }
        .padding()
        .onAppear {
            wizardState.setSteps(steps)
        }
        .automaticCompliance(named: "FormWizardView")
    }
}

// MARK: - Supporting Types (TDD Red Phase Stubs)
// Note: FormWizardStep and FormWizardState are defined in FormWizardTypes.swift
