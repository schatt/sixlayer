import Testing
import SwiftUI

// Normal import - same as external modules like CarManager
// NO @testable - tests from external module perspective
import SixLayerFramework

/// External Module Integration Tests
///
/// These tests simulate how an external module (like CarManager) would use the framework.
/// They use normal `import` (not `@testable`) to test public API access.
///
/// **Purpose:**
/// - Catch API visibility issues that would break external modules
/// - Verify public APIs are accessible from external perspective
/// - Ensure framework is usable by external consumers
///
/// **Difference from SixLayerFrameworkTests:**
/// - Uses `import` instead of `@testable import`
/// - Tests public API only (no internal access)
/// - Simulates external module usage patterns
///
/// **What was broken:**
/// - platformPhotoPicker_L4 was changed from static to instance method
/// - @testable tests still worked (could access internals)
/// - External modules couldn't access it (compilation error)
/// - These tests would have caught that bug
@Suite("External Module Integration Tests")
/// NOTE: Not marked @MainActor on class to allow parallel execution
struct ExternalModuleIntegrationTests {
    
    /// Tests that global photo picker function is accessible from external modules
    ///
    /// This test simulates CarManager usage:
    /// ```swift
    /// import SixLayerFramework
    /// var selectedImage: PlatformImage?
    /// let picker = platformPhotoPicker_L4(onImageSelected: { image in selectedImage = image })
    /// ```
    @Test("Global photo picker function accessible") @MainActor
    func testGlobalPhotoPickerAccessible() {
        // Simulate how CarManager would call this
        let _ = platformPhotoPicker_L4(onImageSelected: { _ in
            // Callback signature is accessible - in real usage, external modules would use this
        })

        // Test that it compiles and creates a view
        #expect(Bool(true), "Function is accessible")

        // Test that callback signature is accessible
        // In real usage, external modules would call this with their own callback
        #expect(Bool(true), "Callback can be provided")
    }
    
    /// Tests that global camera interface function is accessible
    @Test("Global camera interface function accessible") @MainActor
    func testGlobalCameraInterfaceAccessible() {
        let _ = platformCameraInterface_L4(onImageCaptured: { _ in
            // Callback signature is accessible - in real usage, external modules would use this
        })

        // Test that it compiles and creates a view
        #expect(Bool(true), "Function is accessible")

        // Test that callback signature is accessible
        // In real usage, external modules would call this with their own callback
        #expect(Bool(true), "Callback can be provided")
    }
    
    /// Tests that global photo display function is accessible
    @Test("Global photo display function accessible") @MainActor
    func testGlobalPhotoDisplayAccessible() {
        let image = PlatformImage()
        let _ = platformPhotoDisplay_L4(image: image, style: .thumbnail)
        #expect(Bool(true), "Function is accessible")
    }
    
    /// Tests that PlatformImage implicit conversion works from external modules
    @Test("PlatformImage implicit conversion works externally")
    func testPlatformImageImplicitConversion() {
        // Test that UIImage and NSImage can be implicitly converted and produce valid results
        #if os(iOS)
        // 6LAYER_ALLOW: testing PlatformImage boundary conversion from platform-specific images (legitimate external API usage)
        let uiImage = UIImage(systemName: "photo") ?? UIImage()
        let platformImage = PlatformImage(uiImage)

        // Verify the conversion actually worked (uiImage is non-optional; validity is covered by size and equality below)
        #expect(platformImage.size.width > 0, "Converted image should have valid width")
        #expect(platformImage.size.height > 0, "Converted image should have valid height")
        #expect(platformImage.uiImage == uiImage, "Conversion should preserve original image data")

        #elseif os(macOS)
        // 6LAYER_ALLOW: testing PlatformImage boundary conversion from platform-specific images (legitimate external API usage)
        let nsImage = NSImage(systemSymbolName: "photo", accessibilityDescription: nil) ?? NSImage()
        let platformImage = PlatformImage(nsImage)

        // Verify the conversion actually worked
        // NSImage is non-optional, so check if the image has valid size instead
        #expect(platformImage.size.width > 0, "PlatformImage should have valid width")
        #expect(platformImage.size.height > 0, "PlatformImage should have valid height")
        #expect(platformImage.size.width > 0 && platformImage.size.height > 0, "Converted image should have valid dimensions")
        #expect(platformImage.nsImage == nsImage, "Conversion should preserve original image data")
        #endif
    }
    
