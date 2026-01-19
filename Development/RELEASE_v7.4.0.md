# SixLayer Framework v7.4.0 Release Documentation

**Release Date**: January 12, 2026  
**Release Type**: Minor (PhotoPurpose Refactoring - Breaking Change)  
**Previous Release**: v7.3.0  
**Status**: ✅ **COMPLETE**

---

## 🎯 Release Summary

Minor release refactoring `PhotoPurpose` from vehicle-specific enum cases to generic, domain-agnostic purposes. This is a **breaking change** that makes the framework truly generic and usable for any domain, not just vehicle management. Projects can maintain backward compatibility using extension aliases.

---

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

The following vehicle-specific cases have been removed:
- `vehiclePhoto` → Use `.general` or create alias
- `fuelReceipt` → Use `.document` or create alias
- `pumpDisplay` → Use `.document` or create alias
- `odometer` → Use `.document` or create alias
- `maintenance` → Use `.reference` or create alias
- `expense` → Use `.reference` or create alias

#### **New Generic Purposes**

Replaced with generic, domain-agnostic purposes:
- **`.general`** - General purpose photos
- **`.document`** - Document photos (receipts, forms, etc.)
- **`.profile`** - Profile/avatar photos
- **`.reference`** - Reference photos (maintenance, expense tracking, etc.)
- **`.thumbnail`** - Thumbnail/preview images
- **`.preview`** - UI preview images

---

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

#### **Usage Examples**

See `Framework/Examples/PhotoPurposeExtensionExample.swift` for complete examples showing:
- Backward compatibility aliases
- Custom domain-specific purposes
- Usage patterns for both approaches

---

## 🔧 What's Fixed

### **Framework Genericity**

- **Removed domain-specific code**: Framework is now truly generic and usable for any domain
- **Extensible architecture**: Projects can extend PhotoPurpose without modifying framework code
- **Consistent API**: All photo functions work with generic purposes

### **Updated Framework Logic**

All switch statements throughout the framework have been updated:
- **Layer 1**: `displayStyleForPurpose()` - Display style selection
- **Layer 2**: Layout decision functions - Layout and cropping decisions
- **Layer 3**: Strategy selection functions - Display strategy, editing, compression, optimization
- **PlatformImageExtensions**: Size requirements based on purpose

Custom purposes default to `.general` behavior in framework logic, ensuring backward compatibility.

---

## 📋 Migration Guide

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

---

## ✅ Backward Compatibility

**Partial backward compatibility** - Existing code will need updates, but migration is straightforward:

1. **Option 1**: Update code to use new generic purposes (`.general`, `.document`, etc.)
2. **Option 2**: Create extension with aliases (recommended for quick migration)
3. **Option 3**: Use custom purposes for domain-specific needs

See `Framework/Examples/PhotoPurposeExtensionExample.swift` for complete migration examples.

---

## 🧪 Testing

- All existing tests updated to use generic PhotoPurpose cases
- New tests verify extensibility and custom purpose support
- Backward compatibility verified with alias examples
- Framework logic tested with all built-in purposes

---

## 📝 Files Changed

- `Framework/Sources/Core/Models/PlatformPhotoTypes.swift` - Converted enum to struct, added generic purposes
- `Framework/Sources/Layers/Layer1-Semantic/PlatformPhotoSemanticLayer1.swift` - Updated displayStyleForPurpose
- `Framework/Sources/Layers/Layer2-Layout/PlatformPhotoLayoutDecisionLayer2.swift` - Updated layout decision logic
- `Framework/Sources/Layers/Layer3-Strategy/PlatformPhotoStrategySelectionLayer3.swift` - Updated strategy selection
- `Framework/Sources/Layers/Layer4-Component/PlatformPhotoComponentsLayer4.swift` - Updated component logic
- `Framework/Sources/Core/Models/PlatformImageExtensions.swift` - Updated size requirements
- `Framework/Examples/PhotoPurposeExtensionExample.swift` - New example file
- All test files - Updated to use generic purposes

---

## 🔗 Related Components

- All photo capture functions: `platformPhotoCapture_L1()`, `platformPhotoSelection_L1()`, etc.
- Photo display functions: `platformPhotoDisplay_L1()`
- Photo layout and strategy selection functions
- PlatformImage size requirements

---

## 📚 Documentation

- Issue #151: Refactor PhotoPurpose to remove vehicle-specific domain code
- `Framework/Examples/PhotoPurposeExtensionExample.swift` - Complete migration examples
- Updated inline documentation in all affected files

---

## 🎯 Next Steps

Future enhancements could include:
- Additional built-in purposes based on common use cases
- Enhanced documentation for custom purpose creation
- Migration tools or scripts for large codebases

---

**Resolves Issue #151**
