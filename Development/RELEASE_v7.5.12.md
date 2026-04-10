# SixLayer Framework v7.5.12 Release Documentation

**Release Date**: April 2026  
**Release Type**: Patch  
**Previous Release**: v7.5.11  
**Status**: Released

---

## 🎯 Release Summary

Patch release following **v7.5.11**. Fixes **composition between `platformFormContainer` (SwiftUI `Form`) and no-header “sections”**: the old no-header `platformSectionContainer` was a styled `VStack`, which mis-renders inside a `Form`. The inset styling moves to **`platformGroupedInsetContainer`**; no-header **`platformSectionContainer`** is now a real **`Section`** with `.automaticCompliance()` (Resolves [Issue #220](https://github.com/schatt/sixlayer/issues/220)).

---

## 🆕 What's New

### **Form-safe sections vs grouped inset blocks (Issue #220)**

- **`platformGroupedInsetContainer`**: Padded `VStack` + background + corner radius — same visual role as the former no-header `platformSectionContainer` implementation. Use for **card-style** blocks **outside** the `Form` row/section model.
- **No-header `platformSectionContainer`**: Implemented as **`Section { … }.automaticCompliance()`** in `PlatformBasicContainerExtensions`, with global `platformSectionContainer { … }`. Intended for use **inside `platformFormContainer`** (e.g. filter/sort sheets) without apps substituting raw SwiftUI `Section`.
- **Tests**: `PlatformStandaloneDropInTests` asserts a `Section` appears inside `platformFormContainer` for the no-header API, and that `platformGroupedInsetContainer` uses `VStack` without `Section`.

### **Release script**

- **`release-process.sh`**: Accepts an explicit version as **`7.5.12`** or **`v7.5.12`** (leading `v` is normalized).

---

## ✅ Migration (consumers)

- **CarManager** (and similar): Replace no-header **`platformSectionContainer`** used for **inset chrome** with **`platformGroupedInsetContainer`**. Keep **`platformSectionContainer`** for **real form sections** (including no-header inside **`platformFormContainer`**).

---

## 🔗 Related Documentation

- [RELEASES.md](RELEASES.md) — Release history  
- [RELEASE_v7.5.11.md](RELEASE_v7.5.11.md) — Previous patch (v7.5.11)
