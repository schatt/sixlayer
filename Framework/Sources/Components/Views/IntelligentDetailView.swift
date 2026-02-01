//
//  IntelligentDetailView.swift
//  SixLayerFramework
//
//  Intelligent detail view generation based on data introspection
//

import SwiftUI
import CoreData
#if canImport(SwiftData)
import SwiftData
#endif

// MARK: - Intelligent Detail View Engine

/// Intelligent detail view engine that automatically generates UIs from data models
@MainActor
public struct IntelligentDetailView {
    
    /// Generate a detail view for a data model with automatic field detection
    /// Uses @ViewBuilder (no AnyView) so ViewInspector and the type system see the real view structure.
    @ViewBuilder
    public static func platformDetailView<T>(
        for data: T,
        hints: PresentationHints? = nil,
        showEditButton: Bool = true,
        onEdit: (() -> Void)? = nil,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View = { fieldName, value, fieldType in
            Text(String(describing: value))
                .foregroundColor(.secondary)
        }
    ) -> some View {
        let analysis = DataIntrospectionEngine.analyze(data)
        let layoutStrategy = determineLayoutStrategy(analysis: analysis, hints: hints)
        switch layoutStrategy {
        case .compact:
            platformCompactDetailView(
                data: data,
                analysis: analysis,
                showEditButton: showEditButton,
                onEdit: onEdit,
                customFieldView: customFieldView
            )
            .automaticCompliance()
        case .standard:
            platformStandardDetailView(
                data: data,
                analysis: analysis,
                showEditButton: showEditButton,
                onEdit: onEdit,
                customFieldView: customFieldView
            )
            .automaticCompliance()
        case .detailed:
            platformDetailedDetailView(
                data: data,
                analysis: analysis,
                showEditButton: showEditButton,
                onEdit: onEdit,
                customFieldView: customFieldView
            )
            .automaticCompliance()
        case .tabbed:
            platformTabbedDetailView(
                data: data,
                analysis: analysis,
                showEditButton: showEditButton,
                onEdit: onEdit,
                customFieldView: customFieldView
            )
            .automaticCompliance()
        case .adaptive:
            platformAdaptiveDetailView(
                data: data,
                analysis: analysis,
                showEditButton: showEditButton,
                onEdit: onEdit,
                customFieldView: customFieldView
            )
            .automaticCompliance()
        }
    }
    
    /// Generate a detail view using default layout strategy
        public static func platformDetailView<T>(
        for data: T,
        showEditButton: Bool = true,
        onEdit: (() -> Void)? = nil,
        @ViewBuilder customFieldView: @escaping (String, String, FieldType) -> some View = { fieldName, value, fieldType in
            Text(value)
                .foregroundColor(.secondary)
        }
    ) -> some View {
        platformDetailView(
            for: data,
            hints: nil,
            showEditButton: showEditButton,
            onEdit: onEdit,
            customFieldView: { fieldName, value, fieldType in
                customFieldView(fieldName, String(describing: value), fieldType)
            }
        )
    }
}

// MARK: - Layout Strategy

/// Layout strategies for detail views
public enum DetailLayoutStrategy: String, CaseIterable {
    case compact = "compact"       // Minimal layout for simple data
    case standard = "standard"     // Standard layout with sections
    case detailed = "detailed"     // Detailed layout with full information
    case tabbed = "tabbed"        // Tabbed layout for complex data
    case adaptive = "adaptive"     // Automatically choose best strategy
}

/// Strategy for adaptive detail views based on device type
/// This is pure data - testable without SwiftUI
public enum AdaptiveDetailStrategy: Equatable {
    case standard  // Use standard detail view
    case detailed  // Use detailed detail view
}

// MARK: - Private Implementation

public extension IntelligentDetailView {
    
    /// Determine the best layout strategy based on data analysis and hints
    static func determineLayoutStrategy(
        analysis: DataAnalysisResult,
        hints: PresentationHints?
    ) -> DetailLayoutStrategy {
        // Check hints first for explicit preferences
        if let hints = hints {
            switch hints.presentationPreference {
            case .compact:
                return .compact
            case .detail:
                return .detailed
            case .card:
                return .standard
            default:
                break
            }
        }
        
        // Analyze data characteristics to determine optimal strategy
        switch (analysis.complexity, analysis.fields.count) {
        case (.simple, 0...3):
            return .compact
            
        case (.simple, 4...7):
            return .standard
            
        case (.moderate, _):
            return .standard
            
        case (.complex, _):
            return .detailed
            
        case (.veryComplex, _):
            return .tabbed
            
        default:
            return .adaptive
        }
    }
    
