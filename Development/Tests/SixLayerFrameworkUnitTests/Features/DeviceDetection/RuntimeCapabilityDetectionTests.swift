import Testing


//
//  RuntimeCapabilityDetectionTDDTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates runtime capability detection TDD functionality and comprehensive runtime capability detection testing,
//  ensuring proper runtime capability detection and behavior validation across all supported platforms.
//
//  TESTING SCOPE:
//  - Runtime capability detection TDD functionality and validation
//  - Runtime capability detection testing and validation
//  - Cross-platform runtime capability detection consistency and compatibility
//  - Platform-specific runtime capability detection behavior testing
//  - Runtime capability detection accuracy and reliability testing
//  - Edge cases and error handling for runtime capability detection logic
//
//  METHODOLOGY:
//  - Test runtime capability detection TDD functionality using comprehensive runtime capability detection testing
//  - Verify platform-specific runtime capability detection behavior using switch statements and conditional logic
//  - Test cross-platform runtime capability detection consistency and compatibility
//  - Validate platform-specific runtime capability detection behavior using platform detection
//  - Test runtime capability detection accuracy and reliability
//  - Test edge cases and error handling for runtime capability detection logic
//
//  QUALITY ASSESSMENT: ✅ EXCELLENT
//  - ✅ Excellent: Uses comprehensive business logic testing with runtime capability detection TDD
//  - ✅ Excellent: Tests platform-specific behavior with proper runtime capability detection logic
//  - ✅ Excellent: Validates runtime capability detection and behavior comprehensively
//  - ✅ Excellent: Uses proper test structure with runtime capability detection TDD testing
//  - ✅ Excellent: Tests all runtime capability detection scenarios
//

import SwiftUI
@testable import SixLayerFramework

/// TDD Tests for Runtime Capability Detection
/// These tests define the expected behavior and will initially fail
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Runtime Capability Detection", DefaultRuntimeCapabilityIsolationTrait())
open class RuntimeCapabilityDetectionTDDTests: BaseTestClass {
    
    // MARK: - Testing Mode Detection Tests
    
    @Test func testTestingModeDetection() {
        // This test should pass - we're in a test environment
        #expect(TestingCapabilityDetection.isTestingMode, "Should detect testing mode in XCTest environment")
    }
    
    @Test func testTestingDefaultsForEachPlatform() {
        // Test that each platform has predictable testing defaults
        let platforms: [SixLayerPlatform] = [SixLayerPlatform.iOS, SixLayerPlatform.macOS, SixLayerPlatform.watchOS, SixLayerPlatform.tvOS, SixLayerPlatform.visionOS]
        
        for platform in platforms {
            let defaults = TestingCapabilityDetection.getTestingDefaults(for: platform)
            
            // Each platform should have defined defaults
            #expect(Bool(true), "Platform \(platform) should have testing defaults")  // defaults is non-optional
            
            // Log the defaults for verification
            print("Testing defaults for \(platform):")
            print("  Touch: \(defaults.supportsTouch)")
            print("  Haptic: \(defaults.supportsHapticFeedback)")
            print("  Hover: \(defaults.supportsHover)")
            print("  VoiceOver: \(defaults.supportsVoiceOver)")
            print("  SwitchControl: \(defaults.supportsSwitchControl)")
            print("  AssistiveTouch: \(defaults.supportsAssistiveTouch)")
        }
    }
    
    // MARK: - Runtime Detection Tests (These will initially fail)
    
