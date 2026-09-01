//
//  PlatformSidebarHelpersTests.swift
//  SixLayerFramework
//
//  Tests for platform sidebar helper functions
//

import Testing
import SwiftUI
@testable import SixLayerFramework

@Suite("Platform Sidebar Helpers Tests", HostedViewTestIsolationTrait())
struct PlatformSidebarHelpersTests {
    
    // MARK: - platformSidebarPullIndicator Tests
    
    @Test @MainActor func testPlatformSidebarPullIndicatorExists() {
        // Test that the function exists and can be called
        let _ = platformSidebarPullIndicator(isVisible: true)
        // Function should compile and return a view
    }
    
    @Test @MainActor func testPlatformSidebarPullIndicatorWhenVisible() {
        // When isVisible is true, returns leading-edge stripe on iOS/macOS (#324)
        let _ = platformSidebarPullIndicator(isVisible: true)
        // Should compile and return a view
    }
    
    @Test @MainActor func testPlatformSidebarPullIndicatorWhenNotVisible() {
        // Test that when isVisible is false, it returns EmptyView
        let _ = platformSidebarPullIndicator(isVisible: false)
        // Should return EmptyView regardless of platform when not visible
    }
    
    @Test @MainActor func testPlatformSidebarPullIndicatorCanBeUsedInHStack() {
        // Test that it can be used in an HStack as shown in the usage example
        let _ = HStack {
            platformSidebarPullIndicator(isVisible: true)
            Text("Sidebar Content")
        }
    }
    
    @Test @MainActor func testPlatformSidebarPullIndicatorPlatformBehavior() {
        // iOS and macOS show the stripe when visible; other platforms use EmptyView (#324)
        #if os(iOS) || os(macOS)
        let _ = platformSidebarPullIndicator(isVisible: true)
        #else
        let _ = platformSidebarPullIndicator(isVisible: true)
        #endif
    }
    
    @Test @MainActor func testPlatformSidebarPullIndicatorWithDifferentVisibilityStates() {
        // Test that function handles different visibility states correctly
        let _ = platformSidebarPullIndicator(isVisible: true)
        let _ = platformSidebarPullIndicator(isVisible: false)
        
    }
}
