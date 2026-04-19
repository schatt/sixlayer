# AI Agent Guide - SixLayer Framework v7.6.1

**Version**: v7.6.1  
**Release Date**: April 19, 2026  
**Release Type**: Patch

---

## 🎯 What's in v7.6.1

Patch release for Layer 1 accessibility compliance alignment (**Issue #245**, **gh-243** parity with **#243**). Prefer **`.automaticCompliance(identifierName:)`** on framework-owned presentation roots; use **anonymous** `.automaticCompliance()` only on thin shells over **arbitrary** or caller-built `content`. Avoid **`automaticCompliance(named:)`** on generic hosts that can mask inner accessibility.

### **Key Points for AI Agents**

1. **No intentional breaking public API** — changes are modifier-level accessibility wiring; apps should re-run UI tests if they assert on old named-modifier debug output or brittle identifier substrings.
2. **Harness rule** — Parameterless `.automaticCompliance()` on a wrapper with no `identifierName` is treated as fully anonymous and may **suppress** wrapper IDs (#222); pass **`identifierName:`** when the shell must emit a stable `SixLayer.main.ui…` root (see `PlatformSemanticLayer1` patterns).
3. **When in doubt** — Read [RELEASE_v7.6.1.md](RELEASE_v7.6.1.md) and the file-header classification comments in `PlatformInternationalizationL1.swift`, `PlatformSecurityL1.swift`, and `PlatformDataFrameAnalysisL1.swift`. For broader context, [AI_AGENT_v7.6.0.md](AI_AGENT_v7.6.0.md) remains the v7.6 minor baseline.

---

## 🔗 Related Documentation

- [RELEASE_v7.6.1.md](RELEASE_v7.6.1.md) — Release notes  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index

---

**For complete framework documentation, see [AI_AGENT.md](AI_AGENT.md)**
