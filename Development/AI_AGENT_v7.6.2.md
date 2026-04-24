# AI Agent Guide - SixLayer Framework v7.6.2

**Version**: v7.6.2  
**Release Date**: April 23, 2026  
**Release Type**: Patch

---

## 🎯 What's in v7.6.2

Patch for **viewport-aware card layout** (#249, #250); **test isolation** (`DefaultRuntimeCapabilityIsolationTrait` clears capability overrides on **MainActor** and the trait executor thread); **tvOS** compile path for **`SLF-tvOS-AllTests`** (#237); and **internal** test harness work (#247 — no `AccessibilityIdentifierConfig.shared` mutation in tests; #248 — mac/iOS drift reduction).

### **Key Points for AI Agents**

1. **Intelligent cards** — Pass finite `viewportHeight` into `determineIntelligentCardLayout_L2` from `GeometryReader` (or use `PlatformFrameHelpers.finiteViewportHeight` when height is unbounded).
2. **Optimal / responsive demo cards** — `CardLayoutDecision.cardRowHeight` and `viewportHeight` reflect Layer 2 output; `ResponsiveCardView(data:rowHeight:)` defaults to 120pt when height is not supplied.
3. **Tests** — Suites using `DefaultRuntimeCapabilityIsolationTrait` assume per-test cleanup on both pool and main threads; see [RELEASE_v7.6.2.md](RELEASE_v7.6.2.md).
4. **tvOS / tests** — Prefer task-local or environment-driven `AccessibilityIdentifierConfig` in tests (#247); align mac vs iOS expectations with shared tests and explicit `#if os` branches where needed (#248).

---

## 🔗 Related Documentation

- [RELEASE_v7.6.2.md](RELEASE_v7.6.2.md) — Release notes  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index  
- [AI_AGENT_v7.6.1.md](AI_AGENT_v7.6.1.md) — Previous patch guide

---

**For complete framework documentation, see [AI_AGENT.md](AI_AGENT.md)**
