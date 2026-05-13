# SixLayer Framework v7.8.0 Release Documentation

**Release Date**: May 13, 2026  
**Release Type**: Minor  
**Previous Release**: v7.7.2  
**Status**: In preparation

---

## 🎯 Release Summary

v7.8.0 is a **minor** release focused on a **presentation profiles** catalog, **item-collection** hint resolution and optional card-style list rows, optional **DynamicForm** draft storage keys, richer **PlatformImage** EXIF handling, and clearer **system-action** contracts (open URL and remote notifications). Milestone issues **#256**, **#272**, **#273**, **#275**, and **#277** are included.

---

## 🆕 Confirmed in v7.8.0 (implemented)

### **Presentation profiles catalog (Issue #277)**

- Ships shared `Hints/PresentationProfiles.hints`, **`PresentationProfilesCatalog`** (including **`globalPresentationProfilesCatalog`**), and **`PresentationHints(presentationProfileID:bundle:catalog:)`** so apps can centralize presentation defaults outside per-model `.hints`.
- Includes example JSON, cache reset, and unit tests (`PresentationProfilesCatalogTests`).
- Profile-driven sparse-grid geometry / Layer-2 wiring called out in the issue remains **follow-up work** (not part of the #277 closure).

### **Item collection presentation strategy (Issue #272)**

- Adds **`ItemCollectionPresentationStrategyResolver`** so `PresentationHints` / `PresentationPreference` (including automatic and `countBased`) drive **`platformPresentItemCollection_L1`** for both generic and `customItemView` overloads.
- Optional `hints.customPreferences["rowVisualStyle"] == "card"` applies default padded, rounded row chrome on the custom list path; see **`Framework/docs/README_Layer1_Semantic.md`** (Item Collections).

### **Optional draft storage key for dynamic forms (Issue #273)**

- Supports an optional **draft storage key** separate from `DynamicFormConfiguration.id`, so drafts can be partitioned or shared across configurations as needed.

### **PlatformImage EXIF read/write configuration (Issue #275)**

- EXIF-oriented APIs on **PlatformImage** (including writers that return a new image and stripping options), with **HEIC** as a default path via `PlatformImageEXIFConfig`.

### **System-action contract gaps (Issues #256 / #169)**

- Closes gaps in the system-action contract for **`openURL`** and **remote notification** handling, aligning behavior with the documented contract.

---

## ✅ Resolved GitHub issues

- **[Issue #277](https://github.com/schatt/sixlayer/issues/277)** — `PresentationProfilesCatalog`, bundled `PresentationProfiles.hints`, and profile-keyed `PresentationHints` construction.
- **[Issue #275](https://github.com/schatt/sixlayer/issues/275)** — PlatformImage EXIF writers and configuration (including HEIC defaults via `PlatformImageEXIFConfig`).
- **[Issue #273](https://github.com/schatt/sixlayer/issues/273)** — Optional draft storage key separate from `DynamicFormConfiguration.id`.
- **[Issue #272](https://github.com/schatt/sixlayer/issues/272)** — Hint-driven item collection presentation resolver; optional `"card"` row style on custom list collections.
- **[Issue #256](https://github.com/schatt/sixlayer/issues/256)** — System-action contract improvements (`openURL`, remote notifications; closes **#169** contract gaps).

---

## 📎 Additional resolved issues (not in v7.8.0 milestone)

The release script flags **recently closed** work that is easy to miss when writing milestone-only notes. The items below closed during the same release window and are **documented here for traceability**; tie-break for “in this tag vs earlier” is the integration branch / merge order in git, not this list.

- **[Issue #276](https://github.com/schatt/sixlayer/issues/276)** — Platform color hygiene: `Color.platform*` alignment and **UIColor / NSColor** drift reduction across the framework.
- **[Issue #274](https://github.com/schatt/sixlayer/issues/274)** — **PlatformImage.exif** read could return **nil** after lossy JPEG round-trips that strip metadata; complements the EXIF configuration work tracked under **#275**.
- **[Issue #271](https://github.com/schatt/sixlayer/issues/271)** — **watchOS** compile unblockers around **OCRService** and camera API availability (**Epic #233**).
- **[Issue #270](https://github.com/schatt/sixlayer/issues/270)** — **v7.7.2** release checklist and metadata consistency fixes (automation / docs hygiene).
- **[Issue #269](https://github.com/schatt/sixlayer/issues/269)** — Generalize **`Development/scripts/commit-xcodegen.sh`** so the Xcode project name comes from **`project.yml`** (not a hard-coded repo name).
- **[Issue #268](https://github.com/schatt/sixlayer/issues/268)** — Add the **XcodeGen commit helper** script used with declarative project regeneration.

---

## ⚠️ Migration / consumer notes

- **Forms**: If you rely on draft persistence keyed only by `DynamicFormConfiguration.id`, review whether a dedicated draft key is preferable for multi-form or shared-draft scenarios.
- **Images**: When preserving or stripping EXIF, use the new configuration surface on **PlatformImage** rather than ad hoc metadata handling.
- **Collections**: Read the Item Collections section in **`Framework/docs/README_Layer1_Semantic.md`**; custom list collections remain `ScrollView` + lazy stack (not full SwiftUI `List` semantics).

---

## 🔗 References

- [RELEASE_v7.7.2.md](RELEASE_v7.7.2.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
