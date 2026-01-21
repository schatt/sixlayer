import SwiftUI
import Foundation

// MARK: - Property Label Types

/// Defensive enum for common property labels to prevent string-based anti-patterns
public enum PropertyLabel: String, CaseIterable {
    case name = "name"
    case title = "title"
    case description = "description"
    case subtitle = "subtitle"
    case value = "value"
    case id = "id"
    case type = "type"
    case content = "content"
    case data = "data"
    
    var displayName: String {
        return self.rawValue
    }
    
    /// Safe factory method that can't fail at runtime
    static func from(string: String) -> PropertyLabel? {
        return PropertyLabel(rawValue: string)
    }
    
    /// Check if a string matches any of the title-related labels
    static func isTitleLabel(_ label: String) -> Bool {
        guard let propertyLabel = PropertyLabel(rawValue: label) else { return false }
        return propertyLabel == .name || propertyLabel == .title
    }
    
    /// Check if a string matches any of the description-related labels
    static func isDescriptionLabel(_ label: String) -> Bool {
        guard let propertyLabel = PropertyLabel(rawValue: label) else { return false }
        return propertyLabel == .description || propertyLabel == .subtitle
    }
}

// MARK: - Item Type Types

/// Defensive enum for item types to prevent string-based anti-patterns
public enum ItemType: String, CaseIterable {
    case featureCards = "featureCards"
    case generic = "generic"
    case media = "media"
    case navigation = "navigation"
    case form = "form"
    case list = "list"
    case grid = "grid"
    
    var displayName: String {
        return self.rawValue
    }
    
    /// Safe factory method that can't fail at runtime
    static func from(string: String) -> ItemType {
        return ItemType(rawValue: string) ?? .generic
    }
}

// MARK: - Validation Rule Types

/// Defensive enum for validation rules to prevent string-based anti-patterns
public enum ValidationRuleType: String, CaseIterable {
    case required = "required"
    case email = "email"
    case phone = "phone"
    case url = "url"
    case minLength = "minLength"
    case maxLength = "maxLength"
    case min = "min"
    case max = "max"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Generic Data Presentation Functions

/// Generic function for presenting any collection of identifiable items
/// Uses hints to determine optimal presentation strategy
///
/// ## Built-in Callbacks
/// The framework provides four optional callbacks that automatically integrate with row actions:
/// - `onCreateItem`: Displays "Add Item" button in empty state
/// - `onItemSelected`: Handles item selection/navigation
/// - `onItemEdited`: **Automatically appears as "Edit" button in row actions** (swipe actions on iOS, context menu on macOS)
/// - `onItemDeleted`: **Automatically appears as "Delete" button in row actions** (swipe actions on iOS, context menu on macOS)
///
/// When `onItemEdited` or `onItemDeleted` are provided, the framework automatically adds platform-appropriate row actions
/// using `platformRowActions_L4()`. Actions adapt to platform conventions (iOS = swipe, macOS = right-click).
///
/// ## Custom Actions
/// For actions beyond Edit/Delete, use the `customItemView` parameter overload. This allows full control over
/// item appearance and actions. See `README_Layer1_Semantic.md` for detailed examples.
///
/// - Parameters:
///   - items: Array of identifiable items to display
///   - hints: Presentation hints that guide layout and presentation decisions
///   - onCreateItem: Optional callback when user wants to create a new item
///   - onItemSelected: Optional callback when user selects an item
///   - onItemDeleted: Optional callback when user wants to delete an item (automatically appears in row actions)
///   - onItemEdited: Optional callback when user wants to edit an item (automatically appears in row actions)
/// - Returns: A view that presents the collection with appropriate layout and actions
/// - SeeAlso: `README_Layer1_Semantic.md` for detailed callback documentation and examples
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentItemCollection_L1<Item: Identifiable>(
    items: [Item],
    hints: PresentationHints,
    onCreateItem: (() -> Void)? = nil,
    onItemSelected: ((Item) -> Void)? = nil,
    onItemDeleted: ((Item) -> Void)? = nil,
    onItemEdited: ((Item) -> Void)? = nil
) -> some View {
    // Generic implementation that uses hints to guide decisions
    // This function doesn't know about specific business logic
    return GenericItemCollectionView(
        items: items, 
        hints: hints, 
        onCreateItem: onCreateItem,
        onItemSelected: onItemSelected,
        onItemDeleted: onItemDeleted,
        onItemEdited: onItemEdited
    )
    .automaticCompliance(identifierName: "platformPresentItemCollection_L1")
}

/// Generic function for presenting numeric data
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentNumericData_L1(
    data: [GenericNumericData],
    hints: PresentationHints
) -> some View {
    return GenericNumericDataView(data: data, hints: hints)
        .environment(\.accessibilityIdentifierName, "platformPresentNumericData_L1")
        .automaticCompliance()
}

/// Present a single numeric data item
/// Internally wraps the single item in an array and delegates to the array version
/// Note: Requires @MainActor because it calls a main-actor isolated function
@MainActor
public func platformPresentNumericData_L1(
    data: GenericNumericData,
    hints: PresentationHints
) -> some View {
    return platformPresentNumericData_L1(data: [data], hints: hints)
}

/// Generic function for presenting numeric data with custom views
/// Allows specifying custom views for individual numeric data items
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentNumericData_L1(
    data: [GenericNumericData],
    hints: PresentationHints,
    @ViewBuilder customDataView: @escaping (GenericNumericData) -> some View
) -> some View {
    return CustomNumericDataView(
        data: data,
        hints: hints,
        customDataView: { AnyView(customDataView($0)) }
    )
    .environment(\.accessibilityIdentifierName, "platformPresentNumericData_L1")
    .automaticCompliance()
}

/// Generic function for presenting numeric data with custom views and enhanced hints
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentNumericData_L1(
    data: [GenericNumericData],
    hints: EnhancedPresentationHints,
    @ViewBuilder customDataView: @escaping (GenericNumericData) -> some View
) -> some View {
    // Convert enhanced hints to basic hints for backward compatibility
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    // Process extensible hints and merge custom data
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return CustomNumericDataView(
        data: data,
        hints: processedHints,
        customDataView: { AnyView(customDataView($0)) }
    )
    .environment(\.extensibleHints, hints.extensibleHints)
    .environment(\.accessibilityIdentifierName, "platformPresentNumericData_L1")
    .automaticCompliance()
}

/// Generic function for presenting responsive cards
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformResponsiveCard_L1<Content: View>(
    @ViewBuilder content: () -> Content,
    hints: PresentationHints
) -> some View {
    // Use ResponsiveCardsView for card-based presentation
    return ResponsiveCardView(data: ResponsiveCardData(
        title: "Generic Card",
        subtitle: "Generated from Layer 1",
        icon: "doc.text",
        color: .blue,
        complexity: hints.complexity
    ))
}

/// Generic function for presenting form data using our intelligent form system
// DEPRECATED: GenericFormField is deprecated
/*
@MainActor
public func platformPresentFormData_L1(
    fields: [GenericFormField],
    hints: PresentationHints
) -> some View {
    // MARK: - DEPRECATED: SimpleFormView uses GenericFormField which has been deprecated
    // TODO: Replace with DynamicFormView using DynamicFormField
    return Text("Form functionality temporarily disabled - needs DynamicFormField migration")
        .foregroundColor(.secondary)
        .padding()
}
*/

/// Present a single form field
/// Internally wraps the single field in an array and delegates to the array version
@MainActor
public func platformPresentFormData_L1(
    field: DynamicFormField,
    hints: PresentationHints
) -> some View {
    let enhancedHints = EnhancedPresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        extensibleHints: [],
        fieldHints: hints.fieldHints
    )
    
    // Set screen context for accessibility identifier generation
    AccessibilityIdentifierConfig.shared.setScreenContext("screen")
    
    // Use async view helper
    return AsyncFormView(
        fields: [field],
        hints: enhancedHints,
        modelName: nil,
        layoutSpec: nil
    )
    .automaticCompliance()
}

/// Generic function for presenting modal forms
/// Uses hints to determine optimal modal presentation strategy
@MainActor
public func platformPresentModalForm_L1(
    formType: DataTypeHint,
    context: PresentationContext
) -> some View {
    // Create presentation hints for modal context
    let hints = PresentationHints(
        dataType: formType,
        presentationPreference: .modal,
        complexity: .moderate,
        context: context
    )
    
    // Create appropriate form fields based on the form type
    let fields = createFieldsForFormType(formType, context: context)
    
    // Return a modal form with the generated fields
    return ModalFormView(fields: fields, formType: formType, context: context, hints: hints)
        .automaticCompliance()
}

/// Generic function for presenting modal forms with custom form container view
/// Allows custom styling/layout of the modal form container while preserving form logic
///
/// - Parameters:
///   - formType: The type of form to present
///   - context: The presentation context
///   - customFormContainer: Optional view builder that wraps the form content with custom styling
/// - Returns: A view presenting the modal form with optional custom container
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentModalForm_L1<ContainerContent: View>(
    formType: DataTypeHint,
    context: PresentationContext,
    customFormContainer: ((AnyView) -> ContainerContent)? = nil
) -> some View {
    // Create presentation hints for modal context
    let hints = PresentationHints(
        dataType: formType,
        presentationPreference: .modal,
        complexity: .moderate,
        context: context
    )
    
    // Create appropriate form fields based on the form type
    let fields = createFieldsForFormType(formType, context: context)
    
    // Create the base modal form view
    // Note: ModalFormView initializer is main-actor isolated because it's a View
    let baseFormView = AnyView(ModalFormView(fields: fields, formType: formType, context: context, hints: hints)
        .automaticCompliance())
    
    // Apply custom container if provided, otherwise return default
    if let customContainer = customFormContainer {
        return AnyView(customContainer(baseFormView))
    } else {
        return baseFormView
    }
}

/// Generic function for presenting media data
@MainActor
public func platformPresentMediaData_L1(
    media: [GenericMediaItem],
    hints: PresentationHints
) -> some View {
    // Set screen context for accessibility identifier generation
    AccessibilityIdentifierConfig.shared.setScreenContext("screen")
    
    return GenericMediaView(media: media, hints: hints)
        .environment(\.accessibilityIdentifierName, "platformPresentMediaData_L1")
        .automaticCompliance()
}

/// Present a single media item
/// Internally wraps the single item in an array and delegates to the array version
/// Note: Requires @MainActor because it calls a main-actor isolated function
@MainActor
public func platformPresentMediaData_L1(
    media: GenericMediaItem,
    hints: PresentationHints
) -> some View {
    return platformPresentMediaData_L1(media: [media], hints: hints)
}

/// Present a single media item with enhanced hints
/// Internally wraps the single item in an array and delegates to the array version
/// Note: Requires @MainActor because it calls a main-actor isolated function
@MainActor
public func platformPresentMediaData_L1(
    media: GenericMediaItem,
    hints: EnhancedPresentationHints
) -> some View {
    return platformPresentMediaData_L1(media: [media], hints: hints)
}

/// Present a single media item with custom view
/// Internally wraps the single item in an array and delegates to the array version
/// Note: Requires @MainActor because it calls a main-actor isolated function
@MainActor
public func platformPresentMediaData_L1(
    media: GenericMediaItem,
    hints: PresentationHints,
    @ViewBuilder customMediaView: @escaping (GenericMediaItem) -> some View
) -> some View {
    return platformPresentMediaData_L1(media: [media], hints: hints, customMediaView: customMediaView)
}

/// Present a single media item with enhanced hints and custom view
/// Internally wraps the single item in an array and delegates to the array version
/// Note: Requires @MainActor because it calls a main-actor isolated function
@MainActor
public func platformPresentMediaData_L1(
    media: GenericMediaItem,
    hints: EnhancedPresentationHints,
    @ViewBuilder customMediaView: @escaping (GenericMediaItem) -> some View
) -> some View {
    return platformPresentMediaData_L1(media: [media], hints: hints, customMediaView: customMediaView)
}

/// Generic function for presenting media data with custom views
/// Allows specifying custom views for individual media items
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentMediaData_L1(
    media: [GenericMediaItem],
    hints: PresentationHints,
    @ViewBuilder customMediaView: @escaping (GenericMediaItem) -> some View
) -> some View {
    return CustomMediaView(
        media: media,
        hints: hints,
        customMediaView: { AnyView(customMediaView($0)) }
    )
    .environment(\.accessibilityIdentifierName, "platformPresentMediaData_L1")
    .automaticCompliance()
}

/// Generic function for presenting media data with custom views and enhanced hints
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentMediaData_L1(
    media: [GenericMediaItem],
    hints: EnhancedPresentationHints,
    @ViewBuilder customMediaView: @escaping (GenericMediaItem) -> some View
) -> some View {
    // Convert enhanced hints to basic hints for backward compatibility
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    // Process extensible hints and merge custom data
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return CustomMediaView(
        media: media,
        hints: processedHints,
        customMediaView: { AnyView(customMediaView($0)) }
    )
    .environment(\.extensibleHints, hints.extensibleHints)
    .environment(\.accessibilityIdentifierName, "platformPresentMediaData_L1")
    .automaticCompliance()
}

/// Generic function for presenting hierarchical data
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentHierarchicalData_L1(
    items: [GenericHierarchicalItem],
    hints: PresentationHints
) -> some View {
    return GenericHierarchicalView(items: items, hints: hints)
        .environment(\.accessibilityIdentifierName, "platformPresentHierarchicalData_L1")
        .automaticCompliance()
}

/// Present a single hierarchical item
/// Internally wraps the single item in an array and delegates to the array version
/// Note: Requires @MainActor because it calls a main-actor isolated function
@MainActor
public func platformPresentHierarchicalData_L1(
    item: GenericHierarchicalItem,
    hints: PresentationHints
) -> some View {
    return platformPresentHierarchicalData_L1(items: [item], hints: hints)
}

/// Generic function for presenting hierarchical data with custom views
/// Allows specifying custom views for individual hierarchical items
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentHierarchicalData_L1(
    items: [GenericHierarchicalItem],
    hints: PresentationHints,
    @ViewBuilder customItemView: @escaping (GenericHierarchicalItem) -> some View
) -> some View {
    return CustomHierarchicalView(
        items: items,
        hints: hints,
        customItemView: { AnyView(customItemView($0)) }
    )
    .environment(\.accessibilityIdentifierName, "platformPresentHierarchicalData_L1")
    .automaticCompliance()
}

/// Generic function for presenting hierarchical data with custom views and enhanced hints
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentHierarchicalData_L1(
    items: [GenericHierarchicalItem],
    hints: EnhancedPresentationHints,
    @ViewBuilder customItemView: @escaping (GenericHierarchicalItem) -> some View
) -> some View {
    // Convert enhanced hints to basic hints for backward compatibility
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    // Process extensible hints and merge custom data
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return CustomHierarchicalView(
        items: items,
        hints: processedHints,
        customItemView: { AnyView(customItemView($0)) }
    )
    .environment(\.extensibleHints, hints.extensibleHints)
    .environment(\.accessibilityIdentifierName, "platformPresentHierarchicalData_L1")
    .automaticCompliance()
}

/// Generic function for presenting temporal data
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentTemporalData_L1(
    items: [GenericTemporalItem],
    hints: PresentationHints
) -> some View {
    return GenericTemporalView(items: items, hints: hints)
        .environment(\.accessibilityIdentifierName, "platformPresentTemporalData_L1")
        .automaticCompliance()
}

/// Present a single temporal item
/// Internally wraps the single item in an array and delegates to the array version
/// Note: Requires @MainActor because it calls a main-actor isolated function
@MainActor
public func platformPresentTemporalData_L1(
    item: GenericTemporalItem,
    hints: PresentationHints
) -> some View {
    return platformPresentTemporalData_L1(items: [item], hints: hints)
}

