# AI Agent Guide for SixLayer Framework v4.5.0

This document provides guidance for AI assistants working with the SixLayer Framework v4.5.0. **Always read this version-specific guide first** before attempting to help with this framework.

## 🎯 Quick Start

1. **Identify the current framework version** from the project's Package.swift or release tags
2. **Read this AI_AGENT_v4.5.0.md file** for version-specific guidance
3. **Follow the guidelines** for architecture, patterns, and best practices

## 🆕 What's New in v4.5.0

### CardDisplayHelper Hint System - Major Enhancement
The most significant improvement in v4.5.0 is the introduction of a configurable hint system that solves the "⭐ Item" display problem in `GenericItemCollectionView`.

#### Problem Solved
Previously, when custom data types didn't conform to `CardDisplayable`, they would display as generic "⭐ Item" placeholders, making the collection view unusable.

#### Solution: Configurable Property Mapping
The new hint system allows developers to specify which properties contain meaningful display information:

```swift
let hints = PresentationHints(
    customPreferences: [
        "itemTitleProperty": "customTitle",
        "itemSubtitleProperty": "customSubtitle", 
        "itemIconProperty": "customIcon",
        "itemColorProperty": "customColor"
    ]
)

let collectionView = GenericItemCollectionView(
    items: customItems,
    hints: hints
)
```

## 🏗️ Framework Architecture Overview

The SixLayer Framework follows a **layered architecture** where each layer builds upon the previous:

1. **Layer 1**: Basic UI Components (Buttons, TextFields, etc.)
2. **Layer 2**: Composite Components (Forms, Lists, etc.)
3. **Layer 3**: Layout Systems (Grids, Stacks, etc.)
4. **Layer 4**: Navigation Patterns (Tabs, Sheets, etc.)
5. **Layer 5**: Accessibility Features (VoiceOver, Switch Control, etc.)
6. **Layer 6**: Advanced Capabilities (OCR, ML, etc.)

## 🎨 CardDisplayHelper Usage Patterns

### For Custom Data Types
When working with custom data types that don't conform to `CardDisplayable`, use the hint system:

```swift
struct Product {
    let productName: String
    let productDescription: String?
    let productIcon: String
    let brandColor: Color
}

// Configure hints to map custom properties
let hints = PresentationHints(
    customPreferences: [
        "itemTitleProperty": "productName",
        "itemSubtitleProperty": "productDescription",
        "itemIconProperty": "productIcon", 
        "itemColorProperty": "brandColor"
    ]
)

let products = [Product(...)]
let view = GenericItemCollectionView(items: products, hints: hints)
// Now displays "Product Name" instead of "⭐ Item"
```

### For Standard Data Types
Standard property names work automatically without configuration:

```swift
struct StandardItem {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
}

let items = [StandardItem(...)]
let view = GenericItemCollectionView(items: items, hints: nil)
// Automatically discovers title, subtitle, icon, color properties
```

### Fallback Priority System
The CardDisplayHelper follows this priority order:

