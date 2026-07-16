# Platform Toolbar Actions Packing (Layer 4)

## Overview

Space-aware toolbar packing owns **density** across platforms. It keeps up to *K* actions as toolbar controls and packs the rest into an explicit overflow menu via `platformMenu` (iOS / macOS). It does **not** use the system toolbar’s fold-into-`…` behavior.

**Implements:** [Issue #352](https://github.com/schatt/sixlayer/issues/352)

## Related APIs (do not confuse)

| API | Role |
|-----|------|
| `platformMenu` ([#321](https://github.com/schatt/sixlayer/issues/321)) | Small Menu primitive (`Menu { } label: { }` on iOS/macOS; label passthrough elsewhere) |
| `platformToolbarActions_L4` / `PlatformToolbarActionsPacker` (#352) | Capacity + priority packing that *uses* `platformMenu` for overflow |
| System toolbar `…` collapse | Opaque, placement-dependent OS behavior — **not** used here |

Use bare `platformMenu` when you already know you want a Menu. Use packing when you want declared capacity and priority to decide what stays inline.

## Capacity model

- Prefer **declared** capacity (`PlatformToolbarActionsCapacity`) over live geometry.
- `platformDefault`: iOS **2**, macOS **4**, tvOS/visionOS **3**, watchOS **1**.
- Lower `priority` stays visible sooner; equal priority keeps input order.
- `overflowEligible: false` **pins** an action: never enters overflow (may exceed `maxVisible`).

## Platforms without Menu

On watchOS / tvOS / visionOS, `platformMenu` is a label passthrough. Packing still runs; overflow IDs are **omitted** (no fake Menu). Pin critical actions with `overflowEligible: false`.

## Usage

```swift
.toolbar {
    platformToolbarActions_L4(
        [
            PlatformToolbarActionItem(id: "edit", priority: 0, label: "Edit", systemImage: "pencil") {
                edit()
            },
            PlatformToolbarActionItem(id: "share", priority: 1, label: "Share", systemImage: "square.and.arrow.up") {
                share()
            },
            PlatformToolbarActionItem(id: "delete", priority: 2, label: "Delete", systemImage: "trash") {
                delete()
            }
        ],
        capacity: .platformDefault
    )
}
```

### Pure policy (unit-testable)

```swift
let packed = PlatformToolbarActionsPacker.pack(descriptors, capacity: .init(maxVisible: 2))
let plan = PlatformToolbarActionsPacker.renderPlan(for: descriptors, capacity: .init(maxVisible: 2))
```

## Tests

`PlatformToolbarActionsPackingTests` — capacity math, pins, platform defaults, partition, render plans (Menu vs no-Menu).