/// Generic function for presenting temporal data with custom views
/// Allows specifying custom views for individual temporal items
@MainActor
public func platformPresentTemporalData_L1(
    items: [GenericTemporalItem],
    hints: PresentationHints,
    @ViewBuilder customItemView: @escaping (GenericTemporalItem) -> some View
) -> some View {
    return CustomTemporalView(
        items: items,
        hints: hints,
        customItemView: { AnyView(customItemView($0)) }
    )
    .environment(\.accessibilityIdentifierName, "platformPresentTemporalData_L1")
    .automaticCompliance()
}

// MARK: - Navigation Stack Layer 1 Functions

/// Layer 1 semantic function for presenting content in a navigation stack
/// Expresses intent to use stack-based navigation without knowing implementation details
///
/// This function allows developers to express WHAT they want (stack-based navigation)
/// without knowing HOW it's implemented (NavigationStack vs NavigationView, platform differences, etc.)
///
/// - Parameters:
///   - content: The content to display in the navigation stack
///   - title: Optional navigation title
///   - hints: Presentation hints that guide navigation decisions
/// - Returns: A view that presents the content in a navigation stack
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentNavigationStack_L1<Content: View>(
    content: Content,
    title: String? = nil,
    hints: PresentationHints
) -> some View {
    return NavigationStackWrapper(
        content: content,
        title: title,
        hints: hints
    )
    .environment(\.accessibilityIdentifierName, "platformPresentNavigationStack_L1")
    .automaticCompliance()
}

/// Layer 1 semantic function for presenting a collection of items in a navigation stack
/// Expresses intent to use stack-based navigation with list-detail pattern
///
/// - Parameters:
///   - items: Collection of identifiable items to navigate
///   - hints: Presentation hints that guide navigation decisions
///   - itemView: View builder for individual items in the list
///   - destination: View builder for detail views when an item is selected
/// - Returns: A view that presents the items in a navigation stack with list-detail navigation
/// Note: Requires @MainActor because it creates a View struct
@MainActor
public func platformPresentNavigationStack_L1<Item: Identifiable & Hashable, ItemView: View, DestinationView: View>(
    items: [Item],
    hints: PresentationHints,
    @ViewBuilder itemView: @escaping (Item) -> ItemView,
    @ViewBuilder destination: @escaping (Item) -> DestinationView
) -> some View {
    return NavigationStackItemsWrapper(
        items: items,
        hints: hints,
        itemView: { AnyView(itemView($0)) },
        destination: { AnyView(destination($0)) }
    )
    .environment(\.accessibilityIdentifierName, "platformPresentNavigationStack_L1")
    .automaticCompliance()
}

// MARK: - App Navigation Layer 1 Functions

/// Layer 1 semantic function for presenting app navigation with sidebar and detail
/// Expresses intent to use app navigation pattern without knowing implementation details
///
/// This function allows developers to express WHAT they want (app navigation with sidebar/detail)
/// without knowing HOW it's implemented (NavigationSplitView vs detail-only with sheet,
/// device-specific decisions, orientation handling, etc.)
///
/// The framework automatically:
/// - Detects device type (iPad, iPhone, macOS)
/// - Considers orientation (portrait, landscape)
/// - Analyzes screen size (large iPhone models in landscape)
/// - Chooses optimal navigation pattern (split view vs detail-only)
/// - Handles state management (column visibility, sheet presentation)
///
/// - Parameters:
///   - sidebar: View builder for sidebar content
///   - detail: View builder for detail content
///   - columnVisibility: Optional binding for NavigationSplitView column visibility
///   - showingNavigationSheet: Optional binding for sheet presentation (iPhone)
/// - Returns: A view that presents app navigation with intelligent pattern selection
@MainActor
public func platformPresentAppNavigation_L1<SidebarContent: View, DetailContent: View>(
    columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
    showingNavigationSheet: Binding<Bool>? = nil,
    @ViewBuilder sidebar: @escaping () -> SidebarContent,
    @ViewBuilder detail: @escaping () -> DetailContent
) -> some View {
    return AppNavigationWrapper<SidebarContent, DetailContent>(
        columnVisibility: columnVisibility,
        showingNavigationSheet: showingNavigationSheet,
        sidebar: { AnyView(sidebar()) },
        detail: { AnyView(detail()) }
    )
    .environment(\.accessibilityIdentifierName, "platformPresentAppNavigation_L1")
    .automaticCompliance()
}

/// Internal wrapper view for app navigation
/// This view implements the full 6-layer flow: L1 -> L2 -> L3 -> L4
private struct AppNavigationWrapper<SidebarContent: View, DetailContent: View>: View {
    let columnVisibility: Binding<NavigationSplitViewVisibility>?
    let showingNavigationSheet: Binding<Bool>?
    let sidebar: () -> AnyView
    let detail: () -> AnyView
    
    var body: some View {
        // Get current device capabilities
        let deviceType = DeviceType.current
        let deviceCapabilities = DeviceCapabilities()
        let orientation = deviceCapabilities.orientation
        let screenSize = deviceCapabilities.screenSize
        
        // Get iPhone size category if applicable
        #if os(iOS)
        let iPhoneSizeCategory: iPhoneSizeCategory? = deviceType == .phone ? iPhoneSizeCategory.from(screenSize: screenSize) : nil
        #else
        let iPhoneSizeCategory: iPhoneSizeCategory? = nil
        #endif
        
        // Layer 2: Device and orientation-aware decision making
        let l2Decision = determineAppNavigationStrategy_L2(
            deviceType: deviceType,
            orientation: orientation,
            screenSize: screenSize,
            iPhoneSizeCategory: iPhoneSizeCategory
        )
        
        // Layer 3: Platform-aware strategy selection
        let l3Strategy = selectAppNavigationStrategy_L3(
            decision: l2Decision,
            platform: SixLayerPlatform.current
        )
        
        // Layer 4: Component implementation
        EmptyView()
            .platformAppNavigation_L4(
                columnVisibility: columnVisibility,
                showingNavigationSheet: showingNavigationSheet,
                strategy: l3Strategy,
                sidebar: { sidebar() },
                detail: { detail() }
            )
    }
}

/// Generic function for presenting temporal data with custom views and enhanced hints
@MainActor
public func platformPresentTemporalData_L1(
    items: [GenericTemporalItem],
    hints: EnhancedPresentationHints,
    @ViewBuilder customItemView: @escaping (GenericTemporalItem) -> some View
) -> some View {
    // Convert enhanced hints to basic hints for backward compatibility
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    // Process extensible hints and merge custom data
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return CustomTemporalView(
        items: items,
        hints: processedHints,
        customItemView: { AnyView(customItemView($0)) }
    )
    .environment(\.extensibleHints, hints.extensibleHints)
    .environment(\.accessibilityIdentifierName, "platformPresentTemporalData_L1")
    .automaticCompliance()
}

/// Generic function for presenting unknown content at runtime
/// 
/// **IMPORTANT**: This function is reserved for rare cases where the content type
/// is unknown at compile time (e.g., dynamic API responses, user-generated content,
/// or mixed content types). For known content types, use the specific functions:
/// - `platformPresentItemCollection_L1` for collections
/// - `platformPresentFormData_L1` for forms
/// - `platformPresentMediaData_L1` for media
/// - etc.
///
/// This function analyzes content type at runtime and delegates to appropriate
/// specific functions, with a fallback for truly unknown content types.
@MainActor
public func platformPresentContent_L1(
    content: Any,
    hints: PresentationHints
) -> some View {
        return GenericContentView(content: content, hints: hints)
            .environment(\.accessibilityIdentifierName, "platformPresentContent_L1")
            .automaticAccessibility()
            .platformPatterns()
            .visualConsistency()
            .automaticCompliance()
}

/// Present basic numeric values (Int, Float, Double, Bool) with appropriate formatting
@MainActor
public func platformPresentBasicValue_L1(
    value: Any,
    hints: PresentationHints
) -> AnyView {
    return AnyView(BasicValueView(value: value, hints: hints)
        .environment(\.accessibilityIdentifierName, "platformPresentBasicValue_L1")
        .automaticAccessibility()
        .platformPatterns()
        .visualConsistency()
        .automaticCompliance())
}

/// Present basic arrays with appropriate formatting
@MainActor
public func platformPresentBasicArray_L1(
    array: Any,
    hints: PresentationHints
) -> AnyView {
    return AnyView(BasicArrayView(array: array, hints: hints)
        .environment(\.accessibilityIdentifierName, "platformPresentBasicArray_L1")
        .automaticAccessibility()
        .platformPatterns()
        .visualConsistency()
        .automaticCompliance())
}

/// Generic function for presenting settings interface
/// Uses hints to determine optimal settings presentation strategy
@MainActor
public func platformPresentSettings_L1(
    settings: [SettingsSectionData],
    hints: PresentationHints,
    onSettingChanged: ((String, Any) -> Void)? = nil,
    onSettingsSaved: (() -> Void)? = nil,
    onSettingsCancelled: (() -> Void)? = nil
) -> some View {
    // Set screen context for accessibility identifier generation
    AccessibilityIdentifierConfig.shared.setScreenContext("screen")
    
    return GenericSettingsView(
        settings: settings,
        hints: hints,
        onSettingChanged: onSettingChanged,
        onSettingsSaved: onSettingsSaved,
        onSettingsCancelled: onSettingsCancelled
    )
    .automaticCompliance()
}

/// Generic function for presenting settings interface with custom views
/// Allows specifying custom views for settings sections and individual settings
@MainActor
public func platformPresentSettings_L1(
    settings: [SettingsSectionData],
    hints: PresentationHints,
    onSettingChanged: ((String, Any) -> Void)? = nil,
    onSettingsSaved: (() -> Void)? = nil,
    onSettingsCancelled: (() -> Void)? = nil,
    @ViewBuilder customSettingView: @escaping (SettingsSectionData) -> some View
) -> some View {
    return CustomSettingsView(
        settings: settings,
        hints: hints,
        onSettingChanged: onSettingChanged,
        onSettingsSaved: onSettingsSaved,
        onSettingsCancelled: onSettingsCancelled,
        customSettingView: { AnyView(customSettingView($0)) }
    )
    .environment(\.accessibilityIdentifierName, "platformPresentSettings_L1")
    .automaticCompliance()
}

/// Generic function for presenting settings interface with custom views and enhanced hints
@MainActor
public func platformPresentSettings_L1(
    settings: [SettingsSectionData],
    hints: EnhancedPresentationHints,
    onSettingChanged: ((String, Any) -> Void)? = nil,
    onSettingsSaved: (() -> Void)? = nil,
    onSettingsCancelled: (() -> Void)? = nil,
    @ViewBuilder customSettingView: @escaping (SettingsSectionData) -> some View
) -> some View {
    // Convert enhanced hints to basic hints for backward compatibility
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    // Process extensible hints and merge custom data
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return CustomSettingsView(
        settings: settings,
        hints: processedHints,
        onSettingChanged: onSettingChanged,
        onSettingsSaved: onSettingsSaved,
        onSettingsCancelled: onSettingsCancelled,
        customSettingView: { AnyView(customSettingView($0)) }
    )
    .environment(\.extensibleHints, hints.extensibleHints)
    .environment(\.accessibilityIdentifierName, "platformPresentSettings_L1")
    .automaticCompliance()
}

// MARK: - Enhanced Presentation Hints Overloads

/// Generic function for presenting any collection of identifiable items with enhanced hints
/// Uses enhanced hints to determine optimal presentation strategy and process extensible hints
@MainActor
public func platformPresentItemCollection_L1<Item: Identifiable>(
    items: [Item],
    hints: EnhancedPresentationHints,
    onCreateItem: (() -> Void)? = nil,
    onItemSelected: ((Item) -> Void)? = nil,
    onItemDeleted: ((Item) -> Void)? = nil,
    onItemEdited: ((Item) -> Void)? = nil
) -> some View {
    // Convert enhanced hints to basic hints for backward compatibility
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    // Process extensible hints and merge custom data
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return GenericItemCollectionView(
        items: items, 
        hints: processedHints, 
        onCreateItem: onCreateItem,
        onItemSelected: onItemSelected,
        onItemDeleted: onItemDeleted,
        onItemEdited: onItemEdited
    )
    .environment(\.extensibleHints, hints.extensibleHints)
    .environment(\.accessibilityIdentifierName, "platformPresentItemCollection_L1")
    .automaticCompliance()
}

// MARK: - Custom View Support Overloads

/// Generic function for presenting any collection of identifiable items with custom views
/// Allows specifying custom views for item display, editing, and creation
///
/// Use this overload when you need:
/// - Custom actions beyond Edit/Delete (e.g., Share, Archive, Duplicate)
/// - Custom item layout/styling
/// - Item-specific conditional actions
/// - Full control over row appearance
///
/// **Note**: When using `customItemView`, you can still use `platformRowActions_L4()` within your custom view
/// to get platform-appropriate row actions (swipe actions on iOS, context menu on macOS).
///
/// - Parameters:
///   - items: Array of identifiable items to display
///   - hints: Presentation hints that guide layout and presentation decisions
///   - onCreateItem: Optional callback when user wants to create a new item
///   - onItemSelected: Optional callback when user selects an item
///   - onItemDeleted: Optional callback when user wants to delete an item
///   - onItemEdited: Optional callback when user wants to edit an item
///   - customItemView: View builder for custom item display (replaces default item view)
/// - Returns: A view that presents the collection with custom item views
/// - SeeAlso: `README_Layer1_Semantic.md` for examples of custom views with actions
@MainActor
public func platformPresentItemCollection_L1<Item: Identifiable>(
    items: [Item],
    hints: PresentationHints,
    onCreateItem: (() -> Void)? = nil,
    onItemSelected: ((Item) -> Void)? = nil,
    onItemDeleted: ((Item) -> Void)? = nil,
    onItemEdited: ((Item) -> Void)? = nil,
    @ViewBuilder customItemView: @escaping (Item) -> some View
) -> some View {
    return AnyView(GenericItemCollectionView(
        items: items,
        hints: hints,
        onCreateItem: onCreateItem,
        onItemSelected: onItemSelected,
        onItemDeleted: onItemDeleted,
        onItemEdited: onItemEdited
    ))
    .environment(\.accessibilityIdentifierName, "platformPresentItemCollection_L1")
    .automaticCompliance()
}

/// Generic function for presenting any collection of identifiable items with custom views and enhanced hints
@MainActor
public func platformPresentItemCollection_L1<Item: Identifiable>(
    items: [Item],
    hints: EnhancedPresentationHints,
    onCreateItem: (() -> Void)? = nil,
    onItemSelected: ((Item) -> Void)? = nil,
    onItemDeleted: ((Item) -> Void)? = nil,
    onItemEdited: ((Item) -> Void)? = nil,
    @ViewBuilder customItemView: @escaping (Item) -> some View
) -> some View {
    // Convert enhanced hints to basic hints for backward compatibility
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    // Process extensible hints and merge custom data
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return AnyView(GenericItemCollectionView(
        items: items,
        hints: processedHints,
        onCreateItem: onCreateItem,
        onItemSelected: onItemSelected,
        onItemDeleted: onItemDeleted,
        onItemEdited: onItemEdited
    ))
    .environment(\.extensibleHints, hints.extensibleHints)
    .environment(\.accessibilityIdentifierName, "platformPresentItemCollection_L1")
    .automaticCompliance()
}

/// Generic function for presenting any collection of identifiable items with custom views for all actions
@MainActor
public func platformPresentItemCollection_L1<Item: Identifiable>(
    items: [Item],
    hints: PresentationHints,
    onCreateItem: (() -> Void)? = nil,
    onItemSelected: ((Item) -> Void)? = nil,
    onItemDeleted: ((Item) -> Void)? = nil,
    onItemEdited: ((Item) -> Void)? = nil,
    @ViewBuilder customItemView: @escaping (Item) -> some View,
    customCreateView: (() -> some View)? = nil,
    customEditView: ((Item) -> some View)? = nil
) -> some View {
    return AnyView(GenericItemCollectionView(
        items: items,
        hints: hints,
        onCreateItem: onCreateItem,
        onItemSelected: onItemSelected,
        onItemDeleted: onItemDeleted,
        onItemEdited: onItemEdited
    ))
    .environment(\.accessibilityIdentifierName, "platformPresentItemCollection_L1")
    .automaticCompliance()
}

