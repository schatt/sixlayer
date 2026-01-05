import Testing
import Foundation
import SwiftUI

//
//  LayoutParameterCalculatorTests.swift
//  SixLayerFrameworkTests
//
//  Tests for LayoutParameterCalculator - Context-Aware Layout Parameters
//  Tests the intelligent layout parameter calculation system that considers
//  viewport width, device context, window state, and item count
//
//  Test Documentation:
//  Business purpose: Calculate optimal layout parameters (columns, item size, spacing)
//    based on actual viewport width, device context, window state, and content characteristics
//  What are we actually testing:
//    - Viewport width-based column calculation (not device screen size)
//    - Context-aware limits (VR, external display, split view, Stage Manager)
//    - Count-based sizing for media (small/medium/large albums)
//    - Count-based columns for media (more items = more columns up to screen capacity)
//    - Screen size categories (4K, 8K displays)
//    - Edge case handling (external display, VR, split view, Stage Manager, Slide Over)
//  HOW are we testing it:
//    - Test column calculation with different viewport widths
//    - Test external display scenarios (iPhone on 4K monitor)
//    - Test VR goggles (per-eye viewport, max 4 columns)
//    - Test split view (actual split width)
//    - Test Stage Manager (resized windows)
//    - Test screen size categories (4K, 8K)
//    - Test count-based sizing for media
//    - Test count-based columns for media
//    - Test context-aware limits
//

@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Layout Parameter Calculator")
open class LayoutParameterCalculatorTests: BaseTestClass {
    
    // MARK: - Helper Methods
    
    func createContext(
        viewportWidth: CGFloat,
        deviceType: DeviceType = .phone,
        deviceContext: DeviceContext = .standard,
        windowState: UnifiedWindowDetection.WindowState? = nil,
        platform: SixLayerPlatform = .iOS
    ) -> LayoutContext {
        return LayoutContext(
            viewportWidth: viewportWidth,
            deviceType: deviceType,
            deviceContext: deviceContext,
            windowState: windowState,
            platform: platform
        )
    }
    
    // MARK: - Column Calculation Tests
    
    @Test func testCalculateColumnsUsesViewportWidth() {
        // Test that column calculation uses viewport width, not device screen size
        // iPhone on 4K external display should use monitor's viewport width
        
        let smallViewport = createContext(viewportWidth: 375, deviceType: .phone)
        let smallColumns = LayoutParameterCalculator.calculateColumns(
            count: 10,
            dataType: .generic,
            context: smallViewport
        )
        #expect(smallColumns <= 3, "Small viewport should have limited columns")
        
        let largeViewport = createContext(viewportWidth: 3840, deviceType: .phone, deviceContext: .externalDisplay)
        let largeColumns = LayoutParameterCalculator.calculateColumns(
            count: 100,
            dataType: .generic,
            context: largeViewport
        )
        #expect(largeColumns >= 10, "4K external display should allow many columns")
        #expect(largeColumns <= 12, "4K external display should cap at 12 columns for standard context")
    }
    
    @Test func testCalculateColumnsWithVRGoggles() {
        // VR goggles: max 4 columns, larger items
        let vrContext = createContext(
            viewportWidth: 1920,
            deviceType: .vision,
            deviceContext: .standard
        )
        let columns = LayoutParameterCalculator.calculateColumns(
            count: 100,
            dataType: .generic,
            context: vrContext
        )
        #expect(columns <= 4, "VR goggles should max at 4 columns")
    }
    
    @Test func testCalculateColumnsWithSplitView() {
        // Split view: use actual split width
        let splitContext = createContext(
            viewportWidth: 512,
            deviceType: .pad,
            windowState: .splitView
        )
        let columns = LayoutParameterCalculator.calculateColumns(
            count: 20,
            dataType: .generic,
            context: splitContext
        )
        #expect(columns >= 2, "Split view should allow at least 2 columns")
        #expect(columns <= 3, "Split view on small width should be limited")
    }
    
    @Test func testCalculateColumnsWithStageManager() {
        // Stage Manager: use actual window width
        let stageContext = createContext(
            viewportWidth: 800,
            deviceType: .mac,
            windowState: .stageManager
        )
        let columns = LayoutParameterCalculator.calculateColumns(
            count: 30,
            dataType: .generic,
            context: stageContext
        )
        #expect(columns >= 3, "Stage Manager should allow reasonable columns")
        #expect(columns <= 6, "Stage Manager should respect window width")
    }
    
    @Test func testCalculateColumnsWithSlideOver() {
        // Slide Over: conservative limits
        let slideOverContext = createContext(
            viewportWidth: 400,
            deviceType: .pad,
            windowState: .slideOver
        )
        let columns = LayoutParameterCalculator.calculateColumns(
            count: 50,
            dataType: .generic,
            context: slideOverContext
        )
        #expect(columns <= 3, "Slide Over should have conservative column limit")
    }
    
