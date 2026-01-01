# Test Plans for SixLayer Framework

## Problem
Xcode is timing out when trying to discover all 4,518 test methods across 355 test files. This prevents the Test Navigator from displaying the test list.

## Solution
Test Plans organize tests into smaller, manageable groups. When you select a test plan, Xcode only discovers tests for that plan, not all tests at once.

## Available Test Plans

### 1. Unit Tests - Core & Layers
- **File**: `01-UnitTests-CoreLayers.xctestplan`
- **Focus**: Core architecture, layers, services
- **Use when**: Testing foundational functionality

### 2. Unit Tests - Accessibility  
- **File**: `02-UnitTests-Accessibility.xctestplan`
- **Focus**: Accessibility identifier generation, compliance
- **Use when**: Working on accessibility features

### 3. Unit Tests - Forms
- **File**: `03-UnitTests-Forms.xctestplan`
- **Focus**: Form components, validation, state management
- **Use when**: Testing form functionality

### 4. ViewInspector Tests - Accessibility
- **File**: `04-UITests-Accessibility.xctestplan`
- **Focus**: View structure and modifier testing with ViewInspector (unit tests)
- **Use when**: Testing view structure, modifiers, and accessibility identifiers
- **Note**: These are unit tests that verify view structure, not actual UI rendering tests

### 5. All Unit Tests
- **File**: `05-AllUnitTests.xctestplan`
- **Focus**: Complete unit test suite
- **Use when**: Running full unit test suite

## How to Use Test Plans

### In Xcode UI:
1. **Product → Scheme → Edit Scheme...**
2. Click **Test** tab
3. Click **Info** tab (if not already selected)
4. In the **Test Plan** dropdown, select a test plan
5. Click **Close**
6. Now when you open Test Navigator, Xcode will only discover tests for the selected plan

### From Command Line:
```bash
# Run a specific test plan
xcodebuild test \
  -project SixLayerFramework.xcodeproj \
  -scheme SixLayerFramework-AllTests-macOS \
  -testPlan "Unit Tests - Accessibility" \
  -destination "platform=macOS"
```

## Benefits

1. **Faster Discovery**: Xcode only discovers tests in the selected plan
2. **No Timeouts**: Smaller test groups prevent discovery timeouts
3. **Focused Testing**: Run only relevant tests for your current work
4. **Better Organization**: Tests grouped by functionality

## Next Steps

To further optimize, you can:
1. Create more granular test plans for specific features
2. Use test plan filters to exclude certain test suites
3. Create custom test plans for your workflow

## Note

Test plans are stored in:
`SixLayerFramework.xcodeproj/xcshareddata/xctestplans/`

They are shared with the team (xcshareddata) so everyone benefits from the same organization.