/// Generic function for presenting numeric data with enhanced hints
@MainActor
public func platformPresentNumericData_L1(
    data: [GenericNumericData],
    hints: EnhancedPresentationHints
) -> some View {
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return GenericNumericDataView(data: data, hints: processedHints)
        .environment(\.extensibleHints, hints.extensibleHints)
        .environment(\.accessibilityIdentifierName, "platformPresentNumericData_L1")
        .automaticCompliance()
}

/// Generic function for presenting responsive cards with enhanced hints
@MainActor
public func platformResponsiveCard_L1<Content: View>(
    @ViewBuilder content: () -> Content,
    hints: EnhancedPresentationHints
) -> some View {
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return ResponsiveCardView(data: ResponsiveCardData(
        title: "Generic Card",
        subtitle: "Generated from Layer 1",
        icon: "doc.text",
        color: .blue,
        complexity: processedHints.complexity
    ))
    .environment(\.extensibleHints, hints.extensibleHints)
}

/// Generic function for presenting form data with enhanced hints
/// Automatically loads hints from .hints files that describe the data
/// 
/// Precedence order:
/// 1. Explicit layoutSpec (if provided) - highest priority
/// 2. Hints sections from modelName (if provided)
/// 3. Framework defaults (vertical stack of all fields)
@MainActor
public func platformPresentFormData_L1(
    fields: [DynamicFormField],
    hints: EnhancedPresentationHints,
    modelName: String? = nil,
    layoutSpec: LayoutSpec? = nil
) -> some View {
    return AsyncFormView(
        fields: fields,
        hints: hints,
        modelName: modelName,
        layoutSpec: layoutSpec
    )
}

// MARK: - Async Form View Helper

/// Helper view that handles async hints loading
@MainActor
private struct AsyncFormView: View {
    let fields: [DynamicFormField]
    let hints: EnhancedPresentationHints
    let modelName: String?
    let layoutSpec: LayoutSpec?
    
    @State private var resolvedSections: [DynamicFormSection]?
    @State private var isLoading: Bool
    
    // Initialize with cached hints if available (synchronous check)
    // Flow: optional hint → file/cache → default
    init(fields: [DynamicFormField], hints: EnhancedPresentationHints, modelName: String?, layoutSpec: LayoutSpec?) {
        self.fields = fields
        self.hints = hints
        self.modelName = modelName
        self.layoutSpec = layoutSpec
        
        // Step 1: If code provides hint (layoutSpec), use it synchronously
        if let explicitSpec = layoutSpec {
            self._resolvedSections = State(initialValue: explicitSpec.sections)
            self._isLoading = State(initialValue: false)
            return
        }
        
        // Step 2: If no code hint, try file/cache synchronously
        if let modelName = modelName,
           let cachedHints = DataHintsRegistry.getCachedHints(for: modelName),
           !cachedHints.sections.isEmpty {
            // File-based hints are cached - use them immediately without async loading
            let sections = SectionBuilder.buildSections(
                from: cachedHints.sections,
                matching: fields
            )
            self._resolvedSections = State(initialValue: sections)
            self._isLoading = State(initialValue: false)
            return
        }
        
        // Step 3: If file/cache not available, will need async loading or use default
        // If modelName provided but not cached, load async
        // If no modelName, will use default (handled in loadSections)
        self._resolvedSections = State(initialValue: nil)
        self._isLoading = State(initialValue: modelName != nil) // Only loading if we have a modelName
    }
    
    // Cache initial sections to avoid recreating on every body evaluation
    private var initialSections: [DynamicFormSection]? {
        // Precedence 1: Explicit layoutSpec takes highest priority
        if let explicitSpec = layoutSpec {
            return explicitSpec.sections
        }
        
        // If resolved sections are already set (from cached hints), use them
        if let resolved = resolvedSections {
            return resolved
        }
        
        // If no async work needed, return default sections immediately
        if modelName == nil {
            return createDefaultSections()
        }
        
        // Need to load hints asynchronously
        return nil
    }
    
    var body: some View {
        Group {
            if let sections = initialSections {
                // Fast path: No async work needed, render immediately
                createFormView(with: sections)
            } else if isLoading {
                // Slow path: Need to load hints asynchronously
                ProgressView()
                    .task {
                        await loadSections()
                    }
            } else if let sections = resolvedSections {
                createFormView(with: sections)
            } else {
                createFormView(with: createDefaultSections())
            }
        }
    }
    
    // MARK: - DRY: Default Section Creation
    
    private func createDefaultSections() -> [DynamicFormSection] {
        [DynamicFormSection(
            id: "default",
            title: "Form Fields",
            fields: fields
        )]
    }
    
    // MARK: - Section Resolution with Precedence (DRY)
    
    @MainActor
    private func loadSections() async {
        // Flow: optional hint → file/cache → default
        
        // Step 1: If code provides hint (layoutSpec), use it
        if let explicitSpec = layoutSpec {
            resolvedSections = explicitSpec.sections
            isLoading = false
            return
        }
        
        // Step 2: If no code hint, try file/cache
        if let modelName = modelName {
            let hintsResult = await globalDataHintsRegistry.loadHintsResult(for: modelName)
            
            // If file/cache has hints, use them
            if !hintsResult.sections.isEmpty {
                resolvedSections = SectionBuilder.buildSections(
                    from: hintsResult.sections,
                    matching: fields
                )
            } else {
                // Step 3: If file/cache has nothing, use default
                resolvedSections = createDefaultSections()
            }
        } else {
            // No modelName provided, use default
            resolvedSections = createDefaultSections()
        }
        
        isLoading = false
    }
    
    // MARK: - Form View Creation
    
    @ViewBuilder
    private func createFormView(with sections: [DynamicFormSection]) -> some View {
        let configuration = DynamicFormConfiguration(
            id: "form-\(UUID().uuidString)",
            title: hints.customPreferences["formTitle"] ?? "Form",
            description: hints.customPreferences["formDescription"],
            sections: sections,
            submitButtonText: hints.customPreferences["submitButtonText"] ?? "Submit",
            cancelButtonText: hints.customPreferences["cancelButtonText"]
        )
        
        DynamicFormView(
            configuration: configuration,
            onSubmit: { _ in }
        )
        .environment(\.extensibleHints, hints.extensibleHints)
    }
}

