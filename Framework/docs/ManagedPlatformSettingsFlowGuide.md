# Managed platform settings flow (Issue #209)

This guide describes the **default managed settings** API built on `platformSettingsContainer_L4`: one top-level selection model, iPhone stack semantics, and optional **sub-pane** depth inside the detail column using a typed `NavigationStack` path.

## When to use which API

| Need | API |
|------|-----|
| Full control, custom routing, or non-standard UX | `platformSettingsContainer_L4` directly (manual `selectedCategory` or your own bindings). |
| Standard master–detail settings with framework-owned shell + selection | `platformManagedSettingsTopLevel_L4` + `PlatformManagedSettingsTopLevelState`. |
| Hierarchical screens **inside** a top-level pane (e.g. Data → Cleanup) | `PlatformManagedSettingsDetailNavigationState` + `platformManagedSettingsDetailNavigationStack_L4` + `navigationDestination(for:)`. |

Managed APIs **compose with** the navigation layout resolver work (#204 / #206): they delegate to `platformSettingsContainer_L4` for the outer shell; they do not replace resolver-driven split/compact behavior.

### Resolver behavior by platform (outer shell)

| Context | Outer shell | Resolver (#204 / #206) |
|--------|-------------|-------------------------|
| **iPad / macOS** | `platformSettingsContainer_L4` uses `Layer4NestedSplitShellPresentationHost` | **Yes** — width-driven `NavigationLayoutCompactPresentation` (full split, detail-only inner collapse, overlay outer sidebar) matches settings and app navigation contracts. |
| **iPhone** | `NavigationStack` + selection-driven detail (`navigationDestination(isPresented:)` when using managed bindings) | **N/A for nested split** — there is no inner/outer dual-sidebar squeeze; stack semantics are always the correct model. Managed flow still uses the same `selectedCategory` wiring as manual `platformSettingsContainer_L4`. |

Sub-pane stacks (`platformManagedSettingsDetailNavigationStack_L4`) sit **inside** the detail column (or inside the iPhone pushed detail); they do not bypass resolver output on iPad/macOS.

## Compile-time top-level panes

Define a `Hashable` enum (`CaseIterable` for a static list in source order) and use:

```swift
@State private var topLevel = PlatformManagedSettingsTopLevelState<MyPane>(deviceType: DeviceType.current)
```

or `init(orderedTopLevelPaneIDs:deviceType:)` when the list is not `CaseIterable`.

Bind into the shell with:

```swift
EmptyView()
    .platformManagedSettingsTopLevel_L4(
        columnVisibility: $columnVisibility,
        state: $topLevel,
        sidebar: { sidebarView },
        detail: { detailView }
    )
```

Use `PlatformManagedSettingsTopLevelState.anyHashableBinding($topLevel)` only if you call `platformSettingsContainer_L4` yourself.

## Sub-panes (detail stack)

1. Hold stack state: `@State private var detailNav = PlatformManagedSettingsDetailNavigationState<SubPaneID>()`.
2. When the user picks a **different top-level** pane, clear sub-pane depth so routes do not carry across categories. Prefer `PlatformManagedSettingsFlowLogic.selectTopLevelPane(_:topLevel:detailNavigation:)` from sidebar actions (updates top-level selection and calls `popToRoot()` on the detail stack).
3. Wrap the **root** of the detail column:

```swift
EmptyView()
    .platformManagedSettingsDetailNavigationStack_L4(state: $detailNav) {
        List {
            NavigationLink(value: SubPaneID.cleanup) { Text("Cleanup") }
        }
        .navigationDestination(for: SubPaneID.self) { id in
            // destination for id
        }
    }
```

Path updates sync through `navigationPathBinding`; the Layer 4 modifier wires `NavigationStack(path:)` on supported OS versions.

## Migration from manual `selectedCategory`

**Before:** `@State private var selectedCategory: String?` and `platformSettingsContainer_L4(selectedCategory: $selectedCategory)`.

**After:** Replace optional string with `PlatformManagedSettingsTopLevelState<YourPaneEnum>(deviceType:)` and `platformManagedSettingsTopLevel_L4(state: $topLevel, ...)`. Sidebar buttons use `state.selectTopLevel` / `clearTopLevelSelection` via a `Binding` (or mutate `State` in place).

**Sub-panes:** Add `PlatformManagedSettingsDetailNavigationState` and the detail stack modifier only inside the detail pane; keep top-level selection in `PlatformManagedSettingsTopLevelState`.

## Compile-checked sample

The unit test suite includes a **full** example that must compile, including **three levels** of navigation on the Data pane (top-level category → cleanup list → confirmation):

`Development/Tests/SixLayerFrameworkUnitTests/Features/Navigation/ManagedPlatformSettingsFlowGuideExampleTests.swift`

Run: `swift test --filter 'PlatformManagedSettings'`.

## Acceptance criteria (#209) — where this is covered

- **Unified routing / no adopter branching for the default path:** Adopters use `PlatformManagedSettingsTopLevelState` + optional `PlatformManagedSettingsDetailNavigationState`; split vs stack is implemented inside `platformSettingsContainer_L4` and `PlatformManagedSettingsFlowLogic`.
- **Sub-panes:** Detail `NavigationStack` + `navigationDestination(for:)`; switching top-level panes should use `PlatformManagedSettingsFlowLogic.selectTopLevelPane` so depth resets.
- **Compose with #202 / #204–#208:** Managed entry points call `platformSettingsContainer_L4` only; iPad/macOS inherit resolver-driven presentation from that API.
- **Compile-time pane structure:** Prefer a `Hashable` enum with `CaseIterable` (or fixed `orderedTopLevelPaneIDs`); see ``PlatformManagedSettingsTopLevelState``.
- **Escape hatch:** Use `platformSettingsContainer_L4` directly (see table at top of this guide).
- **Tests:** `swift test --filter 'PlatformManagedSettings'` (routing policy + Layer 4 smoke + this compile-checked example).

## Related

- `platformSettingsContainer_L4` — `PlatformNavigationLayer4.swift` (Issue #58).
- `Framework/Examples/PlatformSettingsContainerExample.swift` — manual `selectedCategory` patterns (legacy style).
