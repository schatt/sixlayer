# AI Agent Guide - SixLayer Framework v7.9.0

**Version**: v7.9.0  
**Release Date**: May 31, 2026  
**Release Type**: Minor

---

## 🎯 What's in v7.9.0

v7.9.0 ships **HIG automatic compliance** (minimum typography floors #302, system zoom #303), **intelligent card viewport/layout** (host hints #306, navigation chrome subtraction #307/#308, content-aware height floor #309), **capability override test hygiene** (tri-state on controls #251, platform-aware precursors #311, matrix trim #312, macOS card touch harness #313), **Sendable policy** (#310), and **Epic #233** cross-platform compile/test stabilization. Patch accessibility slices from v7.8.9 (#298 Reduce Motion, #299 Increase Contrast) are on the integration branch.

### Key points for AI agents

1. **Capability overrides:** Precursors are enforced in `setTest*` (AssistiveTouch↔touch, Vision↔OCR; haptic independent). Matrix tests assert **HIG consumer law** only — do not re-validate Apple detection.
2. **Tri-state testing:** Current / disabled / enabled phases belong **beside controls under test** (#251), not on aggregate matrix snapshots.
3. **Card viewport:** Respect host hints (`chromeInset`, max height, `preferFitInViewport`); content-aware height floor applies when viewport clamp is not binding (#309).
4. **HIG compliance:** Use framework typography floor and system zoom APIs; run/host `HIGComplianceTypographyTests` / `HIGComplianceZoomTests` patterns when touching automatic compliance modifiers.
5. **macOS card touch:** `getCardExpansionPlatformConfig()` uses `supportsTouchForMacOSCardExpansion` — polluted `UserDefaults` must not force touch chrome when harness pins off (#313).
6. **Sendable:** Follow documented Sendable policy (#310) when adding public types or crossing actor boundaries.

---

## 🔗 Related docs

- [RELEASE_v7.9.0.md](RELEASE_v7.9.0.md) — Release notes  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index  
- `.cursor/rules/capability-override-test-flows.mdc` — Capability test flow rules  

---

**For full framework guidance, start at [AI_AGENT.md](AI_AGENT.md).**