/// Helper function to create a simple field view for DynamicFormField
@ViewBuilder
@MainActor
private func createSimpleFieldView(for field: DynamicFormField, hints: PresentationHints, loadedHints: [String: FieldDisplayHints] = [:]) -> some View {
    // First try loaded hints from .hints file, then fall back to field's own metadata
    let fieldHints = loadedHints[field.id] ?? field.displayHints
    
    platformVStackContainer(alignment: .leading, spacing: 8) {
        Text(field.label)
            .font(.subheadline)
            .fontWeight(.medium)
        
        // Handle text fields using cross-platform text content type
        if let textContentType = field.textContentType {
            // Cross-platform exhaustive switch - same behavior on all platforms
            switch textContentType {
            case .emailAddress, .password, .telephoneNumber, .URL, .oneTimeCode, .name, .username, .newPassword, .postalCode, .creditCardNumber, .fullStreetAddress, .jobTitle, .organizationName, .givenName, .familyName, .middleName, .namePrefix, .nameSuffix, .addressState, .countryName, .streetAddressLine1, .streetAddressLine2, .addressCity, .addressCityAndState, .sublocality, .location:
                TextField(field.placeholder ?? "Enter \(field.label)", text: .constant(field.defaultValue ?? ""))
                    .textFieldStyle(.roundedBorder)
                    .applyFieldHints(fieldHints)
                    .automaticCompliance(
                        identifierElementType: "TextField",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    #if canImport(UIKit)
                    .textContentType(textContentType.uiTextContentType)
                    #endif
            }
        }
        // Handle UI components using our custom DynamicContentType
        else if let contentType = field.contentType {
            switch contentType {
            case .number, .integer:
                TextField(field.placeholder ?? "Enter \(field.label)", value: .constant(0), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .automaticCompliance(
                        identifierElementType: "TextField",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            case .stepper:
                Stepper(field.label, value: .constant(0.0), in: 0...100, step: 1.0)
                    .automaticCompliance(
                        identifierElementType: "Stepper",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            case .textarea, .richtext:
                TextEditor(text: .constant(field.defaultValue ?? ""))
                    .frame(minHeight: 80)
                    .applyFieldHints(fieldHints)
                    .automaticCompliance(
                        identifierElementType: "TextEditor",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            case .toggle, .boolean:
                Toggle(field.label, isOn: .constant(false))
                    .automaticCompliance(
                        identifierElementType: "Toggle",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            case .select:
                let i18n = InternationalizationService()
                Picker(field.placeholder ?? i18n.placeholderSelectOption(), selection: .constant("")) {
                    Text(i18n.placeholderSelectOption()).tag("")
                    if let options = field.options {
                        ForEach(options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                .pickerStyle(.menu)
                .automaticCompliance(
                    identifierElementType: "Picker",
                    accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                )
            case .date:
                let i18n = InternationalizationService()
                DatePicker("", selection: .constant(Date()))
                    .datePickerStyle(.compact)
                    .selfLabelingControl(label: field.placeholder ?? i18n.placeholderSelectDate())
                    .automaticCompliance(
                        identifierElementType: "DatePicker",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            case .multiDate, .dateRange:
                // Use DatePicker as fallback for Layer1 (MultiDatePicker requires iOS 16+)
                let i18n = InternationalizationService()
                DatePicker("", selection: .constant(Date()))
                    .datePickerStyle(.compact)
                    .selfLabelingControl(label: field.placeholder ?? i18n.placeholderSelectDates())
                    .automaticCompliance(
                        identifierElementType: "DatePicker",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            case .time:
                let i18n = InternationalizationService()
                DatePicker("", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .selfLabelingControl(label: field.placeholder ?? i18n.placeholderSelectTime())
                    .automaticCompliance(
                        identifierElementType: "DatePicker",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            case .color:
                ColorPicker("", selection: .constant(.blue))
                    .selfLabelingControl(label: field.label)
                    .automaticCompliance(
                        identifierElementType: "ColorPicker",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            case .range:
                Slider(value: .constant(0.5), in: 0...1)
                    .automaticCompliance(
                        identifierElementType: "Slider",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            case .display:
                // Display fields use LabeledContent or fallback HStack
                if #available(iOS 16.0, macOS 13.0, *) {
                    LabeledContent(field.label) {
                        Text(field.defaultValue ?? "—")
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Text(field.label)
                            .font(.subheadline)
                        Spacer()
                        Text(field.defaultValue ?? "—")
                            .foregroundColor(.secondary)
                    }
                }
            case .gauge:
                // Gauge fields use Gauge component or fallback ProgressView
                let min = Double(field.metadata?["min"] ?? "0") ?? 0.0
                let max = Double(field.metadata?["max"] ?? "100") ?? 100.0
                let value = Double(field.defaultValue ?? "0") ?? 0.0
                let range = min...max
                
                    if #available(iOS 16.0, macOS 13.0, *) {
                        if field.metadata?["gaugeStyle"] == "circular" {
                            Gauge(value: value, in: range) {
                                if let label = field.metadata?["gaugeLabel"] {
                                    Text(label)
                                }
                            } currentValueLabel: {
                                Text("\(Int(value))")
                            } minimumValueLabel: {
                                Text("\(Int(min))")
                            } maximumValueLabel: {
                                Text("\(Int(max))")
                            }
                            .gaugeStyle(.accessoryCircularCapacity)
                        } else {
                            Gauge(value: value, in: range) {
                                if let label = field.metadata?["gaugeLabel"] {
                                    Text(label)
                                }
                            } currentValueLabel: {
                                Text("\(Int(value))")
                            } minimumValueLabel: {
                                Text("\(Int(min))")
                            } maximumValueLabel: {
                                Text("\(Int(max))")
                            }
                            .gaugeStyle(.linearCapacity)
                        }
                } else {
                    platformVStackContainer(alignment: .leading) {
                        ProgressView(value: value, total: max)
                            .progressViewStyle(.linear)
                        Text("\(Int(value)) / \(Int(max))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            case .multiselect, .radio, .checkbox, .file, .image, .datetime, .array, .data, .custom, .text, .email, .password, .phone, .url, .autocomplete, .enum:
                TextField(field.placeholder ?? "Enter \(field.label)", text: .constant(field.defaultValue ?? ""))
                    .textFieldStyle(.roundedBorder)
                    .automaticCompliance(
                        identifierElementType: "TextField",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            }
        }
        // Fallback for fields with neither textContentType nor contentType
        else {
            TextField(field.placeholder ?? "Enter \(field.label)", text: .constant(field.defaultValue ?? ""))
                .textFieldStyle(.roundedBorder)
                .automaticCompliance(
                    identifierElementType: "TextField",
                    accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                )
        }
    }
}

/// Generic function for presenting media data with enhanced hints
@MainActor
public func platformPresentMediaData_L1(
    media: [GenericMediaItem],
    hints: EnhancedPresentationHints
) -> some View {
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return GenericMediaView(media: media, hints: processedHints)
        .environment(\.extensibleHints, hints.extensibleHints)
        .environment(\.accessibilityIdentifierName, "platformPresentMediaData_L1")
        .automaticCompliance()
}

/// Generic function for presenting hierarchical data with enhanced hints
@MainActor
public func platformPresentHierarchicalData_L1(
    items: [GenericHierarchicalItem],
    hints: EnhancedPresentationHints
) -> some View {
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return GenericHierarchicalView(items: items, hints: processedHints)
        .environment(\.extensibleHints, hints.extensibleHints)
        .environment(\.accessibilityIdentifierName, "platformPresentHierarchicalData_L1")
        .automaticCompliance()
}

/// Generic function for presenting temporal data with enhanced hints
@MainActor
public func platformPresentTemporalData_L1(
    items: [GenericTemporalItem],
    hints: EnhancedPresentationHints
) -> some View {
    let basicHints = PresentationHints(
        dataType: hints.dataType,
        presentationPreference: hints.presentationPreference,
        complexity: hints.complexity,
        context: hints.context,
        customPreferences: hints.customPreferences,
        fieldHints: hints.fieldHints
    )
    
    let processedHints = processExtensibleHints(hints, into: basicHints)
    
    return GenericTemporalView(items: items, hints: processedHints)
        .environment(\.extensibleHints, hints.extensibleHints)
        .environment(\.accessibilityIdentifierName, "platformPresentTemporalData_L1")
        .automaticCompliance()
}

// MARK: - Generic View Structures

/// Custom item collection view that supports custom views for items and actions
public struct CustomItemCollectionView<Item: Identifiable>: View {
    let items: [Item]
    let hints: PresentationHints
    let onCreateItem: (() -> Void)?
    let onItemSelected: ((Item) -> Void)?
    let onItemDeleted: ((Item) -> Void)?
    let onItemEdited: ((Item) -> Void)?
    let customItemView: (Item) -> AnyView
    let customCreateView: (() -> AnyView)?
    let customEditView: ((Item) -> AnyView)?
    
    public init(
        items: [Item],
        hints: PresentationHints,
        onCreateItem: (() -> Void)? = nil,
        onItemSelected: ((Item) -> Void)? = nil,
        onItemDeleted: ((Item) -> Void)? = nil,
        onItemEdited: ((Item) -> Void)? = nil,
        @ViewBuilder customItemView: @escaping (Item) -> some View,
        customCreateView: (() -> some View)? = nil,
        customEditView: ((Item) -> some View)? = nil
    ) {
        self.items = items
        self.hints = hints
        self.onCreateItem = onCreateItem
        self.onItemSelected = onItemSelected
        self.onItemDeleted = onItemDeleted
        self.onItemEdited = onItemEdited
        self.customItemView = { AnyView(customItemView($0)) }
        // Note: Custom views temporarily disabled due to compilation issues
        self.customCreateView = nil
        self.customEditView = nil
    }
    
    public var body: some View {
        if items.isEmpty {
            return AnyView(CollectionEmptyStateView(
                hints: hints, 
                onCreateItem: onCreateItem,
                customCreateView: customCreateView
            ))
        }
        
        // Use custom item views with intelligent layout
        let presentationStrategy = determinePresentationStrategy()
        
        switch presentationStrategy {
        case .grid:
            return AnyView(CustomGridCollectionView(
                items: items,
                hints: hints,
                customItemView: customItemView,
                onItemSelected: onItemSelected,
                onItemDeleted: onItemDeleted,
                onItemEdited: onItemEdited
            ))
        case .list:
            return AnyView(CustomListCollectionView(
                items: items,
                hints: hints,
                customItemView: customItemView,
                onItemSelected: onItemSelected,
                onItemDeleted: onItemDeleted,
                onItemEdited: onItemEdited
            ))
        default:
            // Fall back to grid for custom views
            return AnyView(CustomGridCollectionView(
                items: items,
                hints: hints,
                customItemView: customItemView,
                onItemSelected: onItemSelected,
                onItemDeleted: onItemDeleted,
                onItemEdited: onItemEdited
            ))
        }
    }
    
    /// Determine the optimal presentation strategy based on hints and platform
    private func determinePresentationStrategy() -> PresentationStrategy {
        let _ = hints.customPreferences["itemType"] ?? "generic"
        let _ = hints.customPreferences["interactionStyle"] ?? "static"
        
        // Platform-aware decision making
        let platform = SixLayerPlatform.currentPlatform
        let deviceType = SixLayerPlatform.deviceType
        
        // For custom views, prefer grid on larger screens, list on smaller
        // Use PlatformStrategy to reduce code duplication (Issue #140)
        let preference = platform.defaultPresentationPreference(deviceType: deviceType)
        return presentationStrategyFromPreference(preference)
    }
    
    /// Convert PresentationPreference to PresentationStrategy
    /// Helper function to bridge PlatformStrategy (which uses PresentationPreference) 
    /// with internal PresentationStrategy enum
    private func presentationStrategyFromPreference(_ preference: PresentationPreference) -> PresentationStrategy {
        switch preference {
        case .cards, .card:
            return .expandableCards
        case .list:
            return .list
        case .grid:
            return .grid
        case .masonry:
            return .masonry
        case .coverFlow:
            return .coverFlow
        case .automatic:
            return .adaptive
        default:
            return .adaptive
        }
    }
}

/// Generic item collection view with intelligent presentation decisions
public struct GenericItemCollectionView<Item: Identifiable>: View {
    let items: [Item]
    let hints: PresentationHints
    let onCreateItem: (() -> Void)?
    let onItemSelected: ((Item) -> Void)?
    let onItemDeleted: ((Item) -> Void)?
    let onItemEdited: ((Item) -> Void)?
    
    public init(
        items: [Item], 
        hints: PresentationHints, 
        onCreateItem: (() -> Void)? = nil,
        onItemSelected: ((Item) -> Void)? = nil,
        onItemDeleted: ((Item) -> Void)? = nil,
        onItemEdited: ((Item) -> Void)? = nil
    ) {
        self.items = items
        self.hints = hints
        self.onCreateItem = onCreateItem
        self.onItemSelected = onItemSelected
        self.onItemDeleted = onItemDeleted
        self.onItemEdited = onItemEdited
    }
    
    public var body: some View {
        // Handle empty collections with appropriate empty state
        if items.isEmpty {
            return AnyView(CollectionEmptyStateView(hints: hints, onCreateItem: onCreateItem)
                .appleHIGCompliant()
                .automaticAccessibility()
                .automaticCompliance()
                .platformPatterns()
                .visualConsistency())
        }
        
        // Layer 1: Intelligent presentation decision based on hints and platform
        let presentationStrategy = determinePresentationStrategy()
        
        let baseView: AnyView = switch presentationStrategy {
        case .expandableCards:
            AnyView(ExpandableCardCollectionView(
                items: items, 
                hints: hints, 
                onCreateItem: onCreateItem,
                onItemSelected: onItemSelected,
                onItemDeleted: onItemDeleted,
                onItemEdited: onItemEdited
            ))
        case .coverFlow:
            AnyView(CoverFlowCollectionView(
                items: items, 
                hints: hints, 
                onCreateItem: onCreateItem,
                onItemSelected: onItemSelected,
                onItemDeleted: onItemDeleted,
                onItemEdited: onItemEdited
            ))
        case .grid:
            AnyView(GridCollectionView(
                items: items, 
                hints: hints, 
                onCreateItem: onCreateItem,
                onItemSelected: onItemSelected,
                onItemDeleted: onItemDeleted,
                onItemEdited: onItemEdited
            ))
        case .list:
            AnyView(ListCollectionView(
                items: items, 
                hints: hints, 
                onCreateItem: onCreateItem,
                onItemSelected: onItemSelected,
                onItemDeleted: onItemDeleted,
                onItemEdited: onItemEdited
            ))
        case .masonry:
            AnyView(MasonryCollectionView(
                items: items, 
                hints: hints, 
                onCreateItem: onCreateItem,
                onItemSelected: onItemSelected,
                onItemDeleted: onItemDeleted,
                onItemEdited: onItemEdited
            ))
        case .adaptive:
            AnyView(AdaptiveCollectionView(
                items: items, 
                hints: hints, 
                onCreateItem: onCreateItem,
                onItemSelected: onItemSelected,
                onItemDeleted: onItemDeleted,
                onItemEdited: onItemEdited
            ))
        }
        
        // AUTOMATICALLY apply HIG compliance - this is the key fix!
        return AnyView(baseView
            .appleHIGCompliant()
            .automaticAccessibility()
            .automaticCompliance()
            .platformPatterns()
            .visualConsistency())
    }
    
    /// Determine the optimal presentation strategy based on hints and platform
    private func determinePresentationStrategy() -> PresentationStrategy {
        let itemTypeString = hints.customPreferences["itemType"] ?? "generic"
        let interactionStyleString = hints.customPreferences["interactionStyle"] ?? "static"
        let _ = hints.customPreferences["layoutPreference"] ?? "automatic"
        
        // Convert strings to enums for type safety
        let itemType = ItemType.from(string: itemTypeString)
        let interactionStyle = InteractionStyle(rawValue: interactionStyleString) ?? .static
        
        // Platform-aware decision making
        let platform = SixLayerPlatform.currentPlatform
        let deviceType = SixLayerPlatform.deviceType
        
        // Feature cards with expandable interaction
        if itemType == .featureCards && interactionStyle == .expandable {
            switch platform {
            case .visionOS:
                return .coverFlow // Spatial interface prefers coverflow
            case .macOS:
                return .expandableCards // Desktop prefers hover-expandable cards
            case .iOS:
                return deviceType == .pad ? .expandableCards : .adaptive
            case .watchOS, .tvOS:
                return .list // Constrained interfaces prefer lists
            }
        }
        
        // Media content
        if hints.dataType == .media {
            // Use PlatformStrategy to reduce code duplication (Issue #140)
            let preference = platform.defaultMediaPresentationPreference(deviceType: deviceType)
            return presentationStrategyFromPreference(preference)
        }
        
        // Navigation items
        if hints.dataType == .navigation {
            // Use PlatformStrategy to reduce code duplication (Issue #140)
            let preference = platform.defaultNavigationPresentationPreference()
            return presentationStrategyFromPreference(preference)
        }
        
        // Default based on presentation preference
        switch hints.presentationPreference {
        case .cards:
            return .expandableCards
        case .list:
            return .list
        case .grid:
            return .grid
        case .masonry:
            return .masonry
        case .coverFlow:
            return .coverFlow
        case .countBased(let lowCount, let highCount, let threshold):
            // Explicit count-based preference
            return items.count <= threshold
                ? determineStrategyForPreference(lowCount)
                : determineStrategyForPreference(highCount)
        case .automatic:
            // Count-aware logic for generic/collection content
            if hints.dataType == .generic || hints.dataType == .collection {
                // Safety override: very large collections → list
                if items.count > 200 {
                    return .list
                }
                
                // Count-aware automatic selection
                return determineCountAwareStrategy(
                    count: items.count,
                    dataType: hints.dataType,
                    platform: platform,
                    deviceType: deviceType
                )
            }
            // For other content types with .automatic, use adaptive
            return .adaptive
        default:
            return .adaptive
        }
    }
    
    /// Determine count-aware presentation strategy for generic/collection content
    private func determineCountAwareStrategy(
        count: Int,
        dataType: DataTypeHint,
        platform: SixLayerPlatform,
        deviceType: DeviceType
    ) -> PresentationStrategy {
        let threshold = getCountThreshold(
            dataType: dataType,
            platform: platform,
            deviceType: deviceType
        )
        
        if count <= threshold {
            // Small collection: prefer cards/grid
            switch (platform, deviceType) {
            case (.macOS, _), (.iOS, .pad):
                return .grid
            case (.iOS, .phone):
                return count <= 4 ? .expandableCards : .grid
            default:
                return .grid
            }
        } else {
            // Large collection: prefer list
            return .list
        }
    }
    
    /// Get count threshold based on content type, platform, and device
    /// Uses PlatformStrategy to reduce code duplication (Issue #140)
    private func getCountThreshold(
        dataType: DataTypeHint,
        platform: SixLayerPlatform,
        deviceType: DeviceType
    ) -> Int {
        // Use PlatformStrategy which handles both base threshold and platform/device adjustments
        return platform.countThreshold(dataType: dataType, deviceType: deviceType)
    }

    /// Convert PresentationPreference to PresentationStrategy
    /// Helper function to bridge PlatformStrategy (which uses PresentationPreference) 
    /// with internal PresentationStrategy enum
    private func presentationStrategyFromPreference(_ preference: PresentationPreference) -> PresentationStrategy {
        switch preference {
        case .cards, .card:
            return .expandableCards
        case .list:
            return .list
        case .grid:
            return .grid
        case .masonry:
            return .masonry
        case .coverFlow:
            return .coverFlow
        case .automatic:
            return .adaptive
        default:
            return .adaptive
        }
    }
    
    /// Convert a PresentationPreference to a PresentationStrategy
    /// Used for countBased preferences where nested preferences need resolution
    private func determineStrategyForPreference(_ preference: PresentationPreference) -> PresentationStrategy {
        switch preference {
        case .cards, .card:
            return .expandableCards
        case .list:
            return .list
        case .grid:
            return .grid
        case .masonry:
            return .masonry
        case .coverFlow:
            return .coverFlow
        case .automatic:
            // Recursive: use count-aware automatic logic from Phase 1
            return determineCountAwareStrategy(
                count: items.count,
                dataType: hints.dataType,
                platform: SixLayerPlatform.currentPlatform,
                deviceType: SixLayerPlatform.deviceType
            )
        case .countBased:
            // Shouldn't happen (handled above), but fallback to prevent recursion
            return .adaptive
        default:
            return .adaptive
        }
    }
}

/// Empty state view for collections with intelligent messaging based on context
public struct CollectionEmptyStateView: View {
    let hints: PresentationHints
    let onCreateItem: (() -> Void)?
    let customCreateView: (() -> AnyView)?
    
    public init(hints: PresentationHints, onCreateItem: (() -> Void)? = nil, customCreateView: (() -> AnyView)? = nil) {
        self.hints = hints
        self.onCreateItem = onCreateItem
        self.customCreateView = customCreateView
    }
    
    public var body: some View {
        platformVStackContainer(spacing: 20) {
            // Icon based on data type and context
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            platformVStackContainer(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Create action button if provided
            if let onCreateItem = onCreateItem {
                if let customCreateView = customCreateView {
                    Button(action: onCreateItem) {
                        customCreateView()
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: onCreateItem) {
                        platformHStackContainer(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text(createButtonTitle)
                        }
                        .font(.headline)
                        .foregroundColor(.platformButtonTextOnColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .automaticCompliance()
    }
    
    private var emptyStateIcon: String {
        switch hints.dataType {
        case .media:
            return "photo.on.rectangle"
        case .navigation:
            return "list.bullet"
        case .form:
            return "doc.text"
        case .numeric:
            return "chart.bar"
        case .temporal:
            return "calendar"
        case .hierarchical:
            return "folder"
        case .collection:
            return "square.grid.2x2"
        case .generic:
            return "tray"
        case .text:
            return "text.alignleft"
        case .number:
            return "number"
        case .date:
            return "calendar"
        case .image:
            return "photo"
        case .boolean:
            return "checkmark.circle"
        case .list:
            return "list.bullet"
        case .grid:
            return "grid"
        case .chart:
            return "chart.bar"
        case .action:
            return "play.circle"
        case .product:
            return "bag"
        case .user:
            return "person"
        case .transaction:
            return "creditcard"
        case .communication:
            return "message"
        case .location:
            return "location"
        case .custom:
            return "gear"
        case .card:
            return "creditcard"
        case .detail:
            return "doc.text"
        case .modal:
            return "rectangle.portrait"
        case .sheet:
            return "rectangle.portrait"
        }
    }
    
    private var emptyStateTitle: String {
        switch hints.dataType {
        case .media:
            return "No Media Items"
        case .navigation:
            return "No Navigation Items"
        case .form:
            return "No Form Fields"
        case .numeric:
            return "No Data Available"
        case .temporal:
            return "No Events"
        case .hierarchical:
            return "No Items"
        case .collection:
            return "No Items"
        case .generic:
            return "No Items"
        case .text:
            return "No Text Content"
        case .number:
            return "No Numbers"
        case .date:
            return "No Dates"
        case .image:
            return "No Images"
        case .boolean:
            return "No Boolean Values"
        case .list:
            return "No List Items"
        case .grid:
            return "No Grid Items"
        case .chart:
            return "No Chart Data"
        case .action:
            return "No Actions"
        case .product:
            return "No Products"
        case .user:
            return "No Users"
        case .transaction:
            return "No Transactions"
        case .communication:
            return "No Messages"
        case .location:
            return "No Locations"
        case .custom:
            return "No Items"
        case .card:
            return "No Cards"
        case .detail:
            return "No Details"
        case .modal:
            return "No Modal Content"
        case .sheet:
            return "No Sheet Content"
        }
    }
    
    private var emptyStateMessage: String {
        // Check for custom message in customPreferences first (takes precedence)
        if let customMessage = hints.customPreferences["customMessage"], !customMessage.isEmpty {
            return customMessage
        }
        
        // Fall back to default context/complexity-based messages
        let contextMessage = contextSpecificMessage
        let complexityMessage = complexitySpecificMessage
        
        if !contextMessage.isEmpty && !complexityMessage.isEmpty {
            return "\(contextMessage) \(complexityMessage)"
        } else if !contextMessage.isEmpty {
            return contextMessage
        } else if !complexityMessage.isEmpty {
            return complexityMessage
        } else {
            let i18n = InternationalizationService()
            return i18n.localizedString(for: "SixLayerFramework.emptyState.collectionEmpty")
        }
    }
    
    private var contextSpecificMessage: String {
        switch hints.context {
        case .dashboard:
            return "Add some items to get started."
        case .standard:
            return "No items available."
        case .detail:
            return "No additional items to display."
        case .summary:
            return "No summary data available."
        case .edit:
            return "No items to edit."
        case .create:
            return "Create your first item."
        case .search:
            return "Try adjusting your search criteria."
        case .browse:
            return "No items to browse."
        case .list:
            return "No items in this list."
        case .form:
            return "No form fields available."
        case .modal:
            let i18n = InternationalizationService()
            return i18n.localizedString(for: "SixLayerFramework.navigation.selectItemToContinue")
        case .navigation:
            return "No navigation items available."
        case .settings:
            return "No settings available."
        case .profile:
            return "No profile information available."
        case .gallery:
            return "No items in this gallery."
        }
    }
    
    private var complexitySpecificMessage: String {
        let i18n = InternationalizationService()
        switch hints.complexity {
        case .simple:
            return i18n.localizedString(for: "SixLayerFramework.complexity.simple")
        case .moderate:
            return i18n.localizedString(for: "SixLayerFramework.complexity.moderate")
        case .complex:
            return i18n.localizedString(for: "SixLayerFramework.complexity.complex")
        case .veryComplex:
            return i18n.localizedString(for: "SixLayerFramework.complexity.veryComplex")
        case .advanced:
            return i18n.localizedString(for: "SixLayerFramework.complexity.advanced")
        }
    }
    
    private var createButtonTitle: String {
        switch hints.dataType {
        case .media:
            return "Add Media"
        case .navigation:
            return "Add Navigation Item"
        case .form:
            return "Add Form Field"
        case .numeric:
            return "Add Data"
        case .temporal:
            return "Add Event"
        case .hierarchical:
            return "Add Item"
        case .collection:
            return "Add Item"
        case .generic:
            return "Add Item"
        case .text:
            return "Add Text"
        case .number:
            return "Add Number"
        case .date:
            return "Add Date"
        case .image:
            return "Add Image"
        case .boolean:
            return "Add Boolean"
        case .list:
            return "Add List Item"
        case .grid:
            return "Add Grid Item"
        case .chart:
            return "Add Chart Data"
        case .action:
            return "Add Action"
        case .product:
            return "Add Product"
        case .user:
            return "Add User"
        case .transaction:
            return "Add Transaction"
        case .communication:
            return "Add Message"
        case .location:
            return "Add Location"
        case .custom:
            return "Add Item"
        case .card:
            return "Add Card"
        case .detail:
            return "Add Detail"
        case .modal:
            return "Add Modal"
        case .sheet:
            return "Add Sheet"
        }
    }
}

/// Presentation strategies that Layer 1 can choose from
private enum PresentationStrategy {
    case expandableCards
    case coverFlow
    case grid
    case list
    case masonry
    case adaptive
}

/// Generic numeric data view
public struct GenericNumericDataView: View {
    let data: [GenericNumericData]
    let hints: PresentationHints
    
    public init(data: [GenericNumericData], hints: PresentationHints) {
        self.data = data
        self.hints = hints
    }
    
    // Convenience initializer for any numeric type
    public init<T: Numeric>(values: [T], hints: PresentationHints) {
        self.data = values.enumerated().map { index, value in
            // Convert any numeric type to Double safely
            let doubleValue: Double
            if let intValue = value as? Int {
                doubleValue = Double(intValue)
            } else if let floatValue = value as? Float {
                doubleValue = Double(floatValue)
            } else if let cgFloatValue = value as? CGFloat {
                doubleValue = Double(cgFloatValue)
            } else if let doubleVal = value as? Double {
                doubleValue = doubleVal
            } else {
                // Fallback: convert via String (not ideal but safe)
                doubleValue = Double(String(describing: value)) ?? 0.0
            }
            
            return GenericNumericData(value: doubleValue, label: "Value \(index + 1)")
        }
        self.hints = hints
    }
    
    public var body: some View {
        let baseView = VStack {
            Text("Numeric Data")
                .font(.headline)
            Text("Data points: \(data.count)")
                .font(.caption)
        }
        .padding()
        
        // AUTOMATICALLY apply HIG compliance
        return baseView
            .appleHIGCompliant()
            .automaticAccessibility()
            .platformPatterns()
            .visualConsistency()
            .automaticCompliance()
    }
}

/// Generic form view using our platform extensions
public struct GenericFormView: View {
    let fields: [DynamicFormField]
    let hints: PresentationHints
    
    public var body: some View {
        // Use our platform form container from Layer 4
        platformFormContainer_L4(
            strategy: FormStrategy(
                containerType: .standard,
                fieldLayout: .vertical,
                validation: .deferred
            ),
            content: {
                ForEach(fields, id: \.id) { field in
                    platformVStackContainer(alignment: .leading, spacing: 8) {
                        Text(field.label)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color.platformLabel)
                        
                        // Use platform-specific field styling based on field type
                        if let textContentType = field.textContentType {
                            // Handle text fields using OS UITextContentType
                            TextField(field.placeholder ?? "Enter \(field.label)", text: .constant(""))
                                .textFieldStyle(.roundedBorder)
                                .background(Color.platformSecondaryBackground)
                                #if canImport(UIKit)
                                .textContentType(textContentType.uiTextContentType)
                                #endif
                        } else if let contentType = field.contentType {
                            // Handle UI components using our custom DynamicContentType
                            switch contentType {
                            case .text, .email, .password:
                                TextField(field.placeholder ?? "Enter \(field.label)", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)
                                    .background(Color.platformSecondaryBackground)
                            case .number, .integer:
                                TextField(field.placeholder ?? "Enter \(field.label)", value: .constant(0), format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .background(Color.platformSecondaryBackground)
                            case .textarea:
                                TextEditor(text: .constant(""))
                                    .frame(minHeight: 80)
                                    .background(Color.platformSecondaryBackground)
                                    .cornerRadius(8)
                            case .toggle, .boolean:
                                Toggle(field.label, isOn: .constant(false))
                            case .select:
                                Picker(field.label, selection: .constant("")) {
                                    if let options = field.options {
                                        ForEach(options, id: \.self) { option in
                                            Text(option)
                                                .tag(option)
                                                .accessibilityIdentifier(option) // Apply identifier to segment
                                                .accessibility(label: Text(option)) // Apply label to segment (Stack Overflow pattern)
                                        }
                                    }
                                }
                                .pickerStyle(.menu)
                                .automaticCompliance() // Apply to picker level as well
                            default:
                                TextField(field.placeholder ?? "Enter \(field.label)", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)
                                    .background(Color.platformSecondaryBackground)
                            }
                        } else {
                            // Fallback for fields with neither textContentType nor contentType
                            TextField(field.placeholder ?? "Enter \(field.label)", text: .constant(""))
                                .textFieldStyle(.roundedBorder)
                                .background(Color.platformSecondaryBackground)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        )
        .automaticCompliance(named: "GenericFormView")
    }
}

/// Generic media view
public struct GenericMediaView: View {
    let media: [GenericMediaItem]
    let hints: PresentationHints
    
    public var body: some View {
        VStack {
            Text("Media Collection")
                .font(.headline)
            Text("Items: \(media.count)")
                .font(.caption)
        }
        .padding()
        .automaticCompliance()
    }
}

/// Generic hierarchical view
public struct GenericHierarchicalView: View {
    let items: [GenericHierarchicalItem]
    let hints: PresentationHints
    
    public var body: some View {
        VStack {
            Text("Hierarchical Data")
                .font(.headline)
            Text("Root items: \(items.count)")
                .font(.caption)
        }
        .padding()
        .automaticCompliance()
    }
}

/// Generic temporal view
public struct GenericTemporalView: View {
    let items: [GenericTemporalItem]
    let hints: PresentationHints
    
    public var body: some View {
        VStack {
            Text("Temporal Data")
                .font(.headline)
            Text("Events: \(items.count)")
                .font(.caption)
        }
        .padding()
        .automaticCompliance()
    }
}

/// Modal form view for presenting forms in modal context
public struct ModalFormView: View {
    let fields: [DynamicFormField]
    let formType: DataTypeHint
    let context: PresentationContext
    let hints: PresentationHints
    
    public var body: some View {
        platformVStackContainer(spacing: 16) {
            // Modal header
            HStack {
                Text("Form: \(formType.rawValue.capitalized)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                let i18n = InternationalizationService()
                Button(i18n.localizedString(for: "SixLayerFramework.button.done")) {
                    // TODO: Implement dismiss action
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Form content
            ScrollView {
                platformVStackContainer(spacing: 16) {
                    ForEach(fields, id: \.id) { field in
                        createFieldView(for: field)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(Color.platformBackground)
        .automaticCompliance()
    }
    
    @ViewBuilder
    @MainActor
    private func createFieldView(for field: DynamicFormField) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let textContentType = field.textContentType {
                // Handle text fields using OS UITextContentType
                TextField(field.placeholder ?? "Enter text", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .automaticCompliance(
                        identifierElementType: "TextField",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    #if canImport(UIKit)
                    .textContentType(textContentType.uiTextContentType)
                    #endif
            } else if let contentType = field.contentType {
                // Handle UI components using our custom DynamicContentType
                switch contentType {
                case .text:
                    TextField(field.placeholder ?? "Enter text", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .email:
                    TextField(field.placeholder ?? "Enter email", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .password:
                    SecureField(field.placeholder ?? "Enter password", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "SecureField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .number:
                    TextField(field.placeholder ?? "Enter number", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .date:
                    let i18n = InternationalizationService()
                    DatePicker("", selection: .constant(Date()))
                        .datePickerStyle(.compact)
                        .selfLabelingControl(label: field.placeholder ?? i18n.placeholderSelectDate())
                        .automaticCompliance(
                            identifierElementType: "DatePicker",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .multiDate, .dateRange:
                    // Use DatePicker as fallback for Layer1 (MultiDatePicker requires iOS 16+)
                    let i18n = InternationalizationService()
                    DatePicker("", selection: .constant(Date()))
                        .datePickerStyle(.compact)
                        .selfLabelingControl(label: field.placeholder ?? i18n.placeholderSelectDates())
                        .automaticCompliance(
                            identifierElementType: "DatePicker",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .select:
                    let i18n = InternationalizationService()
                    Picker(field.placeholder ?? i18n.placeholderSelectOption(), selection: .constant("")) {
                        Text(i18n.placeholderSelectOption()).tag("")
                        if let options = field.options {
                            ForEach(options, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .automaticCompliance(
                        identifierElementType: "Picker",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                case .textarea:
                    TextEditor(text: .constant(""))
                        .frame(minHeight: 80)
                        .automaticCompliance(
                            identifierElementType: "TextEditor",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                case .checkbox:
                    Toggle(field.placeholder ?? "Toggle", isOn: .constant(false))
                        .automaticCompliance(
                            identifierElementType: "Toggle",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .radio:
                    platformVStackContainer(alignment: .leading) {
                        Text(field.label)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let options = field.options {
                            ForEach(options, id: \.self) { option in
                                HStack {
                                    Button(action: {
                                        // TODO: Update field value when DynamicFormState is implemented
                                    }) {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                    .automaticCompliance(
                                        identifierElementType: "Button",
                                        accessibilityLabel: "\(field.label): \(option)"  // Issue #156: Parameter-based approach
                                    )
                                    Text(option)
                                }
                            }
                        }
                    }
                    .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                case .phone:
                    TextField(field.placeholder ?? "Enter phone", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .time:
                    let i18n = InternationalizationService()
                    DatePicker("", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .selfLabelingControl(label: field.placeholder ?? i18n.placeholderSelectTime())
                        .automaticCompliance(
                            identifierElementType: "DatePicker",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .datetime:
                    let i18n = InternationalizationService()
                    DatePicker("", selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .selfLabelingControl(label: field.placeholder ?? i18n.placeholderSelectDateTime())
                        .automaticCompliance(
                            identifierElementType: "DatePicker",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .multiselect:
                    Text("Multi-select field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                            identifierElementType: "View",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .file:
                    Text("File upload field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                            identifierElementType: "View",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .url:
                    TextField(field.placeholder ?? "Enter URL", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .color:
                    Text("Color picker field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                            identifierElementType: "View",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .range:
                    Text("Range field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                            identifierElementType: "View",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .toggle, .boolean:
                    Toggle(field.placeholder ?? "Toggle", isOn: .constant(false))
                case .richtext:
                    Text("Rich text field: \(field.label)")
                        .foregroundColor(.secondary)
                case .autocomplete:
                    Text("Autocomplete field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                            identifierElementType: "View",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .integer:
                    TextField(field.placeholder ?? "Enter integer", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .image:
                    Text("Image field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                            identifierElementType: "View",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .array:
                    Text("Array field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                            identifierElementType: "View",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .data:
                    Text("Data field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                            identifierElementType: "View",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                case .custom:
                    Text("Custom field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                case .display:
                    // Display fields use LabeledContent or fallback HStack
                    if #available(iOS 16.0, macOS 13.0, *) {
                        LabeledContent(field.label) {
                            Text(field.defaultValue ?? "—")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text(field.label)
                                .font(.subheadline)
                            Spacer()
                            Text(field.defaultValue ?? "—")
                                .foregroundColor(.secondary)
                        }
                    }
                case .gauge:
                    // Gauge fields use Gauge component or fallback ProgressView
                    let min = Double(field.metadata?["min"] ?? "0") ?? 0.0
                    let max = Double(field.metadata?["max"] ?? "100") ?? 100.0
                    let value = Double(field.defaultValue ?? "0") ?? 0.0
                    let range = min...max
                    
                    if #available(iOS 16.0, macOS 13.0, *) {
                        if field.metadata?["gaugeStyle"] == "circular" {
                            Gauge(value: value, in: range) {
                                if let label = field.metadata?["gaugeLabel"] {
                                    Text(label)
                                }
                            } currentValueLabel: {
                                Text("\(Int(value))")
                            } minimumValueLabel: {
                                Text("\(Int(min))")
                            } maximumValueLabel: {
                                Text("\(Int(max))")
                            }
                            .gaugeStyle(.accessoryCircularCapacity)
                        } else {
                            Gauge(value: value, in: range) {
                                if let label = field.metadata?["gaugeLabel"] {
                                    Text(label)
                                }
                            } currentValueLabel: {
                                Text("\(Int(value))")
                            } minimumValueLabel: {
                                Text("\(Int(min))")
                            } maximumValueLabel: {
                                Text("\(Int(max))")
                            }
                            .gaugeStyle(.linearCapacity)
                        }
                    } else {
                        platformVStackContainer(alignment: .leading) {
                            ProgressView(value: value, total: max)
                                .progressViewStyle(.linear)
                            Text("\(Int(value)) / \(Int(max))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                case .stepper:
                    Stepper(field.label, value: .constant(0.0), in: 0...100, step: 1.0)
                case .enum:
                    let i18n = InternationalizationService()
                    Picker(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectOption"), selection: .constant("")) {
                        let placeholderText = i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectOption")
                        Text(placeholderText)
                            .tag("")
                            .accessibilityIdentifier(placeholderText) // Apply identifier to segment
                            .accessibility(label: Text(placeholderText)) // Apply label to segment
                        if let options = field.options {
                            ForEach(options, id: \.self) { option in
                                Text(option)
                                    .tag(option)
                                    .accessibilityIdentifier(option) // Apply identifier to segment
                                    .accessibility(label: Text(option)) // Apply label to segment (Stack Overflow pattern)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    .automaticCompliance() // Apply to picker level as well
                }
            } else {
                // Fallback for fields with neither textContentType nor contentType
                TextField(field.placeholder ?? "Enter text", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
            }
        }
        .automaticCompliance()
    }
}

/// Simple form view that creates forms from generic form fields
// MARK: - DEPRECATED: This struct uses GenericFormField which has been deprecated
// TODO: Replace with DynamicFormField equivalents
/*
public struct SimpleFormView: View {
    let fields: [DynamicFormField]
    let hints: PresentationHints
    let onSubmit: (([String: String]) -> Void)?
    let onReset: (() -> Void)?
    
    @State private var validationErrors: [String: String] = [:]
    @State private var isSubmitting = false
    
    public init(
        fields: [DynamicFormField],
        hints: PresentationHints,
        onSubmit: (([String: String]) -> Void)? = nil,
        onReset: (() -> Void)? = nil
    ) {
        self.fields = fields
        self.hints = hints
        self.onSubmit = onSubmit
        self.onReset = onReset
    }
    
    public var body: some View {
        platformVStackContainer(spacing: 16) {
            // Form header
            HStack {
                Text(formTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(fields.count) fields")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Form fields
            ScrollView {
                platformVStackContainer(spacing: 16) {
                    ForEach(fields, id: \.id) { field in
                        createFieldView(for: field)
                    }
                }
                .padding(.horizontal)
            }
            
            // Form actions
            HStack {
                Button("Reset") {
                    resetForm()
                }
                .buttonStyle(.bordered)
                .disabled(isSubmitting)
                
                Spacer()
                
                Button("Submit") {
                    submitForm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting || !isFormValid)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.platformBackground)
    }
    
    // MARK: - Computed Properties
    
    private var formTitle: String {
        hints.customPreferences["formTitle"] ?? "Form"
    }
    
    private var isFormValid: Bool {
        validationErrors.isEmpty
    }
    
    // MARK: - Form Actions
    
    private func resetForm() {
        for field in fields {
            field.value = ""
        }
        validationErrors.removeAll()
        onReset?()
    }
    
    private func submitForm() {
        guard validateForm() else { return }
        
        isSubmitting = true
        
        let formData = Dictionary(uniqueKeysWithValues: fields.map { ($0.label, $0.value) })
        
        onSubmit?(formData)
        
        // Reset submitting state after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
        }
    }
    
    // MARK: - Validation
    
    private func validateForm() -> Bool {
        var errors: [String: String] = [:]
        
        for field in fields {
            let fieldError = validateField(field)
            if let error = fieldError {
                errors[field.id.uuidString] = error
            }
        }
        
        validationErrors = errors
        return errors.isEmpty
    }
    
    private func validateField(_ field: DynamicFormField) -> String? {
        let value = field.defaultValue ?? ""
        
        // Required validation
        if field.isRequired && value.isEmpty {
            return "\(field.label) is required"
        }
        
        // Skip other validations if field is empty and not required
        if value.isEmpty {
            return nil
        }
        
        // Apply validation rules
        if let validationRules = field.validationRules {
            for (ruleKey, ruleValue) in validationRules {
                if let error = validateRule(ruleKey: ruleKey, ruleValue: ruleValue, value: value, fieldLabel: field.label) {
                    return error
                }
            }
        }
        
        return nil
    }
    
    private func validateRule(ruleKey: String, ruleValue: String, value: String, fieldLabel: String) -> String? {
        guard let ruleType = ValidationRuleType(rawValue: ruleKey) else {
            // Unknown validation rule - log for debugging but don't crash
            print("Warning: Unknown validation rule '\(ruleKey)' for field '\(fieldLabel)'")
            return nil
        }
        
        switch ruleType {
        case .required:
            return value.isEmpty ? "\(fieldLabel) is required" : nil
        case .email:
            let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            return !matchesPattern(value, pattern: emailRegex) ? "\(fieldLabel) must be a valid email" : nil
        case .phone:
            let phoneRegex = "^[+]?[0-9\\s\\-\\(\\)]{10,}$"
            return !matchesPattern(value, pattern: phoneRegex) ? "\(fieldLabel) must be a valid phone number" : nil
        case .url:
            let urlRegex = "^(https?://)?[\\w\\-]+(\\.[\\w\\-]+)+([\\w\\-\\.,@?^=%&:/~\\+#]*[\\w\\-\\@?^=%&/~\\+#])?$"
            return !matchesPattern(value, pattern: urlRegex) ? "\(fieldLabel) must be a valid URL" : nil
        case .minLength:
            if let min = Int(ruleValue), value.count < min {
                return "\(fieldLabel) must be at least \(min) characters"
            }
            return nil
        case .maxLength:
            if let max = Int(ruleValue), value.count > max {
                return "\(fieldLabel) must be less than \(max) characters"
            }
            return nil
        case .min:
            if let min = Double(ruleValue), let num = Double(value), num < min {
                return "\(fieldLabel) must be at least \(min)"
            }
            return nil
        case .max:
            if let max = Double(ruleValue), let num = Double(value), num > max {
                return "\(fieldLabel) must be less than \(max)"
            }
            return nil
        }
    }
    
    private func matchesPattern(_ value: String, pattern: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: value.utf16.count)
        return regex?.firstMatch(in: value, options: [], range: range) != nil
    }
    
    private func clearFieldError(_ field: DynamicFormField) {
        validationErrors.removeValue(forKey: field.id)
    }
    
    @ViewBuilder
    @MainActor
    private func createFieldView(for field: DynamicFormField) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            // Field label with required indicator
            HStack {
                Text(field.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if field.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            }
            
            // Field input based on type
            Group {
                if let textContentType = field.textContentType {
                    // Handle text fields using OS UITextContentType
                    TextField(field.placeholder ?? "Enter text", text: .constant(field.defaultValue ?? ""))
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                } else if let contentType = field.contentType {
                    // Handle UI components using our custom DynamicContentType
                    switch contentType {
                case .text:
                    TextField(field.placeholder ?? "Enter text", text: .constant(field.defaultValue ?? ""))
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                        .onChange(of: field.defaultValue) { _ in
                            clearFieldError(field)
                        }
                        
                case .email:
                    TextField(field.placeholder ?? "Enter email", text: field.$value)
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                        
                case .password:
                    SecureField(field.placeholder ?? "Enter password", text: field.$value)
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "SecureField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                        
                case .number:
                    TextField(field.placeholder ?? "Enter number", text: field.$value)
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                        
                case .date:
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { DateFormatter.iso8601.date(from: field.value) ?? Date() },
                            set: { field.value = DateFormatter.iso8601.string(from: $0) }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    let i18nDate = InternationalizationService()
                    .selfLabelingControl(label: field.placeholder ?? i18nDate.placeholderSelectDate())
                    .automaticCompliance(
                        identifierElementType: "DatePicker",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    
                case .select:
                    let i18nSelect = InternationalizationService()
                    Picker(field.placeholder ?? i18nSelect.placeholderSelectOption(), selection: field.$value) {
                        Text(i18nSelect.placeholderSelectOption()).tag("")
                        ForEach(field.options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .automaticCompliance(
                        identifierElementType: "Picker",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    
                case .textarea:
                    TextEditor(text: field.$value)
                        .frame(minHeight: 80)
                        .automaticCompliance(
                            identifierElementType: "TextEditor",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                        
                case .checkbox:
                    Toggle(field.placeholder ?? "Toggle", isOn: Binding(
                        get: { field.value.lowercased() == "true" },
                        set: { field.value = $0 ? "true" : "false" }
                    ))
                    .automaticCompliance(
                        identifierElementType: "Toggle",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    
                case .radio:
                    platformVStackContainer(alignment: .leading, spacing: 4) {
                        ForEach(field.options, id: \.self) { option in
                            HStack {
                                Button(action: {
                                    field.value = option
                                    clearFieldError(field)
                                }) {
                                    HStack {
                                        Image(systemName: field.value == option ? "largecircle.fill.circle" : "circle")
                                            .foregroundColor(.accentColor)
                                        Text(option)
                                    }
                                }
                                .buttonStyle(.plain)
                                .automaticCompliance(
                                    identifierElementType: "Button",
                                    accessibilityLabel: "\(field.label): \(option)"  // Issue #156: Parameter-based approach
                                )
                                Spacer()
                            }
                        }
                    }
                    .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    
                case .phone:
                    TextField(field.placeholder ?? "Enter phone", text: field.$value)
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                        #if os(iOS)
                        .keyboardType(.phonePad)
                        #endif
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                        
                case .time:
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { DateFormatter.timeFormatter.date(from: field.value) ?? Date() },
                            set: { field.value = DateFormatter.timeFormatter.string(from: $0) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    let i18nTime = InternationalizationService()
                    .selfLabelingControl(label: field.placeholder ?? i18nTime.placeholderSelectTime())
                    .automaticCompliance(
                        identifierElementType: "DatePicker",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    
                case .datetime:
                    let i18nDateTime = InternationalizationService()
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { DateFormatter.iso8601.date(from: field.value) ?? Date() },
                            set: { field.value = DateFormatter.iso8601.string(from: $0) }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .selfLabelingControl(label: field.placeholder ?? i18nDateTime.placeholderSelectDateTime())
                    .automaticCompliance(
                        identifierElementType: "DatePicker",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    
                case .multiselect:
                    platformVStackContainer(alignment: .leading, spacing: 4) {
                        ForEach(field.options, id: \.self) { option in
                            HStack {
                                Button(action: {
                                    toggleMultiSelectOption(field, option: option)
                                    clearFieldError(field)
                                }) {
                                    HStack {
                                        Image(systemName: field.value.contains(option) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(.accentColor)
                                        Text(option)
                                    }
                                }
                                .buttonStyle(.plain)
                                .automaticCompliance(
                                    identifierElementType: "Button",
                                    accessibilityLabel: "\(field.label): \(option)"  // Issue #156: Parameter-based approach
                                )
                                Spacer()
                            }
                        }
                    }
                    .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    
                case .file:
                    Button(action: {
                        // File picker implementation would go here
                        field.value = "File selected"
                    }) {
                        HStack {
                            Image(systemName: "paperclip")
                            let i18n = InternationalizationService()
                            Text(field.value.isEmpty ? i18n.placeholderSelectFile() : field.value)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                    
                case .url:
                    TextField(field.placeholder ?? "Enter URL", text: field.$value)
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                            identifierElementType: "TextField",
                            accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                        )
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                        
                case .color:
                    let i18n = InternationalizationService()
                    ColorPicker(field.placeholder ?? i18n.placeholderSelectColor(), selection: Binding(
                        get: { Color(hex: field.value) ?? .blue },
                        set: { field.value = $0.toHex() }
                    ))
                    
                case .range:
                    VStack {
                        Slider(
                            value: Binding(
                                get: { Double(field.value) ?? 0.0 },
                                set: { field.value = String($0) }
                            ),
                            in: 0...100
                        )
                        Text("Value: \(field.value)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                case .toggle, .boolean:
                    Toggle(field.placeholder ?? "Toggle", isOn: Binding(
                        get: { field.value.lowercased() == "true" },
                        set: { field.value = $0 ? "true" : "false" }
                    ))
                    
                case .richtext:
                    TextEditor(text: field.$value)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                        
                case .autocomplete:
                    TextField(field.placeholder ?? "Type to search", text: field.$value)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                    
                case .integer:
                    TextField(field.placeholder ?? "Enter integer", text: field.$value)
                        .textFieldStyle(.roundedBorder)
                        .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                case .image:
                    Text("Image field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                case .array:
                    Text("Array field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                case .data:
                    Text("Data field: \(field.label)")
                        .foregroundColor(.secondary)
                        .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                case .`enum`:
                    let i18n = InternationalizationService()
                    Picker(field.placeholder ?? i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectOption"), selection: field.$value) {
                        Text(i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectOption")).tag("")
                        ForEach(field.options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .automaticCompliance(
                        identifierElementType: "View",
                        accessibilityLabel: field.label  // Issue #156: Parameter-based approach
                    )
                case .custom:
                    TextField(field.placeholder ?? "Custom field", text: field.$value)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: field.value) { _ in
                            clearFieldError(field)
                        }
                }
            }
            
            // Error message display
            if let error = validationErrors[field.id.uuidString] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .automaticCompliance()
    }
    
    // MARK: - Helper Methods
    
    private func toggleMultiSelectOption(_ field: DynamicFormField, option: String) {
        // TODO: Implement when DynamicFormState is available
        // This function needs to work with the centralized state management
    }
}
*/

// MARK: - Helper Functions

/// Create appropriate form fields based on the form type and context
private func createFieldsForFormType(_ formType: DataTypeHint, context: PresentationContext) -> [DynamicFormField] {
    switch formType {
    case .form:
        // DEPRECATED: GenericFormField is deprecated
        // return createGenericFormFields(context: context)
        return [] // TODO: Replace with createDynamicFormFields(context: context)
    case .text:
        return [
            DynamicFormField(id: "textContent", contentType: .textarea, label: "Text Content", placeholder: "Enter text content")
        ]
    case .number:
        return [
            DynamicFormField(id: "numericValue", contentType: .number, label: "Numeric Value", placeholder: "Enter number")
        ]
    case .date:
        let i18n = InternationalizationService()
        return [
            DynamicFormField(id: "date", contentType: .date, label: "Date", placeholder: i18n.placeholderSelectDate())
        ]
    case .boolean:
        return [
            DynamicFormField(id: "booleanValue", contentType: .toggle, label: "Boolean Value", placeholder: "Toggle value")
        ]
    case .collection:
        return [
            DynamicFormField(id: "collectionName", contentType: .textarea, label: "Collection Name", placeholder: "Enter collection name"),
            DynamicFormField(id: "itemCount", contentType: .number, label: "Item Count", placeholder: "Enter item count")
        ]
    case .hierarchical:
        return [
            DynamicFormField(id: "rootName", contentType: .textarea, label: "Root Name", placeholder: "Enter root name"),
            DynamicFormField(id: "levelCount", contentType: .number, label: "Level Count", placeholder: "Enter hierarchy levels")
        ]
    case .temporal:
        let i18n = InternationalizationService()
        return [
            DynamicFormField(id: "startDate", contentType: .date, label: "Start Date", placeholder: i18n.placeholderSelectStartDate()),
            DynamicFormField(id: "startTime", contentType: .time, label: "Start Time", placeholder: i18n.placeholderSelectStartTime()),
            DynamicFormField(id: "endDate", contentType: .date, label: "End Date", placeholder: i18n.placeholderSelectEndDate()),
            DynamicFormField(id: "endTime", contentType: .time, label: "End Time", placeholder: i18n.placeholderSelectEndTime())
        ]
    case .media:
        return [
            DynamicFormField(id: "mediaTitle", contentType: .textarea, label: "Media Title", placeholder: "Enter media title"),
            DynamicFormField(id: "mediaFile", contentType: .file, label: "Media File", placeholder: "Upload media file"),
            DynamicFormField(id: "mediaType", contentType: .textarea, label: "Media Type", placeholder: "Enter media type")
        ]
    default:
        // DEPRECATED: GenericFormField is deprecated
        // return createGenericFormFields(context: context)
        return [] // TODO: Replace with createDynamicFormFields(context: context)
    }
}

/// Create generic form fields based on context
/// DEPRECATED: This function is commented out as GenericFormField is deprecated.
/// Use createDynamicFormFields(context:) instead.
/*
private func createGenericFormFields(context: PresentationContext) -> [GenericFormField] {
    switch context {
    case .dashboard:
        return [
            GenericFormField(label: "Dashboard Name", placeholder: "Enter dashboard name", value: .constant(""), fieldType: .text),
            GenericFormField(label: "Auto Refresh", placeholder: "Enable auto refresh", value: .constant(""), fieldType: .checkbox)
        ]
    case .detail:
        return [
            GenericFormField(label: "Title", placeholder: "Enter title", value: .constant(""), fieldType: .text),
            GenericFormField(label: "Description", placeholder: "Enter description", value: .constant(""), fieldType: .richtext),
            let i18n = InternationalizationService()
            GenericFormField(label: "Created Date", placeholder: i18n.placeholderSelectCreationDate(), value: .constant(""), fieldType: .date),
            GenericFormField(label: "Created Time", placeholder: i18n.placeholderSelectCreationTime(), value: .constant(""), fieldType: .time),
            GenericFormField(label: "Attachments", placeholder: "Upload attachments", value: .constant(""), fieldType: .file)
        ]
    case .form:
        return [
            GenericFormField(label: "Name", placeholder: "Enter name", value: .constant(""), fieldType: .text),
            GenericFormField(label: "Email", placeholder: "Enter email", value: .constant(""), fieldType: .email),
            GenericFormField(label: "Age", placeholder: "Enter age", value: .constant(""), fieldType: .number),
            GenericFormField(label: "Birth Date", placeholder: i18n.placeholderSelectBirthDate(), value: .constant(""), fieldType: .date),
            GenericFormField(label: "Country", placeholder: i18n.placeholderSelectCountry(), value: .constant(""), fieldType: .autocomplete),
            GenericFormField(label: "Bio", placeholder: "Enter bio", value: .constant(""), fieldType: .richtext),
            GenericFormField(label: "Profile Photo", placeholder: "Upload profile photo", value: .constant(""), fieldType: .file),
            GenericFormField(label: "Subscribe", placeholder: "Subscribe to updates", value: .constant(""), fieldType: .checkbox)
        ]
    case .list:
        return [
            GenericFormField(label: "List Name", placeholder: "Enter list name", value: .constant(""), fieldType: .text),
            GenericFormField(label: "Sort Order", placeholder: "Enter sort order", value: .constant(""), fieldType: .text)
        ]
    case .modal:
        return [
            GenericFormField(label: "Modal Title", placeholder: "Enter modal title", value: .constant(""), fieldType: .text),
            GenericFormField(label: "Modal Content", placeholder: "Enter modal content", value: .constant(""), fieldType: .textarea)
        ]
    default:
        return [
            GenericFormField(label: "Title", placeholder: "Enter title", value: .constant(""), fieldType: .text),
            GenericFormField(label: "Value", placeholder: "Enter value", value: .constant(""), fieldType: .text)
        ]
    }
}
*/

// MARK: - Dynamic Form Field Creation

/// Create dynamic form fields based on context
/// This replaces the deprecated createGenericFormFields function
public func createDynamicFormFields(context: PresentationContext) -> [DynamicFormField] {
    switch context {
    case .dashboard:
        return [
            DynamicFormField(
                id: "dashboard_name",
                contentType: .text,
                label: "Dashboard Name",
                placeholder: "Enter dashboard name"
            ),
            DynamicFormField(
                id: "auto_refresh",
                contentType: .toggle,
                label: "Auto Refresh",
                placeholder: "Enable auto refresh"
            )
        ]
    case .detail:
        return [
            DynamicFormField(
                id: "title",
                contentType: .text,
                label: "Title",
                placeholder: "Enter title"
            ),
            DynamicFormField(
                id: "description",
                contentType: .richtext,
                label: "Description",
                placeholder: "Enter description"
            ),
            DynamicFormField(
                id: "created_date",
                contentType: .date,
                label: "Created Date",
                placeholder: "Select creation date"
            ),
            DynamicFormField(
                id: "created_time",
                contentType: .time,
                label: "Created Time",
                placeholder: "Select creation time"
            ),
            DynamicFormField(
                id: "attachments",
                contentType: .file,
                label: "Attachments",
                placeholder: "Upload attachments"
            )
        ]
    case .form:
        let i18n = InternationalizationService()
        return [
            DynamicFormField(
                id: "name",
                contentType: .text,
                label: "Name",
                placeholder: "Enter name"
            ),
            DynamicFormField(
                id: "email",
                contentType: .email,
                label: "Email",
                placeholder: "Enter email"
            ),
            DynamicFormField(
                id: "age",
                contentType: .number,
                label: "Age",
                placeholder: "Enter age"
            ),
            DynamicFormField(
                id: "birth_date",
                contentType: .date,
                label: "Birth Date",
                placeholder: i18n.placeholderSelectBirthDate()
            ),
            DynamicFormField(
                id: "country",
                contentType: .autocomplete,
                label: "Country",
                placeholder: i18n.placeholderSelectCountry()
            ),
            DynamicFormField(
                id: "bio",
                contentType: .richtext,
                label: "Bio",
                placeholder: "Enter bio"
            ),
            DynamicFormField(
                id: "profile_photo",
                contentType: .file,
                label: "Profile Photo",
                placeholder: "Upload profile photo"
            ),
            DynamicFormField(
                id: "subscribe",
                contentType: .toggle,
                label: "Subscribe",
                placeholder: "Subscribe to updates"
            )
        ]
    case .list:
        return [
            DynamicFormField(
                id: "list_name",
                contentType: .text,
                label: "List Name",
                placeholder: "Enter list name"
            ),
            DynamicFormField(
                id: "sort_order",
                contentType: .text,
                label: "Sort Order",
                placeholder: "Enter sort order"
            )
        ]
    case .modal:
        return [
            DynamicFormField(
                id: "modal_title",
                contentType: .text,
                label: "Modal Title",
                placeholder: "Enter modal title"
            ),
            DynamicFormField(
                id: "modal_content",
                contentType: .textarea,
                label: "Modal Content",
                placeholder: "Enter modal content"
            )
        ]
    case .browse:
        return [
            DynamicFormField(
                id: "search_query",
                contentType: .text,
                label: "Search",
                placeholder: "Enter search query"
            ),
            DynamicFormField(
                id: "filter_category",
                contentType: .select,
                label: "Category",
                placeholder: "Select category", // TODO: Localize - needs i18n in case scope
                options: ["All", "Recent", "Favorites"]
            )
        ]
    case .edit:
        let i18n = InternationalizationService()
        return [
            DynamicFormField(
                id: "edit_title",
                contentType: .text,
                label: "Title",
                placeholder: "Enter title"
            ),
            DynamicFormField(
                id: "edit_content",
                contentType: .richtext,
                label: "Content",
                placeholder: "Enter content"
            ),
            DynamicFormField(
                id: "save_changes",
                contentType: .toggle,
                label: i18n.localizedString(for: "SixLayerFramework.button.saveChanges"),
                placeholder: i18n.localizedString(for: "SixLayerFramework.form.autoSaveChanges")
            )
        ]
    case .create:
        let i18n = InternationalizationService()
        return [
            DynamicFormField(
                id: "create_name",
                contentType: .text,
                label: "Name",
                placeholder: "Enter name",
                isRequired: true
            ),
            DynamicFormField(
                id: "create_type",
                contentType: .select,
                label: "Type",
                placeholder: i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectType"),
                options: ["Document", "Image", "Video", "Audio"]
            )
        ]
    case .search:
        let i18n = InternationalizationService()
        return [
            DynamicFormField(
                id: "search_term",
                contentType: .text,
                label: "Search Term",
                placeholder: "Enter search term"
            ),
            DynamicFormField(
                id: "search_filters",
                contentType: .multiselect,
                label: "Filters",
                placeholder: i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectFilters"),
                options: ["Date", "Type", "Size", "Author"]
            )
        ]
    case .settings:
        let i18n = InternationalizationService()
        return [
            DynamicFormField(
                id: "theme",
                contentType: .select,
                label: "Theme",
                placeholder: i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectTheme"),
                options: ["Light", "Dark", "Auto"]
            ),
            DynamicFormField(
                id: "notifications",
                contentType: .toggle,
                label: "Notifications",
                placeholder: "Enable notifications"
            )
        ]
    case .profile:
        return [
            DynamicFormField(
                id: "display_name",
                contentType: .text,
                label: "Display Name",
                placeholder: "Enter display name"
            ),
            DynamicFormField(
                id: "bio",
                contentType: .textarea,
                label: "Bio",
                placeholder: "Enter bio"
            ),
            DynamicFormField(
                id: "avatar",
                contentType: .file,
                label: "Avatar",
                placeholder: "Upload avatar"
            )
        ]
    case .summary:
        return [
            DynamicFormField(
                id: "summary_title",
                contentType: .text,
                label: "Title",
                placeholder: "Enter summary title"
            ),
            DynamicFormField(
                id: "summary_content",
                contentType: .textarea,
                label: "Summary",
                placeholder: "Enter summary"
            )
        ]
    case .standard:
        return [
            DynamicFormField(
                id: "title",
                contentType: .text,
                label: "Title",
                placeholder: "Enter title"
            ),
            DynamicFormField(
                id: "value",
                contentType: .text,
                label: "Value",
                placeholder: "Enter value"
            )
        ]
    case .navigation:
        let i18n = InternationalizationService()
        return [
            DynamicFormField(
                id: "destination",
                contentType: .text,
                label: "Destination",
                placeholder: "Enter destination"
            ),
            DynamicFormField(
                id: "route_type",
                contentType: .select,
                label: "Route Type",
                placeholder: i18n.localizedString(for: "SixLayerFramework.form.placeholder.selectRouteType"),
                options: ["Fastest", "Shortest", "Scenic"]
            )
        ]
    case .gallery:
        return [
            DynamicFormField(
                id: "gallery_title",
                contentType: .text,
                label: "Gallery Title",
                placeholder: "Enter gallery title"
            ),
            DynamicFormField(
                id: "gallery_description",
                contentType: .textarea,
                label: "Description",
                placeholder: "Enter gallery description"
            )
        ]
    }
}

// MARK: - Platform Strategy Selection (Layer 3 Integration)

/// Select platform strategy based on hints
/// This delegates to Layer 3 for platform-specific strategy selection
private func selectPlatformStrategy(for hints: PresentationHints) -> String {
    // This is a placeholder that will be implemented in Layer 3
    return "platform_strategy_selected"
}

// MARK: - Enhanced Hints Processing

/// Process extensible hints and merge their custom data into basic hints
private func processExtensibleHints(
    _ enhancedHints: EnhancedPresentationHints,
    into basicHints: PresentationHints
) -> PresentationHints {
    // Merge custom data from extensible hints into custom preferences
    var mergedPreferences = basicHints.customPreferences
    
    // Add custom data from all extensible hints (higher priority hints override lower ones)
    let sortedHints = enhancedHints.extensibleHints.sorted { $0.priority > $1.priority }
    for hint in sortedHints {
        for (key, value) in hint.customData {
            // Convert Any to String for customPreferences
            if let stringValue = value as? String {
                mergedPreferences[key] = stringValue
            } else if let boolValue = value as? Bool {
                mergedPreferences[key] = String(boolValue)
            } else if let intValue = value as? Int {
                mergedPreferences[key] = String(intValue)
            } else if let doubleValue = value as? Double {
                mergedPreferences[key] = String(doubleValue)
            } else {
                mergedPreferences[key] = String(describing: value)
            }
        }
    }
    
    // Merge field hints from enhanced hints (enhanced field hints take precedence)
    var mergedFieldHints = basicHints.fieldHints
    for (fieldId, hint) in enhancedHints.fieldHints {
        mergedFieldHints[fieldId] = hint
    }
    
    // Create new hints with merged preferences and field hints
    return PresentationHints(
        dataType: basicHints.dataType,
        presentationPreference: basicHints.presentationPreference,
        complexity: basicHints.complexity,
        context: basicHints.context,
        customPreferences: mergedPreferences,
        fieldHints: mergedFieldHints
    )
}

// MARK: - Hints Loading

/// Simple cache for hints to ensure DRY: hints are loaded ONCE and reused everywhere
/// Uses global cache in production, thread-local in test mode
@MainActor
private class HintsCache {
    /// Global cache (shared across all threads for production use)
    private var globalCache: [String: [String: FieldDisplayHints]] = [:]
    
    /// Thread-local storage key for test isolation (only used in test mode)
    private static var testCacheKey: String { "HintsCache.test.\(Thread.current.hash)" }
    
    /// Check if we're in testing mode (for test isolation)
    private static var isTestingMode: Bool {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil ||
               environment["XCTestSessionIdentifier"] != nil ||
               NSClassFromString("XCTestCase") != nil
        #else
        return false
        #endif
    }
    
    /// Get cache - uses thread-local in test mode, global in production
    private func getCache() -> [String: [String: FieldDisplayHints]] {
        if Self.isTestingMode {
            // Test mode: use thread-local for isolation
            if let cached = Thread.current.threadDictionary[Self.testCacheKey] as? [String: [String: FieldDisplayHints]] {
                return cached
            }
            let newCache: [String: [String: FieldDisplayHints]] = [:]
            Thread.current.threadDictionary[Self.testCacheKey] = newCache
            return newCache
        } else {
            // Production mode: use global shared cache
            return globalCache
        }
    }
    
    /// Set cache - uses thread-local in test mode, global in production
    private func setCache(_ cache: [String: [String: FieldDisplayHints]]) {
        if Self.isTestingMode {
            // Test mode: store in thread-local
            Thread.current.threadDictionary[Self.testCacheKey] = cache
        } else {
            // Production mode: store in global
            globalCache = cache
        }
    }
    
    private let loader = FileBasedDataHintsLoader()
    
    func getHints(for modelName: String) -> [String: FieldDisplayHints] {
        var cache = getCache()
        
        // Check cache first
        if let cached = cache[modelName] {
            return cached
        }
        
        // Load from file
        let hints = loader.loadHints(for: modelName)
        
        // Cache for future use
        if !hints.isEmpty {
            cache[modelName] = hints
            setCache(cache)
        }
        
        return hints
    }
}

/// Load hints from a .hints file for a data model
/// Cached to ensure DRY: hints are loaded ONCE and reused everywhere
/// Define hints once in .hints file, use everywhere
/// Uses global cache in production, thread-local cache in test mode (prevents state leakage)
@MainActor
private func loadHintsFromFile(for modelName: String) -> [String: FieldDisplayHints] {
    return HintsCache().getHints(for: modelName)
}

// MARK: - Environment Keys

/// Environment key for passing extensible hints to child views
public struct ExtensibleHintsKey: EnvironmentKey {
    public static let defaultValue: [ExtensibleHint] = []
}

public extension EnvironmentValues {
    var extensibleHints: [ExtensibleHint] {
        get { self[ExtensibleHintsKey.self] }
        set { self[ExtensibleHintsKey.self] = newValue }
    }
}

// MARK: - Generic Content View

/// Generic content view for runtime-unknown content types
/// 
/// **Use Case**: Only for cases where content type is unknown at compile time.
/// This view analyzes content type at runtime and delegates to appropriate
/// specific functions, with a fallback for truly unknown content types.
public struct GenericContentView: View {
    let content: Any
    let hints: PresentationHints
    
    public var body: some View {
        // Analyze content type and delegate to appropriate function
        
        if let formFields = content as? [DynamicFormField] {
            // Delegate to form function
            return AnyView(platformPresentFormData_L1(fields: formFields, hints: EnhancedPresentationHints(
                dataType: hints.dataType,
                presentationPreference: hints.presentationPreference,
                complexity: hints.complexity,
                context: hints.context,
                customPreferences: hints.customPreferences,
                extensibleHints: []
            )))
        } else if let mediaItems = content as? [GenericMediaItem] {
            // Delegate to media function
            return AnyView(platformPresentMediaData_L1(media: mediaItems, hints: hints))
        } else if let numericData = content as? [GenericNumericData] {
            // Delegate to numeric function
            return AnyView(platformPresentNumericData_L1(data: numericData, hints: hints))
        } else if let hierarchicalItems = content as? [GenericHierarchicalItem] {
            // Delegate to hierarchical function
            return AnyView(platformPresentHierarchicalData_L1(items: hierarchicalItems, hints: hints))
        } else if let temporalItems = content as? [GenericTemporalItem] {
            // Delegate to temporal function
            return AnyView(platformPresentTemporalData_L1(items: temporalItems, hints: hints))
        } else if isIdentifiableArray(content) {
            // Handle any identifiable array by converting to GenericDataItem
            let items = convertToGenericDataItems(content)
            return AnyView(platformPresentItemCollection_L1(items: items, hints: hints))
        } else if isBasicNumericType(content) {
            // Handle basic numeric types with dedicated function
            return AnyView(platformPresentBasicValue_L1(value: content, hints: hints))
        } else if isBasicArray(content) {
            // Handle basic arrays with dedicated function
            return AnyView(platformPresentBasicArray_L1(array: content, hints: hints))
        } else if content is String {
            // Handle String content with dedicated function
            return AnyView(platformPresentBasicValue_L1(value: content, hints: hints))
        } else {
            // Fallback to generic presentation for truly unknown types
            return AnyView(GenericFallbackView(content: content, hints: hints)
                .automaticCompliance(named: "GenericContentView"))
        }
    }
    
    /// Check if content is an array of identifiable items
    private func isIdentifiableArray(_ content: Any) -> Bool {
        // Check if it's an array and if the first element conforms to Identifiable
        if let array = content as? [Any], !array.isEmpty {
            return array.first is any Identifiable
        }
        return false
    }
    
    /// Check if content is a basic numeric type
    private func isBasicNumericType(_ content: Any) -> Bool {
        let result = content is Int || content is Float || content is Double || content is Bool
        return result
    }
    
    /// Check if content is a basic array
    private func isBasicArray(_ content: Any) -> Bool {
        return content is [Any] && !isIdentifiableArray(content)
    }
    
    /// Convert any identifiable array to GenericDataItem array
    private func convertToGenericDataItems(_ content: Any) -> [GenericDataItem] {
        guard let array = content as? [Any] else { return [] }
        
        return array.compactMap { item in
            if let identifiable = item as? any Identifiable {
                // Try to extract title and subtitle from common properties
                let mirror = Mirror(reflecting: identifiable)
                var title = "Item"
                var subtitle: String? = nil
                var data: [String: Any] = [:]
                
                for child in mirror.children {
                    if let label = child.label {
                        data[label] = child.value
                        
                        // Common property mappings using enum-based approach
                        if PropertyLabel.isTitleLabel(label) {
                            if let stringValue = child.value as? String {
                                title = stringValue
                            }
                        } else if PropertyLabel.isDescriptionLabel(label) {
                            if let stringValue = child.value as? String {
                                subtitle = stringValue
                            }
                        }
                    }
                }
                
                return GenericDataItem(title: title, subtitle: subtitle, data: data)
            }
            return nil
        }
    }
}

/// View for presenting basic numeric values
private struct BasicValueView: View {
    let value: Any
    let hints: PresentationHints
    
    var body: some View {
        VStack {
            Image(systemName: "number")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Value")
                .font(.headline)
            
            if let intValue = value as? Int {
                Text("\(intValue)")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            } else if let floatValue = value as? Float {
                Text("\(floatValue)")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            } else if let doubleValue = value as? Double {
                Text("\(doubleValue)")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            } else if let boolValue = value as? Bool {
                Text(boolValue ? "True" : "False")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(boolValue ? .green : .red)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .automaticCompliance(named: "BasicValueView")
    }
}

/// View for presenting basic arrays
private struct BasicArrayView: View {
    let array: Any
    let hints: PresentationHints
    
    var body: some View {
        platformVStackContainer(alignment: .leading) {
            Image(systemName: "list.bullet")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Array")
                .font(.headline)
            
            if let arrayContent = array as? [Any] {
                Text("\(arrayContent.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if arrayContent.isEmpty {
                    Text("Empty array")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(0..<min(arrayContent.count, 5), id: \.self) { index in
                        HStack {
                            Text("[\(index)]:")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("\(String(describing: arrayContent[index]))")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if arrayContent.count > 5 {
                        Text("... and \(arrayContent.count - 5) more items")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .automaticCompliance(named: "BasicArrayView")
    }
}

/// Fallback view for unknown content types
private struct GenericFallbackView: View {
    let content: Any
    let hints: PresentationHints
    
    var body: some View {
        VStack {
            Image(systemName: "questionmark.circle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Unknown Content")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Type: \(String(describing: type(of: content)))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Show basic introspection for debugging
            if let stringContent = content as? String {
                Text("String: \(stringContent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let dictContent = content as? [String: Any] {
                Text("Dictionary with \(dictContent.count) keys")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Value: \(String(describing: content))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .automaticCompliance(named: "GenericFallbackView")
    }
}

// MARK: - Supporting Extensions

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    func toHex() -> String {
        #if os(iOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
        #else
        return "#000000"
        #endif
    }
}

// MARK: - Settings Data Structures

/// Data structure representing a settings section
public struct SettingsSectionData: Identifiable {
    public let id = UUID()
    public let title: String
    public let items: [SettingsItemData]
    public let isCollapsible: Bool
    public let isExpanded: Bool
    
    public init(
        title: String,
        items: [SettingsItemData],
        isCollapsible: Bool = false,
        isExpanded: Bool = true
    ) {
        self.title = title
        self.items = items
        self.isCollapsible = isCollapsible
        self.isExpanded = isExpanded
    }
}

/// Data structure representing a settings item
public struct SettingsItemData: Identifiable {
    public let id = UUID()
    public let key: String
    public let title: String
    public let description: String?
    public let type: SettingsItemType
    public let value: Any?
    public let options: [String]?
    public let isEnabled: Bool
    
    public init(
        key: String,
        title: String,
        description: String? = nil,
        type: SettingsItemType,
        value: Any? = nil,
        options: [String]? = nil,
        isEnabled: Bool = true
    ) {
        self.key = key
        self.title = title
        self.description = description
        self.type = type
        self.value = value
        self.options = options
        self.isEnabled = isEnabled
    }
}

/// Types of settings items
public enum SettingsItemType: String, CaseIterable {
    case toggle = "toggle"
    case text = "text"
    case number = "number"
    case select = "select"
    case slider = "slider"
    case color = "color"
    case button = "button"
    case info = "info"
}

// MARK: - Generic Settings View

/// Generic settings view that adapts to platform and hints
public struct GenericSettingsView: View {
    let settings: [SettingsSectionData]
    let hints: PresentationHints
    let onSettingChanged: ((String, Any) -> Void)?
    let onSettingsSaved: (() -> Void)?
    let onSettingsCancelled: (() -> Void)?
    
    @State private var values: [String: Any] = [:]
    @State private var sectionStates: [String: Bool] = [:]
    
    public init(
        settings: [SettingsSectionData],
        hints: PresentationHints,
        onSettingChanged: ((String, Any) -> Void)? = nil,
        onSettingsSaved: (() -> Void)? = nil,
        onSettingsCancelled: (() -> Void)? = nil
    ) {
        self.settings = settings
        self.hints = hints
        self.onSettingChanged = onSettingChanged
        self.onSettingsSaved = onSettingsSaved
        self.onSettingsCancelled = onSettingsCancelled
    }
    
    public var body: some View {
        platformVStackContainer(spacing: 0) {
            // Settings content
            ScrollView {
                platformLazyVStackContainer(spacing: 16) {
                    ForEach(settings) { section in
                        SettingsSectionView(
                            section: section,
                            values: $values,
                            sectionStates: $sectionStates,
                            onSettingChanged: onSettingChanged
                        )
                    }
                }
                .padding()
            }
            
            // Action buttons
            if onSettingsSaved != nil || onSettingsCancelled != nil {
                platformHStackContainer(spacing: 16) {
                    if let onSettingsCancelled = onSettingsCancelled {
                        Button("Cancel") {
                            onSettingsCancelled()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if let onSettingsSaved = onSettingsSaved {
                        Button("Save") {
                            onSettingsSaved()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color.platformBackground)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            initializeValues()
        }
        .automaticCompliance(named: "GenericSettingsView")
    }
    
    private func initializeValues() {
        for section in settings {
            for item in section.items {
                if values[item.key] == nil {
                    values[item.key] = item.value
                }
            }
            sectionStates[section.id.uuidString] = section.isExpanded
        }
    }
}

/// Individual settings section view
struct SettingsSectionView: View {
    let section: SettingsSectionData
    @Binding var values: [String: Any]
    @Binding var sectionStates: [String: Bool]
    let onSettingChanged: ((String, Any) -> Void)?
    
    private var isExpanded: Bool {
        sectionStates[section.id.uuidString] ?? section.isExpanded
    }
    
    var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(section.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if section.isCollapsible {
                    Button(action: {
                        sectionStates[section.id.uuidString]?.toggle()
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Section items
            if isExpanded {
                platformVStackContainer(spacing: 8) {
                    ForEach(section.items) { item in
                        GenericSettingsItemView(
                            item: item,
                            value: Binding(
                                get: { values[item.key] },
                                set: { newValue in
                                    values[item.key] = newValue
                                    onSettingChanged?(item.key, newValue as Any)
                                }
                            )
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
    }
}

/// Individual settings item view
struct GenericSettingsItemView: View {
    let item: SettingsItemData
    @Binding var value: Any?
    
    var body: some View {
        platformHStackContainer {
            platformVStackContainer(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if let description = item.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Item-specific controls
            switch item.type {
            case .toggle:
                Toggle("", isOn: Binding(
                    get: { value as? Bool ?? false },
                    set: { value = $0 }
                ))
                .disabled(!item.isEnabled)
                
            case .text:
                TextField("", text: Binding(
                    get: { value as? String ?? "" },
                    set: { value = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)
                .disabled(!item.isEnabled)
                
            case .number:
                TextField("", value: Binding(
                    get: { value as? Double },
                    set: { value = $0 }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 100)
                .disabled(!item.isEnabled)
                
            case .select:
                if let options = item.options {
                    Picker("", selection: Binding(
                        get: { value as? String ?? options.first ?? "" },
                        set: { value = $0 }
                    )) {
                        ForEach(options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!item.isEnabled)
                }
                
            case .slider:
                if let doubleValue = value as? Double {
                    Slider(value: Binding(
                        get: { doubleValue },
                        set: { value = $0 }
                    ), in: 0...100)
                    .disabled(!item.isEnabled)
                }
                
            case .color:
                if let colorValue = value as? Color {
                    ColorPicker("", selection: Binding(
                        get: { colorValue },
                        set: { value = $0 }
                    ))
                    .disabled(!item.isEnabled)
                }
                
            case .button:
                Button(item.title) {
                    // Button action would be handled by onSettingChanged
                    // TODO: Implement when onSettingChanged is available in scope
                }
                .disabled(!item.isEnabled)
                
            case .info:
                Text(value as? String ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Custom Collection View Components

/// Custom grid collection view that uses custom item views
public struct CustomGridCollectionView<Item: Identifiable>: View {
    let items: [Item]
    let hints: PresentationHints
    let customItemView: (Item) -> AnyView
    let onItemSelected: ((Item) -> Void)?
    let onItemDeleted: ((Item) -> Void)?
    let onItemEdited: ((Item) -> Void)?
    
    public var body: some View {
        GeometryReader { geometry in
            let context = LayoutContext.from(viewportWidth: geometry.size.width)
            let columns = LayoutParameterCalculator.calculateColumns(
                count: items.count,
                dataType: hints.dataType,
                context: context
            )
            let spacing = LayoutParameterCalculator.calculateSpacing(
                context: context,
                dataType: hints.dataType
            )
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
            
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    ForEach(items) { item in
                        customItemView(item)
                            .onTapGesture {
                                onItemSelected?(item)
                            }
                    }
                }
                .padding(16)
            }
        }
    }
}

/// Custom list collection view that uses custom item views
public struct CustomListCollectionView<Item: Identifiable>: View {
    let items: [Item]
    let hints: PresentationHints
    let customItemView: (Item) -> AnyView
    let onItemSelected: ((Item) -> Void)?
    let onItemDeleted: ((Item) -> Void)?
    let onItemEdited: ((Item) -> Void)?
    
    public var body: some View {
        ScrollView {
            platformLazyVStackContainer(spacing: 12) {
                ForEach(items) { item in
                    customItemView(item)
                        .onTapGesture {
                            onItemSelected?(item)
                        }
                }
            }
            .padding(16)
        }
    }
}


// MARK: - Additional Custom View Components

/// Custom settings view that supports custom setting views
public struct CustomSettingsView: View {
    let settings: [SettingsSectionData]
    let hints: PresentationHints
    let onSettingChanged: ((String, Any) -> Void)?
    let onSettingsSaved: (() -> Void)?
    let onSettingsCancelled: (() -> Void)?
    let customSettingView: (SettingsSectionData) -> AnyView
    
    public var body: some View {
        ScrollView {
            platformLazyVStackContainer(spacing: 16) {
                ForEach(settings, id: \.title) { setting in
                    customSettingView(setting)
                }
            }
            .padding(16)
        }
        .background(Color.platformBackground)
    }
}

/// Custom media view that supports custom media item views
public struct CustomMediaView: View {
    let media: [GenericMediaItem]
    let hints: PresentationHints
    let customMediaView: (GenericMediaItem) -> AnyView
    
    public var body: some View {
        GeometryReader { geometry in
            let context = LayoutContext.from(viewportWidth: geometry.size.width)
            let columns = LayoutParameterCalculator.calculateColumns(
                count: media.count,
                dataType: .media,
                context: context
            )
            let spacing = LayoutParameterCalculator.calculateSpacing(
                context: context,
                dataType: .media
            )
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
            
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    ForEach(media, id: \.id) { mediaItem in
                        customMediaView(mediaItem)
                    }
                }
                .padding(16)
            }
        }
    }
}

/// Custom hierarchical view that supports custom hierarchical item views
public struct CustomHierarchicalView: View {
    let items: [GenericHierarchicalItem]
    let hints: PresentationHints
    let customItemView: (GenericHierarchicalItem) -> AnyView
    
    public var body: some View {
        ScrollView {
            platformLazyVStackContainer(spacing: 8) {
                ForEach(items, id: \.id) { item in
                    customItemView(item)
                }
            }
            .padding(16)
        }
        .background(Color.platformBackground)
    }
}

/// Custom temporal view that supports custom temporal item views
public struct CustomTemporalView: View {
    let items: [GenericTemporalItem]
    let hints: PresentationHints
    let customItemView: (GenericTemporalItem) -> AnyView
    
    public var body: some View {
        ScrollView {
            platformLazyVStackContainer(spacing: 12) {
                ForEach(items, id: \.id) { item in
                    customItemView(item)
                }
            }
            .padding(16)
        }
        .background(Color.platformBackground)
    }
}

/// Custom numeric data view that supports custom numeric data item views
public struct CustomNumericDataView: View {
    let data: [GenericNumericData]
    let hints: PresentationHints
    let customDataView: (GenericNumericData) -> AnyView
    
    public var body: some View {
        GeometryReader { geometry in
            let columns = determineColumns(for: geometry.size.width)
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
            
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(data, id: \.id) { dataItem in
                        customDataView(dataItem)
                    }
                }
                .padding(16)
            }
        }
    }
    
    private func determineColumns(for width: CGFloat) -> Int {
        let minItemWidth: CGFloat = 200
        let maxColumns = Int(width / minItemWidth)
        return max(1, min(maxColumns, 4))
    }
}

// MARK: - Navigation Stack Wrapper Views

// MARK: - Helper Types for Navigation Stack

/// Dummy identifiable type for empty content navigation decisions
private struct EmptyNavigationItem: Identifiable {
    let id = UUID()
}

/// Internal wrapper view for navigation stack content
/// This view implements the full 6-layer flow: L1 -> L2 -> L3 -> L4
private struct NavigationStackWrapper<Content: View>: View {
    let content: Content
    let title: String?
    let hints: PresentationHints
    
    var body: some View {
        // Layer 2: Content-aware decision making
        // Use empty array with explicit type for simple content wrapper
        let emptyItems: [EmptyNavigationItem] = []
        let l2Decision = determineNavigationStackStrategy_L2(
            items: emptyItems,
            hints: hints
        )
        
        // Layer 3: Platform-aware strategy selection
        let l3Strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: SixLayerPlatform.current
        )
        
        // Layer 4: Component implementation
        platformImplementNavigationStack_L4(
            content: content,
            title: title,
            strategy: l3Strategy
        )
    }
}

/// Internal wrapper view for navigation stack with items
/// This view implements the full 6-layer flow: L1 -> L2 -> L3 -> L4
private struct NavigationStackItemsWrapper<Item: Identifiable & Hashable>: View {
    let items: [Item]
    let hints: PresentationHints
    let itemView: (Item) -> AnyView
    let destination: (Item) -> AnyView
    
    @State private var selectedItem: Item?
    
    var body: some View {
        // Layer 2: Content-aware decision making
        let l2Decision = determineNavigationStackStrategy_L2(
            items: items,
            hints: hints
        )
        
        // Layer 3: Platform-aware strategy selection
        let l3Strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: SixLayerPlatform.current
        )
        
        // Layer 4: Component implementation
        platformImplementNavigationStackItems_L4(
            items: items,
            selectedItem: Binding(
                get: { selectedItem },
                set: { selectedItem = $0 }
            ),
            itemView: { item in
                itemView(item)
            },
            detailView: { item in
                destination(item)
            },
            strategy: l3Strategy
        )
    }
}