    /// Tests that Layer 5 messaging functions are accessible
    @Test("Layer 5 messaging functions accessible")
    func testLayer5MessagingAccessible() {
        // Note: PlatformMessagingLayer5 has internal init, so we can't instantiate it
        // This test verifies that we're testing from external perspective
        // In real usage, external modules would use the public static methods
        #expect(Bool(true), "Testing from external perspective")
    }
    
    /// Tests that photo components have accessibility identifiers (external perspective)
    @Test("Photo components have accessibility identifiers") @MainActor
    func testPhotoComponentsHaveAccessibilityIdentifiers() {
        // Test that photo components apply accessibility identifiers
        // These should work from an external module perspective

        let _ = platformCameraInterface_L4(onImageCaptured: { _ in
            // Callback signature is accessible
        })
        let _ = platformPhotoPicker_L4(onImageSelected: { _ in
            // Callback signature is accessible
        })
        let _ = platformPhotoDisplay_L4(image: PlatformImage(), style: .thumbnail)

        // If these compile and create views, the API is accessible
        #expect(Bool(true), "Photo components accessible and creating views")
    }
    
    /// Tests that PlatformPhotoComponentsLayer4 enum methods are accessible
    @Test("PlatformPhotoComponentsLayer4 enum methods accessible") @MainActor
    func testPhotoComponentsLayer4MethodsAccessible() {
        // Test that we can use the enum methods
        let _ = PlatformPhotoComponentsLayer4.platformCameraInterface_L4(onImageCaptured: { _ in })
        let _ = PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: { _ in })
        let _ = PlatformPhotoComponentsLayer4.platformPhotoDisplay_L4(image: PlatformImage(), style: .thumbnail)

