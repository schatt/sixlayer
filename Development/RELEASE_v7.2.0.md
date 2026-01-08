# SixLayer Framework v7.2.0 Release Documentation

**Release Date**: January 8, 2026  
**Release Type**: Minor (Configurable Photo Sources for OCR Scanner)  
**Previous Release**: v7.1.0  
**Status**: ✅ **COMPLETE**

---

## 🎯 Release Summary

Minor release adding configurable photo source options to `FieldActionOCRScanner`. Developers can now choose whether to offer camera, photo library, or both options to end users, with automatic device capability detection and graceful fallbacks.

---

## 🆕 What's New

### **Configurable Photo Sources for FieldActionOCRScanner (Issue #145)**

#### **New Parameter: `allowedSources`**

Added optional `allowedSources` parameter to `FieldActionOCRScanner`:

```swift
public init(
    isPresented: Binding<Bool>,
    onResult: @escaping (String?) -> Void,
    onError: @escaping (Error) -> Void,
    hint: String?,
    validationTypes: [TextType]?,
    allowedSources: PhotoSource = .both  // NEW: Configurable source
)
```

#### **Supported Options**

- **`.camera`** - Direct camera capture only
- **`.photoLibrary`** - Photo library selection only  
- **`.both`** - Selection dialog with both options (default)

#### **Usage Examples**

**Default Behavior (Both Options):**
```swift
FieldActionOCRScanner(
    isPresented: $showScanner,
    onResult: { text in },
    onError: { error in },
    hint: "Scan document",
    validationTypes: [.general]
    // allowedSources defaults to .both
)
```

**Camera Only:**
```swift
FieldActionOCRScanner(
    isPresented: $showScanner,
    onResult: { text in },
    onError: { error in },
    hint: "Scan document",
    validationTypes: [.general],
    allowedSources: .camera
)
```

**Photo Library Only:**
```swift
FieldActionOCRScanner(
    isPresented: $showScanner,
    onResult: { text in },
    onError: { error in },
    hint: "Scan document",
    validationTypes: [.general],
    allowedSources: .photoLibrary
)
```

---

## 🔧 What's Fixed

### **Device Capability Detection**

The implementation now gracefully handles device capability edge cases:

1. **`.both` selected, but device has no camera:**
   - Automatically shows photo library picker directly (skips selection dialog)
   - Selection dialog only shows camera button if camera is available

2. **`.camera` selected, but device has no camera:**
   - Automatically falls back to photo library picker
   - Prevents errors when camera is unavailable

### **Platform-Specific Detection**

- **iOS**: Uses `UIImagePickerController.isSourceTypeAvailable(.camera)`
- **macOS**: Uses `AVCaptureDevice.DiscoverySession` to detect video devices
- Handles macOS 14.0+ deprecation of `.externalUnknown` → `.external`

---

## ✅ Backward Compatibility

**Fully backward compatible** - Default value is `.both`, maintaining existing behavior for code that doesn't specify `allowedSources`.

---

## 🧪 Testing

Added comprehensive test coverage:
- Parameter acceptance tests for all three source options
- Backward compatibility test
- Integration test with `FieldActionRenderer`
- Edge case tests documenting expected behavior for camera unavailability

---

## 📝 Files Changed

- `Framework/Sources/Components/Forms/FieldActionScanningHelpers.swift` - Main implementation
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Forms/FieldActionsTests.swift` - Test coverage

---

## 🔗 Related Components

- Uses `SystemCameraPicker` for iOS camera interface
- Uses `PlatformPhotoComponentsLayer4.platformCameraInterface_L4` for macOS camera interface
- Uses `UnifiedImagePicker` for photo library selection
- Integrates with `FieldActionRenderer` for form field actions

---

## 📚 Documentation

- Issue #145: Configurable Photo Sources for FieldActionOCRScanner
- Updated inline documentation in `FieldActionOCRScanner`
- Test documentation for edge cases

---

## 🎯 Next Steps

Future enhancements could include:
- Configurable photo sources for `FieldActionBarcodeScanner`
- Custom action sheet styling options
- Additional photo source options (e.g., document scanner)

---

**Resolves Issue #145**
