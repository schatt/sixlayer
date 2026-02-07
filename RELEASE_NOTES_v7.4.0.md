# SixLayer Framework v7.4.0 Release Notes

**Release Date**: January 12, 2026  
**Release Type**: Minor (PhotoPurpose Refactoring - Breaking Change)  
**Previous Version**: v7.3.0

## 🎯 Release Summary

This minor release refactors `PhotoPurpose` from vehicle-specific enum cases to generic, domain-agnostic purposes. This is a **breaking change** that makes the framework truly generic and usable for any domain, not just vehicle management. The change converts `PhotoPurpose` from an enum to a struct, allowing projects to create custom purposes and maintain backward compatibility using extension aliases.

## ⚠️ Breaking Changes

### **PhotoPurpose Refactoring (Issue #151)**

#### **Enum → Struct Conversion**

`PhotoPurpose` has been converted from an enum to a struct to allow extensibility:

**Before (v7.3.0 and earlier):**
```swift
public enum PhotoPurpose: String, CaseIterable {
    case vehiclePhoto = "vehicle"
    case fuelReceipt = "fuel_receipt"
    case pumpDisplay = "pump_display"
    case odometer = "odometer"
    case maintenance = "maintenance"
    case expense = "expense"
    case profile = "profile"
    case document = "document"
}
```

**After (v7.4.0+):**
```swift
public struct PhotoPurpose: Hashable, Sendable {
    public let identifier: String
    
    public init(identifier: String)
    
    // Built-in purposes
    public static let general: PhotoPurpose
    public static let document: PhotoPurpose
    public static let profile: PhotoPurpose
    public static let reference: PhotoPurpose
    public static let thumbnail: PhotoPurpose
    public static let preview: PhotoPurpose
}
```

#### **Vehicle-Specific Cases Removed**

The following vehicle-specific cases have been **removed** and must be migrated:

- `vehiclePhoto` → Use `.general` or create alias
- `fuelReceipt` → Use `.document` or create alias
- `pumpDisplay` → Use `.document` or create alias
- `odometer` → Use `.document` or create alias
- `maintenance` → Use `.reference` or create alias
- `expense` → Use `.reference` or create alias

#### **New Generic Purposes**

Replaced with generic, domain-agnostic purposes:

- **`.general`** - General purpose photos
  - Use for: General photos that don't fit other categories
  - Replaces: `vehiclePhoto`

- **`.document`** - Document photos (receipts, forms, etc.)
  - Use for: Receipts, forms, documents, scanned papers
  - Replaces: `fuelReceipt`, `pumpDisplay`, `odometer`

- **`.profile`** - Profile/avatar photos
  - Use for: User avatars, profile pictures, contact photos
  - Replaces: `profile` (same name, but now a static property)

- **`.reference`** - Reference photos (maintenance, expense tracking, etc.)
  - Use for: Reference images for tracking, maintenance records, expense documentation
  - Replaces: `maintenance`, `expense`

- **`.thumbnail`** - Thumbnail/preview images
  - Use for: Small preview images, thumbnails in lists
  - New purpose, not replacing anything

- **`.preview`** - UI preview images
  - Use for: Preview images in UI, placeholder images
  - New purpose, not replacing anything

## 🆕 What's New

### **Extensible PhotoPurpose System**

#### **Custom Purposes**

Projects can now create custom photo purposes for their specific domain:

```swift
extension PhotoPurpose {
    // Custom purpose for product photos
    static let productPhoto = PhotoPurpose(identifier: "product")
    
    // Custom purpose for medical records
    static let medicalRecord = PhotoPurpose(identifier: "medical_record")
    
    // Custom purpose for real estate listings
    static let propertyPhoto = PhotoPurpose(identifier: "property")
}
```

#### **Backward Compatibility Aliases**

Projects can maintain backward compatibility by creating aliases:

```swift
extension PhotoPurpose {
    // Backward compatibility aliases
    static let vehiclePhoto = PhotoPurpose.general
    static let fuelReceipt = PhotoPurpose.document
    static let pumpDisplay = PhotoPurpose.document
    static let odometer = PhotoPurpose.document
    static let maintenance = PhotoPurpose.reference
    static let expense = PhotoPurpose.reference
}
```

This allows existing code to continue working without changes:

```swift
// Existing code continues to work with aliases
platformPhotoCapture_L1(
    purpose: .vehiclePhoto,  // Works with alias
    context: context,
    onImageCaptured: { image in }
)
```

