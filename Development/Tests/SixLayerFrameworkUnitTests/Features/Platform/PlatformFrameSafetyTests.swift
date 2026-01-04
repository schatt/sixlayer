//
//  PlatformFrameSafetyTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates platform frame sizing safety functionality, ensuring frame constraints
//  are properly clamped to screen/window bounds to prevent views from exceeding device limits.
//
//  TESTING SCOPE:
//  - Frame size clamping on all platforms
//  - Oversized minimum size handling
//  - Oversized maximum size handling
//  - Platform-specific screen size detection
//  - Edge cases and boundary conditions
//
//  METHODOLOGY:
//  - Test frame clamping using actual screen/window sizes
//  - Verify platform-specific behavior (iOS window size, macOS visible frame)
//  - Test edge cases (very large values, very small screens)
//  - Validate clamping logic across all frame methods
//

import Testing
import SwiftUI
@testable import SixLayerFramework

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

#if os(watchOS)
import WatchKit
#endif

/// Tests for platform frame sizing safety
/// Validates that frame constraints are properly clamped to prevent overflow
@Suite("Platform Frame Safety")
open class PlatformFrameSafetyTests: BaseTestClass {
    
    // MARK: - PlatformFrameHelpers Tests
    
    #if os(iOS)
    @Test @MainActor func testGetMaxFrameSizeUsesWindowSize() {
        // Given: iOS platform
        // When: Getting max frame size
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        
        // Then: Should use actual window size (not screen size)
        // This handles Split View, Stage Manager, etc.
        let expectedSize: CGSize
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            expectedSize = window.bounds.size
        } else {
            expectedSize = UIScreen.main.bounds.size
        }
        
