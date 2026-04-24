# UITest contract element resolver (`SixLayerTestKit`)

Issue [#228](https://github.com/schatt/sixlayer/issues/228) adds a **deterministic, identifier-first** resolver for XCUI tests so consumers do not re-implement `descendants(matching:)` fallback chains.

## API

- ``UITestContractXCUIQuerySlot`` — logical categories (button, cell, link, …).
- ``UITestContractXCUIQuerySlot/contractResolutionOrder`` — **stable** fallback ordering (changing it is a semver-visible contract change; update tests when intentional).
- ``UITestContractElementResolverConfiguration`` — ``timeoutPerSlot`` (default `0.25` s) passed to each candidate’s `waitForExistence`.
- ``UITestContractElementResolver/findFirstExisting(under:elementId:slots:configuration:)`` — XCUI entry point (`#if canImport(XCTest)`).
- ``UITestContractElementResolverCore`` — module-internal closure-driven loop used by tests to prove ordering without launching an app.

## Fallback semantics

For each slot **in order**:

1. Build `root.descendants(matching: slot.xcElementType).matching(identifier:).element`.
2. Call `waitForExistence(timeout: timeoutPerSlot)`.
3. Return the first element that becomes available.

Total worst-case wait is roughly `timeoutPerSlot * slotCount` when nothing matches (each slot is tried to its timeout).

## iOS vs macOS

The **same** ordering is used on both platforms. Differences in the accessibility tree (e.g. table rows exposed as `cell` on iOS vs `outlineRow` on macOS in some hosts) are **host-specific**; hosts that need a different axis should pass a custom `slots` array (prepend `.other` or app-specific probes) without changing the library default until a documented cross-platform policy exists.

## Relation to #229

Navigator primitives should call ``UITestContractElementResolver/findFirstExisting`` (or the core with custom materialization) rather than embedding ad-hoc query order.
