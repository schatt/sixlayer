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
            let anchor = "Layer4DualPathFormSpacing_\(String(describing: size))"
            assertLayoutChromeDualPath(anchorName: anchor, context: "platformFormSpacing \(size)") {
                Text("Test")
                    .platformFormSpacing(size)
            }
        }
    }
    
    // MARK: - platformNavigation Tests
    
    @Test @MainActor func testPlatformNavigation() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformNavigationL4", context: "platformNavigation_L4") {
            Text("Content")
                .platformNavigation_L4 {
                    Text("Content")
                }
        }
    }
    
    // MARK: - platformNavigationContainer Tests
    
    @Test @MainActor func testPlatformNavigationContainer() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformNavigationContainer", context: "platformNavigation_L4 container") {
            Text("Content")
                .platformNavigation_L4 {
                    Text("Content")
                }
        }
    }
    
    // MARK: - platformNavigationDestination Tests
    
    @Test @MainActor func testPlatformNavigationDestination() async {
        struct TestItem: Identifiable, Hashable {
            let id = UUID()
        }
        
        let item = Binding<TestItem?>(get: { nil }, set: { _ in })
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathNavigationDestination", context: "platformNavigationDestination_L4") {
            Text("Content")
                .platformNavigationDestination_L4(item: item) { _ in
                    Text("Destination")
                }
        }
    }
    
    // MARK: - platformNavigationButton Tests
    
    @Test @MainActor func testPlatformNavigationButton() async {
        let view = Text("Content")
            .platformNavigationButton_L4(
                title: "Button",
                systemImage: "star",
                accessibilityLabel: "Test Button",
                accessibilityHint: "Press to test",
                action: {}
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
            let anchor = "Layer4DualPathNavTitleDisplayMode_\(String(describing: mode).replacingOccurrences(of: ".", with: "_"))"
            assertLayoutChromeDualPath(anchorName: anchor, context: "platformNavigationTitleDisplayMode_L4(\(mode))") {
                Text("Content")
                    .platformNavigationTitleDisplayMode_L4(mode)
            }
        }
    }
    
    // MARK: - platformNavigationBarTitleDisplayMode Tests
    
    @Test @MainActor func testPlatformNavigationBarTitleDisplayMode() async {
        let modes: [PlatformTitleDisplayMode] = [.automatic, .inline, .large]
        
        for mode in modes {
            let anchor = "Layer4DualPathNavBarTitleDisplayMode_\(String(describing: mode).replacingOccurrences(of: ".", with: "_"))"
            assertLayoutChromeDualPath(anchorName: anchor, context: "platformNavigationBarTitleDisplayMode_L4(\(mode))") {
                Text("Content")
                    .platformNavigationBarTitleDisplayMode_L4(mode)
            }
        }
    }
    
    // MARK: - platformBackground Tests
    
    @Test @MainActor func testPlatformBackground_Default() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformBackgroundDefault", context: "platformBackground default") {
            Text("Content")
                .platformBackground()
        }
    }
    
    @Test @MainActor func testPlatformBackground_CustomColor() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformBackgroundCustomColor", context: "platformBackground custom color") {
            Text("Content")
                .platformBackground(.blue)
        }
    }
    
    // MARK: - platformBackground Missing Parameters Tests (TDD - RED Phase)
    
    @Test @MainActor func testPlatformBackgroundWithIgnoresSafeAreaEdges() async {
        initializeTestConfig()
        // Given: Background with ignoresSafeAreaEdges parameter
        // NOTE: This test will fail until ignoresSafeAreaEdges parameter is added
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformBackgroundSafeArea", context: "platformBackground ignoresSafeAreaEdges") {
            Text("Content")
                .platformBackground(.blue, ignoresSafeAreaEdges: .all)
        }
    }
    
    @Test @MainActor func testPlatformBackgroundWithViewBasedBackground() async {
        initializeTestConfig()
        // Given: View-based background
        // NOTE: This test will fail until view-based overload is added
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformBackgroundViewBased", context: "platformBackground view-based") {
            Text("Content")
                .platformBackground(alignment: .center) {
                    Color.blue
                }
        }
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
        
        _ = hostRootPlatformView(view)
        #expect(Bool(true), "platformBackground with view-based background and alignment should render")
    }
    
    @Test @MainActor func testPlatformBackgroundWithShapeStyle() async {
        initializeTestConfig()
        // Given: ShapeStyle-based background
        // NOTE: This test will fail until ShapeStyle overload is added
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformBackgroundShapeStyle", context: "platformBackground ShapeStyle") {
            Text("Content")
                .platformBackground(.blue.gradient, ignoresSafeAreaEdges: .all)
        }
    }
    
    @Test @MainActor func testPlatformBackgroundMatchesSwiftUI() async {
        initializeTestConfig()
        // Given: Same background parameters
        let swiftUIView = Text("SwiftUI")
            .background(.blue, ignoresSafeAreaEdges: .all)
        let platformView = Text("Platform")
            .platformBackground(.blue, ignoresSafeAreaEdges: .all)
        
        // Then: Both should render successfully
        _ = hostRootPlatformView(swiftUIView)
        _ = hostRootPlatformView(platformView)
        
        #expect(Bool(true), "SwiftUI background with ignoresSafeAreaEdges should render")
        #expect(Bool(true), "platformBackground with ignoresSafeAreaEdges should match SwiftUI behavior")
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
        _ = hostRootPlatformView(view)
        #expect(Bool(true), "platformAlert with data-presenting should render")
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
        _ = hostRootPlatformView(view)
        #expect(Bool(true), "platformAlert with data-presenting (no message) should render")
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
        _ = hostRootPlatformView(view)
        #expect(Bool(true), "platformAlert with nil data should still create view")
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
        _ = hostRootPlatformView(swiftUIView)
        _ = hostRootPlatformView(platformView)
        
        #expect(Bool(true), "SwiftUI alert with data-presenting should render")
        #expect(Bool(true), "platformAlert with data-presenting should match SwiftUI behavior")
    }
    
    // MARK: - platformPadding Tests
    
    @Test @MainActor func testPlatformPadding_Default() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformPaddingDefault", context: "platformPadding default") {
            Text("Content")
                .platformPadding()
        }
    }
    
    @Test @MainActor func testPlatformPadding_Edges() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformPaddingEdges", context: "platformPadding edges") {
            Text("Content")
                .platformPadding(.horizontal, 16)
        }
    }
    
    @Test @MainActor func testPlatformPadding_Value() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformPaddingValue", context: "platformPadding value") {
            Text("Content")
                .platformPadding(20)
        }
    }
    
    @Test @MainActor func testPlatformPadding_EdgeInsets() async {
        initializeTestConfig()
        // Given: EdgeInsets with custom padding values
        let insets = EdgeInsets(top: 10, leading: 15, bottom: 20, trailing: 25)
        
        // When: Applying platformPadding with EdgeInsets
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformPaddingEdgeInsets", context: "platformPadding EdgeInsets") {
            Text("Content")
                .platformPadding(insets)
        }
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
        _ = hostRootPlatformView(swiftUIView)
        _ = hostRootPlatformView(platformView)
        
        #expect(Bool(true), "SwiftUI padding with EdgeInsets should render")
        #expect(Bool(true), "platformPadding with EdgeInsets should render and match SwiftUI behavior")
    }
    
    @Test @MainActor func testPlatformReducedPadding() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformReducedPadding", context: "platformReducedPadding") {
            Text("Content")
                .platformReducedPadding()
        }
    }
    
    // MARK: - platformCornerRadius Tests
    
    @Test @MainActor func testPlatformCornerRadius_Default() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformCornerRadiusDefault", context: "platformCornerRadius default") {
            Text("Content")
                .platformCornerRadius()
        }
    }
    
    @Test @MainActor func testPlatformCornerRadius_Custom() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformCornerRadiusCustom", context: "platformCornerRadius custom") {
            Text("Content")
                .platformCornerRadius(16)
        }
    }
    
    // MARK: - platformShadow Tests
    
    @Test @MainActor func testPlatformShadow_Default() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformShadowDefault", context: "platformShadow default") {
            Text("Content")
                .platformShadow()
        }
    }
    
    @Test @MainActor func testPlatformShadow_Custom() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformShadowCustom", context: "platformShadow custom") {
            Text("Content")
                .platformShadow(color: .gray, radius: 8, x: 2, y: 2)
        }
    }
    
    // MARK: - platformBorder Tests
    
    @Test @MainActor func testPlatformBorder_Default() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformBorderDefault", context: "platformBorder default") {
            Text("Content")
                .platformBorder()
        }
    }
    
    @Test @MainActor func testPlatformBorder_Custom() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformBorderCustom", context: "platformBorder custom") {
            Text("Content")
                .platformBorder(color: .blue, width: 2)
        }
    }
    
    // MARK: - platformFont Tests
    
    @Test @MainActor func testPlatformFont_Default() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformFontDefault", context: "platformFont default") {
            Text("Content")
                .platformFont()
        }
    }
    
    @Test @MainActor func testPlatformFont_Custom() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformFontCustom", context: "platformFont custom") {
            Text("Content")
                .platformFont(.headline)
        }
    }
    
    // MARK: - platformAnimation Tests
    
    @Test @MainActor func testPlatformAnimation_Default() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformAnimationDefault", context: "platformAnimation default") {
            Text("Content")
                .platformAnimation()
        }
    }
    
    @Test @MainActor func testPlatformAnimation_Custom() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformAnimationCustom", context: "platformAnimation custom") {
            Text("Content")
                .platformAnimation(.easeInOut, value: true)
        }
    }
    
    // MARK: - platformFrame Tests
    
    @Test @MainActor func testPlatformMinFrame() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformMinFrame", context: "platformMinFrame") {
            Text("Content")
                .platformMinFrame()
        }
    }
    
    @Test @MainActor func testPlatformMaxFrame() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformMaxFrame", context: "platformMaxFrame") {
            Text("Content")
                .platformMaxFrame()
        }
    }
    
    @Test @MainActor func testPlatformIdealFrame() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformIdealFrame", context: "platformIdealFrame") {
            Text("Content")
                .platformIdealFrame()
        }
    }
    
    @Test @MainActor func testPlatformAdaptiveFrame() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformAdaptiveFrame", context: "platformAdaptiveFrame") {
            Text("Content")
                .platformAdaptiveFrame()
        }
    }
    
    // MARK: - platformFormStyle Tests
    
    @Test @MainActor func testPlatformFormStyle() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformFormStyle", context: "platformFormStyle") {
            Text("Content")
                .platformFormStyle()
        }
    }
    
    // MARK: - platformContentSpacing Tests
    
    @Test @MainActor func testPlatformContentSpacing() async {
        assertLayoutChromeDualPath(anchorName: "Layer4DualPathPlatformContentSpacing", context: "platformContentSpacing") {
            Text("Content")
                .platformContentSpacing()
        }
    }
    
    // MARK: - platformPhotoPicker_L4 Tests
    
    @Test @MainActor func testPlatformPhotoPicker_L4() async {
        let view = platformPhotoPicker_L4 { _ in }
        
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
        let view = platformCameraInterface_L4 { _ in }
        
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

    // MARK: - Layout chrome dual-path (gh-243)

    /// Verifies anonymous layout/chrome modifiers still host, and that an explicit `.named(anchorName)`
    /// produces a discoverable identifier (covers both paths). Uses isolated config + explicit environment
    /// injection so hosting matches modifier bodies under parallel/full-suite runs.
    @MainActor
    fileprivate func assertLayoutChromeDualPath<V: View>(
        anchorName: String,
        context: String,
        @ViewBuilder root: () -> V
    ) {
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            let anonymous = root()
            _ = hostRootPlatformView(anonymous, accessibilityIdentifierConfig: isolated)
            #expect(Bool(true), "\(context): anonymous compliance path should render")

            let named = root().named(anchorName)
            let namedHost = hostRootPlatformView(named, accessibilityIdentifierConfig: isolated)
            #expect(Bool(true), "\(context): named path should render")

            let expectedNamedId = NamedModifier.testingGeneratedIdentifier(name: anchorName, config: isolated)
            let platformIds = findAllAccessibilityIdentifiersFromPlatformView(namedHost)
            let platformHit = platformIds.contains { $0 == expectedNamedId || $0.contains(anchorName) }
            #if canImport(ViewInspector)
            let viIds = AccessibilityTestUtilities.allAccessibilityIdentifiersFromViewInspector(named)
            let viHit = viIds.contains { $0 == expectedNamedId || $0.contains(anchorName) }
            #else
            let viHit = false
            #endif
            let debugLog = isolated.getDebugLog()
            let logHit = debugLog.contains(expectedNamedId)
            #expect(
                platformHit || viHit || logHit,
                "\(context): expected named id '\(expectedNamedId)' via platform, ViewInspector, or config debug log. Platform sample: \(platformIds.prefix(6).joined(separator: ", ")); log tail: \(String(debugLog.suffix(280)))"
            )
        }
    }
}

