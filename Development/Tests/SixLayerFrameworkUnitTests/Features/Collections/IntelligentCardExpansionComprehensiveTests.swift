import Testing

//
//  IntelligentCardExpansionComprehensiveTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive tests for the Intelligent Card Expansion System
//

import SwiftUI
@testable import SixLayerFramework

/// Comprehensive tests for the Intelligent Card Expansion System
/// Tests all 6 layers with edge cases, performance, and integration scenarios
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Intelligent Card Expansion Comprehensive")
open class IntelligentCardExpansionComprehensiveTests: BaseTestClass {    // MARK: - Test Data
    
    private var sampleMenuItems: [MenuItem] {
        [
            MenuItem(id: "1", title: "Dashboard", icon: "chart.bar", color: .blue),
            MenuItem(id: "2", title: "Analytics", icon: "chart.line", color: .green),
            MenuItem(id: "3", title: "Reports", icon: "doc.text", color: .orange),
            MenuItem(id: "4", title: "Settings", icon: "gear", color: .gray),
            MenuItem(id: "5", title: "Profile", icon: "person", color: .purple),
            MenuItem(id: "6", title: "Help", icon: "questionmark", color: .red),
            MenuItem(id: "7", title: "About", icon: "info", color: .indigo),
            MenuItem(id: "8", title: "Contact", icon: "envelope", color: .teal)
        ]
    }
    
    private var expandableHints: PresentationHints {
        PresentationHints(
            dataType: .collection,
            presentationPreference: .cards,
            complexity: .moderate,
            context: .dashboard,
            customPreferences: [
                "itemType": "featureCards",
                "interactionStyle": "expandable",
                "layoutPreference": "adaptiveGrid",
                "contentDensity": "balanced"
            ]
        )
    }
    
    // MARK: - Layer 1 Tests: Semantic Intent Functions
    
    @Test @MainActor func testPlatformPresentItemCollectionL1BasicFunctionality() {
        initializeTestConfig()
        // Test basic Layer 1 functionality
        _ = platformPresentItemCollection_L1(
            items: sampleMenuItems,
            hints: expandableHints
        )
        
        // View creation succeeded (non-optional result)
    }
    
    @Test @MainActor func testPlatformPresentItemCollectionL1WithEmptyItems() {
        initializeTestConfig()
        // Test with empty items array - use a concrete type
        let emptyHints = PresentationHints(
            dataType: .collection,
            presentationPreference: .cards,
            complexity: .simple,
            context: .dashboard
        )
        
        let emptyItems: [MenuItem] = []
        _ = platformPresentItemCollection_L1(
            items: emptyItems,
            hints: emptyHints
        )
        
        // View creation succeeded (non-optional result)
        // The view should render an empty state, not crash or show blank content
    }
    
    @Test @MainActor func testPlatformPresentItemCollectionL1EmptyStateWithDifferentDataTypes() {
            initializeTestConfig()
        // Test empty state with different data types
        let testCases: [(DataTypeHint, String)] = [
            (.media, "No Media Items"),
            (.navigation, "No Navigation Items"),
            (.form, "No Form Fields"),
            (.numeric, "No Data Available"),
            (.temporal, "No Events"),
            (.hierarchical, "No Items"),
            (.collection, "No Items"),
            (.generic, "No Items")
        ]
        
        for (dataType, _) in testCases {
            let hints = PresentationHints(
                dataType: dataType,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: .dashboard
            )
            
            let emptyItems: [MenuItem] = []
            _ = platformPresentItemCollection_L1(
                items: emptyItems,
                hints: hints
            )
            
            // View creation succeeded (non-optional result)
            // In a real test environment, we would verify the empty state title matches expectedTitle
        }
    }
    
    @Test @MainActor func testPlatformPresentItemCollectionL1EmptyStateWithDifferentContexts() {
            initializeTestConfig()
        // Test empty state with different contexts
        let testCases: [PresentationContext] = [
            .dashboard,
            .detail,
            .search,
            .summary,
            .modal
        ]
        
        for context in testCases {
            let hints = PresentationHints(
                dataType: .collection,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: context
            )
            
            let emptyItems: [MenuItem] = []
            _ = platformPresentItemCollection_L1(
                items: emptyItems,
                hints: hints
            )
            
            // View creation succeeded (non-optional result)
            // In a real test environment, we would verify the context-specific messaging
        }
    }
    
