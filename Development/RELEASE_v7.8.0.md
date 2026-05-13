# SixLayer Framework v7.8.0 Release Documentation

**Release Date**: May 13, 2026  
**Release Type**: Minor  
**Previous Release**: v7.7.2  
**Status**: In preparation

---

## 🎯 Release Summary

v7.8.0 is a **minor** release focused on presentation and collection behavior, optional form draft storage configuration, richer **PlatformImage** EXIF handling, and clearer **system-action** contracts (open URL and remote notifications). Milestone issues **#256**, **#272**, **#273**, **#275**, and **#277** are included.

---

## 🆕 Confirmed in v7.8.0 (implemented)

### **Presentation profiles catalog and hints-driven collections (Issue #277)**

- Loads presentation profile metadata from bundled `Hints/PresentationProfiles.hints` (and related catalog APIs).
- Hint-driven card height and content alignment for sparse grids in collection-style layouts.

### **List layout for card-style item collections (Issue #272)**

- Adds a **list** presentation layout path for card-style item collections, with an explicit presentation contract for consumers and tests.

### **Optional draft storage key for dynamic forms (Issue #273)**

- Supports an optional **draft storage key** separate from `DynamicFormConfiguration.id`, so drafts can be partitioned or shared across configurations as needed.

### **PlatformImage EXIF read/write configuration (Issue #275)**

- EXIF-oriented APIs on **PlatformImage** (including writers that return a new image and stripping options), with **HEIC** as a default path via `PlatformImageEXIFConfig`.

### **System-action contract gaps (Issues #256 / #169)**

- Closes gaps in the system-action contract for **`openURL`** and **remote notification** handling, aligning behavior with the documented contract.

---

## ✅ Resolved GitHub issues

- **[Issue #277](https://github.com/schatt/sixlayer/issues/277)** — Presentation profiles catalog; hint-driven card height / content alignment for sparse grids.
- **[Issue #275](https://github.com/schatt/sixlayer/issues/275)** — PlatformImage EXIF writers and configuration (including HEIC defaults via `PlatformImageEXIFConfig`).
- **[Issue #273](https://github.com/schatt/sixlayer/issues/273)** — Optional draft storage key separate from `DynamicFormConfiguration.id`.
- **[Issue #272](https://github.com/schatt/sixlayer/issues/272)** — List layout for card-style item collections (presentation contract).
- **[Issue #256](https://github.com/schatt/sixlayer/issues/256)** — System-action contract improvements (`openURL`, remote notifications; closes **#169** contract gaps).

---

## ⚠️ Migration / consumer notes

- **Forms**: If you rely on draft persistence keyed only by `DynamicFormConfiguration.id`, review whether a dedicated draft key is preferable for multi-form or shared-draft scenarios.
- **Images**: When preserving or stripping EXIF, use the new configuration surface on **PlatformImage** rather than ad hoc metadata handling.
- **Collections**: Prefer the documented presentation contract when choosing **list** vs card-style layouts for item collections.

---

## 🔗 References

- [RELEASE_v7.7.2.md](RELEASE_v7.7.2.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
