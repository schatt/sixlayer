# Platform Export Actions Layer 4 Guide

## Overview

`platformExportActions_L4` composes existing Layer 4 share and print primitives for post-export file flows. It does **not** fold print into `platformShare_L4`.

**Implements:** [Issue #300](https://github.com/schatt/sixlayer/issues/300)

## When to Use

| Entry point | Pattern |
|-------------|---------|
| Post-export button (PDF + CSV) | `.platformExportActions_L4(isPresented:payload:options:onComplete:)` |
| macOS **File → Print** menu | `platformPrint_L4(content:options:)` directly |
| macOS **File → Share** menu | `platformShare_L4(items:from:onComplete:)` or export-actions with `showsPrint: false` |
| Single enabled action | Automatic fast path (no chooser) |

## API

### Types

```swift
public struct ExportActionPayload: @unchecked Sendable {
    public let fileURL: URL
    public let printContent: PrintContent?   // optional; PDF/image derived from URL when nil
    public let jobName: String?
    // iOS only:
    public let excludedShareActivities: [UIActivity.ActivityType]?
}

public struct ExportActionOptions: Sendable {
    public var showsShare: Bool = true
    public var showsPrint: Bool = true       // auto-disabled when not printable
    public var showsCopyPath: Bool = false
}

public enum ExportActionResult: Equatable, Sendable {
    case cancelled
    case shared(Bool)
    case printed(Bool)
}
```

### View modifier

```swift
.platformExportActions_L4(
    isPresented: $showExportActions,
    payload: exportPayload,
    options: .init(),
    onComplete: { result in /* ... */ }
)
```

### Imperative (fast path only)

```swift
let result = platformExportActions_L4(payload: payload, options: options)
```

**Return contract:**

- `nil` — no enabled actions, chooser required (use modifier), or presentation blocked
- `.cancelled` — user dismissed chooser or downstream UI
- `.shared(Bool)` / `.printed(Bool)` — action completed; `Bool` is underlying primitive success

When both share and print are enabled, use the **modifier** (presents `confirmationDialog` chooser on v1).

## Temp File Lifecycle

The caller creates the temp `fileURL`, passes it in `ExportActionPayload`, and deletes the file after `onComplete`. Generation and cleanup stay app/domain concerns.

## Related APIs

- `platformShare_L4(items:from:onComplete:)` — imperative share (Issue #300 adjunct)
- `platformShare_L4(isPresented:items:…)` — share sheet modifier
- `platformPrint_L4` — print dialog modifier and imperative function

## Accessibility / UITest

- Host uses `automaticCompliance(named: "platformExportActions_L4")`
- Chooser buttons expose stable identifiers:
  - `SixLayer.main.ui.platformExportActions_L4.share`
  - `SixLayer.main.ui.platformExportActions_L4.print`
  - `SixLayer.main.ui.platformExportActions_L4.cancel`
- Print path remains non-blocking under `-UITesting` (same contract as `platformPrint_L4`, Issue #261)

## Non-goals

- Framework `CommandMenu` / app menu templates
- Report PDF layout or CSV generation
- Adding print to `UIActivityViewController` activity list
