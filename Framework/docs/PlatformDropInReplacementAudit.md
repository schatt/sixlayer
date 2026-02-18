# Platform* Drop-In Replacement Audit

**Issue:** [#164 — Ensure ALL platform* Types/Functions Are Drop-in Replacements](https://github.com/schatt/sixlayer/issues/164)

**Purpose:** Ensure every public `platform*` type and function that is intended to replace a SwiftUI or native API is a true drop-in: same (or compatible) signature, cross-platform behavior, and no unintended platform leakage.

---

## Drop-In Criteria

A **drop-in replacement** must satisfy:

1. **Signature compatibility** — Same parameter names, types, and order as the native API (or a documented, intentional extension that remains backward-compatible).
2. **Return type** — Same or SwiftUI-compatible return (e.g. `some View` where the native returns a View).
3. **No platform leakage** — Callers do not need `#if os(iOS)` / `#if os(macOS)` around the call; behavior is abstracted.
4. **Accessibility** — Where the framework applies automatic accessibility (e.g. `.automaticCompliance()`), it is applied consistently and does not change the public signature of the drop-in.

**Not every** `platform*` API is a drop-in: some are net-new (e.g. Layer 1 semantic functions). This audit focuses on APIs that either (a) document or imply drop-in replacement for a native type/modifier, or (b) are the obvious cross-platform counterpart (e.g. `platformFrame` ↔ `.frame()`).

---

## Scope

- **In scope:** Public `platform*` functions and types in `Framework/Sources` that replace or mirror SwiftUI/native APIs.
- **Out of scope:** Internal/private APIs, Layer 1 semantic-only functions that have no single native counterpart (e.g. `platformPresentContent_L1`), and types that are not replacements (e.g. framework-specific enums).

---

## Audit Tables

### 1. Standalone view builders (replace SwiftUI view types)

| API | Native equivalent | Status | Notes |
|-----|-------------------|--------|--------|
| `platformTextField(_:text:)` | `TextField(_:text:)` | ✅ Drop-in | Same signature; adds automaticCompliance. |
| `platformTextField(_:text:axis:)` | `TextField(_:text:axis:)` | ✅ Drop-in | iOS 16+ axis. |
| `platformSecureField(_:text:)` | `SecureField(_:text:)` | ✅ Drop-in | Same signature. |
| `platformToggle(_:isOn:)` (String label) | `Toggle(_:isOn:)` | ✅ Drop-in | Same shape. |
| `platformForm { }` | `Form { }` | ✅ Drop-in | ViewBuilder. |
| `platformTextEditor(_:text:)` | `TextEditor(text:)` | ⚠️ Partial | SwiftUI has only `TextEditor(text:)`; we add `prompt` (extension). For strict drop-in, add overload `platformTextEditor(text:)` with no prompt. |
| `platformButton(_ label: String, action:)` | `Button(_ title: String, action:)` | ✅ Drop-in | Same signature; adds automaticCompliance. |
| `platformButton(label: LocalizedStringKey, action:)` | `Button(LocalizedStringKey, action:)` | ✅ Drop-in | Same shape. |

### 2. View modifiers (replace SwiftUI modifiers)

| API | Native equivalent | Status | Notes |
|-----|-------------------|--------|--------|
| `.platformFrame()` | `.frame(maxWidth:maxHeight:)`-style | ⚠️ Semantic | Not 1:1; adds clamping. Document as “platform-aware frame”. |
| `.platformFrame(width:height:alignment:)` | `.frame(width:height:alignment:)` | ✅ Drop-in | #161 added alignment. |
| `.platformFrame(minWidth:idealWidth:maxWidth:...)` | `.frame(minWidth:...)` | ✅ Drop-in | #162; alignment included. |
| (Other `.platform*` modifiers) | Various | 🔲 TBD | To be audited. |

### 3. Platform types (replace UIKit/AppKit types)

| Type | Native equivalent | Status | Notes |
|------|-------------------|--------|--------|
| `PlatformImage` | `UIImage` / `NSImage` | ✅ Drop-in | Cross-platform image type. |
| `PlatformRect` | `CGRect` | ✅ Drop-in | Cross-platform rect. |
| `PlatformSize` | `CGSize` | ✅ Drop-in | Cross-platform size. |
| (Others in PLATFORM_TYPES_LIST.md) | Various | 🔲 TBD | To be audited. |

### 4. Gaps and follow-ups

- **Full modifier list:** Enumerate every public `func platform*` on `View` and compare to SwiftUI modifier signatures.
- **Full type list:** Cross-reference `PLATFORM_TYPES_LIST.md`; mark each as drop-in vs framework-only.
- **Tests:** Ensure `PlatformStandaloneDropInTests` and any modifier tests assert signature compatibility where applicable.

---

## References

- `PLATFORM_TYPES_LIST.md` — Inventory of platform* types.
- `RELEASE_v7.5.0.md` — #161 (platformFrame alignment), #162 (missing parameters).
- `PlatformStandaloneDropInTests.swift` — Tests for standalone drop-ins.
- `PlatformComponentPattern.md` — Pattern for platform-specific implementations behind a single API.

---

*Last updated: 2026-02-18. Audit in progress for issue #164.*
