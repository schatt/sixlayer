# L1 Functions @MainActor Audit Plan

## Summary
Audit all L1 functions to remove unnecessary `@MainActor` annotations, similar to the L4 audit.

## Key Finding from L4 Audit
- Functions that only create/compose views (value types) don't need `@MainActor`
- Functions that access `@Published` properties require `@MainActor`
- Functions that access main-thread-only APIs require `@MainActor`

## L1 Functions That Need @MainActor

### Functions that call `AccessibilityIdentifierConfig.shared.setScreenContext()`
Since `currentScreenContext` is a `@Published` property, these functions need `@MainActor`:
1. `platformPresentFormData_L1` (field version) - line 249
2. `platformPresentMediaData_L1` (array version) - line 328
3. `platformPresentSettings_L4` - line 765

### Functions that might need @MainActor
- Need to check if any access `@Published` properties from `ObservableObject` types
- Need to check if any access main-thread-only APIs (UIApplication, NSApplication, etc.)

## L1 Functions That Likely Don't Need @MainActor

Most L1 functions just:
- Create view structs
- Return composed views
- Use `.environment()` and `.automaticCompliance()` modifiers

These are value type operations and don't require `@MainActor`.

## Audit Steps

1. **Identify all L1 functions** - Count total functions
2. **Categorize by what they do**:
   - Create views only → Remove `@MainActor`
   - Access `@Published` properties → Keep `@MainActor`
   - Access main-thread-only APIs → Keep `@MainActor`
3. **Remove `@MainActor` from functions that only create views**
4. **Test compilation**
5. **Create GitHub issue documenting changes**

## Expected Outcome

Most L1 functions should have `@MainActor` removed, keeping it only on:
- Functions that call `setScreenContext()`
- Functions that access other `@Published` properties
- Functions that access main-thread-only APIs
