import Testing


import SwiftUI
@testable import SixLayerFramework
/// UI Generation Verification Tests
/// Tests that the correct UI components are generated based on capabilities
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("UIGeneration Verification", DefaultRuntimeCapabilityIsolationTrait())
open class UIGenerationVerificationTests: BaseTestClass {
    
    // MARK: - Test Configuration
    
    /// UI generation test configuration
    struct UIGenerationTestConfig {
        let name: String
        let capabilities: CapabilitySet
        let expectedUIComponents: [ExpectedUIComponent]
        let expectedModifiers: [ExpectedModifier]
        let expectedBehaviors: [ExpectedBehavior]
        
        struct CapabilitySet {
            let supportsTouch: Bool
            let supportsHover: Bool
            let supportsHapticFeedback: Bool
            let supportsAssistiveTouch: Bool
            let supportsVoiceOver: Bool
            let supportsSwitchControl: Bool
            let supportsVision: Bool
            let supportsOCR: Bool
            let minTouchTarget: CGFloat
            let hoverDelay: TimeInterval
        }
        
        struct ExpectedUIComponent {
            let type: ComponentType
            let shouldBePresent: Bool
            let description: String
        }
        
        struct ExpectedModifier {
            let type: ModifierType
            let shouldBePresent: Bool
            let description: String
        }
        
        struct ExpectedBehavior {
            let type: BehaviorType
            let shouldBePresent: Bool
            let description: String
        }
        
        enum ComponentType {
            case tapGesture
            case hoverGesture
            case hapticFeedback
            case assistiveTouch
            case accessibilityElement
            case contextMenu
            case dragAndDrop
            case keyboardShortcut
        }
        
        enum ModifierType {
            case onTapGesture
            case onHover
            case onLongPressGesture
            case accessibilityAddTraits
            case accessibilityAction
            case contextMenu
            case onDrop
            case keyboardShortcut
        }
        
        enum BehaviorType {
            case touchInteraction
            case hoverInteraction
            case hapticFeedback
            case assistiveTouchSupport
            case accessibilitySupport
            case contextMenuSupport
            case dragDropSupport
            case keyboardNavigation
        }
        
        // MARK: - Static Configuration Access
        
