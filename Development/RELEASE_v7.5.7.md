# SixLayer Framework v7.5.7 Release Documentation

**Release Date**: February 2026  
**Release Type**: Patch  
**Previous Release**: v7.5.6  
**Status**: In preparation

---

## 🎯 Release Summary

Patch release. Fix duplicate visible field labels in DynamicFormView (Issue #189) and add `DynamicContentType.decimal` for decimal numeric fields.

---

## 🆕 What's New

### **Duplicate field labels fix (Issue #189)**
- **Parent-only label**: Only the parent `DynamicFormFieldView` shows the field label; per-type views no longer render a duplicate `Text(field.label)`.
- **Accessibility preserved**: Each field still exposes its label via `.accessibilityLabel(field.label)` and `identifierName`/environment for VoiceOver and testing.
- **ViewInspector**: `DynamicFormFieldView` conforms to `ViewInspector.Inspectable` so tests can assert each label appears exactly once.

### **DynamicContentType.decimal**
- **New type**: `DynamicContentType.decimal` added for decimal numeric fields (e.g. gallons, currency).
- **Routing**: Wired through `FieldViewTypeDeterminer`, `DynamicFieldComponents` (decimalPad text field), and Layer 1 platform switches; same default/value behavior as `.number` where appropriate.

---

## ✅ Backward Compatibility

**Fully backward compatible** — behavioral fix (no duplicate labels) and new enum case only; no breaking API changes.

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history
