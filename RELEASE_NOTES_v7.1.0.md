# SixLayer Framework v7.1.0 Release Notes

**Release Date**: January 7, 2026  
**Release Type**: Minor (Color Resolution System from Hints Files)  
**Previous Version**: v7.0.2

## 🎯 Release Summary

This minor release adds a comprehensive color resolution system from hints files, enabling developers to use `ItemBadge` and `ItemIcon` components that automatically resolve colors from hints file configuration. Card components now support optional badge content, providing a flexible way to display badges and icons with automatic color resolution based on hints file configuration.

## 🆕 What's New

### **Extended Item Color Provider Types (Issue #144)**

#### **New Provider Types**

Two new provider types have been added to the item color provider system:

1. **`colorName`**: Read color name directly from a property (supports JSON decoding)
   - Reads a color name string from a model property
   - Supports both direct property access and JSON decoding for nested properties
   - Example: If a model has a `color` property with value `"blue"`, it will resolve to `Color.blue`

2. **`fileExtension`**: Map file extension to color name
   - Maps file extensions (like `"pdf"`, `"jpg"`, `"png"`) to color names
   - Uses a configurable mapping dictionary
   - Example: `"pdf"` → `"red"`, `"jpg"` → `"blue"`, `"png"` → `"blue"`

#### **Existing Provider Types**

The following provider types continue to work as before:
- **`severity`**: Map severity levels to colors (e.g., `"high"` → `"red"`, `"low"` → `"green"`)
- **`status`**: Map status values to colors (e.g., `"active"` → `"green"`, `"inactive"` → `"gray"`)

#### **Hints File Configuration**

##### **Color Name Provider**

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

This configuration will:
- Read the `color` property from each item
- Use the value as a color name (e.g., `"blue"` → `Color.blue`)
- Support JSON decoding for nested properties (e.g., `"metadata.color"`)

##### **File Extension Provider**

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

This configuration will:
- Read the `fileExtension` property from each item
- Map the extension to a color using the mapping dictionary
- Use the mapped color name to resolve the actual color

### **ItemBadge Component**

A new badge component that automatically resolves colors from hints files:

```swift
ItemBadge(
    item: category,
    icon: category.icon,
    text: category.name,
    style: .subtle,
    hints: hints
)
```

#### **Badge Styles**

Four badge styles are available:

1. **`.default`**: Colored background with white icon/text
   - Best for: Prominent badges that need to stand out
   - Example: Status indicators, priority badges

2. **`.outline`**: Colored border with colored icon/text
   - Best for: Subtle badges that don't dominate the UI
   - Example: Category tags, type indicators

3. **`.subtle`**: Light colored background with colored icon/text
   - Best for: Soft badges that blend with content
   - Example: Metadata badges, secondary information

4. **`.iconOnly`**: Just icon with colored foreground
   - Best for: Minimal badges with just an icon
   - Example: Quick status indicators, type icons

#### **Automatic Color Resolution**

`ItemBadge` automatically resolves colors using:
1. `PresentationHints` color configuration (from hints files or code)
2. `CardDisplayHelper.extractColor()` for consistent color resolution
3. Falls back to default colors if no configuration is provided

### **ItemIcon Component**

A new icon component that automatically resolves colors from hints files:

```swift
ItemIcon(
    item: document,
    iconName: document.iconName,
    size: 20,
    hints: hints
)
```

#### **Features**

- **Automatic Color Resolution**: Uses `CardDisplayHelper.extractColor()` to resolve colors
- **Configurable Size**: Set icon size via `size` parameter
- **Hints File Integration**: Automatically uses color configuration from hints files
- **Consistent Styling**: Matches framework's color resolution system

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

#### **Supported Cards**

- **`ExpandableCardComponent`**: Expandable cards with optional badge content
- **`SimpleCardComponent`**: Simple cards with optional badge content
- **`ListCardComponent`**: List-style cards with optional badge content

#### **Badge Content API**

Two initializer options are available:

1. **`AnyView` closure**: Maximum flexibility
   ```swift
   badgeContent: { item in
       AnyView(ItemBadge(item: item, text: item.category, hints: hints))
   }
   ```

2. **`@ViewBuilder` closure**: More convenient syntax
   ```swift
   badgeContent: { item in
       ItemBadge(item: item, text: item.category, hints: hints)
   }
   ```

## 🔧 Technical Changes

### **DataHintsLoader Updates**

#### **ItemColorProviderConfig Extensions**

Added `property: String?` field to `ItemColorProviderConfig`:
- Used by `colorName` and `fileExtension` provider types
- Specifies which property to read from the item
- Supports dot notation for nested properties (e.g., `"metadata.color"`)

