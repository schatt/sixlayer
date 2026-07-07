# SixLayer Framework v8.1.0 Release Documentation

**Release Date**: July 7, 2026  
**Release Type**: Minor  
**Previous Release**: v8.0.0  
**Status**: Release prep (`next`)

---

## 🎯 Release Summary

v8.1.0 is a **minor** release focused on **ViewInspector 0.10.x test infrastructure** and **hosted SwiftUI accessibility identifier collection** (Epic #233). Ships **`SixLayerViewInspectorTestKit`** for framework consumers (#327), typed inspect helpers aligned with ViewInspector 0.10 (#326), deep hierarchy walks and synthetic identifier support for hosted a11y probes (#314), and removal of deprecated `ViewInspector.Inspectable` conformances (#328). Also includes **field action layout fixes** for inline OCR/barcode controls and ViewInspector test stabilization on the integration branch.

---

## 🆕 Confirmed in v8.1.0 (implemented)

### **ViewInspector accessibility identifier collection (#314)**

- Deep ViewInspector hierarchy helpers in the test target (`findAllDeep`, button label resolution).
- Hosted identifier collection buckets with manual identifier preference and synthetic segment support for `DynamicFormFieldView`.
- Unified `<V: View>` accessibility test APIs in `AccessibilityTestUtilities` and `BaseTestClass`.
- ViewInspector-hosted hierarchy probes for forms, OCR, intelligent detail, and card components.

### **ViewInspector 0.10.x typed inspect API (#326)**

- `ViewInspectorWrapper` overload disambiguation after Inspectable removal.
- Disfavored typed helpers to prefer AnyView/ClassifiedView overloads where type erasure applies.
- Generalized progress indicator finder for typed inspection paths.

### **SixLayerViewInspectorTestKit export (#327)**

- New SPM product `SixLayerViewInspectorTestKit` with public `inspectView`, `withInspectedView*`, and `firstVStackInHierarchy` helpers.
- Xcode framework targets wired into ViewInspector and unit test schemes.
- TestKit README documenting inspection policy (identifiers vs typed ViewInspector vs AnyView unwrapping).

### **Remove deprecated Inspectable conformances (#328)**

- Deleted consumer-local `ViewInspectorInspectableConformances.swift`; ViewInspector 0.10 inspects custom views via reflection.
- Compiler warning cleanup for `'Inspectable' is deprecated` across shared test helpers.

### **Field actions and test stabilization (integration branch)**

- `FieldActionRenderer` renders inline actions when count fits `maxVisibleActions`; menu only on overflow or explicit `useActionMenu`.
- Default `useActionMenu` → `false` so dual OCR/barcode fields expose separate buttons for tests and accessibility.
- Barcode ViewInspector tests updated for full-hierarchy TextField + Button assertions.

---

## ✅ Resolved GitHub issues (milestone v8.1.0)

- **[Issue #314](https://github.com/schatt/sixlayer/issues/314)** — Fix ViewInspector accessibility identifier collection failures (Epic #233).
- **[Issue #326](https://github.com/schatt/sixlayer/issues/326)** — ViewInspector 0.10.x typed inspect helpers in ViewInspectorWrapper.
- **[Issue #327](https://github.com/schatt/sixlayer/issues/327)** — Export ViewInspector test helpers for framework consumers.
- **[Issue #328](https://github.com/schatt/sixlayer/issues/328)** — Remove deprecated ViewInspector.Inspectable conformances.

---

## ⚠️ Migration / consumer notes

- **ViewInspectorTestKit:** Add `SixLayerViewInspectorTestKit` as a test dependency when using framework `inspectView` / `withInspectedView` helpers; do not copy internal test-only hierarchy helpers from SixLayer's test target.
- **Inspectable conformances:** Remove any `extension MyView: ViewInspector.Inspectable {}` in consumer tests — no replacement needed on ViewInspector 0.10+.
- **Field actions:** Dual OCR/barcode fields now default to inline buttons; pass `useActionMenu: true` only when you want overflow menu presentation.
- **No intentional breaking public API changes** — minor release; test harness and field-action defaults are the main consumer-visible shifts.

---

## 🔗 References

- [RELEASE_v8.0.0.md](RELEASE_v8.0.0.md) — Previous major release.
- [RELEASES.md](RELEASES.md) — Release history index.
- [AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md) — Version-specific agent guide.
