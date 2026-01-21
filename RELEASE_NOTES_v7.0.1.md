# SixLayer Framework v7.0.1 Release Notes

**Release Date**: January 6, 2026  
**Release Type**: Patch (Hints File Color Configuration Support)  
**Previous Version**: v7.0.0

## 🎯 Release Summary

This patch release completes the color configuration feature introduced in v7.0.0 by adding support for storing color configuration in `.hints` files. Developers can now configure card colors declaratively in hints files, and the configuration is automatically loaded when creating `PresentationHints` from model names. This provides a more convenient way to manage color configuration without modifying code.

## 🆕 What's New

### **Hints File Color Configuration (Issue #142)**

#### **Color Configuration in Hints Files**

Two new properties can be added to hints files for color configuration:

1. **`_defaultColor`**: Store default color for card presentation
   - Supports named colors: `"blue"`, `"red"`, `"green"`, `"orange"`, etc.
   - Supports hex colors: `"#FF0000"`, `"#00FF00"`, `"#0000FF"`, etc.

2. **`_colorMapping`**: Store type-based color mapping
   - Format: `{"TypeName": "colorString"}`
   - Example: `{"Vehicle": "blue", "Task": "green", "Expense": "red"}`

#### **Automatic Loading**

Color configuration is automatically loaded when using the convenience initializer:

```swift
// Color configuration automatically loaded from hints file
let hints = await PresentationHints(modelName: "Vehicle")
// hints.defaultColor will be Color.blue (from hints file)
// hints.colorMapping will include Vehicle -> blue mapping
```

#### **Priority and Overrides**

- **Hints file configuration** is used when code parameters are at their defaults
- **Code parameters override** hints file values when explicitly provided
- This allows hints files to provide sensible defaults while still allowing code-level overrides

#### **Hints Generation Script**

The hints generation script (`generate_hints_from_models.swift`) now:
- Preserves `_defaultColor` and `_colorMapping` when generating/updating hints files
- Writes color configuration in the correct JSON order (after fields, before `__example`)
- Skips color config keys when tracking field order

## 🔧 Technical Changes

### **DataHintsLoader Updates**

#### **DataHintsResult Extensions**

Added two new optional properties to `DataHintsResult`:
- `defaultColor: String?` - Stores default color string from hints file
- `colorMapping: [String: String]?` - Stores type-to-color mapping from hints file

#### **parseHintsResult Updates**

The `parseHintsResult` function now:
- Parses `_defaultColor` from hints file JSON
- Parses `_colorMapping` from hints file JSON
- Skips color config keys when parsing field hints (prevents them from being treated as field properties)

#### **PresentationHints Convenience Initializer**

The convenience initializer (`PresentationHints(modelName:)`) now:
- Uses color configuration from hints files when code parameters are at their defaults
- Converts color strings to `Color` objects using `Color.fromString()`
- Allows code parameters to override hints file values when explicitly provided

### **Color String Parsing**

Added support for parsing color strings:
- **Named colors**: `"blue"`, `"red"`, `"green"`, etc. → Maps to SwiftUI `Color` constants
- **Hex colors**: `"#FF0000"`, `"#00FF00"`, etc. → Parses hex and creates `Color` from RGB values

## 📝 Usage Examples

### **Hints File Format**

```json
{
  "name": {
    "fieldType": "string",
    "isOptional": false
  },
  "make": {
    "fieldType": "string",
    "isOptional": true
  },
  "_defaultColor": "blue",
  "_colorMapping": {
    "Vehicle": "blue",
    "Task": "green",
    "Expense": "red"
  },
  "_sections": [...],
  "__example": {...}
}
```

### **Using Color Configuration**

#### **Automatic Loading from Hints File**

```swift
// Color configuration automatically loaded from hints file
let hints = await PresentationHints(modelName: "Vehicle")
// hints.defaultColor will be Color.blue (from hints file)
// hints.colorMapping will include Vehicle -> blue mapping

platformPresentItemCollection_L1(
    items: vehicles,
    hints: hints
)
```

#### **Overriding Hints File Configuration**

```swift
// Override hints file configuration with code parameters
let customHints = await PresentationHints(
    modelName: "Vehicle",
    defaultColor: .red  // Overrides hints file defaultColor
)

platformPresentItemCollection_L1(
    items: vehicles,
    hints: customHints
)
```

#### **Combining Hints File and Code Configuration**

```swift
// Use hints file colorMapping, but override defaultColor
let hints = await PresentationHints(
    modelName: "Vehicle",
    defaultColor: .gray  // Override default, but use colorMapping from hints file
)

platformPresentItemCollection_L1(
    items: vehicles,
    hints: hints
)
```

## 🔄 Migration Guide

### **No Migration Required**

This is a patch release with no breaking changes. Existing code continues to work as before.

### **Optional: Add Color Configuration to Hints Files**

If you want to store color configuration in hints files (recommended for better maintainability):

#### **Step 1: Add `_defaultColor` to Your Hints File**

```json
{
  "_defaultColor": "blue"
}
```

#### **Step 2: Add `_colorMapping` to Your Hints File**

```json
{
  "_colorMapping": {
    "Vehicle": "blue",
    "Task": "green",
    "Expense": "red"
  }
}
```

#### **Step 3: Use Convenience Initializer**

```swift
// Color configuration automatically loaded
let hints = await PresentationHints(modelName: "Vehicle")
```

#### **Step 4: Hints Generation Script Preserves Configuration**

The hints generation script will automatically preserve `_defaultColor` and `_colorMapping` when updating hints files, so you only need to add them once.

## 🧪 Testing

### **New Tests**

- **Color Configuration Parsing**: Tests verify that `_defaultColor` and `_colorMapping` are correctly parsed from hints files
- **Color String Conversion**: Tests verify that named colors and hex colors are correctly converted to `Color` objects
- **Priority and Overrides**: Tests verify that code parameters correctly override hints file values
- **Hints Generation Preservation**: Tests verify that the hints generation script preserves color configuration

### **Updated Tests**

- All existing color configuration tests continue to pass
- Tests updated to verify hints file integration works correctly

## 📚 Related Documentation

- [RELEASE_v7.0.0.md](Development/RELEASE_v7.0.0.md) - Breaking changes for card color configuration
- [AI_AGENT_v7.0.1.md](Development/AI_AGENT_v7.0.1.md) - AI agent guide for v7.0.1

## 🔗 Related Issues

- **Issue #142**: Move Card Color Configuration to PresentationHints System - ✅ Complete (hints file support added)

## 📦 Files Changed

- `Framework/Sources/Core/Models/DataHintsLoader.swift` - Added color configuration parsing and usage
- `scripts/generate_hints_from_models.swift` - Updated to preserve color configuration
- `Development/Tests/SixLayerFrameworkUnitTests/Core/Models/` - Added tests for hints file color configuration

## ✅ Verification Checklist

- [x] All tests pass
- [x] Code compiles without errors
- [x] Documentation updated
- [x] Hints generator preserves color configuration
- [x] Color string parsing works correctly
- [x] Code parameters override hints file values correctly
- [x] Backward compatibility maintained

## 🎯 Next Steps

- Continue monitoring for any issues with hints file color configuration
- Consider adding support for `itemColorProvider` in hints files (currently requires code)
- Explore additional color configuration options based on user feedback

---

**Version**: 7.0.1  
**Release Date**: January 6, 2026  
**Previous Version**: v7.0.0  
**Status**: Production Ready 🚀