1. **Custom property names** specified in hints (developer's explicit intent)
2. **CardDisplayable protocol** (if item conforms)
3. **Reflection-based discovery** of common property names
4. **Generic fallback** ("Item")

## ⚠️ Critical Guidelines

### Always Follow These Rules:
- **Read this version-specific guide first** - Architecture and patterns evolve between versions
- **Use functional programming patterns** - Avoid mutable state where possible
- **Write security-conscious code** - Validate inputs, handle errors gracefully
- **Write cross-platform code** - Support iOS, macOS, and visionOS
- **Follow TDD principles** - Write tests before implementing features
- **Maintain 100% test coverage** - All new code must be tested

### Testing Requirements:
- **Run the full xcodebuild test suite before any release** via `dbs-build --target test` - This is mandatory per project rules
- **All tests must pass** - No exceptions for releases
- **Test hint system functionality** - Verify custom property mapping works
- **Test fallback scenarios** - Ensure reflection works when hints fail

## 🔧 Common Patterns

### GenericItemCollectionView Usage
```swift
// For custom data types - use hints
let customHints = PresentationHints(
    customPreferences: [
        "itemTitleProperty": "yourTitleProperty",
        "itemSubtitleProperty": "yourSubtitleProperty"
    ]
)
let customView = GenericItemCollectionView(items: customItems, hints: customHints)

// For standard data types - hints optional
let standardView = GenericItemCollectionView(items: standardItems, hints: nil)
```

### Card Component Integration
All card components now support the hint system:

```swift
// SimpleCardComponent
let simpleCard = SimpleCardComponent(
    item: customItem,
    layoutDecision: decision,
    hints: hints,  // New parameter
    onItemSelected: { _ in },
    onItemDeleted: { _ in },
    onItemEdited: { _ in }
)

// ListCardComponent  
let listCard = ListCardComponent(
    item: customItem,
    layoutDecision: decision,
    hints: hints,  // New parameter
    onItemSelected: { _ in },
    onItemDeleted: { _ in },
    onItemEdited: { _ in }
)

// MasonryCardComponent
let masonryCard = MasonryCardComponent(
    item: customItem,
    layoutDecision: decision,
    hints: hints,  // New parameter
    onItemSelected: { _ in },
    onItemDeleted: { _ in },
    onItemEdited: { _ in }
)
```

## 🐛 Troubleshooting

### "⭐ Item" Still Appearing
If you're still seeing generic "⭐ Item" displays:

1. **Check if hints are provided** - Custom data types need hints
2. **Verify property names** - Ensure hint property names match actual properties
3. **Check property values** - Ensure properties contain non-empty strings
4. **Test with CardDisplayable** - Consider making your type conform to the protocol

### Reflection Not Working
If reflection isn't finding properties:

1. **Check property names** - Use common names like `title`, `name`, `label`
2. **Verify property types** - Ensure properties are `String` type
3. **Check property values** - Ensure properties are not empty
4. **Use hints as fallback** - Specify exact property names in hints

## 📚 Key Files to Understand

### Core Files
- `Framework/Sources/Core/Models/CardDisplayable.swift` - CardDisplayHelper implementation
- `Framework/Sources/Layers/Layer1-Semantic/PlatformSemanticLayer1.swift` - GenericItemCollectionView
- `Framework/Sources/Layers/Layer4-Component/IntelligentCardExpansionLayer4.swift` - Card components

### Test Files
- `Development/Tests/SixLayerFrameworkTests/Features/Collections/CardDisplayHelperHintTests.swift` - Hint system tests

## 🚀 Best Practices

### When to Use Hints
- **Custom data types** with non-standard property names
- **Legacy data models** that can't be modified
- **Third-party data structures** you don't control

### When Not to Use Hints
- **Standard data types** with common property names
- **Types that conform to CardDisplayable** - protocol takes precedence
- **Simple data structures** - reflection usually works fine

### Performance Considerations
- **Hints are lightweight** - minimal performance impact
- **Reflection is optimized** - efficient property discovery
- **Caching is automatic** - repeated lookups are fast

## 🔄 Migration from Previous Versions

### Existing Code
No changes required - existing code continues to work with improved fallback behavior.

### New Custom Types
Add hints to get meaningful display:

```swift
// Before (shows "⭐ Item")
let view = GenericItemCollectionView(items: customItems)

// After (shows meaningful content)
let hints = PresentationHints(customPreferences: [
    "itemTitleProperty": "yourTitleProperty"
])
let view = GenericItemCollectionView(items: customItems, hints: hints)
```

## 📖 Additional Resources

- **Release Notes**: `Development/RELEASE_v4.5.0.md`
- **API Documentation**: Generated from inline code comments
- **Test Examples**: See test files for usage patterns
- **Framework Rules**: `PROJECT_RULES.md` and `.cursor/rules/mandatory.mdc`

---

**Remember**: This version significantly improves the developer experience with `GenericItemCollectionView`. The hint system provides the flexibility needed for real-world applications while maintaining the simplicity that makes SixLayer Framework powerful.
