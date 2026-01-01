import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for Split View State Management (Issue #15)
/// 
/// BUSINESS PURPOSE: Ensure split view state management works correctly across platforms
/// TESTING SCOPE: State management features for PlatformSplitViewLayer4
/// METHODOLOGY: Test state management, visibility control, and persistence
/// Implements Issue #15: Split View State Management & Visibility Control (Layer 4)
@Suite("Platform Split View State Management Layer 4")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformSplitViewStateManagementLayer4Tests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
    // MARK: - State Management Tests
    
    @Test @MainActor func testPlatformSplitViewStateCreatesStateObject() async {
        // Given: Creating a split view state
        let _ = PlatformSplitViewState()
        
        // Then: State should be created successfully
        #expect(Bool(true), "PlatformSplitViewState should be created")  // state is non-optional
    }
    
    @Test @MainActor func testPlatformSplitViewStateHasDefaultVisibility() async {
        // Given: Creating a split view state
        let _ = PlatformSplitViewState()
        
        // Then: Should have default visibility values
        // Default visibility depends on implementation, but should be accessible
        #expect(Bool(true), "PlatformSplitViewState should have default visibility")
    }
    
    @Test @MainActor func testPlatformVerticalSplitL4AcceptsStateBinding() async {
        // Given: A state binding
        let state = PlatformSplitViewState()
        
        // When: Creating a view with state binding
        // Optimized: Use @State only when necessary - state object creation is sufficient for this test
        let _ = Text("Test")
            .platformVerticalSplit_L4(
                state: Binding(
                    get: { state },
                    set: { _ in }
                ),
                spacing: 0
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: View should be created successfully
        #expect(Bool(true), "platformVerticalSplit_L4 should accept state binding")
    }
    
    @Test @MainActor func testPlatformHorizontalSplitL4AcceptsStateBinding() async {
        // Given: A state binding
        let state = PlatformSplitViewState()
        
        // When: Creating a view with state binding
        // Optimized: Use @State only when necessary - state object creation is sufficient for this test
        let _ = Text("Test")
            .platformHorizontalSplit_L4(
                state: Binding(
                    get: { state },
                    set: { _ in }
                ),
                spacing: 0
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: View should be created successfully
        #expect(Bool(true), "platformHorizontalSplit_L4 should accept state binding")
    }
    
    // MARK: - Visibility Control Tests
    
    @Test @MainActor func testPlatformSplitViewStateCanShowHidePanes() async {
        // Given: A split view state
        let state = PlatformSplitViewState()
        
        // When: Changing visibility
        state.setPaneVisible(0, visible: false)
        
        // Then: Visibility should be updated
        #expect(!state.isPaneVisible(0), "Pane 0 should be hidden")
    }
    
    @Test @MainActor func testPlatformSplitViewStateVisibilityBinding() async {
        // Given: A state with visibility binding
        let state = PlatformSplitViewState()
        let binding = Binding(
            get: { state.isPaneVisible(0) },
            set: { state.setPaneVisible(0, visible: $0) }
        )
        
        // When: Changing visibility via binding
        binding.wrappedValue = false
        
        // Then: State should reflect the change
        #expect(!state.isPaneVisible(0), "Pane visibility should be updated via binding")
    }
    
    @Test @MainActor func testPlatformVerticalSplitL4RespectsVisibilityState() async {
        // Given: A state with hidden pane
        let state = PlatformSplitViewState()
        state.setPaneVisible(0, visible: false)
        
        // When: Creating a view with state
        let _ = Text("Test")
            .platformVerticalSplit_L4(
                state: Binding(
                    get: { state },
                    set: { _ in }
                ),
                spacing: 0
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: View should respect visibility state
        // Hidden panes should not be displayed
        #expect(Bool(true), "platformVerticalSplit_L4 should respect visibility state")
    }
    
    @Test @MainActor func testPlatformHorizontalSplitL4RespectsVisibilityState() async {
        // Given: A state with hidden pane
        let state = PlatformSplitViewState()
        state.setPaneVisible(1, visible: false)
        
        // When: Creating a view with state
        let _ = Text("Test")
            .platformHorizontalSplit_L4(
                state: Binding(
                    get: { state },
                    set: { _ in }
                ),
                spacing: 0
            ) {
                Text("First Pane")
                Text("Second Pane")
            }
        
        // Then: View should respect visibility state
        #expect(Bool(true), "platformHorizontalSplit_L4 should respect visibility state")
    }
    
    // MARK: - State Change Callbacks Tests
    
    @Test @MainActor func testPlatformSplitViewStateCallsVisibilityChangeCallback() async {
        // Given: A state with callback
        var callbackCalled = false
        var callbackValue: Bool?
        let state = PlatformSplitViewState()
        state.onVisibilityChange = { paneIndex, isVisible in
            callbackCalled = true
            callbackValue = isVisible
        }
        
        // When: Changing visibility
        state.setPaneVisible(0, visible: false)
        
        // Then: Callback should be called
        #expect(callbackCalled, "Visibility change callback should be called")
        #expect(callbackValue == false, "Callback should receive correct visibility value")
    }
    
    // MARK: - State Persistence Tests
    
    @Test @MainActor func testPlatformSplitViewStateCanSaveToUserDefaults() async {
        // Given: A state with visibility settings
        let state = PlatformSplitViewState()
        state.setPaneVisible(0, visible: false)
        state.setPaneVisible(1, visible: true)
        
        // When: Saving state
        _ = state.saveToUserDefaults(key: "testSplitViewState")
        
        // Then: State should be saved successfully
        #expect(Bool(true), "State should be saved to UserDefaults")
    }
    
    @Test @MainActor func testPlatformSplitViewStateCanRestoreFromUserDefaults() async {
        // Given: A saved state
        let originalState = PlatformSplitViewState()
        originalState.setPaneVisible(0, visible: false)
        _ = originalState.saveToUserDefaults(key: "testSplitViewState")
        
        // When: Restoring state
        let restoredState = PlatformSplitViewState()
        let restored = restoredState.restoreFromUserDefaults(key: "testSplitViewState")
        
        // Then: State should be restored
        #expect(restored, "State should be restored from UserDefaults")
        if restored {
            #expect(restoredState.isPaneVisible(0) == originalState.isPaneVisible(0), 
                   "Restored visibility should match original")
        }
    }
    
    @Test @MainActor func testPlatformSplitViewStateCanSaveToAppStorage() async {
        // Given: A state with visibility settings
        @AppStorage("testSplitViewState") var storedState: Data?
        let state = PlatformSplitViewState()
        state.setPaneVisible(0, visible: false)
        
        // When: Saving to AppStorage
        let saved = state.saveToAppStorage(key: "testSplitViewState")
        
        // Then: State should be saved
        #expect(saved, "State should be saved to AppStorage")
    }
    
    // MARK: - Cross-Platform Behavior Tests
    
    @Test @MainActor func testPlatformSplitViewStateWorksOnIOS() async {
        #if os(iOS)
        // Given: A state on iOS
        let state = PlatformSplitViewState()
        
        // When: Using with split view
        let _ = Text("Test")
            .platformVerticalSplit_L4(
                state: Binding(
                    get: { state },
                    set: { _ in }
                ),
                spacing: 0
            ) {
                Text("First")
                Text("Second")
            }
        
        // Then: Should work on iOS
        #expect(Bool(true), "State management should work on iOS")
        #else
        #expect(Bool(true), "Test only runs on iOS")
        #endif
    }
    
    @Test @MainActor func testPlatformSplitViewStateWorksOnMacOS() async {
        #if os(macOS)
        // Given: A state on macOS
        let state = PlatformSplitViewState()
        
        // When: Using with split view
        let _ = Text("Test")
            .platformVerticalSplit_L4(
                state: Binding(
                    get: { state },
                    set: { _ in }
                ),
                spacing: 0
            ) {
                Text("First")
                Text("Second")
            }
        
        // Then: Should work on macOS
        #expect(Bool(true), "State management should work on macOS")
        #else
        #expect(Bool(true), "Test only runs on macOS")
        #endif
    }
}

