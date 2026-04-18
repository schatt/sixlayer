import Testing
import SwiftUI
@testable import SixLayerFramework

/// Comprehensive tests for Layer 4 View extension functions
/// Ensures all View extension functions in Layer 4 are tested
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Layer View Extension")
open class Layer4ViewExtensionTests: BaseTestClass {
    
    // MARK: - platformFormField Tests
    
    @Test @MainActor func testPlatformFormField_WithLabel() async {
        initializeTestConfig()
        let view = Text("Field Content")
            .platformFormField(label: "Test Label") {
                Text("Field Content")
            }
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformFormField"
        )
        #expect(hasAccessibilityID, "platformFormField with label should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformFormField_WithoutLabel() async {
        initializeTestConfig()
        let view = Text("Field Content")
            .platformFormField {
                Text("Field Content")
            }
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformFormField"
        )
        #expect(hasAccessibilityID, "platformFormField without label should generate accessibility identifiers ")
    }
    
    // MARK: - platformFormFieldGroup Tests
    
    @Test @MainActor func testPlatformFormFieldGroup_WithTitle() async {
        let view = Text("Group Content")
            .platformFormFieldGroup(title: "Test Group") {
                Text("Group Content")
            }
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformFormFieldGroup"
        )
        #expect(hasAccessibilityID, "platformFormFieldGroup with title should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformFormFieldGroup_WithoutTitle() async {
        let view = Text("Group Content")
            .platformFormFieldGroup {
                Text("Group Content")
            }
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformFormFieldGroup"
        )
        #expect(hasAccessibilityID, "platformFormFieldGroup without title should generate accessibility identifiers ")
    }
    
    // MARK: - platformValidationMessage Tests
    
    @Test @MainActor func testPlatformValidationMessage_Error() async {
        let view = Text("Test")
            .platformValidationMessage("Error message", type: .error)
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformValidationMessage"
        )
        #expect(hasAccessibilityID, "platformValidationMessage error should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformValidationMessage_AllTypes() async {
        let types: [ValidationType] = [.error, .warning, .success, .info]
        
        for type in types {
            let view = Text("Test")
                .platformValidationMessage("Message", type: type)
            
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                platform: SixLayerPlatform.iOS,
                componentName: "platformValidationMessage"
            )
            #expect(hasAccessibilityID, "platformValidationMessage \(type) should generate accessibility identifiers ")
        }
    }
    
    // MARK: - platformFormDivider Tests
    
    @Test @MainActor func testPlatformFormDivider() async {
        let view = Text("Test")
            .platformFormDivider()
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformFormDivider"
        )
        #expect(hasAccessibilityID, "platformFormDivider should generate accessibility identifiers ")
    }
    
    // MARK: - platformFormSpacing Tests
    
    @Test @MainActor func testPlatformFormSpacing_AllSizes() async {
        let sizes: [FormSpacing] = [.small, .medium, .large, .extraLarge]
        
        for size in sizes {
            let view = Text("Test")
                .platformFormSpacing(size)
            
            let hostedView = hostRootPlatformView(view)
            #expect(hostedView != nil, "platformFormSpacing \(size) should render (layout spacing uses anonymous compliance; gh-243)")
        }
    }
    
    // MARK: - platformNavigation Tests
    
    @Test @MainActor func testPlatformNavigation() async {
        let view = Text("Content")
            .platformNavigation_L4 {
                Text("Content")
            }
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformNavigation_L4 should render (no named root accessibility identifier; gh-243)")
    }
    
    // MARK: - platformNavigationContainer Tests
    
    @Test @MainActor func testPlatformNavigationContainer() async {
        let view = Text("Content")
            .platformNavigation_L4 {
                Text("Content")
            }
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformNavigation_L4 should render (no named root accessibility identifier; gh-243)")
    }
    
    // MARK: - platformNavigationDestination Tests
    
    @Test @MainActor func testPlatformNavigationDestination() async {
        struct TestItem: Identifiable, Hashable {
            let id = UUID()
        }
        
        let item = Binding<TestItem?>(get: { nil }, set: { _ in })
        let view = Text("Content")
            .platformNavigationDestination_L4(item: item) { _ in
                Text("Destination")
            }
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformNavigationDestination_L4 should render (no named root accessibility identifier; gh-243)")
    }
    
    // MARK: - platformNavigationButton Tests
    
    @Test @MainActor func testPlatformNavigationButton() async {
        var buttonPressed = false
        let view = Text("Content")
            .platformNavigationButton_L4(
                title: "Button",
                systemImage: "star",
                accessibilityLabel: "Test Button",
                accessibilityHint: "Press to test",
                action: { buttonPressed = true }
            )
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformNavigationButton"
        )
        #expect(hasAccessibilityID, "platformNavigationButton should generate accessibility identifiers ")
    }
    
    // MARK: - platformNavigationTitle Tests
    
    @Test @MainActor func testPlatformNavigationTitle() async {
        let view = Text("Content")
            .platformNavigationTitle_L4("Test Title")
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformNavigationTitle"
        )
        #expect(hasAccessibilityID, "platformNavigationTitle should generate accessibility identifiers ")
    }
    
    // MARK: - platformNavigationTitleDisplayMode Tests
    
    @Test @MainActor func testPlatformNavigationTitleDisplayMode() async {
        let modes: [PlatformTitleDisplayMode] = [.automatic, .inline, .large]
        
        for mode in modes {
            let view = Text("Content")
                .platformNavigationTitleDisplayMode_L4(mode)
            
            let hostedView = hostRootPlatformView(view)
            #expect(hostedView != nil, "platformNavigationTitleDisplayMode_L4(\(mode)) should render (gh-243)")
        }
    }
    
    // MARK: - platformNavigationBarTitleDisplayMode Tests
    
    @Test @MainActor func testPlatformNavigationBarTitleDisplayMode() async {
        let modes: [PlatformTitleDisplayMode] = [.automatic, .inline, .large]
        
        for mode in modes {
            let view = Text("Content")
                .platformNavigationBarTitleDisplayMode_L4(mode)
            
            let hostedView = hostRootPlatformView(view)
            #expect(hostedView != nil, "platformNavigationBarTitleDisplayMode_L4(\(mode)) should render (gh-243)")
        }
    }
    
    // MARK: - platformBackground Tests
    
    @Test @MainActor func testPlatformBackground_Default() async {
        initializeTestConfig()
        let view = Text("Content")
            .platformBackground()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformBackground default should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformBackground_CustomColor() async {
        initializeTestConfig()
        let view = Text("Content")
            .platformBackground(.blue)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformBackground custom color should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformBackground Missing Parameters Tests (TDD - RED Phase)
    
    @Test @MainActor func testPlatformBackgroundWithIgnoresSafeAreaEdges() async {
        initializeTestConfig()
        // Given: Background with ignoresSafeAreaEdges parameter
        // NOTE: This test will fail until ignoresSafeAreaEdges parameter is added
        let view = Text("Content")
            .platformBackground(.blue, ignoresSafeAreaEdges: .all)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformBackground with ignoresSafeAreaEdges should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformBackgroundWithViewBasedBackground() async {
        initializeTestConfig()
        // Given: View-based background
        // NOTE: This test will fail until view-based overload is added
        let view = Text("Content")
            .platformBackground(alignment: .center) {
                Color.blue
            }
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformBackground with view-based background should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformBackgroundWithViewBasedBackgroundAndAlignment() async {
        initializeTestConfig()
        // Given: View-based background with custom alignment
        let view = Text("Content")
            .platformBackground(alignment: .topLeading) {
                VStack {
                    Color.blue
                }
            }
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformBackground with view-based background and alignment should render")
    }
    
    @Test @MainActor func testPlatformBackgroundWithShapeStyle() async {
        initializeTestConfig()
        // Given: ShapeStyle-based background
        // NOTE: This test will fail until ShapeStyle overload is added
        let view = Text("Content")
            .platformBackground(.blue.gradient, ignoresSafeAreaEdges: .all)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformBackground with ShapeStyle should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformBackgroundMatchesSwiftUI() async {
        initializeTestConfig()
        // Given: Same background parameters
        let swiftUIView = Text("SwiftUI")
            .background(.blue, ignoresSafeAreaEdges: .all)
        let platformView = Text("Platform")
            .platformBackground(.blue, ignoresSafeAreaEdges: .all)
        
        // Then: Both should render successfully
        let swiftUIHosted = hostRootPlatformView(swiftUIView)
        let platformHosted = hostRootPlatformView(platformView)
        
        #expect(swiftUIHosted != nil, "SwiftUI background with ignoresSafeAreaEdges should render")
        #expect(platformHosted != nil, "platformBackground with ignoresSafeAreaEdges should match SwiftUI behavior")
    }
    
    // MARK: - platformAlert Data-Presenting Overload Tests (TDD - RED Phase)
    
    @Test @MainActor func testPlatformAlertWithDataPresenting() async {
        initializeTestConfig()
        // Given: Data-presenting alert
        struct AlertData: Identifiable {
            let id: Int
            let message: String
        }
        
        @State var alertData: AlertData? = AlertData(id: 1, message: "Test message")
        
        // When: Applying platformAlert with data-presenting overload
        // NOTE: This test will fail until data-presenting overload is added
        let view = Text("Content")
            .platformAlert(
                Text("Alert Title"),
                isPresented: .constant(true),
                presenting: alertData
            ) { data in
                Button("OK") { }
            } message: { data in
                Text(data.message)
            }
        
        // Then: View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformAlert with data-presenting should render")
    }
    
    @Test @MainActor func testPlatformAlertWithDataPresentingNoMessage() async {
        initializeTestConfig()
        // Given: Data-presenting alert without message
        struct AlertData: Identifiable {
            let id: Int
        }
        
        @State var alertData: AlertData? = AlertData(id: 1)
        
        // When: Applying platformAlert with data-presenting overload (no message)
        let view = Text("Content")
            .platformAlert(
                Text("Alert Title"),
                isPresented: .constant(true),
                presenting: alertData
            ) { data in
                Button("OK") { }
            }
        
        // Then: View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformAlert with data-presenting (no message) should render")
    }
    
    @Test @MainActor func testPlatformAlertDataPresentingNil() async {
        initializeTestConfig()
        // Given: Data-presenting alert with nil data (should not be presented)
        struct AlertData: Identifiable {
            let id: Int
        }
        
        @State var alertData: AlertData? = nil
        
        // When: Applying platformAlert with nil data
        let view = Text("Content")
            .platformAlert(
                Text("Alert Title"),
                isPresented: .constant(false),
                presenting: alertData
            ) { data in
                Button("OK") { }
            } message: { data in
                Text("Message")
            }
        
        // Then: View should still be created (binding controls presentation)
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformAlert with nil data should still create view")
    }
    
    @Test @MainActor func testPlatformAlertDataPresentingMatchesSwiftUI() async {
        initializeTestConfig()
        // Given: Same data-presenting alert
        struct AlertData: Identifiable {
            let id: Int
            let message: String
        }
        
        @State var swiftUIData: AlertData? = AlertData(id: 1, message: "SwiftUI")
        @State var platformData: AlertData? = AlertData(id: 1, message: "Platform")
        
        // When: Applying both SwiftUI and platform alerts
        let swiftUIView = Text("SwiftUI")
            .alert(
                Text("Title"),
                isPresented: .constant(true),
                presenting: swiftUIData
            ) { data in
                Button("OK") { }
            } message: { data in
                Text(data.message)
            }
        
        let platformView = Text("Platform")
            .platformAlert(
                Text("Title"),
                isPresented: .constant(true),
                presenting: platformData
            ) { data in
                Button("OK") { }
            } message: { data in
                Text(data.message)
            }
        
        // Then: Both should render successfully
        let swiftUIHosted = hostRootPlatformView(swiftUIView)
        let platformHosted = hostRootPlatformView(platformView)
        
        #expect(swiftUIHosted != nil, "SwiftUI alert with data-presenting should render")
        #expect(platformHosted != nil, "platformAlert with data-presenting should match SwiftUI behavior")
    }
    
    // MARK: - platformPadding Tests
    
    @Test @MainActor func testPlatformPadding_Default() async {
        initializeTestConfig()
        let view = Text("Content")
            .platformPadding()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformPadding default should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformPadding_Edges() async {
        initializeTestConfig()
        let view = Text("Content")
            .platformPadding(.horizontal, 16)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformPadding edges should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformPadding_Value() async {
        initializeTestConfig()
        let view = Text("Content")
            .platformPadding(20)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformPadding value should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformPadding_EdgeInsets() async {
        initializeTestConfig()
        // Given: EdgeInsets with custom padding values
        let insets = EdgeInsets(top: 10, leading: 15, bottom: 20, trailing: 25)
        
        // When: Applying platformPadding with EdgeInsets
        let view = Text("Content")
            .platformPadding(insets)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformPadding with EdgeInsets should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformPadding_EdgeInsets_MatchesSwiftUI() async {
        initializeTestConfig()
        // Given: EdgeInsets with specific values
        let insets = EdgeInsets(top: 5, leading: 10, bottom: 15, trailing: 20)
        
        // When: Applying both SwiftUI and platform padding
        let swiftUIView = Text("SwiftUI")
            .padding(insets)
        let platformView = Text("Platform")
            .platformPadding(insets)
        
        // Then: Both should render successfully
        let swiftUIHosted = hostRootPlatformView(swiftUIView)
        let platformHosted = hostRootPlatformView(platformView)
        
        #expect(swiftUIHosted != nil, "SwiftUI padding with EdgeInsets should render")
        #expect(platformHosted != nil, "platformPadding with EdgeInsets should render and match SwiftUI behavior")
    }
    
    @Test @MainActor func testPlatformReducedPadding() async {
        initializeTestConfig()
        let view = Text("Content")
            .platformReducedPadding()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformReducedPadding should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformCornerRadius Tests
    
    @Test @MainActor func testPlatformCornerRadius_Default() async {
        initializeTestConfig()
        let view = Text("Content")
            .platformCornerRadius()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformCornerRadius default should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformCornerRadius_Custom() async {
        let view = Text("Content")
            .platformCornerRadius(16)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformCornerRadius custom should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformShadow Tests
    
    @Test @MainActor func testPlatformShadow_Default() async {
        let view = Text("Content")
            .platformShadow()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformShadow default should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformShadow_Custom() async {
        let view = Text("Content")
            .platformShadow(color: .gray, radius: 8, x: 2, y: 2)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformShadow custom should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformBorder Tests
    
    @Test @MainActor func testPlatformBorder_Default() async {
        let view = Text("Content")
            .platformBorder()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformBorder default should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformBorder_Custom() async {
        let view = Text("Content")
            .platformBorder(color: .blue, width: 2)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformBorder custom should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformFont Tests
    
    @Test @MainActor func testPlatformFont_Default() async {
        let view = Text("Content")
            .platformFont()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformFont default should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformFont_Custom() async {
        let view = Text("Content")
            .platformFont(.headline)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformFont custom should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformAnimation Tests
    
    @Test @MainActor func testPlatformAnimation_Default() async {
        let view = Text("Content")
            .platformAnimation()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformAnimation default should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformAnimation_Custom() async {
        let view = Text("Content")
            .platformAnimation(.easeInOut, value: true)
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformAnimation custom should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformFrame Tests
    
    @Test @MainActor func testPlatformMinFrame() async {
        let view = Text("Content")
            .platformMinFrame()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformMinFrame should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformMaxFrame() async {
        let view = Text("Content")
            .platformMaxFrame()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformMaxFrame should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformIdealFrame() async {
        let view = Text("Content")
            .platformIdealFrame()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformIdealFrame should render (anonymous compliance; gh-243)")
    }
    
    @Test @MainActor func testPlatformAdaptiveFrame() async {
        let view = Text("Content")
            .platformAdaptiveFrame()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformAdaptiveFrame should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformFormStyle Tests
    
    @Test @MainActor func testPlatformFormStyle() async {
        let view = Text("Content")
            .platformFormStyle()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformFormStyle should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformContentSpacing Tests
    
    @Test @MainActor func testPlatformContentSpacing() async {
        let view = Text("Content")
            .platformContentSpacing()
        
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformContentSpacing should render (anonymous compliance; gh-243)")
    }
    
    // MARK: - platformPhotoPicker_L4 Tests
    
    @Test @MainActor func testPlatformPhotoPicker_L4() async {
        var imageSelected: PlatformImage?
        let view = platformPhotoPicker_L4 { image in
            imageSelected = image
        }
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformPhotoPicker_L4"
        )
        #expect(hasAccessibilityID, "platformPhotoPicker_L4 should generate accessibility identifiers ")
    }
    
    // MARK: - platformCameraInterface_L4 Tests
    
    @Test @MainActor func testPlatformCameraInterface_L4() async {
        var imageCaptured: PlatformImage?
        let view = platformCameraInterface_L4 { image in
            imageCaptured = image
        }
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformCameraInterface_L4"
        )
        #expect(hasAccessibilityID, "platformCameraInterface_L4 should generate accessibility identifiers ")
    }
    
    // MARK: - platformPhotoDisplay_L4 Tests
    
    @Test @MainActor func testPlatformPhotoDisplay_L4() async {
        let testImage = PlatformImage()
        let styles: [PhotoDisplayStyle] = [.thumbnail, .aspectFit, .fullSize, .rounded]
        
        for style in styles {
            let view = platformPhotoDisplay_L4(image: testImage, style: style)
            
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                platform: SixLayerPlatform.iOS,
                componentName: "platformPhotoDisplay_L4"
            )
            #expect(hasAccessibilityID, "platformPhotoDisplay_L4 \(style) should generate accessibility identifiers ")
        }
    }
    
    @Test @MainActor func testPlatformPhotoDisplay_L4_NilImage() async {
        let view = platformPhotoDisplay_L4(image: nil, style: .thumbnail)
        
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.*ui",
            platform: SixLayerPlatform.iOS,
            componentName: "platformPhotoDisplay_L4"
        )
        #expect(hasAccessibilityID, "platformPhotoDisplay_L4 with nil image should generate accessibility identifiers ")
    }
    
}

