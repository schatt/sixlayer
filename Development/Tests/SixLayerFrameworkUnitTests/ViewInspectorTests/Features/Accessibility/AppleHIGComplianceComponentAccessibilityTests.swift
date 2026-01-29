import Testing

//
//  AppleHIGComplianceComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive accessibility tests for ALL AppleHIGCompliance components
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Apple HIG Compliance Component Accessibility")
open class AppleHIGComplianceComponentAccessibilityTests: BaseTestClass {
    
    // MARK: - AppleHIGComplianceModifier Tests
    
    @Test @MainActor func testAppleHIGComplianceModifierGeneratesAccessibilityIdentifiers() async {
            initializeTestConfig()
        // Given: Framework components (testing our framework, not SwiftUI)
        let testContent = platformVStackContainer {
            platformPresentContent_L1(content: "HIG Compliance Content", hints: PresentationHints())
            PlatformInteractionButton(style: .primary, action: {}, identifierName: "TestButton") {
                platformPresentContent_L1(content: "Test Button", hints: PresentationHints())
            }
        }
        
        // When: Applying AppleHIGComplianceModifier
        let view = testContent.appleHIGCompliance()
        
        // Then: Should generate accessibility identifiers
        // Note: Unit tests use platform view hosting, not ViewInspector
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "AppleHIGComplianceModifier"
        )
        #expect(hasAccessibilityID, "AppleHIGComplianceModifier should generate accessibility identifiers")
    }
    
    // MARK: - SystemAccessibilityModifier Tests
    
    @Test @MainActor func testSystemAccessibilityModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("System Accessibility Content")
            Button("Test Button") { }
        }
        
        // When: Applying SystemAccessibilityModifier
        let view = testContent.systemAccessibility()
        
        // Then: Should generate accessibility identifiers
        // Note: Unit tests use platform view hosting, not ViewInspector
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "SystemAccessibilityModifier"
        )
        #expect(hasAccessibilityID, "SystemAccessibilityModifier should generate accessibility identifiers")
    }
    
    // MARK: - PlatformPatternModifier Tests
    
    @Test @MainActor func testPlatformPatternModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Platform Pattern Content")
            Button("Test Button") { }
        }
        
        // When: Applying PlatformPatternModifier
        let view = testContent.platformPatterns()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: PlatformPatternModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:75.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformPatternModifier"
        )
 #expect(hasAccessibilityID, "PlatformPatternModifier should generate accessibility identifiers ")
    }
    
    // MARK: - VisualConsistencyModifier Tests
    
    @Test @MainActor func testVisualConsistencyModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Visual Consistency Content")
            Button("Test Button") { }
        }
        
        // When: Applying VisualConsistencyModifier
        let view = testContent.visualConsistency()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: VisualConsistencyModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:92.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "VisualConsistencyModifier"
        )
 #expect(hasAccessibilityID, "VisualConsistencyModifier should generate accessibility identifiers ")
    }
    
    // MARK: - InteractionPatternModifier Tests
    
    @Test @MainActor func testInteractionPatternModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Interaction Pattern Content")
            Button("Test Button") { }
        }
        
        // When: Applying InteractionPatternModifier
        let view = testContent.interactionPatterns()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: InteractionPatternModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:108.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "InteractionPatternModifier"
        )
 #expect(hasAccessibilityID, "InteractionPatternModifier should generate accessibility identifiers ")
    }
    
    // MARK: - VoiceOverSupportModifier Tests
    
    @Test @MainActor func testVoiceOverSupportModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("VoiceOver Support Content")
            Button("Test Button") { }
        }
        
        // When: Applying VoiceOverSupportModifier
        let view = testContent.voiceOverSupport()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: VoiceOverSupportModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:124.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "VoiceOverSupportModifier"
        )
 #expect(hasAccessibilityID, "VoiceOverSupportModifier should generate accessibility identifiers ")
    }
    
    // MARK: - KeyboardNavigationModifier Tests
    
    @Test @MainActor func testKeyboardNavigationModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Keyboard Navigation Content")
            Button("Test Button") { }
        }
        
        // When: Applying KeyboardNavigationModifier
        let view = testContent.keyboardNavigation()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: KeyboardNavigationModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:179.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "KeyboardNavigationModifier"
        )
 #expect(hasAccessibilityID, "KeyboardNavigationModifier should generate accessibility identifiers ")
    }
    
    // MARK: - HighContrastModifier Tests
    
    @Test @MainActor func testHighContrastModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("High Contrast Content")
            Button("Test Button") { }
        }
        
        // When: Applying HighContrastModifier
        let view = testContent.highContrast()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: HighContrastModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:196.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "HighContrastModifier"
        )
 #expect(hasAccessibilityID, "HighContrastModifier should generate accessibility identifiers ")
    }
    
    // MARK: - ReducedMotionModifier Tests
    
    @Test @MainActor func testReducedMotionModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Reduced Motion Content")
            Button("Test Button") { }
        }
        
        // When: Applying ReducedMotionModifier
        let view = testContent.reducedMotion()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: ReducedMotionModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:212.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "ReducedMotionModifier"
        )
 #expect(hasAccessibilityID, "ReducedMotionModifier should generate accessibility identifiers ")
    }
    
    // MARK: - DynamicTypeModifier Tests
    
    @Test @MainActor func testDynamicTypeModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Dynamic Type Content")
            Button("Test Button") { }
        }
        
        // When: Applying DynamicTypeModifier
        let view = testContent.dynamicType()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: DynamicTypeModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:225.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "DynamicTypeModifier"
        )
 #expect(hasAccessibilityID, "DynamicTypeModifier should generate accessibility identifiers ")
    }
    
    // MARK: - PlatformNavigationModifier Tests
    
    // NOTE: testPlatformNavigationModifierGeneratesAccessibilityIdentifiers moved to UI tests
    // NavigationStack/NavigationView cannot be reliably tested in unit tests because:
    // 1. ViewInspector's inspect() hangs indefinitely on NavigationStack/NavigationView
    // 2. hostRootPlatformView()'s layoutIfNeeded() hangs when hosting NavigationStack/NavigationView
    // 3. Navigation views require a proper window/view hierarchy to initialize correctly
    // See: Development/Tests/SixLayerFrameworkUITests/Features/Navigation/NavigationLayer4Tests.swift
    
    // MARK: - PlatformStylingModifier Tests
    
    @Test @MainActor func testPlatformStylingModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Platform Styling Content")
            Button("Test Button") { }
        }
        
        // When: Applying PlatformStylingModifier
        let view = testContent.platformStyling()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: PlatformStylingModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:257.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformStylingModifier"
        )
 #expect(hasAccessibilityID, "PlatformStylingModifier should generate accessibility identifiers ")
    }
    
    // MARK: - PlatformIconModifier Tests
    
    @Test @MainActor func testPlatformIconModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Platform Icon Content")
            Button("Test Button") { }
        }
        
        // When: Applying PlatformIconModifier
        let view = testContent.platformIcon()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: PlatformIconModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:268.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformIconModifier"
        )
 #expect(hasAccessibilityID, "PlatformIconModifier should generate accessibility identifiers ")
    }
    
    // MARK: - SystemColorModifier Tests
    
    @Test @MainActor func testSystemColorModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("System Color Content")
            Button("Test Button") { }
        }
        
        // When: Applying SystemColorModifier
        let view = testContent.systemColor()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: SystemColorModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:280.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "SystemColorModifier"
        )
 #expect(hasAccessibilityID, "SystemColorModifier should generate accessibility identifiers ")
    }
    
    // MARK: - SystemTypographyModifier Tests
    
    @Test @MainActor func testSystemTypographyModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("System Typography Content")
            Button("Test Button") { }
        }
        
        // When: Applying SystemTypographyModifier
        let view = testContent.systemTypography()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: SystemTypographyModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:291.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "SystemTypographyModifier"
        )
 #expect(hasAccessibilityID, "SystemTypographyModifier should generate accessibility identifiers ")
    }
    
    // MARK: - SpacingModifier Tests
    
    @Test @MainActor func testSpacingModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Spacing Content")
            Button("Test Button") { }
        }
        
        // When: Applying SpacingModifier
        let view = testContent.spacing()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: SpacingModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:302.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "SpacingModifier"
        )
 #expect(hasAccessibilityID, "SpacingModifier should generate accessibility identifiers ")
    }
    
    // MARK: - TouchTargetModifier Tests
    
    @Test @MainActor func testTouchTargetModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Touch Target Content")
            Button("Test Button") { }
        }
        
        // When: Applying TouchTargetModifier
        let view = testContent.touchTarget()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: TouchTargetModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:317.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "TouchTargetModifier"
        )
 #expect(hasAccessibilityID, "TouchTargetModifier should generate accessibility identifiers ")
    }
    
    // MARK: - PlatformInteractionModifier Tests
    
    @Test @MainActor func testPlatformInteractionModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Platform Interaction Content")
            Button("Test Button") { }
        }
        
        // When: Applying PlatformInteractionModifier
        let view = testContent.platformInteraction()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: PlatformInteractionModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:341.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformInteractionModifier"
        )
 #expect(hasAccessibilityID, "PlatformInteractionModifier should generate accessibility identifiers ")
    }
    
    // MARK: - HapticFeedbackModifier Tests
    
    @Test @MainActor func testHapticFeedbackModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Haptic Feedback Content")
            Button("Test Button") { }
        }
        
        // When: Applying HapticFeedbackModifier
        let view = testContent.hapticFeedback()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: HapticFeedbackModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:358.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "HapticFeedbackModifier"
        )
 #expect(hasAccessibilityID, "HapticFeedbackModifier should generate accessibility identifiers ")
    }
    
    // MARK: - GestureRecognitionModifier Tests
    
    @Test @MainActor func testGestureRecognitionModifierGeneratesAccessibilityIdentifiers() async {
        // Given: Test content
        let testContent = platformVStackContainer {
            Text("Gesture Recognition Content")
            Button("Test Button") { }
        }
        
        // When: Applying GestureRecognitionModifier
        let view = testContent.gestureRecognition()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: GestureRecognitionModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:382.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "GestureRecognitionModifier"
        )
 #expect(hasAccessibilityID, "GestureRecognitionModifier should generate accessibility identifiers ")
    }
    
    // MARK: - AppleHIGComplianceManager Tests
    
    @Test @MainActor func testAppleHIGComplianceManagerGeneratesAccessibilityIdentifiers() async {
        // Given: AppleHIGComplianceManager
        let manager = AppleHIGComplianceManager()
        
        // When: Creating a view with AppleHIGComplianceManager and applying compliance
        let baseView = platformVStackContainer {
            Text("Apple HIG Compliance Manager Content")
        }
        let view = manager.applyHIGCompliance(to: baseView)
            .environmentObject(manager)
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "AppleHIGComplianceManager"
        )
 #expect(hasAccessibilityID, "AppleHIGComplianceManager should generate accessibility identifiers ")
    }
}

