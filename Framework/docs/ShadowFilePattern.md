# Shadow File Pattern for Type Enforcement

## Overview

The shadow file pattern is a compile-time enforcement technique used to catch direct usage of types or functions that should be replaced with platform-specific alternatives. It works by creating a typealias that shadows the original type in DEBUG builds, causing compilation errors when the original type is used directly.

## When to Use

Use this pattern when:
- You want to replace direct usage of a SwiftUI/system type with a platform-specific wrapper
- You need to ensure consistent behavior across all usages (e.g., automatic accessibility identifier application)
- You want to catch violations at compile time during development

## Example: Picker Shadow File

### Problem
We wanted to replace all direct `Picker()` calls with `platformPicker()` to ensure automatic accessibility identifier application (Issue #163). However, it was difficult to find all direct `Picker()` calls in a large codebase.

### Solution: Shadow File

Create a file (e.g., `PickerShadow.swift`) that shadows the type in DEBUG builds:

```swift
//
//  PickerShadow.swift
//  SixLayerFramework
//
//  Shadow file to catch all direct Picker() calls in DEBUG builds
//  This forces us to use platformPicker() instead, ensuring consistent
//  accessibility identifier application (Issue #163)
//

import SwiftUI

#if DEBUG
// Shadow typealias to catch direct Picker() calls
// Forces use of platformPicker() instead for consistent accessibility (Issue #163)
// This prevents direct SwiftUI.Picker() calls and ensures platformPicker() is used
typealias Picker = DirectPickerCallForbidden_UsePlatformPickerInstead
#endif

/// Marker type to prevent direct Picker() calls
/// Use platformPicker() instead for automatic accessibility identifier application
enum DirectPickerCallForbidden_UsePlatformPickerInstead {
    // This type cannot be instantiated - it's only used as a typealias target
    // to catch direct Picker() calls at compile time
}
```

### How It Works

1. **In DEBUG builds**: The `typealias Picker = DirectPickerCallForbidden_UsePlatformPickerInstead` shadows SwiftUI's `Picker` type
2. **Direct calls fail**: Any code that tries to use `Picker(...)` directly will fail to compile because `DirectPickerCallForbidden_UsePlatformPickerInstead` cannot be instantiated
3. **Explicit qualification works**: Code that uses `SwiftUI.Picker(...)` explicitly will still work, allowing the platform-specific wrapper to use the original type internally
4. **In RELEASE builds**: The shadow is removed, so the code compiles normally (though ideally all direct calls should be replaced by then)

### Workflow

1. **Create the shadow file** with the typealias
2. **Build the project** - compilation errors will reveal all direct usages
3. **Replace direct calls** with the platform-specific alternative (e.g., `platformPicker()`)
4. **Use explicit qualification** in the platform-specific implementation (e.g., `SwiftUI.Picker(...)`)
5. **Remove the shadow file** once all direct calls have been replaced

### Benefits

- **Compile-time enforcement**: Catches violations immediately during development
- **Comprehensive coverage**: Finds all usages automatically, even in deeply nested code
- **Clear error messages**: The typealias name can be descriptive (e.g., `DirectPickerCallForbidden_UsePlatformPickerInstead`)
- **Safe for implementation**: Explicit qualification (`SwiftUI.Picker`) allows the wrapper to use the original type

### Limitations

- **DEBUG-only**: Only works in DEBUG builds (by design, to allow release builds)
- **Type-level only**: Works for types, not for functions (though you can shadow function types)
- **Requires explicit qualification**: The platform-specific implementation must use fully qualified names

### Alternative Approaches

If the shadow file pattern doesn't work for your use case, consider:
- **Linter rules**: Custom SwiftLint rules to catch patterns
- **Code search**: Systematic grep/search for patterns
- **Code review**: Manual review process
- **Deprecation warnings**: Mark functions as deprecated with migration guidance

## Related Patterns

- **Platform-specific wrappers**: Functions like `platformPicker()` that wrap system types
- **General rule**: `platformFoo` should return the same type as `Foo` (e.g., `platformPicker` returns `some View` just like `Picker`)

## Historical Context

This pattern was used successfully in Issue #163 to replace all direct `Picker()` calls with `platformPicker()` throughout the codebase. After all direct calls were replaced, the shadow file was removed.

## References

- Issue #163: Automatic accessibility identifier application for Pickers
- `Framework/Sources/Extensions/Platform/PlatformSpecificViewExtensions.swift`: Implementation of `platformPicker()`
