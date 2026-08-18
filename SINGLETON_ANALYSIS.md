# Singleton Analysis - Test State Leakage Risk

## Critical Issues (Accumulating State)

### 1. `CustomFieldRegistry.shared` ⚠️ ONLY USED IN TESTS
**Location**: `Framework/Sources/Components/Forms/AdvancedFieldTypes.swift`
**Status**: **ONLY USED IN TESTS** - No production code references found
**Problem**: 
- `private var customFields: [String: any CustomFieldComponent.Type] = [:]` - dictionary accumulates registrations
- Only referenced in test code (`AdvancedFieldTypesTests.swift`)
- Registry accumulates state across test runs
- Not injectable/thread-local

**Risk**: HIGH - Tests using this registry could see fields registered by other tests running in parallel
**Recommendation**: 
- Make thread-local (like `HintsCache`) OR injectable (like `AccessibilityIdentifierConfig`)
- Tests should use isolated instances to prevent cross-test contamination

### 2. `HintsCache.shared`
**Location**: `Framework/Sources/Layers/Layer1-Semantic/PlatformSemanticLayer1.swift`
**Problem**:
- `private var cache: [String: [String: FieldDisplayHints]] = [:]` - cache accumulates hints
- No clear/reset method
- Not injectable for testing

**Risk**: HIGH - Cache persists between tests, tests could see cached data from other tests

### 3. `AssistiveTouchManager.testCallCounter`
**Location**: `Framework/Sources/Extensions/Accessibility/AssistiveTouchManager.swift`
**Problem**:
- `@MainActor private static var testCallCounter = 0` - static counter accumulates
- No reset mechanism

**Risk**: MEDIUM - Counter grows, but might not affect test logic if tests don't depend on specific values

## Moderate Issues (Stateful Singletons)

### 4. `LiquidGlassDesignSystem.shared`
**Location**: `Framework/Sources/Extensions/SwiftUI/LiquidGlassDesignSystem.swift`
**Problem**:
- `@Published` properties: `isLiquidGlassEnabled`, `currentTheme`
- Not injectable for testing

**Risk**: LOW-MEDIUM - State changes persist, but simple properties (not accumulators)

### 5. `VisualDesignSystem.shared`
**Location**: `Framework/Sources/Extensions/SwiftUI/VisualDesignSystem.swift`
**Problem**:
- `@Published` properties with `NotificationCenter` observers
- `previousTheme` tracking
- Not injectable for testing

**Risk**: LOW-MEDIUM - Theme state persists, but probably doesn't break tests

### 6. `MacOSOptimizationManager` (resolved #422)
**Location**: `Framework/Sources/Platform/macOS/Views/Extensions/PlatformMacOSOptimizationsLayer5.swift`
**Status**: Value type with optional injected `MacOSOptimizationInputs`. No `shared`. Strategy is `macOSPerformanceStrategy(for:)`.

### 7. `DataPresentationIntelligence.shared`
**Location**: `Framework/Sources/Extensions/SwiftUI/DataPresentationIntelligence.swift`
**Problem**:
- Not injectable
- Appears stateless (analysis methods)

**Risk**: LOW - Probably fine, but still not testable in isolation

## Good Patterns (Already Test-Friendly)

### ✅ `RuntimeCapabilityDetection`
**Location**: `Framework/Sources/Core/Models/RuntimeCapabilityDetection.swift`
**Pattern**: Uses `Thread.current.threadDictionary` for test overrides
**Status**: GOOD - Thread-local storage prevents cross-test contamination

### ✅ `TestSetupUtilities.shared`
**Location**: `Development/Tests/SixLayerFrameworkTests/Utilities/TestHelpers/TestSetupUtilities.swift`
**Pattern**: Delegates to `RuntimeCapabilityDetection` (thread-local)
**Status**: GOOD - Uses testable patterns

## Recommendations

### Immediate Priority (HIGH RISK)
1. **Make `CustomFieldRegistry` injectable** - Add environment injection or protocol
2. **Make `HintsCache` injectable** - Add environment injection or clear method
3. **Fix `AssistiveTouchManager.testCallCounter`** - Make it instance-based or add reset

### Future Priority (MODERATE RISK)
4. Consider making design system singletons injectable if they cause test issues
5. Add reset/clear methods to all singletons for test cleanup

### Pattern to Follow
Use the same pattern as `AccessibilityIdentifierConfig`:
- Public initializer for test instances
- Environment injection support
- `resetToDefaults()` or similar cleanup method
