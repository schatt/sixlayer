import Foundation
import SwiftUI

// MARK: - Platform UI Examples
// Comprehensive examples showing how to use the platform-specific UI patterns

/// Simple list item for examples
public struct ListItem: Identifiable, Hashable {
    public let id: String
    public let title: String
}

/// Example implementations demonstrating the platform-specific UI patterns
public struct PlatformUIExamples {
    
    // MARK: - Navigation Examples
    
    /// Example of adaptive navigation that works across all platforms
    public struct AdaptiveNavigationExample: View {
        @State private var selectedItem: ListItem? = nil
        @State private var items = [
            ListItem(id: "1", title: "Item 1"),
            ListItem(id: "2", title: "Item 2"),
            ListItem(id: "3", title: "Item 3"),
            ListItem(id: "4", title: "Item 4"),
            ListItem(id: "5", title: "Item 5")
        ]
        
        public init() {}
        
        public var body: some View {
            PlatformUIIntegration.SmartNavigationContainer(
                title: "Adaptive Navigation",
                style: .adaptive,
                context: .standard
            ) {
                AdaptiveUIPatterns.AdaptiveList(
                    items,
                    style: .adaptive,
                    context: .standard
                ) { item in
                    NavigationLink(destination: DetailView(item: item.title)) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text(item.title)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                    }
                }
            }
            .automaticCompliance(named: "AdaptiveNavigationExample")
        }
    }
    
    /// Example of split view navigation for larger screens
    public struct SplitViewNavigationExample: View {
        @State private var selectedItem: ListItem? = nil
        @State private var items = [
            ListItem(id: "1", title: "Item 1"),
            ListItem(id: "2", title: "Item 2"),
            ListItem(id: "3", title: "Item 3"),
            ListItem(id: "4", title: "Item 4"),
            ListItem(id: "5", title: "Item 5")
        ]
        
        public init() {}
        
        public var body: some View {
            PlatformUIIntegration.SmartNavigationContainer(
                title: "Split View Navigation",
                style: .splitView,
                context: .standard
            ) {
                HStack(spacing: 0) {
                    // Sidebar
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Items")
                            .font(.headline)
                            .padding()
                        
                        List(items, id: \.id, selection: $selectedItem) { item in
                            Text(item.title)
                                .tag(item)
                        }
                        .listStyle(SidebarListStyle())
                    }
                    .frame(width: 250)
                    
                    Divider()
                    
                    // Detail view
                    if let selectedItem = selectedItem {
                        DetailView(item: selectedItem.title)
                    } else {
                        VStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Select an item")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .automaticCompliance(named: "SplitViewNavigationExample")
        }
    }
    
    // MARK: - Modal Examples
    
    /// Example of adaptive modal presentation
    public struct AdaptiveModalExample: View {
        @State private var isPresented = false
        
        public init() {}
        
        public var body: some View {
            VStack(spacing: 20) {
                Text("Modal Examples")
                    .font(.title)
                
                AdaptiveUIPatterns.AdaptiveButton(
                    "Show Adaptive Modal",
                    style: ButtonStyle.primary,
                    action: { isPresented = true }
                )
                
                AdaptiveUIPatterns.AdaptiveButton(
                    "Show Sheet Modal",
                    style: ButtonStyle.secondary,
                    action: { isPresented = true }
                )
            }
            .padding()
            .sheet(isPresented: $isPresented) {
                PlatformUIIntegration.SmartModalContainer(
                    title: "Adaptive Modal",
                    isPresented: $isPresented,
                    style: .adaptive
                ) {
                    VStack(spacing: 20) {
                        Text("This is an adaptive modal that adjusts to the platform.")
                            .multilineTextAlignment(.center)
                        
                        Text("On iOS, it shows as a sheet with detents.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("On macOS, it shows in a window with specific dimensions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .automaticCompliance(named: "AdaptiveModalExample")
        }
    }
    
    // MARK: - List Examples
    
    /// Example of adaptive list with different styles
    public struct AdaptiveListExample: View {
        @State private var selectedStyle: ListStyle = .adaptive
        @State private var items = Array(1...20).map { ListItem(id: "\($0)", title: "Item \($0)") }
        
        public init() {}
        
        public var body: some View {
            PlatformUIIntegration.SmartNavigationContainer(
                title: "Adaptive Lists",
                style: .adaptive
            ) {
                VStack(spacing: 0) {
                    // Style picker - use platformPicker for automatic accessibility (Issue #163)
                    let listStyles: [ListStyle] = [.adaptive, .plain, .grouped, .insetGrouped, .sidebar, .carousel]
                    platformPicker(
                        label: "List Style",
                        selection: $selectedStyle,
                        options: listStyles,
                        optionTag: { $0 },
                        optionLabel: { style in
                            switch style {
                            case .adaptive: return "Adaptive"
                            case .plain: return "Plain"
                            case .grouped: return "Grouped"
                            case .insetGrouped: return "Inset Grouped"
                            case .sidebar: return "Sidebar"
                            case .carousel: return "Carousel"
                            }
                        },
                        pickerName: "ListStylePicker",
                        style: SegmentedPickerStyle()
                    )
                    .padding()
                    
                    Divider()
                    
                    // List
                    AdaptiveUIPatterns.AdaptiveList(
                        items,
                        style: selectedStyle,
                        context: .standard
                    ) { item in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text(item.title)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                    }
                }
            }
            .automaticCompliance(named: "AdaptiveListExample")
        }
    }
    
    // MARK: - Button Examples
    
    /// Example of adaptive buttons with different styles and sizes
    public struct AdaptiveButtonExample: View {
        public init() {}
        
        public var body: some View {
            PlatformUIIntegration.SmartNavigationContainer(
                title: "Adaptive Buttons",
                style: .adaptive
            ) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Button styles
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Button Styles")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Primary",
                                    style: ButtonStyle.primary,
                                    action: {}
                                )
                                
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Secondary",
                                    style: ButtonStyle.secondary,
                                    action: {}
                                )
                                
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Outline",
                                    style: ButtonStyle.outline,
                                    action: {}
                                )
                            }
                            
                            HStack(spacing: 12) {
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Ghost",
                                    style: ButtonStyle.ghost,
                                    action: {}
                                )
                                
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Destructive",
                                    style: ButtonStyle.destructive,
                                    action: {}
                                )
                                
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Adaptive",
                                    style: ButtonStyle.adaptive,
                                    action: {}
                                )
                            }
                        }
                        
                        // Button sizes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Button Sizes")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Small",
                                    size: ButtonSize.small,
                                    action: {}
                                )
                                
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Medium",
                                    size: ButtonSize.medium,
                                    action: {}
                                )
                                
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Large",
                                    size: ButtonSize.large,
                                    action: {}
                                )
                            }
                        }
                        
                        // Buttons with icons
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Buttons with Icons")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Add",
                                    icon: "plus",
                                    style: ButtonStyle.primary,
                                    action: {}
                                )
                                
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Edit",
                                    icon: "pencil",
                                    style: ButtonStyle.secondary,
                                    action: {}
                                )
                                
                                AdaptiveUIPatterns.AdaptiveButton(
                                    "Delete",
                                    icon: "trash",
                                    style: ButtonStyle.destructive,
                                    action: {}
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .automaticCompliance(named: "AdaptiveButtonExample")
        }
    }
    
    // MARK: - Form Examples
    
    /// Example of adaptive form with smart container
    public struct AdaptiveFormExample: View {
        @State private var name = ""
        @State private var email = ""
        @State private var age = ""
        @State private var isPresented = false
        
        public init() {}
        
        public var body: some View {
            PlatformUIIntegration.SmartNavigationContainer(
                title: "Form Examples",
                style: .adaptive
            ) {
                VStack(spacing: 20) {
                    Text("Form Examples")
                        .font(.title)
                    
                    AdaptiveUIPatterns.AdaptiveButton(
                        "Show Form Modal",
                        icon: "doc.text",
                        style: ButtonStyle.primary,
                        action: { isPresented = true }
                    )
                }
                .padding()
            }
            .sheet(isPresented: $isPresented) {
                PlatformUIIntegration.SmartFormContainer(
                    title: "User Information",
                    onSubmit: { isPresented = false },
                    onCancel: { isPresented = false }
                ) {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter your name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter your age", text: $age)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
            }
            .automaticCompliance(named: "AdaptiveFormExample")
        }
    }
    
    // MARK: - Card Examples
    
    /// Example of adaptive cards with smart container
    public struct AdaptiveCardExample: View {
        public init() {}
        
        public var body: some View {
            PlatformUIIntegration.SmartNavigationContainer(
                title: "Card Examples",
                style: .adaptive
            ) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        PlatformUIIntegration.SmartCardContainer(
                            title: "Simple Card",
                            subtitle: "This is a simple card with just content"
                        ) {
                            Text("This card contains simple content without any actions.")
                                .font(.body)
                        }
                        
                        PlatformUIIntegration.SmartCardContainer(
                            title: "Card with Action",
                            subtitle: "This card has an action button",
                            actionTitle: "View Details",
                            action: {}
                        ) {
                            Text("This card has an action button that can be tapped.")
                                .font(.body)
                        }
                        
                        PlatformUIIntegration.SmartCardContainer(
                            title: "Complex Card",
                            subtitle: "This card has multiple elements"
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("This is a more complex card with multiple elements.")
                                    .font(.body)
                                
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("4.5")
                                        .font(.caption)
                                    Spacer()
                                    Text("Updated 2 hours ago")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .automaticCompliance(named: "AdaptiveCardExample")
        }
    }
}

// MARK: - Supporting Views

private struct DetailView: View {
    let item: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Detail for \(item)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This is the detail view for \(item). It shows additional information about the selected item.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle(item)
        .platformNavigationTitleDisplayMode_L4(.inline)
        .automaticCompliance(named: "DetailView")
    }
}

