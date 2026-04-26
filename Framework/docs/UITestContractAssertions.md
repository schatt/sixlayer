# UITest contract assertions (`SixLayerTestKit`)

Issue [#230](https://github.com/schatt/sixlayer/issues/230) adds **optional** helpers around common ``XCUIElement`` checks so consumer suites can share consistent failure wording. They live next to the navigation contract (#227) and resolver (#228) but do **not** replace XCTest.

## API

In Xcode targets `SixLayerTestKit_iOS` / `SixLayerTestKit_macOS`, these APIs are always built with XCTest linked (no `#if canImport` gate) so consumer UI test bundles resolve them reliably.

| Helper | Use when |
|--------|-----------|
| ``UITestContractAssertions/assertExists(_:timeout:_:file:line:)`` | You want a single “must appear” wait with a uniform message. |
| ``UITestContractAssertions/assertHittable(_:timeout:_:file:line:)`` | You must tap or interact; existence alone is insufficient. |
| ``UITestContractAssertions/assertNonEmptyAccessibilityIdentifier(_:timeout:_:file:line:)`` | Contract tests require a stable identifier on a resolved element. |
| ``UITestContractAssertions/assertNonEmptyAccessibilityLabel(_:timeout:_:file:line:)`` | You explicitly require a VoiceOver-visible label (often **not** true for decorative SwiftUI). |

## When to use helpers vs native XCTest

- Use **native** ``XCTAssert`` / ``XCTAssertEqual`` when asserting on **values** you already queried, when composing **custom** messages, or when matching **queries** (e.g. `XCTAssertEqual(app.buttons.count, 3)`).
- Use **these helpers** when several tests repeat the same **wait + boolean** pattern and you want **one-line** calls and **shared** diagnostic phrasing.
- Do **not** route every assertion through helpers — they add little when the assertion is already a single `XCTAssertTrue(element.waitForExistence(...))`.

## Consumer example

See ``SixLayerUITestNavigatorConsumerSmokeUITests`` in `Development/Tests/SixLayerFrameworkUITests` (#231): smoke tests call ``SixLayerUITestNavigator`` together with ``UITestContractAssertions`` on a **minimal** TestApp host launched with `-OpenUITestContractSmokeHost` (stable `com.sixlayer.smoke.*` identifiers only).

## SwiftPM unit bundles

Helpers require a linked XCTest host with UI automation configured. **SwiftPM** `swift test` **unit** targets cannot exercise them without a UI test runner; coverage lives in the **UI test** target, not in `SixLayerUITestNavigationContractTests`.

## Relation to other docs

- Navigation primitives: ``SixLayerUITestNavigator`` — [SixLayerUITestNavigator.md](SixLayerUITestNavigator.md)
- Identifier validation: [UITestNavigationContract.md](UITestNavigationContract.md)
- Resolver ordering: [UITestContractElementResolver.md](UITestContractElementResolver.md)
