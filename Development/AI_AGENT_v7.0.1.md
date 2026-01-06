# AI Agent Guide for SixLayer Framework v7.0.1

**Version**: v7.0.1  
**Release Date**: January 6, 2026  
**Release Type**: Patch (Hints File Color Configuration Support)  
**Previous Version**: v7.0.0

---

## 🎯 Version Overview

This is a **patch release** that adds color configuration support to hints files. The breaking changes from v7.0.0 remain, but now developers can store color configuration in `.hints` files and have it automatically loaded when creating `PresentationHints` from model names.

---

## 🆕 What's New in v7.0.1

### **Hints File Color Configuration**

#### **Color Configuration in Hints Files**
- **`_defaultColor`**: Store default color for card presentation in hints files
  - Supports named colors: `"blue"`, `"red"`, `"green"`, etc.
  - Supports hex colors: `"#FF0000"`, `"#00FF00"`, etc.
- **`_colorMapping`**: Store type-based color mapping in hints files
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

## 🔧 Technical Details

### **DataHintsLoader Updates**

#### **DataHintsResult**
- Added `defaultColor: String?` property (parsed from `_defaultColor` in hints file)
- Added `colorMapping: [String: String]?` property (parsed from `_colorMapping` in hints file)

#### **parseHintsResult**
- Parses `_defaultColor` from hints file JSON (top-level key)
- Parses `_colorMapping` from hints file JSON (top-level key)
- Skips color config keys when parsing field hints (prevents treating them as field properties)

#### **PresentationHints Convenience Initializer**
- Uses color configuration from hints files via `DataHintsResult`
- Converts color strings to `Color` objects using `parseColorFromString`
- Parameter overrides take precedence over hints file configuration

### **Hints Generation Script**

#### **generate_hints_from_models.swift**
- Preserves `_defaultColor` and `_colorMapping` from existing hints files
- Writes color configuration in correct JSON order (after fields, before `__example`)
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
  "make": {
    "fieldType": "string",
    "isOptional": false
  },
  "_defaultColor": "blue",
  "_colorMapping": {
    "Vehicle": "blue",
    "Task": "green"
  },
  "_sections": [
    {
      "id": "default",
      "title": "Vehicle Information",
      "fields": ["name", "make"]
    }
  ],
  "__example": {
    "fieldType": "string",
    "isOptional": false,
    ...
  }
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

## ⚠️ Important Notes

### **Breaking Changes from v7.0.0**
All breaking changes from v7.0.0 remain:
- `CardDisplayable` protocol no longer includes `cardColor` property
- Color configuration must be done via `PresentationHints`
- See [AI_AGENT_v7.0.0.md](AI_AGENT_v7.0.0.md) for complete migration guide

### **Color Configuration Priority**
When creating `PresentationHints`:
1. **Parameter overrides** (highest priority)
2. **Hints file configuration** (if parameters not provided)
3. **Default values** (nil if not configured)

### **Color String Parsing**
- Named colors: `"blue"`, `"red"`, `"green"`, `"yellow"`, `"orange"`, `"purple"`, `"pink"`, `"gray"`, `"grey"`, `"black"`, `"white"`, `"cyan"`, `"mint"`, `"teal"`, `"indigo"`, `"brown"`
- Hex colors: `"#FF0000"`, `"#00FF00"`, `"#0000FF"` (supports 3, 6, or 8 character hex)
- Case-insensitive for named colors

---

## 🔄 Migration from v7.0.0

### **No Code Changes Required**
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

## 🧪 Testing Considerations

### **Color Configuration Testing**
- Test that color configuration is parsed correctly from hints files
- Test that parameter overrides take precedence over hints file configuration
- Test that hints generation script preserves color configuration
- Test color string parsing (named colors and hex)

### **Backward Compatibility**
- All existing code continues to work
- Hints files without color configuration work as before
- Parameter-based color configuration still works

---

## 📚 Related Documentation

- [RELEASE_v7.0.1.md](../Development/RELEASE_v7.0.1.md) - Complete release notes
- [AI_AGENT_v7.0.0.md](AI_AGENT_v7.0.0.md) - Breaking changes from v7.0.0
- [AI_AGENT.md](AI_AGENT.md) - Main AI agent guide

---

## 🎯 Key Takeaways for AI Assistants

1. **Color configuration can now be stored in hints files** - Use `_defaultColor` and `_colorMapping` top-level keys
2. **Parameter overrides take precedence** - When creating `PresentationHints`, parameters override hints file configuration
3. **Hints script preserves color config** - The generation script will preserve existing color configuration
4. **No breaking changes** - This is a patch release, all existing code continues to work
5. **Color string parsing** - Supports both named colors and hex format

---

## 🔗 See Also

- [RELEASE_v7.0.0.md](../Development/RELEASE_v7.0.0.md) - Breaking changes for card color configuration
- [Framework/Sources/Core/Models/DataHintsLoader.swift](../../Framework/Sources/Core/Models/DataHintsLoader.swift) - Implementation details
- [scripts/generate_hints_from_models.swift](../../scripts/generate_hints_from_models.swift) - Hints generation script

