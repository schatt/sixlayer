import Testing
import Foundation

//
//  NavigationStackLayer2Tests.swift
//  SixLayerFrameworkTests
//
//  Layer 2 (Decision) TDD Tests for NavigationStack
//  Tests for determineNavigationStackStrategy_L2 function
//
//  Test Documentation:
//  Business purpose: Determine when NavigationStack is appropriate vs other navigation patterns
//  What are we actually testing:
//    - Navigation strategy decision algorithm based on content analysis
//    - Integration with existing NavigationStrategy enum
//    - Content complexity analysis for navigation decisions
//    - Device type considerations for navigation
//  HOW are we testing it:
//    - Test navigation strategy selection with different content types
//    - Test navigation strategy selection with different item counts
//    - Test navigation strategy selection with different hints
//    - Test integration with existing NavigationStrategy enum
//    - Validate decision logic algorithms
//

@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("NavigationStack Layer 2")
open class NavigationStackLayer2Tests: BaseTestClass {
    
    // MARK: - Test Data
    
    struct TestItem: Identifiable, Hashable {
        let id: UUID
        let title: String
    }
    
    // MARK: - determineNavigationStackStrategy_L2 Tests
    
    @Test @MainActor func testDetermineNavigationStackStrategy_L2_ReturnsDecision() {
        // Given: Simple content with navigation hints
        let items = (1...3).map { i in TestItem(id: UUID(), title: "Item \(i)") }
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .navigation,
            complexity: .simple,
            context: .navigation
        )
        
        // When: Determining navigation strategy
        let decision = determineNavigationStackStrategy_L2(
            items: items,
            hints: hints
        )
        
