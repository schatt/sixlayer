# SixLayer Framework v8.3.0 Release Documentation

**Release Date**: TBD (prep)  
**Release Type**: Minor  
**Previous Release**: v8.2.1  
**Status**: Release prep (docs / `--docs`)

---

## 🎯 Release Summary

v8.3.0 is a **minor** release focused on:

1. **Space-aware toolbar action packing** — declared capacity + priority packing that uses `platformMenu` for overflow ([#352](https://github.com/schatt/sixlayer/issues/352)).
2. **Cross-platform AllTests runtime stabilization** for tvOS / watchOS / visionOS lanes under Epic [#233](https://github.com/schatt/sixlayer/issues/233) ([#318](https://github.com/schatt/sixlayer/issues/318), [#319](https://github.com/schatt/sixlayer/issues/319), [#320](https://github.com/schatt/sixlayer/issues/320)).

Remaining AllTests **bootstrap / install** work for tvOS and watchOS tracks under milestone **v8.4.0** (#353, #354, epic #233).

---

## 🆕 Confirmed in v8.3.0 (implemented)

### **Toolbar action packing (#352)**

- Public packing policy: `PlatformToolbarActionsPacker.pack` / `partition` / `renderPlan` with capacity, priority, and pins (`overflowEligible: false`).
- Platform defaults: iOS 2 / macOS 4 / tvOS·visionOS 3 / watchOS 1.
- L4: `platformToolbarActions_L4` — keep-K inline toolbar controls; overflow via `platformMenu` on iOS/macOS; overflow omitted where Menu is unavailable (no fake Menu).
- Does **not** use system toolbar fold-into-`…`.
- Guide: [PlatformToolbarActionsLayer4Guide.md](../Framework/docs/PlatformToolbarActionsLayer4Guide.md).

### **Platform AllTests runtime (#318 / #319 / #320)**

- tvOS / watchOS / visionOS unit-lane expectation and fixture fixes so AllTests runtime failures from the epic baseline are addressed on those platforms.
- Follow-on simulator bootstrap / UITest install failures remain open on v8.4.0 (#353, #354).

### **Also on `next` since v8.2.1 (supporting)**

- XCUI dead scroll / query ladder cleanup (#348, #351).
- TDD policy clarification: compile reds do not count; no deliberate red required for pure existing-test rewrites (#350).

---

## ✅ Resolved GitHub issues (milestone v8.3.0)

- **[Issue #352](https://github.com/schatt/sixlayer/issues/352)** — Space-aware toolbar action packing (uses `platformMenu`).
- **[Issue #320](https://github.com/schatt/sixlayer/issues/320)** — visionOS `SLF-visionOS-AllTests` runtime failures.
- **[Issue #319](https://github.com/schatt/sixlayer/issues/319)** — watchOS `SLF-watchOS-AllTests` runtime failures.
- **[Issue #318](https://github.com/schatt/sixlayer/issues/318)** — tvOS `SLF-tvOS-AllTests` runtime failures.
- **[Issue #355](https://github.com/schatt/sixlayer/issues/355)** — Prepare v8.3.0 release (docs / `--docs`).

---

## ⚠️ Migration / consumer notes

- Prefer `platformToolbarActions_L4` when you want density-aware packing; keep bare `platformMenu` when you already know you want a Menu.
- On watchOS / tvOS / visionOS, pin critical actions (`overflowEligible: false`) — overflow is omitted without Menu.
- Action IDs must be unique (duplicate IDs are unsupported).

---

## 📚 References

- [PlatformToolbarActionsLayer4Guide.md](../Framework/docs/PlatformToolbarActionsLayer4Guide.md)
- [AI_AGENT_v8.3.0.md](AI_AGENT_v8.3.0.md)
- Epic [#233](https://github.com/schatt/sixlayer/issues/233) (continued on v8.4.0)
