import SwiftUI
#if canImport(CoreData)
import CoreData
#endif
#if canImport(SwiftData)
import SwiftData
#endif

// MARK: - Error Severity Types

/// Defensive enum for error severity to prevent string-based anti-patterns
public enum ErrorSeverity: String, CaseIterable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Ordering Helpers

extension IntelligentFormView {
    /// Optional provider for external order rules (e.g., EnhancedHints/registry)
    public static var orderRulesProvider: ((DataAnalysisResult) -> FieldOrderRules?)?
    
    /// Default priority-based ordering: prefer common primary fields like "title" or "name" first.
    /// Falls back to stable name ordering; avoids alphabetic-by-type grouping.
    internal static func orderFieldsByPriority(_ fields: [DataField]) -> [DataField] {
        // If external rules exist, resolve first
        if let analysis = _currentAnalysisContext, let rules = orderRulesProvider?(analysis) {
            let names = fields.map { $0.name }
            let trait = activeTrait()
            let orderedNames = FieldOrderResolver.resolve(fields: names, rules: rules, activeTrait: trait)
            let byName = Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0) })
            return orderedNames.compactMap { byName[$0] } + names.filter { !orderedNames.contains($0) }.compactMap { byName[$0] }
        }
        
        return fields.sorted { lhs, rhs in
            let wl = defaultWeight(for: lhs.name)
            let wr = defaultWeight(for: rhs.name)
            if wl != wr { return wl > wr }
            return lhs.name < rhs.name
        }
    }
    
    private static func defaultWeight(for fieldName: String) -> Int {
        let n = fieldName.lowercased()
        if n == "title" { return 1_000 }
        if n == "name" { return 900 }
        if n.contains("title") { return 800 }
        if n.contains("summary") { return 700 }
        return 0
    }
    
    // MARK: - Trait/Context
    internal static func activeTrait() -> FieldTrait {
        // Simple heuristic: phones are compact, others regular
        switch SixLayerPlatform.deviceType {
        case .phone: return .compact
        default: return .regular
        }
    }
    
    // Store the latest analysis so the provider can use it without changing signatures widely
    @TaskLocal static var _currentAnalysisContext: DataAnalysisResult?
    
    // Wrap content generation to set the analysis context
    static func withAnalysisContext<T>(_ analysis: DataAnalysisResult, build: () -> T) -> T {
        return Self.$_currentAnalysisContext.withValue(analysis) { build() }
    }
}

// MARK: - Intelligent Form View

/// Intelligent form generation using our 6-layer platform architecture
/// This view analyzes data models and generates appropriate forms using platform extensions
@MainActor
public struct IntelligentFormView {
    
    // MARK: - Public API
    
