## Status (current)

Investigation showed ViewInspector builds on macOS for the SDK versions we care about. SixLayer wires ViewInspector through normal SPM / Xcode target dependencies (`project.yml`, shared test helpers).

Tests use `#if canImport(ViewInspector)` where ViewInspector is optional. The historical **`VIEW_INSPECTOR_MAC_FIXED`** Swift active compilation condition was **removed** from test targets; do not re-add it unless you introduce a new, documented migration.

## Original problem (archival)

ViewInspector was once reported not to compile on macOS due to iOS-only SwiftUI types. Upstream [ViewInspector #405](https://github.com/nalexn/ViewInspector/issues/405) tracks vendor-side details; our notes in [README.md](./README.md) and [6layer_Issue.md](./6layer_Issue.md) describe what we did in-repo.

## Obsolete instructions (do not follow)

Older drafts referred to uncommenting `.define("VIEW_INSPECTOR_MAC_FIXED")` in `Package.swift` and using `#if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)`. That path is retired.