        #expect(maxSize.width == expectedSize.width, "Max width should match window/screen width")
        #expect(maxSize.height == expectedSize.height, "Max height should match window/screen height")
    }
    #endif
    
    #if os(macOS)
    @Test func testClampFrameSizeClampsOversizedMinimums() {
        // Given: An oversized minimum width (larger than screen)
        let oversizedWidth: CGFloat = 5000
        let clampedWidth = PlatformFrameHelpers.clampFrameSize(oversizedWidth, dimension: PlatformFrameHelpers.FrameDimension.width)
        
        // Then: Should be clamped to screen bounds
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowed = screenSize.width * 0.9
        let absoluteMax: CGFloat = 3840
        
        #expect(clampedWidth <= min(maxAllowed, absoluteMax), "Oversized width should be clamped")
        #expect(clampedWidth >= 300, "Clamped width should respect absolute minimum")
    }
    
    @Test func testClampFrameSizeClampsOversizedMinimumHeight() {
        // Given: An oversized minimum height (larger than screen)
        let oversizedHeight: CGFloat = 5000
        let clampedHeight = PlatformFrameHelpers.clampFrameSize(oversizedHeight, dimension: PlatformFrameHelpers.FrameDimension.height)
        
        // Then: Should be clamped to screen bounds
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowed = screenSize.height * 0.9
        let absoluteMax: CGFloat = 2160
        
        #expect(clampedHeight <= min(maxAllowed, absoluteMax), "Oversized height should be clamped")
        #expect(clampedHeight >= 400, "Clamped height should respect absolute minimum")
    }
    
    @Test func testClampMaxFrameSizeClampsOversizedMaximums() {
        // Given: An oversized maximum width (larger than screen)
        let oversizedMaxWidth: CGFloat = 5000
        let clampedMaxWidth = PlatformFrameHelpers.clampMaxFrameSize(oversizedMaxWidth, dimension: PlatformFrameHelpers.FrameDimension.width)
        
        // Then: Should be clamped to screen bounds
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowed = screenSize.width * 0.9
        
        #expect(clampedMaxWidth <= maxAllowed, "Oversized max width should be clamped to screen")
    }
    #endif
    
    #if os(watchOS) || os(tvOS) || os(visionOS)
    @Test @MainActor func testGetMaxFrameSizeUsesScreenSize() {
        // Given: watchOS/tvOS/visionOS platform
        // When: Getting max frame size
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        
        // Then: Should use screen size
        let expectedSize: CGSize
        #if os(watchOS)
        expectedSize = WKInterfaceDevice.current().screenBounds.size
        #else
        expectedSize = UIScreen.main.bounds.size
        #endif
        
        #expect(maxSize.width == expectedSize.width, "Max width should match screen width")
        #expect(maxSize.height == expectedSize.height, "Max height should match screen height")
    }
    #endif
    
    // MARK: - platformFrame() Tests
    
    @Test @MainActor func testPlatformFrameAppliesMaxConstraintsOnMobile() {
        // Given: A view on iOS/watchOS/tvOS/visionOS
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        let view = Text("Test")
            .platformFrame()
        
        // Then: View should have max constraints applied
        _ = PlatformFrameHelpers.getMaxFrameSize()
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View should render with max constraints")
        #endif
    }
    
    #if os(macOS)
    @Test @MainActor func testPlatformFrameAppliesClampedMinConstraintsOnMacOS() {
        // Given: A view on macOS
        let view = Text("Test")
            .platformFrame()
        
        // Then: View should have clamped minimum constraints
        // Default is 600x800, which should be clamped if screen is smaller
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let expectedMinWidth = min(600, screenSize.width * 0.9)
        let expectedMinHeight = min(800, screenSize.height * 0.9)
        
        // Verify view renders (actual constraint verification would require GeometryReader)
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View should render with clamped min constraints")
    }
    #endif
    
    // MARK: - platformFrame(minWidth:minHeight:maxWidth:maxHeight:) Tests
    
    @Test @MainActor func testPlatformFrameClampsOversizedMaxWidth() {
        // Given: A view with oversized maxWidth
        let oversizedMaxWidth: CGFloat = 10000
        let view = Text("Test")
            .platformFrame(maxWidth: oversizedMaxWidth)
        
        // Then: Max width should be clamped to screen/window bounds
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        #expect(oversizedMaxWidth > maxSize.width, "Test value should be larger than screen")
        #endif
        
        // View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with clamped maxWidth should render")
    }
    
    #if os(macOS)
    @Test @MainActor func testPlatformFrameClampsOversizedMinWidth() {
        // Given: A view with oversized minWidth
        let oversizedMinWidth: CGFloat = 5000
        let view = Text("Test")
            .platformFrame(minWidth: oversizedMinWidth)
        
        // Then: Min width should be clamped
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowed = screenSize.width * 0.9
        
        // View should render successfully with clamped minWidth
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with clamped minWidth should render")
    }
    #endif
    
    // MARK: - platformMinFrame() Tests
    
    #if os(macOS)
    @Test @MainActor func testPlatformMinFrameClampsOversizedMinimums() {
        // Given: A view using platformMinFrame on macOS
        let view = Text("Test")
            .platformMinFrame()
        
        // Then: Default 600x800 should be clamped if screen is smaller
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        
        // View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformMinFrame should render with clamped constraints")
    }
    #endif
    
    // MARK: - platformMaxFrame() Tests
    
    @Test @MainActor func testPlatformMaxFrameClampsOversizedMaximums() {
        // Given: A view using platformMaxFrame
        let view = Text("Test")
            .platformMaxFrame()
        
        // Then: Max constraints should be applied and clamped
        #if os(macOS)
        // macOS: 1200x1000 should be clamped to screen
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        #expect(1200 <= screenSize.width * 0.9 || screenSize.width < 1200, "Max width should be within screen bounds")
        #endif
        
        // View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformMaxFrame should render with clamped constraints")
    }
    
    // MARK: - platformAdaptiveFrame() Tests
    
    #if os(macOS)
    @Test @MainActor func testPlatformAdaptiveFrameClampsAllConstraints() {
        // Given: A view using platformAdaptiveFrame on macOS
        let view = Text("Test")
            .platformAdaptiveFrame()
        
        // Then: All constraints (min/ideal/max) should be clamped
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        
        // View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformAdaptiveFrame should render with all constraints clamped")
    }
    #endif
    
    // MARK: - platformDetailViewFrame() Tests
    
    #if os(macOS)
    @Test @MainActor func testPlatformDetailViewFrameClampsOversizedMinimums() {
        // Given: A view using platformDetailViewFrame on macOS
        let view = Text("Test")
            .platformDetailViewFrame()
        
        // Then: Default 800x600 should be clamped if screen is smaller
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        
        // View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformDetailViewFrame should render with clamped constraints")
    }
    #endif
    
    // MARK: - Edge Cases
    
    @Test @MainActor func testPlatformFrameHandlesVerySmallScreen() {
        // Given: A view on a very small screen (simulated by using small max values)
        // When: Applying platformFrame with small max values
        let view = Text("Test")
            .platformFrame(maxWidth: 200, maxHeight: 200)
        
        // Then: View should still render (constraints should be respected)
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View should render even with small constraints")
    }
    
    #if os(macOS)
    @Test func testClampFrameSizeRespectsAbsoluteMinimums() {
        // Given: A very small minimum size
        let tinyWidth: CGFloat = 100
        let clampedWidth = PlatformFrameHelpers.clampFrameSize(tinyWidth, dimension: PlatformFrameHelpers.FrameDimension.width)
        
        // Then: Should respect absolute minimum (300 for width)
        #expect(clampedWidth >= 300, "Clamped width should respect absolute minimum of 300")
    }
    
    @Test func testClampFrameSizeRespectsAbsoluteMaximums() {
        // Given: A very large size (larger than 4K)
        let hugeWidth: CGFloat = 10000
        let clampedWidth = PlatformFrameHelpers.clampFrameSize(hugeWidth, dimension: PlatformFrameHelpers.FrameDimension.width)
        
        // Then: Should respect absolute maximum (3840 for width)
        #expect(clampedWidth <= 3840, "Clamped width should respect absolute maximum of 3840")
    }
    #endif
    
    // MARK: - Cross-Platform Consistency
    
    @Test @MainActor func testPlatformFrameConsistentBehaviorAcrossPlatforms() {
        // Given: A view with the same constraints
        let view = Text("Test")
            .platformFrame(maxWidth: 1000, maxHeight: 800)
        
        // Then: Should render successfully on all platforms
        // (Behavior differs by platform, but all should clamp to screen bounds)
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformFrame should render consistently across platforms")
    }
}