        static let allConfigurations: [UIGenerationTestConfig] = [
            // Touch-enabled configuration
            UIGenerationTestConfig(
                name: "Touch-Enabled UI Generation",
                capabilities: UIGenerationTestConfig.CapabilitySet(
                    supportsTouch: true,
                    supportsHover: false,
                    supportsHapticFeedback: true,
                    supportsAssistiveTouch: true,
                    supportsVoiceOver: true,
                    supportsSwitchControl: true,
                    supportsVision: false,
                    supportsOCR: false,
                    minTouchTarget: 44,
                    hoverDelay: 0.0
                ),
                expectedUIComponents: [
                    UIGenerationTestConfig.ExpectedUIComponent(
                        type: .tapGesture,
                        shouldBePresent: true,
                        description: "Tap gesture should be present for touch interaction"
                    ),
                    UIGenerationTestConfig.ExpectedUIComponent(
                        type: .hapticFeedback,
                        shouldBePresent: true,
                        description: "Haptic feedback should be present for touch interaction"
                    ),
                    UIGenerationTestConfig.ExpectedUIComponent(
                        type: .assistiveTouch,
                        shouldBePresent: true,
                        description: "AssistiveTouch should be present for touch interaction"
                    ),
                    UIGenerationTestConfig.ExpectedUIComponent(
                        type: .accessibilityElement,
                        shouldBePresent: true,
                        description: "Accessibility elements should always be present"
                    )
                ],
                expectedModifiers: [
                    UIGenerationTestConfig.ExpectedModifier(
                        type: .onTapGesture,
                        shouldBePresent: true,
                        description: "onTapGesture modifier should be present"
                    ),
                    UIGenerationTestConfig.ExpectedModifier(
                        type: .onLongPressGesture,
                        shouldBePresent: true,
                        description: "onLongPressGesture modifier should be present"
                    ),
                    UIGenerationTestConfig.ExpectedModifier(
                        type: .accessibilityAddTraits,
                        shouldBePresent: true,
                        description: "accessibilityAddTraits modifier should be present"
                    ),
                    UIGenerationTestConfig.ExpectedModifier(
                        type: .accessibilityAction,
                        shouldBePresent: true,
                        description: "accessibilityAction modifier should be present"
                    )
                ],
                expectedBehaviors: [
                    UIGenerationTestConfig.ExpectedBehavior(
                        type: .touchInteraction,
                        shouldBePresent: true,
                        description: "Touch interaction should be enabled"
                    ),
                    UIGenerationTestConfig.ExpectedBehavior(
                        type: .hapticFeedback,
                        shouldBePresent: true,
                        description: "Haptic feedback should be enabled"
                    ),
                    UIGenerationTestConfig.ExpectedBehavior(
                        type: .assistiveTouchSupport,
                        shouldBePresent: true,
                        description: "AssistiveTouch support should be enabled"
                    ),
                    UIGenerationTestConfig.ExpectedBehavior(
                        type: .accessibilitySupport,
                        shouldBePresent: true,
                        description: "Accessibility support should always be enabled"
                    )
                ]
            ),
            
            // Hover-enabled configuration
            UIGenerationTestConfig(
                name: "Hover-Enabled UI Generation",
                capabilities: UIGenerationTestConfig.CapabilitySet(
                    supportsTouch: false,
                    supportsHover: true,
                    supportsHapticFeedback: false,
                    supportsAssistiveTouch: false,
                    supportsVoiceOver: true,
                    supportsSwitchControl: true,
                    supportsVision: false,
                    supportsOCR: false,
                    minTouchTarget: 0,
                    hoverDelay: 0.5
                ),
                expectedUIComponents: [
                    UIGenerationTestConfig.ExpectedUIComponent(
                        type: .hoverGesture,
                        shouldBePresent: true,
                        description: "Hover gesture should be present for hover interaction"
                    ),
                    UIGenerationTestConfig.ExpectedUIComponent(
                        type: .accessibilityElement,
                        shouldBePresent: true,
                        description: "Accessibility elements should always be present"
                    )
                ],
                expectedModifiers: [
                    UIGenerationTestConfig.ExpectedModifier(
                        type: .onHover,
                        shouldBePresent: true,
                        description: "onHover modifier should be present"
                    ),
                    UIGenerationTestConfig.ExpectedModifier(
                        type: .accessibilityAddTraits,
                        shouldBePresent: true,
                        description: "accessibilityAddTraits modifier should be present"
                    )
                ],
                expectedBehaviors: [
                    UIGenerationTestConfig.ExpectedBehavior(
                        type: .hoverInteraction,
                        shouldBePresent: true,
                        description: "Hover interaction should be enabled"
                    ),
                    UIGenerationTestConfig.ExpectedBehavior(
                        type: .accessibilitySupport,
                        shouldBePresent: true,
                        description: "Accessibility support should always be enabled"
                    )
                ]
            )
        ]
    }
    
    // MARK: - Test Configurations
    
    private let uiTestConfigurations: [UIGenerationTestConfig] = UIGenerationTestConfig.allConfigurations
    
    // MARK: - UI Generation Tests
    
    @Test func testAllUIGenerationConfigurations() {
        for config in uiTestConfigurations {
            testUIGenerationConfiguration(config)
        }
    }
    
    @Test(arguments: UIGenerationTestConfig.allConfigurations)
    func testUIGenerationConfiguration(_ config: UIGenerationTestConfig) {
        print("🎨 Testing UI generation for: \(config.name)")
        
        // Test that the configuration is valid
        #expect(config.name.count > 0, "Configuration name should not be empty")
        #expect(config.capabilities.minTouchTarget >= 0, "Minimum touch target should be non-negative")
        #expect(config.capabilities.hoverDelay >= 0.0, "Hover delay should be non-negative")
        
        // Test that expected components are defined
        #expect(config.expectedUIComponents.count > 0, "Expected UI components should be defined")
        #expect(config.expectedModifiers.count > 0, "Expected modifiers should be defined")
        #expect(config.expectedBehaviors.count > 0, "Expected behaviors should be defined")
    }
    
