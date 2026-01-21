# SixLayer Framework v7.0.0 Release Notes

**Release Date**: January 6, 2026  
**Release Type**: Major (Breaking Changes - Card Color Configuration)  
**Previous Version**: v6.8.0

## 🎯 Release Summary

This major release represents a significant architectural improvement by moving card color configuration from the model layer to the presentation layer. The `CardDisplayable` protocol no longer includes the `cardColor` property, making models SwiftUI-free and enabling their use in Intent extensions and other non-UI contexts. Color decisions are now made at the presentation layer using `PresentationHints`, following the 6-layer architecture principles.

## ⚠️ Breaking Changes

### **CardDisplayable Protocol Changes (Issue #142)**

#### **Removed Property: `cardColor`**

The `cardColor: Color?` property has been **removed** from the `CardDisplayable` protocol. This breaking change affects all code that implements `CardDisplayable` and provides a `cardColor` property.

**Before (v6.8.0 and earlier):**
```swift
extension Vehicle: CardDisplayable {
    var cardTitle: String { name }
    var cardSubtitle: String? { make }
    var cardColor: Color? { .blue }  // ❌ REMOVED - No longer available
}
```

**After (v7.0.0+):**
```swift
extension Vehicle: CardDisplayable {
    var cardTitle: String { name }
    var cardSubtitle: String? { make }
    // cardColor removed - configure via PresentationHints instead
}

// In presentation layer:
platformPresentItemCollection_L1(
    items: vehicles,
    hints: PresentationHints(
        colorMapping: [ObjectIdentifier(Vehicle.self): .blue]
    )
)
```

#### **Why This Breaking Change?**

1. **SwiftUI-Free Models**: Models can now be used in Intent extensions, WidgetKit extensions, and other non-UI contexts where SwiftUI is not available
2. **Architecture Compliance**: Color decisions belong at the presentation layer, not the model layer, following 6-layer architecture principles
3. **Separation of Concerns**: Models define data structure; presentation layer defines visual appearance
4. **Flexibility**: Multiple presentations of the same model can have different colors without modifying the model

## 🆕 New Features

### **PresentationHints Color Configuration System (Issue #142)**

A comprehensive color configuration system has been added to `PresentationHints`, providing multiple ways to specify card colors at the presentation layer.

#### **1. Type-Based Color Mapping**

Map colors to specific types using `ObjectIdentifier`:

```swift
PresentationHints(
    colorMapping: [
        ObjectIdentifier(Vehicle.self): .blue,
        ObjectIdentifier(Expense.self): .green,
        ObjectIdentifier(Task.self): .orange
    ]
)
```

**Benefits:**
- Simple and declarative
- Works well when all instances of a type should have the same color
- Type-safe using `ObjectIdentifier`

#### **2. Per-Item Color Provider**

Use a closure to determine color based on item properties:

```swift
PresentationHints(
    itemColorProvider: { item in
        if let vehicle = item as? Vehicle {
            return vehicle.type == .car ? .blue : .red
        }
        if let expense = item as? Expense {
            return expense.amount > 1000 ? .red : .green
        }
        return nil
    }
)
```

**Benefits:**
- Maximum flexibility
- Can base color on any item property
- Supports complex conditional logic

#### **3. Default Color**

Set a fallback color for items that don't match other rules:

```swift
PresentationHints(
    defaultColor: .gray
)
```

**Benefits:**
- Ensures all items have a color
- Simple fallback mechanism
- Works well with other color sources

#### **4. Color Resolution Priority Order**

The framework uses the following priority order when resolving colors:

1. **`colorMapping`** (by type) - Highest priority
2. **`itemColorProvider`** (per-item closure)
3. **`defaultColor`** (fallback)
4. **Legacy `customPreferences["itemColorProperty"]`** (backward compatibility)
5. **Legacy `customPreferences["itemColorDefault"]`** (backward compatibility)
6. **Reflection** (looks for `color`, `tint`, or `accent` properties)
7. **`nil`** (no color) - Lowest priority

This ensures backward compatibility while providing new, more powerful options.

## 🔧 Implementation Details

### **CardDisplayHelper.extractColor() Updates**

The `CardDisplayHelper.extractColor()` method has been completely refactored to:

- **Use `PresentationHints` color configuration** as the primary source
- **Maintain backward compatibility** with legacy `customPreferences` keys
- **Follow priority order** to ensure correct color selection
- **Support reflection** as a last resort for models with color properties

### **Card Component Updates**

All card components now accept and use the `hints` parameter:

- **`ExpandableCardComponent`** - Now accepts `hints` parameter and uses it for color resolution
- **`CoverFlowCardComponent`** - Now accepts `hints` parameter and uses it for color resolution
- **`SimpleCardComponent`** - Already using hints (no changes needed)
- **`ListCardComponent`** - Already using hints (no changes needed)
- **`MasonryCardComponent`** - Already using hints (no changes needed)

