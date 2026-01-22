# Lightweight Compliance for Basic SwiftUI Types

## Overview

Create a lightweight compliance method for basic SwiftUI types (Text, Image, etc.) that applies only accessibility identifier/label without view-level HIG features (touch targets, margins, focus indicators, etc.).

## Motivation

Currently, `.automaticCompliance()` applies full HIG compliance including view-level features that basic types don't need:
- Touch target sizing (not needed for Text, Image)
- Focus indicators (not needed for non-interactive types)
- Margins/padding (not needed for basic display types)
- Color contrast modifiers (may not be needed for basic types)

Additionally, `.automaticCompliance()` returns `some View`, which breaks type preservation for types like `Text` that have type-specific modifiers (`.bold()`, `.italic()`, `.font()`, etc.).

## Requirements

### Core Features
- Apply accessibility identifier (for testing)
- Apply accessibility label (for VoiceOver)
- Skip view-level HIG features (touch targets, margins, focus indicators, etc.)
- Use same identifier generation logic as `.automaticCompliance()`
- Use same label localization logic as `.automaticCompliance()`

## Implementation Approach

### Phase 1: Create Basic Compliance Modifier

1. Create `BasicAutomaticComplianceModifier` that:
   - Reuses identifier generation logic from `AutomaticComplianceModifier`
   - Reuses label localization logic
   - **Skips** `applyHIGComplianceFeatures()` call
   - Only applies identifier and label

2. Create View extension method:
   ```swift
   func basicAutomaticCompliance(
       identifierName: String? = nil,
       identifierElementType: String? = nil,
       identifierLabel: String? = nil,
       accessibilityLabel: String? = nil
   ) -> some View
   ```

