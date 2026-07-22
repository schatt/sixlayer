# SixLayer Framework v8.3.4 Release Documentation

**Release Date**: TBD (prep)  
**Release Type**: Patch  
**Previous Release**: v8.3.3  
**Status**: Prep

---

## 🎯 Release Summary

v8.3.4 is a **patch** release focused on:

1. **macOS / iOS XCUITest reliability** — host-land markers, one-launch suite sessions, deep-link launch reuse, and macOS green after host-sentinel / sharedApp hardening ([#370](https://github.com/schatt/sixlayer/issues/370), [#372](https://github.com/schatt/sixlayer/issues/372)–[#374](https://github.com/schatt/sixlayer/issues/374)).
2. **Unit / ViewInspector hang footguns** — stop live Vision / fire-and-forget OCR awaits and NavigationStack / barcode Bool(true) theater in unit and VI lanes ([#366](https://github.com/schatt/sixlayer/issues/366), [#367](https://github.com/schatt/sixlayer/issues/367), [#369](https://github.com/schatt/sixlayer/issues/369)).
3. **Targeted UITest contract fixes** — SD150 / L4 / photo picker iOS failures; Layer5 `voiceOverEnabled` contract id; Category E clipboard timing ([#368](https://github.com/schatt/sixlayer/issues/368), [#371](https://github.com/schatt/sixlayer/issues/371)).

---

## 🆕 Confirmed in v8.3.4 (implemented)

### **XCUI host land + shared sessions (#370, #372–#374)**

- `uiTestHostLandMarker` / leaf land markers for stable deep-link waits before assigning `sharedApp`.
- One-launch suite sessions for L5/L6/CatE/C/OCR (#373), Category A full-host + L2/L3/CatB (#374).
- Reuse L4/L1 XCUI app when deep-link launch args match (#372); navigation section always fresh-launches (no reuse fallback ladder).
- macOS: wait for host foreground after launch; Text leaf host-sentinel for XCUI visibility; Category B / SD150 query and typing hardening (#370).

### **Vision / OCR test isolation (#366, #367)**

- Stop OCRService ViewInspector tests from awaiting live Vision; pattern-match `OCRError.invalidImage`.
- Await OCRError / Vision helper paths instead of fire-and-forget `processImage` in unit tests; tighten BarcodeServiceTests away from live Vision.

### **Hang footgun cleanup (#369)**

- Remove VI NavigationStack / barcode `Bool(true)` hang theater; document NavigationStack hosting as forbidden in unit/VI.
- Stop BarcodeExamples from auto-mounting Vision scan; Layer1 XCUI land for Barcode category.

### **Contract / UITest fixes (#368, #371)**

- SD150 SecureField typing helpers (focus retry, paste leaf, disable strong-password UI).
- L4 photo picker XCUITest host mount + exact contract id under `-UITesting`.
- Layer5 `voiceOverEnabled` leaf `accessibilityIdentifier`; stop VoiceOverEnabledView from collapsing a11y identity; Category E clipboard timing.

---

## ✅ Resolved GitHub issues (milestone v8.3.4)

- **[Issue #370](https://github.com/schatt/sixlayer/issues/370)** — XCUI slow-test baseline / macOS XCUI green (host-land, sharedApp, host-sentinel).
- **[Issue #372](https://github.com/schatt/sixlayer/issues/372)** — XCUI: reuse app process when L4/L1 deep-link args match.
- **[Issue #373](https://github.com/schatt/sixlayer/issues/373)** — XCUI: one-launch suites (L5/L6/CatE/C/OCR) + SD150 typing trim.
- **[Issue #374](https://github.com/schatt/sixlayer/issues/374)** — XCUI: Category A full-host one launch + L2/L3/CatB shared session.
- **[Issue #375](https://github.com/schatt/sixlayer/issues/375)** — Prepare v8.3.4 release (docs / `--docs`).

### Also closed since v8.3.3 (supporting; not all on milestone)

- **[Issue #366](https://github.com/schatt/sixlayer/issues/366)** — macOS ViewInspector hang: unbounded OCRService Vision awaits.
- **[Issue #367](https://github.com/schatt/sixlayer/issues/367)** — Remove fire-and-forget / live Vision `processImage` from unit tests.
- **[Issue #368](https://github.com/schatt/sixlayer/issues/368)** — Fix three failing iOS UITests (SD150, L4 nav stack, L4 photo picker).
- **[Issue #369](https://github.com/schatt/sixlayer/issues/369)** — Hang footgun cleanup: no VI NavigationStack / barcode Bool(true) theater.
- **[Issue #371](https://github.com/schatt/sixlayer/issues/371)** — Layer5 `voiceOverEnabled` contract id; Category E clipboard timing.

---

## ⚠️ Migration / consumer notes

- **No public API changes** intended for app consumers; this release is test-harness and XCUI reliability.
- **UITest hosts / deep-links:** prefer leaf land markers and wait for host land before sharing `XCUIApplication` across tests in a suite.
- **Unit / ViewInspector:** do not host `NavigationStack` or fire live Vision/OCR in those lanes — use XCUI for E2E system surfaces.
- **SPM consumers** may bump to **v8.3.4** for the green XCUI / VI baseline; production framework surface is unchanged for typical app use.

---

## 📚 References

- [RELEASE_v8.3.3.md](RELEASE_v8.3.3.md) — Previous patch (ExactNamed host-sentinel).
- [RELEASES.md](RELEASES.md) — Release history index.