        // Then: Should return a decision with a strategy
        #expect(decision.strategy != nil, "Should have a navigation strategy")
    }
    
    @Test @MainActor func testDetermineNavigationStackStrategy_L2_SimpleContentUsesNavigationStack() {
        // Given: Simple content (few items)
        let items = (1...3).map { i in TestItem(id: UUID(), title: "Item \(i)") }
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .navigation,
            complexity: .simple,
            context: .navigation
        )
        
        // When: Determining navigation strategy
        let decision = determineNavigationStackStrategy_L2(
            items: items,
            hints: hints
        )
        
        // Then: Should recommend NavigationStack for simple content
        #expect(decision.strategy == .navigationStack, 
                "Simple content should use NavigationStack strategy")
    }
    
    @Test @MainActor func testDetermineNavigationStackStrategy_L2_EmptyContentUsesNavigationStack() {
        // Given: Empty content
        let items: [TestItem] = []
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .navigation,
            complexity: .simple,
            context: .navigation
        )
        
        // When: Determining navigation strategy
        let decision = determineNavigationStackStrategy_L2(
            items: items,
            hints: hints
        )
        
        // Then: Should recommend NavigationStack for empty content
        #expect(decision.strategy == .navigationStack, 
                "Empty content should use NavigationStack strategy")
    }
    
    @Test @MainActor func testDetermineNavigationStackStrategy_L2_RespectsHintsPreference() {
        // Given: Hints explicitly requesting navigation
        let items = (1...10).map { i in TestItem(id: UUID(), title: "Item \(i)") }
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .navigation,
            complexity: .moderate,
            context: .navigation
        )
        
        // When: Determining navigation strategy
        let decision = determineNavigationStackStrategy_L2(
            items: items,
            hints: hints
        )
        
        // Then: Should respect hints preference
        #expect(decision.strategy == .navigationStack, 
                "Should respect hints preference for navigation")
    }
    
    @Test @MainActor func testDetermineNavigationStackStrategy_L2_RespectsDetailPreference() {
        // Given: Hints explicitly requesting detail/split view
        let items = (1...10).map { i in TestItem(id: UUID(), title: "Item \(i)") }
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .detail,
            complexity: .moderate,
            context: .navigation
        )
        
        // When: Determining navigation strategy
        let decision = determineNavigationStackStrategy_L2(
            items: items,
            hints: hints
        )
        
        // Then: Should respect detail preference (may recommend splitView)
        #expect(decision.strategy == .splitView || decision.strategy == .navigationStack,
                "Should respect detail preference, may use splitView or navigationStack")
    }
    
    @Test @MainActor func testDetermineNavigationStackStrategy_L2_RespectsModalPreference() {
        // Given: Hints explicitly requesting modal
        let items = (1...5).map { i in TestItem(id: UUID(), title: "Item \(i)") }
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .modal,
            complexity: .simple,
            context: .navigation
        )
        
        // When: Determining navigation strategy
        let decision = determineNavigationStackStrategy_L2(
            items: items,
            hints: hints
        )
        
        // Then: Should respect modal preference
        #expect(decision.strategy == .modal, 
                "Should respect modal preference")
    }
    
    @Test @MainActor func testDetermineNavigationStackStrategy_L2_ComplexContentAnalysis() {
        // Given: Complex content (many items)
        let items = (1...50).map { i in TestItem(id: UUID(), title: "Item \(i)") }
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .automatic,
            complexity: .complex,
            context: .navigation
        )
        
        // When: Determining navigation strategy
        let decision = determineNavigationStackStrategy_L2(
            items: items,
            hints: hints
        )
        
        // Then: Should make appropriate decision for complex content
        #expect(decision.strategy != nil, "Should have a strategy for complex content")
        #expect(decision.reasoning != nil && !decision.reasoning!.isEmpty,
                "Should provide reasoning for decision")
    }
    
    @Test @MainActor func testDetermineNavigationStackStrategy_L2_ProvidesReasoning() {
        // Given: Content with hints
        let items = (1...5).map { i in TestItem(id: UUID(), title: "Item \(i)") }
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .navigation,
            complexity: .simple,
            context: .navigation
        )
        
        // When: Determining navigation strategy
        let decision = determineNavigationStackStrategy_L2(
            items: items,
            hints: hints
        )
        
        // Then: Should provide reasoning
        #expect(decision.reasoning != nil, "Should provide reasoning")
        #expect(!decision.reasoning!.isEmpty, "Reasoning should not be empty")
    }
    
    // MARK: - App Navigation Decision Tests
    
    @Test @MainActor func testDetermineAppNavigationStrategy_L2_iPad_UsesSplitView() {
        // Given: iPad device
        let deviceType = DeviceType.pad
        let orientation = DeviceOrientation.portrait
        let screenSize = CGSize(width: 1024, height: 768)
        
        // When: Determining app navigation strategy
        let decision = determineAppNavigationStrategy_L2(
            deviceType: deviceType,
            orientation: orientation,
            screenSize: screenSize,
            iPhoneSizeCategory: nil
        )
        
        // Then: Should recommend split view for iPad
        #expect(decision.useSplitView == true, "iPad should use split view")
        #expect(decision.reasoning.contains("iPad"), "Reasoning should mention iPad")
    }
    
    @Test @MainActor func testDetermineAppNavigationStrategy_L2_macOS_UsesSplitView() {
        // Given: macOS device
        let deviceType = DeviceType.mac
        let orientation = DeviceOrientation.landscape
        let screenSize = CGSize(width: 1920, height: 1080)
        
        // When: Determining app navigation strategy
        let decision = determineAppNavigationStrategy_L2(
            deviceType: deviceType,
            orientation: orientation,
            screenSize: screenSize,
            iPhoneSizeCategory: nil
        )
        
        // Then: Should recommend split view for macOS
        #expect(decision.useSplitView == true, "macOS should use split view")
        #expect(decision.reasoning.contains("macOS"), "Reasoning should mention macOS")
    }
    
    @Test @MainActor func testDetermineAppNavigationStrategy_L2_iPhonePortrait_UsesDetailOnly() {
        // Given: iPhone in portrait
        let deviceType = DeviceType.phone
        let orientation = DeviceOrientation.portrait
        let screenSize = CGSize(width: 390, height: 844)
        
        // When: Determining app navigation strategy
        let decision = determineAppNavigationStrategy_L2(
            deviceType: deviceType,
            orientation: orientation,
            screenSize: screenSize,
            iPhoneSizeCategory: .standard
        )
        
        // Then: Should recommend detail-only for iPhone portrait
        #expect(decision.useSplitView == false, "iPhone portrait should use detail-only")
        #expect(decision.reasoning.contains("portrait"), "Reasoning should mention portrait")
    }
    
    @Test @MainActor func testDetermineAppNavigationStrategy_L2_iPhonePlusLandscape_UsesSplitView() {
        // Given: iPhone Plus in landscape
        let deviceType = DeviceType.phone
        let orientation = DeviceOrientation.landscape
        let screenSize = CGSize(width: 896, height: 414)
        
        // When: Determining app navigation strategy
        let decision = determineAppNavigationStrategy_L2(
            deviceType: deviceType,
            orientation: orientation,
            screenSize: screenSize,
            iPhoneSizeCategory: .plus
        )
        
        // Then: Should recommend split view for large iPhone in landscape
        #expect(decision.useSplitView == true, "iPhone Plus landscape should use split view")
        #expect(decision.reasoning.contains("landscape"), "Reasoning should mention landscape")
    }
    
    @Test @MainActor func testDetermineAppNavigationStrategy_L2_iPhoneProMaxLandscape_UsesSplitView() {
        // Given: iPhone Pro Max in landscape
        let deviceType = DeviceType.phone
        let orientation = DeviceOrientation.landscape
        let screenSize = CGSize(width: 926, height: 428)
        
        // When: Determining app navigation strategy
        let decision = determineAppNavigationStrategy_L2(
            deviceType: deviceType,
            orientation: orientation,
            screenSize: screenSize,
            iPhoneSizeCategory: .proMax
        )
        
        // Then: Should recommend split view for Pro Max in landscape
        #expect(decision.useSplitView == true, "iPhone Pro Max landscape should use split view")
        #expect(decision.reasoning.contains("landscape"), "Reasoning should mention landscape")
    }
    
    @Test @MainActor func testDetermineAppNavigationStrategy_L2_iPhoneStandardLandscape_UsesDetailOnly() {
        // Given: iPhone standard in landscape
        let deviceType = DeviceType.phone
        let orientation = DeviceOrientation.landscape
        let screenSize = CGSize(width: 844, height: 390)
        
        // When: Determining app navigation strategy
        let decision = determineAppNavigationStrategy_L2(
            deviceType: deviceType,
            orientation: orientation,
            screenSize: screenSize,
            iPhoneSizeCategory: .standard
        )
        
        // Then: Should recommend detail-only for standard iPhone in landscape
        #expect(decision.useSplitView == false, "iPhone standard landscape should use detail-only")
        #expect(decision.reasoning.contains("landscape"), "Reasoning should mention landscape")
    }
}

