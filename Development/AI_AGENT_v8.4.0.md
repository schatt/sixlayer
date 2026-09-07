# AI Agent Guide - SixLayer Framework v8.4.0

**Version**: v8.4.0  
**Release Date**: September 7, 2026  
**Release type**: Minor (on v8.3.8)  
**Primary issues**: [#423](https://github.com/schatt/sixlayer/issues/423)–[#425](https://github.com/schatt/sixlayer/issues/425), [#444](https://github.com/schatt/sixlayer/issues/444), [#449](https://github.com/schatt/sixlayer/issues/449)–[#450](https://github.com/schatt/sixlayer/issues/450), [#453](https://github.com/schatt/sixlayer/issues/453)–[#457](https://github.com/schatt/sixlayer/issues/457)

## 🎯 What's in v8.4.0

- **L5 honesty:** real iOS haptic / swipe / pull-to-refresh tests and helpers (#423, #424). Do not document APIs that are not in `Framework/Sources` (#425).
- **Removed lies:** `platformIOSLayout(keyboardAware:)` is gone (#444). Fourteen placeholder `Platform*Layer5` demo Views are deleted (#453).
- **Coverage:** L5/L6 inventory (#450); `#else` stub identity tests (#449); unit clusters for AccessibilityFeatures, Messaging/Resource, SplitView, card expansion (#454–#457).

## Agent notes

- Do **not** reintroduce phantom L5 performance modifiers (`platformLazyLoading`, `platformMemoryOptimization`, etc.).
- Do **not** recreate the 14 deleted Layer5 demo shells without a product issue. Next real macOS L5 chrome is **#451** on v8.5.0.
- Opposite-lane `#else { self }` stubs: assert identity with subject type (`Text`), per #449. Do not treat stub identity as behavioral coverage.
- `#453` is source-breaking for anyone who referenced those demo types. Call that out; do not hide it in a minor because the types were empty.
- Next development line after this tag is **v8.5.0** (haptics unify #445, split/nav consolidate #447, macOS L5 #451, keyboard nav #446).

## References

- [RELEASE_v8.4.0.md](RELEASE_v8.4.0.md)
- [AI_AGENT_v8.3.0.md](AI_AGENT_v8.3.0.md) — prior minor baseline
- [AI_AGENT.md](AI_AGENT.md) — version index
