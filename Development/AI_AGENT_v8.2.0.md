# AI Agent Guide - SixLayer Framework v8.2.0

**Version**: v8.2.0  
**Release Date**: TBD (prep on `next`)  
**Release Type**: Minor

---

## 🎯 What's in v8.2.0

v8.2.0 ships **macOS XCUITest deep-link hosts** and **parallel test hygiene** (Epic #233): Layer1/Layer4/CatA/SD150 launch-arg hosts (#316), no suite `.serialized` (#335), capability `TaskLocal` unit-test fixes (#334), MainActor hosting teardown / redundant-`try` cleanup (#337), and Gitea artifact CA trust (#336). ViewInspector baseline remains [AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md).

### Key points for AI agents

1. **UITests:** Prefer `-OpenLayer1Category=` / `-L1Section=` / `-L4Section=` / `-CatASection=` deep-links and exact accessibility identifiers — do not scroll to discover UI (#316).
2. **No OR-fallback query chains:** One stable id; fail with nearby-id dumps if missing.
3. **Parallel:** Do not add suite `.serialized` to mask races; keep tests parallel-safe (#335).
4. **Hosting teardown:** `HostingSession` entry teardown is `@MainActor`; isolation trait catches test errors without `try` on non-throwing `withValue` (#337).
5. **Public API:** No intentional breaking consumer API; UITest authors and a11y id stamps are the main shifts.

---

## 🔗 Related docs

- [RELEASE_v8.2.0.md](RELEASE_v8.2.0.md) — Release notes  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index  
- [AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md) — ViewInspector / TestKit baseline  

---

**For full framework guidance, start at [AI_AGENT.md](AI_AGENT.md).**
