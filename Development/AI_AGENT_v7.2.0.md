# AI Agent Guide - SixLayer Framework v7.2.0

**Version**: v7.2.0  
**Release Date**: January 8, 2026  
**Release Type**: Minor (Configurable Photo Sources for OCR Scanner)

---

## 🎯 What's New in v7.2.0

### **Configurable Photo Sources for FieldActionOCRScanner (Issue #145)**

The `FieldActionOCRScanner` now supports configurable photo sources, allowing developers to choose whether to offer camera, photo library, or both options to end users.

#### **New Parameter: `allowedSources`**

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

## 🔧 Edge Case Handling

The implementation gracefully handles device capability edge cases:

### **`.both` Selected, But Device Has No Camera**

- Automatically shows photo library picker directly (skips selection dialog)
- Selection dialog only shows camera button if camera is available

### **`.camera` Selected, But Device Has No Camera**

- Automatically falls back to photo library picker
- Prevents errors when camera is unavailable

### **Device Capability Detection**

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

## 📚 Previous Versions

- **[AI_AGENT_v7.1.0.md](AI_AGENT_v7.1.0.md)** - Color Resolution System from Hints Files
- **[AI_AGENT_v7.0.2.md](AI_AGENT_v7.0.2.md)** - Hints File Presentation Properties Support
- **[AI_AGENT_v7.0.1.md](AI_AGENT_v7.0.1.md)** - Hints File Color Configuration Support
- **[AI_AGENT_v7.0.0.md](AI_AGENT_v7.0.0.md)** - Breaking Changes - Card Color Configuration

---

**Resolves Issue #145**
