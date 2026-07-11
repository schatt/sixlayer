# AI Agent Guide - SixLayer Framework v8.2.0

**Version**: v8.2.0  
**Release Date**: TBD (prep on `next`)  
**Release Type**: Minor

---

## 🎯 What's in v8.2.0

v8.2.0 ships **XCUITest reliability** and **parallel test hygiene** (Epic #233): Layer1/Layer4/CatA/SD150 launch-arg hosts on macOS (#316), iOS Layer4 contract / a11y harness greens with UITest-safe L4 stubs (#317), no suite `.serialized` (#335), capability `TaskLocal` unit-test fixes (#334), MainActor hosting teardown / redundant-`try` cleanup (#337), and Gitea artifact CA trust (#336). ViewInspector baseline remains [AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md).

### Key points for AI agents

1. **UITests:** Prefer `-OpenLayer1Category=` / `-L1Section=` / `-L4Section=` / `-CatASection=` deep-links and exact accessibility identifiers — do not scroll to discover UI (#316).
2. **iOS Layer4 under UITesting:** open-URL / remote-notification / print / export / photo-picker paths stub or auto-finish; use `-OpenLayer4IdentifierEdgeCase` for the manual harness (#317).
3. **No OR-fallback query chains:** One stable id; fail with nearby-id dumps if missing.
4. **Parallel:** Do not add suite `.serialized` to mask races; keep tests parallel-safe (#335).
5. **Hosting teardown:** `HostingSession` entry teardown is `@MainActor`; isolation trait catches test errors without `try` on non-throwing `withValue` (#337).
6. **Public API:** No intentional breaking consumer API; UITest authors and a11y id stamps are the main shifts.

---

## 🔗 Related docs

- [RELEASE_v8.2.0.md](RELEASE_v8.2.0.md) — Release notes  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index  
- [AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md) — ViewInspector / TestKit baseline  

---

**For full framework guidance, start at [AI_AGENT.md](AI_AGENT.md).**
