# Layer 1 Accessibility Guide

## Overview

All Layer 1 `platform*_L1` functions have complete accessibility support, ensuring that every view created by these functions is fully accessible to users with disabilities. This guide documents the accessibility features available for each Layer 1 function.

**Issue #166 Status**: ✅ Complete - All 86 Layer 1 functions have full accessibility support.

## Accessibility Features

Every Layer 1 function that returns a `View` automatically includes:

### ✅ **Accessibility Identifier**
- Automatically generated from function name (e.g., `platformPresentItemCollection_L1`)
- Can be customized using `identifierName` parameter
- Used for UI testing and automation

### ✅ **Accessibility Label**
- Descriptive text read by VoiceOver
- Automatically extracted from view content when available
- Can be explicitly provided via `accessibilityLabel` parameter
- When `accessibilityLabel` is nil, `identifierLabel` is used as the VoiceOver label (see `AutomaticAccessibilityIdentifiers.md` and `AccessibilityLabelsGuide.md`)

### ✅ **Accessibility Hints**
- Helpful hints explaining element purpose
- Applied when appropriate for interactive elements
- Context-aware hints based on function type

### ✅ **Accessibility Traits**
- Correct traits automatically applied (button, link, header, etc.)
- Matches element's purpose and behavior
- Ensures proper VoiceOver navigation

### ✅ **Accessibility Values**
- Current state values for stateful elements
- Updates automatically when state changes
- Accurate representation of element state

### ✅ **Accessibility Sort Priority**
- Logical reading order
- Ensures VoiceOver navigates in correct sequence
- Platform-appropriate ordering

### ✅ **HIG Compliance Features**
- Touch target sizing (minimum 44x44 points)
- Color contrast (WCAG AA compliant)
- Typography scaling (Dynamic Type support)
- Focus indicators
- Motion preferences
- Light/dark mode support

## Function Categories and Accessibility

### 1. Data Presentation Functions (44 functions)

#### Item Collection (`platformPresentItemCollection_L1`)
- **Accessibility Identifier**: `platformPresentItemCollection_L1`
- **Traits**: Collection, List (when appropriate)
- **Labels**: Automatically extracted from item content
- **Hints**: "Double tap to select item" (when `onItemSelected` provided)
- **Row Actions**: Edit/Delete actions automatically accessible via swipe/context menu

**Example:**
```swift
platformPresentItemCollection_L1(
    items: vehicles,
    hints: hints,
    onItemSelected: { vehicle in
        // VoiceOver: "Double tap to select item"
    },
    onItemEdited: { vehicle in
        // VoiceOver: "Swipe left for more options, then double tap Edit"
    }
)
```

#### Numeric Data (`platformPresentNumericData_L1`)
- **Accessibility Identifier**: `platformPresentNumericData_L1`
- **Traits**: Static Text
- **Labels**: Formatted number with unit (e.g., "1,250.50 USD")
- **Values**: Current numeric value

#### Form Data (`platformPresentFormData_L1`)
- **Accessibility Identifier**: `platformPresentFormData_L1`
- **Traits**: Form, Text Field (for input fields)
- **Labels**: Field labels automatically used
- **Hints**: "Double tap to edit" (for editable fields)

#### Modal Form (`platformPresentModalForm_L1`)
- **Accessibility Identifier**: `platformPresentModalForm_L1`
- **Traits**: Modal, Form
- **Labels**: Form title and field labels
- **Focus Management**: Automatic focus on first field

#### Media Data (`platformPresentMediaData_L1`)
- **Accessibility Identifier**: `platformPresentMediaData_L1`
- **Traits**: Image, Media (when appropriate)
- **Labels**: Image titles/descriptions
- **Hints**: "Double tap to view full size" (when tappable)

#### Hierarchical Data (`platformPresentHierarchicalData_L1`)
- **Accessibility Identifier**: `platformPresentHierarchicalData_L1`
- **Traits**: Outline, List
- **Labels**: Item titles with hierarchy level
- **Navigation**: Proper hierarchy navigation for VoiceOver