    /// Generate a form for creating new data with data binding integration
    ///
    /// **Type-Only Form Generation (New Object Creation)**:
    /// If `initialData` is `nil` but fully declarative hints are available, the form can be
    /// generated from hints alone. This enables form generation without requiring instance data.
    /// 
    /// **How it works:**
    /// 1. Creates a blank entity (Core Data or SwiftData) with defaults from hints
    /// 2. Uses existing update flow (reuses all existing form logic)
    /// 3. On cancel: Deletes the blank entity
    /// 4. On save: Uses existing save logic
    ///
    /// **Requirements:**
    /// - **Core Data**: Works automatically. Entity is created using `NSEntityDescription.insertNewObject`
    ///   and values are set via KVC. No Codable or memberwise initialization required.
    /// - **SwiftData**: Requires `T: Codable` for type-only forms to work (preferred). If your SwiftData model
    ///   does not conform to Codable, memberwise initialization would be required (not yet implemented).
    ///   For non-Codable SwiftData models, use `generateForm(for: existingInstance)` with a pre-created instance instead.
    /// - **Plain Swift types**: Not supported for type-only forms. Use `generateForm(for: existingInstance)`.
    ///
    /// **Automatic Data Binding**:
    /// By default (`autoBind: true`), a `DataBinder` is automatically created if:
    /// - No `dataBinder` is explicitly provided
    /// - The model appears to support binding (has analyzable fields)
    /// - Instance data is available (not applicable for type-only forms)
    ///
    /// The automatically created `DataBinder` instance is available but fields must
    /// be manually bound using key paths. See `DataBinder.bind(_:to:)` for details.
    ///
    /// **Opt-Out**: Set `autoBind: false` to disable automatic `DataBinder` creation.
    /// This is useful for read-only forms, immutable models, or external state management.
    ///
    /// - Parameters:
    ///   - dataType: The type of data model
    ///   - initialData: Initial data instance (optional if fully declarative hints are available)
    ///   - dataBinder: Optional explicit DataBinder. If provided, `autoBind` is ignored.
    ///   - autoBind: Whether to automatically create a DataBinder (default: true, ignored for type-only forms)
    ///   - inputHandlingManager: Optional input handling manager
    ///   - customFieldView: Custom view builder for field rendering
    ///   - onSubmit: Callback when form is submitted. For type-only forms, receives a dictionary of field values.
    ///   - onCancel: Callback when form is cancelled
    /// - Returns: A view representing the generated form
    public static func generateForm<T>(
        for dataType: T.Type,
        initialData: T? = nil,
        dataBinder: DataBinder<T>? = nil,
        autoBind: Bool = true,
        inputHandlingManager: InputHandlingManager? = nil,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View = { _, _, _ in EmptyView() },
        onSubmit: @escaping (T) -> Void = { _ in },
        onCancel: @escaping () -> Void = { }
    ) -> some View {
        // Try type-only analysis if no initialData provided
        if initialData == nil {
            let modelName = String(describing: dataType)
                .components(separatedBy: ".").last ?? String(describing: dataType)
            
            if let analysis = DataIntrospectionEngine.analyzeFromType(dataType, modelName: modelName) {
                // Type-only form generation: use hints-only analysis
                // Hints are fully declarative, so we can generate the form entirely from hints
                let formStrategy = determineFormStrategy(analysis: analysis)
                
                // Load hints for the model type
                let hintsLoader = FileBasedDataHintsLoader()
                let hintsResult = hintsLoader.loadHintsResult(for: modelName)
                let fieldHints = hintsResult.fieldHints
                
                // Generate form content from hints (no instance data needed)
                // Note: This content is not used directly - TypeOnlyFormWrapper creates entity and uses update flow
                let _ = withAnalysisContext(analysis) {
                    Group {
                    switch formStrategy.containerType {
                    case .form:
                        platformVStackContainer(spacing: 20) {
                            platformVStackContainer(alignment: .leading, spacing: 8) {
                                let i18n = InternationalizationService()
                                Text(i18n.localizedString(for: "SixLayerFramework.form.title"))
                                    .font(.headline)
                                    .automaticCompliance(named: "FormTitle")
                            }
                            .automaticCompliance(named: "DynamicFormHeader")
                            
                            platformFormContainer_L4(
                                strategy: formStrategy,
                                content: {
                                    generateFormContent(
                                        analysis: analysis,
                                        initialData: nil as T?, // No instance data - use hints defaults
                                        dataBinder: nil,   // No binding for type-only forms
                                        inputHandlingManager: inputHandlingManager,
                                        customFieldView: customFieldView,
                                        formStrategy: formStrategy,
                                        fieldHints: fieldHints
                                    )
                                }
                            )
                            .automaticCompliance(named: "DynamicFormSectionView")
                        }
                        .automaticCompliance(named: "DynamicFormView")
                        .overlay(
                            generateTypeOnlyFormActions(
                                onCancel: onCancel
                            )
                        )
                        
                    case .standard, .scrollView, .custom, .adaptive:
                        platformVStackContainer(spacing: 20) {
                            platformVStackContainer(alignment: .leading, spacing: 8) {
                                let i18n = InternationalizationService()
Text(i18n.localizedString(for: "SixLayerFramework.form.title"))
                                    .font(.headline)
                                    .automaticCompliance(named: "FormTitle")
                            }
                            .automaticCompliance(named: "DynamicFormHeader")
                            
                            platformFormContainer_L4(
                                strategy: formStrategy,
                                content: {
                                    generateFormContent(
                                        analysis: analysis,
                                        initialData: nil as T?, // No instance data - use hints defaults
                                        dataBinder: nil,   // No binding for type-only forms
                                        inputHandlingManager: inputHandlingManager,
                                        customFieldView: customFieldView,
                                        formStrategy: formStrategy,
                                        fieldHints: fieldHints
                                    )
                                }
                            )
                            .automaticCompliance(named: "DynamicFormSectionView")
                        }
                        .overlay(
                            generateTypeOnlyFormActions(
                                onCancel: onCancel
                            )
                        )
                    }
                    }
                }
                
                // Wrap in a view that creates blank entity and uses existing update flow
                // This approach:
                // 1. Creates blank entity (Core Data or SwiftData) with defaults from hints
                // 2. Uses existing update flow (reuses all existing code)
                // 3. On cancel: deletes the entity
                // 4. On save: uses existing save logic
                return AnyView(
                    TypeOnlyFormWrapper(
                        dataType: dataType,
                        analysis: analysis,
                        formStrategy: formStrategy,
                        fieldHints: fieldHints,
                        inputHandlingManager: inputHandlingManager,
                        customFieldView: { name, value, type in
                            AnyView(customFieldView(name, value, type))
                        },
                        onSubmit: onSubmit,
                        onCancel: onCancel
                    )
                )
            } else {
                // Cannot generate form without instance data and fully declarative hints
                let i18n = InternationalizationService()
                return AnyView(
                    VStack {
                        Text(i18n.localizedString(for: "SixLayerFramework.form.cannotGenerate"))
                            .font(.headline)
                        Text(i18n.localizedString(for: "SixLayerFramework.form.fullyDeclarativeRequired"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                )
            }
        }
        
        // Analyze data - will use hints-first if available, Mirror as fallback
        let analysis = DataIntrospectionEngine.analyze(initialData)
        let formStrategy = determineFormStrategy(analysis: analysis)
        
        // Auto-create dataBinder if enabled and not provided
        // Note: initialData is guaranteed to be non-nil here (we checked above)
        let effectiveDataBinder: DataBinder<T>?
        if let providedBinder = dataBinder {
            effectiveDataBinder = providedBinder
        } else if autoBind && supportsAutoBinding(initialData!, analysis: analysis) {
            effectiveDataBinder = createAutoDataBinder(for: initialData!, analysis: analysis)
        } else {
            effectiveDataBinder = nil
        }
        
        // Load hints for the model type
        let modelName = String(describing: type(of: initialData))
            .components(separatedBy: ".").last ?? String(describing: type(of: initialData))
        let hintsLoader = FileBasedDataHintsLoader()
        let hintsResult = hintsLoader.loadHintsResult(for: modelName)
        let fieldHints = hintsResult.fieldHints
        
        let content = withAnalysisContext(analysis) {
            Group {
            switch formStrategy.containerType {
            case .form:
                // Wrap in DynamicFormView structure for accessibility testing
                VStack(spacing: 20) {
                    // DynamicFormHeader - form title/description
                    platformVStackContainer(alignment: .leading, spacing: 8) {
                        let i18n = InternationalizationService()
Text(i18n.localizedString(for: "SixLayerFramework.form.title"))
                            .font(.headline)
                            .automaticCompliance(named: "FormTitle")
                    }
                    .automaticCompliance(named: "DynamicFormHeader")
                    
                    // DynamicFormSectionView - form content sections
                    platformFormContainer_L4(
                        strategy: formStrategy,
                        content: {
                            generateFormContent(
                                analysis: analysis,
                                initialData: initialData,
                                dataBinder: effectiveDataBinder,
                                inputHandlingManager: inputHandlingManager,
                                customFieldView: customFieldView,
                                formStrategy: formStrategy,
                                fieldHints: fieldHints
                            )
                        }
                    )
                    .automaticCompliance(named: "DynamicFormSectionView")
                }
                .automaticCompliance(named: "DynamicFormView")
                .overlay(
                    generateFormActions(
                        initialData: initialData,
                        onSubmit: onSubmit,
                        onCancel: onCancel
                    )
                )
                
            case .standard, .scrollView, .custom, .adaptive:
                // Wrap in DynamicFormView structure for accessibility testing
                VStack(spacing: 20) {
                    // DynamicFormHeader - form title/description
                    platformVStackContainer(alignment: .leading, spacing: 8) {
                        let i18n = InternationalizationService()
Text(i18n.localizedString(for: "SixLayerFramework.form.title"))
                            .font(.headline)
                            .automaticCompliance(named: "FormTitle")
                    }
                    .automaticCompliance(named: "DynamicFormHeader")
                    
                    // DynamicFormSectionView - form content sections
                    platformFormContainer_L4(
                        strategy: formStrategy,
                        content: {
                            generateFormContent(
                                analysis: analysis,
                                initialData: initialData,
                                dataBinder: effectiveDataBinder,
                                inputHandlingManager: inputHandlingManager,
                                customFieldView: customFieldView,
                                formStrategy: formStrategy,
                                fieldHints: fieldHints
                            )
                        }
                    )
                    .automaticCompliance(named: "DynamicFormSectionView")
                }
                .automaticCompliance(named: "DynamicFormView")
                .overlay(
                    generateFormActions(
                        initialData: initialData,
                        onSubmit: onSubmit,
                        onCancel: onCancel
                    )
                )
            }
            }
        }
        // Apply IntelligentFormView identifier at the outermost level
        // Inner components (DynamicFormView, DynamicFormHeader, etc.) maintain their own identifiers
        return AnyView(content
            .automaticCompliance(named: "IntelligentFormView"))
    }
    
    /// Generate a form for updating existing data with data binding integration
    ///
    /// **Automatic Data Binding**:
    /// By default (`autoBind: true`), a `DataBinder` is automatically created if:
    /// - No `dataBinder` is explicitly provided
    /// - The model appears to support binding (has analyzable fields)
    ///
    /// The automatically created `DataBinder` instance is available but fields must
    /// be manually bound using key paths. See `DataBinder.bind(_:to:)` for details.
    ///
    /// **Opt-Out**: Set `autoBind: false` to disable automatic `DataBinder` creation.
    /// This is useful for read-only forms, immutable models, or external state management.
    ///
    /// **Entity Auto-Save (Issue #80)**:
    /// By default, entities are automatically saved periodically (every 30 seconds).
    /// Set `autoSaveInterval` to 0 to disable auto-save, or customize the interval.
    /// Draft entities (newly created) are marked and saved automatically.
    ///
    /// - Parameters:
    ///   - data: The data model instance to edit
    ///   - dataBinder: Optional explicit DataBinder. If provided, `autoBind` is ignored.
    ///   - autoBind: Whether to automatically create a DataBinder (default: true)
    ///   - inputHandlingManager: Optional input handling manager
    ///   - customFieldView: Custom view builder for field rendering
    ///   - onUpdate: Callback when form is updated
    ///   - onCancel: Callback when form is cancelled
    ///   - isDraft: Whether this entity is a draft (created but not yet submitted) (default: false)
    ///   - autoSaveInterval: Interval for periodic auto-save in seconds (default: 30.0, set to 0 to disable)
    /// - Returns: A view representing the generated form
    public static func generateForm<T>(
        for data: T,
        dataBinder: DataBinder<T>? = nil,
        autoBind: Bool = true,
        inputHandlingManager: InputHandlingManager? = nil,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View = { _, _, _ in EmptyView() },
        onUpdate: @escaping (T) -> Void = { _ in },
        onCancel: @escaping () -> Void = { },
        isDraft: Bool = false,
        autoSaveInterval: TimeInterval = 30.0
    ) -> some View {
        let analysis = DataIntrospectionEngine.analyze(data)
        let formStrategy = determineFormStrategy(analysis: analysis)
        
        // Auto-create dataBinder if enabled and not provided
        let effectiveDataBinder: DataBinder<T>?
        if let providedBinder = dataBinder {
            effectiveDataBinder = providedBinder
        } else if autoBind && supportsAutoBinding(data, analysis: analysis) {
            effectiveDataBinder = createAutoDataBinder(for: data, analysis: analysis)
        } else {
            effectiveDataBinder = nil
        }
        
        // Load hints for the model type
        let modelName = String(describing: type(of: data))
            .components(separatedBy: ".").last ?? String(describing: type(of: data))
        let hintsLoader = FileBasedDataHintsLoader()
        let hintsResult = hintsLoader.loadHintsResult(for: modelName)
        let fieldHints = hintsResult.fieldHints
        
        let content = withAnalysisContext(analysis) {
            Group {
            switch formStrategy.containerType {
            case .form:
                // Wrap in DynamicFormView structure for accessibility testing
                VStack(spacing: 20) {
                    // DynamicFormHeader - form title/description
                    platformVStackContainer(alignment: .leading, spacing: 8) {
                        let i18n = InternationalizationService()
Text(i18n.localizedString(for: "SixLayerFramework.form.title"))
                            .font(.headline)
                            .automaticCompliance(named: "FormTitle")
                    }
                    .automaticCompliance(named: "DynamicFormHeader")
                    
                    // DynamicFormSectionView - form content sections
                    platformFormContainer_L4(
                        strategy: formStrategy,
                        content: {
                            generateFormContent(
                                analysis: analysis,
                                initialData: data,
                                dataBinder: effectiveDataBinder,
                                inputHandlingManager: inputHandlingManager,
                                customFieldView: customFieldView,
                                formStrategy: formStrategy,
                                fieldHints: fieldHints
                            )
                        }
                    )
                    .automaticCompliance(named: "DynamicFormSectionView")
                }
                .automaticCompliance(named: "DynamicFormView")
                .overlay(
                    generateFormActions(
                        initialData: data,
                        onSubmit: { onUpdate($0) },
                        onCancel: onCancel,
                        isDraft: isDraft
                    )
                )
                
            case .standard, .scrollView, .custom, .adaptive:
                // Wrap in DynamicFormView structure for accessibility testing
                VStack(spacing: 20) {
                    // DynamicFormHeader - form title/description
                    platformVStackContainer(alignment: .leading, spacing: 8) {
                        let i18n = InternationalizationService()
Text(i18n.localizedString(for: "SixLayerFramework.form.title"))
                            .font(.headline)
                            .automaticCompliance(named: "FormTitle")
                    }
                    .automaticCompliance(named: "DynamicFormHeader")
                    
                    // DynamicFormSectionView - form content sections
                    platformFormContainer_L4(
                        strategy: formStrategy,
                        content: {
                            generateFormContent(
                                analysis: analysis,
                                initialData: data,
                                dataBinder: effectiveDataBinder,
                                inputHandlingManager: inputHandlingManager,
                                customFieldView: customFieldView,
                                formStrategy: formStrategy,
                                fieldHints: fieldHints
                            )
                        }
                    )
                    .automaticCompliance(named: "DynamicFormSectionView")
                }
                .automaticCompliance(named: "DynamicFormView")
                .overlay(
                    generateFormActions(
                        initialData: data,
                        onSubmit: { onUpdate($0) },
                        onCancel: onCancel,
                        isDraft: isDraft
                    )
                )
            }
            }
        }
        // Apply IntelligentFormView identifier at the outermost level
        // Inner components (DynamicFormView, DynamicFormHeader, etc.) maintain their own identifiers
        return AnyView(content
            .automaticCompliance(named: "IntelligentFormView"))
    }
    
    /// Generate form action buttons for type-only forms
    /// Note: Type-only forms don't have instance data, so submit is handled differently
    private static func generateTypeOnlyFormActions(
        onCancel: @escaping () -> Void
    ) -> some View {
        VStack {
            Spacer()
            let i18n = InternationalizationService()
            platformHStackContainer(spacing: 12) {
                Button(i18n.localizedString(for: "SixLayerFramework.button.cancel")) { onCancel() }
                    .buttonStyle(.bordered)
                    .foregroundColor(Color.platformLabel)

                Spacer()

                // Note: For type-only forms, submit would need to collect values from form state
                // This is a limitation - we can't automatically construct T from collected values
                // Users can access form field values through their own state management
                Button(i18n.localizedString(for: "SixLayerFramework.button.create")) {
                    // Type-only forms: values are collected in form state
                    // Users need to access values through their own state management
                    // or use a different API that accepts [String: Any]
                    onCancel() // For now, just cancel - proper implementation would collect values
                }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(Color.platformBackground)
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
            .automaticCompliance(named: "DynamicFormActions")
        }
    }
    
    // MARK: - Private Implementation
    
    /// Determine the best form strategy based on data analysis
    private static func determineFormStrategy(
        analysis: DataAnalysisResult
    ) -> FormStrategy {
        let containerType: FormContainerType
        let fieldLayout: FieldLayout
        let validation: ValidationStrategy
        
        // Analyze data characteristics to determine optimal strategy
        switch (analysis.complexity, analysis.fields.count) {
        case (.simple, 0...3):
            containerType = .form
            fieldLayout = .vertical
            validation = .immediate
        case (.simple, 4...7):
            containerType = .standard
            fieldLayout = .vertical
            validation = .deferred
        case (.moderate, _):
            containerType = .standard
            fieldLayout = .adaptive
            validation = .deferred
        case (.complex, _):
            containerType = .scrollView
            fieldLayout = .adaptive
            validation = .deferred
        case (.veryComplex, _):
            containerType = .custom
            fieldLayout = .adaptive
            validation = .deferred
        default:
            containerType = .adaptive
            fieldLayout = .adaptive
            validation = .deferred
        }
        
        return FormStrategy(
            containerType: containerType,
            fieldLayout: fieldLayout,
            validation: validation
        )
    }
    
    /// Generate the main form content using our platform extensions
    private static func generateFormContent<T>(
        analysis: DataAnalysisResult,
        initialData: T?,
        dataBinder: DataBinder<T>?,
        inputHandlingManager: InputHandlingManager?,
        customFieldView: @escaping (String, Any, FieldType) -> some View,
        formStrategy: FormStrategy,
        fieldHints: [String: FieldDisplayHints] = [:]
    ) -> some View {
        Group {
            switch formStrategy.fieldLayout {
            case .vertical:
                generateVerticalLayout(
                    analysis: analysis,
                    initialData: initialData,
                    dataBinder: dataBinder,
                    inputHandlingManager: inputHandlingManager,
                    customFieldView: customFieldView,
                    fieldHints: fieldHints
                )
                
            case .horizontal:
                generateHorizontalLayout(
                    analysis: analysis,
                    initialData: initialData,
                    dataBinder: dataBinder,
                    inputHandlingManager: inputHandlingManager,
                    customFieldView: customFieldView,
                    fieldHints: fieldHints
                )
                
            case .grid:
                generateGridLayout(
                    analysis: analysis,
                    initialData: initialData,
                    dataBinder: dataBinder,
                    inputHandlingManager: inputHandlingManager,
                    customFieldView: customFieldView
                )
                
            case .adaptive:
                generateAdaptiveLayout(
                    analysis: analysis,
                    initialData: initialData,
                    dataBinder: dataBinder,
                    inputHandlingManager: inputHandlingManager,
                    customFieldView: customFieldView,
                    formStrategy: formStrategy,
                    fieldHints: fieldHints
                )
                
            case .compact, .standard, .spacious:
                generateVerticalLayout(
                    analysis: analysis,
                    initialData: initialData,
                    dataBinder: dataBinder,
                    inputHandlingManager: inputHandlingManager,
                    customFieldView: customFieldView,
                    fieldHints: fieldHints
                )
            }
        }
    }
    
    /// Filter out hidden fields based on hints
    private static func filterHiddenFields(_ fields: [DataField], hints: [String: FieldDisplayHints]) -> [DataField] {
        return fields.filter { field in
            guard let hint = hints[field.name] else { return true } // Show if no hint
            return !hint.isHidden // Hide if hint says so
        }
    }
    
    /// Generate vertical field layout with intelligent grouping
    private static func generateVerticalLayout<T>(
        analysis: DataAnalysisResult,
        initialData: T?,
        dataBinder: DataBinder<T>?,
        inputHandlingManager: InputHandlingManager?,
        customFieldView: @escaping (String, Any, FieldType) -> some View,
        fieldHints: [String: FieldDisplayHints] = [:]
    ) -> some View {
        platformVStackContainer(spacing: 16) {
            // Prefer explicit important fields first (e.g., title/name), avoid alphabetic-by-type
            let visibleFields = filterHiddenFields(analysis.fields, hints: fieldHints)
            let orderedFields = orderFieldsByPriority(visibleFields)
            ForEach(orderedFields, id: \.name) { field in
                generateFieldView(
                    field: field,
                    initialData: initialData,
                    dataBinder: dataBinder,
                    inputHandlingManager: inputHandlingManager,
                    customFieldView: customFieldView,
                    fieldHints: fieldHints
                )
            }
        }
    }
    
    /// Generate horizontal field layout (side-by-side fields)
    private static func generateHorizontalLayout<T>(
        analysis: DataAnalysisResult,
        initialData: T?,
        dataBinder: DataBinder<T>?,
        inputHandlingManager: InputHandlingManager?,
        customFieldView: @escaping (String, Any, FieldType) -> some View,
        fieldHints: [String: FieldDisplayHints] = [:]
    ) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            let orderedFields = orderFieldsByPriority(analysis.fields)
            ForEach(orderedFields, id: \.name) { field in
                generateFieldView(
                    field: field,
                    initialData: initialData,
                    dataBinder: dataBinder,
                    inputHandlingManager: inputHandlingManager,
                    customFieldView: customFieldView,
                    fieldHints: fieldHints
                )
            }
        }
    }
    
    /// Generate grid field layout
    private static func generateGridLayout<T>(
        analysis: DataAnalysisResult,
        initialData: T?,
        dataBinder: DataBinder<T>?,
        inputHandlingManager: InputHandlingManager?,
        customFieldView: @escaping (String, Any, FieldType) -> some View,
        fieldHints: [String: FieldDisplayHints] = [:]
    ) -> some View {
        let visibleFields = filterHiddenFields(analysis.fields, hints: fieldHints)
        let columns = min(3, max(1, Int(sqrt(Double(visibleFields.count)))))
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 16) {
            let orderedFields = orderFieldsByPriority(visibleFields)
            ForEach(orderedFields, id: \.name) { field in
                generateFieldView(
                    field: field,
                    initialData: initialData,
                    dataBinder: dataBinder,
                    inputHandlingManager: inputHandlingManager,
                    customFieldView: customFieldView,
                    fieldHints: fieldHints
                )
            }
        }
    }
    
    /// Generate adaptive field layout based on content
    private static func generateAdaptiveLayout<T>(
        analysis: DataAnalysisResult,
        initialData: T?,
        dataBinder: DataBinder<T>?,
        inputHandlingManager: InputHandlingManager?,
        customFieldView: @escaping (String, Any, FieldType) -> some View,
        formStrategy: FormStrategy,
        fieldHints: [String: FieldDisplayHints] = [:]
    ) -> some View {
        let visibleFields = filterHiddenFields(analysis.fields, hints: fieldHints)
        if visibleFields.count <= 4 {
            return AnyView(generateVerticalLayout(
                analysis: analysis,
                initialData: initialData,
                dataBinder: dataBinder,
                inputHandlingManager: inputHandlingManager,
                customFieldView: customFieldView,
                fieldHints: fieldHints
            ))
        } else if visibleFields.count <= 8 {
            return AnyView(generateHorizontalLayout(
                analysis: analysis,
                initialData: initialData,
                dataBinder: dataBinder,
                inputHandlingManager: inputHandlingManager,
                customFieldView: customFieldView,
                fieldHints: fieldHints
            ))
        } else {
            return AnyView(generateGridLayout(
                analysis: analysis,
                initialData: initialData,
                dataBinder: dataBinder,
                inputHandlingManager: inputHandlingManager,
                customFieldView: customFieldView,
                fieldHints: fieldHints
            ))
        }
    }
    
    /// Group fields by type for better organization
    private static func groupFieldsByType(_ fields: [DataField]) -> [FieldType: [DataField]] {
        var grouped: [FieldType: [DataField]] = [:]
        
        for field in fields {
            if grouped[field.type] == nil {
                grouped[field.type] = []
            }
            grouped[field.type]?.append(field)
        }
        
        return grouped
    }
    
    /// Get human-readable title for field type
    private static func getFieldTypeTitle(_ fieldType: FieldType) -> String {
        switch fieldType {
        case .string: return "Text Fields"
        case .number: return "Numeric Fields"
        case .boolean: return "Toggle Fields"
        case .date: return "Date Fields"
        case .url: return "URL Fields"
        case .uuid: return "Identifier Fields"
        case .image: return "Media Fields"
        case .document: return "Document Fields"
        case .relationship: return "Relationship Fields"
        case .hierarchical: return "Hierarchical Fields"
        case .custom: return "Custom Fields"
        }
    }
    
    /// Generate individual field view using our platform extensions
    private static func generateFieldView<T>(
        field: DataField,
        initialData: T?,
        dataBinder: DataBinder<T>?,
        inputHandlingManager: InputHandlingManager?,
        customFieldView: @escaping (String, Any, FieldType) -> some View,
        fieldHints: [String: FieldDisplayHints] = [:]
    ) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            // Field label with required indicator
            HStack {
                Text(field.name.capitalized)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.platformLabel)
                if !field.isOptional {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            }
            .accessibilityLabel(!field.isOptional ? "\(field.name.capitalized), required" : field.name.capitalized)
            
            // Field input
            // Use custom field view if provided, otherwise use default
            let hints = fieldHints[field.name]
            let fieldValue = initialData != nil 
                ? extractFieldValue(from: initialData!, fieldName: field.name) 
                : getDefaultValue(for: field, hint: hints) // Use hint defaultValue if available
            
            // Use custom field view if provided, otherwise use default with hints
            // Note: We check if hints exist to determine if we should use DefaultPlatformFieldView
            // The customFieldView parameter allows overriding the default behavior
            Group {
                if hints != nil {
                    // Use default field view with hints support (includes picker rendering)
                    DefaultPlatformFieldView(
                        field: field,
                        value: fieldValue,
                        hints: hints,
                        onValueChange: { newValue in
                            // Update dataBinder if available for real-time model updates
                            if let dataBinder = dataBinder {
                                dataBinder.updateField(field.name, value: newValue)
                            }
                            // For type-only forms, values are collected in wrapper's @State
                            // (handled by TypeOnlyFormWrapper)
                        }
                    )
                } else {
                    // Use custom field view (or EmptyView if not provided)
                    customFieldView(field.name, fieldValue, field.type)
                }
            }
            
            // Field description if available
            if let description = getFieldDescription(for: field) {
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.platformSecondaryLabel)
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Generate form action buttons using our platform extensions
    private static func generateFormActions<T>(
        initialData: T?,
        onSubmit: @escaping (T) -> Void,
        onCancel: @escaping () -> Void,
        isDraft: Bool = false
    ) -> some View {
        VStack {
            Spacer()
            let i18n = InternationalizationService()
            platformHStackContainer(spacing: 12) {
                Button(i18n.localizedString(for: "SixLayerFramework.button.cancel")) { onCancel() }
                    .buttonStyle(.bordered)
                    .foregroundColor(Color.platformLabel)

                Spacer()

                Button(initialData != nil ? i18n.localizedString(for: "SixLayerFramework.button.update") : i18n.localizedString(for: "SixLayerFramework.button.create")) {
                    // Note: For SwiftData models, ModelContext should be passed explicitly
                    // In a SwiftUI view, you can get it from @Environment(\.modelContext)
                    // For now, handleSubmit will attempt to find it via reflection (may not work reliably)
                    // Future enhancement: Modify generateFormActions to accept optional ModelContext parameter
                    handleSubmit(
                        initialData: initialData,
                        modelContext: nil, // TODO: Could be enhanced to get from @Environment(\.modelContext) if available
                        onSubmit: onSubmit,
                        isDraft: isDraft
                    )
                }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(Color.platformBackground)
            }
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
            .automaticCompliance(named: "DynamicFormActions")
        }
    }
    
    // MARK: - Helper Functions
    
    /// Handle form submission with auto-persistence for Core Data and SwiftData entities
    /// Implements Issue #8, #9, and #20: Auto-save Core Data and SwiftData entities
    /// Also implements Issue #80: Clear draft flag when entity is submitted
    /// 
    /// - Parameters:
    ///   - initialData: The data model to save (Core Data NSManagedObject or SwiftData PersistentModel)
    ///   - modelContext: Optional ModelContext for SwiftData models (iOS 17+, macOS 14+). 
    ///                  If nil and data is a SwiftData model, will attempt to find context via reflection.
    ///                  For best results, pass the ModelContext explicitly.
    ///   - onSubmit: Callback to execute after auto-save
    ///   - isDraft: Whether this entity is a draft (will clear draft flag on submit)
    @MainActor
    internal static func handleSubmit<T>(
        initialData: T?,
        modelContext: Any? = nil,
        onSubmit: @escaping (T) -> Void,
        isDraft: Bool = false
    ) {
        guard let data = initialData else {
            print("Warning: Submit attempted without initialData; ignoring")
            return
        }
        
        // Step 1: Auto-save Core Data entities if applicable (Issue #9)
        // This ensures Core Data entities are saved even if onSubmit is empty (Issue #8)
        #if canImport(CoreData)
        if let managedObject = data as? NSManagedObject,
           let context = managedObject.managedObjectContext {
            do {
                // Update timestamp if property exists
                if managedObject.entity.attributesByName["updatedAt"] != nil {
                    managedObject.setValue(Date(), forKey: "updatedAt")
                } else if managedObject.entity.attributesByName["modifiedAt"] != nil {
                    managedObject.setValue(Date(), forKey: "modifiedAt")
                } else if managedObject.entity.attributesByName["lastModified"] != nil {
                    managedObject.setValue(Date(), forKey: "lastModified")
                }
                
                // Clear draft flag if entity was a draft (Issue #80)
                if isDraft && managedObject.entity.attributesByName["isDraft"] != nil {
                    managedObject.setValue(false, forKey: "isDraft")
                }
                
                // Save the context
                if context.hasChanges {
                    try context.save()
                    // Note: Visual feedback would require @State or environment object
                    // For now, we rely on the developer's onSubmit callback for feedback
                }
            } catch {
                // Log error but don't crash - developer's onSubmit may handle it
                print("Error auto-saving Core Data entity: \(error.localizedDescription)")
                // In a future enhancement, we could show an error alert here
            }
        }
        #endif
        
        // Step 1b: Auto-save SwiftData models if applicable (Issue #20)
        // This ensures SwiftData models are saved even if onSubmit is empty
        #if canImport(SwiftData)
        if #available(macOS 14.0, iOS 17.0, *) {
            if let persistentModel = data as? any PersistentModel {
                // SwiftData models need their ModelContext to save
                // Use provided context or attempt to find via reflection (may not work reliably)
                var contextToUse: ModelContext? = nil
                
                // First, try to use the provided context (preferred method)
                if let providedContext = modelContext as? ModelContext {
                    contextToUse = providedContext
                } else {
                    // Attempt to find ModelContext via reflection (fallback, may not work)
                    // SwiftData models don't expose their context directly, but we can try
                    let modelMirror = Mirror(reflecting: persistentModel)
                    for child in modelMirror.children {
                        if let label = child.label,
                           (label == "modelContext" || label == "_modelContext" || 
                            label.contains("context") || label.contains("Context")) {
                            if let context = child.value as? ModelContext {
                                contextToUse = context
                                break
                            }
                        }
                    }
                }
                
                // If we have a context, save it
                if let context = contextToUse {
                    do {
                        // Attempt to update timestamp properties if they exist
                        // Note: Swift doesn't support direct property setting via reflection
                        // We detect the properties but can't set them - developers should update timestamps
                        // in their models or in the onSubmit callback
                        updateSwiftDataTimestampsIfNeeded(persistentModel)
                        
                        // Save the context if it has changes
                        if context.hasChanges {
                            try context.save()
                        }
                    } catch {
                        // Log error but don't crash - developer's onSubmit may handle it
                        print("Error auto-saving SwiftData model: \(error.localizedDescription)")
                        // Continue execution - onSubmit callback will still be called
                    }
                } else {
                    // Couldn't find ModelContext - log warning but continue
                    // The developer's onSubmit callback can handle saving if needed
                    print("SwiftData model auto-save: Could not access ModelContext. " +
                          "Pass ModelContext explicitly via modelContext parameter, or handle saving in onSubmit callback.")
                }
            }
        }
        #endif
        
        // Step 2: Call developer's onSubmit callback (for custom logic after auto-save)
        // This allows developers to add custom logic like navigation, notifications, etc.
        onSubmit(data)
    }
    
