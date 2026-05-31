# Developer Extension Guide for 6layer Framework

## Overview

This guide explains how developers can extend the 6layer framework to integrate their custom views, business logic, and unique functionality while leveraging the framework's intelligent platform adaptation and performance optimization capabilities.

> **Stable Extension Surface (Normative)**  
> The sections below describe the **supported public extension surface** for the framework.  
> Anything **not** listed here should be treated as an **internal implementation detail** and is **not** considered stable across minor versions.

### Stable Extension Surface (Public APIs)

The following areas are explicitly supported as **stable extension points** for app code:

1. **Layer 1 Semantic Functions (public, stable entry points)**
   - `platformPresentItemCollection_L1(...)`
   - `platformPresentNumericData_L1(...)` (all overloads)
   - `platformResponsiveCard_L1(...)`
   - **Deprecated but supported for migration only**: `platformPresentFormData_L1(...)`  
     - New code should prefer `DynamicFormView` + `DynamicFormField` instead.

2. **Hints & Extensibility Types**
   - `PresentationHints`
   - `EnhancedPresentationHints`
   - `CustomHint` / `ExtensibleHint` conforming types
   - All associated enums used in hints (e.g. `DataTypeHint`, `PresentationPreference`, `ContentComplexity`, `PresentationContext`)
   - These types are the **primary way** for apps to influence layout/behavior without depending on internal engine details.

3. **Service Extension Points**
   - **CloudKit**
     - `CloudKitService`
     - `CloudKitServiceDelegate` (primary extension surface for CloudKit behavior)
     - `CloudKitServiceError`, `CloudKitSyncStatus`
   - **Internationalization / Localization**
     - `InternationalizationService` (class is public and may be instantiated/configured by apps)
   - **Notifications**
     - `NotificationService` and its public configuration/entry points
   - **Security & Privacy**
     - `SecurityService` and associated public types (e.g. `SecurityServiceError`, `BiometricType`, `PrivacyPermissionType`)
   - These services are designed to be **constructed and configured** by app code, and their documented delegates / configuration types are part of the stable surface.

4. **Forms & Dynamic Form System**
   - `DynamicFormView`
   - `DynamicFormField`
   - `DynamicFormState`
   - Public enums and supporting types used by the form system (field types, validation rules, etc.)
   - These APIs are the recommended way to integrate complex forms with the framework.

5. **Layer 4 Components & Modifiers**
   - Public SwiftUI components and modifiers under the `Platform*` / `platform*` naming:
     - e.g. `platformCardGrid(...)`, `platformCardStyle(...)`, `platformCardPadding()`
     - e.g. `platformMemoryOptimization()`, `platformRenderingOptimization()`
   - These can be used directly in custom views and are part of the supported surface.

### Internal vs. Public – How to Decide

When in doubt, use the following rules:

- **Safe to depend on (public extension surface):**
  - Public functions and types explicitly documented in:
    - `README_Layer1_Semantic.md`
    - `DeveloperExtensionGuide.md` (this file)
    - `ExtensionQuickReference.md`
    - Service guides (e.g. `CloudKitServiceGuide.md`, `NotificationGuide.md`, `SecurityGuide.md`)
  - Public services and their documented delegates/configuration types.
  - Public SwiftUI components and modifiers under the `platform*` / `Platform*` naming.

- **Treat as internal (not stable across minor versions):**
  - Any **non-public** type or member.
  - Types whose documentation explicitly calls them **deprecated**, **internal**, or **implementation detail**.
  - Engine/architecture helpers such as `HintProcessingEngine` or low-level strategy/decision engine types that are not mentioned in the docs above.
  - Internal view types used to implement Layer 1/Layer 4 functions (for example: `GenericItemCollectionView`, internal layout views, or anything in `Core/Architecture` that is not called out as public surface).

