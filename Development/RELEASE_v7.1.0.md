# SixLayer Framework v7.1.0 Release Documentation

**Release Date**: January 7, 2026  
**Release Type**: Minor (Color Resolution System from Hints Files)  
**Previous Release**: v7.0.2  
**Status**: ✅ **COMPLETE**

---

## 🎯 Release Summary

Minor release adding a comprehensive color resolution system from hints files. Developers can now use `ItemBadge` and `ItemIcon` components that automatically resolve colors from hints file configuration, and optionally add badges to card components.

---

## 🆕 What's New

### **Extended Item Color Provider Types (Issue #144)**

#### **New Provider Types**
- **`colorName`**: Read color name directly from a property (supports JSON decoding)
- **`fileExtension`**: Map file extension to color name
- Existing `severity` and `status` types continue to work

#### **Hints File Configuration**
```json
{
  "_defaults": {
    "_itemColorProvider": {
      "type": "colorName",
      "property": "color"
    }
  }
}
```

Or for file extensions:
```json
{
  "_defaults": {
    "_itemColorProvider": {
      "type": "fileExtension",
      "property": "fileExtension",
      "mapping": {
        "pdf": "red",
        "jpg": "blue",
        "png": "blue",
        "doc": "blue",
        "xls": "green",
        "txt": "gray"
      }
    }
  }
}
```

### **ItemBadge Component**

New badge component that automatically resolves colors from hints files:

```swift
ItemBadge(
    item: category,
    icon: category.icon,
    text: category.name,
    style: .subtle,
    hints: hints
)
```

**Styles:**
- `.default` - Colored background, white icon/text
- `.outline` - Colored border, colored icon/text
- `.subtle` - Light colored background, colored icon/text
- `.iconOnly` - Just icon with colored foreground

### **ItemIcon Component**

New icon component that automatically resolves colors from hints files:

```swift
ItemIcon(
    item: document,
    iconName: document.iconName,
    size: 20,
    hints: hints
)
```

### **Optional Badge Content in Cards**

All card components now support optional `badgeContent`:

```swift
ExpandableCardComponent(
    item: item,
    layoutDecision: layoutDecision,
    strategy: strategy,
    hints: hints,
    // ... other parameters ...
    badgeContent: { item in
        ItemBadge(
            item: item,
            text: item.category,
            hints: hints
        )
    }
)
```

**Supported Cards:**
- `ExpandableCardComponent`
- `SimpleCardComponent`
- `ListCardComponent`

---

## 🔧 Technical Changes

### **DataHintsLoader Updates**

#### **ItemColorProviderConfig**
- Added `property: String?` field for colorName and fileExtension types
- Extended to support new provider types

#### **createItemColorProvider**
- Handles `colorName` type: reads color name from property (with JSON decoding support)
- Handles `fileExtension` type: maps file extension to color using mapping dictionary
- Maintains backward compatibility with existing `severity` and `status` types

### **New Components**

#### **ItemBadge**
- Automatically resolves color using `CardDisplayHelper.extractColor()`
- Four style options for different use cases
- Uses hints file configuration when available

#### **ItemIcon**
- Automatically resolves color using `CardDisplayHelper.extractColor()`
- Configurable size
- Uses hints file configuration when available

### **Card Component Updates**

All card components now have:
- Optional `badgeContent: ((Item) -> AnyView)?` parameter
- Two initializers: one with `AnyView` closure, one with `@ViewBuilder` for convenience
- Badge content displayed when provided

### **Hints Generator Updates**

- Updated `__example` section with examples for new provider types
- Includes comments explaining colorName and fileExtension usage

---

## 📝 Migration Guide

### **No Breaking Changes**
This is a non-breaking addition. Existing code continues to work unchanged.

### **Using New Features**

#### **In Hints Files**
Add to `_defaults` section:
```json
{
  "_defaults": {
    "_itemColorProvider": {
      "type": "colorName",
      "property": "color"
    }
  }
}
```

#### **In Code**
```swift
// Standalone badge
ItemBadge(
    item: category,
    icon: category.icon,
    text: category.name,
    style: .subtle,
    hints: hints
)

// Standalone icon
ItemIcon(
    item: document,
    iconName: document.iconName,
    hints: hints
)

// Badge in card
ExpandableCardComponent(
    item: item,
    // ... other parameters ...
    badgeContent: { item in
        ItemBadge(item: item, text: item.category, hints: hints)
    }
)
```

---

## 🧪 Testing

### **New Tests**
- `ItemColorProviderExtendedTypesTests` - Tests for colorName and fileExtension provider types
- `ItemBadgeTests` - Tests for ItemBadge component with all styles
- `ItemIconTests` - Tests for ItemIcon component
- `CardBadgeContentTests` - Tests for optional badgeContent in cards

---

## 📚 Documentation

- Updated hints generator to include examples for new provider types
- All components documented with usage examples

---

## 🔗 Related Issues

- Resolves Issue #144: Add Color Resolution System from Hints Files for Badge/Chip Components

---

## 📦 Files Changed

- `Framework/Sources/Core/Models/DataHintsLoader.swift` - Extended ItemColorProviderConfig and createItemColorProvider
- `Framework/Sources/Components/Collections/ItemBadge.swift` - New component
- `Framework/Sources/Components/Collections/ItemIcon.swift` - New component
- `Framework/Sources/Layers/Layer4-Component/IntelligentCardExpansionLayer4.swift` - Added badgeContent support
- `scripts/generate_hints_from_models.swift` - Updated examples
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Collections/ItemColorProviderExtendedTypesTests.swift` - New tests
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Collections/ItemBadgeTests.swift` - New tests
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Collections/ItemIconTests.swift` - New tests
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Collections/CardBadgeContentTests.swift` - New tests

---

## ✅ Verification Checklist

- [x] All tests pass
- [x] Code compiles without errors
- [x] Documentation updated
- [x] Hints generator includes examples
- [x] All provider types supported
- [x] Card components support badges
- [x] Backward compatible

---

## 🚀 Next Steps

- Continue monitoring for any issues with color resolution
- Consider adding support for additional badge styles if needed
- Explore integration with more card types