#### **createItemColorProvider Updates**

The `createItemColorProvider` function now handles:

1. **`colorName` type**:
   - Reads color name from specified property
   - Supports JSON decoding for nested properties
   - Converts color name string to `Color` object

2. **`fileExtension` type**:
   - Reads file extension from specified property
   - Maps extension to color using mapping dictionary
   - Converts mapped color name to `Color` object

3. **Backward compatibility**:
   - Existing `severity` and `status` types continue to work
   - No breaking changes to existing functionality

### **New Components**

#### **ItemBadge**

- **Location**: `Framework/Sources/Components/Collections/ItemBadge.swift`
- **Features**:
  - Automatic color resolution using `CardDisplayHelper.extractColor()`
  - Four badge styles for different use cases
  - Hints file integration for color configuration
  - Icon and text support

#### **ItemIcon**

- **Location**: `Framework/Sources/Components/Collections/ItemIcon.swift`
- **Features**:
  - Automatic color resolution using `CardDisplayHelper.extractColor()`
  - Configurable size
  - Hints file integration for color configuration
  - Simple icon display with automatic coloring

### **Card Component Updates**

All card components now have:
- Optional `badgeContent: ((Item) -> AnyView)?` parameter
- Two initializer overloads:
  - One with `AnyView` closure for maximum flexibility
  - One with `@ViewBuilder` closure for convenient syntax
- Badge content displayed when provided

### **Hints Generator Updates**

The hints generation script (`generate_hints_from_models.swift`) now:
- Updated `__example` section with examples for new provider types
- Includes comments explaining `colorName` and `fileExtension` usage
- Shows mapping dictionary format for file extension provider

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
        "png": "blue"
      }
    }
  }
}
```

#### **In Code**

##### **Standalone Badge**

```swift
ItemBadge(
    item: category,
    icon: category.icon,
    text: category.name,
    style: .subtle,
    hints: hints
)
```

##### **Standalone Icon**

```swift
ItemIcon(
    item: document,
    iconName: document.iconName,
    size: 20,
    hints: hints
)
```

##### **Badge in Card**

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

## 🧪 Testing

### **New Test Suites**

1. **`ItemColorProviderExtendedTypesTests`**:
   - Tests for `colorName` provider type
   - Tests for `fileExtension` provider type
   - Tests for JSON decoding support
   - Tests for mapping dictionary functionality

2. **`ItemBadgeTests`**:
   - Tests for all four badge styles
   - Tests for automatic color resolution
   - Tests for hints file integration
   - Tests for icon and text display

3. **`ItemIconTests`**:
   - Tests for icon display
   - Tests for automatic color resolution
   - Tests for hints file integration
   - Tests for size configuration

4. **`CardBadgeContentTests`**:
   - Tests for optional badge content in cards
   - Tests for badge content with different card types
   - Tests for badge content with hints file configuration

## 📚 Related Documentation

- [RELEASE_v7.0.0.md](Development/RELEASE_v7.0.0.md) - Card color configuration system
- [RELEASE_v7.0.1.md](Development/RELEASE_v7.0.1.md) - Hints file color configuration support

## 🔗 Related Issues

- **Issue #144**: Add Color Resolution System from Hints Files for Badge/Chip Components - ✅ Complete

## 📦 Files Changed

- `Framework/Sources/Core/Models/DataHintsLoader.swift` - Extended `ItemColorProviderConfig` and `createItemColorProvider`
- `Framework/Sources/Components/Collections/ItemBadge.swift` - New component
- `Framework/Sources/Components/Collections/ItemIcon.swift` - New component
- `Framework/Sources/Layers/Layer4-Component/IntelligentCardExpansionLayer4.swift` - Added `badgeContent` support
- `scripts/generate_hints_from_models.swift` - Updated examples
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Collections/ItemColorProviderExtendedTypesTests.swift` - New tests
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Collections/ItemBadgeTests.swift` - New tests
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Collections/ItemIconTests.swift` - New tests
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Collections/CardBadgeContentTests.swift` - New tests

## ✅ Verification Checklist

- [x] All tests pass
- [x] Code compiles without errors
- [x] Documentation updated
- [x] Hints generator includes examples
- [x] All provider types supported
- [x] Card components support badges
- [x] Backward compatible
- [x] Color resolution works correctly

## 🎯 Next Steps

- Continue monitoring for any issues with color resolution
- Consider adding support for additional badge styles if needed
- Explore integration with more card types
- Gather user feedback on badge and icon usage patterns

---

**Version**: 7.1.0  
**Release Date**: January 7, 2026  
**Previous Version**: v7.0.2  
**Status**: Production Ready 🚀
