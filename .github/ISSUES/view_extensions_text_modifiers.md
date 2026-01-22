# View Extensions for Text Modifiers

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
- ✅ **AC4.1**: Extensions work on Text views
- ✅ **AC4.2**: Extensions work on Image views
- ✅ **AC4.3**: Extensions work on other View types
- ✅ **AC4.4**: Extensions don't conflict with existing SwiftUI modifiers

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

## Related Issues

- **Issue #172**: Lightweight Compliance for Basic SwiftUI Types
  - This issue enables the chaining use case that View extensions solve
  - View extensions are required to make `.basicAutomaticCompliance()` chainable with Text modifiers

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