    // MARK: - SwiftData Helper Functions
    
    #if canImport(SwiftData)
    /// Attempts to detect timestamp properties on a SwiftData model
    /// Note: Direct property setting via reflection is not possible in Swift
    /// This function detects timestamp properties but cannot update them directly
    /// Developers should update timestamps in their models or in onSubmit callback
    /// 
    /// Example in onSubmit callback:
    /// ```swift
    /// onSubmit: { model in
    ///     if var task = model as? Task {
    ///         task.updatedAt = Date()
    ///     }
    ///     // ... other logic
    /// }
    /// ```
    @available(macOS 14.0, iOS 17.0, *)
    private static func updateSwiftDataTimestampsIfNeeded(_ model: any PersistentModel) {
        // Check if model has timestamp properties that should be updated
        // Note: We can only detect, not update via reflection
        let mirror = Mirror(reflecting: model)
        let timestampProperties = ["updatedAt", "modifiedAt", "lastModified"]
        
        // Detect if any timestamp properties exist
        for child in mirror.children {
            if let label = child.label, timestampProperties.contains(label) {
                // Timestamp property exists - developers should update it manually
                // This is a limitation of Swift's reflection API
                return
            }
        }
    }
    #endif
    
    /// Extract field value from an object using reflection or KVC
    /// Delegates to shared DataValueExtraction utility
    private static func extractFieldValue(from object: Any, fieldName: String) -> Any {
        return DataValueExtraction.extractFieldValue(from: object, fieldName: fieldName)
    }
    
