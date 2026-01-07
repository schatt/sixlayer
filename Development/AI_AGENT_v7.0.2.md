# AI Agent Guide - SixLayer Framework v7.0.2

**Version**: v7.0.2  
**Release Date**: January 6, 2026  
**Release Type**: Patch (Hints File Presentation Properties Support)

---

## 🎯 What's New in v7.0.2

### **Hints File Presentation Properties Support (Issue #143)**

All `PresentationHints` properties are now supported in hints files, matching code-based functionality:

- **`_dataType`**: Configure data type hint (generic, text, number, date, image, boolean, collection, numeric, hierarchical, temporal)
- **`_complexity`**: Configure content complexity (simple, moderate, complex, veryComplex, advanced)
- **`_context`**: Configure presentation context (dashboard, browse, detail, edit, create, search, settings, profile, summary, list)
- **`_customPreferences`**: Configure custom preferences as dictionary
- **`_presentationPreference`**: Configure presentation preference (simple string or countBased object)

**Key Points:**
- Properties from hints files are used when code parameters are at their defaults
- Code parameters override hints file values when explicitly provided
- Hints generator preserves all presentation properties
- Comprehensive tests included

---

## 📚 For AI Assistants

### **Important Changes**

1. **Hints File Format**: All PresentationHints properties can now be configured in `_defaults` section
2. **Property Priority**: Code parameters override hints file values (same pattern as colors)
3. **Default Detection**: System checks if code parameters are at defaults before using hints file values

### **Example Hints File Configuration**

```json
{
  "_defaults": {
    "_dataType": "collection",
    "_complexity": "moderate",
    "_context": "browse",
    "_customPreferences": {
      "businessType": "vehicle",
      "formStyle": "multiStep"
    },
    "_presentationPreference": "list"
  }
}
```

### **Count-Based Presentation Preference**

```json
{
  "_defaults": {
    "_presentationPreference": {
      "type": "countBased",
      "lowCount": "list",
      "highCount": "grid",
      "threshold": 10
    }
  }
}
```

---

## 🔗 Related Documentation

- [RELEASE_v7.0.2.md](../RELEASE_v7.0.2.md) - Complete release notes
- [AI_AGENT_v7.0.1.md](AI_AGENT_v7.0.1.md) - Previous version (Color Configuration)
- [AI_AGENT_v7.0.0.md](AI_AGENT_v7.0.0.md) - Breaking Changes (Card Color Configuration)

---

## ✅ Verification

- All tests pass
- Code compiles without errors
- Documentation updated
- Hints generator includes examples

