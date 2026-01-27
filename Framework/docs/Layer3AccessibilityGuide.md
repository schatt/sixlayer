# Layer 3 Accessibility Guide

## Overview

Layer 3 - Strategy Selection functions select optimal strategies for OCR operations based on text types, document types, and platform capabilities. Like Layer 2, Layer 3 functions return data structures (e.g., `OCRStrategy`), which are used by other layers to create Views.

## Key Difference from Layer 1

**Layer 1**: Functions return `View` → Need `.automaticCompliance()`  
**Layer 2**: Functions return data structures (`OCRLayout`) → No `.automaticCompliance()` needed  
**Layer 3**: Functions return data structures (`OCRStrategy`) → No `.automaticCompliance()` needed

## Layer 3 Functions

### OCR Strategy Functions (7 functions)

All Layer 3 OCR strategy functions return `OCRStrategy` data structures:

1. **`platformOCRStrategy_L3`** - Generic OCR strategy selection
   - Returns: `OCRStrategy`
   - Purpose: Selects optimal OCR strategy based on text types and platform
   - Accessibility: N/A (returns data structure, not View)

2. **`platformDocumentOCRStrategy_L3`** - Document-specific OCR strategy
   - Returns: `OCRStrategy`
   - Purpose: Selects OCR strategy for specific document types
   - Accessibility: N/A (returns data structure, not View)

3. **`platformReceiptOCRStrategy_L3`** - Receipt-specific OCR strategy
   - Returns: `OCRStrategy`
   - Purpose: Selects OCR strategy optimized for receipt processing
   - Accessibility: N/A (returns data structure, not View)

4. **`platformBusinessCardOCRStrategy_L3`** - Business card-specific OCR strategy
   - Returns: `OCRStrategy`
   - Purpose: Selects OCR strategy optimized for business card processing
   - Accessibility: N/A (returns data structure, not View)

5. **`platformInvoiceOCRStrategy_L3`** - Invoice-specific OCR strategy
   - Returns: `OCRStrategy`
   - Purpose: Selects OCR strategy optimized for invoice processing
   - Accessibility: N/A (returns data structure, not View)

6. **`platformOptimalOCRStrategy_L3`** - Optimal OCR strategy selection
   - Returns: `OCRStrategy`
   - Purpose: Selects optimal OCR strategy based on text types and confidence threshold
   - Accessibility: N/A (returns data structure, not View)

7. **`platformBatchOCRStrategy_L3`** - Batch OCR strategy selection
   - Returns: `OCRStrategy`
   - Purpose: Selects OCR strategy optimized for batch processing
   - Accessibility: N/A (returns data structure, not View)

## Accessibility for Example Views

While Layer 3 functions themselves don't need accessibility (they return data structures), the **example views** that demonstrate these functions in the RealUI test app do need accessibility support.

### Example Views with Accessibility

All example views in `Layer3ExamplesView.swift` have `.automaticCompliance()` applied:

- **`Layer3ExamplesView`** - Main container view
- **`OCRStrategyExamples`** - Container for OCR strategy examples
- **`GeneralOCRStrategyExample`** - Example for `platformOCRStrategy_L3`
- **`DocumentOCRStrategyExample`** - Example for `platformDocumentOCRStrategy_L3`
- **`ReceiptOCRStrategyExample`** - Example for `platformReceiptOCRStrategy_L3`
- **`BusinessCardOCRStrategyExample`** - Example for `platformBusinessCardOCRStrategy_L3`
- **`InvoiceOCRStrategyExample`** - Example for `platformInvoiceOCRStrategy_L3`
- **`OptimalOCRStrategyExample`** - Example for `platformOptimalOCRStrategy_L3`
- **`BatchOCRStrategyExample`** - Example for `platformBatchOCRStrategy_L3`
- **`StrategyDetailsView`** - Displays strategy information
- **`ExampleCard`** - Reusable card component
- **`ExampleSection`** - Section header component

### Accessibility Features Applied

Each example view has:

- ✅ **Accessibility Identifier**: Automatically generated via `.automaticCompliance(named: "ViewName")`
- ✅ **Accessibility Label**: Generated from view name and content
- ✅ **Accessibility Hints**: Contextual hints when appropriate
- ✅ **Accessibility Traits**: Correct traits for interactive elements
- ✅ **Accessibility Values**: State values for dynamic content
- ✅ **Accessibility Sort Priority**: Logical reading order
- ✅ **HIG Compliance**: Apple Human Interface Guidelines features

## Testing

### UI Tests

Comprehensive XCUITest suite in `Layer3AccessibilityUITests.swift` verifies:

- ✅ Accessibility identifiers exist for all example views
- ✅ Accessibility labels are present for interactive elements
- ✅ Accessibility traits are correct
- ✅ VoiceOver compatibility
- ✅ Switch Control compatibility

### Test Coverage

- **7 Layer 3 functions** - All have example views
- **12 example views** - All have accessibility support
- **100% coverage** - All functions and views tested

## Usage Example

```swift
// Layer 3 function returns data structure (no accessibility needed)
let strategy = platformOCRStrategy_L3(
    textTypes: [.general, .number, .date],
    platform: .current
)

// Example view that uses the strategy (needs accessibility)
struct GeneralOCRStrategyExample: View {
    @State private var strategy: OCRStrategy?
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            platformButton("Calculate Strategy") {
                strategy = platformOCRStrategy_L3(
                    textTypes: [.general, .number, .date],
                    platform: .current
                )
            }
            
            if let strategy = strategy {
                StrategyDetailsView(strategy: strategy)
            }
        }
        .automaticCompliance(named: "GeneralOCRStrategyExample") // ✅ Accessibility applied
    }
}
```

## Compliance Standards

Layer 3 example views comply with:

- ✅ **WCAG 2.1 Level AA** - Web Content Accessibility Guidelines
- ✅ **Apple HIG** - Apple Human Interface Guidelines
- ✅ **VoiceOver** - Full VoiceOver compatibility
- ✅ **Switch Control** - Switch Control accessibility
- ✅ **Dynamic Type** - Text scaling support
- ✅ **High Contrast** - High contrast mode support

## Summary

- **Layer 3 functions**: Return data structures, no accessibility needed
- **Example views**: Have complete accessibility support via `.automaticCompliance()`
- **Test coverage**: 100% for all 7 functions and 12 example views
- **Compliance**: Meets all accessibility standards
