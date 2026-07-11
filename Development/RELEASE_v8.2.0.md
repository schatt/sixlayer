# SixLayer Framework v8.2.0 Release Documentation

**Release Date**: TBD (prep on `next`)  
**Release Type**: Minor  
**Previous Release**: v8.1.1  
**Status**: Release prep (`next`)

---

## 🎯 Release Summary

v8.2.0 is a **minor** release focused on **XCUITest reliability** and **parallel test hygiene** under Epic #233. Ships deep-link TestApp hosts and exact accessibility markers for macOS UITests (#316), greens iOS `SLF-iOS-UITests` Layer4 contract rows and the manual a11y harness (#317), removes suite `.serialized` so tests must pass under parallel execution (#335), fixes unit-test fallout from capability `TaskLocal` isolation (#334), silences macOS unit-test MainActor / redundant-`try` warnings in shared helpers (#337), and CI trust for system CAs on Gitea artifact uploads (#336).

---

## 🆕 Confirmed in v8.2.0 (implemented)

### **macOS SLF-macOS-UITests deep-link hosts (#316)**

- Launch-arg deep-links for Layer1 (`-OpenLayer1Category=` / `-L1Section=`), Layer4 contract/overlay (`-L4Section=` / `-OpenLayer4OverlayAccessibility`), Category A (`-CatASection=`), and SD150 exact section ids.
- No scroll-as-discovery / OR-fallback query chains in rewritten UITests; prefer exact identifiers and `.exists`.
- Framework a11y stamps: `platformPresentNavigationStack_L1` always named; `platformPhotoCapture_L1` compliance on `.both`; nav-stack id on L4 surface inside `NavigationStackWrapper`.

### **iOS SLF-iOS-UITests Layer4 and a11y harness (#317)**

- Fixed the nine failing iOS UITests around Layer4 contract rows and the manual accessibility harness (Epic #233).
- Under `-UITesting` / `XCUI_TESTING`, `platformOpenURL_L4` and `platformRegisterForRemoteNotifications_L4` return success without invoking system UI (XCUITest host is not in-process XCTest).
- Print/export paths skip or auto-finish under UITest instead of relying on XCTest to dismiss system modals; `platformPrint_L4` does not present a sheet under UITest and `PrintSheet` resets its presentation binding; `platformExportActions_L4` auto-finishes when a chooser would present.
- `platformPhotoPicker_L4` mounts an inline SwiftUI contract stub under UITest (iOS sheet a11y was unreliable for the contract).
- Harness improvements: label-anchored L4 scroll, modal-dismiss assertions that do not require nav-title visibility after deep scroll, and `-OpenLayer4IdentifierEdgeCase` deep link for the manual harness.

### **Parallel suite policy (#335)**

- Remove suite `.serialized`; tests must remain green under parallel XCTest / Swift Testing.

### **Unit-test isolation follow-ups (#334, #337)**

- Fix SLF unit failures after #315 capability `TaskLocal` isolation (#334).
- Mark hosting teardown `@MainActor`; drop redundant `try` on non-throwing `withValue` in `HostedViewTestIsolationTrait` (#337).

### **CI (#336)**

- Trust system CA for Gitea artifact uploads.

---

## ✅ Resolved GitHub issues (milestone-ish for v8.2.0)

- **[Issue #316](https://github.com/schatt/sixlayer/issues/316)** — macOS `SLF-macOS-UITests` XCUITest runtime failures (deep-link / Layer1–Layer4 hosts).
- **[Issue #317](https://github.com/schatt/sixlayer/issues/317)** — iOS `SLF-iOS-UITests` Layer4 contract rows and a11y harness failures.
- **[Issue #334](https://github.com/schatt/sixlayer/issues/334)** — Fix SLF unit test failures after #315 capability TaskLocal isolation.
- **[Issue #335](https://github.com/schatt/sixlayer/issues/335)** — Remove suite `.serialized`; tests must pass under parallel.
- **[Issue #336](https://github.com/schatt/sixlayer/issues/336)** — ci: trust system CA for Gitea artifact uploads.
- **[Issue #337](https://github.com/schatt/sixlayer/issues/337)** — Silence macOS unit-test MainActor / try warnings in shared test helpers.

---

## ⚠️ Migration / consumer notes

- **UITest hosts:** Prefer launch-arg deep-links and exact accessibility identifiers over home navigation / swipe discovery when writing SixLayer UITests (macOS #316; iOS Layer4 harness #317).
- **UITest-friendly Layer4:** Under UITesting flags, open-URL / remote-notification / print / export / photo-picker paths are stubbed or auto-finished so XCUITest does not depend on system sheets (#317).
- **Parallel:** Do not reintroduce suite-level `.serialized` to hide parallel races; fix isolation instead (#335).
- **No intentional breaking public API changes** — minor release; a11y identifier stamps, UITest stubs, and test-host patterns are the main consumer-visible shifts for UITest authors.

---

## 🔗 References

- [RELEASE_v8.1.1.md](RELEASE_v8.1.1.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
- [AI_AGENT_v8.2.0.md](AI_AGENT_v8.2.0.md) — Version-specific agent guide.
