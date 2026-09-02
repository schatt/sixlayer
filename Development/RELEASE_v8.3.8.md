# SixLayer Framework v8.3.8 Release Documentation

**Release Date**: September 1, 2026  
**Release Type**: Patch  
**Previous Release**: v8.3.7  
**Status**: Released

---

## 🎯 Release Summary

v8.3.8 is a **patch** release focused on:

1. **Hosted Environment identifier config (#437)** — restore `.environment(\.accessibilityIdentifierConfig)` on hosted views after #435's unhosted inspect split; prove the Gitea iOS/macOS UITest identifier cluster green.
2. **Host-managed picker dismiss (#441, #442)** — public `SystemImagePickerDismissPolicy` stops embedded CameraView/PhotoPicker/UnifiedImagePicker representables from UIKit-`dismiss` tearing down ancestor SwiftUI hosts (e.g. consumer `fullScreenCover`); macOS types compile and default policy runs on all platforms.
3. **ViewInspector CI stall window (#437)** — raise self-hosted ViewInspector job stall kill to 600s so long VI runs are not misread as assertion failures.

---

## 🆕 Confirmed in v8.3.8 (implemented)

### **Hosted Environment identifier config (#437)**

#435 correctly forbids reading `@Environment` on the unhosted `inspect()` path but overshot by ignoring Environment when the view **is** hosted (TestApp and consumers using `.environment(\.accessibilityIdentifierConfig, …)`).

- `UnhostedInspection.withIdentifierConfig` — hosted reads Environment; unhosted uses task-local then `.shared` without instantiating the key.
- Identifier modifiers (`named`, `exactNamed`, `automaticCompliance` / basic compliance) resolve config through that split.
- TestApp keeps an isolated config on `WindowGroup`; it does not write `.shared`.
- Added/updated `AccessibilityIdentifierConfigResolutionTests` (hosted Environment namespace + global-off; unhosted still task-local/shared).
- Gitea 242 UITest identifier cluster (12 tests) green on `SLF-macOS-UITests` and `SLF-iOS-UITests`.

### **SystemImagePickerDismissPolicy (#441, #442)**

Embedded system image pickers called UIKit `dismiss` when `presentingViewController != nil`, walking the presentation chain and tearing down ancestor SwiftUI hosts.

- Public **`SystemImagePickerDismissPolicy`** with default **`hostManaged`**: representables never UIKit-dismiss; hosts close sheets/covers via bindings.
- **`dismissWhenModallyPresented`**: legacy opt-in for UIKit-modal paths only.
- Removed `shouldDismissSystemImagePickerAfterSelection` heuristic entirely.
- Optional `dismissPolicy:` on `CameraView`, `PhotoPickerView`, `UnifiedImagePicker`, `SystemImagePicker`, `SystemCameraPicker` (all default `hostManaged`).
- Framework sheet bindings close field-action picker sheets via bindings instead of representable dismiss.
- **#442**: expose policy types on macOS so `UnifiedImagePicker` compiles; default policy contract tests run on all platforms.

### **ViewInspector CI stall window (#437)**

Self-hosted ViewInspector jobs on Gitea 242 were stall-killed (exit 124 / 180s no tee-log bytes), not assertion reds. Workflow stall window for VI jobs is **600s**; macOS VI `timeout_minutes` **90**.

---

## ⚠️ Migration / consumer notes

### Embedded pickers — use bindings, not UIKit dismiss (#441)

| Scenario | Policy | Host responsibility |
|---|---|---|
| Picker inside `fullScreenCover` / nested sheet | `.hostManaged` (default) | Close cover/sheet via `@Binding` when selection completes |
| Legacy UIKit-modal presentation only | `.dismissWhenModallyPresented` | Representable may UIKit-dismiss its own modal |

Consumers that relied on automatic UIKit dismiss after selection in embedded contexts must close presentation via their own bindings.

### Identifier config — hosted vs unhosted (#437)

- **Hosted app / TestApp**: continue using `.environment(\.accessibilityIdentifierConfig, …)` — now honored again on hosted modifier paths.
- **ViewInspector unhosted inspect**: still uses task-local then `.shared`; Environment is not read there (by design, #435).

---

## ✅ Resolved GitHub issues (milestone v8.3.8)

- **[Issue #437](https://github.com/schatt/sixlayer/issues/437)** — Make required iOS and macOS tests green on next after #435 (hosted Environment identifier config; UITest cluster; VI stall window).
- **[Issue #441](https://github.com/schatt/sixlayer/issues/441)** — Embedded CameraView/PhotoPicker dismiss tears down host fullScreenCover (`SystemImagePickerDismissPolicy`).
- **[Issue #442](https://github.com/schatt/sixlayer/issues/442)** — macOS: `SystemImagePickerDismissPolicy` missing — `UnifiedImagePicker` fails to compile.

---

## 📚 References

- [RELEASE_v8.3.7.md](RELEASE_v8.3.7.md) — Previous patch.
- [RELEASES.md](RELEASES.md) — Release history index.
- [#439](https://github.com/schatt/sixlayer/issues/439) — Switch ViewInspector pin back to nalexn when they tag (still open; not in this release).
