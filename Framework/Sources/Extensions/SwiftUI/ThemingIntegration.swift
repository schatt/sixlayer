import Foundation
import SwiftUI



// MARK: - Theming Integration
// Integration layer that applies theming to existing framework components

/// Themed wrapper for the SixLayer Framework
public struct ThemedFrameworkView<Content: View>: View {
    let content: Content
    @StateObject private var designSystem = VisualDesignSystem.shared

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .environmentObject(designSystem)
            .environment(\.theme, designSystem.currentTheme)
            .environment(\.platformStyle, designSystem.platformStyle)
            .environment(\.colorSystem, ColorSystem(from: designSystem.designSystem, theme: designSystem.currentTheme))
            .environment(\.typographySystem, TypographySystem(from: designSystem.designSystem, theme: designSystem.currentTheme))
            .environment(\.designSystem, designSystem.designSystem)
            .environment(\.designTokens, designSystem.currentColors)
            .environment(\.spacingTokens, designSystem.currentSpacing)
            .environment(\.componentStates, designSystem.currentComponentStates)
            .environment(\.accessibilitySettings, designSystem.accessibilitySettings)
            .preferredColorScheme(designSystem.currentTheme == .dark ? .dark : .light)
            .automaticCompliance(named: "ThemedFrameworkView")
    }
}

/// Themed version of IntelligentFormView
public struct ThemedIntelligentFormView<DataType: Codable>: View {
    let dataType: DataType.Type
    let initialData: DataType?
    let customFieldView: (String, Any, Binding<Any>) -> AnyView
    let onSubmit: (DataType) -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorSystem) private var colors
    @Environment(\.typographySystem) private var typography
    @Environment(\.platformStyle) private var platform
    
    public init(
        for dataType: DataType.Type,
        initialData: DataType? = nil,
        customFieldView: @escaping (String, Any, Binding<Any>) -> AnyView = { _, _, _ in AnyView(EmptyView()) },
        onSubmit: @escaping (DataType) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.dataType = dataType
        self.initialData = initialData
        self.customFieldView = customFieldView
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }
    
    public var body: some View {
        // Delegate to IntelligentFormView for actual form generation
        // This ensures ThemedIntelligentFormView benefits from all IntelligentFormView features,
        // including type-only form generation, hints-first discovery, and entity creation
        IntelligentFormView.generateForm(
            for: dataType,
            initialData: initialData,
            customFieldView: { name, value, fieldType in
                // Convert IntelligentFormView's customFieldView signature to ThemedIntelligentFormView's
                // ThemedIntelligentFormView expects (String, Any, Binding<Any>)
                // IntelligentFormView provides (String, Any, FieldType)
                // We create a binding from the value for the themed view
                customFieldView(name, value, Binding.constant(value))
            },
            onSubmit: onSubmit,
            onCancel: onCancel
        )
        .themedCard()
    }
}