#### Temporal Data (`platformPresentTemporalData_L1`)
- **Accessibility Identifier**: `platformPresentTemporalData_L1`
- **Traits**: Static Text, Time (when appropriate)
- **Labels**: Formatted dates/times with context
- **Values**: Date/time values in accessible format

#### Content & Basic Values
- **`platformPresentContent_L1`**: Identifier, labels from content
- **`platformPresentBasicValue_L1`**: Identifier, formatted value labels
- **`platformPresentBasicArray_L1`**: Identifier, list of values

#### Settings (`platformPresentSettings_L1`)
- **Accessibility Identifier**: `platformPresentSettings_L1`
- **Traits**: Form, Settings
- **Labels**: Setting titles and descriptions
- **Values**: Current setting values (toggle states, text values, etc.)

#### Responsive Card (`platformResponsiveCard_L1`)
- **Accessibility Identifier**: `platformResponsiveCard_L1`
- **Traits**: Container, Card
- **Labels**: Card title/content labels
- **Hints**: "Card" (when appropriate)

### 2. Navigation Functions (3 functions)

#### Navigation Stack (`platformPresentNavigationStack_L1`)
- **Accessibility Identifier**: `platformPresentNavigationStack_L1` or title-based
- **Traits**: Navigation, Container
- **Labels**: Navigation title
- **Navigation**: Proper navigation hierarchy for VoiceOver

#### App Navigation (`platformPresentAppNavigation_L1`)
- **Accessibility Identifier**: `platformPresentAppNavigation_L1`
- **Traits**: Navigation, Split View (when appropriate)
- **Labels**: Sidebar and detail section labels
- **Navigation**: Platform-appropriate navigation patterns

### 3. Photo Functions (6 functions)

#### Photo Capture (`platformPhotoCapture_L1`)
- **Accessibility Identifier**: `platformPhotoCapture_L1`
- **Traits**: Button, Camera
- **Labels**: "Take photo" or camera interface labels
- **Hints**: "Double tap to capture photo"

#### Photo Selection (`platformPhotoSelection_L1`)
- **Accessibility Identifier**: `platformPhotoSelection_L1`
- **Traits**: Button, Image Picker
- **Labels**: "Select photo" or picker interface labels
- **Hints**: "Double tap to select from photo library"

#### Photo Display (`platformPhotoDisplay_L1`)
- **Accessibility Identifier**: `platformPhotoDisplay_L1`
- **Traits**: Image
- **Labels**: Image descriptions or titles
- **Hints**: "Double tap to view full size" (when tappable)

### 4. Security Functions (4 functions)

#### Secure Content (`platformPresentSecureContent_L1`)
- **Accessibility Identifier**: `platformPresentSecureContent_L1`
- **Traits**: Container, Secure
- **Labels**: Content labels with security indicator
- **Privacy**: Respects privacy indicators

#### Secure Text Field (`platformPresentSecureTextField_L1`)
- **Accessibility Identifier**: `platformPresentSecureTextField_L1`
- **Traits**: Text Field, Secure Text Entry
- **Labels**: Field title/label
- **Hints**: "Double tap to enter secure text"

#### Privacy Indicator (`platformShowPrivacyIndicator_L1`)
- **Accessibility Identifier**: `platformShowPrivacyIndicator_L1`
- **Traits**: Indicator
- **Labels**: Privacy permission type indicator
- **Note**: Returns `EmptyView()` but has identifier for consistency

### 5. OCR Functions (5 functions)

#### OCR with Disambiguation (`platformOCRWithDisambiguation_L1`)
- **Accessibility Identifier**: `platformOCRWithDisambiguation_L1`
- **Traits**: Container, Image Processor
- **Labels**: "OCR processing" or result labels
- **Hints**: "Double tap to correct text" (when correction available)

#### OCR with Visual Correction (`platformOCRWithVisualCorrection_L1`)
- **Accessibility Identifier**: `platformOCRWithVisualCorrection_L1`
- **Traits**: Container, Image Processor, Interactive
- **Labels**: OCR result labels
- **Hints**: "Double tap to edit recognized text"

#### Extract Structured Data (`platformExtractStructuredData_L1`)
- **Accessibility Identifier**: `platformExtractStructuredData_L1`
- **Traits**: Container, Data Processor
- **Labels**: Extracted data labels
- **Values**: Structured data values