    /// Get default value for a field, preferring hint defaultValue if available
    private static func getDefaultValue(for field: DataField, hint: FieldDisplayHints? = nil) -> Any {
        // If hint provides a defaultValue, use it
        if let hint = hint, let defaultValue = hint.defaultValue {
            return defaultValue
        }
        
        // Otherwise use type-based defaults
        switch field.type {
        case .string:
            return ""
        case .number:
            return 0
        case .boolean:
            return false
        case .date:
            return Date()
        case .url:
            return URL(string: "https://example.com") ?? URL(string: "https://example.com")!
        case .uuid:
            return UUID()
        case .image, .document:
            return ""
        case .relationship, .hierarchical, .custom:
            return ""
        }
    }
    
    /// Get field description based on field characteristics
    private static func getFieldDescription(for field: DataField) -> String? {
        var descriptions: [String] = []
        
        if field.isOptional {
            descriptions.append("Optional")
        }
        
        if field.isArray {
            descriptions.append("Multiple values")
        }
        
        if field.hasDefaultValue {
            descriptions.append("Has default")
        }
        
        return descriptions.isEmpty ? nil : descriptions.joined(separator: " • ")
    }
}

// MARK: - Default Platform Field View

/// Default platform field view using our cross-platform system
@MainActor
private struct DefaultPlatformFieldView: View {

