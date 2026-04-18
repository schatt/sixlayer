# Platform Print Layer 4 Guide

## Overview

The Platform Print Layer 4 provides a unified cross-platform printing API that works identically on both iOS and macOS. This eliminates the need for platform-specific printing code while maintaining native performance and user experience.

**Implements**: [Issue #43](https://github.com/schatt/6layer/issues/43) - Cross-Platform Printing Solution

## Cross-Platform Behavior

### iOS Implementation
- Uses `UIPrintInteractionController` presented as a modal sheet
- Shows print options and preview
- Supports AirPrint printers
- Can save as PDF
- Provides haptic feedback on completion

### macOS Implementation
- Uses `NSPrintOperation` with standard print dialog
- Shows macOS print panel
- Supports all macOS print services
- Can save as PDF
- Provides visual confirmation

## API Reference

### View Modifier

```swift
func platformPrint_L4(
    isPresented: Binding<Bool>,
    content: PrintContent,
    options: PrintOptions? = nil,
    onComplete: ((Bool) -> Void)? = nil
) -> some View
```

**Parameters:**
- `isPresented`: Binding to control print dialog presentation
- `content`: Content to print (text, image, PDF, or view)
- `options`: Optional print configuration options
- `onComplete`: Optional callback when printing completes (receives success status)

**Returns:** View with print modifier applied

### Direct Print Function

```swift
@MainActor
@discardableResult
func platformPrint_L4(
    content: PrintContent,
    options: PrintOptions? = nil
) -> Bool
```

**Parameters:**
- `content`: Content to print
- `options`: Optional print configuration options

**Returns:** Success status (true if print dialog was shown, false otherwise)

## Print Content Types

### Text Content

```swift
let textContent = PrintContent.text("Document content here")
```

### Image Content

```swift
let imageContent = PrintContent.image(platformImage)
```

### PDF Content

```swift
let pdfData = // ... PDF data
let pdfContent = PrintContent.pdf(pdfData)
```

### View Content

```swift
let viewContent = PrintContent.view(AnyView(MySwiftUIView()))
```

## Print Options

```swift
#if os(iOS)
let options = PrintOptions(
    jobName: "My Document",
    showsNumberOfCopies: true,
    showsPageRange: true,
    numberOfCopies: 1,
    pageRange: nil,
    outputType: .photo  // iOS only: .general, .photo, or .grayscale
)
#else
let options = PrintOptions(
    jobName: "My Document",
    showsNumberOfCopies: true,
    showsPageRange: true,
    numberOfCopies: 1,
    pageRange: nil
)
#endif
```

**Properties:**
- `jobName`: Optional name for the print job
- `showsNumberOfCopies`: Whether to show number of copies option (default: true)
- `showsPageRange`: Whether to show page range option (default: true)
- `numberOfCopies`: Number of copies (default: 1)
- `pageRange`: Optional page range (nil = all pages)
- `outputType`: iOS only - Print quality (.general, .photo, .grayscale). Defaults to .photo for images, .general for other content

## Usage Examples

### Basic Text Printing

```swift
struct ContentView: View {
    @State private var showPrintDialog = false
    
    var body: some View {
        Button("Print Document") {
            showPrintDialog = true
        }
        .platformPrint_L4(
            isPresented: $showPrintDialog,
            content: .text("This is the document content to print")
        )
    }
}
```

### Printing with Options

```swift
struct ContentView: View {
    @State private var showPrintDialog = false
    
    var body: some View {
        Button("Print with Options") {
            showPrintDialog = true
        }
        .platformPrint_L4(
            isPresented: $showPrintDialog,
            content: .text("Document content"),
            options: PrintOptions(
                jobName: "My Report",
                showsNumberOfCopies: true,
                numberOfCopies: 2
            ),
            onComplete: { success in
                if success {
                    print("Print completed successfully")
                } else {
                    print("Print was cancelled or failed")
                }
            }
        )
    }
}
```

### Printing Images

```swift
struct ContentView: View {
    @State private var showPrintDialog = false
    let image: PlatformImage
    
    var body: some View {
        Button("Print Image") {
            showPrintDialog = true
        }
        .platformPrint_L4(
            isPresented: $showPrintDialog,
            content: .image(image)
        )
    }
}
```

### Printing Insurance Cards (Photo Quality)

```swift
struct InsuranceCardView: View {
    @State private var showPrintDialog = false
    let insuranceCardImage: PlatformImage
    
    var body: some View {
        Button("Print Insurance Card") {
            showPrintDialog = true
        }
        .platformPrint_L4(
            isPresented: $showPrintDialog,
            content: .image(insuranceCardImage),
            options: PrintOptions(
                jobName: "Insurance Card",
                outputType: .photo  // Photo-quality printing
            ),
            onComplete: { success in
                if success {
                    print("Insurance card printed successfully")
                }
            }
        )
    }
}
```

### Printing PDFs

```swift
struct ContentView: View {
    @State private var showPrintDialog = false
    let pdfData: Data
    
    var body: some View {
        Button("Print PDF") {
            showPrintDialog = true
        }
        .platformPrint_L4(
            isPresented: $showPrintDialog,
            content: .pdf(pdfData)
        )
    }
}
```

### Printing SwiftUI Views

```swift
struct ContentView: View {
    @State private var showPrintDialog = false
    
    var body: some View {
        Button("Print View") {
            showPrintDialog = true
        }
        .platformPrint_L4(
            isPresented: $showPrintDialog,
            content: .view(AnyView(
                VStack {
                    Text("Header")
                        .font(.title)
                    Text("Body content")
                }
            ))
        )
    }
}
```

### Direct Print Function

```swift
struct ContentView: View {
    var body: some View {
        Button("Print Directly") {
            let success = platformPrint_L4(
                content: .text("Direct print content")
            )
            if success {
                print("Print dialog shown")
            }
        }
    }
}
```

## Platform-Specific Notes

### iOS
- Print dialog appears as a modal sheet
- Supports AirPrint printers automatically
- Can save to Files app as PDF
- Provides haptic feedback on completion
- **Photo-quality printing**: Use `outputType: .photo` for images (e.g., insurance cards, photos)
- **Error handling**: Gracefully handles cases when no printer is available
- **Automatic quality selection**: Images default to `.photo` output type, other content uses `.general`

### macOS
- Print dialog appears as standard macOS print panel
- Supports all configured print services
- Can save as PDF via print dialog
- Job name and options are handled by the print dialog UI
- **Error handling**: Gracefully handles cases when no printer is available

## Accessibility

The print modifier chains `.automaticCompliance()` (anonymous) so HIG-related accessibility behavior applies without stamping a fixed named root `accessibilityIdentifier` on arbitrary print content (see gh-243).

## Error Handling

The print functions return `Bool` to indicate success:
- `true`: Print dialog was shown successfully
- `false`: Print dialog could not be shown (e.g., no content, no printer available, system error)

The `onComplete` callback provides more detailed feedback:
- `true`: User completed printing
- `false`: User cancelled or an error occurred

**Common Error Scenarios:**
- No printer available: Function returns `false`, callback receives `false`
- Invalid content type: Function returns `false`, callback receives `false`
- User cancellation: Function returns `true` (dialog shown), callback receives `false`
- System error: Function returns `true` (dialog shown), callback receives `false` with error logged

## Testing

The implementation includes comprehensive TDD tests in `PlatformPrintLayer4Tests.swift` covering:
- API consistency across platforms
- All content types (text, image, PDF, view)
- Platform-specific implementations
- Print options configuration
- Callback execution
- Accessibility compliance
- Error handling

## Related Documentation

- [Layer 4 Component Architecture](six-layer-architecture-current-status.md)
- [Layer 4 Implementation Guide](README_Layer4_Implementation.md#system-actions) - System Actions (URL opening and sharing)
- [Cross-Platform Patterns](README_UsageExamples.md)

## Implementation Details

### File Structure
- `Framework/Sources/Layers/Layer4-Component/PlatformPrintLayer4.swift` - Main implementation
- `Development/Tests/SixLayerFrameworkUnitTests/Features/Platform/PlatformPrintLayer4Tests.swift` - Test suite

### Dependencies
- Uses existing `PlatformImage` types
- Integrates with framework's accessibility system
- Follows existing cross-platform patterns from Layer 4

## Best Practices

1. **Use View Modifier for UI Integration**: Prefer the view modifier when integrating with SwiftUI views
2. **Use Direct Function for Programmatic Printing**: Use the direct function when printing from non-UI code
3. **Handle Completion Callbacks**: Always check the completion callback to provide user feedback
4. **Provide Meaningful Job Names**: Set `jobName` in options for better user experience
5. **Test on Both Platforms**: Verify printing behavior on both iOS and macOS

## Limitations

- SwiftUI view rendering requires iOS 16+ / macOS 13+ for optimal results
- Fallback implementations are provided for older OS versions
- Print options (copies, page range) are handled by the system print dialog UI
- Some advanced print settings may be platform-specific

## Future Enhancements

Potential future improvements:
- Custom print formatters
- Print preview customization
- Batch printing support
- Print queue management
- Advanced print settings API

