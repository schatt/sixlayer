# SixLayer Framework v7.2.0 Release Notes

**Release Date**: January 8, 2026  
**Release Type**: Minor (Configurable Photo Sources for OCR Scanner)  
**Previous Version**: v7.1.0

## 🎯 Release Summary

This minor release adds configurable photo source options to `FieldActionOCRScanner`, giving developers control over whether to offer camera, photo library, or both options to end users. The implementation includes automatic device capability detection and graceful fallbacks, ensuring a smooth user experience even when camera hardware is unavailable.

## 🆕 What's New

### **Configurable Photo Sources for FieldActionOCRScanner (Issue #145)**

#### **New Parameter: `allowedSources`**

Added optional `allowedSources` parameter to `FieldActionOCRScanner` initializer:

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

#### **PhotoSource Enum**

Three options are available:

1. **`.camera`**: Direct camera capture only
   - Shows camera interface directly
   - No photo library option
   - Best for: Apps that require live capture (e.g., document scanning apps)

2. **`.photoLibrary`**: Photo library selection only
   - Shows photo library picker directly
   - No camera option
   - Best for: Apps that work with existing photos (e.g., photo editing apps)

3. **`.both`**: Selection dialog with both options (default)
   - Shows action sheet/dialog with camera and photo library options
   - User chooses which source to use
   - Best for: General-purpose apps that support both capture and selection

#### **Usage Examples**

##### **Default Behavior (Both Options)**

```swift
FieldActionOCRScanner(
    isPresented: $showScanner,
    onResult: { text in
        // Handle OCR result
    },
    onError: { error in
        // Handle error
    },
    hint: "Scan document",
    validationTypes: [.general]
    // allowedSources defaults to .both
)
```

This will show an action sheet/dialog with both camera and photo library options.

##### **Camera Only**

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

This will show the camera interface directly, skipping the selection dialog.

##### **Photo Library Only**

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

This will show the photo library picker directly, skipping the selection dialog.

## 🔧 What's Fixed

### **Device Capability Detection**

The implementation now gracefully handles device capability edge cases:

#### **Case 1: `.both` Selected, But Device Has No Camera**

**Behavior**:
- Automatically shows photo library picker directly
- Skips selection dialog (since camera option wouldn't work)
- Selection dialog only shows camera button if camera is available

**User Experience**:
- No confusing error messages
- Seamless fallback to available option
- Works correctly on devices without cameras (e.g., some iPads, macOS)

#### **Case 2: `.camera` Selected, But Device Has No Camera**

**Behavior**:
- Automatically falls back to photo library picker
- Prevents errors when camera is unavailable
- Logs warning for debugging purposes

**User Experience**:
- App doesn't crash or show error
- User can still select photos from library
- Graceful degradation

### **Platform-Specific Detection**

#### **iOS Detection**

Uses `UIImagePickerController.isSourceTypeAvailable(.camera)`:
- Checks if camera source type is available
- Standard iOS API for camera availability
- Works across all iOS devices

#### **macOS Detection**

Uses `AVCaptureDevice.DiscoverySession` to detect video devices:
- Queries available video capture devices
- Handles macOS 14.0+ deprecation of `.externalUnknown` → `.external`
- Works with both built-in and external cameras

#### **Cross-Platform Consistency**

- Same API works on both iOS and macOS
- Automatic platform-specific detection
- Consistent user experience across platforms

## ✅ Backward Compatibility

**Fully backward compatible** - Default value is `.both`, maintaining existing behavior for code that doesn't specify `allowedSources`:

```swift
// Existing code continues to work unchanged
FieldActionOCRScanner(
    isPresented: $showScanner,
    onResult: { text in },
    onError: { error in },
    hint: "Scan document",
    validationTypes: [.general]
    // allowedSources defaults to .both - same as before
)
```

## 🧪 Testing

### **New Test Coverage**

Added comprehensive test coverage:

1. **Parameter Acceptance Tests**:
   - Tests for all three source options (`.camera`, `.photoLibrary`, `.both`)
   - Verifies correct behavior for each option

2. **Backward Compatibility Test**:
   - Verifies default `.both` behavior matches previous implementation
   - Ensures existing code continues to work

3. **Integration Test**:
   - Tests integration with `FieldActionRenderer`
   - Verifies end-to-end functionality

4. **Edge Case Tests**:
   - Documents expected behavior for camera unavailability
   - Tests fallback mechanisms
   - Verifies graceful degradation

## 📝 Files Changed

- `Framework/Sources/Components/Forms/FieldActionScanningHelpers.swift` - Main implementation
  - Added `PhotoSource` enum
  - Added `allowedSources` parameter to `FieldActionOCRScanner`
  - Implemented device capability detection
  - Added graceful fallback logic

- `Development/Tests/SixLayerFrameworkUnitTests/Features/Forms/FieldActionsTests.swift` - Test coverage
  - Added tests for all source options
  - Added backward compatibility tests
  - Added integration tests
  - Added edge case tests

## 🔗 Related Components

- **`SystemCameraPicker`**: Used for iOS camera interface
- **`PlatformPhotoComponentsLayer4.platformCameraInterface_L4`**: Used for macOS camera interface
- **`UnifiedImagePicker`**: Used for photo library selection
- **`FieldActionRenderer`**: Integrates with form field actions

## 📚 Documentation

- **Issue #145**: Configurable Photo Sources for FieldActionOCRScanner - ✅ Complete
- Updated inline documentation in `FieldActionOCRScanner`
- Test documentation for edge cases

## 🎯 Next Steps

Future enhancements could include:
- Configurable photo sources for `FieldActionBarcodeScanner`
- Custom action sheet styling options
- Additional photo source options (e.g., document scanner)
- Enhanced device capability detection for other platforms

## 🔄 Migration Guide

### **No Migration Required**

This is a non-breaking addition. Existing code continues to work unchanged.

### **Optional: Specify Photo Source**

If you want to restrict photo sources:

```swift
// Camera only
FieldActionOCRScanner(
    isPresented: $showScanner,
    onResult: { text in },
    onError: { error in },
    hint: "Scan document",
    validationTypes: [.general],
    allowedSources: .camera
)

// Photo library only
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

**Version**: 7.2.0  
**Release Date**: January 8, 2026  
**Previous Version**: v7.1.0  
**Status**: Production Ready 🚀
