# AI Agent Guide - SixLayer Framework v7.7.0

**Version**: v7.7.0  
**Release Date**: April 24, 2026  
**Release Type**: Minor

---

## 🎯 What's in v7.7.0

v7.7.0 ships the new **VisionKit live data scanner Layer 4 path** (Issue #252) and completes **runtime capability namespacing** (Issue #253), including additional namespaces beyond the initial co-ship scope: `Network`, `Media`, `Pasteboard`, and `Accessibility`.

Release process and test-harness updates from Issues **#246** and **#247** are included in this release record.

### Key points for AI agents

1. **Scanner APIs**: Use `platformDataScannerContent_L4` / `platformDataScannerInterface_L4*` for live scanning UI.
2. **Scanner gating**: Prefer `RuntimeCapabilityDetection.Photos.supportsLiveDataScanner` as the capability source of truth.
3. **Namespaced capabilities**: Prefer `RuntimeCapabilityDetection.<Namespace>.*` over deprecated top-level forwarders.
4. **Dynamic network semantics**: `Network.isConstrained` / `isExpensive` are dynamic path state (`NWPath`) snapshots, not static hardware capability.
5. **Tests**: Use namespace test overrides and always call `RuntimeCapabilityDetection.clearAllCapabilityOverrides()` in teardown paths.

---

## 🧭 Namespace map (v7.7.0)

- `Photos`: camera/library/scanner
- `Vision`: Vision/OCR/image analyzer/document camera
- `Files`: security-scoped resources/bookmarks
- `Network`: `isConstrained`, `isExpensive`, `hasPathSnapshot`
- `Media`: microphone/screen-capture capability
- `Pasteboard`: string read/write capability
- `Accessibility`: namespaced access to VoiceOver/Switch Control/AssistiveTouch/high-contrast probes

---

## 🔗 Related docs

- [RELEASE_v7.7.0.md](RELEASE_v7.7.0.md) — Release notes
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index
- [RuntimeCapabilityDetectionGuide.md](../Framework/docs/RuntimeCapabilityDetectionGuide.md) — Capability semantics and test overrides

---

**For full framework guidance, start at [AI_AGENT.md](AI_AGENT.md).**