#### **Usage Examples**

See `Framework/Examples/PhotoPurposeExtensionExample.swift` for complete examples showing:
- Backward compatibility aliases
- Custom domain-specific purposes
- Usage patterns for both approaches

## 🔧 What's Fixed

### **Framework Genericity**

#### **Removed Domain-Specific Code**

The framework is now truly generic and usable for any domain:
- No vehicle-specific code in framework
- No assumptions about business domain
- Works for any use case (vehicles, tasks, documents, products, etc.)

#### **Extensible Architecture**

Projects can extend `PhotoPurpose` without modifying framework code:
- Create custom purposes for specific domains
- Maintain backward compatibility with aliases
- Framework logic adapts to custom purposes

#### **Consistent API**

All photo functions work with generic purposes:
- `platformPhotoCapture_L1()` - Works with any purpose
- `platformPhotoSelection_L1()` - Works with any purpose
- `platformPhotoDisplay_L1()` - Works with any purpose
- All Layer 2, 3, and 4 functions updated

### **Updated Framework Logic**

All switch statements throughout the framework have been updated to handle the new generic purposes:

#### **Layer 1: Display Style Selection**

`displayStyleForPurpose()` in `PlatformPhotoSemanticLayer1.swift`:
- Updated to handle generic purposes
- Custom purposes default to `.general` behavior
- Maintains backward compatibility

#### **Layer 2: Layout Decision Functions**

Layout decision functions in `PlatformPhotoLayoutDecisionLayer2.swift`:
- Updated layout decisions for generic purposes
- Custom purposes use appropriate defaults
- Maintains consistent behavior

#### **Layer 3: Strategy Selection Functions**

Strategy selection functions in `PlatformPhotoStrategySelectionLayer3.swift`:
- Updated display strategy selection
- Updated editing strategy selection
- Updated compression and optimization strategies
- Custom purposes default to `.general` behavior

#### **PlatformImageExtensions: Size Requirements**

Size requirements based on purpose in `PlatformImageExtensions.swift`:
- Updated size requirements for generic purposes
- Custom purposes use `.general` size requirements
- Maintains performance optimizations

**Important**: Custom purposes default to `.general` behavior in framework logic, ensuring backward compatibility and predictable behavior.

## 📝 Migration Guide

### **Step 1: Update PhotoPurpose Usage**

**Before:**
```swift
platformPhotoCapture_L1(
    purpose: .vehiclePhoto,
    context: context,
    onImageCaptured: { image in }
)
```

**After (Option 1 - Use Generic Purpose):**
```swift
platformPhotoCapture_L1(
    purpose: .general,  // or .document, .reference, etc.
    context: context,
    onImageCaptured: { image in }
)
```

**After (Option 2 - Create Alias):**
```swift
extension PhotoPurpose {
    static let vehiclePhoto = PhotoPurpose.general
}

// Then use as before:
platformPhotoCapture_L1(
    purpose: .vehiclePhoto,  // Works with alias
    context: context,
    onImageCaptured: { image in }
)
```

### **Step 2: Update Switch Statements**

**Before:**
```swift
switch purpose {
case .vehiclePhoto:
    // handle vehicle photo
case .fuelReceipt:
    // handle fuel receipt
case .pumpDisplay:
    // handle pump display
}
```

**After:**
```swift
switch purpose {
case .general, .preview:
    // handle general/preview photos
case .document:
    // handle documents
case .reference:
    // handle reference photos
default:
    // Custom purposes default to .general behavior
}
```

### **Step 3: Create Extension for Backward Compatibility**

Add this extension to your project for backward compatibility:

```swift
extension PhotoPurpose {
    // Map old vehicle-specific purposes to new generic ones
    static let vehiclePhoto = PhotoPurpose.general
    static let fuelReceipt = PhotoPurpose.document
    static let pumpDisplay = PhotoPurpose.document
    static let odometer = PhotoPurpose.document
    static let maintenance = PhotoPurpose.reference
    static let expense = PhotoPurpose.reference
}
```

This allows existing code to continue working without changes.

### **Step 4: Update Custom Logic**

If you have custom logic that switches on `PhotoPurpose`:

1. **Update switch statements** to use new generic purposes
2. **Handle custom purposes** with default cases
3. **Test thoroughly** to ensure behavior matches expectations

## ✅ Backward Compatibility

**Partial backward compatibility** - Existing code will need updates, but migration is straightforward:

1. **Option 1**: Update code to use new generic purposes (`.general`, `.document`, etc.)
2. **Option 2**: Create extension with aliases (recommended for quick migration)
3. **Option 3**: Use custom purposes for domain-specific needs

See `Framework/Examples/PhotoPurposeExtensionExample.swift` for complete migration examples.

## 🧪 Testing

### **Updated Tests**

- All existing tests updated to use generic `PhotoPurpose` cases
- New tests verify extensibility and custom purpose support
- Backward compatibility verified with alias examples
- Framework logic tested with all built-in purposes

### **New Tests**

- Tests for custom purpose creation
- Tests for backward compatibility aliases
- Tests for framework logic with custom purposes
- Tests for all built-in purposes

## 📝 Files Changed

### **Core Framework**

- `Framework/Sources/Core/Models/PlatformPhotoTypes.swift`:
  - Converted enum to struct
  - Added generic purposes (`.general`, `.document`, `.profile`, `.reference`, `.thumbnail`, `.preview`)
  - Added `identifier` property and initializer

### **Layer 1: Semantic**

- `Framework/Sources/Layers/Layer1-Semantic/PlatformPhotoSemanticLayer1.swift`:
  - Updated `displayStyleForPurpose()` to handle generic purposes
  - Custom purposes default to `.general` behavior

### **Layer 2: Layout**

- `Framework/Sources/Layers/Layer2-Layout/PlatformPhotoLayoutDecisionLayer2.swift`:
  - Updated layout decision logic for generic purposes
  - Custom purposes use appropriate defaults

### **Layer 3: Strategy**

- `Framework/Sources/Layers/Layer3-Strategy/PlatformPhotoStrategySelectionLayer3.swift`:
  - Updated display strategy selection
  - Updated editing strategy selection
  - Updated compression and optimization strategies
  - Custom purposes default to `.general` behavior

### **Layer 4: Component**

- `Framework/Sources/Layers/Layer4-Component/PlatformPhotoComponentsLayer4.swift`:
  - Updated component logic for generic purposes
  - All photo capture/selection/display functions updated

### **PlatformImage Extensions**

- `Framework/Sources/Core/Models/PlatformImageExtensions.swift`:
  - Updated size requirements based on purpose
  - Custom purposes use `.general` size requirements

### **Examples**

- `Framework/Examples/PhotoPurposeExtensionExample.swift`:
  - New example file showing migration patterns
  - Demonstrates backward compatibility aliases
  - Shows custom purpose creation

### **Tests**

- All test files updated to use generic purposes
- New tests for extensibility and custom purposes

## 🔗 Related Components

All photo-related functions and components are affected:

- **Photo Capture Functions**:
  - `platformPhotoCapture_L1()`
  - `platformPhotoSelection_L1()`
  - `platformPhotoCapture_L4()`
  - `platformPhotoSelection_L4()`

- **Photo Display Functions**:
  - `platformPhotoDisplay_L1()`
  - `platformPhotoDisplay_L4()`

- **Photo Layout and Strategy Functions**:
  - All Layer 2 layout decision functions
  - All Layer 3 strategy selection functions

- **PlatformImage Size Requirements**:
  - Size requirements based on purpose

## 📚 Documentation

- **Issue #151**: Refactor PhotoPurpose to remove vehicle-specific domain code - ✅ Complete
- `Framework/Examples/PhotoPurposeExtensionExample.swift` - Complete migration examples
- Updated inline documentation in all affected files

## 🎯 Next Steps

Future enhancements could include:
- Additional built-in purposes based on common use cases
- Enhanced documentation for custom purpose creation
- Migration tools or scripts for large codebases
- Additional examples for different domains

## 🔄 Impact Summary

### **For Framework**

- ✅ **Truly Generic**: Framework is now domain-agnostic
- ✅ **Extensible**: Projects can create custom purposes
- ✅ **Maintainable**: No domain-specific code in framework
- ✅ **Future-Proof**: Easy to add new built-in purposes

### **For Developers**

- ⚠️ **Breaking Change**: Must migrate existing code
- ✅ **Migration Path**: Clear migration guide provided
- ✅ **Backward Compatibility**: Can use aliases for quick migration
- ✅ **Flexibility**: Can create custom purposes for specific domains

---

**Version**: 7.4.0  
**Release Date**: January 12, 2026  
**Previous Version**: v7.3.0  
**Status**: Production Ready 🚀  
**Resolves Issue #151**