// MARK: - Main Example App

/// Main example app that demonstrates all platform-specific UI patterns
public struct PlatformUIExampleApp: View {
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            PlatformUIExamples.AdaptiveNavigationExample()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Navigation")
                }
                .tag(0)
            
            PlatformUIExamples.AdaptiveModalExample()
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("Modals")
                }
                .tag(1)
            
            PlatformUIExamples.AdaptiveListExample()
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Lists")
                }
                .tag(2)
            
            PlatformUIExamples.AdaptiveButtonExample()
                .tabItem {
                    Image(systemName: "button.programmable")
                    Text("Buttons")
                }
                .tag(3)
            
            PlatformUIExamples.AdaptiveFormExample()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Forms")
                }
                .tag(4)
            
            PlatformUIExamples.AdaptiveCardExample()
                .tabItem {
                    Image(systemName: "rectangle")
                    Text("Cards")
                }
                .tag(5)
        }
        .withThemedFramework()
        .automaticCompliance(named: "PlatformUIExampleApp")
    }
}

// MARK: - Layout Decision Reasoning Examples
// Examples showing how to use reasoning properties for debugging, analytics, and transparency

/// Example showing how to access and use layout decision reasoning
public struct LayoutDecisionReasoningExample: View {
    @State private var layoutDecision: GenericLayoutDecision?
    @State private var formDecision: GenericFormLayoutDecision?
    @State private var debugInfo: String = ""
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Layout Decision Reasoning")
                .font(.title2)
                .fontWeight(.bold)
            