### 6. Notification Functions (1 View function)

#### Alert Presentation (`platformPresentAlert_L1`)
- **Accessibility Identifier**: `platformPresentAlert_L1`
- **Traits**: Alert, Dialog
- **Labels**: Alert title and message
- **Focus Management**: Automatic focus on alert

**Note**: Other notification functions (`platformRequestNotificationPermission_L1`, `platformShowNotification_L1`, `platformUpdateBadge_L1`) are async/throwing functions that don't return Views, so they don't need accessibility modifiers.

### 7. Internationalization Functions (16 functions)

#### Localized Content (`platformPresentLocalizedContent_L1`)
- **Accessibility Identifier**: `platformPresentLocalizedContent_L1`
- **Traits**: Container
- **Labels**: Localized content labels
- **RTL Support**: Automatic right-to-left layout support

#### Localized Text Presentation
- **`platformPresentLocalizedText_L1`**: Text with locale-aware formatting
- **`platformPresentLocalizedNumber_L1`**: Numbers with locale formatting
- **`platformPresentLocalizedCurrency_L1`**: Currency with locale formatting
- **`platformPresentLocalizedDate_L1`**: Dates with locale formatting
- **`platformPresentLocalizedTime_L1`**: Times with locale formatting
- **`platformPresentLocalizedPercentage_L1`**: Percentages with locale formatting
- **`platformPresentLocalizedPlural_L1`**: Plural forms with locale rules
- **`platformPresentLocalizedString_L1`**: Localized strings

All have:
- **Accessibility Identifier**: Function name-based
- **Traits**: Static Text
- **Labels**: Localized formatted values
- **RTL Support**: Automatic layout direction

#### RTL Containers
- **`platformRTLContainer_L1`**: Generic RTL container
- **`platformRTLHStack_L1`**: RTL-aware horizontal stack
- **`platformRTLVStack_L1`**: RTL-aware vertical stack
- **`platformRTLZStack_L1`**: RTL-aware z-stack

All have:
- **Accessibility Identifier**: Function name-based
- **Traits**: Container
- **Layout Direction**: Automatic RTL/LTR based on locale

#### Localized Form Fields
- **`platformLocalizedTextField_L1`**: Text field with localization
- **`platformLocalizedSecureField_L1`**: Secure field with localization
- **`platformLocalizedTextEditor_L1`**: Text editor with localization

All have:
- **Accessibility Identifier**: Function name-based
- **Traits**: Text Field, Secure Text Entry (for secure field)
- **Labels**: Field title/label (can be provided via `accessibilityLabel` parameter)
- **Hints**: "Double tap to edit" (when editable)

### 8. Data Analysis Functions (6 functions)

#### DataFrame Analysis (`platformAnalyzeDataFrame_L1`)
- **Accessibility Identifier**: `platformAnalyzeDataFrame_L1`
- **Traits**: Container, Data Visualization
- **Labels**: Analysis result labels
- **Values**: Statistical values and insights

#### Compare DataFrames (`platformCompareDataFrames_L1`)
- **Accessibility Identifier**: `platformCompareDataFrames_L1`
- **Traits**: Container, Data Comparison
- **Labels**: Comparison result labels
- **Values**: Difference values and metrics

#### Assess Data Quality (`platformAssessDataQuality_L1`)
- **Accessibility Identifier**: `platformAssessDataQuality_L1`
- **Traits**: Container, Quality Assessment
- **Labels**: Quality metric labels
- **Values**: Quality scores and recommendations

### 9. Barcode Functions (1 function)

#### Barcode Scanning (`platformScanBarcode_L1`)
- **Accessibility Identifier**: `platformScanBarcode_L1`
- **Traits**: Container, Barcode Scanner
- **Labels**: "Barcode scanner" or result labels
- **Hints**: "Double tap to scan barcode" (when interactive)
- **Values**: Detected barcode values

## Customizing Accessibility

### Providing Custom Labels