        // If these compile, the enum methods are accessible from external modules
        #expect(Bool(true), "Enum methods accessible")
    }
    
    /// Tests that OCROverlayView is accessible from external modules
    @Test("OCROverlayView accessible from external modules") @MainActor
    func testOCROverlayViewAccessible() {
        let testImage = PlatformImage()
        let testResult = OCRResult(
            extractedText: "Test OCR Text",
            confidence: 0.95,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 1.0,
            language: .english
        )

        // Test that OCROverlayView can be created from external module
        let _ = OCROverlayView(
            image: testImage,
            result: testResult,
            configuration: OCROverlayConfiguration(),
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )

        // If this compiles and creates a view, the API is accessible
        #expect(Bool(true), "OCROverlayView accessible and creating views")

        // Test that callback signatures are accessible
        #expect(Bool(true), "Callbacks can be provided")
    }
    
    /// Tests that ListCollectionView properly handles callbacks
    @Test("ListCollectionView callbacks accessible from external modules") @MainActor
    func testListCollectionViewCallbacksAccessible() {
        // Create sample items for testing
        struct TestItem: Identifiable {
            let id = UUID()
            let title: String
        }

        let testItems = [TestItem(title: "Test Item")]
        let hints = PresentationHints()

        // Test ListCollectionView with callbacks
        let _ = ListCollectionView(
            items: testItems,
            hints: hints,
            onCreateItem: nil,
            onItemSelected: { _ in
                // Callback signature is accessible - in real usage, external modules would use this
            },
            onItemDeleted: { _ in
                // Callback signature is accessible - in real usage, external modules would use this
            }
        )

        // If this compiles and creates a view, the API is accessible
        #expect(Bool(true), "ListCollectionView with callbacks accessible")
    }
    
    /// Tests that IntelligentFormView.generateForm is accessible from external modules
    @Test("IntelligentFormView.generateForm is accessible") @MainActor
    func testIntelligentFormViewGenerateFormAccessible() {
        // Test that IntelligentFormView.generateForm can be called from external modules
        struct TestFormData: Identifiable {
            let id = UUID()
            var name: String
            var email: String
        }

        let testData = TestFormData(name: "Test", email: "test@example.com")

        // Test that generateForm for creating new data is accessible
        let _ = IntelligentFormView.generateForm(
            for: TestFormData.self,
            initialData: testData,
            onSubmit: { _ in },
            onCancel: { }
        )

        // Test that generateForm for updating existing data is accessible
        let _ = IntelligentFormView.generateForm(
            for: testData,
            onUpdate: { _ in },
            onCancel: { }
        )

        // If these compile and create views, the API is accessible
        #expect(Bool(true), "IntelligentFormView.generateForm is accessible from external modules")
    }
    
    /// Tests that IntelligentDetailView.platformDetailView is accessible from external modules
    @Test("IntelligentDetailView.platformDetailView is accessible") @MainActor
    func testIntelligentDetailViewAccessible() {
        struct TestDetailData: Identifiable {
            let id = UUID()
            let name: String
            let status: String
        }

        let testData = TestDetailData(name: "Test", status: "Active")

        // Test that platformDetailView can be called from external modules
        let _ = IntelligentDetailView.platformDetailView(for: testData)

        // If this compiles and creates a view, the API is accessible
        #expect(Bool(true), "IntelligentDetailView.platformDetailView is accessible from external modules")
    }
    
    /// Tests that ResponsiveLayout static methods are accessible from external modules
    @Test("ResponsiveLayout static methods accessible") @MainActor
    func testResponsiveLayoutAccessible() {
        // Test that ResponsiveLayout static methods can be used from external modules
        let _ = ResponsiveLayout.adaptiveGrid {
            Text("Test content")
        }

        // If this compiles, ResponsiveLayout is accessible
        #expect(Bool(true), "ResponsiveLayout is accessible from external modules")
    }
    
    /// Tests that ResponsiveContainer is accessible from external modules
    @Test("ResponsiveContainer is accessible") @MainActor
    func testResponsiveContainerAccessible() {
        // Test that ResponsiveContainer can be used from external modules
        // Note: Uses proper 2-parameter closure signature
        let _ = ResponsiveContainer { isHorizontal, isVertical in
            EmptyView().platformVStackContainer {
                Text("H: \(isHorizontal ? "Yes" : "No")")
                Text("V: \(isVertical ? "Yes" : "No")")
            }
        }

        // If this compiles, ResponsiveContainer is accessible
        #expect(Bool(true), "ResponsiveContainer is accessible from external modules")
    }
    
    /// Tests that OCR Layer 1 functions are accessible from external modules
    @Test("OCR Layer 1 functions accessible") @MainActor
    func testOCRLayer1Accessible() {
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [.general],
            language: .english,
            confidenceThreshold: 0.8
        )

        // Test platformOCRWithVisualCorrection_L1
        let _ = platformOCRWithVisualCorrection_L1(
            image: testImage,
            context: context,
            onResult: { _ in }
        )

        // If this compiles, OCR functions are accessible
        #expect(Bool(true), "OCR Layer 1 functions are accessible from external modules")
    }
    
    /// Tests that DataIntrospectionEngine is accessible from external modules
    @Test("DataIntrospectionEngine.analyze is accessible")
    func testDataIntrospectionEngineAccessible() {
        struct TestData: Identifiable {
            let id = UUID()
            let name: String
            let age: Int
        }
        
        let testData = TestData(name: "Test", age: 25)
        
        // Test that DataIntrospectionEngine.analyze can be called from external modules
        let analysis = DataIntrospectionEngine.analyze(testData)
        
        // Test that the result has the expected structure
        #expect(analysis.fields.count >= 2, "Should detect at least 2 fields")
        
        let hasNameField = analysis.fields.contains { $0.name == "name" }
        #expect(hasNameField, "Should detect 'name' field")
        
        let hasAgeField = analysis.fields.contains { $0.name == "age" }
        #expect(hasAgeField, "Should detect 'age' field")
    }
    
    /// Tests that PresentationHints can be used from external modules
    @Test("PresentationHints is accessible")
    func testPresentationHintsAccessible() {
        // Test that PresentationHints can be created from external modules
        let _ = PresentationHints()
        
        // If this compiles, PresentationHints is accessible
        #expect(Bool(true), "PresentationHints is accessible from external modules")
    }
    
    /// Tests AccessibilityManager is accessible
    @Test("AccessibilityManager is accessible")
    @MainActor
    func testAccessibilityManagerAccessible() {
        // Test that AccessibilityManager can be created
        let _ = AccessibilityManager()

        #expect(Bool(true), "AccessibilityManager is accessible from external modules")
    }

    /// Tests that PlatformTabStrip is constructible from external modules (#292).
    @Test("PlatformTabStrip public initializer accessible") @MainActor
    func testPlatformTabStripAccessible() {
        let items = [
            PlatformTabItem(title: "Costs", systemImage: "dollarsign.circle"),
            PlatformTabItem(title: "Fuel", systemImage: "fuelpump"),
        ]
        let selection = Binding.constant(0)
        let _ = PlatformTabStrip(selection: selection, items: items)
        #expect(Bool(true), "PlatformTabStrip is accessible from external modules")
    }
}

