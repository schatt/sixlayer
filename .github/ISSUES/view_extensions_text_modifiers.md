# View Extensions for Text Modifiers

**GitHub Issue**: [#174](https://github.com/schatt/sixlayer/issues/174)

## Overview

Create `View` extensions that replicate Text-specific modifiers (`.bold()`, `.italic()`, `.font()`, `.fontWeight()`, etc.) to enable chaining after `.basicAutomaticCompliance()` and other modifiers that return `some View`.

## Motivation

SwiftUI's `Text` type has several modifiers that return `Text`, enabling chaining:
- `.bold()` → returns `Text`
- `.italic()` → returns `Text`
- `.font()` → returns `Text`
- `.fontWeight()` → returns `Text`

However, when applying `.basicAutomaticCompliance()` (which returns `some View`), the ability to chain Text-specific modifiers is lost:
```swift
Text("Hello")
    .basicAutomaticCompliance()  // Returns some View
    .bold()  // ❌ Error: 'bold()' is not available on 'some View'
```

By creating `View` extensions that replicate these Text modifiers, we can enable chaining:
```swift
Text("Hello")
    .basicAutomaticCompliance()  // Returns some View
    .bold()  // ✅ Works via View extension
    .italic()  // ✅ Works via View extension
```

## Requirements

### Core Features
- Replicate Text modifier behavior as View extensions
- Return `some View` (not `Text`) to work with any View
- Maintain same visual/appearance behavior as Text modifiers
- Enable chaining after `.basicAutomaticCompliance()` and other View modifiers

### Text Modifiers to Replicate

Based on SwiftUI's Text API, the following modifiers should be replicated:

1. **`.bold()`** - Apply bold font weight
   ```swift
   extension View {
       func bold() -> some View {
           self.fontWeight(.bold)
       }
   }
   ```

2. **`.italic()`** - Apply italic style
   ```swift
   extension View {
       func italic() -> some View {
           // Use environment or modifier to apply italic
       }
   }
   ```

3. **`.font(_ font: Font)`** - Apply font
   ```swift
   extension View {
       func font(_ font: Font) -> some View {
           self.font(font)
       }
   }
   ```

4. **`.fontWeight(_ weight: Font.Weight?)`** - Apply font weight
   ```swift
   extension View {
       func fontWeight(_ weight: Font.Weight?) -> some View {
           self.fontWeight(weight)
       }
   }
   ```

5. **`.foregroundColor(_ color: Color?)`** - Apply foreground color (if not already available on View)
   ```swift
   extension View {
       func foregroundColor(_ color: Color?) -> some View {
           self.foregroundColor(color)
       }
   }
   ```

6. **`.foregroundStyle(_ style: any ShapeStyle)`** - Apply foreground style (if not already available on View)
   ```swift
   extension View {
       func foregroundStyle(_ style: any ShapeStyle) -> some View {
           self.foregroundStyle(style)
       }
   }
   ```

### Additional Considerations

- Some modifiers (like `.font()`, `.fontWeight()`, `.foregroundColor()`, `.foregroundStyle()`) may already exist on `View` in newer SwiftUI versions
- Need to verify which modifiers are already available vs. need to be added
- Should test that extensions work correctly with all View types, not just Text
- Should ensure extensions don't conflict with existing SwiftUI View modifiers

### Behavior on Non-Text Views

**Important**: These modifiers are **environment modifiers** in SwiftUI:

1. **On container views (VStack, HStack, etc.)**:
   - Modifiers propagate to child views via environment
   - Example: `VStack { Text("A"); Text("B") }.bold()` applies bold to both Text views
   - This is expected SwiftUI behavior

2. **On non-text views (Image, Shape, etc.)**:
   - `.font()`, `.fontWeight()`, `.bold()`, `.italic()` have **no visible effect**
   - They don't error, but don't change appearance
   - Example: `Image(systemName: "star").bold()` compiles but has no visual effect
   - This matches SwiftUI's existing behavior

3. **Design decision**: 
   - Extensions should work on any View (for chaining compatibility)
   - No special error handling needed - SwiftUI already handles this gracefully
   - Document this behavior clearly
   - Add tests to verify no errors occur on non-text views

## Implementation Plan

### Phase 1: Research and Verification
1. ✅ Identify all Text-specific modifiers that return `Text`
2. ✅ Verify which of these are already available on `View` in current SwiftUI version
3. ✅ Document which modifiers need to be added vs. which are already available
4. ✅ Test current SwiftUI behavior to understand any differences

### Phase 2: Implementation
1. Create View extensions for modifiers that don't already exist on View
2. For modifiers that already exist, verify they work correctly after `.basicAutomaticCompliance()`
3. Ensure extensions maintain same behavior as Text modifiers
4. Add comprehensive tests

### Phase 3: Testing
1. Test chaining: `Text("Hello").basicAutomaticCompliance().bold().italic()`
2. Test with other View types: `Image(...).basicAutomaticCompliance().bold()`
3. Test visual appearance matches Text modifier behavior
4. Test that extensions don't break existing code

## Acceptance Criteria

### AC1: Basic Modifier Extensions
- ✅ **AC1.1**: `.bold()` View extension exists and works on any View
- ✅ **AC1.2**: `.italic()` View extension exists and works on any View
- ✅ **AC1.3**: `.font(_:)` View extension exists and works on any View (if needed)
- ✅ **AC1.4**: `.fontWeight(_:)` View extension exists and works on any View (if needed)
- ✅ **AC1.5**: Extensions return `some View` (not `Text`)

### AC2: Chaining Support
- ✅ **AC2.1**: `Text.basicAutomaticCompliance().bold()` compiles and works
- ✅ **AC2.2**: `Text.basicAutomaticCompliance().italic()` compiles and works
- ✅ **AC2.3**: `Text.basicAutomaticCompliance().bold().italic()` compiles and works
- ✅ **AC2.4**: `Text.basicAutomaticCompliance().font(.title)` compiles and works
- ✅ **AC2.5**: `Text.basicAutomaticCompliance().fontWeight(.bold)` compiles and works

### AC3: Visual Consistency
- ✅ **AC3.1**: View extension `.bold()` produces same visual result as Text `.bold()`
- ✅ **AC3.2**: View extension `.italic()` produces same visual result as Text `.italic()`
- ✅ **AC3.3**: View extension `.font(_:)` produces same visual result as Text `.font(_:)`
- ✅ **AC3.4**: View extension `.fontWeight(_:)` produces same visual result as Text `.fontWeight(_:)`

### AC4: Universal Compatibility
- ⏳ **AC4.1**: Extensions work on Text views
- ⏳ **AC4.2**: Extensions work on Image views (no error, no visible effect - expected)
- ⏳ **AC4.3**: Extensions work on container views (VStack, HStack) and propagate to children
- ⏳ **AC4.4**: Extensions work on other View types (no error, may have no visible effect)
- ⏳ **AC4.5**: Extensions don't conflict with existing SwiftUI modifiers
- ⏳ **AC4.6**: Extensions don't cause compilation errors on non-text views

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

### Test Coverage Requirements

**IMPORTANT**: For each test phase, follow this process:
1. **Write test** (with expected behavior)
2. **Stub implementation** (if needed for compilation)
3. **Verify test compiles** (Red phase complete)
4. **Verify test fails** (assertion fails, not compilation error)
5. **Implement feature** (Green phase)
6. **Verify test passes** (Green phase complete)

## Test Plan

### Unit Tests (Logic)
- Test that View extensions compile and return correct types
- Test that extensions can be chained
- Test that extensions don't conflict with existing modifiers

### ViewInspector Tests
- Test that `.bold()` View extension applies correct modifier
- Test that `.italic()` View extension applies correct modifier
- Test that `.font(_:)` View extension applies correct modifier
- Test that `.fontWeight(_:)` View extension applies correct modifier
- Test chaining: `Text.basicAutomaticCompliance().bold().italic()`

### UI Tests (Visual)
- Test visual appearance matches Text modifier behavior
- Test that extensions work correctly with different View types
- Test that chaining produces expected visual results
- Test that extensions on VStack propagate to child Text views
- Test that extensions on Image/Shape don't cause errors (even if no visible effect)
- Test that extensions on VStack propagate to child Text views
- Test that extensions on Image/Shape don't cause errors (even if no visible effect)

### Test File Structure

**Create unit test file:**
- `Development/Tests/SixLayerFrameworkUnitTests/Features/ViewExtensions/TextModifierExtensionsTests.swift`

**Unit test class structure:**
```swift
@Suite("View Extensions for Text Modifiers")
open class TextModifierExtensionsTests: BaseTestClass {
    // Tests for each View extension modifier
}
```

**Create ViewInspector test file:**
- `Development/Tests/SixLayerFrameworkViewInspectorTests_iOS/Features/ViewExtensions/TextModifierExtensionsViewInspectorTests.swift`

**ViewInspector test class structure:**
```swift
@Suite("View Extensions for Text Modifiers (ViewInspector)")
open class TextModifierExtensionsViewInspectorTests: BaseTestClass {
    // ViewInspector tests for modifier application
}
```

**Create UI test file:**
- `Development/Tests/SixLayerFrameworkUITests/TextModifierExtensionsUITests.swift`

**UI test class structure:**
```swift
@MainActor
final class TextModifierExtensionsUITests: XCTestCase {
    var app: XCUIApplication!
    
    // Visual appearance tests
}
```

### Test Naming Convention

Follow pattern: `test<Modifier>_<Condition>_<ExpectedResult>()`

Examples:
- `testBoldExtension_AppliesFontWeight_WhenCalledOnView()`
- `testItalicExtension_AppliesItalicStyle_WhenCalledOnView()`
- `testChaining_BoldAndItalic_WorksAfterBasicCompliance()`
- `testFontExtension_AppliesFont_WhenCalledOnView()`

## Related Issues

- **Issue #172**: Lightweight Compliance for Basic SwiftUI Types
  - This issue enables the chaining use case that View extensions solve
  - View extensions are required to make `.basicAutomaticCompliance()` chainable with Text modifiers
  - Issue #172 references this issue (#174) for View extensions implementation

## Implementation Notes

### SwiftUI Modifier Availability

Need to verify which modifiers are already available on `View`:
- `.font(_:)` - Likely already available on View
- `.fontWeight(_:)` - Likely already available on View
- `.foregroundColor(_:)` - Likely already available on View
- `.foregroundStyle(_:)` - Likely already available on View (iOS 15+)
- `.bold()` - May need to be added (wraps `.fontWeight(.bold)`)
- `.italic()` - May need to be added (uses environment or modifier)

### Implementation Approach

For modifiers that don't exist on View:
1. Create View extension that applies equivalent modifier
2. Ensure behavior matches Text modifier exactly
3. Return `some View` to maintain type compatibility

For modifiers that already exist on View:
1. Verify they work correctly after `.basicAutomaticCompliance()`
2. Document that they're already available
3. Add tests to ensure compatibility

## Status

- [ ] Phase 1: Research and Verification
- [ ] Phase 2: Implementation
- [ ] Phase 3: Testing
- [ ] Ready for Review
