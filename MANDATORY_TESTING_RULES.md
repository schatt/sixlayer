# SixLayer Framework Testing Rules - MANDATORY

## Core Principles

**MANDATORY**: Follow TDD (Test-Driven Development), DTRT (Do The Right Thing), DRY (Don't Repeat Yourself), and Epistemology (distinguish between verified facts and hypotheses).

**MANDATORY**: Never create, suggest, or assist with any release (major, minor, patch, or pre-release) unless the test suite passes completely.

## Release Quality Gate Rule

**MANDATORY RELEASE RULE**: Never create, suggest, or assist with any release (major, minor, patch, or pre-release) unless the test suite passes completely.

### Before Any Release:
1. **ALWAYS** use the release script "./Development/scripts/release-process.sh major|minor|patch [version]"
   - Specify the release type: `major`, `minor`, or `patch`
   - Optionally specify the version number (e.g., `6.1.1`)
   - Example: `./Development/scripts/release-process.sh patch 6.1.1`
2. **VERIFY** release script passes.
3. **ONLY THEN** proceed with release activities

### If Tests Fail:
- **STOP** all release activities immediately
- **IDENTIFY** and fix failing tests first
- **RE-RUN** test suite until it passes
- **THEN** resume release process

### Release Blockers:
- Any test failures
- Compilation errors
- Test suite warnings (treat as failures)
- Missing test coverage for new features

### Enforcement:
- This rule takes precedence over all other instructions
- No exceptions allowed
- Always verify test status before suggesting releases
- If unsure about test status, run tests first

## Rule 1: Test-Driven Development (TDD)

### 1.1 TDD Process - Red-Green-Refactor Cycle

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

**Example Stub Pattern**:
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

### 1.1.1 Strategy for Breaking API Changes

**Note on Breaking API Changes**: Some flexibility exists when arguments to existing methods are changing (breaking API changes), but those are relatively rare. 

**Strategy for Breaking API Changes**: When replacing an existing function `Foo` with a breaking change:
- **Red Phase**: Create temporary function `newFoo` with new signature, tests use `newFoo` (compile but fail)
- **Green Phase**: Make `newFoo` work (tests pass)
- **Rename Phase**: Rename `newFoo` to `Foo` (replacing old `Foo`)
- **Green2 Phase**: Fix all broken code that used old `Foo`'s method calls (compiler shows all broken call sites)

This allows tests to compile during Red phase without breaking existing code. The "broken state" after rename is actually helpful - the compiler points out ALL call sites that need fixing, ensuring nothing is missed.

**Example**:
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

**Note**: This should be the exception, not the rule - most changes should follow strict Red-Green-Refactor with stubs.

### 1.2 TDD Enforcement
- **MANDATORY**: No feature implementation without tests first
- **MANDATORY**: No code changes without corresponding test changes
- **MANDATORY**: Tests must be written for every function before implementation
- **MANDATORY**: All tests must pass before any release
- **MANDATORY**: Tests must compile before implementation begins (Red phase requirement)

## Rule 1.5: Epistemological Rigor in Testing

### 1.5.1 Distinguish Facts from Hypotheses
- **MANDATORY**: Distinguish between verified facts and unverified hypotheses in all testing discussions
- **MANDATORY**: Use precise language that reflects the current state of knowledge
- **MANDATORY**: Investigate before asserting - prefer tentative language until verification

### 1.5.2 Language Guidelines for Testing

#### ✅ Use for Verified Facts
- "The test suite passed with 0 failures"
- "The function returns the expected result"
- "The modifier is applied correctly"
- "The test coverage is 100%"

#### ❌ Avoid for Unverified Claims
- "This test will definitely catch all bugs" (without evidence)
- "The implementation is correct" (without verification)
- "This will solve the problem" (without testing)

#### ✅ Use for Hypotheses and Theories
- "I think this test might catch the bug"
- "This approach could improve test coverage"
- "It's possible that this test is insufficient"
- "My theory is that this test needs more scenarios"

### 1.5.3 Investigation Workflow
1. **Observe** - State what you can see/measure in test results
2. **Hypothesize** - Use tentative language for possible causes of test failures
3. **Investigate** - Gather evidence through additional testing/analysis
4. **Verify** - Confirm or refute the hypothesis
5. **Assert** - Only then state as fact

### 1.5.4 Test Quality Assessment
- **MANDATORY**: Express confidence levels when appropriate: "I'm 80% confident this test covers the edge case"
- **MANDATORY**: Acknowledge limitations of current test knowledge: "I can only test X, so Y is still unknown"
- **MANDATORY**: Distinguish between partial and complete test coverage: "I know the happy path is tested but not the error cases"

## Rule 2: Complete Function Testing

### 2.1 Every Function Must Be Tested
- **MANDATORY**: Every public function in the framework must have comprehensive tests
- **MANDATORY**: Every function must be tested for its complete functionality
- **MANDATORY**: Every function must be tested for all modifiers it applies
- **MANDATORY**: No function can be released without complete test coverage

### 2.2 Function Behavior Testing
- **MANDATORY**: Tests must validate actual behavior, not just function existence
- **MANDATORY**: Tests must fail when functionality is broken
- **MANDATORY**: Tests must pass when functionality works correctly
- **MANDATORY**: Tests must only test behavior that actually exists (no testing of stubs or non-functional flags)
```swift
// ✅ CORRECT: Test that function does what it's supposed to do
func testPlatformPresentItemCollection_L1_DoesWhatItsSupposedToDo() {
    // Given
    let items = [TestItem(id: "1", title: "Test")]
    let hints = PresentationHints(...)
    
    // When
    let view = platformPresentItemCollection_L1(items: items, hints: hints)
    
    // Then
    XCTAssertNotNil(view, "Should create a view")
    XCTAssertTrue(view.displaysItems, "Should display the items")
    XCTAssertEqual(view.itemCount, 1, "Should display correct number of items")
}
```

### 1.3 Modifier Application Testing
- **MANDATORY**: Every function must be tested for ALL modifiers it applies
- **MANDATORY**: Tests must validate that modifiers are actually applied
- **MANDATORY**: Tests must validate modifier behavior, not just existence
```swift
// ✅ CORRECT: Test that function applies all correct modifiers
func testPlatformPresentItemCollection_L1_AppliesAllCorrectModifiers() {
    // Given
    let items = [TestItem(id: "1", title: "Test")]
    let hints = PresentationHints(...)
    
    // When
    let view = platformPresentItemCollection_L1(items: items, hints: hints)
    
    // Then
    XCTAssertTrue(view.hasAutomaticAccessibilityIdentifiers, "Should apply automatic accessibility identifiers")
    XCTAssertTrue(view.isHIGCompliant, "Should apply HIG compliance")
    XCTAssertTrue(view.hasPerformanceOptimizations, "Should apply performance optimizations")
    XCTAssertTrue(view.isCrossPlatformCompatible, "Should apply cross-platform compatibility")
}
```

## Rule 2: Platform-Dependent Testing

### 2.1 Platform Mocking Requirements
- **MANDATORY**: If any modifiers are platform-dependent, tests MUST mock those platforms
- **MANDATORY**: Tests MUST ensure correct behavior on all supported platforms
- **MANDATORY**: Platform-specific behavior MUST be validated
- **MANDATORY**: Platform mocking is required for ANY FUNCTION that contains platform-dependent behavior (not per layer, but per individual function)
- **MANDATORY**: No platform-dependent function can be released without platform mocking tests

### 2.3 Platform Mocking Examples

### 2.3 Platform Mocking Examples

#### L1 Function - Platform Dependent (Requires Mocking)
```swift
// ✅ CORRECT: L1_platformBlah does different things on different platforms
func testPlatformBlah_L1_AppliesCorrectModifiersOnIOS() {
    // Given
    let mockPlatform = MockPlatform(.iOS)
    let input = createTestInput()
    
    // When
    let result = platformBlah_L1(input: input)
    
    // Then
    XCTAssertTrue(result.hasIOSSpecificBehavior, "Should apply iOS-specific behavior")
    XCTAssertTrue(result.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    // Platform mocking REQUIRED - this function is platform-dependent
}
```

#### L1 Function - Stub Implementation (No Testing of Non-Functional Flags)
```swift
// ✅ CORRECT: L1_platformStub has a flag that does nothing (stub implementation)
func testPlatformStub_L1_AppliesCorrectModifiers() {
    // Given
    let input = createTestInput()
    
    // When
    let result = platformStub_L1(input: input, enableAdvancedFeature: true)
    
    // Then
    XCTAssertTrue(result.hasBasicFunctionality, "Should have basic functionality")
    XCTAssertTrue(result.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    // DO NOT test enableAdvancedFeature - it's a stub that does nothing
    // Testing non-functional flags would be testing non-existent behavior
}
```

#### L1 Function - Unconditional Behavior (No Testing of Irrelevant Flags)
```swift
// ✅ CORRECT: L1_functionA returns FOO unconditionally
func testFunctionA_L1_AppliesCorrectModifiers() {
    // Given
    let input = createTestInput()
    
    // When
    let result = functionA_L1(input: input, bazFlag: true)
    
    // Then
    XCTAssertEqual(result, "FOO", "Should return FOO unconditionally")
    XCTAssertTrue(result.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    // DO NOT test bazFlag - it doesn't affect the unconditional behavior
    // Testing irrelevant flags would be testing non-existent behavior
}
```

#### L1 Function - Flag Passed Through Layers (Test Where Behavior Actually Changes)
```swift
// ✅ CORRECT: L1 passes flag through to L3, which passes to L6
func testPlatformFeature_L1_PassesFlagThroughLayers() {
    // Given
    let input = createTestInput()
    
    // When
    let result = platformFeature_L1(input: input, enableAdvancedFeature: true)
    
    // Then
    XCTAssertTrue(result.hasBasicFunctionality, "Should have basic functionality")
    XCTAssertTrue(result.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    // DO NOT test enableAdvancedFeature here - L1 just passes it through
    // The flag is tested in L6 where it actually affects behavior
}
```

#### L3 Function - Flag Passed Through (No Testing of Pass-Through Flags)
```swift
// ✅ CORRECT: L3 passes flag through to L6 without changing behavior
func testPlatformStrategy_L3_PassesFlagThrough() {
    // Given
    let input = createTestInput()
    
    // When
    let result = platformStrategy_L3(input: input, enableAdvancedFeature: true)
    
    // Then
    XCTAssertTrue(result.hasStrategyBehavior, "Should have strategy behavior")
    XCTAssertTrue(result.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    // DO NOT test enableAdvancedFeature here - L3 just passes it through
    // The flag is tested in L6 where it actually affects behavior
}
```

#### L6 Function - Flag Actually Affects Behavior (Test the Flag)
```swift
// ✅ CORRECT: L6 actually does different things based on the flag
func testPlatformImplementation_L6_AppliesCorrectModifiersWithAdvancedFeature() {
    // Given
    let input = createTestInput()
    
    // When: Test with flag enabled
    let enabledResult = platformImplementation_L6(input: input, enableAdvancedFeature: true)
    
    // Then: Should have advanced behavior
    XCTAssertTrue(enabledResult.hasAdvancedBehavior, "Should have advanced behavior when enabled")
    XCTAssertTrue(enabledResult.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    
    // When: Test with flag disabled
    let disabledResult = platformImplementation_L6(input: input, enableAdvancedFeature: false)
    
    // Then: Should have basic behavior
    XCTAssertFalse(disabledResult.hasAdvancedBehavior, "Should not have advanced behavior when disabled")
    XCTAssertTrue(disabledResult.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    
    // Test enableAdvancedFeature here - L6 actually changes behavior based on this flag
}
```
```swift
// ✅ CORRECT: L1_platformComplex does different things based on BOTH data AND platform
func testPlatformComplex_L1_AppliesCorrectModifiersOnIOSWithDifferentData() {
    // Given: Both platform mocking AND different data types
    let mockPlatform = MockPlatform(.iOS)
    let simpleData = createSimpleTestData()
    let complexData = createComplexTestData()
    
    // When: Test with simple data on iOS
    let simpleResult = platformComplex_L1(data: simpleData)
    
    // Then: Should apply iOS-specific behavior for simple data
    XCTAssertTrue(simpleResult.hasIOSSpecificBehavior, "Should apply iOS-specific behavior")
    XCTAssertTrue(simpleResult.hasSimpleDataBehavior, "Should apply simple data behavior")
    XCTAssertTrue(simpleResult.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    
    // When: Test with complex data on iOS
    let complexResult = platformComplex_L1(data: complexData)
    
    // Then: Should apply iOS-specific behavior for complex data
    XCTAssertTrue(complexResult.hasIOSSpecificBehavior, "Should apply iOS-specific behavior")
    XCTAssertTrue(complexResult.hasComplexDataBehavior, "Should apply complex data behavior")
    XCTAssertTrue(complexResult.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    
    // Platform mocking AND data variation REQUIRED - this function is both platform AND data dependent
}

func testPlatformComplex_L1_AppliesCorrectModifiersOnMacOSWithDifferentData() {
    // Given: Both platform mocking AND different data types
    let mockPlatform = MockPlatform(.macOS)
    let simpleData = createSimpleTestData()
    let complexData = createComplexTestData()
    
    // When: Test with simple data on macOS
    let simpleResult = platformComplex_L1(data: simpleData)
    
    // Then: Should apply macOS-specific behavior for simple data
    XCTAssertTrue(simpleResult.hasMacOSSpecificBehavior, "Should apply macOS-specific behavior")
    XCTAssertTrue(simpleResult.hasSimpleDataBehavior, "Should apply simple data behavior")
    XCTAssertTrue(simpleResult.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    
    // When: Test with complex data on macOS
    let complexResult = platformComplex_L1(data: complexData)
    
    // Then: Should apply macOS-specific behavior for complex data
    XCTAssertTrue(complexResult.hasMacOSSpecificBehavior, "Should apply macOS-specific behavior")
    XCTAssertTrue(complexResult.hasComplexDataBehavior, "Should apply complex data behavior")
    XCTAssertTrue(complexResult.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    
    // Platform mocking AND data variation REQUIRED - this function is both platform AND data dependent
}
```
```swift
// ✅ CORRECT: Test platform-dependent behavior with mocking
func testPlatformIOSNavigationBar_AppliesCorrectModifiersOnIOS() {
    // Given
    let mockPlatform = MockPlatform(.iOS)
    let view = Button("Test") { }
    
    // When
    let result = view.platformIOSNavigationBar(title: "Test")
    
    // Then
    XCTAssertTrue(result.hasIOSNavigationBar, "Should have iOS navigation bar on iOS")
    XCTAssertTrue(result.hasAutomaticAccessibilityIdentifiers, "Should apply accessibility identifiers")
    XCTAssertTrue(result.isHIGCompliant, "Should apply HIG compliance")
}

func testPlatformIOSNavigationBar_NoOpOnNonIOS() {
    // Given
    let mockPlatform = MockPlatform(.macOS)
    let view = Button("Test") { }
    
    // When
    let result = view.platformIOSNavigationBar(title: "Test")
    
    // Then
    XCTAssertFalse(result.hasIOSNavigationBar, "Should not have iOS navigation bar on macOS")
    XCTAssertTrue(result.hasAutomaticAccessibilityIdentifiers, "Should still apply accessibility identifiers")
    XCTAssertTrue(result.isHIGCompliant, "Should still apply HIG compliance")
}
```

### 2.4 Testing Requirements Summary

#### Function Types and Required Testing:

1. **Platform-Dependent Only**: **MANDATORY** - Requires platform mocking
   - `L1_platformBlah()` - Different behavior on iOS vs macOS
   - Test: `testPlatformBlah_L1_AppliesCorrectModifiersOnIOS()`
   - Test: `testPlatformBlah_L1_AppliesCorrectModifiersOnMacOS()`

2. **Data-Dependent Only**: **MANDATORY** - Requires data variation testing
   - `L1_platformFoo()` - Different behavior based on data complexity
   - Test: `testPlatformFoo_L1_AppliesCorrectModifiersWithSimpleData()`
   - Test: `testPlatformFoo_L1_AppliesCorrectModifiersWithComplexData()`

3. **Both Platform AND Data Dependent**: **MANDATORY** - Requires BOTH platform mocking AND data variation
   - `L1_platformComplex()` - Different behavior based on BOTH platform AND data
   - Test: `testPlatformComplex_L1_AppliesCorrectModifiersOnIOSWithSimpleData()`
   - Test: `testPlatformComplex_L1_AppliesCorrectModifiersOnIOSWithComplexData()`
   - Test: `testPlatformComplex_L1_AppliesCorrectModifiersOnMacOSWithSimpleData()`
   - Test: `testPlatformComplex_L1_AppliesCorrectModifiersOnMacOSWithComplexData()`

4. **Neither Platform Nor Data Dependent**: **MANDATORY** - Requires basic functionality testing
   - `L1_platformSimple()` - Same behavior regardless of platform or data
   - Test: `testPlatformSimple_L1_AppliesCorrectModifiers()`

## Rule 3: Layered Testing Architecture

### 3.1 Layer Independence
- **MANDATORY**: Each layer's tests assume lower layers are correct
- **MANDATORY**: L5 tests do NOT test L6 component behavior (L6 tests handle that)
- **MANDATORY**: Each layer tests its complete functionality and modifier application
- **MANDATORY**: No layer can be released without complete test coverage

### 3.2 Layer Testing Responsibilities

#### Layer 1 Tests
```swift
// ✅ CORRECT: L1 tests focus on L1 functionality
func testPlatformPresentItemCollection_L1_CompleteFunctionality() {
    // Test L1 semantic intent
    // Test L1 modifier application (accessibility, HIG compliance, etc.)
    // Platform mocking REQUIRED if THIS SPECIFIC FUNCTION is platform-dependent
    // DO NOT test L2-L6 behavior (those are tested in their respective layers)
}
```

#### Layer 2 Tests
```swift
// ✅ CORRECT: L2 tests focus on L2 functionality
func testDetermineOptimalLayout_L2_CompleteFunctionality() {
    // Test L2 layout decision logic
    // Test L2 modifier application
    // Platform mocking REQUIRED if THIS SPECIFIC FUNCTION is platform-dependent
    // Assume L1 functions work correctly (tested in L1 tests)
    // DO NOT test L3-L6 behavior
}
```

#### Layer 4 Tests
```swift
// ✅ CORRECT: L4 tests focus on L4 functionality
func testPlatformFormContainer_L4_CompleteFunctionality() {
    // Test L4 component implementation
    // Test L4 modifier application
    // Platform mocking REQUIRED if THIS SPECIFIC FUNCTION is platform-dependent
    // Assume L1-L3 functions work correctly
    // DO NOT test L5-L6 behavior
}
```

#### Layer 5 Tests
```swift
// ✅ CORRECT: L5 tests focus on L5 functionality
func testPlatformMemoryOptimization_L5_CompleteFunctionality() {
    // Test L5 performance optimization
    // Test L5 modifier application
    // Platform mocking REQUIRED if THIS SPECIFIC FUNCTION is platform-dependent
    // Assume L1-L4 functions work correctly
    // DO NOT test L6 behavior (L6 tests handle that)
}
```

#### Layer 6 Tests
```swift
// ✅ CORRECT: L6 tests focus on L6 functionality
func testPlatformIOSHapticFeedback_L6_CompleteFunctionality() {
    // Test L6 platform-specific features
    // Test L6 modifier application
    // Platform mocking REQUIRED if THIS SPECIFIC FUNCTION is platform-dependent
    // Assume L1-L5 functions work correctly
}
```

## Rule 4: Modifier Application Testing

### 4.1 Complete Modifier Coverage
- **MANDATORY**: Every function must be tested for ALL modifiers it applies
- **MANDATORY**: Tests must validate that modifiers are actually applied
- **MANDATORY**: Tests must validate modifier behavior, not just existence
- **MANDATORY**: No function can be released without testing all its modifiers

### 4.2 Modifier Testing Pattern
```swift
// ✅ CORRECT: Test all modifiers a function should apply
func testFunction_AppliesAllRequiredModifiers() {
    // Given
    let input = createTestInput()
    
    // When
    let result = functionUnderTest(input)
    
    // Then
    XCTAssertTrue(result.hasModifierA, "Should apply modifier A")
    XCTAssertTrue(result.hasModifierB, "Should apply modifier B")
    XCTAssertTrue(result.hasModifierC, "Should apply modifier C")
    // Test ALL modifiers the function should apply
}
```

## Rule 5: Real-World Scenario Testing

### 5.1 User Scenario Coverage
- **MANDATORY**: Tests must cover real-world usage scenarios
- **MANDATORY**: Tests must validate the framework's own documented patterns
- **MANDATORY**: Tests must catch the exact issues users encounter
- **MANDATORY**: No function can be released without real-world scenario testing

### 5.2 Scenario Testing Pattern
```swift
// ✅ CORRECT: Test real-world usage scenarios
func testCustomViewWithAllSixLayers_CompleteFunctionality() {
    // Given: The exact pattern from framework documentation
    let view = createCustomViewWithAllSixLayers()
    
    // When: Apply the complete pattern
    let result = view
        .platformPresentItemCollection_L1(...)  // L1
        .onAppear {
            let decision = determineOptimalCardLayout_L2(...)  // L2
            let strategy = selectCardLayoutStrategy_L3(...)    // L3
        }
        .platformMemoryOptimization()  // L5
        .platformIOSHapticFeedback()  // L6
    
    // Then: Validate complete functionality
    XCTAssertTrue(result.hasAllLayerFeatures, "Should have all layer features")
    XCTAssertTrue(result.hasAutomaticAccessibilityIdentifiers, "Should have accessibility identifiers")
    XCTAssertTrue(result.isHIGCompliant, "Should be HIG compliant")
    XCTAssertTrue(result.hasPerformanceOptimizations, "Should have performance optimizations")
    XCTAssertTrue(result.hasPlatformSpecificFeatures, "Should have platform-specific features")
}
```

## Rule 6: Test Quality Standards

### 6.1 Test Completeness
- **MANDATORY**: Tests must validate actual behavior, not just function existence
- **MANDATORY**: Tests must fail when functionality is broken
- **MANDATORY**: Tests must pass when functionality works correctly
- **MANDATORY**: No test can be released without validating actual behavior

### 6.2 Test Validation
```swift
// ❌ BAD: Test only checks function exists
func testFunction_Exists() {
    let result = functionUnderTest()
    XCTAssertNotNil(result, "Function should exist")
}

// ✅ GOOD: Test validates actual behavior
func testFunction_DoesWhatItsSupposedToDo() {
    let result = functionUnderTest()
    XCTAssertNotNil(result, "Should create result")
    XCTAssertTrue(result.hasExpectedBehavior, "Should have expected behavior")
    XCTAssertTrue(result.hasRequiredModifiers, "Should have required modifiers")
}
```

## Rule 7: Enforcement

### 7.1 Mandatory Compliance
- **MANDATORY**: All new functions must follow these testing rules
- **MANDATORY**: All existing functions must be updated to follow these rules
- **MANDATORY**: No function can be released without complete test coverage
- **MANDATORY**: No exception to these rules is allowed

### 7.2 Quality Gates
- **MANDATORY**: Tests must pass before any release
- **MANDATORY**: Test coverage must be 100% for all functions
- **MANDATORY**: All modifiers must be tested for all functions
- **MANDATORY**: No release can proceed without meeting all quality gates

## Rule 7: Cosmetic vs Functional Testing

### 7.1 Cosmetic Testing (FORBIDDEN)
**MANDATORY**: The following testing patterns are FORBIDDEN as they don't catch bugs:

#### 7.1.1 View Creation Tests
```swift
// ❌ FORBIDDEN: Only tests that view exists
let enhancedView = testView.accessibilityEnhanced()
XCTAssertNotNil(enhancedView, "Enhanced view should be created")
```

#### 7.1.2 Configuration Tests
```swift
// ❌ FORBIDDEN: Only tests that config exists
XCTAssertNotNil(platformConfig, "Platform configuration should be valid")
```

#### 7.1.3 Default Value Tests
```swift
// ❌ FORBIDDEN: Only tests that default is set
XCTAssertTrue(config.performance.metalRendering, "Metal rendering should be enabled by default")
```

### 7.2 Functional Testing (REQUIRED)
**MANDATORY**: All tests must validate actual behavior and functionality:

#### 7.2.1 View Creation Tests
```swift
// ✅ REQUIRED: Tests actual functionality
let enhancedView = testView.accessibilityEnhanced()
let hostingController = UIHostingController(rootView: enhancedView)
hostingController.view.layoutIfNeeded()

// Test that accessibility features are actually applied
XCTAssertTrue(hostingController.view.isAccessibilityElement, "View should be accessibility element")
XCTAssertNotNil(hostingController.view.accessibilityLabel, "View should have accessibility label")
XCTAssertNotNil(hostingController.view.accessibilityHint, "View should have accessibility hint")
```

#### 7.2.2 Configuration Tests
```swift
// ✅ REQUIRED: Tests that configuration actually affects behavior
let config = CardExpansionPlatformConfig()
config.supportsTouch = true

let view = createTestView(with: config)
let hostingController = UIHostingController(rootView: view)
hostingController.view.layoutIfNeeded()

// Verify touch behavior is actually enabled
XCTAssertTrue(hostingController.view.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } ?? false, 
              "Touch configuration should enable tap gestures")
```

#### 7.2.3 Default Value Tests
```swift
// ✅ REQUIRED: Tests that default values actually work
let config = SixLayerConfiguration()
XCTAssertTrue(config.performance.metalRendering, "Metal rendering should be enabled by default")

// Test that the default actually enables metal rendering
let view = createTestView()
let hostingController = UIHostingController(rootView: view)
hostingController.view.layoutIfNeeded()

// Verify metal rendering is actually active
#if os(macOS)
XCTAssertTrue(hostingController.view.layer?.isKind(of: CAMetalLayer.self) ?? false, 
              "Metal rendering default should enable Metal layer")
#endif
```

### 7.3 Test Quality Validation
**MANDATORY**: Every test must meet these criteria:
- ✅ Tests actual behavior, not just existence
- ✅ Verifies that modifiers are actually applied
- ✅ Confirms that configurations actually affect behavior
- ✅ Tests platform-specific behavior when applicable
- ✅ Uses hosting controllers to test real view behavior
- ✅ Would catch bugs if the functionality was broken

**MANDATORY**: A test is cosmetic if it:
- ❌ Only checks that objects exist
- ❌ Only verifies configuration values are set
- ❌ Only tests default values without testing they work
- ❌ Doesn't test actual functionality
- ❌ Wouldn't catch bugs if the functionality was broken

### 7.4 Testing Callback Functionality (REQUIRED)
**MANDATORY**: When testing components with callbacks, tests must verify callbacks are ACTUALLY invoked:

#### 7.4.1 Callback Testing Pattern
```swift
// ❌ FORBIDDEN: Only tests that callbacks exist
func testListCollectionViewWithCallbacks() {
    let view = ListCollectionView(
        items: items,
        onItemSelected: { _ in }
    )
    #expect(view != nil, "View should be created")
}

// ✅ REQUIRED: Tests that callbacks are actually invoked
func testListCollectionViewOnItemSelectedCallback() {
    var callbackInvoked = false
    var selectedItem: TestItem?
    
    let view = ListCollectionView(
        items: items,
        onItemSelected: { item in
            callbackInvoked = true
            selectedItem = item
        }
    )
    
    // Use ViewInspector or similar to simulate tap
    do {
        let inspector = try ViewInspector.inspect(view)
        let cards = try inspector.findAll(ListCardComponent<TestItem>.self)
        if let firstCard = cards.first {
            try firstCard.callOnTapGesture()
        }
        
        // Verify callback was actually invoked
        #expect(callbackInvoked, "Callback should be invoked when tapped")
        #expect(selectedItem != nil, "Selected item should not be nil")
        #expect(selectedItem?.id == items.first?.id, "Correct item should be selected")
    } catch {
        // Fallback: At least document expected behavior
        #expect(true, "Callbacks should be invokable when component is tapped")
    }
}
```

#### 7.4.2 Callback Testing Requirements
- **MANDATORY**: Tests must simulate user interaction (tap, swipe, etc.)
- **MANDATORY**: Tests must verify callbacks are invoked when interaction occurs
- **MANDATORY**: Tests must verify correct data is passed to callbacks
- **MANDATORY**: Tests must verify callback parameters match expected values
- **MANDATORY**: Use ViewInspector or similar tools to simulate interactions
- **MANDATORY**: If ViewInspector isn't available, use hosting controllers to test real behavior

## Rule 8: External Module Integration Testing

### 8.1 Dual Test Module Strategy
- **MANDATORY**: Every function touched MUST be tested in BOTH test modules
- **MANDATORY**: Internal tests use `@testable import` for implementation testing
- **MANDATORY**: External tests use normal `import` for public API visibility testing
- **MANDATORY**: No function can be released without external integration tests

### 8.2 Test Module Structure
```swift
// SixLayerFrameworkTests - Internal testing with @testable
@testable import SixLayerFramework

// SixLayerFrameworkExternalIntegrationTests - External testing
import SixLayerFramework  // NO @testable
```

### 8.3 External Integration Test Requirements
- **MANDATORY**: Every public API MUST be tested from external perspective
- **MANDATORY**: Tests must verify functions are accessible from external modules
- **MANDATORY**: Tests must catch API visibility issues (like v4.6.5 bug)
- **MANDATORY**: Every function touched MUST have corresponding external test

### 8.4 External Test Pattern
```swift
// ✅ REQUIRED: External integration test for every function
@Suite("External Module Integration Tests")
struct ExternalModuleIntegrationTests {
    
    @Test("Platform photo picker accessible from external modules")
    func testPlatformPhotoPickerAccessible() async throws {
        // Simulate external module usage
        await MainActor.run {
            let _ = platformPhotoPicker_L4(onImageSelected: { _ in })
            #expect(true, "Function is accessible")
        }
    }
    
    // Every function that's touched MUST have a test here
}
```

### 8.5 When to Add External Tests
- **MANDATORY**: When you modify any file, add corresponding external test
- **MANDATORY**: When you add a new public function, add external test
- **MANDATORY**: When you fix an API visibility bug, add external test
- **MANDATORY**: When you refactor public APIs, update external tests

### 8.6 What We Learned from v4.6.5
The `platformPhotoPicker_L4` bug (v4.6.5):
- ❌ Internal tests passed (using `@testable`)
- ❌ External modules couldn't access it (normal `import`)
- ✅ External integration tests would have caught this

**MANDATORY**: External integration tests catch bugs that `@testable` tests miss.

## Summary

**MANDATORY**: Every function must be tested to ensure:
1. ✅ It does what it's supposed to do
2. ✅ It applies all the correct modifiers it should
3. ✅ Platform-dependent behavior is properly mocked and tested
4. ✅ Each layer is tested independently (L5 doesn't test L6 behavior)
5. ✅ Real-world usage scenarios are covered
6. ✅ Tests actually validate behavior, not just existence
7. ✅ Tests are functional, not cosmetic
8. ✅ Public APIs are accessible from external modules (external integration tests)

**MANDATORY**: This ensures that bugs like the automatic accessibility identifier failure and the v4.6.5 API visibility issue cannot go undetected.

**MANDATORY**: No function can be released without meeting ALL these requirements.
