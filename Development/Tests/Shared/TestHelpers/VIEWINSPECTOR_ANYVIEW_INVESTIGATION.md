# ViewInspector findAll returning empty – root cause

## Symptom

`verifyViewContainsText` and `verifyViewContainsImage` in `BaseTestClass` use:

```swift
let inspected = try AnyView(view).inspect()
let viewText = inspected.findAll(ViewInspector.ViewType.Text.self)
```

For views like `IntelligentDetailView.platformDetailView(for:)`, `platformPresentContent_L1(content: 42, …)`, and `platformPhotoDisplay_L4`, `viewText` / `viewImages` are **empty** even though the views do contain `Text` / `Image` in their hierarchy.

## Root cause

**ViewInspector’s `findAll(ViewType.Text.self)` does not recurse through `AnyView`.**

- `AnyView` is a type-erasure boundary. ViewInspector’s search stops at that boundary and does not traverse into the type-erased content.
- The framework often returns views wrapped in `AnyView` (e.g. `IntelligentDetailView` returns `AnyView(platformStandardDetailView(...)).automaticCompliance()`).
- Tests then wrap again with `AnyView(view).inspect()`, so the inspected root is an `AnyView` whose content (e.g. `ModifiedContent<AnyView<...>, AutomaticComplianceModifier>`) is never searched by `findAll`.
- Result: `findAll(Text.self)` / `findAll(Image.self)` returns `[]` even when `Text`/`Image` exist inside the wrapped content.

References:

- ViewInspector guide: “To traverse into AnyView content, use the `.anyView(index)` method.”
- Community notes: “AnyView creates a type erasure boundary that ViewInspector’s search functions may not traverse.”

## Fix

Before calling `findAll`, **unwrap the root** so the search runs on the content inside the outer `AnyView`:

1. After `let inspected = try AnyView(view).inspect()`, try to get the content of the root `AnyView` with `try inspected.anyView()`.
2. Use that as the search root: `let searchRoot = (try? inspected.anyView()) ?? inspected`.
3. Call `findAll` on `searchRoot`: `searchRoot.findAll(ViewType.Text.self)` (and similarly for `Image`).

If the framework view is itself `ModifiedContent<AnyView<Concrete>, Modifier>`, a single unwrap gets us to `ModifiedContent`; whether `findAll` then finds `Text` depends on whether ViewInspector recurses into `ModifiedContent`’s content. If one unwrap is not enough, the next step is to add recursive unwrapping (keep calling `anyView()` on the current root until it fails, then call `findAll` on the last unwrapped root).
