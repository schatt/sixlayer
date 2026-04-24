# UI test navigation contract (`SixLayerTestKit`)

Issue [#227](https://github.com/schatt/sixlayer/issues/227) introduces **typed** identifiers for consumer UI test navigation so selectors stay stable, validated, and self-documenting.

## Public types

| Type | Role |
|------|------|
| `UITestScreenId` | Top-level screen / flow anchor |
| `UITestRouteId` | Optional subsection within a screen |
| `UITestElementId` | Optional element (e.g. accessibility identifier contract) |
| `UITestNavigationContract` | Aggregate of the above |
| `UITestNavigationContractError` | Validation failures with deterministic `LocalizedError` messages |

## Typed vs plain `String`

- **Typed wrappers** (`UITestScreenId`, …) require `init(validating:)` so invalid or empty identifiers fail at construction time, not deep inside a UI test helper.
- **No `ExpressibleByStringLiteral`** on those types: string literals skip validation; callers must explicitly use `try UITestScreenId(validating:)` (or `UITestNavigationContract(screen:route:element:)`) so mistakes are visible at the call site.
- **Plain `String`** remains valid inside `rawValue` after validation for logging, `XCUIElement` queries, and persistence.

## Validation rules

Screen, route, and element identifiers share the same rules; only the thrown empty error (`emptyScreenId` vs `emptyRouteId` vs `emptyElementId`) differs by role.

1. Leading and trailing whitespace is trimmed.
2. After trim, the value must be non-empty (distinct errors for screen vs route vs element).
3. Allowed code points: ASCII letters, digits, `.`, `-`, `_` (common for reverse-DNS-style accessibility identifiers and stable route keys).

Extending allowed characters is a **semver-conscious** API change: add new initializers or configuration if you need Unicode identifiers later.

Optional XCUI assertion helpers built on these identifiers: [UITestContractAssertions.md](UITestContractAssertions.md) (#230).

## Non-goals

- No coupling to the SixLayer internal test app or demo routes.
- No XCUI types in this layer (#228+ will consume these contracts).
