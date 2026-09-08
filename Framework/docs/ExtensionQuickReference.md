# 6layer Framework Extension Quick Reference

## 🚀 Quick Start

```swift
import SixLayerFramework

// Basic usage - framework handles everything
platformPresentItemCollection_L1(
    items: myItems,
    hints: PresentationHints(
        dataType: .collection,
        presentationPreference: .cards,
        complexity: .moderate,
        context: .dashboard
    )
)
```

## 🔧 Extension Mechanisms

### 1. **Semantic Functions (Layer 1)**
```swift
// Present collections
platformPresentItemCollection_L1(items: items, hints: hints)

// Present forms
platformPresentFormData_L1(fields: fields, hints: hints)

// Present responsive cards
platformResponsiveCard_L1(content: { MyContent() }, hints: hints)
```

### 2. **Custom Hints (Most Powerful)**
```swift
class MyAppHint: CustomHint {
    init(showAdvanced: Bool = false) {
        super.init(
            hintType: "myapp.custom",
            priority: .high,
            overridesDefault: false,
            customData: [
                "showAdvanced": showAdvanced,
                "recommendedLayout": "adaptive"
            ]
        )
    }
}

// Use with enhanced hints
let hints = EnhancedPresentationHints(
    dataType: .collection,
    presentationPreference: .automatic,
    complexity: .moderate,
    context: .dashboard,
    extensibleHints: [MyAppHint(showAdvanced: true)]
)
```

### 3. **Direct Components (Layer 4)**
```swift
platformCardGrid(columns: 3, spacing: 16) {
    ForEach(items) { item in
        MyCustomCard(item: item)
            .platformCardStyle(
                backgroundColor: .systemBackground,
                cornerRadius: 12
            )
    }
}
.platformCardPadding()
```

### 4. **Progressive Enhancement**
```swift
platformResponsiveCard_L1(content: { MyContent() }, hints: hints)
    #if os(iOS)
    .platformIOSHapticFeedback(style: .light)  // Layer 5 (real API)
    #endif
    #if os(macOS)
    .platformMacOSWindowResizing(resizable: true)  // Layer 6
    #endif
```

Generic `platformMemoryOptimization` / `platformRenderingOptimization` modifiers are not implemented (#425).

## 📊 Hints Structure

```swift
struct PresentationHints {
    let dataType: DataTypeHint           // .collection, .form, .numeric
    let presentationPreference: PresentationPreference  // .cards, .grid, .list
    let complexity: ContentComplexity    // .simple, .moderate, .complex
    let context: PresentationContext     // .dashboard, .browse, .input
    let customPreferences: [String: String]
}
```

## 🎯 Common Patterns

### **E-commerce Product Grid**
```swift
let hints = EnhancedPresentationHints(
    dataType: .collection,
    presentationPreference: .grid,
    complexity: .moderate,
    context: .browse,
    extensibleHints: [
        CustomHint(
            hintType: "ecommerce.product",
            customData: [
                "category": "electronics",
                "showPricing": true,
                "recommendedColumns": 3
            ]
        )
    ]
)
```

### **Dashboard with Custom Metrics**
```swift
let hints = EnhancedPresentationHints(
    dataType: .collection,
    presentationPreference: .automatic,
    complexity: .moderate,
    context: .dashboard,
    extensibleHints: [
        CustomHint(
            hintType: "dashboard.metrics",
            customData: [
                "section": "financial",
                "showAdvancedMetrics": true,
                "refreshInterval": 30
            ]
        )
    ]
)
```

## ⚡ Layer 5 (platform technical)

Use real L5 APIs only (e.g. `platformIOSHapticFeedback`, split-view / navigation-stack `_L5` helpers). Generic `platformMemoryOptimization` / `platformRenderingOptimization` / `platformViewCaching` names are **not** in Sources — see [README_Layer5_Performance.md](README_Layer5_Performance.md) (#425).

## 🔍 Debugging

```swift
// Check if hints are processed
print("Hint count: \(enhancedHints.extensibleHints.count)")
print("Custom data: \(enhancedHints.allCustomData)")

// Extract preferences
let layoutPrefs = HintProcessingEngine.extractLayoutPreferences(from: enhancedHints)
```

## 📱 Platform-Specific

```swift
#if os(iOS)
// iOS-specific hints
let iosHint = CustomHint(
    hintType: "ios.optimized",
    customData: ["preferredSpacing": 16]
)
#elseif os(macOS)
// macOS-specific hints
let macosHint = CustomHint(
    hintType: "macos.optimized",
    customData: ["preferredSpacing": 20]
)
#endif
```

## 🚨 Common Issues

### **Hints Not Working**
- ✅ Inherit from `CustomHint` class
- ❌ Don't create custom structs
- ✅ Use appropriate priority levels

### **Performance Issues**
- Start with `.complexity = .simple`
- Apply optimizations gradually
- Test on real devices

### **Platform Differences**
- Use `.presentationPreference = .automatic`
- Let framework handle platform adaptation
- Use conditional compilation for specific needs

## 📚 Full Documentation

- **[DeveloperExtensionGuide.md](DeveloperExtensionGuide.md)** - Complete guide
- **[HintsSystemExtensibility.md](HintsSystemExtensibility.md)** - Advanced hints
- **[README_UsageExamples.md](README_UsageExamples.md)** - Examples and patterns

## 💡 Best Practices

1. **Start Simple**: Use basic hints first, enhance progressively
2. **Meaningful Names**: Use descriptive hint types and data keys
3. **Appropriate Priority**: Don't overuse `.critical` priority
4. **Platform Agnostic**: Let framework handle platform differences
5. **Test Thoroughly**: Verify on both iOS and macOS

## 🔗 Quick Links

- **Framework Functions**: [FunctionIndex.md](FunctionIndex.md)
- **Architecture**: [README_6LayerArchitecture.md](README_6LayerArchitecture.md)
- **Examples**: [README_UsageExamples.md](README_UsageExamples.md)
