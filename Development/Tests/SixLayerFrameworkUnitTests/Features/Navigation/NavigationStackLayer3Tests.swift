import Testing
import Foundation

//
//  NavigationStackLayer3Tests.swift
//  SixLayerFrameworkTests
//
//  Layer 3 (Strategy Selection) TDD Tests for NavigationStack
//  Tests for selectNavigationStackStrategy_L3 function
//
//  Test Documentation:
//  Business purpose: Select optimal NavigationStack implementation strategy based on Layer 2 decision and platform
//  What are we actually testing:
//    - Platform-specific strategy selection (iOS 16+ vs iOS 15, macOS, etc.)
//    - Integration with Layer 2 decisions
//    - Platform capability considerations
//    - Fallback strategy selection
//  HOW are we testing it:
//    - Test strategy selection for different platforms
//    - Test strategy selection with different Layer 2 decisions
//    - Test iOS version handling (16+ vs 15)
//    - Test macOS strategy selection
//    - Validate strategy selection logic
//

@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("NavigationStack Layer 3")
open class NavigationStackLayer3Tests: BaseTestClass {
    
    // MARK: - Test Data
    
    // MARK: - selectNavigationStackStrategy_L3 Tests
    
    @Test @MainActor func testSelectNavigationStackStrategy_L3_ReturnsStrategy() {
        // Given: Layer 2 decision recommending NavigationStack
        let l2Decision = NavigationStackDecision(
            strategy: .navigationStack,
            reasoning: "Simple content should use NavigationStack"
        )
        
        // When: Selecting implementation strategy
        let strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .iOS
        )
        
