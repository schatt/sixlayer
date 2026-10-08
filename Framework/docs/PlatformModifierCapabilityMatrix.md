# Platform Modifier Capability Matrix

Secondary platforms (visionOS, tvOS, watchOS) do not clone iOS View modifiers. New and changed modifiers branch on `PlatformModifierCapabilityMatrix` (GitHub #448). Use `#if` only when `apiUnavailable` is true. When the branch is `.stubIdentity`, return `self`.

Host apps and XCUITest stay on **#392**–**#394**. This matrix is the product spine those epics consume.

## API

| Type | Role |
| --- | --- |
| `PlatformModifierCapability` | pointer, hover, haptics, pullToRefresh, keyboard, spatial, touch, swipe |
| `PlatformModifierCapabilityReading` | Detection inputs. `intrinsic(for:)` is the documented platform default before device probes. |
| `PlatformModifierCapabilityMatrix.resolved(_:)` | Pure resolution. Tests inject readings; they do not emulate another OS. |
| `PlatformModifierCapabilityMatrix.current` | Live reading: `RuntimeCapabilityDetection` plus `SixLayerPlatform.supportsKeyboardNavigation`. |
| `branch(for:)` | `.apply`, `.stubIdentity`, or `.skipUnavailableAPI` |

## Detection mapping

| Capability | Source |
| --- | --- |
| touch | `RuntimeCapabilityDetection.supportsTouch` |
| hover | `RuntimeCapabilityDetection.supportsHover` |
| haptics | `RuntimeCapabilityDetection.supportsHapticFeedback` |
| keyboard | `SixLayerPlatform.supportsKeyboardNavigation` (macOS and tvOS). No separate runtime probe. tvOS keyboard is the focus engine. |
| spatial | `platform == .visionOS`. No runtime probe. |
| pointer | macOS or visionOS, and hover is on. iPad pencil hover stays on `hover` only. |
| pullToRefresh | Touch on iOS or macOS. watchOS touch does not imply pull-to-refresh. |
| swipe | Touch. tvOS still skips because `DragGesture` is not in that SDK (#237). |

`intrinsic(for:)` matches those detection defaults: iOS touch and haptics, no hover; macOS hover and keyboard; watchOS touch and haptics; tvOS keyboard only; visionOS hover, no touch, no haptics. iPad pencil hover and macOS touchscreens show up only when the live reading says so.

## Branch for each intrinsic platform

| Capability | iOS | macOS | watchOS | tvOS | visionOS |
| --- | --- | --- | --- | --- | --- |
| touch | apply | stub | apply | stub | stub |
| hover | stub | apply | skip | skip | apply |
| haptics | apply | stub | apply | stub | stub |
| pullToRefresh | apply | stub | skip | skip | stub |
| keyboard | stub | apply | skip | apply | stub |
| spatial | skip | skip | skip | skip | apply |
| pointer | stub | apply | skip | skip | apply |
| swipe | apply | stub | apply | skip | stub |

Turning iOS touch off stubs pull-to-refresh and swipe and leaves haptics applied. Turning macOS touch on applies pull-to-refresh and swipe. iOS hover on (pencil) applies hover and still stubs pointer.

## Unit-lane policy when a capability is absent

| Branch | Modifier | Unit test |
| --- | --- | --- |
| `.apply` | Platform behavior for this capability. Not a copy of an iOS modifier. | Assert that behavior on the real host. |
| `.stubIdentity` | Return `self`. The SwiftUI API compiles; the capability is off. | Assert identity. Do not assert iOS behavior. |
| `.skipUnavailableAPI` | Do not reference the missing API. Guard the call site with `#if`. | Skip the observation. Do not compile an iOS clone under `#else`. |

`#if os(iOS)` followed by `#else self` is reserved for APIs whose SDK symbol is missing, and for existing iOS-named wrappers (`platformIOS*`). It is not the way to add visionOS, tvOS, or watchOS support.

```swift
switch PlatformModifierCapabilityMatrix.current.branch(for: .pullToRefresh) {
case .apply:
    // This platform's refresh. Do not paste platformIOSPullToRefresh.
    self.refreshable { onRefresh() }
case .stubIdentity:
    self
case .skipUnavailableAPI:
    // Also `#if` the site so watchOS/tvOS do not reference `refreshable`.
    self
}
```

## Where implementation lives

| Issue | Owns |
| --- | --- |
| **#376** | tvOS product. Keyboard applies (focus). Swipe, hover, pointer, and pull-to-refresh skip. |
| **#377** | watchOS product. Touch, swipe, and haptics apply. Pull-to-refresh, hover, pointer, keyboard, and spatial skip. `SixLayerHaptic.fire` is still UIKit-on-iOS; watchOS haptic playback belongs here. |
| **#378** | visionOS product. Spatial, pointer, and hover apply. Touch, haptics, swipe, and pull-to-refresh stub. |
| **#392**–**#394** | Host app and XCUITest. Do not duplicate those issues from this matrix. |
| **#379**–**#380** | Unit-lane observation paths. |
| **#233** | Full suite on every platform. |

## Out of scope

- Host apps
- Phantom Layer 5 performance modifiers (**#425**)
