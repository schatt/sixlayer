# ViewInspector Compilation Error on macOS SDK 26

**Issue filed:** [GitHub Issue #405](https://github.com/nalexn/ViewInspector/issues/405)

## Summary
ViewInspector fails to compile on macOS SDK 26 due to missing SwiftUI types that are iOS-only.

## Environment
- **macOS SDK Version**: 26.0
- **Xcode Version**: 26.0.1 (Build 17A400)
- **Swift Version**: 6.2 (swift-6.2-RELEASE)
- **ViewInspector Version**: 0.9.7 - 0.10.3 (all versions affected)

## Error Details

### Missing SwiftUI Types on macOS
The following SwiftUI types are not available in macOS SDK 26, but ViewInspector attempts to use them:

1. **VideoPlayer** (`Sources/ViewInspector/SwiftUI/VideoPlayer.swift`)
   - Error: `cannot find type 'VideoPlayer' in scope`
   - Line 85: `extension VideoPlayer: SingleViewProvider`

2. **SignInWithAppleButton** (`Sources/ViewInspector/SwiftUI/SignInWithAppleButton.swift`)
   - Error: `cannot find type 'SignInWithAppleButton' in scope`
   - Multiple locations in the file

3. **Map, MapAnnotation, MapMarker, MapPin** (`Sources/ViewInspector/SwiftUI/Map.swift` and `MapAnnotation.swift`)
   - Errors:
     - `cannot find type 'MapAnnotation' in scope`
     - `cannot find type 'MapMarker' in scope`
     - `cannot find type 'MapPin' in scope`
     - `cannot find type 'MapUserTrackingMode' in scope`
     - `cannot find type 'MapInteractionModes' in scope`
     - `cannot find type '_DefaultAnnotatedMapContent' in scope`
     - `cannot find type '_MapAnnotationData' in scope`

### Complete Error Output
```
/Users/schatt/code/github/6layer/.build/checkouts/ViewInspector/Sources/ViewInspector/SwiftUI/VideoPlayer.swift:85:11: error: cannot find type 'VideoPlayer' in scope
extension VideoPlayer: SingleViewProvider {
           `- error: cannot find type 'VideoPlayer' in scope

/Users/schatt/code/github/6layer/.build/checkouts/ViewInspector/Sources/ViewInspector/SwiftUI/SignInWithAppleButton.swift:56:32: error: cannot find type 'SignInWithAppleButton' in scope
func labelType() throws -> SignInWithAppleButton.Label {
                               `- error: cannot find type 'SignInWithAppleButton' in scope

/Users/schatt/code/github/6layer/.build/checkouts/ViewInspector/Sources/ViewInspector/SwiftUI/Map.swift:57:39: error: cannot find type 'MapUserTrackingMode' in scope
func userTrackingMode() throws -> MapUserTrackingMode {
                                 `- error: cannot find type 'MapUserTrackingMode' in scope
```

## Cause
These SwiftUI types (`VideoPlayer`, `SignInWithAppleButton`, `Map` variants) are iOS-only and not available on macOS. ViewInspector currently has conditional compilation guards for `canImport(AVKit)` and `canImport(AuthenticationServices)` but does not exclude the code paths for macOS.

## Expected Behavior
ViewInspector should compile on macOS with these iOS-only view types conditionally excluded.

## Proposed Solution
Add `#if !os(macOS)` guards around the affected files or code sections:

- `Sources/ViewInspector/SwiftUI/VideoPlayer.swift` - Wrap entire file or extension in `#if !os(macOS)`
- `Sources/ViewInspector/SwiftUI/SignInWithAppleButton.swift` - Wrap entire file in `#if !os(macOS)`
- `Sources/ViewInspector/SwiftUI/Map.swift` - Add macOS exclusion to existing guards
- `Sources/ViewInspector/SwiftUI/MapAnnotation.swift` - Add macOS exclusion to existing guards
- `Sources/ViewInspector/ViewSearchIndex.swift` - Conditionally include entries in the array

## Reproduction Steps
1. Create a new Swift Package with macOS as a target
2. Add ViewInspector as a test dependency
3. Attempt to build the test target on macOS SDK 26
4. Observe compilation errors

## Impact
- Cannot run tests on macOS that depend on ViewInspector
- Blocks cross-platform testing workflows
- Affects CI/CD pipelines targeting macOS

## Workaround Implementation

We've implemented a comprehensive workaround that allows our test suite to work around this issue:

### Our Solution
1. **Created `ViewInspectorWrapper.swift`**: A centralized wrapper that abstracts ViewInspector usage
2. **Conditional compilation in tests**: `#if canImport(ViewInspector)` (no macOS-specific compile flag)
3. **Updated many test files**: See [FIXED_FILES.md](./FIXED_FILES.md) for the historical file list

### Files Updated
See [FIXED_FILES.md](./FIXED_FILES.md) for a complete list of all 38 test files that have been updated.

### Implementation Details
- **Wrapper location**: `Development/Tests/Shared/TestHelpers/` (current repo layout)
- **Pattern used**: `#if canImport(ViewInspector)` … `#else` … `#endif`
- **Xcode wiring**: ViewInspector SPM dependency and test targets in `project.yml` (the old `VIEW_INSPECTOR_MAC_FIXED` active compilation condition was removed)

### Previous Workarounds (Not Used)
1. Use iOS-only test targets
2. Disable tests that require ViewInspector on macOS
3. Use a different testing framework for macOS-specific tests

## Related Files
- `Sources/ViewInspector/SwiftUI/VideoPlayer.swift`
- `Sources/ViewInspector/SwiftUI/SignInWithAppleButton.swift`
- `Sources/ViewInspector/SwiftUI/Map.swift`
- `Sources/ViewInspector/SwiftUI/MapAnnotation.swift`
- `Sources/ViewInspector/ViewSearchIndex.swift`

## Additional Context
Attempting to manually patch by adding `#if !os(macOS)` guards introduces syntax errors because:
1. The conditional compilation directives conflict with existing `#if canImport` blocks
2. Adding `#if...#endif` inside array literals causes parsing errors
3. Map.swift and MapAnnotation.swift already have `#if canImport(MapKit)` blocks that would need to be changed to `#if !os(macOS) && canImport(MapKit)`