        // Then: Should return a strategy with an implementation
        #expect(strategy.implementation != nil, "Should have an implementation strategy")
    }
    
    @Test @MainActor func testSelectNavigationStackStrategy_L3_iOS16PlusUsesNavigationStack() {
        // Given: Layer 2 decision and iOS 16+ platform
        let l2Decision = NavigationStackDecision(
            strategy: .navigationStack,
            reasoning: "NavigationStack recommended"
        )
        
        // When: Selecting strategy for iOS 16+
        let strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .iOS,
            iosVersion: 16.0
        )
        
        // Then: Should use NavigationStack implementation
        #expect(strategy.implementation == .navigationStack, 
                "iOS 16+ should use NavigationStack implementation")
    }
    
    @Test @MainActor func testSelectNavigationStackStrategy_L3_iOS15UsesNavigationView() {
        // Given: Layer 2 decision and iOS 15 platform
        let l2Decision = NavigationStackDecision(
            strategy: .navigationStack,
            reasoning: "NavigationStack recommended"
        )
        
        // When: Selecting strategy for iOS 15
        let strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .iOS,
            iosVersion: 15.0
        )
        
        // Then: Should fallback to NavigationView
        #expect(strategy.implementation == .navigationView, 
                "iOS 15 should fallback to NavigationView")
    }
    
    @Test @MainActor func testSelectNavigationStackStrategy_L3_macOSUsesNavigationView() {
        // Given: Layer 2 decision and macOS platform
        let l2Decision = NavigationStackDecision(
            strategy: .navigationStack,
            reasoning: "NavigationStack recommended"
        )
        
        // When: Selecting strategy for macOS
        let strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .macOS
        )
        
        // Then: macOS should use NavigationView (NavigationStack not available on macOS)
        #expect(strategy.implementation == .navigationView, 
                "macOS should use NavigationView")
    }
    
    @Test @MainActor func testSelectNavigationStackStrategy_L3_RespectsLayer2Decision() {
        // Given: Layer 2 decision recommending split view
        let l2Decision = NavigationStackDecision(
            strategy: .splitView,
            reasoning: "Split view recommended for large content"
        )
        
        // When: Selecting strategy
        let strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .iOS
        )
        
        // Then: Should respect Layer 2 decision
        #expect(strategy.implementation == .splitView || strategy.implementation == .navigationStack,
                "Should respect Layer 2 splitView decision")
    }
    
    @Test @MainActor func testSelectNavigationStackStrategy_L3_HandlesAdaptiveStrategy() {
        // Given: Layer 2 decision with adaptive strategy
        let l2Decision = NavigationStackDecision(
            strategy: .adaptive,
            reasoning: "Adaptive strategy for complex content"
        )
        
        // When: Selecting strategy
        let strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .iOS
        )
        
        // Then: Should select appropriate implementation based on platform
        #expect(strategy.implementation != nil, "Should have an implementation for adaptive strategy")
    }
    
    @Test @MainActor func testSelectNavigationStackStrategy_L3_HandlesModalStrategy() {
        // Given: Layer 2 decision with modal strategy
        let l2Decision = NavigationStackDecision(
            strategy: .modal,
            reasoning: "Modal presentation recommended"
        )
        
        // When: Selecting strategy
        let strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .iOS
        )
        
        // Then: Should use modal implementation
        #expect(strategy.implementation == .modal, 
                "Should use modal implementation")
    }
    
    @Test @MainActor func testSelectNavigationStackStrategy_L3_ProvidesReasoning() {
        // Given: Layer 2 decision
        let l2Decision = NavigationStackDecision(
            strategy: .navigationStack,
            reasoning: "NavigationStack recommended"
        )
        
        // When: Selecting strategy
        let strategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .iOS
        )
        
        // Then: Should provide reasoning
        #expect(strategy.reasoning != nil, "Should provide reasoning")
        #expect(!strategy.reasoning!.isEmpty, "Reasoning should not be empty")
    }
    
    @Test @MainActor func testSelectNavigationStackStrategy_L3_DifferentPlatforms() {
        // Given: Layer 2 decision
        let l2Decision = NavigationStackDecision(
            strategy: .navigationStack,
            reasoning: "NavigationStack recommended"
        )
        
        // When: Selecting strategy for different platforms
        let iOSStrategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .iOS
        )
        
        let macOSStrategy = selectNavigationStackStrategy_L3(
            decision: l2Decision,
            platform: .macOS
        )
        
        // Then: Should return strategies for both platforms
        #expect(iOSStrategy.implementation != nil, "iOS should have implementation")
        #expect(macOSStrategy.implementation != nil, "macOS should have implementation")
    }
    
    // MARK: - App Navigation Strategy Selection Tests
    
    @Test @MainActor func testSelectAppNavigationStrategy_L3_SplitView_iOS16() {
        // Given: Layer 2 decision recommending split view
        let l2Decision = AppNavigationDecision(
            useSplitView: true,
            reasoning: "iPad should use split view"
        )
        
        // When: Selecting strategy for iOS 16+
        let strategy = selectAppNavigationStrategy_L3(
            decision: l2Decision,
            platform: .iOS,
            iosVersion: 16.0
        )
        
        // Then: Should use split view on iOS 16+
        #expect(strategy.implementation == .splitView, "iOS 16+ should support split view")
        #expect(strategy.reasoning.contains("Split view"), "Reasoning should mention split view")
    }
    
    @Test @MainActor func testSelectAppNavigationStrategy_L3_SplitView_iOS15_Fallback() {
        // Given: Layer 2 decision recommending split view
        let l2Decision = AppNavigationDecision(
            useSplitView: true,
            reasoning: "iPad should use split view"
        )
        
        // When: Selecting strategy for iOS 15
        let strategy = selectAppNavigationStrategy_L3(
            decision: l2Decision,
            platform: .iOS,
            iosVersion: 15.0
        )
        
        // Then: Should fallback to detail-only on iOS 15
        #expect(strategy.implementation == .detailOnly, "iOS 15 should fallback to detail-only")
        #expect(strategy.reasoning.contains("not available"), "Reasoning should mention fallback")
    }
    
    @Test @MainActor func testSelectAppNavigationStrategy_L3_SplitView_macOS() {
        // Given: Layer 2 decision recommending split view
        let l2Decision = AppNavigationDecision(
            useSplitView: true,
            reasoning: "macOS should use split view"
        )
        
        // When: Selecting strategy for macOS
        let strategy = selectAppNavigationStrategy_L3(
            decision: l2Decision,
            platform: .macOS
        )
        
        // Then: Should use split view on macOS
        #expect(strategy.implementation == .splitView, "macOS should support split view")
        #expect(strategy.reasoning.contains("macOS"), "Reasoning should mention macOS")
    }
    
    @Test @MainActor func testSelectAppNavigationStrategy_L3_DetailOnly() {
        // Given: Layer 2 decision recommending detail-only
        let l2Decision = AppNavigationDecision(
            useSplitView: false,
            reasoning: "iPhone portrait should use detail-only"
        )
        
        // When: Selecting strategy
        let strategy = selectAppNavigationStrategy_L3(
            decision: l2Decision,
            platform: .iOS
        )
        
        // Then: Should use detail-only
        #expect(strategy.implementation == .detailOnly, "Should use detail-only")
        #expect(strategy.reasoning.contains("Detail-only"), "Reasoning should mention detail-only")
    }
    
    @Test @MainActor func testSelectAppNavigationStrategy_L3_ProvidesReasoning() {
        // Given: Layer 2 decision
        let l2Decision = AppNavigationDecision(
            useSplitView: true,
            reasoning: "Test decision"
        )
        
        // When: Selecting strategy
        let strategy = selectAppNavigationStrategy_L3(
            decision: l2Decision,
            platform: .iOS
        )
        
        // Then: Should provide reasoning
        #expect(!strategy.reasoning.isEmpty, "Should provide reasoning")
    }
}

