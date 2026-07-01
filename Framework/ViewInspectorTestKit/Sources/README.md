# SixLayerViewInspectorTestKit

Optional test-only product for [ViewInspector](https://github.com/nalexn/ViewInspector) consumers of SixLayer. Keeps ViewInspector out of app and framework release targets while sharing the same inspection helpers SixLayer uses internally.

`SixLayerTestKit` intentionally does **not** depend on ViewInspector; use this product when you need typed SwiftUI hierarchy inspection in unit tests.

## Installation

### Swift Package Manager

Add SixLayer as a dependency, then link the test kit from **test targets only**:

```swift
.testTarget(
    name: "MyAppViewInspectorTests",
    dependencies: [
        "MyApp",
        .product(name: "SixLayerFramework", package: "SixLayerFramework"),
        .product(name: "SixLayerViewInspectorTestKit", package: "SixLayerFramework"),
    ]
)
```

ViewInspector ≥ 0.10.x is resolved transitively via the test kit.

### Xcode (local SixLayer checkout)

Link `SixLayerViewInspectorTestKit_iOS` or `SixLayerViewInspectorTestKit_macOS` from your test bundle target only.

## Usage

```swift
import SwiftUI
import ViewInspector
import SixLayerViewInspectorTestKit

private struct SettingsRow: View, Inspectable {
    var body: some View {
        HStack { Text("Title") }
    }
}

@MainActor
func testRowLayout() throws {
    let vStack = try firstVStackInView(SettingsRow(), minChildren: 1)
    #expect(vStack.count >= 1)
}
```

## When to use typed inspection vs accessibility identifiers

Follow SixLayer issue [#178](https://github.com/schatt/sixlayer/issues/178):

| Approach | Prefer when |
|----------|-------------|
| **Accessibility identifiers** (`accessibilityIdentifier`, XCUITest) | Contract you want stable across refactors; navigation and end-to-end flows; views wrapped in `AnyView` where hierarchy traversal is brittle. |
| **Typed ViewInspector** (`inspectView`, `withInspectedView*`) | Unit-level layout/structure assertions on concrete `Inspectable` view types; verifying modifier stacks and child counts without launching the app. |
| **AnyView / unwrapped helpers** (`withInspectedViewUnwrapped`, `firstVStackInHierarchy`) | Production view types are not `Inspectable` or are type-erased; last resort before identifiers. Unwrap before `findAll` — see `VIEWINSPECTOR_ANYVIEW_INVESTIGATION.md` in SixLayer's internal test helpers. |

**Default:** add accessibility identifiers for user-visible contract surfaces; use this kit for focused unit tests on inspectable view builders.

## Exported API (phase 1)

- `inspectView`, `withInspectedView`, `withInspectedViewThrowing`
- Type-erased `AnyView` / `ClassifiedView` overloads and `*Unwrapped` variants
- `firstVStackInHierarchy`, `firstVStackInView`
- `NoVStackInHierarchy`

## Not included (phase 2 / follow-up)

`ViewInspectorInspectableConformances` for internal SixLayer form views may remain consumer-local until inner types are exported or conformances ship in this kit with `@testable import SixLayerFramework`. See issue [#327](https://github.com/schatt/sixlayer/issues/327).

## Related

- [#326](https://github.com/schatt/sixlayer/issues/326) — ViewInspector 0.10.x typed inspect API
- [#178](https://github.com/schatt/sixlayer/issues/178) — ViewInspector policy in SixLayer tests
- `SixLayerTestKit` — service mocks, UI test navigation contract (no ViewInspector)