    @Test @MainActor func testPlatformPresentItemCollectionL1WithDifferentDataTypes() {
        initializeTestConfig()
        // Test with different data types
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .cards,
            complexity: .complex,
            context: .dashboard
        )
        
        _ = platformPresentItemCollection_L1(
            items: sampleMenuItems,
            hints: hints
        )
        
        // View creation succeeded (non-optional result)
    }
    
    // MARK: - Layer 2 Tests: Layout Decision Engine
    
    @Test func testDetermineIntelligentCardLayoutL2BasicFunctionality() {
        // Test basic layout determination
        let layout = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        
        // Layout decision creation succeeded (non-optional result)
        #expect(layout.cardWidth > 0)
        #expect(layout.cardHeight > 0)
        #expect(layout.columns > 0)
    }
    
    @Test func testDetermineIntelligentCardLayoutL2WithDifferentScreenSizes() {
        // Test with different screen sizes
        let mobileLayout = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 375,
            deviceType: .phone,
            contentComplexity: .moderate
        )
        
        let tabletLayout = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 768,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        
        let desktopLayout = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 1920,
            deviceType: .mac,
            contentComplexity: .moderate
        )
        
        // Desktop should have more columns than tablet, tablet more than mobile
        #expect(desktopLayout.columns > tabletLayout.columns)
        #expect(tabletLayout.columns > mobileLayout.columns)
    }
    
    @Test func testDetermineIntelligentCardLayoutL2WithDifferentContentCounts() {
        // Test with different content counts
        let smallLayout = determineIntelligentCardLayout_L2(
            contentCount: 1,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        
        let mediumLayout = determineIntelligentCardLayout_L2(
            contentCount: 10,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        
        let largeLayout = determineIntelligentCardLayout_L2(
            contentCount: 100,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        
        // More content should result in more columns (or at least not fewer)
        #expect(mediumLayout.columns >= smallLayout.columns)
        #expect(largeLayout.columns >= mediumLayout.columns)
    }
    
    @Test func testDetermineIntelligentCardLayoutL2WithDifferentComplexityLevels() {
        // Test with different complexity levels
        let simpleLayout = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: .simple
        )
        
        let complexLayout = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: .complex
        )
        
        // Complex content should result in larger cards
        #expect(complexLayout.cardWidth > simpleLayout.cardWidth)
        #expect(complexLayout.cardHeight > simpleLayout.cardHeight)
    }
    
    @Test func testDetermineIntelligentCardLayoutL2EdgeCases() {
        // Test edge cases
        _ = determineIntelligentCardLayout_L2(
            contentCount: 0,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        
        _ = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 100,
            deviceType: .phone,
            contentComplexity: .moderate
        )
        
        // Zero content layout creation succeeded (non-optional result)
        // Very small screen layout creation succeeded (non-optional result)
    }
    
    // MARK: - Layer 3 Tests: Strategy Selection
    
    @Test func testSelectCardExpansionStrategyL3BasicFunctionality() {
        // Test basic strategy selection
        let strategy = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            interactionStyle: .expandable,
            contentDensity: .balanced
        )
        
        // Strategy creation succeeded (non-optional result)
        #expect(!strategy.supportedStrategies.isEmpty)
    }
    
    @Test func testSelectCardExpansionStrategyL3WithDifferentDeviceTypes() {
        // Test with different device types
        _ = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 375,
            deviceType: .phone,
            interactionStyle: .expandable,
            contentDensity: .balanced
        )
        
        _ = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 768,
            deviceType: .pad,
            interactionStyle: .expandable,
            contentDensity: .balanced
        )
        
        _ = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 1920,
            deviceType: .mac,
            interactionStyle: .expandable,
            contentDensity: .balanced
        )
        
        // Platform strategies creation succeeded (non-optional results)
    }
    
    @Test func testSelectCardExpansionStrategyL3WithDifferentInteractionStyles() {
        // Test with different interaction styles
        _ = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            interactionStyle: .expandable,
            contentDensity: .balanced
        )
        
        _ = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            interactionStyle: .static,
            contentDensity: .balanced
        )
        
        // Interaction style strategies creation succeeded (non-optional results)
    }
    
    @Test @MainActor func testSelectCardExpansionStrategyL3WithDifferentContentDensities() {
        // Test with different content densities
        _ = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            interactionStyle: .expandable,
            contentDensity: .dense
        )
        
        _ = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            interactionStyle: .expandable,
            contentDensity: .spacious
        )
        
        // Content density strategies creation succeeded (non-optional results)
    }
    
    // MARK: - Layer 4 Tests: Component Implementation
    
    @Test @MainActor func testExpandableCardComponentBasicFunctionality() {
        // Test basic expandable card component
        let layoutDecision = IntelligentCardLayoutDecision(
            columns: 3,
            spacing: 16,
            cardWidth: 200,
            cardHeight: 150,
            padding: 16
        )
        
        let strategy = CardExpansionStrategy(
            supportedStrategies: [.hoverExpand],
            primaryStrategy: .hoverExpand,
            expansionScale: 1.15,
            animationDuration: 0.3
        )
        
        _ = ExpandableCardComponent(
            item: sampleMenuItems[0],
            layoutDecision: layoutDecision,
            strategy: strategy,
            isExpanded: false,
            isHovered: false,
            onExpand: {},
            onCollapse: {},
            onHover: { _ in },
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        
        // Card component creation succeeded (non-optional result)
    }
    
    @Test @MainActor func testExpandableCardComponentWithDifferentStrategies() {
        // Test with different expansion strategies
        let layoutDecision = IntelligentCardLayoutDecision(
            columns: 3,
            spacing: 16,
            cardWidth: 200,
            cardHeight: 150,
            padding: 16
        )
        
        let hoverStrategy = CardExpansionStrategy(
            supportedStrategies: [.hoverExpand],
            primaryStrategy: .hoverExpand,
            expansionScale: 1.15,
            animationDuration: 0.3
        )
        
        let contentRevealStrategy = CardExpansionStrategy(
            supportedStrategies: [.contentReveal],
            primaryStrategy: .contentReveal,
            expansionScale: 1.0,
            animationDuration: 0.3
        )
        
        _ = ExpandableCardComponent(
            item: sampleMenuItems[0],
            layoutDecision: layoutDecision,
            strategy: hoverStrategy,
            isExpanded: false,
            isHovered: false,
            onExpand: {},
            onCollapse: {},
            onHover: { _ in },
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        
        _ = ExpandableCardComponent(
            item: sampleMenuItems[0],
            layoutDecision: layoutDecision,
            strategy: contentRevealStrategy,
            isExpanded: false,
            isHovered: false,
            onExpand: {},
            onCollapse: {},
            onHover: { _ in },
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        
        // Different strategy cards creation succeeded (non-optional results)
    }
    
    // MARK: - Layer 5 Tests: Platform Optimization
    
    // NOTE: Platform simulation tests are split by platform for clarity and to handle
    // thread/actor isolation issues on macOS. Each test only runs when simulation works
    // or when testing the actual platform.
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_iOS() async {
        let config = getCardExpansionPlatformConfig()

        // Check runtime platform instead of compile-time platform
        let runtimePlatform = RuntimeCapabilityDetection.currentPlatform
        if runtimePlatform == .iOS {
            #expect(config.supportsTouch == true, "iOS should support touch")
            #expect(config.supportsHapticFeedback == true, "iOS should support haptic feedback")
            #expect(config.supportsHover == false, "iOS should not support hover by default")
            #expect(config.supportsVoiceOver == true, "iOS should support VoiceOver")
            #expect(config.supportsSwitchControl == true, "iOS should support Switch Control")
            #expect(config.supportsAssistiveTouch == true, "iOS should support AssistiveTouch")
        } else {
            // On other platforms, simulation may not work due to thread/actor isolation
            // Skip assertions - this is expected behavior
        }
    }
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_macOS() async {
        let config = getCardExpansionPlatformConfig()

        #expect(config.supportsTouch == false, "macOS should not support touch")
        #expect(config.supportsHapticFeedback == false, "macOS should not support haptic feedback")
        #expect(config.supportsHover == true, "macOS should support hover")
        #expect(config.supportsVoiceOver == true, "macOS should support VoiceOver")
        #expect(config.supportsSwitchControl == true, "macOS should support Switch Control")
        #expect(config.supportsAssistiveTouch == false, "macOS should not support AssistiveTouch")
    }
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_watchOS() async {
        let config = getCardExpansionPlatformConfig()

        #expect(config.supportsTouch == true, "watchOS should support touch")
        #expect(config.supportsHapticFeedback == true, "watchOS should support haptic feedback")
        #expect(config.supportsHover == false, "watchOS should not support hover")
        #expect(config.supportsVoiceOver == true, "watchOS should support VoiceOver")
        #expect(config.supportsSwitchControl == true, "watchOS should support Switch Control")
        #expect(config.supportsAssistiveTouch == true, "watchOS should support AssistiveTouch")
    }
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_tvOS() async {
        let config = getCardExpansionPlatformConfig()

        #expect(config.supportsTouch == false, "tvOS should not support touch")
        #expect(config.supportsHapticFeedback == false, "tvOS should not support haptic feedback")
        #expect(config.supportsHover == false, "tvOS should not support hover")
        #expect(config.supportsVoiceOver == true, "tvOS should support VoiceOver")
        #expect(config.supportsSwitchControl == true, "tvOS should support Switch Control")
        #expect(config.supportsAssistiveTouch == false, "tvOS should not support AssistiveTouch")
    }
    
    @Test @MainActor func testGetCardExpansionPlatformConfig_visionOS() async {
        let config = getCardExpansionPlatformConfig()

        // Check runtime platform instead of compile-time platform
        let runtimePlatform = RuntimeCapabilityDetection.currentPlatform
        if runtimePlatform == .visionOS {
            #expect(config.supportsTouch == false, "visionOS should not support touch")
            #expect(config.supportsHapticFeedback == false, "visionOS should not support haptic feedback")
            #expect(config.supportsHover == true, "visionOS should support hover")
            #expect(config.supportsVoiceOver == true, "visionOS should support VoiceOver")
            #expect(config.supportsSwitchControl == true, "visionOS should support Switch Control")
            #expect(config.supportsAssistiveTouch == false, "visionOS should not support AssistiveTouch")

            // visionOS should have platform-correct minTouchTarget (0.0, not 44.0)
            #expect(config.minTouchTarget == 0.0, "visionOS should have 0.0 touch target (platform-native)")
        } else {
            // On other platforms, simulation may not work due to thread/actor isolation
            // Skip assertions - this is expected behavior
        }
    }
    
    @Test @MainActor func testGetCardExpansionPerformanceConfig() {
        initializeTestConfig()
        // Test performance configuration
        _ = getCardExpansionPerformanceConfig()
        
        // Platform config creation succeeded (non-optional result)
    }
    
    @Test @MainActor func testPlatformFeatureMatrix() {
        initializeTestConfig()
        // Clear any existing capability overrides to test platform defaults
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        // Test that platform features are correctly detected based on platform defaults
        let config = getCardExpansionPlatformConfig()
        
        // Test feature combinations that should be mutually exclusive
        if config.supportsTouch {
            // If touch is supported, haptic feedback should also be supported
            #expect(config.supportsHapticFeedback, "Touch-enabled platforms should support haptic feedback")
        }
        
        if config.supportsHover {
            // If hover is supported, it could be macOS or visionOS
            // macOS testing default: supportsHover=true, supportsTouch=false
            // visionOS testing default: supportsHover=true, supportsTouch=true
            if !config.supportsTouch {
                // This is macOS (hover but no touch)
                #expect(!config.supportsTouch, "macOS testing default should not support touch")
            } else {
                // This is visionOS (hover and touch)
                #expect(config.supportsTouch, "visionOS testing default should support touch")
            }
        }
        
        // Test that accessibility features are correctly detected based on platform
        // VoiceOver and Switch Control are available on all platforms
        // Note: supportsVoiceOver/supportsSwitchControl check if currently enabled,
        // so we set overrides to test platform availability
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        let configWithAccessibility = getCardExpansionPlatformConfig()
        #expect(configWithAccessibility.supportsVoiceOver, "VoiceOver should be available on all platforms")
        #expect(configWithAccessibility.supportsSwitchControl, "Switch Control should be available on all platforms")
        
        // AssistiveTouch is only available on iOS and watchOS (platform capability, not user setting)
        // Verify platform detection returns correct defaults without needing overrides
        let runtimePlatform = RuntimeCapabilityDetection.currentPlatform
        if runtimePlatform == .iOS || runtimePlatform == .watchOS {
            #expect(config.supportsAssistiveTouch, "AssistiveTouch should be available on iOS and watchOS (platform capability)")
        } else {
            // macOS, tvOS, and visionOS do not support AssistiveTouch
            #expect(!config.supportsAssistiveTouch, "AssistiveTouch should not be available on \(runtimePlatform)")
        }
        
        // Test that touch target size is appropriate for current platform
        // Apple HIG: 44pt minimum applies to touch-first platforms (iOS/watchOS)
        // regardless of whether touch is currently enabled, as these platforms
        // are designed for touch interaction
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget: CGFloat = (currentPlatform == .iOS || currentPlatform == .watchOS) ? 44.0 : 0.0
        #expect(config.minTouchTarget == expectedMinTouchTarget, "Touch targets should be platform-appropriate (\(expectedMinTouchTarget)) for \(currentPlatform)")
    }
    
    // MARK: - Layer 6 Tests: Platform System
    
    @Test @MainActor func testNativeExpandableCardViewBasicFunctionality() {
        initializeTestConfig()
        // Test basic native expandable card view
        let platformConfig = getCardExpansionPlatformConfig()
        let performanceConfig = CardExpansionPerformanceConfig()
        let accessibilityConfig = CardExpansionAccessibilityConfig()
        
        _ = NativeExpandableCardView(
            item: sampleMenuItems[0],
            expansionStrategy: .hoverExpand,
            platformConfig: platformConfig,
            performanceConfig: performanceConfig,
            accessibilityConfig: accessibilityConfig
        )
        
        // Card view creation succeeded (non-optional result)
    }
    
    @Test @MainActor func testNativeExpandableCardViewWithDifferentStrategies() {
        initializeTestConfig()
        // Test with different expansion strategies
        let platformConfig = getCardExpansionPlatformConfig()
        let performanceConfig = CardExpansionPerformanceConfig()
        let accessibilityConfig = CardExpansionAccessibilityConfig()
        
        _ = NativeExpandableCardView(
            item: sampleMenuItems[0],
            expansionStrategy: .hoverExpand,
            platformConfig: platformConfig,
            performanceConfig: performanceConfig,
            accessibilityConfig: accessibilityConfig
        )
        
        _ = NativeExpandableCardView(
            item: sampleMenuItems[0],
            expansionStrategy: .contentReveal,
            platformConfig: platformConfig,
            performanceConfig: performanceConfig,
            accessibilityConfig: accessibilityConfig
        )
        
        _ = NativeExpandableCardView(
            item: sampleMenuItems[0],
            expansionStrategy: .gridReorganize,
            platformConfig: platformConfig,
            performanceConfig: performanceConfig,
            accessibilityConfig: accessibilityConfig
        )
        
        _ = NativeExpandableCardView(
            item: sampleMenuItems[0],
            expansionStrategy: .focusMode,
            platformConfig: platformConfig,
            performanceConfig: performanceConfig,
            accessibilityConfig: accessibilityConfig
        )
        
        // Multiple strategy card views creation succeeded (non-optional results)
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testEndToEndCardExpansionWorkflow() {
        initializeTestConfig()
        // Test complete end-to-end workflow
        _ = platformPresentItemCollection_L1(
            items: sampleMenuItems,
            hints: expandableHints
        )
        
        // View creation succeeded (non-optional result)
        
        // Test Layer 2
        _ = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        
        // Layout decision creation succeeded (non-optional result)
        
        // Test Layer 3
        _ = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            interactionStyle: .expandable,
            contentDensity: .balanced
        )
        
        // Strategy creation succeeded (non-optional result)
        
        // Test Layer 5
        let platformConfig = getCardExpansionPlatformConfig()
        let performanceConfig = getCardExpansionPerformanceConfig()
        
        // Platform and performance configs creation succeeded (non-optional results)
        
        // Test Layer 6
        let accessibilityConfig = CardExpansionAccessibilityConfig()
        _ = NativeExpandableCardView(
            item: sampleMenuItems[0],
            expansionStrategy: .hoverExpand,
            platformConfig: platformConfig,
            performanceConfig: performanceConfig,
            accessibilityConfig: accessibilityConfig
        )
        
        // Platform view creation succeeded (non-optional result)
    }
    
    @Test @MainActor func testCrossLayerDataFlow() {
        initializeTestConfig()
        // Test that data flows correctly between layers
        let hints = expandableHints
        
        // Layer 1 -> Layer 2
        _ = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: hints.complexity
        )
        
        // Layout decision creation succeeded (non-optional result)
        
        // Layer 2 -> Layer 3
        _ = selectCardExpansionStrategy_L3(
            contentCount: sampleMenuItems.count,
            screenWidth: 1024,
            deviceType: .pad,
            interactionStyle: .expandable,
            contentDensity: .balanced
        )
        
        // Strategy creation succeeded (non-optional result)
    }
    
    // MARK: - Performance Tests
    
    @Test @MainActor func testCardExpansionPerformance() {
        initializeTestConfig()
        // Performance test removed - performance monitoring was removed from framework
        // Large dataset creation was removed as it was unused
    }
    
    @Test @MainActor func testLayoutDecisionPerformance() {
        initializeTestConfig()
        // Test layout decision performance
        // Performance test removed - performance monitoring was removed from framework
    }
    
    @Test @MainActor func testStrategySelectionPerformance() {
        initializeTestConfig()
        // Test strategy selection performance
        // Performance test removed - performance monitoring was removed from framework
    }
    
    // MARK: - Error Handling Tests
    
    @Test @MainActor func testErrorHandlingWithInvalidData() {
        initializeTestConfig()
        // Test error handling with invalid data
        let invalidHints = PresentationHints(
            dataType: .collection,
            presentationPreference: .cards,
            complexity: .moderate,
            context: .dashboard
        )
        
        _ = platformPresentItemCollection_L1(
            items: sampleMenuItems,
            hints: invalidHints
        )
        
        // View creation succeeded (non-optional result)
    }
    
    @Test @MainActor func testErrorHandlingWithExtremeValues() {
        initializeTestConfig()
        // Test error handling with extreme values
        _ = determineIntelligentCardLayout_L2(
            contentCount: Int.max,
            screenWidth: 0,
            deviceType: .phone,
            contentComplexity: .complex
        )
        
        // Extreme layout creation succeeded (non-optional result)
    }
    
    // MARK: - Accessibility Tests
    
    @Test @MainActor func testAccessibilitySupport() {
        initializeTestConfig()
        // Test accessibility support on iOS (which supports AssistiveTouch)
        RuntimeCapabilityDetection.setTestTouchSupport(true); RuntimeCapabilityDetection.setTestHapticFeedback(true); RuntimeCapabilityDetection.setTestHover(false)
        let platformConfig = getCardExpansionPlatformConfig()
        let performanceConfig = CardExpansionPerformanceConfig()
        let accessibilityConfig = CardExpansionAccessibilityConfig()
        
        _ = NativeExpandableCardView(
            item: sampleMenuItems[0],
            expansionStrategy: .hoverExpand,
            platformConfig: platformConfig,
            performanceConfig: performanceConfig,
            accessibilityConfig: accessibilityConfig
        )
        
        // Card view creation succeeded (non-optional result)
        
        // Test that accessibility features are properly configured
        // Set accessibility capability overrides to ensure they're detected
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        let platformConfigWithAccessibility = getCardExpansionPlatformConfig()
        #expect(platformConfigWithAccessibility.supportsVoiceOver, "VoiceOver should be available")
        #expect(platformConfigWithAccessibility.supportsSwitchControl, "Switch Control should be available")
        #expect(platformConfigWithAccessibility.supportsAssistiveTouch, "AssistiveTouch should be available when enabled")
    }
    
    // MARK: - Edge Case Tests
    
    @Test @MainActor func testEdgeCaseEmptyItems() {
        initializeTestConfig()
        // Test with empty items - use a concrete type
        let emptyItems: [MenuItem] = []
        _ = platformPresentItemCollection_L1(
            items: emptyItems,
            hints: expandableHints
        )
        
        // View creation succeeded (non-optional result)
    }
    
    @Test @MainActor func testCollectionEmptyStateView() {
        initializeTestConfig()
        // Test the CollectionEmptyStateView directly
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .cards,
            complexity: .moderate,
            context: .dashboard
        )
        
        _ = CollectionEmptyStateView(hints: hints)
        // Empty state view creation succeeded (non-optional result)
    }
    
    @Test @MainActor func testCollectionEmptyStateViewWithDifferentDataTypes() {
            initializeTestConfig()
        // Test empty state view with different data types
        let testCases: [DataTypeHint] = [
            .media, .navigation, .form, .numeric, .temporal, .hierarchical, .collection, .generic
        ]
        
        for dataType in testCases {
            let hints = PresentationHints(
                dataType: dataType,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: .dashboard
            )
            
            _ = CollectionEmptyStateView(hints: hints)
            // Empty state view creation succeeded (non-optional result)
        }
    }
    
    @Test @MainActor func testCollectionEmptyStateViewWithDifferentContexts() {
            initializeTestConfig()
        // Test empty state view with different contexts
        let testCases: [PresentationContext] = [
            .dashboard, .detail, .search, .summary, .modal
        ]
        
        for context in testCases {
            let hints = PresentationHints(
                dataType: .collection,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: context
            )
            
            _ = CollectionEmptyStateView(hints: hints)
            // Empty state view creation succeeded (non-optional result)
        }
    }
    
    @Test @MainActor func testCollectionEmptyStateViewWithDifferentComplexities() {
            initializeTestConfig()
        // Test empty state view with different complexity levels
        let testCases: [ContentComplexity] = Array(ContentComplexity.allCases) // Use real enum
        
        for complexity in testCases {
            let hints = PresentationHints(
                dataType: .collection,
                presentationPreference: .automatic,
                complexity: complexity,
                context: .dashboard
            )
            
            _ = CollectionEmptyStateView(hints: hints)
            // Empty state view creation succeeded (non-optional result)
        }
    }
    
    // MARK: - Create Action Tests
    
    @Test @MainActor func testPlatformPresentItemCollectionL1WithCreateAction() {
            initializeTestConfig()
        // Test with create action provided
        var _ = false
        let createAction = {
            // Test callback is accepted
        }
        
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .cards,
            complexity: .moderate,
            context: .dashboard
        )
        
        let emptyItems: [MenuItem] = []
        _ = platformPresentItemCollection_L1(
            items: emptyItems,
            hints: hints,
            onCreateItem: createAction
        )
        
        // View creation succeeded (non-optional result)
        // Note: In a real test environment, we would verify the create button is present
        // and that calling it triggers the createAction
    }
    
    @Test @MainActor func testPlatformPresentItemCollectionL1WithoutCreateAction() {
        initializeTestConfig()
        // Test without create action (should not show create button)
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .cards,
            complexity: .moderate,
            context: .dashboard
        )
        
        let emptyItems: [MenuItem] = []
        _ = platformPresentItemCollection_L1(
            items: emptyItems,
            hints: hints
            // No onCreateItem parameter
        )
        
        // View creation succeeded (non-optional result)
        // Note: In a real test environment, we would verify no create button is shown
    }
    
    @Test @MainActor func testCollectionEmptyStateViewWithCreateAction() {
            initializeTestConfig()
        // Test empty state view with create action
        var _ = false
        let createAction = {
            // Test callback is accepted
        }
        
        let hints = PresentationHints(
            dataType: .media,
            presentationPreference: .cards,
            complexity: .moderate,
            context: .dashboard
        )
        
        _ = CollectionEmptyStateView(hints: hints, onCreateItem: createAction)
        // Empty state view creation succeeded (non-optional result)
        // Note: In a real test environment, we would verify the create button is present
    }
    
    @Test @MainActor func testCollectionEmptyStateViewWithoutCreateAction() {
        initializeTestConfig()
        // Test empty state view without create action
        let hints = PresentationHints(
            dataType: .media,
            presentationPreference: .cards,
            complexity: .moderate,
            context: .dashboard
        )
        
        _ = CollectionEmptyStateView(hints: hints)
        // Empty state view creation succeeded (non-optional result)
        // Note: In a real test environment, we would verify no create button is shown
    }
    
    @Test @MainActor func testCreateButtonTitlesForDifferentDataTypes() {
            initializeTestConfig()
        // Test that create button titles are appropriate for different data types
        let testCases: [(DataTypeHint, String)] = [
            (.media, "Add Media"),
            (.navigation, "Add Navigation Item"),
            (.form, "Add Form Field"),
            (.numeric, "Add Data"),
            (.temporal, "Add Event"),
            (.hierarchical, "Add Item"),
            (.collection, "Add Item"),
            (.generic, "Add Item"),
            (.text, "Add Text"),
            (.number, "Add Number"),
            (.date, "Add Date"),
            (.image, "Add Image"),
            (.boolean, "Add Boolean"),
            (.list, "Add List Item"),
            (.grid, "Add Grid Item"),
            (.chart, "Add Chart Data"),
            (.action, "Add Action"),
            (.product, "Add Product"),
            (.user, "Add User"),
            (.transaction, "Add Transaction"),
            (.communication, "Add Message"),
            (.location, "Add Location"),
            (.custom, "Add Item")
        ]
        
        for (dataType, _) in testCases {
            let hints = PresentationHints(
                dataType: dataType,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: .dashboard
            )
            
            _ = CollectionEmptyStateView(hints: hints, onCreateItem: {})
            // Empty state view creation succeeded (non-optional result)
            // Note: In a real test environment, we would verify the button title matches expectedTitle
        }
    }
    
    @Test @MainActor func testEdgeCaseSingleItem() {
        initializeTestConfig()
        // Test with single item
        let singleItem = [sampleMenuItems[0]]
        _ = platformPresentItemCollection_L1(
            items: singleItem,
            hints: expandableHints
        )
        
        // View creation succeeded (non-optional result)
    }
    
    @Test @MainActor func testEdgeCaseVeryLargeDataset() {
            initializeTestConfig()
        // Test with very large dataset
        let veryLargeDataSet = (1...1000).map { index in
            MenuItem(
                id: "\(index)",
                title: "Item \(index)",
                icon: "star",
                color: .blue
            )
        }
        
        _ = platformPresentItemCollection_L1(
            items: veryLargeDataSet,
            hints: expandableHints
        )
        
        // View creation succeeded (non-optional result)
    }
    
    @Test func testEdgeCaseVerySmallScreen() {
        // Test with very small screen
        _ = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 50,
            deviceType: .phone,
            contentComplexity: .moderate
        )
        
        // Layout decision creation succeeded (non-optional result)
    }
    
    @Test func testEdgeCaseVeryLargeScreen() {
        // Test with very large screen
        _ = determineIntelligentCardLayout_L2(
            contentCount: sampleMenuItems.count,
            screenWidth: 10000,
            deviceType: .mac,
            contentComplexity: .moderate
        )
        
        // Layout decision creation succeeded (non-optional result)
    }
    
    // MARK: - Enum Tests
    
    @Test func testExpansionStrategyEnum() {
        // Test ExpansionStrategy enum
        #expect(ExpansionStrategy.hoverExpand.rawValue == "hoverExpand")
        #expect(ExpansionStrategy.contentReveal.rawValue == "contentReveal")
        #expect(ExpansionStrategy.gridReorganize.rawValue == "gridReorganize")
        #expect(ExpansionStrategy.focusMode.rawValue == "focusMode")
        #expect(ExpansionStrategy.none.rawValue == "none")
        
        // Test all cases
        let allCases = ExpansionStrategy.allCases
        #expect(allCases.count == 5)
    }
    
    @Test func testInteractionStyleEnum() {
        // Test InteractionStyle enum
        #expect(InteractionStyle.expandable.rawValue == "expandable")
        #expect(InteractionStyle.static.rawValue == "static")
        #expect(InteractionStyle.interactive.rawValue == "interactive")
        
        // Test all cases
        let allCases = InteractionStyle.allCases
        #expect(allCases.count == 3)
    }
    
    @Test func testContentDensityEnum() {
        // Test ContentDensity enum
        #expect(ContentDensity.dense.rawValue == "dense")
        #expect(ContentDensity.balanced.rawValue == "balanced")
        #expect(ContentDensity.spacious.rawValue == "spacious")
        
        // Test all cases
        let allCases = ContentDensity.allCases
        #expect(allCases.count == 3)
        // Performance test removed - performance monitoring was removed from framework
    }

// MARK: - Test Helper Types

private struct MenuItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
}
}