    let field: DataField
    let value: Any
    let hints: FieldDisplayHints?
    let onValueChange: (Any) -> Void
    
    /// Whether the field is editable (defaults to true if hints not provided)
    private var isEditable: Bool {
        return hints?.isEditable ?? true
    }
    
    init(field: DataField, value: Any, hints: FieldDisplayHints? = nil, onValueChange: @escaping (Any) -> Void) {
        self.field = field
        self.value = value
        self.hints = hints
        self.onValueChange = onValueChange
    }
    
    // Computed property to get field errors
    private var fieldErrors: [String] {
        [] // No validation errors without FormStateManager
    }
    
    // Computed property to check if field is valid
    private var isValid: Bool {
        true // Always valid without FormStateManager
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 4) {
            // Main field input
            fieldInputView
            
            // Error display
            if !fieldErrors.isEmpty {
                errorDisplayView
            }
        }
        .automaticCompliance()
    }
    
    @ViewBuilder
    private var fieldInputView: some View {
        switch field.type {
        case .string:
            // Check if this should be a picker based on hints
            if let hints = hints, hints.inputType == "picker", let options = hints.pickerOptions, !options.isEmpty {
                // Render picker for enum fields using platformPicker (Issue #163)
                // Use dynamic binding that reads from value and writes via onValueChange
                platformPicker(
                    label: field.name.capitalized,
                    selection: Binding<String>(
                        get: {
                            // Get current value as String, defaulting to first option if not set
                            let currentValue = (value as? String) ?? options.first?.value ?? ""
                            // Ensure the value is valid (exists in options), otherwise use first option
                            return options.contains(where: { $0.value == currentValue }) ? currentValue : (options.first?.value ?? "")
                        },
                        set: { newValue in
                            if isEditable {
                                onValueChange(newValue)
                            }
                        }
                    ),
                    options: options,
                    pickerName: "IntelligentFormPicker"
                )
                .disabled(!isEditable)
            } else {
                // Default TextField for string fields
                TextField("Enter \(field.name)", text: Binding(
                    get: { value as? String ?? "" },
                    set: { if isEditable { onValueChange($0) } }
                ))
                .textFieldStyle(.roundedBorder)
                .disabled(!isEditable)
                .background(isValid ? Color.platformSecondaryBackground : Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
                )
            }

        case .number:
            HStack {
                TextField("Enter \(field.name)", value: Binding(
                    get: { value as? Double ?? 0.0 },
                    set: { if isEditable { onValueChange($0) } }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .disabled(!isEditable)
                #if os(iOS)
                .keyboardType(UIKeyboardType.decimalPad)
                #endif
                .background(isValid ? Color.platformSecondaryBackground : Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
                )

                Stepper("", value: Binding(
                    get: { value as? Double ?? 0.0 },
                    set: { if isEditable { onValueChange($0) } }
                ), in: 0...1000)
                .disabled(!isEditable)
            }

        case .boolean:
            Toggle(field.name.capitalized, isOn: Binding(
                get: { value as? Bool ?? false },
                set: { if isEditable { onValueChange($0) } }
            ))
            .disabled(!isEditable)

        case .date:
            DatePicker(
                field.name.capitalized,
                selection: Binding(
                    get: { value as? Date ?? Date() },
                    set: { if isEditable { onValueChange($0) } }
                ),
                displayedComponents: [.date]
            )
            .disabled(!isEditable)

        case .url:
            TextField("Enter URL", text: Binding(
                get: { value as? String ?? "" },
                set: { if isEditable { onValueChange($0) } }
            ))
            .textFieldStyle(.roundedBorder)
            .disabled(!isEditable)
            #if os(iOS)
            .keyboardType(UIKeyboardType.URL)
            .autocapitalization(.none)
            #endif
            .background(isValid ? Color.platformSecondaryBackground : Color.red.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
            )

        case .uuid:
            TextField("Enter UUID", text: Binding(
                get: { value as? String ?? "" },
                set: { if isEditable { onValueChange($0) } }
            ))
            .textFieldStyle(.roundedBorder)
            .disabled(!isEditable)
            #if os(iOS)
            .autocapitalization(.none)
            #endif
            .background(isValid ? Color.platformSecondaryBackground : Color.red.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
            )

        case .image, .document:
            Button("Select \(field.type.rawValue)") {
                // File picker implementation would go here
                if isEditable {
                    onValueChange("")
                }
            }
            .buttonStyle(.bordered)
            .disabled(!isEditable)

        case .relationship, .hierarchical, .custom:
            TextField("Enter \(field.name)", text: Binding(
                get: { value as? String ?? "" },
                set: { if isEditable { onValueChange($0) } }
            ))
            .textFieldStyle(.roundedBorder)
            .disabled(!isEditable)
            .background(isValid ? Color.platformSecondaryBackground : Color.red.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var errorDisplayView: some View {
        platformVStackContainer(alignment: .leading, spacing: 2) {
            ForEach(Array(fieldErrors.enumerated()), id: \.offset) { index, error in
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: errorIcon(for: "error"))
                        .foregroundColor(errorColor(for: "error"))
                        .font(.caption)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(errorColor(for: "error"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func errorIcon(for severity: String) -> String {
        guard let errorSeverity = ErrorSeverity(rawValue: severity) else {
            // Unknown severity - log for debugging but don't crash
            print("Warning: Unknown error severity '\(severity)', defaulting to info")
            return ErrorSeverity.info.iconName
        }
        return errorSeverity.iconName
    }
    
    private func errorColor(for severity: String) -> Color {
        guard let errorSeverity = ErrorSeverity(rawValue: severity) else {
            // Unknown severity - log for debugging but don't crash
            print("Warning: Unknown error severity '\(severity)', defaulting to info")
            return ErrorSeverity.info.color
        }
        return errorSeverity.color
    }
}

// MARK: - Convenience Extensions

public extension View {
    
    /// Apply intelligent form generation
    internal func platformIntelligentForm<T>(
        for dataType: T.Type,
        initialData: T? = nil,
        dataBinder: DataBinder<T>? = nil,
        inputHandlingManager: InputHandlingManager? = nil,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View = { _, _, _ in EmptyView() },
        onSubmit: @escaping (T) -> Void = { _ in },
        onCancel: @escaping () -> Void = { }
    ) -> some View {
        IntelligentFormView.generateForm(
            for: dataType,
            initialData: initialData,
            dataBinder: dataBinder,
            inputHandlingManager: inputHandlingManager,
            customFieldView: customFieldView,
            onSubmit: onSubmit,
            onCancel: onCancel
        )
    }
    
    /// Apply intelligent form generation for existing data
    internal func platformIntelligentForm<T>(
        for data: T,
        dataBinder: DataBinder<T>? = nil,
        inputHandlingManager: InputHandlingManager? = nil,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View = { _, _, _ in EmptyView() },
        onUpdate: @escaping (T) -> Void = { _ in },
        onCancel: @escaping () -> Void = { }
    ) -> some View {
        IntelligentFormView.generateForm(
            for: data,
            dataBinder: dataBinder,
            inputHandlingManager: inputHandlingManager,
            customFieldView: customFieldView,
            onUpdate: onUpdate,
            onCancel: onCancel
        )
    }
}

// MARK: - Type-Only Form Wrapper

/// Wrapper view for type-only form generation (new object creation)
/// Creates a blank entity upfront, populates with defaults from hints, then uses existing update flow
@MainActor
private struct TypeOnlyFormWrapper<T>: View {
    let dataType: T.Type
    let analysis: DataAnalysisResult
    let formStrategy: FormStrategy
    let fieldHints: [String: FieldDisplayHints]
    let inputHandlingManager: InputHandlingManager?
    let customFieldView: (String, Any, FieldType) -> AnyView
    let onSubmit: (T) -> Void
    let onCancel: () -> Void
    
    // Environment contexts
    #if canImport(CoreData)
    @Environment(\.managedObjectContext) private var managedObjectContext
    #endif
    
    #if canImport(SwiftData)
    @available(macOS 14.0, iOS 17.0, *)
    @Environment(\.modelContext) private var modelContext: ModelContext
    #endif
    
    // State to hold the created entity
    @State private var createdEntity: T?
    @State private var isNewEntity: Bool = true // Track if entity should be deleted on cancel
    
    var body: some View {
        Group {
            if let entity = createdEntity {
                // Use existing update flow once entity is created
                // Mark as draft since it's a newly created entity (Issue #80)
                IntelligentFormView.generateForm(
                    for: entity,
                    onUpdate: { updatedEntity in
                        onSubmit(updatedEntity)
                    },
                    onCancel: {
                        handleCancel()
                    },
                    isDraft: isNewEntity, // Mark as draft if it's a new entity
                    autoSaveInterval: 30.0 // Auto-save every 30 seconds
                )
            } else {
                // Creating entity...
                ProgressView("Creating form...")
                    .onAppear {
                        createBlankEntity()
                    }
            }
        }
    }
    
    /// Create a blank entity and populate with defaults from hints
    private func createBlankEntity() {
        let modelName = String(describing: dataType)
            .components(separatedBy: ".").last ?? String(describing: dataType)
        
        // Try Core Data first
        #if canImport(CoreData)
        if let entity = createCoreDataEntity(entityName: modelName) {
            createdEntity = entity as? T
            isNewEntity = true
            return
        }
        #endif
        
        // Try SwiftData
        #if canImport(SwiftData)
        if #available(macOS 14.0, iOS 17.0, *) {
            if let entity = createSwiftDataEntity() {
                createdEntity = entity
                isNewEntity = true
                return
            }
        }
        #endif
        
        // If we can't create an entity, show error
        // (This shouldn't happen if hints are fully declarative)
    }
    
    #if canImport(CoreData)
    /// Create a blank Core Data entity and populate with defaults from hints
    /// DRY: Uses shared EntityCreationUtilities
    private func createCoreDataEntity(entityName: String) -> NSManagedObject? {
        let context = managedObjectContext
        
        // Use shared utility
        return EntityCreationUtilities.createBlankCoreDataEntity(
            entityName: entityName,
            context: context,
            fields: analysis.fields,
            fieldHints: fieldHints
        )
    }
    #endif
    
    #if canImport(SwiftData)
    /// Create a blank SwiftData entity using Codable or memberwise initializer
    @available(macOS 14.0, iOS 17.0, *)
    private func createSwiftDataEntity() -> T? {
        // Try Codable first (preferred)
        if let codableEntity = createSwiftDataEntityUsingCodable() {
            return codableEntity
        }
        
        // Fall back to memberwise initializer
        return createSwiftDataEntityUsingMemberwise()
    }
    
    /// Create SwiftData entity using Codable (preferred method)
    /// 
    /// **Note**: This requirement applies only to SwiftData (and plain Swift types).
    /// Core Data does not require Codable because it uses KVC (Key-Value Coding).
    /// 
    /// **Requirements**: T must conform to Codable for this to work.
    /// If T does not conform to Codable, memberwise initialization will be attempted.
    /// 
    /// See: `createSwiftDataEntityUsingMemberwise()` for fallback.
    /// DRY: Uses shared EntityCreationUtilities
    @available(macOS 14.0, iOS 17.0, *)
    private func createSwiftDataEntityUsingCodable() -> T? {
        let context = modelContext
        
        // Use shared utility
        if let entity = EntityCreationUtilities.createBlankSwiftDataEntity(
            entityType: T.self,
            context: context,
            fields: analysis.fields,
            fieldHints: fieldHints
        ) {
            return entity as? T
        }
        return nil
    }
    
    /// Create SwiftData entity using memberwise initializer (fallback)
    /// 
    /// **Limitation**: Swift does not support dynamic memberwise initialization at runtime.
    /// This method is a placeholder for future enhancement.
    /// 
    /// **Recommendation**: Make your SwiftData models conform to Codable for type-only form support.
    /// 
    /// For now, if Codable is not available, type-only forms will not work for SwiftData models.
    /// Use `generateForm(for: existingInstance)` instead with a pre-created instance.
    @available(macOS 14.0, iOS 17.0, *)
    private func createSwiftDataEntityUsingMemberwise() -> T? {
        // Swift does not support dynamic memberwise initialization at runtime.
        // We would need:
        // 1. Reflection to find the initializer
        // 2. Type information for each parameter
        // 3. Dynamic invocation (not possible in Swift)
        // 
        // Future enhancement: Could use SwiftSyntax or code generation to create
        // a helper initializer that accepts [String: Any] dictionary.
        return nil
    }
    #endif
    
    /// Get default value for a field type
    /// DRY: Uses shared EntityCreationUtilities
    private func getDefaultValueForType(_ fieldType: FieldType) -> Any {
        return EntityCreationUtilities.getDefaultValueForType(fieldType)
    }
    
    /// Handle cancel - delete the created entity if it's new
    private func handleCancel() {
        guard isNewEntity else {
            onCancel()
            return
        }
        
        // Delete the entity we created
        #if canImport(CoreData)
        if let managedObject = createdEntity as? NSManagedObject,
           let context = managedObject.managedObjectContext {
            context.delete(managedObject)
        }
        #endif
        
        #if canImport(SwiftData)
        if #available(macOS 14.0, iOS 17.0, *) {
            if let persistentModel = createdEntity as? any PersistentModel {
                let context = modelContext
                context.delete(persistentModel)
            }
        }
        #endif
        
        onCancel()
    }
}