/// Themed version of GenericFormView
// MARK: - DEPRECATED: This struct uses GenericFormField which has been deprecated
// TODO: Replace with DynamicFormField equivalents
/*
public struct ThemedGenericFormView: View {
    let fields: [GenericFormField]
    let onSubmit: ([String: Any]) -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorSystem) private var colors
    @Environment(\.typographySystem) private var typography
    @Environment(\.platformStyle) private var platform
    @State private var formData: [String: Any] = [:]
    
    public init(
        fields: [GenericFormField],
        onSubmit: @escaping ([String: Any]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.fields = fields
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }
    
    public var body: some View {
        platformVStackContainer(spacing: 0) {
            // Header
            HStack {
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.title"))
                    .font(typography.title2)
                    .foregroundColor(colors.text)
                Spacer()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldsCount", arguments: [String(fields.count)]))
                    .font(typography.caption1)
                    .foregroundColor(colors.textSecondary)
            }
            .padding(.horizontal)
            .padding(.top)
            .background(colors.surface)
            
            // Form content
            ScrollView {
                platformVStackContainer(spacing: 16) {
                    ForEach(fields, id: \.id) { field in
                        createFieldView(for: field)
                    }
                }
                .padding()
            }
            .background(colors.background)
            
            // Footer
            HStack {
                let i18n = InternationalizationService()
                AdaptiveUIPatterns.AdaptiveButton(
                    i18n.localizedString(for: "SixLayerFramework.button.cancel"),
                    style: .outline,
                    size: .medium,
                    action: onCancel
                )
                
                Spacer()
                
                AdaptiveUIPatterns.AdaptiveButton(
                    i18n.localizedString(for: "SixLayerFramework.button.submit"),
                    style: .primary,
                    size: .medium,
                    action: { onSubmit(formData) }
                )
            }
            .padding()
            .background(colors.surface)
        }
        .themedCard()
        .automaticCompliance(named: "ThemedGenericFormView")
    }
    
    private func createFieldView(for field: GenericFormField) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colors.text)
            
            switch field.fieldType {
            case .text:
                let i18n = InternationalizationService()
                TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterText"), text: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                .themedTextField()
                
            case .email:
                let i18n = InternationalizationService()
                TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterEmail"), text: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                .themedTextField()
                
            case .password:
                let i18n = InternationalizationService()
                SecureField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterPassword"), text: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                .themedTextField()
                
            case .number:
                let i18n = InternationalizationService()
                TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterNumber"), text: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                .themedTextField()
                
            case .date:
                let i18n = InternationalizationService()
                DatePicker(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectDate"), selection: Binding(
                    get: { formData[field.id.uuidString] as? Date ?? Date() },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                .datePickerStyle(.compact)
                
            case .select:
                let i18n = InternationalizationService()
                Picker(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectOption"), selection: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                )) {
                    Text(i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectOption")).tag("")
                    ForEach(field.options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .themedTextField()
                    
            case .textarea:
                TextEditor(text: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                .frame(minHeight: 100)
                .themedTextField()
                
            case .checkbox:
                Toggle(field.label, isOn: Binding(
                    get: { formData[field.id.uuidString] as? Bool ?? false },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                
            case .radio:
                platformVStackContainer(alignment: .leading) {
                    Text(field.label)
                        .font(typography.body)
                        .fontWeight(.medium)
                    
                    ForEach(field.options, id: \.self) { option in
                        HStack {
                            Button(action: {
                                formData[field.id.uuidString] = option
                            }) {
                                Image(systemName: (formData[field.id.uuidString] as? String ?? "") == option ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor((formData[field.id.uuidString] as? String ?? "") == option ? .blue : .gray)
                            }
                            Text(option)
                        }
                    }
                }
            case .phone:
                let i18n = InternationalizationService()
                TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterPhone"), text: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                .themedTextField()
            case .time:
                let i18n = InternationalizationService()
                DatePicker(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectTime"), selection: Binding(
                    get: { formData[field.id.uuidString] as? Date ?? Date() },
                    set: { formData[field.id.uuidString] = $0 }
                ), displayedComponents: .hourAndMinute)
            case .datetime:
                let i18n = InternationalizationService()
                DatePicker(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectDateTime"), selection: Binding(
                    get: { formData[field.id.uuidString] as? Date ?? Date() },
                    set: { formData[field.id.uuidString] = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
            case .multiselect:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.multiselect", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .file:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.fileUpload", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .url:
                let i18n = InternationalizationService()
                TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterURL"), text: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                .themedTextField()
            case .color:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.colorPicker", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .range:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.range", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .toggle, .boolean:
                let i18n = InternationalizationService()
                Toggle(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.toggle"), isOn: Binding(
                    get: { formData[field.id.uuidString] as? Bool ?? false },
                    set: { formData[field.id.uuidString] = $0 }
                ))
            case .richtext:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.richText", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .autocomplete:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.autocomplete", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .integer:
                let i18n = InternationalizationService()
                TextField(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.enterInteger"), text: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                ))
                .themedTextField()
            case .image:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.image", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .array:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.array", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .data:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.data", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .`enum`:
                let i18n = InternationalizationService()
                Picker(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectOption"), selection: Binding(
                    get: { formData[field.id.uuidString] as? String ?? "" },
                    set: { formData[field.id.uuidString] = $0 }
                )) {
                    Text(i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectOption")).tag("")
                    ForEach(field.options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .themedTextField()
            case .custom:
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.form.fieldType.custom", arguments: [field.label]))
                    .font(typography.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
*/

