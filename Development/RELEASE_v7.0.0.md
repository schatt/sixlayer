# SixLayer Framework v7.0.0 Release Documentation

**Release Date**: January 6, 2026  
**Release Type**: Major (Breaking Changes - Card Color Configuration)  
**Previous Release**: v6.8.0  
**Status**: ✅ **COMPLETE**

---

## 🎯 Release Summary

Major release moving card color configuration from `CardDisplayable` protocol to `PresentationHints` system. This breaking change makes models SwiftUI-free, enabling their use in Intent extensions and other non-UI contexts. Color decisions are now made at the presentation layer, following 6-layer architecture principles.

---

## ⚠️ Breaking Changes

### **CardDisplayable Protocol Changes (Issue #142)**

#### **Removed Property**
- **`cardColor: Color?`** - Removed from `CardDisplayable` protocol
- Models are now SwiftUI-free and can be used in Intent extensions

#### **Migration Required**
All code that implements `CardDisplayable` and provides `cardColor` must be updated:

**Before:**
```swift
extension Vehicle: CardDisplayable {
    var cardTitle: String { name }
    var cardColor: Color? { .blue }  // ❌ Removed
}
```

**After:**
```swift
extension Vehicle: CardDisplayable {
    var cardTitle: String { name }
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

---

## 🆕 New Features

### **PresentationHints Color Configuration (Issue #142)**

#### **Type-Based Color Mapping**
```swift
PresentationHints(
    colorMapping: [
        ObjectIdentifier(Vehicle.self): .blue,
        ObjectIdentifier(Expense.self): .green
    ]
)
```

#### **Per-Item Color Provider**
```swift
PresentationHints(
    itemColorProvider: { item in
        if let vehicle = item as? Vehicle {
            return vehicle.type == .car ? .blue : .red
        }
        return nil
    }
)
```

#### **Default Color**
```swift
PresentationHints(
    defaultColor: .gray
)
```

#### **Priority Order**
1. `colorMapping` (by type)
2. `itemColorProvider` (per-item)
3. `defaultColor` (fallback)
4. Legacy `customPreferences["itemColorProperty"]` (backward compatibility)
5. Legacy `customPreferences["itemColorDefault"]` (backward compatibility)
6. Reflection (look for color/tint/accent properties)
7. `nil` (no color)

---

## 🔧 Implementation Details

### **CardDisplayHelper.extractColor() Updates**
- Updated to use `PresentationHints` color configuration
- Maintains backward compatibility with legacy `customPreferences`
- Proper priority order ensures correct color selection

### **Card Component Updates**
- `ExpandableCardComponent` - now accepts and uses `hints` parameter
- `CoverFlowCardComponent` - now accepts and uses `hints` parameter
- `SimpleCardComponent`, `ListCardComponent`, `MasonryCardComponent` - already using hints

### **Files Updated**
- `Framework/Sources/Core/Models/PlatformTypes.swift` - Added color configuration to PresentationHints
- `Framework/Sources/Core/Models/CardDisplayable.swift` - Removed cardColor, updated extractColor
- `Framework/Sources/Layers/Layer4-Component/IntelligentCardExpansionLayer4.swift` - Pass hints to components
- `Framework/Examples/GenericTypes.swift` - Removed cardColor from examples
- All test files updated

---

## 🧪 Test Coverage

### **New Test Suite**
- `PresentationHintsColorConfigurationTests.swift` - Comprehensive test coverage for new color configuration system
- Tests for type-based mapping, per-item provider, default color, and priority order

### **Updated Tests**
- All existing tests updated to use `PresentationHints` instead of `cardColor`
- All test files updated to pass `hints` parameter to card components

---

## 📝 Migration Guide

### **Step 1: Remove cardColor from Models**
```swift
// Remove this:
var cardColor: Color? { .blue }
```

### **Step 2: Configure Colors in PresentationHints**
```swift
// Option 1: Type-based mapping
let hints = PresentationHints(
    colorMapping: [
        ObjectIdentifier(MyType.self): .blue
    ]
)

// Option 2: Per-item provider
let hints = PresentationHints(
    itemColorProvider: { item in
        // Custom logic based on item properties
        return .blue
    }
)

// Option 3: Default color
let hints = PresentationHints(
    defaultColor: .gray
)
```

### **Step 3: Pass Hints to Layer 1 Functions**
```swift
platformPresentItemCollection_L1(
    items: items,
    hints: hints
)
```

---

## 🔗 Related Issues

- **Issue #142**: Move Card Color Configuration to PresentationHints System - ✅ Complete

---

## ✅ Release Checklist

- [x] All tests pass
- [x] Breaking changes documented
- [x] Migration guide provided
- [x] Issue #142 closed
- [x] Documentation updated
- [x] Examples updated

---

**See [RELEASES.md](RELEASES.md) for complete release history.**