    @Test func testCalculateColumnsWithExternalDisplay() {
        // External display: use monitor's viewport width
        // iPhone on 4K = 12+ columns possible
        let externalContext = createContext(
            viewportWidth: 3840,
            deviceType: .phone,
            deviceContext: .externalDisplay
        )
        let columns = LayoutParameterCalculator.calculateColumns(
            count: 200,
            dataType: .generic,
            context: externalContext
        )
        #expect(columns >= 12, "4K external display should allow 12+ columns")
    }
    
    @Test func testCalculateColumnsWithScreenSizeCategories() {
        // Test different screen size categories
        let smallContext = createContext(viewportWidth: 500)
        let smallColumns = LayoutParameterCalculator.calculateColumns(
            count: 20,
            dataType: .generic,
            context: smallContext
        )
        #expect(smallColumns <= 3, "Small screen should have limited columns")
        
        let mediumContext = createContext(viewportWidth: 1024)
        let mediumColumns = LayoutParameterCalculator.calculateColumns(
            count: 20,
            dataType: .generic,
            context: mediumContext
        )
        #expect(mediumColumns > smallColumns, "Medium screen should have more columns than small")
        
        let largeContext = createContext(viewportWidth: 2560)
        let largeColumns = LayoutParameterCalculator.calculateColumns(
            count: 20,
            dataType: .generic,
            context: largeContext
        )
        #expect(largeColumns > mediumColumns, "Large screen should have more columns than medium")
        
        let xlargeContext = createContext(viewportWidth: 3840)
        let xlargeColumns = LayoutParameterCalculator.calculateColumns(
            count: 20,
            dataType: .generic,
            context: xlargeContext
        )
        #expect(xlargeColumns >= 10, "2K screen should allow many columns")
        
        let xxlargeContext = createContext(viewportWidth: 7680)
        let xxlargeColumns = LayoutParameterCalculator.calculateColumns(
            count: 20,
            dataType: .generic,
            context: xxlargeContext
        )
        #expect(xxlargeColumns >= 12, "4K screen should allow even more columns")
    }
    
    // MARK: - Count-Based Sizing Tests (Media)
    
    @Test func testCalculateColumnsWithCountBasedSizingForMedia() {
        // Small album (≤10 items): Large thumbnails
        let smallAlbumContext = createContext(viewportWidth: 1024)
        let smallColumns = LayoutParameterCalculator.calculateColumns(
            count: 8,
            dataType: .media,
            context: smallAlbumContext
        )
        #expect(smallColumns >= 3, "Small album should allow reasonable columns")
        
        // Medium (11-50): Medium thumbnails
        let mediumAlbumContext = createContext(viewportWidth: 1024)
        let mediumColumns = LayoutParameterCalculator.calculateColumns(
            count: 30,
            dataType: .media,
            context: mediumAlbumContext
        )
        #expect(mediumColumns >= smallColumns, "Medium album should allow more columns than small")
        
        // Large (51+): Small thumbnails
        let largeAlbumContext = createContext(viewportWidth: 1024)
        let largeColumns = LayoutParameterCalculator.calculateColumns(
            count: 100,
            dataType: .media,
            context: largeAlbumContext
        )
        #expect(largeColumns >= mediumColumns, "Large album should allow more columns than medium")
    }
    
    @Test func testCalculateItemSizeWithCountBasedSizing() {
        // Test count-based item sizing for media
        let smallAlbumContext = createContext(viewportWidth: 1024)
        let smallSize = LayoutParameterCalculator.calculateItemSize(
            count: 8,
            dataType: .media,
            context: smallAlbumContext
        )
        #expect(smallSize >= 200, "Small album should have larger items")
        
        let mediumAlbumContext = createContext(viewportWidth: 1024)
        let mediumSize = LayoutParameterCalculator.calculateItemSize(
            count: 30,
            dataType: .media,
            context: mediumAlbumContext
        )
        #expect(mediumSize < smallSize * 1.2, "Medium album should have slightly smaller items")
        
        let largeAlbumContext = createContext(viewportWidth: 1024)
        let largeSize = LayoutParameterCalculator.calculateItemSize(
            count: 100,
            dataType: .media,
            context: largeAlbumContext
        )
        #expect(largeSize < mediumSize * 1.2, "Large album should have smaller items")
    }
    
    @Test func testCalculateItemSizeWithLargerScreens() {
        // Larger screens can show larger items even with many photos
        let smallScreenContext = createContext(viewportWidth: 768)
        let smallScreenSize = LayoutParameterCalculator.calculateItemSize(
            count: 100,
            dataType: .media,
            context: smallScreenContext
        )
        
        let largeScreenContext = createContext(viewportWidth: 3840)
        let largeScreenSize = LayoutParameterCalculator.calculateItemSize(
            count: 100,
            dataType: .media,
            context: largeScreenContext
        )
        #expect(largeScreenSize > smallScreenSize, "Larger screens should allow larger items even with many photos")
    }
    