### **Files Updated**

- `Framework/Sources/Core/Models/PlatformTypes.swift` - Added color configuration properties to `PresentationHints`
- `Framework/Sources/Core/Models/CardDisplayable.swift` - Removed `cardColor` property, updated `extractColor()` method
- `Framework/Sources/Layers/Layer4-Component/IntelligentCardExpansionLayer4.swift` - Pass `hints` parameter to card components
- `Framework/Examples/GenericTypes.swift` - Removed `cardColor` from examples
- All test files updated to use `PresentationHints` instead of `cardColor`

## 🧪 Test Coverage

### **New Test Suite**

- **`PresentationHintsColorConfigurationTests.swift`** - Comprehensive test coverage for the new color configuration system
  - Tests for type-based mapping
  - Tests for per-item provider
  - Tests for default color
  - Tests for priority order
  - Tests for backward compatibility with legacy `customPreferences`

### **Updated Tests**

- All existing tests updated to use `PresentationHints` instead of `cardColor`
- All test files updated to pass `hints` parameter to card components
- All examples updated to demonstrate new color configuration patterns

## 📝 Migration Guide

### **Step 1: Remove `cardColor` from Models**

Remove the `cardColor` property from all `CardDisplayable` implementations:

```swift
// ❌ REMOVE THIS:
extension Vehicle: CardDisplayable {
    var cardColor: Color? { .blue }
}
```

### **Step 2: Configure Colors in PresentationHints**

Choose one of three approaches based on your needs:

#### **Option 1: Type-Based Mapping (Recommended for Simple Cases)**

```swift
let hints = PresentationHints(
    colorMapping: [
        ObjectIdentifier(Vehicle.self): .blue,
        ObjectIdentifier(Expense.self): .green
    ]
)

platformPresentItemCollection_L1(
    items: items,
    hints: hints
)
```

#### **Option 2: Per-Item Provider (Recommended for Complex Logic)**

```swift
let hints = PresentationHints(
    itemColorProvider: { item in
        if let vehicle = item as? Vehicle {
            return vehicle.type == .car ? .blue : .red
        }
        return nil
    }
)

platformPresentItemCollection_L1(
    items: items,
    hints: hints
)
```

#### **Option 3: Default Color (Recommended for Fallback)**

```swift
let hints = PresentationHints(
    defaultColor: .gray
)

platformPresentItemCollection_L1(
    items: items,
    hints: hints
)
```

### **Step 3: Pass Hints to Layer 1 Functions**

Ensure `PresentationHints` with color configuration is passed to all Layer 1 presentation functions:

```swift
platformPresentItemCollection_L1(
    items: items,
    hints: hints  // Must include color configuration
)
```

### **Migration Example: Complete Before/After**

**Before (v6.8.0):**
```swift
extension Vehicle: CardDisplayable {
    var cardTitle: String { name }
    var cardColor: Color? { .blue }
}

// Usage
platformPresentItemCollection_L1(
    items: vehicles,
    hints: PresentationHints()
)
```

**After (v7.0.0+):**
```swift
extension Vehicle: CardDisplayable {
    var cardTitle: String { name }
    // cardColor removed
}

// Usage
let hints = PresentationHints(
    colorMapping: [ObjectIdentifier(Vehicle.self): .blue]
)

platformPresentItemCollection_L1(
    items: vehicles,
    hints: hints
)
```

## 🎯 Benefits

### **For Developers**

1. **SwiftUI-Free Models**: Models can be used in Intent extensions, WidgetKit, and other non-UI contexts
2. **Flexible Color Configuration**: Multiple ways to specify colors based on your needs
3. **Better Architecture**: Color decisions at presentation layer, not model layer
4. **Backward Compatible**: Legacy `customPreferences` keys still work

### **For Framework**

1. **Architecture Compliance**: Follows 6-layer architecture principles
2. **Separation of Concerns**: Clear separation between data and presentation
3. **Extensibility**: Easy to add new color configuration options in the future
4. **Maintainability**: Centralized color resolution logic

## 📚 Related Issues

- **Issue #142**: Move Card Color Configuration to PresentationHints System - ✅ Complete

## ✅ Release Checklist

- [x] All tests pass
- [x] Breaking changes documented
- [x] Migration guide provided
- [x] Issue #142 closed
- [x] Documentation updated
- [x] Examples updated
- [x] Test coverage complete

---

**Version**: 7.0.0  
**Release Date**: January 6, 2026  
**Previous Version**: v6.8.0  
**Status**: Production Ready 🚀