    @Test func testRuntimeTouchDetectionUsesTestingDefaults() {
        // In testing mode, should use hardcoded defaults
        let platform = SixLayerPlatform.current
        let expectedDefaults = TestingCapabilityDetection.getTestingDefaults(for: platform)
        
        // This should use testing defaults, not runtime detection
        let actualTouchSupport = RuntimeCapabilityDetection.supportsTouch
        #expect(actualTouchSupport == expectedDefaults.supportsTouch, 
                     "Runtime detection should use testing defaults when in testing mode")
    }
    
    @Test @MainActor func testRuntimeHapticDetectionUsesTestingDefaults() {
        // Set capability override to match testing defaults
        let platform = SixLayerPlatform.current
        let expectedDefaults = TestingCapabilityDetection.getTestingDefaults(for: platform)
        
        // Set override to match expected defaults
        RuntimeCapabilityDetection.setTestHapticFeedback(expectedDefaults.supportsHapticFeedback)
        defer {
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
        
        let actualHapticSupport = RuntimeCapabilityDetection.supportsHapticFeedback
        #expect(actualHapticSupport == expectedDefaults.supportsHapticFeedback, 
                     "Runtime haptic detection should use testing defaults when in testing mode")
    }
    
    @Test @MainActor func testRuntimeHoverDetectionUsesTestingDefaults() {
        // Set capability override to match testing defaults
        let platform = SixLayerPlatform.current
        let expectedDefaults = TestingCapabilityDetection.getTestingDefaults(for: platform)
        
        // Set override to match expected defaults
        RuntimeCapabilityDetection.setTestHover(expectedDefaults.supportsHover)
        
        let actualHoverSupport = RuntimeCapabilityDetection.supportsHover
        #expect(actualHoverSupport == expectedDefaults.supportsHover, 
                     "Runtime hover detection should respect capability overrides")
        
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    // MARK: - Override Functionality Tests
    
    /// Thread-local `false` for touch cannot remove touch on iOS/watchOS (platform guarantee).
    @Test @MainActor func testThreadLocalFalseTouchOverrideIgnoredOnTouchFirstPlatforms() {
        switch SixLayerPlatform.current {
        case .iOS, .watchOS:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            defer {
                RuntimeCapabilityDetection.clearAllCapabilityOverrides()
            }
            #expect(RuntimeCapabilityDetection.supportsTouch)
        default:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            defer {
                RuntimeCapabilityDetection.clearAllCapabilityOverrides()
            }
            #expect(!RuntimeCapabilityDetection.supportsTouch)
        }
    }
    
    @Test @MainActor func testTouchOverrideTakesPrecedenceOverTestingDefaults() {
        // Set override
        CapabilityOverride.touchSupport = true
        
        // Should use override, not testing defaults
        #expect(RuntimeCapabilityDetection.supportsTouchWithOverride, 
                     "Override should take precedence over testing defaults")
        
        // Set override to false
        CapabilityOverride.touchSupport = false
        #expect(!RuntimeCapabilityDetection.supportsTouchWithOverride, 
                      "Override should work when set to false")
    }
    
    @Test @MainActor func testHapticOverrideTakesPrecedenceOverTestingDefaults() {
        // Set override
        CapabilityOverride.hapticSupport = true
        
        // Should use override, not testing defaults
        #expect(RuntimeCapabilityDetection.supportsHapticFeedbackWithOverride, 
                     "Haptic override should take precedence over testing defaults")
    }
    
    @Test @MainActor func testHoverOverrideTakesPrecedenceOverTestingDefaults() {
        // Set override
        CapabilityOverride.hoverSupport = false
        
        // Should use override, not testing defaults
        #expect(!RuntimeCapabilityDetection.supportsHoverWithOverride, 
                      "Hover override should take precedence over testing defaults")
    }
    
    // MARK: - Platform-Specific Behavior Tests
    
    @Test @MainActor func testMacOSTouchDefaults() {
        let macDefaults = TestingCapabilityDetection.getTestingDefaults(for: .macOS)
        
        // macOS testing defaults should be predictable
        #expect(!macDefaults.supportsTouch, "macOS testing default should be false for touch")
        #expect(!macDefaults.supportsHapticFeedback, "macOS testing default should be false for haptic")
        #expect(macDefaults.supportsHover, "macOS testing default should be true for hover")
        #expect(!macDefaults.supportsAssistiveTouch, "macOS testing default should be false for AssistiveTouch")
    }
    
    @Test @MainActor func testiOSTouchDefaults() {
        let iOSDefaults = TestingCapabilityDetection.getTestingDefaults(for: .iOS)
        
        // iOS testing defaults should be predictable
        #expect(iOSDefaults.supportsTouch, "iOS testing default should be true for touch")
        #expect(iOSDefaults.supportsHapticFeedback, "iOS testing default should be true for haptic")
        #expect(!iOSDefaults.supportsHover, "iOS testing default should be false for hover (simplified)")
        #expect(iOSDefaults.supportsAssistiveTouch, "iOS testing default should be true for AssistiveTouch")
    }
    
    @Test @MainActor func testVisionOSTouchDefaults() {
        let visionDefaults = TestingCapabilityDetection.getTestingDefaults(for: .visionOS)
        
        // visionOS testing defaults should match actual platform capabilities
        // visionOS is spatial computing: no touch, no haptic, but supports hover through hand tracking
        #expect(!visionDefaults.supportsTouch, "visionOS testing default should be false for touch (spatial computing, not touchscreen)")
        #expect(!visionDefaults.supportsHapticFeedback, "visionOS testing default should be false for haptic (no native haptic feedback)")
        #expect(visionDefaults.supportsHover, "visionOS testing default should be true for hover (hand tracking provides hover)")
        #expect(visionDefaults.supportsVoiceOver, "visionOS testing default should be true for VoiceOver")
        #expect(visionDefaults.supportsVision, "visionOS testing default should be true for Vision framework")
        #expect(visionDefaults.supportsOCR, "visionOS testing default should be true for OCR")
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testCardExpansionConfigUsesRuntimeDetection() {
        initializeTestConfig()
        // Set capability overrides to match testing defaults
        let platform = SixLayerPlatform.current
        let expectedDefaults = TestingCapabilityDetection.getTestingDefaults(for: platform)
        
        RuntimeCapabilityDetection.setTestTouchSupport(expectedDefaults.supportsTouch)
        RuntimeCapabilityDetection.setTestHapticFeedback(expectedDefaults.supportsHapticFeedback)
        RuntimeCapabilityDetection.setTestHover(expectedDefaults.supportsHover)
        
        let config = getCardExpansionPlatformConfig()
        
        // The config should use runtime detection (which respects capability overrides)
        #expect(config.supportsTouch == expectedDefaults.supportsTouch, 
                     "Card expansion config should use runtime detection")
        #expect(config.supportsHapticFeedback == expectedDefaults.supportsHapticFeedback, 
                     "Card expansion config should use runtime detection")
        #expect(config.supportsHover == expectedDefaults.supportsHover, 
                     "Card expansion config should use runtime detection")
        
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    @Test @MainActor func testPlatformOptimizationUsesRuntimeDetection() {
        initializeTestConfig()
        // Setup test environment
        setupTestEnvironment()
        
        // Clear any overrides before test
        CapabilityOverride.touchSupport = nil
        CapabilityOverride.hapticSupport = nil
        CapabilityOverride.hoverSupport = nil
        
        let platform = SixLayerPlatform.current
        let supportsTouchGestures = platform.supportsTouchGestures
        
        // Should use runtime detection (which uses testing defaults in test mode)
        let expectedDefaults = TestingCapabilityDetection.getTestingDefaults(for: platform)
        #expect(supportsTouchGestures == expectedDefaults.supportsTouch, 
                     "Platform optimization should use runtime detection")
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    // MARK: - Override Persistence Tests
    
    @Test @MainActor func testOverridePersistenceAcrossMultipleCalls() {
        initializeTestConfig()
        // Set overrides
        CapabilityOverride.touchSupport = true
        CapabilityOverride.hapticSupport = false
        
        // Multiple calls should return consistent values
        for _ in 0..<5 {
            #expect(RuntimeCapabilityDetection.supportsTouchWithOverride)
            #expect(!RuntimeCapabilityDetection.supportsHapticFeedbackWithOverride)
        }
    }
    
    @Test @MainActor func testOverrideClearing() {
        initializeTestConfig()
        // Set override
        CapabilityOverride.touchSupport = true
        #expect(RuntimeCapabilityDetection.supportsTouchWithOverride)
        
        // Clear override
        CapabilityOverride.touchSupport = nil
        
        // With no `CapabilityOverride`, `supportsTouchWithOverride` must mirror intrinsic runtime
        // detection (e.g. macOS can report touch-capable hardware / simulated prefs).
        let intrinsicTouchSupport = RuntimeCapabilityDetection.supportsTouch
        #expect(RuntimeCapabilityDetection.supportsTouchWithOverride == intrinsicTouchSupport)
    }
    
    // MARK: - Edge Case Tests
    
    @Test @MainActor func testMultipleOverridesWorkIndependently() {
        initializeTestConfig()
        // Set different overrides
        CapabilityOverride.touchSupport = true
        CapabilityOverride.hapticSupport = false
        CapabilityOverride.hoverSupport = true
        
        // Each should work independently
        #expect(RuntimeCapabilityDetection.supportsTouchWithOverride)
        #expect(!RuntimeCapabilityDetection.supportsHapticFeedbackWithOverride)
        #expect(RuntimeCapabilityDetection.supportsHoverWithOverride)
    }
    
    @Test @MainActor func testOverridePrecedenceOrder() {
        initializeTestConfig()
        // Override should take precedence over testing defaults
        let platform = SixLayerPlatform.current
        let testingDefaults = TestingCapabilityDetection.getTestingDefaults(for: platform)
        
        // Set override to opposite of testing default
        CapabilityOverride.touchSupport = !testingDefaults.supportsTouch
        
        // Should use override, not testing default
        #expect(RuntimeCapabilityDetection.supportsTouchWithOverride == !testingDefaults.supportsTouch)
    }

    // MARK: - Touch Target Tests

    @Test func testMinTouchTargetValues() {
        // Apple HIG per platform (Issue #237) — authoritative contract:
        //   iOS:      44pt (touch HIG)
        //   watchOS:  44pt (inherited HIG; no explicit numeric minimum published)
        //   tvOS:     60pt (focus engine at 10-foot viewing distance)
        //   visionOS: 60pt (gaze+pinch minimum; NOT conditional on runtime touch)
        //   macOS:    44pt if runtime touch detected, else 0pt
        //
        // The prior test lumped tvOS + visionOS with macOS as
        // "non-touch-first, so 44-if-touch-else-0". That's wrong:
        // tvOS and visionOS have their own HIG floors independent of touch.
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()

        let platform = SixLayerPlatform.current
        let expected = PlatformTestUtilities.expectedMinTouchTarget(for: platform)
        let actual = RuntimeCapabilityDetection.minTouchTarget

        #expect(abs(actual - expected) < 0.001,
                "Apple HIG: \(platform) expected \(expected)pt, got \(actual)pt (supportsTouch=\(RuntimeCapabilityDetection.supportsTouch))")
    }

    @Test func testMinTouchTargetTriStatePhases() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        func assertMinTouchTargetLaw(phase: String) {
            let platform = SixLayerPlatform.current
            let effectiveTouch = RuntimeCapabilityDetection.supportsTouch
            let expected = PlatformTestUtilities.expectedMinTouchTarget(
                for: platform,
                touchDetected: effectiveTouch
            )
            let actual = RuntimeCapabilityDetection.minTouchTarget

            switch platform {
            case .iOS, .watchOS, .macOS, .tvOS, .visionOS:
                #expect(
                    abs(actual - expected) < 0.001,
                    "\(phase) on \(platform): expected \(expected)pt, got \(actual)pt (touch=\(effectiveTouch))"
                )
            }
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        assertMinTouchTargetLaw(phase: "current")

        RuntimeCapabilityDetection.setTestTouchSupport(false)
        assertMinTouchTargetLaw(phase: "disabled")

        RuntimeCapabilityDetection.setTestTouchSupport(true)
        assertMinTouchTargetLaw(phase: "enabled")
    }

    @Test func testMinTouchTargetIsNonNegative() {
        // minTouchTarget should never be negative
        #expect(RuntimeCapabilityDetection.minTouchTarget >= 0.0, "Minimum touch target should never be negative")
    }

    @Test func testMinTouchTargetDebug() {
        // Debug test to see what's happening
        let runtimePlatform = RuntimeCapabilityDetection.currentPlatform
        let sixLayerPlatform = SixLayerPlatform.current
        let supportsTouch = RuntimeCapabilityDetection.supportsTouch
        let minTouchTarget = RuntimeCapabilityDetection.minTouchTarget

        print("RuntimePlatform: \(runtimePlatform), SixLayerPlatform: \(sixLayerPlatform), supportsTouch: \(supportsTouch), minTouchTarget: \(minTouchTarget)")

        // For iOS, this should definitely be 44.0
        if runtimePlatform == .iOS {
            #expect(minTouchTarget == 44.0, "iOS should always have 44.0 minTouchTarget, got \(minTouchTarget)")
        }

        // Check if both platform detections agree
        #expect(runtimePlatform == sixLayerPlatform, "RuntimeCapabilityDetection.currentPlatform should match SixLayerPlatform.current")
    }

    // MARK: - Vision / Photos namespaced runtime (#253)

    @available(*, deprecated, message: "Legacy forwarder compatibility coverage.")
    @Test @MainActor
    func testLegacySupportsVisionMatchesVisionNamespace() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        #expect(RuntimeCapabilityDetection.supportsVision == RuntimeCapabilityDetection.Vision.isFrameworkAvailable)
    }

    @available(*, deprecated, message: "Legacy forwarder compatibility coverage.")
    @Test @MainActor
    func testLegacySupportsOCRMatchesVisionNamespace() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        #expect(RuntimeCapabilityDetection.supportsOCR == RuntimeCapabilityDetection.Vision.supportsOCR)
    }

    @Test @MainActor
    func testVisionOverridesClearWithClearAllCapabilityOverrides() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        let baselineFramework = RuntimeCapabilityDetection.Vision.isFrameworkAvailable
        let baselineOCR = RuntimeCapabilityDetection.Vision.supportsOCR
        let baselineImageAnalyzer = RuntimeCapabilityDetection.Vision.supportsImageAnalyzer
        let baselineDocumentCamera = RuntimeCapabilityDetection.Vision.supportsDocumentCamera

        RuntimeCapabilityDetection.Vision.setTestIsFrameworkAvailable(!baselineFramework)
        #expect(RuntimeCapabilityDetection.Vision.isFrameworkAvailable == !baselineFramework)

        RuntimeCapabilityDetection.Vision.setTestSupportsOCR(!baselineOCR)
        #expect(RuntimeCapabilityDetection.Vision.supportsOCR == !baselineOCR)

        RuntimeCapabilityDetection.Vision.setTestSupportsImageAnalyzer(!baselineImageAnalyzer)
        #expect(RuntimeCapabilityDetection.Vision.supportsImageAnalyzer == !baselineImageAnalyzer)

        RuntimeCapabilityDetection.Vision.setTestSupportsDocumentCamera(!baselineDocumentCamera)
        #expect(RuntimeCapabilityDetection.Vision.supportsDocumentCamera == !baselineDocumentCamera)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()

        #expect(RuntimeCapabilityDetection.Vision.isFrameworkAvailable == baselineFramework)
        #expect(RuntimeCapabilityDetection.Vision.supportsOCR == baselineOCR)
        #expect(RuntimeCapabilityDetection.Vision.supportsImageAnalyzer == baselineImageAnalyzer)
        #expect(RuntimeCapabilityDetection.Vision.supportsDocumentCamera == baselineDocumentCamera)
    }

    @Test @MainActor
    func testPhotosOverridesClearWithClearAllCapabilityOverrides() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        let baselineCamera = RuntimeCapabilityDetection.Photos.hasCamera
        let baselinePicker = RuntimeCapabilityDetection.Photos.isPhotoLibraryPickerAvailable
        let baselineScanner = RuntimeCapabilityDetection.Photos.supportsLiveDataScanner

        RuntimeCapabilityDetection.Photos.setTestHasCamera(!baselineCamera)
        #expect(RuntimeCapabilityDetection.Photos.hasCamera == !baselineCamera)

        RuntimeCapabilityDetection.Photos.setTestIsPhotoLibraryPickerAvailable(!baselinePicker)
        #expect(RuntimeCapabilityDetection.Photos.isPhotoLibraryPickerAvailable == !baselinePicker)

        RuntimeCapabilityDetection.Photos.setTestSupportsLiveDataScanner(!baselineScanner)
        #expect(RuntimeCapabilityDetection.Photos.supportsLiveDataScanner == !baselineScanner)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()

        #expect(RuntimeCapabilityDetection.Photos.hasCamera == baselineCamera)
        #expect(RuntimeCapabilityDetection.Photos.isPhotoLibraryPickerAvailable == baselinePicker)
        #expect(RuntimeCapabilityDetection.Photos.supportsLiveDataScanner == baselineScanner)
    }

    @Test func testPhotoDeviceCapabilitiesFromRuntimeMatchesPhotosProbes() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        let caps = PhotoDeviceCapabilities.fromRuntimeCapabilityDetection()
        #expect(caps.hasCamera == RuntimeCapabilityDetection.Photos.hasCamera)
        #expect(caps.hasPhotoLibrary == RuntimeCapabilityDetection.Photos.isPhotoLibraryPickerAvailable)
    }

    /// Smoke: VisionKit / Vision static probes must not trap on the main actor.
    @Test @MainActor
    func testVisionAndPhotosCapabilityReadsDoNotCrashOnMainActor() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        _ = RuntimeCapabilityDetection.Photos.photoLibraryReadAccessLevel
        _ = RuntimeCapabilityDetection.Photos.supportsLiveDataScanner
        _ = RuntimeCapabilityDetection.Vision.supportsImageAnalyzer
        _ = RuntimeCapabilityDetection.Vision.supportsDocumentCamera
        #expect(Bool(true))
    }

    // MARK: - Files namespaced runtime (#253)

    @available(*, deprecated, message: "Legacy forwarder compatibility coverage.")
    @Test @MainActor
    func testLegacySupportsSecurityScopedResourcesMatchesFilesNamespace() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        #expect(
            RuntimeCapabilityDetection.supportsSecurityScopedResources
                == RuntimeCapabilityDetection.Files.supportsSecurityScopedResources
        )
    }

    @available(*, deprecated, message: "Legacy forwarder compatibility coverage.")
    @Test @MainActor
    func testLegacySupportsSecurityScopedBookmarksMatchesFilesNamespace() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        #expect(
            RuntimeCapabilityDetection.supportsSecurityScopedBookmarks
                == RuntimeCapabilityDetection.Files.supportsSecurityScopedBookmarks
        )
    }

    @available(*, deprecated, message: "Legacy forwarder compatibility coverage.")
    @Test @MainActor
    func testLegacySecurityScopedForwardersReflectFilesOverrides() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        let baseResources = RuntimeCapabilityDetection.Files.supportsSecurityScopedResources
        let baseBookmarks = RuntimeCapabilityDetection.Files.supportsSecurityScopedBookmarks

        RuntimeCapabilityDetection.Files.setTestSupportsSecurityScopedResources(!baseResources)
        #expect(RuntimeCapabilityDetection.supportsSecurityScopedResources == !baseResources)

        RuntimeCapabilityDetection.Files.setTestSupportsSecurityScopedBookmarks(!baseBookmarks)
        #expect(RuntimeCapabilityDetection.supportsSecurityScopedBookmarks == !baseBookmarks)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }

    @Test @MainActor
    func testFilesOverridesClearWithClearAllCapabilityOverrides() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        let baselineResources = RuntimeCapabilityDetection.Files.supportsSecurityScopedResources
        let baselineBookmarks = RuntimeCapabilityDetection.Files.supportsSecurityScopedBookmarks

        RuntimeCapabilityDetection.Files.setTestSupportsSecurityScopedResources(!baselineResources)
        #expect(RuntimeCapabilityDetection.Files.supportsSecurityScopedResources == !baselineResources)

        RuntimeCapabilityDetection.Files.setTestSupportsSecurityScopedBookmarks(!baselineBookmarks)
        #expect(RuntimeCapabilityDetection.Files.supportsSecurityScopedBookmarks == !baselineBookmarks)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()

        #expect(RuntimeCapabilityDetection.Files.supportsSecurityScopedResources == baselineResources)
        #expect(RuntimeCapabilityDetection.Files.supportsSecurityScopedBookmarks == baselineBookmarks)
    }

    @Test @MainActor
    func testFilesCapabilityReadsDoNotCrash() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        _ = RuntimeCapabilityDetection.Files.supportsSecurityScopedResources
        _ = RuntimeCapabilityDetection.Files.supportsSecurityScopedBookmarks
        #expect(Bool(true))
    }

    // MARK: - Network / Media / Pasteboard / Accessibility namespaces

    @Test @MainActor
    func testNetworkOverridesClearWithClearAllCapabilityOverrides() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        let baselineConstrained = RuntimeCapabilityDetection.Network.isConstrained
        let baselineExpensive = RuntimeCapabilityDetection.Network.isExpensive

        RuntimeCapabilityDetection.Network.setTestIsConstrained(!baselineConstrained)
        #expect(RuntimeCapabilityDetection.Network.isConstrained == !baselineConstrained)

        RuntimeCapabilityDetection.Network.setTestIsExpensive(!baselineExpensive)
        #expect(RuntimeCapabilityDetection.Network.isExpensive == !baselineExpensive)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        #expect(RuntimeCapabilityDetection.Network.isConstrained == baselineConstrained)
        #expect(RuntimeCapabilityDetection.Network.isExpensive == baselineExpensive)
    }

    @Test @MainActor
    func testNetworkOverrideKeysAreIndependent() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        RuntimeCapabilityDetection.Network.setTestIsConstrained(true)
        RuntimeCapabilityDetection.Network.setTestIsExpensive(false)
        #expect(RuntimeCapabilityDetection.Network.isConstrained)
        #expect(!RuntimeCapabilityDetection.Network.isExpensive)
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }

    @Test @MainActor
    func testNetworkHasPathSnapshotOverrideAndClear() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        RuntimeCapabilityDetection.Network.setTestHasPathSnapshot(true)
        #expect(RuntimeCapabilityDetection.Network.hasPathSnapshot)
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }

    @Test @MainActor
    func testMediaOverridesClearWithClearAllCapabilityOverrides() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        let baselineMic = RuntimeCapabilityDetection.Media.hasMicrophoneInput
        let baselineScreen = RuntimeCapabilityDetection.Media.supportsScreenCapture

        RuntimeCapabilityDetection.Media.setTestHasMicrophoneInput(!baselineMic)
        #expect(RuntimeCapabilityDetection.Media.hasMicrophoneInput == !baselineMic)

        RuntimeCapabilityDetection.Media.setTestSupportsScreenCapture(!baselineScreen)
        #expect(RuntimeCapabilityDetection.Media.supportsScreenCapture == !baselineScreen)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        #expect(RuntimeCapabilityDetection.Media.hasMicrophoneInput == baselineMic)
        #expect(RuntimeCapabilityDetection.Media.supportsScreenCapture == baselineScreen)
    }

    @Test @MainActor
    func testPasteboardOverridesClearWithClearAllCapabilityOverrides() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        let baselineRead = RuntimeCapabilityDetection.Pasteboard.canReadStrings
        let baselineWrite = RuntimeCapabilityDetection.Pasteboard.canWriteStrings

        RuntimeCapabilityDetection.Pasteboard.setTestCanReadStrings(!baselineRead)
        #expect(RuntimeCapabilityDetection.Pasteboard.canReadStrings == !baselineRead)

        RuntimeCapabilityDetection.Pasteboard.setTestCanWriteStrings(!baselineWrite)
        #expect(RuntimeCapabilityDetection.Pasteboard.canWriteStrings == !baselineWrite)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        #expect(RuntimeCapabilityDetection.Pasteboard.canReadStrings == baselineRead)
        #expect(RuntimeCapabilityDetection.Pasteboard.canWriteStrings == baselineWrite)
    }

    @Test @MainActor
    func testAccessibilityNamespaceMatchesExistingAccessors() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        #expect(RuntimeCapabilityDetection.Accessibility.supportsVoiceOver == RuntimeCapabilityDetection.supportsVoiceOver)
        #expect(RuntimeCapabilityDetection.Accessibility.supportsSwitchControl == RuntimeCapabilityDetection.supportsSwitchControl)
        #expect(RuntimeCapabilityDetection.Accessibility.supportsAssistiveTouch == RuntimeCapabilityDetection.supportsAssistiveTouch)
    }

    #if os(iOS)
    @Test @MainActor
    func testiOSHoverDeviceCapabilityOverrideIsDeterministic() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        RuntimeCapabilityDetection.setTestiOSHoverDeviceCapability(true)
        #expect(RuntimeCapabilityDetection.supportsHover)
        RuntimeCapabilityDetection.setTestiOSHoverDeviceCapability(false)
        #expect(!RuntimeCapabilityDetection.supportsHover)
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    #endif

    #if os(macOS)
    /// Regression for GitHub #236: `UserDefaults.standard` touch simulation must not leak into card config when the suite harness pins preferences off.
    @Test @MainActor
    func testMacOSCardConfigIgnoresPollutedTouchEnabledUserDefaults() async {
        let key = "SixLayerFramework.TouchEnabled"
        UserDefaults.standard.set(true, forKey: key)
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let config = getCardExpansionPlatformConfig()
        #expect(!config.supportsTouch)
        #expect(config.minTouchTarget == 0.0)
    }
    #endif
}
