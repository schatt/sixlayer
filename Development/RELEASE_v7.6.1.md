# SixLayer Framework v7.6.1 Release Documentation

**Release Date**: April 19, 2026  
**Release Type**: Patch  
**Previous Release**: v7.6.0  
**Status**: Released

---

## 🎯 Release Summary

Patch release completing the Layer 1 `automaticCompliance` audit (GitHub **#245**, parity with **#243** / **gh-243**). Presentation APIs that previously used `automaticCompliance(named:)` or bare `.automaticCompliance()` in ways that suppressed or mis-stated accessibility roots now use the **`identifierName:`** overload (or anonymous shells only on caller-owned content), so generated `SixLayer.main.ui…` identifiers stay consistent with ViewInspector and UI test harnesses.

---

## 🆕 What's New

### **Layer 1 semantic and related surfaces**

- **`PlatformSemanticLayer1`**: Generic shells (`GenericContentView`, basic value/array, settings, content entry) aligned with anonymous or `identifierName:` compliance; avoids `NamedAutomaticComplianceModifier` on arbitrary runtime content.
- **`PlatformDataFrameAnalysisL1`**: Public APIs and internal analysis sections use `identifierName:` instead of `named:`; custom visualization overloads keep anonymous compliance on the caller wrapper only.
- **`PlatformSecurityL1`**: `platformPresentSecureTextField_L1` uses `identifierName:`; secure content and privacy-indicator paths remain anonymous where there is no stable framework-owned chrome.
- **`PlatformInternationalizationL1`**: Localized TextField, SecureField, and TextEditor use `identifierName:`; RTL and localized **content** wrappers remain anonymous.
- **`PlatformNotificationL1`**: Clarified documentation for the alert service shell (no `named:` APIs).

### **Tests**

- Issue **#245** ViewInspector guard tests updated for DataFrame, security/notification, internationalization, and semantic Layer 1 expectations (no `NamedAutomaticComplianceModifier` fingerprint where policy forbids it).

---

## ✅ Resolved GitHub issues

- **Issue #245** — Audit Layer 1 `automaticCompliance(named:)` usage (parity with #243); closed with migration to `identifierName:` and documented classifications per file.

---

## ⚠️ Migration / consumer notes

- **Accessibility identifier strings** may differ slightly where roots moved from `automaticCompliance(named:)` to `identifierName:`; UI tests that matched **exact** debug strings for the named modifier should assert on **stable** `SixLayer.main.ui…` prefixes or component segments instead of `NamedAutomaticComplianceModifier` log lines.
- **Swift Package** consumers: bump `from: "7.6.1"` (or exact revision) after tagging.

---

## 🔗 References

- **#243** — Layer 4 precedent for anonymous compliance on layout/navigation chrome.  
- **#222** — Anonymous `.automaticCompliance()` wrapper ID suppression behavior (`slfSuppressAnonymousAutomaticComplianceWrapperIdentifier`).