Depending on internal types or copying internal implementation details may work in one release but is **not covered by stability guarantees** and may break in future minor versions.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Concurrency and Sendable](#concurrency-and-sendable)
3. [Extension Mechanisms](#extension-mechanisms)
4. [Custom Hints System](#custom-hints-system)
5. [Integration Patterns](#integration-patterns)
6. [Best Practices](#best-practices)
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)

## Concurrency and Sendable

SixLayer separates **immutable hints** (loaded at launch, safe across actors) from **runtime presentation** (form state, closures, SwiftUI views on `@MainActor`).

### Rule of thumb

**`Sendable`** = immutable, shareable configuration. **Not `Sendable`** = live UI, callbacks, or type-erased runtime bags.

| Category | `Sendable`? | Examples |
|----------|-------------|----------|
| Declarative config / metadata | **Yes** | `FieldDisplayHints`, `PresentationHints`, `HintsSectionLayout`, `DataHintsResult`, `ItemColorProviderConfig` |
| UI-bound / mutable state | **No** — `@MainActor` | `DynamicFormState` |
| Fields with closures or `[String: Any]` | **No** | `DynamicFormField`, runtime `DynamicFormSection` |
| App business models | **Optional** | Only if your app crosses actors; framework uses `CardDisplayable`, not required `Sendable` |
| Audited escape hatch | **`@unchecked Sendable`** sparingly | `CustomHint` (`[String: Any]` metadata), `PlatformImage` |

### Hints vs form presentation

- **Cached at launch:** `DataHintsResult` — field hints, `HintsSectionLayout` recipes (section IDs, ordered field IDs, layout style), colors, OCR groups.
- **Resolved at form open:** `SectionBuilder.buildSections(from:matching:)` wires layout recipes to live `DynamicFormField` instances.
- **Rendered on `@MainActor`:** visibility filters, collapse state, custom trailing/value views.

Do not store closure-bearing `DynamicFormField` values in hints caches. Behavior is derived from hint flags (e.g. OCR/barcode) or attached by app code when the form is presented.

### Review checklist (new public value types)

1. Will this type cross actor boundaries or sit in a shared cache?
2. If yes, are all stored properties provably `Sendable`?
3. If no, document `@MainActor` or intentional non-`Sendable` in the type’s doc comment.

## Quick Start

### 1. Import the Framework

```swift
import SixLayerFramework
```

### 2. Create Your Custom View

```swift
struct MyCustomView: View {
    let myData: [MyCustomItem]
    
    var body: some View {
        // Use framework functions to present your data
        platformPresentItemCollection_L1(
            items: myData,
            hints: PresentationHints(
                dataType: .collection,
                presentationPreference: .cards,
                complexity: .moderate,
                context: .dashboard
            )
        )
    }
}
```

### 3. The Framework Handles the Rest

- **Automatic Layout**: Framework analyzes your data and hints to determine optimal presentation
- **Platform Adaptation**: Views automatically adapt to iOS/macOS conventions
- **Performance Optimization**: Framework applies memory and rendering optimizations
- **Responsive Behavior**: Views respond to screen size and device capabilities

## Extension Mechanisms

### 1. Semantic Intent Extension (Layer 1)

Express **what** you want to achieve without worrying about implementation details:

```swift
// Present collections of items
platformPresentItemCollection_L1(items: items, hints: hints)

// Present numeric data
platformPresentNumericData_L1(data: data, hints: hints)

// Present forms
platformPresentFormData_L1(fields: fields, hints: hints)

// Present responsive cards
platformResponsiveCard_L1(content: { MyContent() }, hints: hints)
```

### 2. Custom Hints System

The most powerful extension mechanism - create custom hints that influence framework decisions:

```swift
class MyAppHint: CustomHint {
    init(
        showAdvancedFeatures: Bool = false,
        theme: String = "default",
        customBehavior: String = "standard"
    ) {
        super.init(
            hintType: "myapp.custom",
            priority: .high,
            overridesDefault: false,
            customData: [
                "showAdvancedFeatures": showAdvancedFeatures,
                "theme": theme,
                "customBehavior": customBehavior,
                "recommendedLayout": "adaptive",
                "animationStyle": "smooth"
            ]
        )
    }
}
```

### 3. Direct Component Usage (Layer 4)

Use framework components directly in your custom views:

```swift
struct MyCustomDashboard: View {
    var body: some View {
        platformCardGrid(columns: 3, spacing: 16) {
            ForEach(items) { item in
                MyCustomCard(item: item)
                    .platformCardStyle(
                        backgroundColor: .systemBackground,
                        cornerRadius: 12,
                        shadowRadius: 4
                    )
            }
        }
        .platformCardPadding()
    }
}
```

### 4. Progressive Enhancement

Combine multiple layers for advanced functionality:

```swift
struct MyComplexView: View {
    var body: some View {
        platformResponsiveCard_L1(
            content: { MyCustomContent() },
            hints: hints
        )
        .platformMemoryOptimization()        // Layer 5
        .platformRenderingOptimization()     // Layer 5
        #if os(macOS)
        .platformMacOSWindowResizing(resizable: true)  // Layer 6
        #endif
    }
}
```

## Custom Hints System

### Understanding Hints

Hints are the communication mechanism between your app and the framework:

```swift
public struct PresentationHints: Sendable {
    public let dataType: DataTypeHint           // What type of data
    public let presentationPreference: PresentationPreference  // Preferred layout
    public let complexity: ContentComplexity    // Content complexity level
    public let context: PresentationContext     // Display context
    public let customPreferences: [String: String]  // Basic extensibility
}
```

### Enhanced Hints for Advanced Extensibility

```swift
public struct EnhancedPresentationHints: Sendable {
    // ... basic hints ...
    public let extensibleHints: [ExtensibleHint]  // Custom hint types
}
```

### Creating Custom Hint Types

```swift
// 1. Inherit from CustomHint
class EcommerceProductHint: CustomHint {
    init(
        category: String,
        showPricing: Bool = true,
        showReviews: Bool = true,
        layoutStyle: String = "grid"
    ) {
        super.init(
            hintType: "ecommerce.product",
            priority: .high,
            overridesDefault: false,
            customData: [
                "category": category,
                "showPricing": showPricing,
                "showReviews": showReviews,
                "layoutStyle": layoutStyle,
                "recommendedColumns": 3,
                "showWishlist": true,
                "quickViewEnabled": true
            ]
        )
    }
}

// 2. Use in your views
let hints = EnhancedPresentationHints(
    dataType: .collection,
    presentationPreference: .automatic,
    complexity: .moderate,
    context: .browse,
    extensibleHints: [
        EcommerceProductHint(
            category: "electronics",
            showPricing: true,
            showReviews: true
        )
    ]
)
```

### Hint Priority Levels

```swift
.priority = .low      // Can be overridden by framework
.priority = .normal   // Standard preferences
.priority = .high     // Important preferences
.priority = .critical // Must be respected by framework
```

## Integration Patterns

### 1. Data Model Integration

Ensure your models conform to required protocols:

```swift
struct MyCustomItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    
    // Framework will use these properties for layout decisions
    var estimatedComplexity: ContentComplexity {
        if description.count > 100 { return .complex }
        if description.count > 50 { return .moderate }
        return .simple
    }
}
```

### 2. Custom Hint Factories

Create reusable hint patterns for your app:

```swift
extension EnhancedPresentationHints {
    /// Create hints optimized for your app's dashboard
    static func forMyAppDashboard(
        section: String,
        showAdvancedMetrics: Bool = true,
        layoutStyle: String = "adaptive"
    ) -> EnhancedPresentationHints {
        let dashboardHint = CustomHint(
            hintType: "myapp.dashboard",
            priority: .high,
            overridesDefault: false,
            customData: [
                "section": section,
                "showAdvancedMetrics": showAdvancedMetrics,
                "layoutStyle": layoutStyle,
                "recommendedColumns": 2,
                "showQuickActions": true,
                "refreshInterval": 30
            ]
        )
        
        return EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard,
            extensibleHints: [dashboardHint]
        )
    }
}
```

### 3. Conditional Framework Usage

Adapt framework usage based on your app's needs:

```swift
struct MyAdaptiveView: View {
    let useFramework: Bool
    let items: [MyItem]
    
    var body: some View {
        if useFramework {
            // Use framework for intelligent layout
            platformPresentItemCollection_L1(
                items: items,
                hints: EnhancedPresentationHints.forMyAppDashboard(
                    section: "main",
                    showAdvancedMetrics: true
                )
            )
        } else {
            // Fallback to custom implementation
            MyCustomLayout(items: items)
        }
    }
}
```

## Best Practices

### 1. Naming Conventions

```swift
// Use reverse domain notation for hint types
hintType: "com.mycompany.myapp.feature"

// Use descriptive names for custom data keys
customData: [
    "showAdvancedFeatures": true,      // ✅ Clear and descriptive
    "adv": true                        // ❌ Too cryptic
]
```

### 2. Hint Design

```swift
// ✅ Good: Provide meaningful guidance
customData: [
    "recommendedColumns": 3,
    "preferredAnimation": "smooth",
    "estimatedComplexity": "moderate"
]

// ❌ Avoid: Overly specific or rigid constraints
customData: [
    "forceColumns": 3,                 // Too rigid
    "exactWidth": 300                  // Too specific
]
```

### 3. Performance Considerations

```swift
// Use appropriate complexity levels
let hints = PresentationHints(
    dataType: .collection,
    presentationPreference: .automatic,
    complexity: .simple,  // Start simple, let framework optimize
    context: .dashboard
)

// Apply performance optimizations when needed
MyHeavyView()
    .platformMemoryOptimization()
    .platformRenderingOptimization()
```

### 4. Platform Awareness

```swift
// Let framework handle platform differences
let hints = PresentationHints(
    dataType: .collection,
    presentationPreference: .automatic,  // Let framework decide
    complexity: .moderate,
    context: .dashboard
)

// Or specify platform-specific preferences
#if os(iOS)
let platformHints = CustomHint(
    hintType: "ios.specific",
    customData: ["preferredSpacing": 16]
)
#elseif os(macOS)
let platformHints = CustomHint(
    hintType: "macos.specific",
    customData: ["preferredSpacing": 20]
)
#endif
```

## Examples

### Example 1: E-commerce Product Catalog

```swift
struct ProductCatalogView: View {
    let products: [Product]
    
    var body: some View {
        let hints = EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .grid,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [
                EcommerceProductHint(
                    category: "electronics",
                    showPricing: true,
                    showReviews: true,
                    layoutStyle: "masonry"
                )
            ]
        )
        
        return platformPresentItemCollection_L1(
            items: products,
            hints: hints
        )
        .navigationTitle("Products")
        .platformMemoryOptimization()
    }
}
```

### Example 2: Financial Dashboard

```swift
struct FinancialDashboardView: View {
    let financialData: [FinancialMetric]
    
    var body: some View {
        let hints = EnhancedPresentationHints.forMyAppDashboard(
            section: "financial",
            showAdvancedMetrics: true,
            layoutStyle: "adaptive"
        )
        
        return platformPresentItemCollection_L1(
            items: financialData,
            hints: hints
        )
        .platformRenderingOptimization()
    }
}
```

### Example 3: Custom Form with Framework Integration

```swift
struct CustomExpenseForm: View {
    @StateObject private var formState = DynamicFormState(configuration: formConfig)
    
    private let formConfig = DynamicFormConfiguration(
        sections: [
            DynamicFormSection(
                id: "expense",
                title: "Expense Details",
                fields: [
                    DynamicFormField(id: "amount", type: .number, label: "Amount"),
                    DynamicFormField(id: "description", type: .text, label: "Description"),
                    DynamicFormField(id: "category", type: .select, label: "Category", options: ["Travel", "Meals", "Office", "Other"])
                ]
            )
        ]
    )
    
    var body: some View {
        VStack(spacing: 20) {
            // Use framework for form presentation with native types
            DynamicFormView(
                configuration: formConfig,
                formState: formState
            )
            
            // Custom submit button
            Button("Submit Expense") {
                // Handle submission - access native types directly
                let amount: Double = formState.getValue(for: "amount") ?? 0.0
                let description: String = formState.getValue(for: "description") ?? ""
                let category: String = formState.getValue(for: "category") ?? ""
                
                // Process form data...
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

**⚠️ Note**: The deprecated `GenericFormField` and `platformPresentFormData_L1` functions have been replaced with `DynamicFormField` and `DynamicFormView` for better type safety and native data type support.

### Example 4: Custom CloudKit Service Delegate (Stable Extension Surface)

The following example shows how to extend the framework using the **stable CloudKit extension surface** (`CloudKitServiceDelegate` and `CloudKitService`).

```swift
import SixLayerFramework
import CloudKit

/// App-specific CloudKit delegate that customizes container, validation, and conflict resolution
final class MyCloudKitDelegate: CloudKitServiceDelegate {
    // Required: which CloudKit container to use
    func containerIdentifier() -> String {
        // Replace with your app's container identifier
        "iCloud.com.mycompany.myapp"
    }

    // Optional: validate records before they are saved
    func validateRecord(_ record: CKRecord) throws {
        // Enforce a required "ownerID" field for all records
        if record["ownerID"] == nil {
            throw CloudKitServiceError.missingRequiredField("ownerID")
        }
    }

    // Optional: transform records before save (e.g. add metadata)
    func transformRecord(_ record: CKRecord) -> CKRecord {
        record["lastUpdatedAt"] = Date() as NSDate
        return record
    }

    // Optional: app-specific conflict resolution strategy
    func resolveConflict(local: CKRecord, remote: CKRecord) -> CKRecord? {
        // Example: prefer the record with the latest modification date
        let localDate = local.modificationDate ?? Date.distantPast
        let remoteDate = remote.modificationDate ?? Date.distantPast
        return localDate >= remoteDate ? local : remote
    }

    // Optional: centralized error handling hook
    func handleError(_ error: Error) -> Bool {
        // Log or map errors to your own telemetry system
        print("CloudKit error:", error)
        // Return true if the error is fully handled and should not be rethrown
        return false
    }

    // Optional: observe sync completion events
    func syncDidComplete(success: Bool, recordsChanged: Int) {
        print("CloudKit sync completed. success=\(success), recordsChanged=\(recordsChanged)")
    }
}

/// Example usage of the delegate with the stable service surface
@MainActor
final class CloudSyncManager: ObservableObject {
    private let service: CloudKitService

    init() {
        let delegate = MyCloudKitDelegate()
        self.service = CloudKitService(delegate: delegate)
    }

    func save(record: CKRecord) async {
        do {
            try await service.save(record)
        } catch {
            // Errors are already passed through `handleError(_:)` on the delegate
            print("Failed to save record:", error)
        }
    }
}
```

This example is safe to use across minor versions because it relies **only** on the documented public surface:

- `CloudKitService`
- `CloudKitServiceDelegate`
- `CloudKitServiceError`

### Example 5: App-Specific Layer 1 Wrapper (Stable Semantic Extension)

You can also safely extend the framework at **Layer 1** by introducing your own semantic helpers that forward into the documented Layer 1 functions. This lets you express richer intent (\"present my app's dashboard\") without depending on internal layout/strategy types.

```swift
import SixLayerFramework
import SwiftUI

/// App-specific semantic function for presenting a dashboard section
@MainActor
public func presentDashboardSection_L1<Metric: Identifiable>(
    metrics: [Metric],
    title: String,
    showAdvanced: Bool
) -> some View {
    // 1. Build hints using the stable hints surface
    let hints = EnhancedPresentationHints(
        dataType: .collection,
        presentationPreference: .automatic,
        complexity: showAdvanced ? .complex : .moderate,
        context: .dashboard,
        extensibleHints: [
            CustomHint(
                hintType: "com.mycompany.myapp.dashboard",
                priority: .high,
                overridesDefault: false,
                customData: [
                    "sectionTitle": title,
                    "showAdvancedMetrics": showAdvanced,
                    "layoutStyle": "adaptive"
                ]
            )
        ]
    )

    // 2. Forward into the stable Layer 1 entry point
    return platformPresentItemCollection_L1(
        items: metrics,
        hints: hints
    )
}

/// Usage in a view
struct MyDashboardSectionView: View {
    let metrics: [MyMetric]

    var body: some View {
        presentDashboardSection_L1(
            metrics: metrics,
            title: "Financial Overview",
            showAdvanced: true
        )
        .navigationTitle("Dashboard")
    }
}
```

This pattern is considered stable because it:

- Uses only **documented public types** (`EnhancedPresentationHints`, `CustomHint`, `platformPresentItemCollection_L1`).
- Encapsulates app-specific semantics in your own function (`presentDashboardSection_L1`) without reaching into internal strategy/engine types.

## Troubleshooting

### Common Issues

#### 1. Hints Not Being Processed

```swift
// ✅ Ensure your hints conform to ExtensibleHint protocol
class MyHint: CustomHint {  // Inherit from CustomHint
    // ... implementation
}

// ❌ Don't create custom structs
struct MyHint {  // Won't work with framework
    // ... implementation
}
```

#### 2. Priority Conflicts

```swift
// ✅ Use appropriate priority levels
.priority = .normal  // For standard preferences
.priority = .high    // For important preferences

// ❌ Avoid overusing critical priority
.priority = .critical  // Only when absolutely necessary
```

#### 3. Data Type Mismatches

```swift
// ✅ Use appropriate Swift types
customData: [
    "count": 42,                    // Int
    "enabled": true,                // Bool
    "name": "example",              // String
    "options": ["a", "b", "c"],     // Array
    "config": ["key": "value"]      // Dictionary
]

// ❌ Avoid complex types
customData: [
    "callback": { /* closure */ },  // Won't serialize properly
    "view": MyView()                // Won't work
]
```

### Debugging Tips

```swift
// Check if your hints are being processed
print("Hint count: \(enhancedHints.extensibleHints.count)")
print("Highest priority: \(enhancedHints.highestPriorityHint?.hintType ?? "none")")
print("All custom data: \(enhancedHints.allCustomData)")

// Verify hint processing
let layoutPrefs = HintProcessingEngine.extractLayoutPreferences(from: enhancedHints)
print("Layout preferences: \(layoutPrefs)")
```

### Performance Issues

```swift
// If experiencing performance issues, check complexity levels
let hints = PresentationHints(
    dataType: .collection,
    presentationPreference: .automatic,
    complexity: .simple,  // Start with simple
    context: .dashboard
)

// Apply performance optimizations
MyView()
    .platformMemoryOptimization()
    .platformRenderingOptimization()
```

## Getting Help

### Documentation Resources

- **Architecture Overview**: [README_6LayerArchitecture.md](README_6LayerArchitecture.md)
- **Hints System**: [HintsSystemExtensibility.md](HintsSystemExtensibility.md)
- **Usage Examples**: [README_UsageExamples.md](README_UsageExamples.md)
- **Layer Details**: Individual layer README files

### Framework Functions

Key functions for extension:

- `platformPresentItemCollection_L1()` - Present collections
- `platformPresentNumericData_L1()` - Present numeric data
- `platformPresentFormData_L1()` - Present forms ⚠️ **DEPRECATED** - Use `DynamicFormView` instead
- `platformResponsiveCard_L1()` - Present responsive cards
- `platformCardGrid()` - Grid layout
- `platformCardStyle()` - Card styling
- `platformMemoryOptimization()` - Memory optimization
- `platformRenderingOptimization()` - Rendering optimization

**Form Functions (Recommended):**
- `DynamicFormView()` - Modern form presentation with native types
- `DynamicFormField()` - Form field configuration
- `DynamicFormState()` - Form state management

### Support

- Check the framework source code for implementation details
- Review the stub examples in the `Stubs/` directory
- Test your extensions thoroughly on both iOS and macOS
- Use the debugging tools to verify hint processing

## Conclusion

The 6layer framework provides powerful extension mechanisms that allow you to:

- **Focus on your business logic** while the framework handles platform adaptation
- **Create intelligent layouts** through the hints system
- **Optimize performance** automatically across all layers
- **Maintain consistency** across iOS and macOS platforms
- **Future-proof your code** with automatic framework updates

By following the patterns and best practices outlined in this guide, you can seamlessly integrate your custom views and functionality with the framework's intelligent decision-making engine.

Remember: Start simple with basic hints, then progressively enhance with custom hint types and advanced features as needed. The framework is designed to work with minimal configuration while providing powerful customization options for advanced use cases.