// MARK: - Test Extensions

extension View {
    func appleHIGCompliance() -> some View {
        self.modifier(AppleHIGComplianceModifier(
            manager: AppleHIGComplianceManager(),
            complianceLevel: .enhanced
        ))
    }
    
    func systemAccessibility() -> some View {
        self.modifier(SystemAccessibilityModifier(
            accessibilityState: SixLayerFramework.AccessibilitySystemState(),
            platform: .iOS
        ))
    }
    
    
    func voiceOverSupport() -> some View {
        self.modifier(VoiceOverSupportModifier(isEnabled: true))
    }
    
    func keyboardNavigation() -> some View {
        self.modifier(KeyboardNavigationModifier(
            hasKeyboardSupport: true,
            hasFullKeyboardAccess: true
        ))
    }
    
    func highContrast() -> some View {
        self.modifier(HighContrastModifier(isEnabled: true))
    }
    
    func reducedMotion() -> some View {
        self.modifier(ReducedMotionModifier(isEnabled: true))
    }
    
    func dynamicType() -> some View {
        self.modifier(DynamicTypeModifier())
    }
    
    func platformNavigation() -> some View {
        self.modifier(PlatformNavigationModifier(platform: .iOS))
    }
    
    func platformStyling() -> some View {
        self.modifier(PlatformStylingModifier(
            designSystem: PlatformDesignSystem(for: .iOS)
        ))
    }
    
    func platformIcon() -> some View {
        self.modifier(PlatformIconModifier(
            iconSystem: HIGIconSystem(for: .iOS)
        ))
    }
    
    func systemColor() -> some View {
        self.modifier(SystemColorModifier(
            colorSystem: HIGColorSystem(for: .iOS)
        ))
    }
    
    func systemTypography() -> some View {
        self.modifier(SystemTypographyModifier(
            typographySystem: HIGTypographySystem(for: .iOS)
        ))
    }
    
    func spacing() -> some View {
        self.modifier(SpacingModifier(
            spacingSystem: HIGSpacingSystem(for: .iOS)
        ))
    }
    
    func touchTarget() -> some View {
        self.modifier(TouchTargetModifier(platform: .iOS))
    }
    
    func platformInteraction() -> some View {
        self.modifier(PlatformInteractionModifier(platform: .iOS))
    }
    
    func hapticFeedback() -> some View {
        self.modifier(HapticFeedbackModifier(platform: .iOS))
    }
    
    func gestureRecognition() -> some View {
        self.modifier(GestureRecognitionModifier(platform: .iOS))
    }
}


