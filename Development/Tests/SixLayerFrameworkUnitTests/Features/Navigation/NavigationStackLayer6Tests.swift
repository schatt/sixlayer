import Testing
import SwiftUI

//
//  NavigationStackLayer6Tests.swift
//  SixLayerFrameworkTests
//
//  Layer 6 (Platform System) TDD Tests for NavigationStack
//  Tests for platform-specific NavigationStack enhancements
//
//  Test Documentation:
//  Business purpose: Apply platform-specific enhancements to NavigationStack
//  What are we actually testing:
//    - iOS-specific navigation enhancements (haptics, gestures, etc.)
//    - macOS-specific navigation enhancements (keyboard navigation, etc.)
//    - Platform-specific accessibility features
//    - Platform-specific UI patterns
//  HOW are we testing it:
//    - Test that platform enhancements are applied
//    - Test iOS-specific features on iOS
//    - Test macOS-specific features on macOS
//    - Test that enhancements don't break functionality
//

@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("NavigationStack Layer 6")
open class NavigationStackLayer6Tests: BaseTestClass {
    
    // MARK: - Test Data
    
    // MARK: - platformNavigationStackEnhancements_L6 Tests
    
    @Test @MainActor func testPlatformNavigationStackEnhancements_L6_AppliesEnhancements() {
        // Given: A navigation stack view
        let content = Text("Test Content")
            .platformNavigation_L4 {
                Text("Content")
            }
        
        // When: Applying platform enhancements
        let view = content
            .platformNavigationStackEnhancements_L6()
        
        expectL6EnhancementApplied(view)
    }
    
    @Test @MainActor func testPlatformNavigationStackEnhancements_L6_PlatformSpecific() {
        // Given: A navigation stack view
        let content = Text("Test Content")
            .platformNavigation_L4 {
                Text("Content")
            }
        
        // When: Applying platform enhancements
        let view = content
            .platformNavigationStackEnhancements_L6()
        
        expectL6EnhancementApplied(view)
    }
    
    @Test @MainActor func testPlatformNavigationStackEnhancements_L6_Accessibility() {
        // Given: A navigation stack view
        let content = Text("Test Content")
            .platformNavigation_L4 {
                Text("Content")
            }
        
        // When: Applying accessibility enhancements
        let view = content
            .platformNavigationStackEnhancements_L6()
        
        expectL6EnhancementApplied(view)
    }
    
    @Test @MainActor func testPlatformNavigationStackEnhancements_L6_WorksWithLayer1() {
        // Given: A Layer 1 navigation stack
        let hints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .navigation,
            complexity: .simple,
            context: .navigation
        )
        
        let view = platformPresentNavigationStack_L1(
            content: Text("Test"),
            hints: hints
        )
        
        // When: Applying Layer 6 enhancements
        let enhanced = view
            .platformNavigationStackEnhancements_L6()
        
        expectL6EnhancementApplied(enhanced)
    }
    
    @MainActor
    private func expectL6EnhancementApplied(_ view: some View) {
        #if os(macOS)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_FocusableModifier")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "AccessibilityAttachmentModifier")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_FlexFrameLayout")
        #elseif os(iOS)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "AccessibilityAttachmentModifier")
        #else
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)
        #expect(
            !description.contains("_FocusableModifier"),
            "L6 is a pass-through off iOS/macOS, got: \(description)"
        )
        #endif
    }
}