Some functions support optional `accessibilityLabel` parameters. When `accessibilityLabel` is not provided, `.automaticCompliance()` uses `identifierLabel` as the VoiceOver label (localized and formatted). Pass raw text for `identifierLabel`; do not sanitize it.

```swift
// Text field with custom label
platformLocalizedTextField_L1(
    title: "Email",
    text: $email,
    hints: hints,
    accessibilityLabel: "Email address field"  // Custom VoiceOver label
)

// Secure field with custom label
platformLocalizedSecureField_L1(
    title: "Password",
    text: $password,
    hints: hints,
    accessibilityLabel: "Password entry field"  // Custom VoiceOver label
)
```

### Custom Identifier Names

Functions that support `identifierName` parameter:

```swift
platformPresentItemCollection_L1(
    items: items,
    hints: hints
)
.automaticCompliance(identifierName: "vehicle-list")  // Custom identifier
```

## Testing Accessibility

### Unit Tests

All Layer 1 functions have unit tests in `Development/Tests/LayeredTestingSuite/L1SemanticTests.swift` that verify:
- Functions return hostable views
- Views can have accessibility compliance applied
- 77 tests covering all 86 functions

### UI Tests

Comprehensive UI tests in `Development/Tests/SixLayerFrameworkUITests/Layer1AccessibilityUITests.swift` verify:
- Accessibility identifiers exist and are findable
- Accessibility labels are present and descriptive
- Accessibility traits are correct
- VoiceOver compatibility
- Switch Control compatibility

### RealUI Test App

All functions have examples in the RealUI test app (`Development/Tests/SixLayerFrameworkUITests/TestApp/Layer1Examples/`) that can be:
- Viewed in the test app
- Tested with VoiceOver
- Verified with accessibility inspector
- Used as reference implementations

## Best Practices

### 1. Use Layer 1 Functions for All UI

Always use Layer 1 functions instead of raw SwiftUI components to ensure accessibility:

```swift
// ✅ Good: Automatic accessibility
platformPresentItemCollection_L1(items: items, hints: hints)

// ❌ Bad: Manual accessibility setup required
List(items) { item in ... }
    .accessibilityIdentifier("...")
    .accessibilityLabel("...")
    // ... many more modifiers needed
```

### 2. Provide Custom Labels When Needed

For form fields, provide custom labels when the default isn't descriptive enough:

```swift
// ✅ Good: Custom label for clarity
platformLocalizedTextField_L1(
    title: "Email",
    text: $email,
    accessibilityLabel: "Email address for account login"
)
```

### 3. Test with VoiceOver

Always test your Layer 1 implementations with VoiceOver enabled:
- iOS: Settings → Accessibility → VoiceOver
- macOS: System Preferences → Accessibility → VoiceOver

### 4. Verify with Accessibility Inspector

Use Xcode's Accessibility Inspector to verify:
- Identifiers are present
- Labels are descriptive
- Traits are correct
- Values are accurate

## Accessibility Compliance

All Layer 1 functions comply with:

- ✅ **WCAG 2.1 Level AA** - Color contrast, text sizing
- ✅ **Apple Human Interface Guidelines** - Touch targets, spacing, typography
- ✅ **VoiceOver** - Full screen reader support
- ✅ **Switch Control** - Full switch control support
- ✅ **Dynamic Type** - Text scaling support
- ✅ **High Contrast** - High contrast mode support
- ✅ **Reduced Motion** - Motion preference support

## Related Documentation

- **[Automatic Accessibility Identifiers](AutomaticAccessibilityIdentifiers.md)** - How identifiers are generated
- **[Accessibility Labels Guide](AccessibilityLabelsGuide.md)** - How labels work
- **[Layer 1 Semantic Guide](README_Layer1_Semantic.md)** - Complete Layer 1 function reference
- **[Testing Guide](Layer1AccessibilityTestingGuide.md)** - How to test Layer 1 accessibility

## Issue #166 Completion

**Status**: ✅ Complete

- **86/86 functions** have `.automaticCompliance()`
- **77 unit tests** covering all functions
- **Comprehensive UI tests** for accessibility verification
- **47+ RealUI examples** demonstrating all functions
- **Complete documentation** (this guide)

All Layer 1 functions are now fully accessible and ready for production use.
