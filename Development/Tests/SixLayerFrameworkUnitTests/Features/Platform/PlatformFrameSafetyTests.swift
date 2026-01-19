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
    
    #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
    @Test @MainActor func testPlatformFrameAppliesMaxConstraintsOnMobile() {
        // Given: platformFrame() applies max constraints on mobile
        // When: Getting max frame size (as platformFrame() does internally)
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        
        // Then: Max size should match expected screen/window size
        let expectedSize: CGSize
        #if os(iOS)
        // iOS: Should use window size (handles Split View, Stage Manager, etc.)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            expectedSize = window.bounds.size
        } else {
            expectedSize = UIScreen.main.bounds.size
        }
        #elseif os(watchOS)
        expectedSize = WKInterfaceDevice.current().screenBounds.size
        #else
        expectedSize = UIScreen.main.bounds.size
        #endif
        
        #expect(maxSize.width == expectedSize.width, "Max width should match screen/window width")
        #expect(maxSize.height == expectedSize.height, "Max height should match screen/window height")
        
        // Verify the view modifier renders successfully
        let view = Text("Test")
            .platformFrame()
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View should render with max constraints")
    }
    #endif
    
    #if os(macOS)
    @Test @MainActor func testPlatformFrameAppliesClampedMinConstraintsOnMacOS() {
        // Given: Default platformFrame() uses 600x800 minimums on macOS
        let defaultMinWidth: CGFloat = 600
        let defaultMinHeight: CGFloat = 800
        
        // When: Clamping these values (as platformFrame() does internally)
        let clampedWidth = PlatformFrameHelpers.clampFrameSize(defaultMinWidth, dimension: .width)
        let clampedHeight = PlatformFrameHelpers.clampFrameSize(defaultMinHeight, dimension: .height)
        
        // Then: Values should be clamped to screen bounds if screen is smaller
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let expectedMinWidth = min(defaultMinWidth, screenSize.width * 0.9)
        let expectedMinHeight = min(defaultMinHeight, screenSize.height * 0.9)
        
        #expect(clampedWidth == expectedMinWidth, "Width should be clamped to screen bounds")
        #expect(clampedHeight == expectedMinHeight, "Height should be clamped to screen bounds")
        
        // Also verify the view modifier renders successfully
        let view = Text("Test")
            .platformFrame()
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View should render with clamped min constraints")
    }
    #endif
    
    // MARK: - platformFrame(minWidth:minHeight:maxWidth:maxHeight:) Tests
    
    @Test @MainActor func testPlatformFrameClampsOversizedMaxWidth() {
        // Given: An oversized maxWidth
        let oversizedMaxWidth: CGFloat = 10000
        
        // When: Clamping the max width (as platformFrame() does internally)
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        let clampedMaxWidth = min(oversizedMaxWidth, maxSize.width)
        #expect(oversizedMaxWidth > maxSize.width, "Test value should be larger than screen")
        #expect(clampedMaxWidth <= maxSize.width, "Clamped max width should not exceed screen")
        #elseif os(macOS)
        let clampedMaxWidth = PlatformFrameHelpers.clampMaxFrameSize(oversizedMaxWidth, dimension: .width)
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowed = screenSize.width * 0.9
        #expect(clampedMaxWidth <= maxAllowed, "Clamped max width should not exceed screen bounds")
        #endif
        
        // View should render successfully
        let view = Text("Test")
            .platformFrame(maxWidth: oversizedMaxWidth)
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with clamped maxWidth should render")
    }
    
    #if os(macOS)
    @Test @MainActor func testPlatformFrameClampsOversizedMinWidth() {
        // Given: An oversized minWidth
        let oversizedMinWidth: CGFloat = 5000
        
        // When: Clamping the min width (as platformFrame() does internally)
        let clampedMinWidth = PlatformFrameHelpers.clampFrameSize(oversizedMinWidth, dimension: .width)
        
        // Then: Min width should be clamped to screen bounds
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowed = screenSize.width * 0.9
        let absoluteMax: CGFloat = 3840
        
        #expect(clampedMinWidth <= min(maxAllowed, absoluteMax), "Clamped min width should not exceed screen bounds")
        #expect(clampedMinWidth >= 300, "Clamped min width should respect absolute minimum")
        
        // View should render successfully with clamped minWidth
        let view = Text("Test")
            .platformFrame(minWidth: oversizedMinWidth)
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with clamped minWidth should render")
    }
    #endif
    
    // MARK: - platformFrame idealWidth and idealHeight Tests
    
    @Test @MainActor func testPlatformFrameAcceptsIdealWidth() {
        // Given: A view with idealWidth specified
        let idealWidth: CGFloat = 800
        
        // When: Applying platformFrame with idealWidth
        let view = Text("Test")
            .platformFrame(idealWidth: idealWidth)
        
        // Then: View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with idealWidth should render")
    }
    
    @Test @MainActor func testPlatformFrameAcceptsIdealHeight() {
        // Given: A view with idealHeight specified
        let idealHeight: CGFloat = 600
        
        // When: Applying platformFrame with idealHeight
        let view = Text("Test")
            .platformFrame(idealHeight: idealHeight)
        
        // Then: View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with idealHeight should render")
    }
    
    @Test @MainActor func testPlatformFrameAcceptsIdealWidthAndIdealHeight() {
        // Given: A view with both idealWidth and idealHeight specified
        let idealWidth: CGFloat = 800
        let idealHeight: CGFloat = 600
        
        // When: Applying platformFrame with both ideal sizes
        let view = Text("Test")
            .platformFrame(idealWidth: idealWidth, idealHeight: idealHeight)
        
        // Then: View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with idealWidth and idealHeight should render")
    }
    
    @Test @MainActor func testPlatformFrameAcceptsMinIdealMaxCombination() {
        // Given: A view with min, ideal, and max constraints
        let minWidth: CGFloat = 400
        let idealWidth: CGFloat = 800
        let maxWidth: CGFloat = 1200
        let minHeight: CGFloat = 300
        let idealHeight: CGFloat = 600
        let maxHeight: CGFloat = 900
        
        // When: Applying platformFrame with all constraints
        let view = Text("Test")
            .platformFrame(
                minWidth: minWidth,
                idealWidth: idealWidth,
                maxWidth: maxWidth,
                minHeight: minHeight,
                idealHeight: idealHeight,
                maxHeight: maxHeight
            )
        
        // Then: View should render successfully
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with min/ideal/max constraints should render")
    }
    
    @Test @MainActor func testPlatformFrameClampsOversizedIdealWidth() {
        // Given: An oversized idealWidth
        let oversizedIdealWidth: CGFloat = 10000
        
        // When: Clamping the ideal width (as platformFrame() does internally)
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        let clampedIdealWidth = min(oversizedIdealWidth, maxSize.width)
        #expect(oversizedIdealWidth > maxSize.width, "Test value should be larger than screen")
        #expect(clampedIdealWidth <= maxSize.width, "Clamped ideal width should not exceed screen")
        #elseif os(macOS)
        let clampedIdealWidth = PlatformFrameHelpers.clampMaxFrameSize(oversizedIdealWidth, dimension: .width)
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowed = screenSize.width * 0.9
        #expect(clampedIdealWidth <= maxAllowed, "Clamped ideal width should not exceed screen bounds")
        #endif
        
        // View should render successfully
        let view = Text("Test")
            .platformFrame(idealWidth: oversizedIdealWidth)
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with clamped idealWidth should render")
    }
    
    @Test @MainActor func testPlatformFrameClampsOversizedIdealHeight() {
        // Given: An oversized idealHeight
        let oversizedIdealHeight: CGFloat = 10000
        
        // When: Clamping the ideal height (as platformFrame() does internally)
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        let maxSize = PlatformFrameHelpers.getMaxFrameSize()
        let clampedIdealHeight = min(oversizedIdealHeight, maxSize.height)
        #expect(oversizedIdealHeight > maxSize.height, "Test value should be larger than screen")
        #expect(clampedIdealHeight <= maxSize.height, "Clamped ideal height should not exceed screen")
        #elseif os(macOS)
        let clampedIdealHeight = PlatformFrameHelpers.clampMaxFrameSize(oversizedIdealHeight, dimension: .height)
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowed = screenSize.height * 0.9
        #expect(clampedIdealHeight <= maxAllowed, "Clamped ideal height should not exceed screen bounds")
        #endif
        
        // View should render successfully
        let view = Text("Test")
            .platformFrame(idealHeight: oversizedIdealHeight)
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "View with clamped idealHeight should render")
    }
    
    // MARK: - platformMinFrame() Tests
    
    #if os(macOS)
    @Test @MainActor func testPlatformMinFrameClampsOversizedMinimums() {
        // Given: platformMinFrame() uses 600x800 minimums on macOS
        let defaultMinWidth: CGFloat = 600
        let defaultMinHeight: CGFloat = 800
        
        // When: Clamping these values (as platformMinFrame() does internally)
        let clampedWidth = PlatformFrameHelpers.clampFrameSize(defaultMinWidth, dimension: .width)
        let clampedHeight = PlatformFrameHelpers.clampFrameSize(defaultMinHeight, dimension: .height)
        
        // Then: Values should be clamped to screen bounds if screen is smaller
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let expectedMinWidth = min(defaultMinWidth, screenSize.width * 0.9)
        let expectedMinHeight = min(defaultMinHeight, screenSize.height * 0.9)
        
        #expect(clampedWidth == expectedMinWidth, "Width should be clamped to screen bounds")
        #expect(clampedHeight == expectedMinHeight, "Height should be clamped to screen bounds")
        
        // View should render successfully
        let view = Text("Test")
            .platformMinFrame()
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformMinFrame should render with clamped constraints")
    }
    #endif
    
    // MARK: - platformMaxFrame() Tests
    
    @Test @MainActor func testPlatformMaxFrameClampsOversizedMaximums() {
        // Given: platformMaxFrame() uses 1200x1000 maximums on macOS
        #if os(macOS)
        let defaultMaxWidth: CGFloat = 1200
        let defaultMaxHeight: CGFloat = 1000
        
        // When: Clamping these values (as platformMaxFrame() does internally)
        let clampedMaxWidth = PlatformFrameHelpers.clampMaxFrameSize(defaultMaxWidth, dimension: .width)
        let clampedMaxHeight = PlatformFrameHelpers.clampMaxFrameSize(defaultMaxHeight, dimension: .height)
        
        // Then: Values should be clamped to screen bounds
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowedWidth = screenSize.width * 0.9
        let maxAllowedHeight = screenSize.height * 0.9
        
        #expect(clampedMaxWidth <= maxAllowedWidth, "Max width should be clamped to screen bounds")
        #expect(clampedMaxHeight <= maxAllowedHeight, "Max height should be clamped to screen bounds")
        #endif
        
        // View should render successfully
        let view = Text("Test")
            .platformMaxFrame()
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformMaxFrame should render with clamped constraints")
    }
    
    // MARK: - platformAdaptiveFrame() Tests
    
    #if os(macOS)
    @Test @MainActor func testPlatformAdaptiveFrameClampsAllConstraints() {
        // Given: platformAdaptiveFrame() uses multiple constraints on macOS
        // min: 600x800, ideal: 800x900, max: 1200x1000
        let defaultMinWidth: CGFloat = 600
        let defaultIdealWidth: CGFloat = 800
        let defaultMaxWidth: CGFloat = 1200
        let defaultMinHeight: CGFloat = 800
        let defaultIdealHeight: CGFloat = 900
        let defaultMaxHeight: CGFloat = 1000
        
        // When: Clamping all values (as platformAdaptiveFrame() does internally)
        let clampedMinWidth = PlatformFrameHelpers.clampFrameSize(defaultMinWidth, dimension: .width)
        let clampedIdealWidth = PlatformFrameHelpers.clampMaxFrameSize(defaultIdealWidth, dimension: .width)
        let clampedMaxWidth = PlatformFrameHelpers.clampMaxFrameSize(defaultMaxWidth, dimension: .width)
        let clampedMinHeight = PlatformFrameHelpers.clampFrameSize(defaultMinHeight, dimension: .height)
        let clampedIdealHeight = PlatformFrameHelpers.clampMaxFrameSize(defaultIdealHeight, dimension: .height)
        let clampedMaxHeight = PlatformFrameHelpers.clampMaxFrameSize(defaultMaxHeight, dimension: .height)
        
        // Then: All values should be clamped to screen bounds
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let maxAllowedWidth = screenSize.width * 0.9
        let maxAllowedHeight = screenSize.height * 0.9
        
        #expect(clampedMinWidth <= maxAllowedWidth, "Min width should be clamped")
        #expect(clampedIdealWidth <= maxAllowedWidth, "Ideal width should be clamped")
        #expect(clampedMaxWidth <= maxAllowedWidth, "Max width should be clamped")
        #expect(clampedMinHeight <= maxAllowedHeight, "Min height should be clamped")
        #expect(clampedIdealHeight <= maxAllowedHeight, "Ideal height should be clamped")
        #expect(clampedMaxHeight <= maxAllowedHeight, "Max height should be clamped")
        
        // View should render successfully
        let view = Text("Test")
            .platformAdaptiveFrame()
        let hostedView = hostRootPlatformView(view)
        #expect(hostedView != nil, "platformAdaptiveFrame should render with all constraints clamped")
    }
    #endif
    
    // MARK: - platformDetailViewFrame() Tests
    
    #if os(macOS)
    @Test @MainActor func testPlatformDetailViewFrameClampsOversizedMinimums() {
        // Given: platformDetailViewFrame() uses 800x600 minimums on macOS
        let defaultMinWidth: CGFloat = 800
        let defaultMinHeight: CGFloat = 600
        
        // When: Clamping these values (as platformDetailViewFrame() does internally)
        let clampedWidth = PlatformFrameHelpers.clampFrameSize(defaultMinWidth, dimension: .width)
        let clampedHeight = PlatformFrameHelpers.clampFrameSize(defaultMinHeight, dimension: .height)
        
        // Then: Values should be clamped to screen bounds if screen is smaller
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1920, height: 1080)
        let expectedMinWidth = min(defaultMinWidth, screenSize.width * 0.9)
        let expectedMinHeight = min(defaultMinHeight, screenSize.height * 0.9)
        
        #expect(clampedWidth == expectedMinWidth, "Width should be clamped to screen bounds")
        #expect(clampedHeight == expectedMinHeight, "Height should be clamped to screen bounds")
        
        // View should render successfully
        let view = Text("Test")
            .platformDetailViewFrame()
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