/// Themed version of ResponsiveCardView
public struct ThemedResponsiveCardView: View {
    let title: String
    let subtitle: String?
    let content: AnyView
    let action: (() -> Void)?
    
    @Environment(\.colorSystem) private var colors
    @Environment(\.typographySystem) private var typography
    @Environment(\.platformStyle) private var platform
    
    public init(
        title: String,
        subtitle: String? = nil,
        content: AnyView,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.action = action
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 12) {
            // Header
            platformVStackContainer(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(typography.headline)
                    .foregroundColor(colors.text)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            // Content
            content
            
            // Action button
            if let action = action {
                AdaptiveUIPatterns.AdaptiveButton(
                    "View Details",
                    style: .outline,
                    size: .small,
                    action: action
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .themedCard()
        .automaticCompliance(named: "ThemedResponsiveCardView")
    }
}

/// Themed version of GenericItemCollectionView
public struct ThemedGenericItemCollectionView: View {
    let items: [Any]
    let title: String
    let onItemTap: (Any) -> Void
    
    @Environment(\.colorSystem) private var colors
    @Environment(\.typographySystem) private var typography
    @Environment(\.platformStyle) private var platform
    
    public init(
        items: [Any],
        title: String,
        onItemTap: @escaping (Any) -> Void
    ) {
        self.items = items
        self.title = title
        self.onItemTap = onItemTap
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(title)
                    .font(typography.headline)
                    .foregroundColor(colors.text)
                Spacer()
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.list.itemsCount", arguments: [String(items.count)]))
                    .font(typography.caption1)
                    .foregroundColor(colors.textSecondary)
            }
            
            // Items grid
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button(action: { onItemTap(item) }) {
                        let i18n = InternationalizationService()
                        VStack {
                            Text(i18n.localizedString(for: "SixLayerFramework.list.itemNumber", arguments: [String(index + 1)]))
                                .font(typography.body)
                                .foregroundColor(colors.text)
                            Text(i18n.localizedString(for: "SixLayerFramework.list.tapToView"))
                                .font(typography.caption1)
                                .foregroundColor(colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .themedCard()
        .automaticCompliance(named: "ThemedGenericItemCollectionView")
    }
    
    private var gridColumns: [GridItem] {
        // Use PlatformStrategy for platform-specific grid column count (Issue #140)
        let sixLayerPlatform = convertPlatformStyle(platform)
        let columnCount = sixLayerPlatform.defaultGridColumnCount
        return Array(repeating: GridItem(.flexible()), count: columnCount)
    }
    
    private func convertPlatformStyle(_ platform: PlatformStyle) -> SixLayerPlatform {
        switch platform {
        case .ios: return .iOS
        case .macOS: return .macOS
        case .watchOS: return .watchOS
        case .tvOS: return .tvOS
        case .visionOS: return .visionOS
        }
    }
}

/// Themed version of GenericNumericDataView
public struct ThemedGenericNumericDataView: View {
    let data: [Double]
    let title: String
    let unit: String?
    
    @Environment(\.colorSystem) private var colors
    @Environment(\.typographySystem) private var typography
    @Environment(\.platformStyle) private var platform
    
    public init(
        data: [Double],
        title: String,
        unit: String? = nil
    ) {
        self.data = data
        self.title = title
        self.unit = unit
    }
    
    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(title)
                    .font(typography.headline)
                    .foregroundColor(colors.text)
                Spacer()
                if let unit = unit {
                    Text(unit)
                        .font(typography.caption1)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            // Data visualization
            platformVStackContainer(spacing: 8) {
                if let maxValue = data.max() {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        HStack {
                            Text("\(index + 1)")
                                .font(typography.caption1)
                                .foregroundColor(colors.textSecondary)
                                .frame(width: 20, alignment: .leading)
                            
                            ThemedProgressBar(
                                progress: maxValue > 0 ? value / maxValue : 0,
                                variant: .primary
                            )
                            
                            Text(String(format: "%.1f", value))
                                .font(typography.caption1)
                                .foregroundColor(colors.text)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .themedCard()
        .automaticCompliance(named: "ThemedGenericNumericDataView")
    }
}

// MARK: - View Extensions

public extension View {
    /// Wrap this view with the themed framework system
    func withThemedFramework() -> some View {
        ThemedFrameworkView {
            self
        }
    }
}
