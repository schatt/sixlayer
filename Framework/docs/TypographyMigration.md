# Typography migration (Dynamic Type)

For apps replacing fixed `.font(.system(size:))` call sites (e.g. [CarManager #493](https://github.com/schatt/CarManager/issues/493)).

## Recommended mapping

| Use case | API |
|----------|-----|
| Body, labels, controls | `Font.platformBody`, `.platformCallout`, etc., or `DynamicFontResolver` / design tokens (#294) |
| Empty-state / hero SF Symbols at a design size (40–80pt) | `View.platformDecorativeIconFont(designSize:relativeTo:)` (default anchor `.largeTitle`) |
| Custom point size that must scale | `Font.platformSystem(size:relativeTo:weight:design:contentSize:)` |
| Camera overlays, pinpoints, non-scaling chrome | `Font.platformFixedSystem(size:)` |

## Breaking change

`Font.platformSystem(size:)` **now scales** with Dynamic Type (iOS via `UIFontMetrics`; macOS via `SixLayerContentSizeCategory.typographyScaleFactor`). If you relied on a fixed size, switch to `platformFixedSystem(size:)`.

## Examples

```swift
// Before
Image(systemName: "car.fill")
    .font(.system(size: 48))

// After (preferred for decorative icons)
Image(systemName: "car.fill")
    .platformDecorativeIconFont(designSize: 48)

// Or explicit font (e.g. when not on a View chain)
Text("★")
    .font(.platformSystem(size: 48, relativeTo: .largeTitle))
```

## Framework internals

Layer1 empty states and Layer4 decorative icons use `platformDecorativeIconFont`. `BarcodeOverlayView` uses `platformFixedSystem` for viewfinder chrome (documented exception).

Related: #295 `DynamicFontResolver`, #294 design-token typography.