    /// Generate a compact detail view
    static func platformCompactDetailView<T>(
        data: T,
        analysis: DataAnalysisResult,
        showEditButton: Bool,
        onEdit: (() -> Void)?,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View
    ) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            if showEditButton, let onEdit = onEdit {
                platformHStackContainer {
                    Spacer()
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 8)
            }

            ForEach(analysis.fields, id: \.name) { field in
                platformFieldView(
                    field: field,
                    value: getFieldValue(from: data, fieldName: field.name),
                    customFieldView: customFieldView
                )
            }
        }
        .padding()
    }
    
    /// Generate a standard detail view with sections
    static func platformStandardDetailView<T>(
        data: T,
        analysis: DataAnalysisResult,
        showEditButton: Bool,
        onEdit: (() -> Void)?,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View
    ) -> some View {
        ScrollView {
            platformLazyVStackContainer(alignment: .leading, spacing: 16) {
                if showEditButton, let onEdit = onEdit {
                    platformHStackContainer {
                        Spacer()
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.bottom, 8)
                }

                // Group fields by type for better organization
                let groupedFields = groupFieldsByType(analysis.fields)
                
                ForEach(Array(groupedFields.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { fieldType in
                    if let fields = groupedFields[fieldType] {
                        platformVStackContainer(alignment: .leading, spacing: 12) {
                            Text(fieldType.rawValue.capitalized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(fields, id: \.name) { field in
                                platformFieldView(
                                    field: field,
                                    value: getFieldValue(from: data, fieldName: field.name),
                                    customFieldView: customFieldView
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    /// Generate a detailed view with full information
    static func platformDetailedDetailView<T>(
        data: T,
        analysis: DataAnalysisResult,
        showEditButton: Bool,
        onEdit: (() -> Void)?,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View
    ) -> some View {
        ScrollView {
            platformLazyVStackContainer(alignment: .leading, spacing: 20) {
                // Header section
                platformVStackContainer(alignment: .leading, spacing: 8) {
                    let i18n = InternationalizationService()
                    Text(i18n.localizedString(for: "SixLayerFramework.detail.title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(analysis.fields.count) fields • \(analysis.complexity.rawValue) complexity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                    if showEditButton, let onEdit = onEdit {
                    platformHStackContainer {
                        Spacer()
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Fields organized by importance
                let prioritizedFields = prioritizeFields(analysis.fields)
                
                ForEach(Array(prioritizedFields.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { priority in
                    if let fields = prioritizedFields[priority] {
                        platformVStackContainer(alignment: .leading, spacing: 16) {
                            Text(priority.rawValue.capitalized)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ForEach(fields, id: \.name) { field in
                                platformDetailedFieldView(
                                    field: field,
                                    value: getFieldValue(from: data, fieldName: field.name),
                                    customFieldView: customFieldView
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    /// Generate a tabbed view for very complex data (no AnyView — @ViewBuilder unifies types)
    @ViewBuilder
    static func platformTabbedDetailView<T>(
        data: T,
        analysis: DataAnalysisResult,
        showEditButton: Bool,
        onEdit: (() -> Void)?,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            TabView {
                platformStandardDetailView(
                    data: data,
                    analysis: analysis,
                    showEditButton: showEditButton,
                    onEdit: onEdit,
                    customFieldView: customFieldView
                )
                .tabItem {
                    Image(systemName: "info.circle")
                    let i18n = InternationalizationService()
                    Text(i18n.localizedString(for: "SixLayerFramework.detail.overview"))
                }
                platformDetailedDetailView(
                    data: data,
                    analysis: analysis,
                    showEditButton: showEditButton,
                    onEdit: onEdit,
                    customFieldView: customFieldView
                )
                .tabItem {
                    Image(systemName: "doc.text")
                    let i18n = InternationalizationService()
                    Text(i18n.localizedString(for: "SixLayerFramework.detail.title"))
                }
                platformRawDataView(data: data, analysis: analysis)
                    .tabItem {
                        Image(systemName: "code")
                        let i18n = InternationalizationService()
                        Text(i18n.localizedString(for: "SixLayerFramework.detail.rawData"))
                    }
            }
        } else {
            platformDetailedDetailView(
                data: data,
                analysis: analysis,
                showEditButton: showEditButton,
                onEdit: onEdit,
                customFieldView: customFieldView
            )
        }
        #elseif os(macOS)
        if #available(macOS 13.0, *) {
            TabView {
                platformStandardDetailView(
                    data: data,
                    analysis: analysis,
                    showEditButton: showEditButton,
                    onEdit: onEdit,
                    customFieldView: customFieldView
                )
                .tabItem {
                    Image(systemName: "info.circle")
                    let i18n = InternationalizationService()
                    Text(i18n.localizedString(for: "SixLayerFramework.detail.overview"))
                }
                platformDetailedDetailView(
                    data: data,
                    analysis: analysis,
                    showEditButton: showEditButton,
                    onEdit: onEdit,
                    customFieldView: customFieldView
                )
                .tabItem {
                    Image(systemName: "doc.text")
                    let i18n = InternationalizationService()
                    Text(i18n.localizedString(for: "SixLayerFramework.detail.title"))
                }
                platformRawDataView(data: data, analysis: analysis)
                    .tabItem {
                        Image(systemName: "code")
                        let i18n = InternationalizationService()
                        Text(i18n.localizedString(for: "SixLayerFramework.detail.rawData"))
                    }
            }
        } else {
            platformDetailedDetailView(
                data: data,
                analysis: analysis,
                showEditButton: showEditButton,
                onEdit: onEdit,
                customFieldView: customFieldView
            )
        }
        #else
        platformDetailedDetailView(
            data: data,
            analysis: analysis,
            showEditButton: showEditButton,
            onEdit: onEdit,
            customFieldView: customFieldView
        )
        #endif
    }
    
    /// Determine adaptive detail view strategy based on device type
    /// This is PURE business logic - testable WITHOUT rendering views
    /// Returns which view strategy to use for a given device type
    nonisolated static func determineAdaptiveDetailStrategy(for deviceType: DeviceType) -> AdaptiveDetailStrategy {
        switch deviceType {
        case .phone:
            return .standard
        case .pad, .mac:
            return .detailed
        default:
            return .standard
        }
    }
    
    /// Generate an adaptive detail view (no AnyView — @ViewBuilder unifies types)
    @ViewBuilder
    static func platformAdaptiveDetailView<T>(
        data: T,
        analysis: DataAnalysisResult,
        showEditButton: Bool,
        onEdit: (() -> Void)?,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View
    ) -> some View {
        // Use extracted decision logic
        let deviceType = SixLayerPlatform.deviceType
        let strategy = determineAdaptiveDetailStrategy(for: deviceType)
        
        // Render based on the strategy decision (no AnyView — @ViewBuilder unifies types)
        switch strategy {
        case .standard:
            platformStandardDetailView(
                data: data,
                analysis: analysis,
                showEditButton: showEditButton,
                onEdit: onEdit,
                customFieldView: customFieldView
            )
            .automaticCompliance(named: "platformAdaptiveDetailView")
        case .detailed:
            platformDetailedDetailView(
                data: data,
                analysis: analysis,
                showEditButton: showEditButton,
                onEdit: onEdit,
                customFieldView: customFieldView
            )
            .automaticCompliance(named: "platformAdaptiveDetailView")
        }
    }
    
    /// Generate a field view based on field type
    @ViewBuilder
    static func platformFieldView(
        field: DataField,
        value: Any,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View
    ) -> some View {
        platformHStackContainer {
            Text(field.name.capitalized)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Use custom field view if provided, otherwise use default
            customFieldView(field.name, value, field.type)
        }
        .padding(.vertical, 4)
    }
    
    /// Generate a detailed field view
    @ViewBuilder
    static func platformDetailedFieldView(
        field: DataField,
        value: Any,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View
    ) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.name.capitalized)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Use custom field view if provided, otherwise use default
            customFieldView(field.name, value, field.type)
            
            // Show field metadata
            platformHStackContainer {
                Text(field.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if field.isOptional {
                    let i18n = InternationalizationService()
                    Text(i18n.localizedString(for: "SixLayerFramework.detail.optional"))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if field.isArray {
                    let i18n = InternationalizationService()
                    Text(i18n.localizedString(for: "SixLayerFramework.detail.array"))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if field.isIdentifiable {
                    let i18n = InternationalizationService()
                    Text(i18n.localizedString(for: "SixLayerFramework.detail.identifiable"))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    /// Generate default field value display
    @ViewBuilder
    static func platformDefaultFieldValue(field: DataField, value: Any) -> some View {
        switch field.type {
        case .string:
            Text(String(describing: value))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        case .number:
            Text(String(describing: value))
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        case .boolean:
            Image(systemName: (value as? Bool == true) ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor((value as? Bool == true) ? .green : .red)
        case .date:
            let i18n = InternationalizationService()
            if let date = value as? Date {
                Text(date, style: .date)
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Text(i18n.localizedString(for: "SixLayerFramework.invalid.date"))
                    .font(.body)
                    .foregroundColor(.red)
            }
        case .url:
            let i18n = InternationalizationService()
            if let url = value as? URL {
                Link(url.lastPathComponent, destination: url)
                    .font(.body)
                    .foregroundColor(.blue)
            } else {
                Text(i18n.localizedString(for: "SixLayerFramework.invalid.url"))
                    .font(.body)
                    .foregroundColor(.red)
            }
        case .uuid:
            Text(String(describing: value))
                .font(.caption)
                .foregroundColor(.secondary)
                .font(.system(.caption, design: .monospaced))
        case .image, .document:
            Image(systemName: "doc")
                .foregroundColor(.blue)
        case .relationship, .hierarchical, .custom:
            Text(String(describing: value))
                .font(.body)
                .foregroundColor(.secondary)
                .italic()
        }
    }
    
    /// Generate raw data view for debugging
    static func platformRawDataView<T>(data: T, analysis: DataAnalysisResult) -> some View {
        ScrollView {
            platformVStackContainer(alignment: .leading, spacing: 16) {
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.detail.rawDataAnalysis"))
                    .font(.title)
                    .fontWeight(.bold)
                
                platformVStackContainer(alignment: .leading, spacing: 8) {
                    Text("Complexity: \(analysis.complexity.rawValue)")
                    Text("Field Count: \(analysis.fields.count)")
                    Text("Has Media: \(analysis.patterns.hasMedia ? "Yes" : "No")")
                    Text("Has Dates: \(analysis.patterns.hasDates ? "Yes" : "No")")
                    Text("Has Relationships: \(analysis.patterns.hasRelationships ? "Yes" : "No")")
                    Text("Is Hierarchical: \(analysis.patterns.isHierarchical ? "Yes" : "No")")
                }
                .font(.body)
                .foregroundColor(.secondary)
                
                Divider()
                
                Text("Field Details:")
                    .font(.headline)
                
                ForEach(analysis.fields, id: \.name) { field in
                    platformVStackContainer(alignment: .leading, spacing: 4) {
                        Text("\(field.name): \(field.type.rawValue)")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("Optional: \(field.isOptional ? "Yes" : "No") • Array: \(field.isArray ? "Yes" : "No") • Identifiable: \(field.isIdentifiable ? "Yes" : "No")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
        }
    }
    
    /// Group fields by type for better organization
    static func groupFieldsByType(_ fields: [DataField]) -> [FieldType: [DataField]] {
        var grouped: [FieldType: [DataField]] = [:]
        
        for field in fields {
            if grouped[field.type] == nil {
                grouped[field.type] = []
            }
            grouped[field.type]?.append(field)
        }
        
        return grouped
    }
    
    /// Prioritize fields for detailed view
    static func prioritizeFields(_ fields: [DataField]) -> [FieldPriority: [DataField]] {
        var prioritized: [FieldPriority: [DataField]] = [:]
        
        for field in fields {
            let priority = determineFieldPriority(field)
            if prioritized[priority] == nil {
                prioritized[priority] = []
            }
            prioritized[priority]?.append(field)
        }
        
        return prioritized
    }
    
    /// Determine field priority for display
    static func determineFieldPriority(_ field: DataField) -> FieldPriority {
        // Primary fields are usually identifiers and names
        if field.name.lowercased().contains("id") || field.name.lowercased().contains("name") {
            return .primary
        }
        
        // Secondary fields are important but not primary
        if field.name.lowercased().contains("title") || field.name.lowercased().contains("description") {
            return .secondary
        }
        
        // Tertiary fields are metadata and less important
        return .tertiary
    }
    
    /// Get field value using reflection or Core Data introspection
    /// Extract field value from data model
    /// Delegates to shared DataValueExtraction utility
    static func getFieldValue<T>(from data: T, fieldName: String) -> Any {
        return DataValueExtraction.extractFieldValue(from: data, fieldName: fieldName)
    }
}

// MARK: - Field Priority

/// Priority levels for field display
public enum FieldPriority: String, CaseIterable {
    case primary = "primary"       // Most important fields
    case secondary = "secondary"   // Important but not primary
    case tertiary = "tertiary"     // Metadata and less important
}

// MARK: - Convenience Extensions

public extension View {
    
    /// Apply intelligent detail view generation
    func platformIntelligentDetail<T>(
        for data: T,
        hints: PresentationHints? = nil,
        @ViewBuilder customFieldView: @escaping (String, Any, FieldType) -> some View = { _, _, _ in EmptyView() }
    ) -> some View {
        IntelligentDetailView.platformDetailView(
            for: data,
            hints: hints,
            customFieldView: customFieldView
        )
    }
    
    /// Apply intelligent detail view generation with default strategy
    func platformIntelligentDetail<T>(
        for data: T,
        @ViewBuilder customFieldView: @escaping (String, String, FieldType) -> some View = { _, _, _ in EmptyView() }
    ) -> some View {
        IntelligentDetailView.platformDetailView(
            for: data,
            customFieldView: customFieldView
        )
    }
}