            // Example 1: Accessing reasoning properties
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Accessing Reasoning Properties")
                    .font(.headline)
                
                Button("Generate Layout Decision") {
                    generateLayoutDecision()
                }
                .buttonStyle(.borderedProminent)
                
                if let decision = layoutDecision {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Approach: \(decision.approach.rawValue)")
                        Text("Columns: \(decision.columns)")
                        Text("Spacing: \(decision.spacing, specifier: "%.1f")pt")
                        Text("Performance: \(decision.performance.rawValue)")
                        Text("Reasoning: \(decision.reasoning)")
                            .foregroundColor(.blue)
                            .italic()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Example 2: Debugging with reasoning
            VStack(alignment: .leading, spacing: 8) {
                Text("2. Debugging Layout Decisions")
                    .font(.headline)
                
                Button("Debug Layout Decision") {
                    debugLayoutDecision()
                }
                .buttonStyle(.bordered)
                
                if !debugInfo.isEmpty {
                    Text(debugInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Example 3: Form layout reasoning
            VStack(alignment: .leading, spacing: 8) {
                Text("3. Form Layout Reasoning")
                    .font(.headline)
                
                Button("Generate Form Decision") {
                    generateFormDecision()
                }
                .buttonStyle(.bordered)
                
                if let decision = formDecision {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Container: \(decision.preferredContainer.rawValue)")
                        Text("Field Layout: \(decision.fieldLayout.rawValue)")
                        Text("Spacing: \(decision.spacing.rawValue)")
                        Text("Validation: \(decision.validation.rawValue)")
                        Text("Complexity: \(decision.contentComplexity.rawValue)")
                        Text("Reasoning: \(decision.reasoning)")
                            .foregroundColor(.green)
                            .italic()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .automaticCompliance(named: "LayoutDecisionReasoningExample")
    }
    
    // MARK: - Example Methods
    
    private func generateLayoutDecision() {
        // Simulate generating a layout decision
        layoutDecision = GenericLayoutDecision(
            approach: .grid,
            columns: 3,
            spacing: 16.0,
            performance: .optimized,
            reasoning: "Selected grid layout with 3 columns for optimal user experience on tablet devices"
        )
    }
    
    private func debugLayoutDecision() {
        guard let decision = layoutDecision else { return }
        
        // Example of using reasoning for debugging
        debugInfo = """
        🔍 Layout Decision Debug Info:
        
        Decision: \(decision.approach.rawValue) layout
        Reasoning: \(decision.reasoning)
        
        Analysis:
        - Columns: \(decision.columns) (optimal for content density)
        - Spacing: \(String(format: "%.1f", decision.spacing))pt (comfortable spacing)
        - Performance: \(decision.performance.rawValue) (balanced performance)
        
        This reasoning helps understand why this specific layout was chosen.
        """
    }
    
    private func generateFormDecision() {
        // Simulate generating a form layout decision
        formDecision = GenericFormLayoutDecision(
            preferredContainer: .adaptive,
            fieldLayout: .standard,
            spacing: .comfortable,
            validation: .realTime,
            contentComplexity: .moderate,
            reasoning: "Form layout optimized based on field count and complexity for better user experience"
        )
    }
}

/// Example showing how to log reasoning for analytics
public struct LayoutReasoningAnalyticsExample: View {
    @State private var analyticsLog: [String] = []
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Reasoning Analytics Example")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This example shows how to log layout decision reasoning for analytics and monitoring.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Simulate Layout Decisions") {
                simulateLayoutDecisions()
            }
            .buttonStyle(.borderedProminent)
            
            if !analyticsLog.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analytics Log:")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(analyticsLog.enumerated()), id: \.offset) { index, logEntry in
                                Text("\(index + 1). \(logEntry)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .automaticCompliance(named: "LayoutReasoningAnalyticsExample")
    }
    
    private func simulateLayoutDecisions() {
        analyticsLog.removeAll()
        
        // Simulate multiple layout decisions and log their reasoning
        let decisions = [
            GenericLayoutDecision(
                approach: .grid,
                columns: 2,
                spacing: 16.0,
                performance: .standard,
                reasoning: "Grid layout selected for balanced content presentation"
            ),
            GenericLayoutDecision(
                approach: .list,
                columns: 1,
                spacing: 8.0,
                performance: .highPerformance,
                reasoning: "List layout chosen for optimal performance with large datasets"
            ),
            GenericLayoutDecision(
                approach: .adaptive,
                columns: 3,
                spacing: 24.0,
                performance: .optimized,
                reasoning: "Adaptive layout for responsive design across different screen sizes"
            )
        ]
        
        for decision in decisions {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let logEntry = "[\(timestamp)] Layout: \(decision.approach.rawValue) | Reasoning: \(decision.reasoning)"
            analyticsLog.append(logEntry)
        }
    }
}

/// Example showing how to display reasoning in UI for transparency
public struct LayoutReasoningTransparencyExample: View {
    @State private var showReasoning = false
    @State private var currentDecision: GenericLayoutDecision?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Layout Transparency Example")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This example shows how to display layout reasoning to users for transparency.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Generate Layout with Reasoning") {
                generateLayoutWithReasoning()
            }
            .buttonStyle(.borderedProminent)
            
            if let decision = currentDecision {
                VStack(spacing: 16) {
                    // Display the layout decision
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Layout Decision")
                            .font(.headline)
                        
                        HStack {
                            Text("Approach:")
                            Spacer()
                            Text(decision.approach.rawValue.capitalized)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Columns:")
                            Spacer()
                            Text("\(decision.columns)")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Spacing:")
                            Spacer()
                            Text("\(decision.spacing, specifier: "%.1f")pt")
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Toggle reasoning display
                    Button(showReasoning ? "Hide Reasoning" : "Show Reasoning") {
                        showReasoning.toggle()
                    }
                    .buttonStyle(.bordered)
                    
                    if showReasoning {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Why this layout was chosen:")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Text(decision.reasoning)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.opacity)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .animation(.easeInOut, value: showReasoning)
        .automaticCompliance(named: "LayoutReasoningTransparencyExample")
    }
    
    private func generateLayoutWithReasoning() {
        currentDecision = GenericLayoutDecision(
            approach: .adaptive,
            columns: 2,
            spacing: 20.0,
            performance: .optimized,
            reasoning: "Adaptive layout selected to provide optimal user experience across different device sizes, with 2 columns for balanced content density and 20pt spacing for comfortable reading."
        )
        showReasoning = false
    }
}
