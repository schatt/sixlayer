# AI Agent Guide - SixLayer Framework v8.2.1

**Version**: v8.2.1  
**Release Date**: July 12, 2026  
**Release type**: Patch (on v8.2.0)  
**Primary issue**: [#340](https://github.com/schatt/sixlayer/issues/340)

## 🎯 What's in v8.2.1

Patch for **Xcode 27 beta compile failures** when building against iOS 17 / macOS 15 deployment targets:

- **Root cause:** Redundant `#available` for OS versions **below** the package minimum inside `@ViewBuilder` → Xcode 27 limited-availability ContentBuilder → `TupleContent<…>: View` requires iOS/macOS 26+.
- **Fix:** Remove dead sub-minimum gates only; legitimate `#available(iOS 18.0, *)` on iOS 17 deploy is fine.
- **Public API:** No intentional breaking changes.

Still use **[AI_AGENT_v8.2.0.md](AI_AGENT_v8.2.0.md)** for XCUITest / parallel-test guidance from the minor release.

## Agent notes

- Do **not** reintroduce `#available(iOS 16, *)` / `#available(macOS 13, *)` (or lower) inside `@ViewBuilder` when package minimums are iOS 17 / macOS 15 — use compile-time `#if os(...)` or trust the deployment target instead.
- If TupleContent / iOS 26+ errors reappear under a new Xcode beta, check for new dead gates before assuming a framework API change is required.
- Apple Feedback **FB23710247** tracks upstream ContentBuilder behavior.

## References

- [RELEASE_v8.2.1.md](RELEASE_v8.2.1.md)
- [AI_AGENT_v8.2.0.md](AI_AGENT_v8.2.0.md) — prior minor baseline