3. Create View extensions for Text-specific modifiers (see Issue #174):
   - View extensions for `.bold()`, `.italic()`, `.font()`, `.fontWeight()`, etc.
   - This allows chaining Text modifiers after `.basicAutomaticCompliance()` which returns `some View`.
   - No separate Text extension needed - Text uses View extension.
   - **See Issue #174 for View extensions implementation details.**

### Phase 2: Refactor Full Compliance to Use Basic (DRY)

**Key Question**: Should `.automaticCompliance()` be refactored to use `.basicAutomaticCompliance()` internally?

**Answer: Yes** - Following DRY principles:

1. **Refactor `AutomaticComplianceModifier`** to:
   - Apply `BasicAutomaticComplianceModifier` first (gets identifier + label)
   - Then apply HIG compliance features on top
   - This eliminates code duplication

2. **Implementation pattern**:
   ```swift
   // In AutomaticComplianceModifier.body():
   return applyHIGComplianceFeatures(
       to: content.modifier(BasicAutomaticComplianceModifier(...)),
       elementType: identifierElementType
   )
   ```

3. **Benefits**:
   - Single source of truth for identifier/label logic
   - Easier maintenance (fixes in one place)
   - Clear separation: basic compliance vs. full compliance
   - Consistent behavior between basic and full compliance

4. **Considerations**:
   - Need to ensure modifier chaining works correctly
   - May need to extract shared identifier generation into helper functions
   - Both modifiers should use same config access pattern

## Affected Types

Basic SwiftUI types that would benefit:
- `Text` - ✅ **ONLY type with type-preserving modifiers** (`.bold()`, `.italic()`, `.font()`, `.fontWeight()` return `Text`)
- `Image` - ❌ Does NOT have type-preserving modifiers (all return `some View`)
- `Label` - ❌ Does NOT have type-preserving modifiers (all return `some View`)
- `Link` - ❌ Does NOT have type-preserving modifiers (all return `some View`)
- `Shape` types (Circle, Rectangle, etc.) - ❌ Do NOT have type-preserving modifiers (return wrapper types like `_StrokedShape`)
- Other basic display types - ❌ Do NOT have type-preserving modifiers

**Conclusion**: `Text` is the **only** basic SwiftUI type with type-preserving modifiers. All other types' modifiers return `some View` or wrapper types.

## Type-Specific Modifier Analysis

### Text Modifiers (Type-Preserving)
Text has several modifiers that return `Text`, enabling chaining:
- `.bold()` → returns `Text`
- `.italic()` → returns `Text`
- `.font()` → returns `Text`
- `.fontWeight()` → returns `Text`
- `.foregroundColor()` → returns `Text` (older SwiftUI) or `some View` (newer)

**Example:**
```swift
Text("Hello")
    .bold()
    .italic()
    .font(.title)
    // All return Text, so chaining works
```

### Image Modifiers (NOT Type-Preserving)
Image modifiers all return `some View`, not `Image`:
- `.resizable()` → returns `some View`
- `.renderingMode()` → returns `some View`
- `.interpolation()` → returns `some View`
- `.antialiased()` → returns `some View`
- `.symbolRenderingMode()` → returns `some View`
- `.symbolVariant()` → returns `some View`
- `.font()` → returns `some View` (for SF Symbols)
- `.foregroundColor()` → returns `some View`

**Example:**
```swift
Image(systemName: "star")
    .resizable()
    .renderingMode(.template)
    // Already returns some View, so type preservation doesn't help
```

### Label Modifiers (NOT Type-Preserving)
Label modifiers all return `some View`, not `Label`:
- `.font()` → returns `some View`
- `.foregroundColor()` / `.foregroundStyle()` → returns `some View`
- `.labelStyle()` → returns `some View`

**Example:**
```swift
Label("Swift", systemImage: "swift")
    .font(.title)
    .foregroundStyle(.blue)
    // Returns some View
```

### Link Modifiers (NOT Type-Preserving)
Link modifiers all return `some View`, not `Link`:
- `.font()` → returns `some View`
- `.foregroundColor()` / `.foregroundStyle()` → returns `some View`

**Example:**
```swift
Link("Visit Apple", destination: URL(string: "https://apple.com")!)
    .font(.headline)
    // Returns some View
```

### Shape Modifiers (NOT Type-Preserving)
Shape modifiers return wrapper types, not the original shape:
- `.stroke()` → returns `_StrokedShape<OriginalShape>`
- `.trim()` → returns `_TrimmedShape<OriginalShape>`
- `.fill()` → returns `some View`

**Example:**
```swift
Circle()
    .stroke()
    .trim(from: 0, to: 0.5)
    // Returns wrapper types, not Circle
```

## Related Issues

- **Issue #174**: View Extensions for Text Modifiers
  - View extensions for `.bold()`, `.italic()`, `.font()`, `.fontWeight()`, etc.
  - Enables chaining Text modifiers after `.basicAutomaticCompliance()`
  - Required to complete the Text modifier chaining use case

## Related

- Current `platformText()` implementation - returns `Text` but doesn't apply compliance
- `.automaticCompliance()` - full compliance including view-level HIG features
- Issue #157 - Accessibility label auto-extraction

## Acceptance Criteria

### Phase 1: Basic Compliance Implementation

#### 1. General Basic Compliance (`.basicAutomaticCompliance()`)
- ✅ **AC1.1**: `.basicAutomaticCompliance()` applies accessibility identifier using same logic as `.automaticCompliance()`
- ✅ **AC1.2**: `.basicAutomaticCompliance()` applies accessibility label using same localization/formatting logic as `.automaticCompliance()`
- ✅ **AC1.3**: `.basicAutomaticCompliance()` does NOT apply HIG compliance features (touch targets, margins, focus indicators, etc.)
- ✅ **AC1.4**: `.basicAutomaticCompliance()` returns `some View` (for general use)
- ✅ **AC1.5**: `.basicAutomaticCompliance()` respects global config settings (enableAutoIDs, globalAutomaticAccessibilityIdentifiers)
- ✅ **AC1.6**: `.basicAutomaticCompliance()` supports all parameters: `identifierName`, `identifierElementType`, `identifierLabel`, `accessibilityLabel`

#### 2. Text Modifier Chaining Support
- ✅ **AC2.1**: `Text.basicAutomaticCompliance()` applies accessibility identifier (uses View extension)
- ✅ **AC2.2**: `Text.basicAutomaticCompliance()` applies accessibility label (uses View extension)
- ✅ **AC2.3**: `Text.basicAutomaticCompliance()` returns `some View` (enables chaining via View extensions)
- ⏳ **AC2.4**: View extensions for Text modifiers enable chaining (see Issue #174)
- ⏳ **AC2.5**: `Text.basicAutomaticCompliance().bold().italic()` works via View extensions (see Issue #174)

#### 3. Integration with platformText
- ✅ **AC3.1**: `platformText()` can optionally use `Text.basicAutomaticCompliance()` internally
- ✅ **AC3.2**: `platformText().basicAutomaticCompliance()` works correctly
- ✅ **AC3.3**: `platformText().basicAutomaticCompliance().bold()` works correctly (type preservation)

### Phase 2: DRY Refactoring

#### 4. AutomaticComplianceModifier Refactoring
- ✅ **AC4.1**: `AutomaticComplianceModifier` uses `BasicAutomaticComplianceModifier` internally
- ✅ **AC4.2**: `AutomaticComplianceModifier` applies HIG features on top of basic compliance
- ✅ **AC4.3**: `.automaticCompliance()` behavior remains unchanged (backward compatible)
- ✅ **AC4.4**: Identifier generation logic is shared between basic and full compliance
- ✅ **AC4.5**: Label localization logic is shared between basic and full compliance

#### 5. Code Quality
- ✅ **AC5.1**: No code duplication between `BasicAutomaticComplianceModifier` and `AutomaticComplianceModifier`
- ✅ **AC5.2**: Shared identifier generation logic extracted into helper functions
- ✅ **AC5.3**: Shared label localization logic extracted into helper functions
- ✅ **AC5.4**: Both modifiers use same config access pattern

## TDD Requirements

### Test-Driven Development Process

**MANDATORY**: Follow Red-Green-Refactor cycle for all implementation:

1. **RED**: Write tests that **COMPILE** (and fail)
   - Tests must compile successfully
   - Tests must fail (assertions fail, not compilation errors)
   - May require stubbing methods/interfaces so tests can compile
   - **Red phase ends when tests compile and fail**
   
2. **GREEN**: Implement minimum code to pass tests
   - **Green phase begins when tests compile (and fail)**
   - Implement just enough code to make tests pass
   - No premature optimization or refactoring
   
3. **REFACTOR**: Improve code while keeping tests green
   - All tests must remain passing
   - Improve code quality, eliminate duplication
   - Extract shared logic, improve naming, etc.

**Critical Rule**: Red phase is NOT complete until tests compile. If tests don't compile, create stub implementations (empty methods, return default values, etc.) so tests can compile and fail on assertions, not compilation errors.

**Note on Breaking API Changes**: Some flexibility exists when arguments to existing methods are changing (breaking API changes), but those are relatively rare. 

**Strategy for Breaking API Changes**: When replacing an existing function `Foo` with a breaking change:
- **Red Phase**: Create temporary function `newFoo` with new signature, tests use `newFoo` (compile but fail)
- **Green Phase**: Make `newFoo` work (tests pass)
- **Rename Phase**: Rename `newFoo` to `Foo` (replacing old `Foo`)
- **Green2 Phase**: Fix all broken code that used old `Foo`'s method calls (compiler shows all broken call sites)

This allows tests to compile during Red phase without breaking existing code. The "broken state" after rename is actually helpful - the compiler points out ALL call sites that need fixing, ensuring nothing is missed.

Example:
```swift
// Red phase: Create newFoo with new signature (stub)
func newFoo(newParam: String) -> some View {
    self  // Stub - allows test to compile
}

// Tests use newFoo
#expect(newFoo(newParam: "test") != nil)  // Compiles, fails assertion (Red phase)

// Green phase: Make newFoo work
func newFoo(newParam: String) -> some View {
    // Actual implementation
    Text(newParam).automaticCompliance()
}

// Rename phase: Rename newFoo to Foo (replacing old Foo)
func Foo(newParam: String) -> some View {
    // Same implementation (was newFoo)
    Text(newParam).automaticCompliance()
}
// Old Foo removed - compiler now shows ALL broken call sites

// Green2 phase: Fix all call sites (compiler errors guide you)
// Old: Foo(oldParam: 42)  // Compiler error - must fix
// New: Foo(newParam: "42")  // Fixed
```

**Why this is better**: The compiler forces you to find and fix ALL broken call sites. You can't miss any - they're all compilation errors. This is more reliable than manually finding call sites during migration.

This should be the exception, not the rule - most changes should follow strict Red-Green-Refactor with stubs.

### Test Coverage Requirements

**IMPORTANT**: For each test phase, follow this process:
1. **Write test** (with expected behavior)
2. **Stub implementation** (if needed for compilation)
3. **Verify test compiles** (Red phase complete)
4. **Verify test fails** (assertion fails, not compilation error)
5. **Implement feature** (Green phase)
6. **Verify test passes** (Green phase complete)

#### Phase 1 Tests

**1. BasicAutomaticComplianceModifier Unit Tests**
- ✅ **T1.1**: Test that `.basicAutomaticCompliance()` applies accessibility identifier (ViewInspector)
- ✅ **T1.2**: Test that `.basicAutomaticCompliance()` applies accessibility label (ViewInspector)
- ✅ **T1.3**: Test that `.basicAutomaticCompliance()` does NOT apply HIG features (ViewInspector)
- ✅ **T1.4**: Test identifier generation matches `.automaticCompliance()` logic
- ✅ **T1.5**: Test label localization matches `.automaticCompliance()` logic
- ✅ **T1.6**: Test config respect (enableAutoIDs, globalAutomaticAccessibilityIdentifiers)
- ✅ **T1.7**: Test all parameter combinations (identifierName, identifierElementType, identifierLabel, accessibilityLabel)
- ✅ **T1.8**: Test on iOS platform (using ViewInspector if available)
- ✅ **T1.9**: Test on macOS platform (using ViewInspector if available)

**1b. BasicAutomaticComplianceModifier UI-Only Tests**
- ✅ **T1.10**: Test that `.basicAutomaticCompliance()` identifier is findable via XCUITest
- ✅ **T1.11**: Test that `.basicAutomaticCompliance()` label is readable via XCUITest
- ✅ **T1.12**: Test that Text with `.basicAutomaticCompliance()` identifier is findable
- ✅ **T1.13**: Test that Image with `.basicAutomaticCompliance()` identifier is findable

**2. Text Modifier Chaining Tests**
- ✅ **T2.1**: Test that `Text.basicAutomaticCompliance()` applies identifier (ViewInspector)
- ✅ **T2.2**: Test that `Text.basicAutomaticCompliance()` applies label (ViewInspector)
- ⏳ **T2.3**: Test that View extension `.bold()` works after `.basicAutomaticCompliance()` (see Issue #174)
- ⏳ **T2.4**: Test that View extension `.italic()` works after `.basicAutomaticCompliance()` (see Issue #174)
- ⏳ **T2.5**: Test that View extension `.font(.title)` works after `.basicAutomaticCompliance()` (see Issue #174)
- ⏳ **T2.6**: Test chaining: `Text("Hello").basicAutomaticCompliance().bold().italic().font(.title)` (see Issue #174)
- ⏳ **T2.7**: Test that View extensions for Text modifiers work on any View, not just Text (see Issue #174)

**2b. Text.basicAutomaticCompliance() UI-Only Tests**
- ✅ **T2.8**: Test that `Text.basicAutomaticCompliance()` identifier is findable via XCUITest
- ✅ **T2.9**: Test that `Text.basicAutomaticCompliance()` label is readable via XCUITest
- ✅ **T2.10**: Test that chained Text modifiers still have identifier findable

**3. Integration Unit Tests**
- ✅ **T3.1**: Test `platformText("Hello").basicAutomaticCompliance()` works (ViewInspector)
- ✅ **T3.2**: Test `platformText("Hello").basicAutomaticCompliance().bold()` works (compile-time + ViewInspector)
- ✅ **T3.3**: Test `Image(systemName: "star").basicAutomaticCompliance()` works (ViewInspector)
- ✅ **T3.4**: Test `Label("Text", systemImage: "icon").basicAutomaticCompliance()` works (ViewInspector)

**3b. Integration UI-Only Tests**
- ✅ **T3.5**: Test `platformText("Hello").basicAutomaticCompliance()` identifier is findable via XCUITest
- ✅ **T3.6**: Test `Image(systemName: "star").basicAutomaticCompliance()` identifier is findable via XCUITest
- ✅ **T3.7**: Test `Label("Text", systemImage: "icon").basicAutomaticCompliance()` identifier is findable via XCUITest

#### Phase 2 Tests

**4. Refactoring Verification Unit Tests**
- ✅ **T4.1**: Test that `.automaticCompliance()` still applies identifier (regression test - ViewInspector)
- ✅ **T4.2**: Test that `.automaticCompliance()` still applies label (regression test - ViewInspector)
- ✅ **T4.3**: Test that `.automaticCompliance()` still applies HIG features (regression test - ViewInspector)
- ✅ **T4.4**: Test that identifier generation is identical between basic and full compliance
- ✅ **T4.5**: Test that label localization is identical between basic and full compliance
- ✅ **T4.6**: Test that `AutomaticComplianceModifier` uses `BasicAutomaticComplianceModifier` internally

**4b. Refactoring Verification UI-Only Tests**
- ✅ **T4.7**: Test that `.automaticCompliance()` identifier is still findable via XCUITest (regression)
- ✅ **T4.8**: Test that `.automaticCompliance()` label is still readable via XCUITest (regression)
- ✅ **T4.9**: Test that basic and full compliance produce same identifier (XCUITest verification)

### Test File Structure

**Create unit test file:**
- `Development/Tests/SixLayerFrameworkUnitTests/ViewInspectorTests/Features/Accessibility/BasicAutomaticComplianceTests.swift`

**Unit test class structure:**
```swift
@Suite("Basic Automatic Compliance")
open class BasicAutomaticComplianceTests: BaseTestClass {
    // Phase 1: Basic Compliance Tests
    // Phase 2: Refactoring Verification Tests
}
```

**Create UI-only test file:**
- `Development/Tests/SixLayerFrameworkUITests/BasicAutomaticComplianceUITests.swift`

**UI-only test class structure:**
```swift
@MainActor
final class BasicAutomaticComplianceUITests: XCTestCase {
    var app: XCUIApplication!
    
    // Phase 1: Basic Compliance UI Tests
    // Phase 2: Refactoring Verification UI Tests
}
```

**Test Types:**
- **Unit Tests**: Use ViewInspector (when available) to verify modifiers are applied at compile-time
- **UI-Only Tests**: Use XCUITest to verify identifiers/labels are findable in running app (runtime verification)

### Test Patterns

**Follow existing patterns from:**
- `AutomaticAccessibilityIdentifiersTests.swift` - identifier generation testing
- `AutomaticAccessibilityLabelTests.swift` - label localization testing
- `AutomaticHIGComplianceTests.swift` - HIG feature testing

**Unit Tests (ViewInspector):**
- Verifying accessibility identifiers are applied (compile-time verification)
- Verifying accessibility labels are applied (compile-time verification)
- Platform-specific testing (iOS/macOS)
- Type preservation verification (compile-time checks)

**UI-Only Tests (XCUITest):**
- Verifying identifiers are findable in running app (runtime verification)
- Verifying labels are readable by VoiceOver/accessibility (runtime verification)
- End-to-end accessibility testing (real app behavior)
- Cross-platform UI testing (iOS/macOS)

**Test isolation:**
- Use `initializeTestConfig()` in each test
- Use `runWithTaskLocalConfig()` for isolated config per test
- No shared state between tests

**Red Phase Stubbing Requirements:**
- If test calls `.basicAutomaticCompliance()`, create stub extension that returns `some View`
- If test calls `Text.basicAutomaticCompliance()`, create stub extension that returns `Text`
- Stub implementations should:
  - Compile successfully
  - Return appropriate types (even if empty/placeholder)
  - Allow tests to compile and fail on assertions
- Example stub:
  ```swift
  // Red phase stub - allows test to compile
  extension View {
      func basicAutomaticCompliance(...) -> some View {
          self  // Stub: just returns self, no actual implementation
      }
  }
  
  // Test compiles, but assertion fails (Red phase complete)
  #expect(viewHasIdentifier, "Should have identifier")  // Fails - Red phase
  ```

### Test Naming Convention

Follow pattern: `test<Feature>_<Condition>_<ExpectedResult>()`

Examples:
- `testBasicAutomaticCompliance_AppliesIdentifier_WhenEnabled()`
- `testBasicAutomaticCompliance_DoesNotApplyHIGFeatures_ForBasicTypes()`
- `testTextBasicAutomaticCompliance_ReturnsTextType_AllowingChaining()`
- `testAutomaticCompliance_UsesBasicCompliance_Internally()`

## Notes

- This addresses the limitation where `.automaticCompliance()` returns `some View`, breaking Text chaining
- Basic types don't need view-level HIG features (touch targets, margins, etc.)
- Identifier and label are the core compliance features needed for basic types
- **MANDATORY**: All tests must pass before implementation is complete
- **MANDATORY**: Follow TDD Red-Green-Refactor cycle
- **MANDATORY**: No code duplication (DRY principle)
