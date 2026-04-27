# SixLayer Framework v7.7.2 Release Documentation

**Release Date**: April 27, 2026  
**Release Type**: Patch  
**Previous Release**: v7.7.1  
**Status**: Released

---

## 🎯 Release Summary

v7.7.2 fixes the `LocationService` main-thread CoreLocation services-enabled check, wires `DynamicImageField` into the image/photo picker flow with `DynamicFormState` updates, clarifies non-mutative Layer 1 dynamic field preview documentation, and refreshes release metadata required by the release automation.

---

## 🆕 Confirmed in v7.7.2 (implemented)

### **Release checklist metadata consistency**

- Updated the release history index to list v7.7.2 as the current release.
- Added this individual release note file for release automation and consumer documentation.
- Updated top-level, framework, examples, project status, package, and AI-agent version references to v7.7.2.

### **Location service threading fix (Issue #258)**

- Moved the potentially blocking `CLLocationManager.locationServicesEnabled()` check off the main actor.
- Preserved the existing public `LocationServiceProtocol` API while keeping synchronous authorization paths responsive.
- Centralized authorization predicates so iOS and macOS behavior stay aligned.

### **Dynamic image field state integration (Issue #265)**

- Wired `DynamicImageField` to the image/photo selection flow and `DynamicFormState`.
- Stores selected iOS/macOS images as JPEG `Data` in form state.
- Keeps non-image-picker platforms explicit with a localized unavailable message while preserving existing `Data` previews.

### **Layer 1 preview documentation (Issue #267)**

- Clarified that Layer 1 semantic field preview helpers are non-mutative previews, not `DynamicFormState`-backed forms.
- Added doc comments for `createSimpleFieldView` and both `createFieldView` overloads.

---

## ✅ Resolved GitHub issues

- **Issue #270** — v7.7.2 release checklist metadata failures addressed.
- **Issue #267** — Layer 1 dynamic field preview documentation clarified.
- **Issue #265** — `DynamicImageField` wired to image/photo flow and `DynamicFormState`.
- **Issue #258** — `LocationService` main-thread location services check fixed.

---

## 🔗 References

- [RELEASE_v7.7.1.md](RELEASE_v7.7.1.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