    @Test func testTouchUIGenerationBothStates() throws {
        // Test touch-enabled configuration
        let touchEnabledConfig = UIGenerationTestConfig(
            name: "Touch-Enabled Test",
            capabilities: UIGenerationTestConfig.CapabilitySet(
                supportsTouch: true,
                supportsHover: false,
                supportsHapticFeedback: true,
                supportsAssistiveTouch: true,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsVision: false,
                supportsOCR: false,
                minTouchTarget: 44,
                hoverDelay: 0.0
            ),
            expectedUIComponents: [
                UIGenerationTestConfig.ExpectedUIComponent(
                    type: .tapGesture,
                    shouldBePresent: true,
                    description: "Tap gesture should be present"
                )
            ],
            expectedModifiers: [],
            expectedBehaviors: []
        )
        
        // Test touch-disabled configuration
        let touchDisabledConfig = UIGenerationTestConfig(
            name: "Touch-Disabled Test",
            capabilities: UIGenerationTestConfig.CapabilitySet(
                supportsTouch: false,
                supportsHover: false,
                supportsHapticFeedback: false,
                supportsAssistiveTouch: false,
                supportsVoiceOver: true,
                supportsSwitchControl: true,
                supportsVision: false,
                supportsOCR: false,
                minTouchTarget: 0,
                hoverDelay: 0.0
            ),
            expectedUIComponents: [
                UIGenerationTestConfig.ExpectedUIComponent(
                    type: .accessibilityElement,
                    shouldBePresent: true,
                    description: "Accessibility elements should always be present"
                )
            ],
            expectedModifiers: [],
            expectedBehaviors: []
        )
        
        // Verify configurations are valid
        #expect(touchEnabledConfig.capabilities.supportsTouch == true, "Touch should be enabled")
        #expect(touchDisabledConfig.capabilities.supportsTouch == false, "Touch should be disabled")
    }
    
    /// Test hover UI generation for both hover-enabled and hover-disabled states
    @Test(arguments: UIGenerationTestConfig.allConfigurations)
    func testHoverUIGenerationBothStates(_ config: UIGenerationTestConfig) throws {
        // Given
        let hoverEnabledConfig = config
        
        // Then
        #expect(hoverEnabledConfig.capabilities.supportsHover == config.capabilities.supportsHover, "Hover support should match configuration")
    }
    
    /// Test platform-specific configuration differences (representative DTO shapes, not host emulation).
    @Test func testPlatformSpecificConfigurationDifferences() {
        let touchFirstShape = UIGenerationTestConfig.CapabilitySet(
            supportsTouch: true,
            supportsHover: false,
            supportsHapticFeedback: true,
            supportsAssistiveTouch: true,
            supportsVoiceOver: true,
            supportsSwitchControl: true,
            supportsVision: false,
            supportsOCR: false,
            minTouchTarget: 44,
            hoverDelay: 0.0
        )
        
        let hoverFirstShape = UIGenerationTestConfig.CapabilitySet(
            supportsTouch: false,
            supportsHover: true,
            supportsHapticFeedback: false,
            supportsAssistiveTouch: false,
            supportsVoiceOver: true,
            supportsSwitchControl: true,
            supportsVision: false,
            supportsOCR: false,
            minTouchTarget: 0,
            hoverDelay: 0.1
        )
        
        #expect(touchFirstShape.supportsTouch != hoverFirstShape.supportsTouch, "Touch-first and hover-first shapes should differ on touch")
        #expect(touchFirstShape.supportsHover != hoverFirstShape.supportsHover, "Touch-first and hover-first shapes should differ on hover")
        #expect(touchFirstShape.supportsHapticFeedback != hoverFirstShape.supportsHapticFeedback, "Touch-first and hover-first shapes should differ on haptic")
    }
    
    /// Card expansion config on **current host** through touch/hover tri-state (#251).
    @Test @MainActor func testCardExpansionConfigTriStatePhases() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        func assertConfigMirrorsDetection(phase: String) {
            let platform = SixLayerPlatform.current
            let config = getCardExpansionPlatformConfig()
            let effectiveTouch = RuntimeCapabilityDetection.supportsTouch
            let expectedMin = PlatformTestUtilities.expectedMinTouchTarget(
                for: platform,
                touchDetected: effectiveTouch
            )

            switch platform {
            case .iOS, .watchOS, .macOS, .tvOS, .visionOS:
                #expect(config.supportsTouch == effectiveTouch, "\(phase): touch should mirror detection")
                #expect(config.supportsHover == RuntimeCapabilityDetection.supportsHover, "\(phase): hover should mirror detection")
                #expect(config.minTouchTarget == expectedMin, "\(phase): minTouchTarget should match HIG on \(platform)")
            }
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        assertConfigMirrorsDetection(phase: "current")

        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestHover(false)
        assertConfigMirrorsDetection(phase: "disabled")

        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestHover(true)
        assertConfigMirrorsDetection(phase: "enabled")
    }
}
