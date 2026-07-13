# UI Test Strategy (supersedes one-launch consolidation draft)

**Status:** Historical “one launch + navigate everywhere” plan is **superseded** by #316 / #348.

## North star

The TestApp exists only to exercise the framework. XCUITests should:

1. **Deep-link** via launch arguments (`-Open…`, optional `-*Section=`).
2. **Land** on an **exact** host-root accessibility identifier (`exactNamed("…-host-root")`).
3. **Assert** via exact identifiers (or a single exact text predicate) — **not** menu scroll discovery, type-slot query ladders, or sequential navBar/staticText/CONTAINS OR waits.

Do **not** add URL-scheme routing unless a future need appears; launch args already isolate XCUITest runs.

## Deliberate exceptions

| Surface | Why it stays |
|---------|----------------|
| TestKit `UITestContractElementResolver` / `contractResolutionOrder` | Product API for consumers — keep. |
| `SixLayerUITestNavigator` Back / smoke host | Proves navigator API on `-OpenUITestContractSmokeHost` only. |
| Form/table scroll helpers (`xcuiSwipe…`) | Interaction with tall forms (#261), **not** discovery of which screen to open. |

## Removed / do not revive

- `navigateToLayerExamples` / `navigateBackToLaunch` / `findElement` type cascades in suite helpers.
- Launch-page browse + scroll-as-discovery to reach Layer N examples.
- Stale Phase-1 design of one shared app launch with in-suite menu navigation.

## Layer coverage checklist

| Area | Deep link | Host root id |
|------|-----------|--------------|
| Layer 2 | `-OpenLayer2Examples` | `layer2-examples-host-root` |
| Layer 3 | `-OpenLayer3Examples` | `layer3-examples-host-root` |
| Layer 4 | `-OpenLayer4Examples` + `-L4Section=` | section header ids |
| Layer 5 | `-OpenLayer5Accessibility` | `layer5-examples-host-root` |
| Layer 6 | `-OpenLayer6Examples` | `layer6-examples-host-root` |
| Cat A Global Off | `-OpenCategoryAAccessibility` `-CategoryAGlobalAutoOff` | `category-a-global-off-host-root` |
| Identifier Edge Case | `-OpenLayer4IdentifierEdgeCase` | `identifier-edge-case-host-root` |
| Category B | `-OpenDetailViewCategoryB` | `category-b-detail-host-root` |

## Wall-clock note

After menu navigation is gone, remaining time is mostly **process relaunch** (intentional for parallel isolation) and real interactions — not query ladders.
