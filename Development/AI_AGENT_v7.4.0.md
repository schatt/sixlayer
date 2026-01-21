# AI Agent Guide - SixLayer Framework v7.4.0

**Version**: v7.4.0  
**Release Date**: January 12, 2026  
**Release Type**: Minor (PhotoPurpose Refactoring - Breaking Change)

---

## ⚠️ **CRITICAL: Breaking Change in v7.4.0**

This release includes a **breaking change** to `PhotoPurpose`. All code using photo purposes must be updated.

### **PhotoPurpose Enum → Struct Conversion (Issue #151)**

`PhotoPurpose` has been converted from an enum to a struct to allow extensibility and make the framework truly generic.

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

### **Vehicle-Specific Cases Removed**

The following cases have been **removed**:
- `vehiclePhoto` → Use `.general` or create alias
- `fuelReceipt` → Use `.document` or create alias
- `pumpDisplay` → Use `.document` or create alias
- `odometer` → Use `.document` or create alias
- `maintenance` → Use `.reference` or create alias
- `expense` → Use `.reference` or create alias

### **New Generic Purposes**

- **`.general`** - General purpose photos (replaces `vehiclePhoto`)
- **`.document`** - Document photos (replaces `fuelReceipt`, `pumpDisplay`, `odometer`)
- **`.profile`** - Profile/avatar photos (same name, now static property)
- **`.reference`** - Reference photos (replaces `maintenance`, `expense`)
- **`.thumbnail`** - Thumbnail/preview images (new)
- **`.preview`** - UI preview images (new)

---

## 🎯 What's New in v7.4.0

### **Extensible PhotoPurpose System**

Projects can now create custom photo purposes for their specific domain:

```swift
extension PhotoPurpose {
    // Custom purpose for product photos
    static let productPhoto = PhotoPurpose(identifier: "product")
    
    // Custom purpose for medical records
    static let medicalRecord = PhotoPurpose(identifier: "medical_record")
}
```

### **Backward Compatibility Aliases**

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

This allows existing code to continue working without changes.

---

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

Add this extension to your project:

```swift
extension PhotoPurpose {
    static let vehiclePhoto = PhotoPurpose.general
    static let fuelReceipt = PhotoPurpose.document
    static let pumpDisplay = PhotoPurpose.document
    static let odometer = PhotoPurpose.document
    static let maintenance = PhotoPurpose.reference
    static let expense = PhotoPurpose.reference
}
```

---

## 🔧 Framework Updates

### **All Layers Updated**

All framework logic has been updated to handle generic purposes:

- **Layer 1**: `displayStyleForPurpose()` updated
- **Layer 2**: Layout decision functions updated
- **Layer 3**: Strategy selection functions updated
- **Layer 4**: Component logic updated
- **PlatformImageExtensions**: Size requirements updated

**Important**: Custom purposes default to `.general` behavior in framework logic, ensuring backward compatibility.

---

## 📝 Key Points for AI Agents

1. **⚠️ Breaking Change**: All code using `PhotoPurpose` must be updated
2. **Migration Required**: Use generic purposes or create aliases
3. **Extensible**: Projects can create custom purposes
4. **Backward Compatible**: Can use aliases for quick migration
5. **Framework Generic**: Framework is now truly domain-agnostic

### **When Helping with Migration**

1. **Identify PhotoPurpose Usage**: Find all places where `PhotoPurpose` is used
2. **Choose Migration Strategy**: 
   - Option 1: Update to generic purposes (`.general`, `.document`, etc.)
   - Option 2: Create aliases for backward compatibility
3. **Update Switch Statements**: Update any switch statements on `PhotoPurpose`
4. **Test Thoroughly**: Verify behavior matches expectations

---

## 🔗 Related Documentation

- [RELEASE_v7.4.0.md](RELEASE_v7.4.0.md) - Complete release notes with detailed migration guide
- [RELEASE_NOTES_v7.4.0.md](../RELEASE_NOTES_v7.4.0.md) - User-facing release notes
- Issue #151: Refactor PhotoPurpose to remove vehicle-specific domain code
- `Framework/Examples/PhotoPurposeExtensionExample.swift` - Complete migration examples

---

**For complete framework documentation, see [AI_AGENT.md](AI_AGENT.md)**
