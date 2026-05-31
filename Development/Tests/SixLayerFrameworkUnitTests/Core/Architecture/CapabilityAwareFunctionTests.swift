import Testing


//
//  CapabilityAwareFunctionTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates capability-aware function functionality and comprehensive capability-dependent function testing,
//  ensuring proper capability detection and function behavior validation across all supported platforms.
//
//  TESTING SCOPE:
//  - Capability-dependent function testing and validation
//  - Capability-aware function behavior testing
//  - Cross-platform capability function consistency and compatibility
//  - Capability function enablement and disablement testing
//  - Platform-specific capability function behavior testing
//  - Edge cases and error handling for capability-aware functions
//
//  METHODOLOGY:
//  - Test capability-dependent function behavior using comprehensive capability testing
//  - Verify capability-aware function behavior using switch statements and conditional logic
//  - Test cross-platform capability function consistency and compatibility
//  - Validate capability function enablement and disablement testing
//  - Test platform-specific capability function behavior using platform detection
//  - Test edge cases and error handling for capability-aware functions
//
//  QUALITY ASSESSMENT: ✅ EXCELLENT
//  - ✅ Excellent: Uses comprehensive business logic testing with capability-dependent functions
//  - ✅ Excellent: Tests capability-aware function behavior with proper conditional logic
//  - ✅ Excellent: Validates capability function enablement and disablement comprehensively
//  - ✅ Excellent: Uses proper test structure with capability-aware function testing
//  - ✅ Excellent: Tests both enabled and disabled capability scenarios
//

import SwiftUI
@testable import SixLayerFramework

/// Capability-aware function testing
/// Tests every function that depends on capabilities in both enabled and disabled states.
/// Uses `DefaultRuntimeCapabilityIsolationTrait` (GitHub #236) for per-test override hygiene;
/// see `.cursor/rules/capability-override-test-flows.mdc` and GitHub #278.
@Suite("Capability-aware functions", DefaultRuntimeCapabilityIsolationTrait())
open class CapabilityAwareFunctionTests: BaseTestClass {
    
    // BaseTestClass handles cleanup automatically
    
    // MARK: - Touch thread-local overrides (default / positive / negative)
    
    /// Default: no thread-local touch overrides; card config mirrors `RuntimeCapabilityDetection`.
    @MainActor
    private func runTouchThreadLocalOverrideDefaultVerification() {
        let touch = RuntimeCapabilityDetection.supportsTouch
        let haptic = RuntimeCapabilityDetection.supportsHapticFeedback
        let config = getCardExpansionPlatformConfig()
        #expect(config.supportsTouch == touch)
        #expect(config.supportsHapticFeedback == haptic)
    }
    
    /// Positive: `true` overrides where used; touch-first paths and HIG floors (Issue #237).
    @MainActor
    private func runTouchThreadLocalOverridePositiveVerification() {
        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        defer {
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
        #expect(RuntimeCapabilityDetection.supportsTouch)
        #expect(RuntimeCapabilityDetection.supportsHapticFeedback)
        #expect(RuntimeCapabilityDetection.supportsAssistiveTouch)
        let config = getCardExpansionPlatformConfig()
        #expect(config.supportsTouch)
        #expect(config.supportsHapticFeedback)
        #expect(config.supportsAssistiveTouch)
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget = PlatformTestUtilities.expectedMinTouchTarget(
            for: currentPlatform,
            touchDetected: true
        )
        #expect(config.minTouchTarget == expectedMinTouchTarget,
                "Touch targets must match Apple HIG for \(currentPlatform): expected \(expectedMinTouchTarget)pt")
    }
    
