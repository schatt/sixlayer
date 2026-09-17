# AI Agent Guide - SixLayer Framework v8.5.0

**Version**: v8.5.0  
**Release Date**: September 17, 2026  
**Release type**: Minor (on v8.4.0)  
**Primary issues**: [#397](https://github.com/schatt/sixlayer/issues/397), [#445](https://github.com/schatt/sixlayer/issues/445)–[#447](https://github.com/schatt/sixlayer/issues/447), [#451](https://github.com/schatt/sixlayer/issues/451), [#459](https://github.com/schatt/sixlayer/issues/459), [#465](https://github.com/schatt/sixlayer/issues/465), [#466](https://github.com/schatt/sixlayer/issues/466), [#472](https://github.com/schatt/sixlayer/issues/472)

## 🎯 What's in v8.5.0

- **Haptics:** prefer `platformHapticFeedback(_:)`; do not teach deprecated `platformIOSHapticFeedback` as the primary API (#445).
- **macOS L5/L6:** use `PlatformMacOSOptimizationsLayer5` (#451) and keyboard-first NavigationStack L6 (#446); shared sidebar-sheet / overlay-detail chrome helpers (#447).
- **Forms:** AddFuelView L3 uses FormLayoutDecision (#397); select-all-on-begin-editing is per-form opt-in (#472).
- **Honesty:** example demos live under `Framework/Examples/` (#465); Layer1 semantic zeros have unit suites (#466). Retire drops local `done/` tips (#459).

## Agent notes

- Do **not** reintroduce Framework Sources example shells that were moved or deleted in #465 / #453.
- Do **not** document haptic APIs that bypass `SixLayerHaptic` / capability gating.
- Split/nav chrome decisions belong in the pure L5 helpers; do not duplicate platform `#if` in call sites when the shared helpers exist.
- Coverage deepeners (#467–#470, #490, #491) and datetime stack (#481) are **not** in this tag — later milestones.
- Next development line after this tag is **v8.6.0** (forms product + primary-lane coverage clusters).

## References

- [RELEASE_v8.5.0.md](RELEASE_v8.5.0.md)
- [AI_AGENT_v8.4.0.md](AI_AGENT_v8.4.0.md) — prior minor baseline
- [AI_AGENT.md](AI_AGENT.md) — version index
