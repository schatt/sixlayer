# AI Agent Guide for SixLayer Framework v7.0.0

This guide summarizes the version-specific context for v7.0.0. **Always read this file before assisting with the framework at this version.**

> **Scope**: This guide is for AI assistants helping developers use or extend the framework (not for automated tooling).

## 🎯 Quick Start

1. Confirm the project is on **v7.0.0** (see `Package.swift` comment or release tags).
2. **📚 Start with the Sample App**: See `Development/Examples/TaskManagerSampleApp/` for a complete, canonical example of how to structure a real app using SixLayer Framework correctly.
3. **⚠️ BREAKING CHANGE**: `CardDisplayable` protocol no longer includes `cardColor` property. Color configuration is now done via `PresentationHints`.
4. Know that **models are now SwiftUI-free** and can be used in Intent extensions.
5. Apply TDD, DRY, DTRT, and Epistemology rules in every change.

## ⚠️ Breaking Changes in v7.0.0

### CardDisplayable Protocol Changes (Issue #142)

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

## 🆕 What's New in v7.0.0

### PresentationHints Color Configuration (Issue #142)

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

### Card Component Updates
- `ExpandableCardComponent` - now accepts and uses `hints` parameter
- `CoverFlowCardComponent` - now accepts and uses `hints` parameter
- All card components now properly pass hints to color extraction

## 🔄 What's Inherited from v6.8.0

### Platform Switch Consolidation (DRY Improvements)
- **PlatformStrategy Module**: Centralized platform-specific simple values
- **19 switch statements** consolidated into `PlatformStrategy`
- **4 duplicate functions** eliminated
- **Single source of truth** for platform-specific simple values

### Runtime Check Pattern Consistency
- **Consistent runtime capability checks** in `PlatformStrategy`
- Ensures platform-specific values are only returned when capabilities are actually available

## 📝 Important Patterns

### Using PresentationHints for Colors
When you need to configure colors for card display, use `PresentationHints`:

```swift
// ✅ Good: Configure colors in PresentationHints
let hints = PresentationHints(
    colorMapping: [ObjectIdentifier(MyType.self): .blue]
)

platformPresentItemCollection_L1(
    items: items,
    hints: hints
)

// ❌ Bad: Don't add cardColor to CardDisplayable
extension MyType: CardDisplayable {
    var cardColor: Color? { .blue }  // This no longer exists!
}
```

### Card Component Initialization
All card components that accept hints should receive them:

```swift
// ✅ Good: Pass hints to card components
ExpandableCardComponent(
    item: item,
    layoutDecision: layoutDecision,
    strategy: strategy,
    hints: hints,  // Required!
    isExpanded: false,
    // ...
)

// ❌ Bad: Missing hints parameter
ExpandableCardComponent(
    item: item,
    layoutDecision: layoutDecision,
    strategy: strategy,
    // Missing hints!
    isExpanded: false,
    // ...
)
```

## 🔗 Related Issues

- **Issue #142**: Move Card Color Configuration to PresentationHints System - ✅ Complete

## 📚 Key Files

- **PresentationHints**: `Framework/Sources/Core/Models/PlatformTypes.swift` - Color configuration properties
- **CardDisplayable**: `Framework/Sources/Core/Models/CardDisplayable.swift` - Protocol without cardColor
- **CardDisplayHelper**: `Framework/Sources/Core/Models/CardDisplayable.swift` - Color extraction with PresentationHints

## ⚠️ Migration Notes

### For Framework Consumers
- **Remove `cardColor` from all `CardDisplayable` conformances**
- **Configure colors via `PresentationHints` in presentation layer**
- **Update all card component initializations to include `hints` parameter**

### For Framework Developers
- **Never add `cardColor` back to `CardDisplayable` protocol**
- **Always pass `hints` to card components**
- **Use `PresentationHints` color configuration for all color decisions**