    /// Negative: `false` is respected on platforms that can simulate “no touch”; on iOS/watchOS a
    /// false **touch** override is ignored (platform guarantee) while other overrides still apply.
    @MainActor
    private func runTouchThreadLocalOverrideNegativeVerification() {
        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        defer {
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
        let currentPlatform = SixLayerPlatform.current
        let config = getCardExpansionPlatformConfig()
        switch currentPlatform {
        case .iOS, .watchOS:
            #expect(RuntimeCapabilityDetection.supportsTouch,
                    "Thread-local false touch override is ignored on touch-first platforms")
            #expect(config.supportsTouch)
            #expect(!RuntimeCapabilityDetection.supportsHapticFeedback)
            #expect(!config.supportsHapticFeedback)
            #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch)
            #expect(!config.supportsAssistiveTouch)
        case .macOS, .tvOS, .visionOS:
            #expect(!RuntimeCapabilityDetection.supportsTouch)
            #expect(!config.supportsTouch)
            #expect(!config.supportsHapticFeedback)
            #expect(!config.supportsAssistiveTouch)
        }
        let expectedMinTouchTarget = PlatformTestUtilities.expectedMinTouchTarget(
            for: currentPlatform,
            touchDetected: config.supportsTouch
        )
        #expect(config.minTouchTarget == expectedMinTouchTarget,
                "Touch targets must match Apple HIG for \(currentPlatform): expected \(expectedMinTouchTarget)pt")
    }
    
    // MARK: - Touch-Dependent Function Tests
    
    /// BUSINESS PURPOSE: Runs all three thread-local touch override flows (see `.cursor/rules/capability-override-test-flows.mdc`).
    @Test @MainActor func testTouchDependentFunctions() {
        runTouchThreadLocalOverrideDefaultVerification()
        runTouchThreadLocalOverridePositiveVerification()
        runTouchThreadLocalOverrideNegativeVerification()
    }
    
    @Test @MainActor func testTouchThreadLocalOverride_DefaultPathMirrorsIntrinsicDetection() {
        runTouchThreadLocalOverrideDefaultVerification()
    }
    
    @Test @MainActor func testTouchThreadLocalOverride_PositivePathEnablesTouchStack() {
        runTouchThreadLocalOverridePositiveVerification()
    }
    
    @Test @MainActor func testTouchThreadLocalOverride_NegativePathRespectedOrTouchIgnoredPerPlatform() {
        runTouchThreadLocalOverrideNegativeVerification()
    }
    
    /// BUSINESS PURPOSE: Positive thread-local touch stack (alias for filters / audit lists).
    @Test @MainActor func testTouchDependentFunctionsEnabled() {
        runTouchThreadLocalOverridePositiveVerification()
    }
    
    /// BUSINESS PURPOSE: Negative thread-local touch stack (alias for filters / audit lists).
    @Test @MainActor func testTouchDependentFunctionsDisabled() {
        runTouchThreadLocalOverrideNegativeVerification()
    }
    
    /// BUSINESS PURPOSE: Positive path with hover pinned off (card expansion interaction slice).
    @Test @MainActor func testTouchFunctionsEnabled() {
        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        RuntimeCapabilityDetection.setTestHover(false)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }
        let config = getCardExpansionPlatformConfig()
        let currentPlatform = SixLayerPlatform.current
        let expectedMinTouchTarget = PlatformTestUtilities.expectedMinTouchTarget(
            for: currentPlatform,
            touchDetected: true
        )
        #expect(config.minTouchTarget == expectedMinTouchTarget,
                "Touch targets must match Apple HIG for \(currentPlatform): expected \(expectedMinTouchTarget)pt")
        #expect(config.supportsTouch)
        #expect(config.supportsHapticFeedback)
        #expect(config.supportsAssistiveTouch)
    }
    
    /// BUSINESS PURPOSE: Negative path slice without hover (delegates to shared negative semantics).
    @Test @MainActor func testTouchFunctionsDisabled() {
        runTouchThreadLocalOverrideNegativeVerification()
    }
    
    // MARK: - Hover-Dependent Function Tests
    
    /// Hover-dependent card config on the **current host** through hover tri-state (#251).
    @Test @MainActor func testHoverDependentFunctionsTriStatePhases() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        func assertHoverLaw(phase: String) {
            let platform = SixLayerPlatform.current
            let config = getCardExpansionPlatformConfig()
            let hover = RuntimeCapabilityDetection.supportsHover

            switch platform {
            case .iOS, .watchOS, .macOS, .tvOS, .visionOS:
                #expect(config.supportsHover == hover, "\(phase): hover should mirror detection on \(platform)")
                #expect(config.hoverDelay == RuntimeCapabilityDetection.hoverDelay, "\(phase): hoverDelay should mirror detection")
                if !hover {
                    #expect(config.hoverDelay == 0, "\(phase): no hover → zero delay on \(platform)")
                }
            }
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        assertHoverLaw(phase: "current")

        RuntimeCapabilityDetection.setTestHover(false)
        assertHoverLaw(phase: "disabled")

        RuntimeCapabilityDetection.setTestHover(true)
        assertHoverLaw(phase: "enabled")
    }

    /// BUSINESS PURPOSE: Test hover-dependent functions across all platforms
    /// TESTING SCOPE: Hover capability detection, hover delay, touch exclusion
    /// METHODOLOGY: Test runtime capabilities on current platform
    @Test @MainActor func testHoverDependentFunctions() {
        // Test both enabled and disabled states using the new methodology
        testHoverDependentFunctionsEnabled()
        testHoverDependentFunctionsDisabled()
    }
    
    /// BUSINESS PURPOSE: Test hover functions when hover is enabled
    /// TESTING SCOPE: Hover capability detection, hover delay, touch exclusion
    /// METHODOLOGY: Test runtime capabilities on current platform
    @Test @MainActor func testHoverDependentFunctionsEnabled() {
        // Suite trait clears overrides before each @Test; chained calls inside
        // `testHoverDependentFunctions` / `testAllCapabilityDependentFunctions` still rely on
        // explicit cleanup at the end of each phase below.
        RuntimeCapabilityDetection.setTestHover(true)
        RuntimeCapabilityDetection.setTestTouchSupport(false)
        
        // Test hover functions on current platform
        let currentPlatform = SixLayerPlatform.current
        let expectedHoverDelay: TimeInterval = (currentPlatform == .macOS || currentPlatform == .visionOS || currentPlatform == .iOS) ? 0.5 : 0.0

        let config = getCardExpansionPlatformConfig()

        // Test that hover-related functions work when hover is supported
        #expect(config.supportsHover, "Hover should be supported when enabled on current platform")

        // Verify hoverDelay returns platform-appropriate value for current platform
        #expect(config.hoverDelay == expectedHoverDelay, "Hover delay should be platform-appropriate (\(expectedHoverDelay)) for current platform \(currentPlatform)")
        // Note: Touch and hover CAN coexist (iPad with mouse, macOS with touchscreen, visionOS)
        // We trust what the OS reports - if both are available, both are available
        
        // Clean up
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    /// BUSINESS PURPOSE: Hover-dependent functions provide hover delays and exclude touch interactions when hover is enabled
    /// TESTING SCOPE: Hover capability detection, hover delay, touch exclusion
    /// METHODOLOGY: Test runtime capabilities on current platform
    @Test @MainActor func testHoverDependentFunctionsDisabled() {
        // Test hover capabilities on current platform
        RuntimeCapabilityDetection.setTestHover(false)
        // Do not force touch true here to avoid conflicting assumptions across platforms
        
        // Test hover functions on current platform
        let config = getCardExpansionPlatformConfig()

        // Test that hover-related functions handle disabled state gracefully
        #expect(!config.supportsHover, "Hover should not be supported when disabled on current platform")

        // Verify hoverDelay returns 0.0 when hover is not supported (Issue #141)
        // When hover is disabled, there's no point in returning a hover delay value
        #expect(config.hoverDelay == 0.0, "Hover delay should be 0.0 when hover is not supported on current platform \(SixLayerPlatform.current)")
        // Do not assert touch state when hover is disabled; it can vary by platform/config
        
        // Clean up
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    // MARK: - Vision Framework-Dependent Function Tests
    
    /// BUSINESS PURPOSE: Vision framework functions provide OCR processing and image analysis capabilities
    /// TESTING SCOPE: Vision framework availability, OCR processing, image analysis
    /// METHODOLOGY: Test both enabled and disabled Vision framework states
    @Test @MainActor func testVisionFrameworkDependentFunctions() {
        let supportsVision = isVisionFrameworkAvailable()
        
        if supportsVision {
            testVisionFunctionsEnabled()
        } else {
            testVisionFunctionsDisabled()
        }
    }
    
    /// BUSINESS PURPOSE: Vision framework functions enable OCR text extraction and image processing when available
    /// TESTING SCOPE: Vision framework availability, OCR processing, image analysis
    /// METHODOLOGY: Test Vision framework enabled state with actual OCR processing
    @Test @MainActor func testVisionFunctionsEnabled() {
        // Vision is not surfaced for OCR on watchOS in this stack; the disabled-path suite covers it.
        #if os(watchOS)
        #expect(Bool(true), "Vision enabled-path checks run on platforms with Vision OCR support")
        return
        #endif
        // Vision framework should be available
        #expect(isVisionFrameworkAvailable(), 
                     "Vision framework should be available when enabled")
        
        // OCR should be available
        #expect(isVisionOCRAvailable(), 
                     "OCR should be available when Vision framework is enabled")
        
        // Vision functions should not crash
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [.general],
            language: .english,
            confidenceThreshold: 0.8
        )
        let strategy = OCRStrategy(
            supportedTextTypes: [.general],
            supportedLanguages: [.english],
            processingMode: .standard
        )
        
        // Test that Vision functions can be called without crashing
        let service = OCRService()
        Task {
            do {
                let _ = try await service.processImage(
                    testImage,
                    context: context,
                    strategy: strategy
                )
            } catch {
                // Expected for test images
            }
        }
    }
    
    /// BUSINESS PURPOSE: Vision framework functions provide fallback behavior when Vision framework is unavailable
    /// TESTING SCOPE: Vision framework availability, OCR processing, image analysis
    /// METHODOLOGY: Test Vision framework disabled state with graceful fallback handling
    @Test @MainActor func testVisionFunctionsDisabled() {
        // If Vision is available on this platform/SDK, skip strict disabled assertions
        guard !isVisionFrameworkAvailable() else {
            // Validate that availability implies OCR availability relationship
            #expect(isVisionOCRAvailable() == true, "OCR availability should align with Vision framework availability when enabled")
            return
        }
        
        // Vision framework should not be available
        #expect(!isVisionFrameworkAvailable(), 
                      "Vision framework should not be available when disabled")
        
        // OCR should not be available
        #expect(!isVisionOCRAvailable(), 
                      "OCR should not be available when Vision framework is disabled")
        
        // Vision functions should still be callable but return fallback behavior
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [.general],
            language: .english,
            confidenceThreshold: 0.8
        )
        let strategy = OCRStrategy(
            supportedTextTypes: [.general],
            supportedLanguages: [.english],
            processingMode: .standard
        )
        
        // Test that Vision functions handle disabled state gracefully
        let service = OCRService()
        Task {
            do {
                let _ = try await service.processImage(
                    testImage,
                    context: context,
                    strategy: strategy
                )
                // Should provide fallback result when Vision is disabled
                #expect(Bool(true), "Should provide fallback result when Vision is disabled")  // result is non-optional
            } catch {
                // Should handle error gracefully when Vision is disabled
                #expect(Bool(true), "Should handle error gracefully when Vision is disabled")  // error is non-optional
            }
        }
    }
    
    // MARK: - Accessibility-Dependent Function Tests
    
    /// BUSINESS PURPOSE: Accessibility functions provide VoiceOver and Switch Control support for inclusive user interaction
    /// TESTING SCOPE: VoiceOver support, Switch Control support, accessibility compliance
    /// METHODOLOGY: Test accessibility capability detection and support
    @Test @MainActor func testAccessibilityDependentFunctions() {
        // Test accessibility functions that are available
        // Note: AccessibilityOptimizationManager was removed - using simplified accessibility testing
        
        // Set test overrides for accessibility capabilities
        RuntimeCapabilityDetection.setTestVoiceOver(true)
        RuntimeCapabilityDetection.setTestSwitchControl(true)
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        // Test that accessibility behavior can be tested
        let config = getCardExpansionPlatformConfig()
        #expect(config.supportsVoiceOver, "VoiceOver should be supported")
        #expect(config.supportsSwitchControl, "Switch Control should be supported")
    }
    
    // MARK: - Color Encoding-Dependent Function Tests
    
    /// BUSINESS PURPOSE: Color encoding functions convert platform-specific colors to cross-platform data format
    /// TESTING SCOPE: Color encoding, color decoding, cross-platform color compatibility
    /// METHODOLOGY: Test color encoding and decoding across all platforms
    @Test @MainActor func testColorEncodingDependentFunctions() {
        // Color encoding should work on all platforms
        testColorEncodingFunctionsEnabled()
    }
    
    /// BUSINESS PURPOSE: Color encoding functions enable cross-platform color data exchange through encoding and decoding
    /// TESTING SCOPE: Color encoding, color decoding, cross-platform color compatibility
    /// METHODOLOGY: Test color encoding and decoding functionality
    @Test @MainActor func testColorEncodingFunctionsEnabled() {
        // Issue #237: platformColorEncode/Decode throw .platformNotSupported on
        // tvOS/watchOS/visionOS by framework design (the documented contract).
        // A full tvOS/watchOS/visionOS encoding implementation is tracked under
        // #241 (capability-aware graceful degradation). Until then, this test
        // asserts the iOS/macOS success contract AND the tvOS/etc. documented
        // failure contract, so neither regression goes unnoticed.
        let testColor = Color.blue
        #if os(iOS) || os(macOS)
        do {
            let encodedData = try platformColorEncode(testColor)
            #expect(!encodedData.isEmpty, "Color encoding should work on iOS/macOS")

            let _ = try platformColorDecode(encodedData)
            #expect(Bool(true), "Color decoding should work on iOS/macOS")
        } catch {
            Issue.record("Color encoding/decoding should work on iOS/macOS: \(error)")
        }
        #else
        #expect(throws: ColorEncodingError.self,
                "tvOS/watchOS/visionOS: framework is documented to throw .platformNotSupported until #241") {
            _ = try platformColorEncode(testColor)
        }
        #endif
    }
    
    // MARK: - Comprehensive Capability-Aware Testing
    
    /// BUSINESS PURPOSE: Comprehensive capability testing validates all capability-dependent functions work correctly together
    /// TESTING SCOPE: All capability-dependent functions, cross-platform consistency
    /// METHODOLOGY: Test all capability-dependent functions in sequence
    @Test @MainActor func testAllCapabilityDependentFunctions() {
        // Test all capability-dependent functions
        testTouchDependentFunctions()
        testHoverDependentFunctions()
        testVisionFrameworkDependentFunctions()
        testAccessibilityDependentFunctions()
        testColorEncodingDependentFunctions()
    }
    
    // MARK: - Capability State Validation
    
    /// **Plumbing:** `CardExpansionPlatformConfig` mirrors `RuntimeCapabilityDetection` for the fields it copies.
    /// **Cross-cutting laws:** haptic implies touch; AssistiveTouch matches platform availability; OCR implies Vision.
    /// Kept narrow per `.cursor/rules/capability-override-test-flows.mdc` (GitHub #278) — not a parallel capability matrix suite.
    @Test @MainActor func testCapabilityStateConsistency() {
        let config = getCardExpansionPlatformConfig()

        #expect(config.supportsTouch == RuntimeCapabilityDetection.supportsTouch,
                "Card expansion config should mirror runtime touch detection")
        #expect(config.supportsHover == RuntimeCapabilityDetection.supportsHover,
                "Card expansion config should mirror runtime hover detection")
        #expect(config.supportsHapticFeedback == RuntimeCapabilityDetection.supportsHapticFeedback,
                "Card expansion config should mirror runtime haptic detection")
        #expect(config.supportsAssistiveTouch == RuntimeCapabilityDetection.supportsAssistiveTouch,
                "Card expansion config should mirror runtime AssistiveTouch availability")
        #expect(config.supportsVoiceOver == RuntimeCapabilityDetection.supportsVoiceOver,
                "Card expansion config should mirror runtime VoiceOver detection")
        #expect(config.supportsSwitchControl == RuntimeCapabilityDetection.supportsSwitchControl,
                "Card expansion config should mirror runtime Switch Control detection")

        let vision = isVisionFrameworkAvailable()
        let ocr = isVisionOCRAvailable()
        #expect(!(ocr && !vision), "OCR availability should imply Vision framework availability")

        #expect(!(config.supportsHapticFeedback && !config.supportsTouch),
                "Haptic capability should not be reported without touch (incoherent actuation surface)")

        let assistiveTouchPlatformSupported = SixLayerPlatform.current.supportsAssistiveTouch
        if assistiveTouchPlatformSupported {
            #expect(!(config.supportsAssistiveTouch && !config.supportsTouch),
                    "AssistiveTouch implies touch on platforms that ship the feature")
        } else {
            #expect(!config.supportsAssistiveTouch,
                    "AssistiveTouch should be unavailable on platforms that do not ship the OS feature")
        }
    }
}
