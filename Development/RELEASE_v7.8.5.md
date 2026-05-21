# SixLayer Framework v7.8.5 Release Documentation

**Release Date**: May 21, 2026  
**Release Type**: Patch  
**Previous Release**: v7.8.4  
**Status**: Released

---

## 🎯 Release Summary

v7.8.5 is a **patch** release focused on **numeric form field display coercion** (#289): `DynamicNumberField` and `DynamicIntegerField` now format `Int`, `Double`, and `NSNumber` values already stored in `DynamicFormState` for display, while continuing to persist `String` from user edits. Also includes **XCUITest / Layer 4 test stabilization** for SD150 integration flows and **build hygiene** (deprecated `onChange` / `setOverrideTraitCollection` fixes, tautological test cleanup).

---

## 🆕 Confirmed in v7.8.5 (implemented)

### **Stored numeric display coercion (#289)**

- `DynamicFormStoredNumericDisplay.displayString(fromStoredValue:defaultValue:)` — formats stored values for text fields without scientific notation for typical magnitudes.
- `DynamicFormField.numericTextBinding(in:)` — read/write binding: numeric types on read, `String` on write.
- `DynamicNumberField` / `DynamicIntegerField` wired to the helper; draft storage key behavior documented in `FormAutoSaveGuide.md`.

**Usage:**

```swift
// Prefill from Core Data / DTO — Int/Double/NSNumber render in the field
formState.setValue(42.5, for: "amount")

// User edits still store String
```

### **Tests**

- `DynamicFormStoredNumericDisplayTests` — coercion and binding contract.
- SD150 / L4 XCUITest scroll, keyboard, and integration-toggle stabilization.
- Layer 4 assistive tests: `traitOverrides.accessibilityContrast` instead of deprecated `setOverrideTraitCollection`.

### **Build hygiene**

- `AdvancedFieldTypes`: macOS 14+ zero-parameter `onChange` for date/time pickers.
- `Layer1PresentationTests`: removed tautological `#expect(true)` placeholders.

---

## ✅ Resolved / advanced GitHub issues

- **[Issue #289](https://github.com/schatt/sixlayer/issues/289)** — Dynamic number/integer fields show blank when `fieldValues` holds numeric types.

---

## ⚠️ Migration / consumer notes

- **Hosts prefilling forms:** You may keep storing `Int`/`Double`/`NSNumber` for number fields; display coercion runs on read. Prefer `String` when you control the mapping if you want exact user-entered text round-tripped.
- **CarManager:** Bump SPM to `7.8.5` after tag when integrating framework changes.

---

## 🔗 References

- [RELEASE_v7.8.4.md](RELEASE_v7.8.4.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
