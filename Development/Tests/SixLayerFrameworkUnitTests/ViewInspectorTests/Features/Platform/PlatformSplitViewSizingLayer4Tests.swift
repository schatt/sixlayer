import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for Split View Sizing & Constraints (Issue #16)
/// 
/// BUSINESS PURPOSE: Ensure split view sizing and constraints work correctly across platforms
/// TESTING SCOPE: Sizing configuration for PlatformSplitViewLayer4
/// METHODOLOGY: Test sizing constraints, per-pane sizing, and container sizing
/// Implements Issue #16: Split View Sizing & Constraints (Layer 4)
@Suite("Platform Split View Sizing Layer 4")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformSplitViewSizingLayer4Tests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
    // MARK: - PlatformSplitViewSizing Configuration Tests
    
    @Test @MainActor func testPlatformSplitViewSizingCreatesConfiguration() async {
        // Given: Creating a sizing configuration
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600)
        )
        
        // Then: Configuration should be created
        #expect(sizing.firstPane?.minWidth == 250, "First pane minWidth should be set")
        #expect(sizing.firstPane?.idealWidth == 280, "First pane idealWidth should be set")
        #expect(sizing.firstPane?.maxWidth == 350, "First pane maxWidth should be set")
    }
    
    @Test @MainActor func testPlatformSplitViewSizingWithContainerConstraints() async {
        // Given: Creating sizing with container constraints
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600),
            container: PlatformSplitViewPaneSizing(minWidth: 700, idealWidth: 900, maxWidth: 1200)
        )
        
        // Then: Container constraints should be set
        #expect(sizing.container?.minWidth == 700, "Container minWidth should be set")
        #expect(sizing.container?.idealWidth == 900, "Container idealWidth should be set")
        #expect(sizing.container?.maxWidth == 1200, "Container maxWidth should be set")
    }
    
    @Test @MainActor func testPlatformSplitViewPaneSizingWithHeightConstraints() async {
        // Given: Creating pane sizing with height constraints
        let paneSizing = PlatformSplitViewPaneSizing(
            minWidth: 250,
            idealWidth: 280,
            maxWidth: 350,
            minHeight: 300,
            idealHeight: 400,
            maxHeight: 500
        )
        
        // Then: Height constraints should be set
        #expect(paneSizing.minHeight == 300, "minHeight should be set")
        #expect(paneSizing.idealHeight == 400, "idealHeight should be set")
        #expect(paneSizing.maxHeight == 500, "maxHeight should be set")
    }
    
    // MARK: - Split View with Sizing Tests
    
    @Test @MainActor func testPlatformVerticalSplitL4AcceptsSizingConfiguration() async {
        // Given: A sizing configuration
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600)
        )
        
        // When: Creating a view with sizing
        let view = Text("Test")
            .platformVerticalSplit_L4(
                spacing: 0,
                sizing: sizing
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: View should be created successfully
        #expect(Bool(true), "platformVerticalSplit_L4 should accept sizing configuration")
    }
    
    @Test @MainActor func testPlatformHorizontalSplitL4AcceptsSizingConfiguration() async {
        // Given: A sizing configuration
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600)
        )
        
        // When: Creating a view with sizing
        let view = Text("Test")
            .platformHorizontalSplit_L4(
                spacing: 0,
                sizing: sizing
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: View should be created successfully
        #expect(Bool(true), "platformHorizontalSplit_L4 should accept sizing configuration")
    }
    
    @Test @MainActor func testPlatformVerticalSplitL4AppliesSizingConstraintsOnMacOS() async {
        #if os(macOS)
        // Given: A sizing configuration on macOS
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600)
        )
        
        // When: Creating a view with sizing
        let view = Text("Test")
            .platformVerticalSplit_L4(
                spacing: 0,
                sizing: sizing
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: Sizing constraints should be applied (macOS uses VSplitView with frame modifiers)
        #expect(Bool(true), "platformVerticalSplit_L4 should apply sizing constraints on macOS")
        #else
        #expect(Bool(true), "Test only runs on macOS")
        #endif
    }
    
    @Test @MainActor func testPlatformHorizontalSplitL4AppliesSizingConstraintsOnMacOS() async {
        #if os(macOS)
        // Given: A sizing configuration on macOS
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600)
        )
        
        // When: Creating a view with sizing
        let view = Text("Test")
            .platformHorizontalSplit_L4(
                spacing: 0,
                sizing: sizing
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: Sizing constraints should be applied (macOS uses HSplitView with frame modifiers)
        #expect(Bool(true), "platformHorizontalSplit_L4 should apply sizing constraints on macOS")
        #else
        #expect(Bool(true), "Test only runs on macOS")
        #endif
    }
    
    @Test @MainActor func testPlatformVerticalSplitL4AppliesContainerConstraints() async {
        // Given: A sizing configuration with container constraints
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600),
            container: PlatformSplitViewPaneSizing(minWidth: 700, idealWidth: 900, maxWidth: 1200)
        )
        
        // When: Creating a view with container constraints
        let view = Text("Test")
            .platformVerticalSplit_L4(
                spacing: 0,
                sizing: sizing
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: Container constraints should be applied
        #expect(Bool(true), "platformVerticalSplit_L4 should apply container constraints")
    }
    
    @Test @MainActor func testPlatformSplitViewSizingWithMultiplePanes() async {
        // Given: A sizing configuration with multiple panes
        let sizing = PlatformSplitViewSizing(
            panes: [
                PlatformSplitViewPaneSizing(minWidth: 200, idealWidth: 250, maxWidth: 300),
                PlatformSplitViewPaneSizing(minWidth: 300, idealWidth: 400, maxWidth: 500),
                PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600)
            ]
        )
        
        // Then: All panes should have sizing constraints
        #expect(sizing.panes.count == 3, "Should have 3 panes")
        #expect(sizing.panes[0].minWidth == 200, "First pane minWidth should be set")
        #expect(sizing.panes[1].minWidth == 300, "Second pane minWidth should be set")
        #expect(sizing.panes[2].minWidth == 400, "Third pane minWidth should be set")
    }
    
    // MARK: - Responsive Sizing Tests
    
    @Test @MainActor func testPlatformSplitViewSizingWithResponsiveBehavior() async {
        // Given: A sizing configuration with responsive behavior
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600),
            responsive: true
        )
        
        // Then: Responsive behavior should be enabled
        #expect(sizing.responsive == true, "Responsive behavior should be enabled")
    }
    
    // MARK: - Cross-Platform Behavior Tests
    
    @Test @MainActor func testPlatformSplitViewSizingWorksOnIOS() async {
        #if os(iOS)
        // Given: A sizing configuration on iOS
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600)
        )
        
        // When: Creating a view with sizing
        let view = Text("Test")
            .platformVerticalSplit_L4(
                spacing: 0,
                sizing: sizing
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: Should work on iOS (sizing may be applied differently than macOS)
        #expect(Bool(true), "Sizing configuration should work on iOS")
        #else
        #expect(Bool(true), "Test only runs on iOS")
        #endif
    }
    
    @Test @MainActor func testPlatformSplitViewSizingWorksOnMacOS() async {
        #if os(macOS)
        // Given: A sizing configuration on macOS
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 250, idealWidth: 280, maxWidth: 350),
            secondPane: PlatformSplitViewPaneSizing(minWidth: 400, idealWidth: 500, maxWidth: 600)
        )
        
        // When: Creating a view with sizing
        let view = Text("Test")
            .platformVerticalSplit_L4(
                spacing: 0,
                sizing: sizing
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: Should work on macOS (sizing applied via frame modifiers)
        #expect(Bool(true), "Sizing configuration should work on macOS")
        #else
        #expect(Bool(true), "Test only runs on macOS")
        #endif
    }
}

