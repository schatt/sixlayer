# AI Agent Guide - SixLayer Framework v8.3.0

**Version**: v8.3.0  
**Release Date**: TBD (prep)  
**Release type**: Minor (on v8.2.1)  
**Primary issues**: [#352](https://github.com/schatt/sixlayer/issues/352), [#318](https://github.com/schatt/sixlayer/issues/318)–[#320](https://github.com/schatt/sixlayer/issues/320)

## 🎯 What's in v8.3.0

- **Toolbar packing (#352):** `PlatformToolbarActionsPacker` + `platformToolbarActions_L4`. Declared capacity / priority / pins; overflow via `platformMenu` on iOS/macOS; overflow omitted on watchOS / tvOS / visionOS.
- **Platform AllTests runtime (#318–#320):** tvOS / watchOS / visionOS lane expectation and fixture fixes under Epic #233.
- Bootstrap / UITest install failures for tvOS/watchOS continue on **v8.4.0** (#353, #354, epic #233).

## Agent notes

- Do **not** confuse packing with bare `platformMenu` (#321) or with system toolbar `…` collapse. See [PlatformToolbarActionsLayer4Guide.md](../Framework/docs/PlatformToolbarActionsLayer4Guide.md).
- Prefer unique action IDs; `partition` / L4 indexing assume uniqueness.
- Pin critical actions with `overflowEligible: false` on platforms without Menu.
- TDD: compile failures are never deliberate red; pure rewrites of existing coverage do not need a new red (#350).

## References

- [RELEASE_v8.3.0.md](RELEASE_v8.3.0.md)
- [AI_AGENT_v8.2.1.md](AI_AGENT_v8.2.1.md) — prior patch baseline
- [AI_AGENT_v8.2.0.md](AI_AGENT_v8.2.0.md) — prior minor XCUI / parallel guidance
