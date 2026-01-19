# SixLayer Framework Examples

**Version**: v7.4.1

## Overview

This folder contains example types and implementations that demonstrate how to use the SixLayer Framework. These are **example implementations** that you can copy and modify for your own use cases.

## Available Examples

### **PhotoPurposeExtensionExample.swift** (v7.4.0)
Comprehensive example showing PhotoPurpose extensibility and migration:

- **Backward compatibility aliases**: Map old vehicle-specific purposes to new generic ones
- **Custom domain-specific purposes**: Create purposes for your specific domain (e-commerce, medical, insurance, etc.)
- **Usage examples**: Complete examples showing how to use aliases and custom purposes
- **Migration guide**: Shows how to migrate from vehicle-specific to generic purposes

**⚠️ Important**: PhotoPurpose was refactored in v7.4.0 from enum to struct. This example shows how to maintain backward compatibility and create custom purposes.

### **GenericTypes.swift**
Example types showing how to create custom data structures that work with the framework:

- **GenericVehicle**: Example vehicle type with CardDisplayable conformance
- **GenericDataItem**: Generic container for any identifiable data
- **VehicleType**: Enumeration for vehicle categorization

### **AutomaticAccessibilityIdentifiersExample.swift**
Demonstrates the automatic accessibility identifier system:

- **Basic automatic identifier usage** with Layer 1 functions
- **Manual override patterns** showing precedence
- **Opt-out scenarios** for specific views
- **Global configuration management** examples

### **AccessibilityIdentifierDebuggingExample.swift**
Shows debugging and inspection capabilities:

- **Debug logging controls** for development
- **Real-time ID inspection** with console output
- **Collision detection testing** examples
- **Advanced debugging scenarios**

### **EnhancedBreadcrumbExample.swift** (v4.1.3)
Comprehensive example of the enhanced breadcrumb system:

- **View hierarchy tracking** with `.named()`
- **Screen context management** with `.screenContext()`
- **UI test code generation** with file saving and clipboard
- **Breadcrumb trail generation** with complete navigation paths
- **UI test helper methods** for common actions
- **Complete automatic accessibility identifiers** (fixed in v4.1.3)

### **NavigationStackExample.swift** (NEW)
Complete example of the 6-layer NavigationStack implementation:

- **Simple content navigation** - Basic navigation stack with title
- **List-detail navigation** - Navigation with items and detail views
- **Split view navigation** - Large screen optimized navigation
- **Modal navigation** - Modal presentation pattern
- **Complete 6-layer flow** - Demonstrates L1 → L2 → L3 → L4 → L5 → L6

### **AutomaticHIGStylingExample.swift** (v5.9.0)
Demonstrates automatic HIG-compliant styling (Issue #35):

- **Layer 1 automatic styling** - All Layer 1 functions automatically get styling
- **Custom view opt-in** - How to use `.automaticCompliance()` with custom views
- **Before/after comparison** - Shows the difference between manual and automatic styling
- **Platform-specific styling** - Automatic platform detection and appropriate styling
- **Component examples** - Text, buttons, toggles, and layout components with automatic styling

### **PlatformImagePhase3Examples.swift** (Issue #33)
Comprehensive examples of PlatformImage Phase 3 features:

- **Export methods** - PNG, JPEG, and Bitmap export examples
- **Image processing** - Resize, crop, rotate, color adjustments, and filters
- **Metadata extraction** - Image properties and analysis
- **Complete pipelines** - End-to-end image processing workflows
- **Image editor class** - Full-featured editor with undo capability
- **Optimization examples** - Image optimization for upload and thumbnails
- **Cross-platform usage** - Consistent processing across iOS and macOS

## How to Use Examples

1. **Copy the example files** you need into your project
2. **Modify the examples** to match your application's requirements
3. **Import SixLayerFramework** in your modified examples
4. **Use the framework functions** with your custom types

## Example Usage

```swift
import SixLayerFramework

// Copy GenericVehicle and modify for your needs
struct MyProduct: Identifiable, CardDisplayable {
    let id = UUID()
    let name: String
    let price: Double
    let category: String
    
    // Implement CardDisplayable protocol
    var cardTitle: String { name }
    var cardSubtitle: String? { category }
    var cardDescription: String? { "$\(price)" }
    var cardColor: Color? { .blue }
}

// Use with framework
let products = [MyProduct(name: "Widget", price: 19.99, category: "Tools")]
let hints = EnhancedPresentationHints.forEcommerceProducts(...)

return platformPresentItemCollection_L1(
    items: products,
    hints: hints
)
```

## Important Notes

- **These are examples** - modify them for your specific needs
- **Don't commit these to the framework** - they're for reference only
- **Test thoroughly** - ensure your types work with your data and requirements
- **Follow naming conventions** - use appropriate naming for your domain

## Framework Integration

These examples show how to:
- Implement `Identifiable` protocol
- Implement `CardDisplayable` protocol
- Work with the platform presentation functions
- Handle generic data in collections
- Create type-safe enums for categorization

## Support

For questions about using these examples:
- Check the main framework documentation
- Look at the framework source code for more patterns
- Refer to the test files for usage examples
