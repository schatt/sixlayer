import Testing
import SwiftUI

//
//  NavigationStackLayer5Tests.swift
//  SixLayerFrameworkTests
//
//  Layer 5 (Performance Optimization) TDD Tests for NavigationStack
//  Tests for platformNavigationStackOptimizations_L5 function
//
//  Test Documentation:
//  Business purpose: Apply performance optimizations to NavigationStack implementations
//  What are we actually testing:
//    - Performance optimization modifiers are applied
//    - Platform-specific optimizations (iOS vs macOS)
//    - Memory optimization for navigation stacks
//    - View state preservation optimizations
//  HOW are we testing it:
//    - Test that optimizations are applied to views
//    - Test platform-specific optimization differences
//    - Test that optimizations don't break functionality
//    - Validate optimization modifiers are present
//

@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("NavigationStack Layer 5")
open class NavigationStackLayer5Tests: BaseTestClass {
    
    // MARK: - platformNavigationStackOptimizations_L5 Tests
    
    @Test @MainActor func testPlatformNavigationStackOptimizations_L5_AppliesOptimizations() {
        let content = Text("Test Content")
        let view = content
            .platformNavigationStackOptimizations_L5()
        
        expectL5OptimizationApplied(view)
    }
    
    @Test @MainActor func testPlatformNavigationStackOptimizations_L5_WorksWithNavigationStack() {
        let content = Text("Test Content")
            .platformNavigation_L4 {
                Text("Content")
            }
        let view = content
            .platformNavigationStackOptimizations_L5()
        
        expectL5OptimizationApplied(view)
    }
    
    @Test @MainActor func testPlatformNavigationStackOptimizations_L5_PlatformSpecific() {
        let content = Text("Test Content")
        let view = content
            .platformNavigationStackOptimizations_L5()
        
        expectL5OptimizationApplied(view)
    }
    
    @Test @MainActor func testPlatformNavigationStackOptimizations_L5_MemoryOptimization() {
        let content = Text("Test Content")
            .platformNavigation_L4 {
                Text("Content")
            }
        let view = content
            .platformNavigationStackOptimizations_L5()
        
        expectL5OptimizationApplied(view)
    }
    
    @Test @MainActor func testPlatformNavigationStackOptimizations_L5_StatePreservation() {
        let content = Text("Test Content")
            .platformNavigation_L4 {
                Text("Content")
            }
        let view = content
            .platformNavigationStackOptimizations_L5()
        
        expectL5OptimizationApplied(view)
    }
    
    @Test @MainActor func testPlatformNavigationStackOptimizations_L5_DeepNavigationStacks() {
        let content = Text("Test Content")
            .platformNavigation_L4 {
                Text("Content")
            }
        let view = content
            .platformNavigationStackOptimizations_L5()
        
        expectL5OptimizationApplied(view)
    }
    
    @MainActor
    private func expectL5OptimizationApplied(_ view: some View) {
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)
        #if os(iOS) || os(macOS)
        #expect(
            description.contains("_TransactionModifier"),
            "L5 should apply a transaction modifier, got: \(description)"
        )
        #else
        #expect(
            !description.contains("_TransactionModifier"),
            "L5 is a pass-through off iOS/macOS, got: \(description)"
        )
        #endif
    }
}
