# Live Data Scanner Guide

This guide covers how to use the Layer 4 live scanner APIs introduced for VisionKit `DataScannerViewController` workflows.

## When to use this API

Use live scanner APIs when you need **recognized text/barcodes from camera viewfinder input** (tap/select recognized items).

Do not use this API when you need only image capture/selection:
- use `platformCameraInterface_L4` for camera image capture
- use `platformPhotoPicker_L4` for photo library image selection

## Capability gating

Gate scanner entry using runtime capabilities:

- `RuntimeCapabilityDetection.Photos.supportsLiveDataScanner`

If unavailable, show fallback UI (camera/photo picker or explanatory copy).

## Layer 4 API surface

Core content:
- `platformDataScannerContent_L4(...)`

Presented flows:
- `platformDataScannerInterface_L4(...)` (uses configuration presentation style)
- `platformDataScannerInterface_L4AsSheet(...)`
- `platformDataScannerInterface_L4AsFullScreenCover(...)`

Configuration:
- `PlatformDataScannerConfiguration`
  - recognized data types (text / filtered text / barcode symbologies)
  - quality level
  - highlights / guidance / pinch-to-zoom / high-frame-rate tracking
  - region of interest
  - presentation style

## Top app message (required UX support)

Pass app copy via `bannerMessage` to show an instructional/status message at the top of the scanner UI.

Examples:
- "Tap the serial number, then Done"
- "Select amount first, then account number"

## Callback model

Scanner APIs expose:
- tap callback (`onItemTap`)
- incremental callbacks (`onItemsAdded`, `onItemsUpdated`, `onItemsRemoved`)
- unavailability callback (`onBecameUnavailable`)

Use these to keep host state synchronized with recognized items.

## Session control

`PlatformDataScannerSessionController` provides:
- `startScanning()`
- `stopScanning()`
- `capturePhoto()`

Attach the controller to scanner content/presentation APIs and call these from host logic when needed.

## Multi-field mapping pattern

The framework returns recognized items; field assignment policy is app-owned.

Typical pattern:
1. user selects active field in form
2. user taps recognized text/barcode
3. app routes payload to active field
4. app advances focus to next field

This supports flows like "first tap -> field A, second tap -> field B".

## Platform behavior notes

- VisionKit scanner path is iOS-focused.
- Non-supported platforms/contexts should use fallback UI.
- Keep scanner and fallback paths additive; do not replace existing photo/camera flows globally.