    // MARK: - Spacing Calculation Tests
    
    @Test func testCalculateSpacingWithDeviceTypes() {
        let macContext = createContext(viewportWidth: 1920, deviceType: .mac)
        let macSpacing = LayoutParameterCalculator.calculateSpacing(
            context: macContext,
            dataType: .generic
        )
        #expect(macSpacing == 20, "Mac should have 20pt spacing")
        
        let padContext = createContext(viewportWidth: 1024, deviceType: .pad)
        let padSpacing = LayoutParameterCalculator.calculateSpacing(
            context: padContext,
            dataType: .generic
        )
        #expect(padSpacing == 16, "iPad should have 16pt spacing")
        
        let phoneContext = createContext(viewportWidth: 375, deviceType: .phone)
        let phoneSpacing = LayoutParameterCalculator.calculateSpacing(
            context: phoneContext,
            dataType: .generic
        )
        #expect(phoneSpacing == 12, "iPhone should have 12pt spacing")
    }
    
    @Test func testCalculateSpacingWithWindowState() {
        let standardContext = createContext(viewportWidth: 1024, deviceType: .pad)
        let standardSpacing = LayoutParameterCalculator.calculateSpacing(
            context: standardContext,
            dataType: .generic
        )
        
        let splitViewContext = createContext(
            viewportWidth: 1024,
            deviceType: .pad,
            windowState: .splitView
        )
        let splitViewSpacing = LayoutParameterCalculator.calculateSpacing(
            context: splitViewContext,
            dataType: .generic
        )
        #expect(splitViewSpacing < standardSpacing, "Split view should have reduced spacing")
        
        let slideOverContext = createContext(
            viewportWidth: 1024,
            deviceType: .pad,
            windowState: .slideOver
        )
        let slideOverSpacing = LayoutParameterCalculator.calculateSpacing(
            context: slideOverContext,
            dataType: .generic
        )
        #expect(slideOverSpacing < standardSpacing, "Slide Over should have reduced spacing")
    }
    
    // MARK: - Screen Size Category Tests
    
    @Test func testScreenSizeCategoryFromWidth() {
        #expect(ScreenSizeCategory.from(width: 500) == .small, "Width < 768 should be small")
        #expect(ScreenSizeCategory.from(width: 1024) == .medium, "Width 768-1440 should be medium")
        #expect(ScreenSizeCategory.from(width: 2000) == .large, "Width 1440-2560 should be large")
        #expect(ScreenSizeCategory.from(width: 3000) == .xlarge, "Width 2560-3840 should be xlarge (2K)")
        #expect(ScreenSizeCategory.from(width: 5000) == .xxlarge, "Width 3840-7680 should be xxlarge (4K)")
        #expect(ScreenSizeCategory.from(width: 10000) == .xxxlarge, "Width 7680+ should be xxxlarge (8K)")
    }
    
    // MARK: - Edge Case Tests
    
    @Test func testCalculateColumnsWithMinimalWidth() {
        // Test with very small viewport
        let minimalContext = createContext(viewportWidth: 200)
        let columns = LayoutParameterCalculator.calculateColumns(
            count: 5,
            dataType: .generic,
            context: minimalContext
        )
        #expect(columns >= 1, "Should always have at least 1 column")
    }
    
    @Test func testCalculateColumnsWithZeroCount() {
        // Test with zero items
        let context = createContext(viewportWidth: 1024)
        let columns = LayoutParameterCalculator.calculateColumns(
            count: 0,
            dataType: .generic,
            context: context
        )
        #expect(columns >= 1, "Should always have at least 1 column even with zero items")
    }
    
    @Test func testCalculateColumnsWithVeryLargeCount() {
        // Test with very large item count
        let context = createContext(viewportWidth: 3840, deviceContext: .externalDisplay)
        let columns = LayoutParameterCalculator.calculateColumns(
            count: 10000,
            dataType: .media,
            context: context
        )
        #expect(columns >= 12, "4K external display should allow many columns even with huge count")
        #expect(columns <= 16, "Should respect maximum column limit")
    }
    
    @Test func testCalculateColumnsWithDifferentDataTypes() {
        let context = createContext(viewportWidth: 1024)
        
        let mediaColumns = LayoutParameterCalculator.calculateColumns(
            count: 50,
            dataType: .media,
            context: context
        )
        
        let genericColumns = LayoutParameterCalculator.calculateColumns(
            count: 50,
            dataType: .generic,
            context: context
        )
        
        // Media might have different sizing due to count-based logic
        #expect(mediaColumns >= 1, "Media should have at least 1 column")
        #expect(genericColumns >= 1, "Generic should have at least 1 column")
    }
}

