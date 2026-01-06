# SixLayer Framework v7.0.1 Release Documentation

**Release Date**: January 6, 2026  
**Release Type**: Patch (Hints File Color Configuration Support)  
**Previous Release**: v7.0.0  
**Status**: ✅ **COMPLETE**

---

## 🎯 Release Summary

Patch release adding color configuration support to hints files. Developers can now store color configuration in `.hints` files and have it automatically loaded when creating `PresentationHints` from model names. This completes the color configuration feature introduced in v7.0.0.

---

## 🆕 What's New

### **Hints File Color Configuration (Issue #142)**

#### **Color Configuration in Hints Files**
- **`_defaultColor`**: Store default color for card presentation
  - Supports named colors: `"blue"`, `"red"`, `"green"`, etc.
  - Supports hex colors: `"#FF0000"`, `"#00FF00"`, etc.
- **`_colorMapping`**: Store type-based color mapping
  - Format: `{"TypeName": "colorString"}`
  - Example: `{"Vehicle": "blue", "Task": "green"}`

#### **Automatic Loading**
- Color configuration automatically loaded when using:
  ```swift
  let hints = await PresentationHints(modelName: "Vehicle")
  ```
- Color configuration from hints files is used unless overridden by parameters
- Parameter overrides take precedence over hints file configuration

#### **Hints Generation Script**
- Script now preserves `_defaultColor` and `_colorMapping` when generating/updating hints files
- Color configuration written in correct order (after fields, before `__example`)

---

## 🔧 Technical Changes

### **DataHintsLoader Updates**

#### **DataHintsResult**
- Added `defaultColor: String?` property
- Added `colorMapping: [String: String]?` property

#### **parseHintsResult**
- Parses `_defaultColor` from hints file JSON
- Parses `_colorMapping` from hints file JSON
- Skips color config keys when parsing field hints

#### **PresentationHints Convenience Initializer**
- Uses color configuration from hints files
- Converts color strings to `Color` objects
- Parameter overrides take precedence

### **Hints Generation Script**

#### **generate_hints_from_models.swift**
- Preserves `_defaultColor` and `_colorMapping` from existing hints files
- Writes color configuration in correct JSON order
- Skips color config keys when tracking field order

---

## 📝 Usage Examples

### **Hints File Format**

```json
{
  "name": {
    "fieldType": "string",
    "isOptional": false
  },
  "_defaultColor": "blue",
  "_colorMapping": {
    "Vehicle": "blue",
    "Task": "green"
  },
  "_sections": [...],
  "__example": {...}
}
```

### **Using Color Configuration**

```swift
// Color configuration automatically loaded from hints file
let hints = await PresentationHints(modelName: "Vehicle")
// hints.defaultColor will be Color.blue (from hints file)
// hints.colorMapping will include Vehicle -> blue mapping

// Override hints file configuration with parameters
let customHints = await PresentationHints(
    modelName: "Vehicle",
    defaultColor: .red  // Overrides hints file defaultColor
)
```

---

## 🔄 Migration Guide

### **No Migration Required**

This is a patch release with no breaking changes. Existing code continues to work as before.

### **Optional: Add Color Configuration to Hints Files**

If you want to store color configuration in hints files:

1. **Add `_defaultColor` to your hints file:**
   ```json
   "_defaultColor": "blue"
   ```

2. **Add `_colorMapping` to your hints file:**
   ```json
   "_colorMapping": {
     "Vehicle": "blue",
     "Task": "green"
   }
   ```

3. **The hints generation script will preserve these when updating hints files**

---

## 📚 Related Documentation

- [RELEASE_v7.0.0.md](RELEASE_v7.0.0.md) - Breaking changes for card color configuration
- [AI_AGENT_v7.0.1.md](AI_AGENT_v7.0.1.md) - AI agent guide for v7.0.1

---

## ✅ Testing

- ✅ Color configuration parsing from hints files
- ✅ Color configuration preservation in hints generation script
- ✅ Parameter overrides take precedence over hints file configuration
- ✅ Backward compatibility maintained

---

## 🎯 Next Steps

- Continue monitoring for any issues with hints file color configuration
- Consider adding support for `itemColorProvider` in hints files (currently requires code)

