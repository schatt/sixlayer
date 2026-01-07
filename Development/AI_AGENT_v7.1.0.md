# AI Agent Guide - SixLayer Framework v7.1.0

**Version**: v7.1.0  
**Release Date**: January 7, 2026  
**Release Type**: Minor (Color Resolution System from Hints Files)

---

## 🎯 What's New in v7.1.0

### **Extended Item Color Provider Types (Issue #144)**

The `_itemColorProvider` system now supports additional provider types:

- **`colorName`**: Read color name directly from a property (supports JSON decoding)
- **`fileExtension`**: Map file extension to color name
- Existing `severity` and `status` types continue to work

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
    // ... other parameters ...
    badgeContent: { item in
        ItemBadge(item: item, text: item.category, hints: hints)
    }
)
```

---

## 📚 For AI Assistants

### **Important Changes**

1. **Extended Provider Types**: `_itemColorProvider` now supports `colorName` and `fileExtension` types
2. **New Components**: `ItemBadge` and `ItemIcon` for automatic color resolution
3. **Card Integration**: Optional `badgeContent` parameter in all card components

### **Hints File Configuration**

#### **colorName Type**
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

#### **fileExtension Type**
```json
{
  "_defaults": {
    "_itemColorProvider": {
      "type": "fileExtension",
      "property": "fileExtension",
      "mapping": {
        "pdf": "red",
        "jpg": "blue",
        "png": "blue"
      }
    }
  }
}
```

### **Usage Patterns**

#### **Standalone Badge**
```swift
ItemBadge(
    item: category,
    icon: category.icon,
    text: category.name,
    style: .subtle,
    hints: hints
)
```

#### **Standalone Icon**
```swift
ItemIcon(
    item: document,
    iconName: document.iconName,
    hints: hints
)
```

#### **Badge in Card**
```swift
ExpandableCardComponent(
    item: item,
    layoutDecision: layoutDecision,
    strategy: strategy,
    hints: hints,
    badgeContent: { item in
        ItemBadge(item: item, text: item.category, hints: hints)
    }
)
```

---

## 🔗 Related Documentation

- [RELEASE_v7.1.0.md](../RELEASE_v7.1.0.md) - Complete release notes
- [AI_AGENT_v7.0.2.md](AI_AGENT_v7.0.2.md) - Previous version (Presentation Properties)
- [AI_AGENT_v7.0.1.md](AI_AGENT_v7.0.1.md) - Color Configuration

---

## ✅ Verification

- All tests pass
- Code compiles without errors
- Documentation updated
- Hints generator includes examples
- Backward compatible

