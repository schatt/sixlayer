//
//  RuntimeCapabilityDetection.swift
//  SixLayerFramework
//
//  Runtime capability detection that queries the OS instead of hardcoding platform assumptions.
//
//  Namespaced capability groups (`Photos`, `Vision`, `Files`) and their test hooks are tracked
//  under GitHub #253; live VisionKit data scanner availability is co-shipped with #252.
//

import Foundation
import os
import SwiftUI

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(Network)
import Network
#endif

#if canImport(Photos)
import Photos
#endif

#if canImport(Vision)
import Vision
#endif

#if canImport(ReplayKit)
import ReplayKit
#endif

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

#if os(iOS)
#if canImport(VisionKit)
import VisionKit
#endif
#endif

// MARK: - Runtime Capability Detection

/// Runtime capability detection that queries the OS for actual hardware/software capabilities
/// instead of making assumptions based on platform
public struct RuntimeCapabilityDetection {
    
    // MARK: - Platform Detection
    
    /// Get the current platform (always uses real compile-time platform detection)
    /// Tests should run on actual platforms/simulators to test platform-specific behavior
    public static var currentPlatform: SixLayerPlatform {
        return SixLayerPlatform.current
    }

    // MARK: - Private Capability Override Getters
    
    private static var testTouchSupport: Bool? {
        return Thread.current.threadDictionary["testTouchSupport"] as? Bool
    }
    
    private static var testHapticFeedback: Bool? {
        return Thread.current.threadDictionary["testHapticFeedback"] as? Bool
    }
    
    private static var testHover: Bool? {
        return Thread.current.threadDictionary["testHover"] as? Bool
    }
    
    private static var testVoiceOver: Bool? {
        return Thread.current.threadDictionary["testVoiceOver"] as? Bool
    }
    
    private static var testSwitchControl: Bool? {
        return Thread.current.threadDictionary["testSwitchControl"] as? Bool
    }
    
    private static var testAssistiveTouch: Bool? {
        return Thread.current.threadDictionary["testAssistiveTouch"] as? Bool
    }
    
    private static var testHighContrast: Bool? {
        return Thread.current.threadDictionary["testHighContrast"] as? Bool
    }

    private static var testPhotosHasCamera: Bool? {
        Thread.current.threadDictionary["testPhotosHasCamera"] as? Bool
    }

    private static var testPhotosIsPhotoLibraryPickerAvailable: Bool? {
        Thread.current.threadDictionary["testPhotosIsPhotoLibraryPickerAvailable"] as? Bool
    }

    private static var testPhotosSupportsLiveDataScanner: Bool? {
        Thread.current.threadDictionary["testPhotosSupportsLiveDataScanner"] as? Bool
    }

    private static var testVisionIsFrameworkAvailable: Bool? {
        Thread.current.threadDictionary["testVisionIsFrameworkAvailable"] as? Bool
    }

    private static var testVisionSupportsOCR: Bool? {
        Thread.current.threadDictionary["testVisionSupportsOCR"] as? Bool
    }

    private static var testVisionSupportsImageAnalyzer: Bool? {
        Thread.current.threadDictionary["testVisionSupportsImageAnalyzer"] as? Bool
    }

    private static var testVisionSupportsDocumentCamera: Bool? {
        Thread.current.threadDictionary["testVisionSupportsDocumentCamera"] as? Bool
    }

    private static var testFilesSupportsSecurityScopedResources: Bool? {
        Thread.current.threadDictionary["testFilesSupportsSecurityScopedResources"] as? Bool
    }

    private static var testFilesSupportsSecurityScopedBookmarks: Bool? {
        Thread.current.threadDictionary["testFilesSupportsSecurityScopedBookmarks"] as? Bool
    }

    #if os(iOS)
    private static var testiOSHoverDeviceCapability: Bool? {
        Thread.current.threadDictionary["testiOSHoverDeviceCapability"] as? Bool
    }
    #endif

    private static var testNetworkIsConstrained: Bool? {
        Thread.current.threadDictionary["testNetworkIsConstrained"] as? Bool
    }

    private static var testNetworkIsExpensive: Bool? {
        Thread.current.threadDictionary["testNetworkIsExpensive"] as? Bool
    }

    private static var testNetworkHasPathSnapshot: Bool? {
        Thread.current.threadDictionary["testNetworkHasPathSnapshot"] as? Bool
    }

    private static var testMediaHasMicrophoneInput: Bool? {
        Thread.current.threadDictionary["testMediaHasMicrophoneInput"] as? Bool
    }

    private static var testMediaSupportsScreenCapture: Bool? {
        Thread.current.threadDictionary["testMediaSupportsScreenCapture"] as? Bool
    }

    private static var testPasteboardCanReadStrings: Bool? {
        Thread.current.threadDictionary["testPasteboardCanReadStrings"] as? Bool
    }

    private static var testPasteboardCanWriteStrings: Bool? {
        Thread.current.threadDictionary["testPasteboardCanWriteStrings"] as? Bool
    }
    
    // MARK: - High Contrast Detection
    
    /// Detects if **Darker System Colors** is enabled (`UIAccessibility.isDarkerSystemColorsEnabled` on iOS).
    ///
    /// This is not **Increase Contrast** (`colorSchemeContrast`). For subtitle/caption text under
    /// Increase Contrast, use `PlatformContrastAccessibility.readableSecondary(contrast:)` or
    /// `View.platformForegroundReadableSecondary()`.
    ///
    /// Respects test override if set, otherwise queries the actual system setting.
    @MainActor
    public static var isHighContrastEnabled: Bool {
        // Check for capability override first (thread-local, no MainActor needed for override)
        if let testValue = testHighContrast {
            return testValue
        }
        
        // Use real runtime detection
        #if os(iOS)
        // Use Thread.isMainThread check with MainActor.assumeIsolated to satisfy compiler
        // while preventing crashes during parallel test execution
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                UIAccessibility.isDarkerSystemColorsEnabled
            }
        } else {
            // If not on main thread, return false (conservative default)
            // This prevents crashes during parallel test execution
            return false
        }
        #elseif os(macOS)
        // macOS doesn't have a direct equivalent, but we can check system preferences
        // For now, return false as macOS high contrast is less common
        return false
        #else
        return false
        #endif
    }
    
    // MARK: - Touch Capability Detection
    
    /// Detects if touch input is actually supported by querying the OS
    /// Note: nonisolated - detection functions don't access MainActor APIs
    nonisolated public static var supportsTouch: Bool {
        // Use real runtime detection - tests should run on actual platforms/simulators
        #if os(iOS)
        if let override = testTouchSupport {
            return override ? true : detectiOSTouchSupport()
        }
        return detectiOSTouchSupport()
        #elseif os(watchOS)
        if let override = testTouchSupport {
            return override ? true : detectwatchOSTouchSupport()
        }
        return detectwatchOSTouchSupport()
        #else
        if let testValue = testTouchSupport {
            return testValue
        }
        #if os(macOS)
        return detectmacOSTouchSupport()
        #elseif os(tvOS)
        return detecttvOSTouchSupport()
        #elseif os(visionOS)
        return detectvisionOSTouchSupport()
        #else
        return false
        #endif
        #endif
    }

    /// Touch reads for **card expansion** on macOS (GitHub #236).
    ///
    /// When `RuntimeCapabilityHarness.macOSTouchEnabledPreference` is unset, ignores
    /// `SixLayerFramework.TouchEnabled` in `UserDefaults` so stale keys do not force
    /// touch-sized chrome. Harness, `setTestTouchSupport`, and hardware/driver paths
    /// still align with full `supportsTouch`. Non-macOS hosts return `supportsTouch`.
    nonisolated internal static var supportsTouchForMacOSCardExpansion: Bool {
        #if os(macOS)
        if let testValue = testTouchSupport {
            return testValue
        }
        if RuntimeCapabilityHarness.macOSTouchEnabledPreference != nil {
            return detectmacOSTouchSupport()
        }
        if canDetectTouchEvents() {
            return true
        }
        if hasThirdPartyTouchDrivers() {
            return true
        }
        return false
        #else
        return supportsTouch
        #endif
    }
    
    #if os(iOS)
    /// iOS touch detection - checks for actual touch capability
    /// All iOS devices support touch - this is a platform guarantee
    private static func detectiOSTouchSupport() -> Bool {
        // All iOS devices have touch screens - this is a compile-time and runtime guarantee
        // No need for complex runtime checks that can fail in test environments
        // Simply return true since we're on iOS
        return true
    }
    #endif
    
    #if os(macOS)
    /// macOS touch detection - checks for third-party touch drivers or native support
    private static func detectmacOSTouchSupport() -> Bool {
        // Check if we're running on a Mac with touch capability
        // This could be through third-party drivers or future native support
        
        // Method 1: Check for touch events in the current session
        if canDetectTouchEvents() {
            return true
        }
        
        // Method 2: Check for third-party touch driver processes
        if hasThirdPartyTouchDrivers() {
            return true
        }
        
        // Method 3: Check system preferences or environment variables
        if isTouchEnabledInSystemPreferences() {
            return true
        }
        
        return false
    }
    
    /// Check if we can detect touch events in the current session
    private static func canDetectTouchEvents() -> Bool {
        // Try to detect if touch events are being processed
        // This is a placeholder - would need actual implementation
        return false
    }
    
    /// Check for third-party touch driver processes
    private static func hasThirdPartyTouchDrivers() -> Bool {
        // Check for common touch driver processes
        let _ = [
            "UPDD",           // Universal Pointer Device Driver
            "TouchBase",      // TouchBase driver
            "EloTouch",       // Elo Touch driver
            "PlanarTouch",    // Planar touch driver
        ]
        
        // This would require checking running processes
        // For now, return false as we don't have process checking implemented
        return false
    }
    
    /// Check if touch is enabled in system preferences
    private static func isTouchEnabledInSystemPreferences() -> Bool {
        if let harnessValue = RuntimeCapabilityHarness.macOSTouchEnabledPreference {
            return harnessValue
        }
        return UserDefaults.standard.bool(forKey: "SixLayerFramework.TouchEnabled")
    }
    #endif
    
    // MARK: - Haptic Feedback Detection
    
    /// Detects if haptic feedback is actually supported
    /// Note: nonisolated - detection functions only use UserDefaults (thread-safe) or return constants
    nonisolated public static var supportsHapticFeedback: Bool {
        // Check for capability override first
        if let testValue = testHapticFeedback {
            return testValue
        }
        
        // Use real runtime detection - simulators correctly report their platform
        // Tests should run on actual platforms/simulators to test platform-specific behavior
        #if os(iOS)
        return detectiOSHapticSupport()
        #elseif os(macOS)
        return detectmacOSHapticSupport()
        #elseif os(watchOS)
        return detectwatchOSHapticSupport()
        #elseif os(tvOS)
        return detecttvOSHapticSupport()
        #elseif os(visionOS)
        return detectvisionOSHapticSupport()
        #else
        return false
        #endif
    }
    
    #if os(iOS)
    private static func detectiOSHapticSupport() -> Bool {
        // iOS devices support haptic feedback
        return true
    }
    #endif
    
    #if os(macOS)
    private static func detectmacOSHapticSupport() -> Bool {
        if let harnessValue = RuntimeCapabilityHarness.macOSHapticEnabledPreference {
            return harnessValue
        }
        return UserDefaults.standard.bool(forKey: "SixLayerFramework.HapticEnabled")
    }
    #endif
    
    // MARK: - Hover Detection
    
    /// Detects if hover events are actually supported
    /// Note: nonisolated - early returns use thread-local storage (no MainActor needed)
    /// Only accesses MainActor APIs when actually querying OS (rare in tests)
    nonisolated public static var supportsHover: Bool {
        // Check for capability override first (thread-local, no MainActor needed)
        if let testValue = testHover {
            return testValue
        }
        
        // Use real runtime detection - simulators correctly report their platform
        // Tests should run on actual platforms/simulators to test platform-specific behavior
        #if os(iOS)
        // Access MainActor API only when actually on iOS and not in test mode
        // Use direct call - detectiOSHoverSupport now handles thread safety internally
        return detectiOSHoverSupport()
        #elseif os(macOS)
        return detectmacOSHoverSupport()  // Doesn't need MainActor
        #elseif os(watchOS)
        return detectwatchOSHoverSupport()
        #elseif os(tvOS)
        return detecttvOSHoverSupport()
        #elseif os(visionOS)
        return detectvisionOSHoverSupport()
        #else
        return false
        #endif
    }
    
    #if os(iOS)
    /// iOS hover detection - checks for iPad with Apple Pencil hover support
    /// 
    /// Hover is supported on:
    /// - iPad Pro 11-inch (4th gen+) and 12.9-inch (6th gen+)
    /// - iPad Air 11-inch and 13-inch (M2/M3)
    /// - iPad Mini (A17 Pro)
    /// - iPad Pro 11-inch and 13-inch (M4/M5)
    /// When paired with Apple Pencil 2 or Apple Pencil Pro
    /// 
    /// Note: This checks device capability, not whether a pencil is currently connected.
    /// If a pencil is connected/disconnected during runtime, this property will reflect
    /// the current state when accessed, but views won't automatically update unless
    /// they re-evaluate the property (e.g., on view refresh or state change).
    /// 
    /// Note: Uses Thread.isMainThread check to prevent crashes during parallel test execution
    private static func detectiOSHoverSupport() -> Bool {
        if let override = testiOSHoverDeviceCapability {
            return override
        }
        // Check if we're on iPad with hover-capable device
        // Use Thread.isMainThread check with MainActor.assumeIsolated to satisfy compiler
        // while preventing crashes during parallel test execution
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                guard UIDevice.current.userInterfaceIdiom == .pad else {
                    return false
                }
                
                // Check if device supports hover (iOS 16.1+)
                // For iPad, hover is supported on newer models with Apple Pencil 2 or Pro
                // We check if UIPencilInteraction can be instantiated as a proxy for hover support
                // Note: Actual pencil connection is checked at runtime when hover events occur
                if #available(iOS 16.1, *) {
                    // UIPencilInteraction is available on iPad models that support hover
                    // This is a class that can be instantiated if the device supports hover
                    // We use a simple check: if we're on iPad, assume hover is possible
                    // The actual hover capability depends on device model and pencil connection
                    // For runtime detection, we return true for iPad; actual hover support
                    // is determined when hover events are attempted
                    return true
                }
                
                // For iOS < 16.1, fall back to device type check
                // Older iPads don't support hover, so this is conservative
                return false
            }
        } else {
            // If not on main thread, assume no hover (conservative default)
            // This prevents crashes during parallel test execution
            return false
        }
    }
    #endif
    
    #if os(macOS)
    private static func detectmacOSHoverSupport() -> Bool {
        // macOS pointer devices fundamentally support hover semantics.
        // Do not couple capability to transient button state (which flakes in CI/tests).
        return true
    }
    
    private static func detectmacOSAssistiveTouchSupport() -> Bool {
        // macOS doesn't have AssistiveTouch (it's iOS/watchOS specific)
        // Check if there's any equivalent accessibility feature
        return false
    }
    #endif
    
    #if os(watchOS)
    private static func detectwatchOSTouchSupport() -> Bool {
        // Apple Watch always supports touch
        // Check if touch events are available
        return true // watchOS devices always have touch capability
    }
    
    private static func detectwatchOSHapticSupport() -> Bool {
        // Apple Watch supports haptic feedback
        // Check if haptic engine is available
        return true // All Apple Watch models support haptics
    }
    
    private static func detectwatchOSHoverSupport() -> Bool {
        // Apple Watch doesn't support hover
        return false
    }
    
    private static func detectwatchOSVoiceOverSupport() -> Bool {
        // VoiceOver exists on Apple Watch; UIAccessibility voice-over query APIs are unavailable on watchOS SDK.
        return true
    }
    
    private static func detectwatchOSSwitchControlSupport() -> Bool {
        // Switch Control is an iPhone/iPad-focused feature; avoid unavailable UIAccessibility APIs on watchOS.
        return false
    }
    
    private static func detectwatchOSAssistiveTouchSupport() -> Bool {
        // AssistiveTouch is not applicable to watchOS; avoid unavailable UIAccessibility APIs.
        return false
    }
    #endif
    
    #if os(tvOS)
    private static func detecttvOSTouchSupport() -> Bool {
        // Apple TV doesn't support touch
        return false
    }
    
    private static func detecttvOSHapticSupport() -> Bool {
        // Apple TV doesn't support haptics
        return false
    }
    
    private static func detecttvOSHoverSupport() -> Bool {
        // Apple TV doesn't support hover
        return false
    }
    
    private static func detecttvOSVoiceOverSupport() -> Bool {
        // Check if VoiceOver is available on tvOS
        return withMainActorProbe {
            UIAccessibility.isVoiceOverRunning
        } ?? false
    }
    
    private static func detecttvOSSwitchControlSupport() -> Bool {
        // Check if Switch Control is available on tvOS
        return withMainActorProbe {
            UIAccessibility.isSwitchControlRunning
        } ?? false
    }
    
    private static func detecttvOSAssistiveTouchSupport() -> Bool {
        // Apple TV doesn't have AssistiveTouch
        return false
    }
    #endif
    
    #if os(visionOS)
    private static func detectvisionOSTouchSupport() -> Bool {
        // Vision Pro is spatial computing, not touchscreen
        return false
    }
    
    private static func detectvisionOSHapticSupport() -> Bool {
        // Vision Pro doesn't have native haptic feedback
        return false
    }
    
    private static func detectvisionOSHoverSupport() -> Bool {
        // Vision Pro supports hover through hand tracking
        // Check if hand tracking is available
        return true // Vision Pro supports hover via hand tracking
    }
    
    private static func detectvisionOSVoiceOverSupport() -> Bool {
        // Check if VoiceOver is available on visionOS
        return withMainActorProbe {
            UIAccessibility.isVoiceOverRunning
        } ?? false
    }
    
    private static func detectvisionOSSwitchControlSupport() -> Bool {
        // Check if Switch Control is available on visionOS
        return withMainActorProbe {
            UIAccessibility.isSwitchControlRunning
        } ?? false
    }
    
    private static func detectvisionOSAssistiveTouchSupport() -> Bool {
        // AssistiveTouch is iOS/watchOS specific, not available on visionOS
        return false
    }
    #endif
    
    // MARK: - Accessibility Support Detection
    
    /// Detects if VoiceOver is supported on this platform
    /// Returns whether the platform supports VoiceOver, not whether it's currently running
    /// Note: nonisolated - platform capability detection only
    nonisolated public static var supportsVoiceOver: Bool {
        // Check for capability override first (thread-local, no MainActor needed)
        if let testValue = testVoiceOver {
            return testValue
        }

        // Platform capability detection - all Apple platforms support VoiceOver
        // All cases of SixLayerPlatform support VoiceOver
        return true
    }
    
    /// Detects if Switch Control is supported on this platform
    /// Returns whether the platform supports Switch Control, not whether it's currently running
    /// Note: nonisolated - platform capability detection only
    nonisolated public static var supportsSwitchControl: Bool {
        // Check for capability override first (thread-local, no MainActor needed)
        if let testValue = testSwitchControl {
            return testValue
        }

        // Platform capability detection - all Apple platforms support Switch Control
        // All cases of SixLayerPlatform support Switch Control
        return true
    }
    
    /// Detects if AssistiveTouch capability is available on the current platform.
    /// Semantics: **platform availability** - whether the platform supports AssistiveTouch as a feature.
    /// - iOS/watchOS: true (feature supported by OS)
    /// - macOS/tvOS/visionOS: false (not supported by OS)
    /// 
    /// Note: This checks platform availability, not whether the user has it enabled.
    /// Test overrides can simulate different platforms, but platform detection is authoritative for availability.
    /// Uses PlatformStrategy to reduce code duplication (Issue #140)
    nonisolated public static var supportsAssistiveTouch: Bool {
        guard currentPlatform.supportsAssistiveTouch else {
            return false
        }
        if let testValue = testAssistiveTouch {
            if testValue && !supportsTouch {
                return false
            }
            return testValue
        }
        return true
    }
    
    // MARK: - Vision Framework Detection
    
    /// Detect Vision framework availability using runtime checks
    private static func detectVisionFrameworkAvailability() -> Bool {
        #if canImport(Vision)
        #if os(iOS)
        if #available(iOS 11.0, *) {
            return true
        }
        return false
        #elseif os(macOS)
        if #available(macOS 10.15, *) {
            return true
        }
        return false
        #elseif os(watchOS)
        // Vision framework not available on watchOS
        return false
        #elseif os(tvOS)
        // Vision framework not available on tvOS
        return false
        #elseif os(visionOS)
        if #available(visionOS 1.0, *) {
            return true
        }
        return false
        #else
        return false
        #endif
        #else
        return false
        #endif
    }

    // MARK: - Namespaced runtime capabilities (#253 / #252)

    /// Vision framework, OCR, and still-image / document Vision probes.
    /// Live camera ``DataScannerViewController`` availability is under ``Photos`` (see #252).
    public enum Vision {
        /// Whether the Vision framework is usable on this OS/device class (same logic as legacy ``RuntimeCapabilityDetection/supportsVision``).
        nonisolated public static var isFrameworkAvailable: Bool {
            if let forced = testVisionIsFrameworkAvailable {
                guard platformShipsVisionFramework else { return false }
                return forced
            }
            return detectVisionFrameworkAvailability()
        }

        /// Vision-backed OCR availability (same logic as legacy ``RuntimeCapabilityDetection/supportsOCR``).
        nonisolated public static var supportsOCR: Bool {
            if let forced = testVisionSupportsOCR {
                guard platformShipsVisionFramework, isFrameworkAvailable else { return false }
                return forced
            }
            return detectVisionFrameworkAvailability()
        }

        /// Still-image Live Text–style analysis (`ImageAnalyzer`), iOS 16+ when VisionKit exposes it.
        nonisolated public static var supportsImageAnalyzer: Bool {
            if let forced = testVisionSupportsImageAnalyzer {
                guard platformShipsVisionFramework, isFrameworkAvailable else { return false }
                return forced
            }
            return detectSupportsImageAnalyzer()
        }

        /// Document camera / scan UX (`VNDocumentCameraViewController`) when supported.
        nonisolated public static var supportsDocumentCamera: Bool {
            if let forced = testVisionSupportsDocumentCamera {
                guard platformShipsVisionFramework, isFrameworkAvailable else { return false }
                return forced
            }
            return detectSupportsDocumentCamera()
        }

        /// `nil` clears the override; `true` / `false` force branch tests (does not change OS hardware).
        public static func setTestIsFrameworkAvailable(_ value: Bool?) {
            if value == true, !platformShipsVisionFramework {
                logIgnoredTestOverrideOnce(
                    key: "SixLayerFramework.didLogIgnoredTestVisionTrue",
                    message: "SixLayerFramework: setTestIsFrameworkAvailable(true) ignored — Vision framework is unavailable on this platform."
                )
                return
            }
            if value == false || value == nil {
                clearVisionDependentTestOverrides()
            }
            setThreadOptionalBool(key: "testVisionIsFrameworkAvailable", value: value)
        }

        public static func setTestSupportsOCR(_ value: Bool?) {
            if value == true {
                guard platformShipsVisionFramework else {
                    logIgnoredTestOverrideOnce(
                        key: "SixLayerFramework.didLogIgnoredTestOCRTrue",
                        message: "SixLayerFramework: setTestSupportsOCR(true) ignored — Vision framework is unavailable on this platform."
                    )
                    return
                }
                setTestIsFrameworkAvailable(true)
            }
            setThreadOptionalBool(key: "testVisionSupportsOCR", value: value)
        }

        public static func setTestSupportsImageAnalyzer(_ value: Bool?) {
            if value == true {
                guard platformShipsVisionFramework else {
                    logIgnoredTestOverrideOnce(
                        key: "SixLayerFramework.didLogIgnoredTestImageAnalyzerTrue",
                        message: "SixLayerFramework: setTestSupportsImageAnalyzer(true) ignored — Vision framework is unavailable on this platform."
                    )
                    return
                }
                setTestIsFrameworkAvailable(true)
            }
            setThreadOptionalBool(key: "testVisionSupportsImageAnalyzer", value: value)
        }

        public static func setTestSupportsDocumentCamera(_ value: Bool?) {
            if value == true {
                guard platformShipsVisionFramework else {
                    logIgnoredTestOverrideOnce(
                        key: "SixLayerFramework.didLogIgnoredTestDocumentCameraTrue",
                        message: "SixLayerFramework: setTestSupportsDocumentCamera(true) ignored — Vision framework is unavailable on this platform."
                    )
                    return
                }
                setTestIsFrameworkAvailable(true)
            }
            setThreadOptionalBool(key: "testVisionSupportsDocumentCamera", value: value)
        }

        private static var platformShipsVisionFramework: Bool {
            detectVisionFrameworkAvailability()
        }

        private static func clearVisionDependentTestOverrides() {
            setThreadOptionalBool(key: "testVisionSupportsOCR", value: nil)
            setThreadOptionalBool(key: "testVisionSupportsImageAnalyzer", value: nil)
            setThreadOptionalBool(key: "testVisionSupportsDocumentCamera", value: nil)
        }
    }

    /// Security-scoped resources and bookmark persistence (GitHub #253).
    ///
    /// Use these members for new code instead of the deprecated top-level
    /// ``RuntimeCapabilityDetection/supportsSecurityScopedResources`` and
    /// ``RuntimeCapabilityDetection/supportsSecurityScopedBookmarks`` forwarders.
    public enum Files {
        /// Same semantics as legacy ``RuntimeCapabilityDetection/supportsSecurityScopedResources``; prefer this member for new code.
        nonisolated public static var supportsSecurityScopedResources: Bool {
            if let forced = testFilesSupportsSecurityScopedResources { return forced }
            return detectSecurityScopedResourceSupport()
        }

        /// Same semantics as legacy ``RuntimeCapabilityDetection/supportsSecurityScopedBookmarks``; prefer this member for new code.
        nonisolated public static var supportsSecurityScopedBookmarks: Bool {
            if let forced = testFilesSupportsSecurityScopedBookmarks { return forced }
            return detectSecurityScopedBookmarkSupport()
        }

        /// Thread-local override for tests. `nil` removes the entry so ``clearAllCapabilityOverrides()`` and subsequent reads use OS detection.
        public static func setTestSupportsSecurityScopedResources(_ value: Bool?) {
            setThreadOptionalBool(key: "testFilesSupportsSecurityScopedResources", value: value)
        }

        /// Thread-local override for tests. `nil` removes the entry so ``clearAllCapabilityOverrides()`` and subsequent reads use OS detection.
        public static func setTestSupportsSecurityScopedBookmarks(_ value: Bool?) {
            setThreadOptionalBool(key: "testFilesSupportsSecurityScopedBookmarks", value: value)
        }
    }

    /// Dynamic network path state wrappers (Low Data Mode and expensive-link hints).
    public enum Network {
        /// Whether an `NWPathMonitor` snapshot has been observed.
        nonisolated public static var hasPathSnapshot: Bool {
            if let forced = testNetworkHasPathSnapshot { return forced }
            return detectNetworkHasPathSnapshot()
        }

        /// Mirrors `NWPath.isConstrained` (Low Data Mode path state).
        nonisolated public static var isConstrained: Bool {
            resolvedBool(override: testNetworkIsConstrained, detector: detectNetworkIsConstrained)
        }

        /// Mirrors `NWPath.isExpensive` (metered / costly path state).
        nonisolated public static var isExpensive: Bool {
            resolvedBool(override: testNetworkIsExpensive, detector: detectNetworkIsExpensive)
        }

        public static func setTestIsConstrained(_ value: Bool?) {
            setThreadOptionalBool(key: "testNetworkIsConstrained", value: value)
        }

        public static func setTestIsExpensive(_ value: Bool?) {
            setThreadOptionalBool(key: "testNetworkIsExpensive", value: value)
        }

        public static func setTestHasPathSnapshot(_ value: Bool?) {
            setThreadOptionalBool(key: "testNetworkHasPathSnapshot", value: value)
        }
    }

    /// Media capability wrappers for microphone input and screen capture APIs.
    public enum Media {
        nonisolated public static var hasMicrophoneInput: Bool {
            resolvedBool(override: testMediaHasMicrophoneInput, detector: detectMediaHasMicrophoneInput)
        }

        nonisolated public static var supportsScreenCapture: Bool {
            resolvedBool(override: testMediaSupportsScreenCapture, detector: detectMediaSupportsScreenCapture)
        }

        public static func setTestHasMicrophoneInput(_ value: Bool?) {
            setThreadOptionalBool(key: "testMediaHasMicrophoneInput", value: value)
        }

        public static func setTestSupportsScreenCapture(_ value: Bool?) {
            setThreadOptionalBool(key: "testMediaSupportsScreenCapture", value: value)
        }
    }

    /// Pasteboard / clipboard string IO wrappers.
    public enum Pasteboard {
        nonisolated public static var canReadStrings: Bool {
            resolvedBool(override: testPasteboardCanReadStrings, detector: detectPasteboardCanReadStrings)
        }

        nonisolated public static var canWriteStrings: Bool {
            resolvedBool(override: testPasteboardCanWriteStrings, detector: detectPasteboardCanWriteStrings)
        }

        public static func setTestCanReadStrings(_ value: Bool?) {
            setThreadOptionalBool(key: "testPasteboardCanReadStrings", value: value)
        }

        public static func setTestCanWriteStrings(_ value: Bool?) {
            setThreadOptionalBool(key: "testPasteboardCanWriteStrings", value: value)
        }
    }

    /// Namespaced access to existing accessibility probes.
    public enum Accessibility {
        nonisolated public static var supportsVoiceOver: Bool { RuntimeCapabilityDetection.supportsVoiceOver }
        nonisolated public static var supportsSwitchControl: Bool { RuntimeCapabilityDetection.supportsSwitchControl }
        nonisolated public static var supportsAssistiveTouch: Bool { RuntimeCapabilityDetection.supportsAssistiveTouch }

        @MainActor public static var isHighContrastEnabled: Bool { RuntimeCapabilityDetection.isHighContrastEnabled }

        public static func setTestVoiceOver(_ value: Bool?) { RuntimeCapabilityDetection.setTestVoiceOver(value) }
        public static func setTestSwitchControl(_ value: Bool?) { RuntimeCapabilityDetection.setTestSwitchControl(value) }
        public static func setTestAssistiveTouch(_ value: Bool?) { RuntimeCapabilityDetection.setTestAssistiveTouch(value) }
        public static func setTestHighContrast(_ value: Bool?) { RuntimeCapabilityDetection.setTestHighContrast(value) }
    }

    /// Camera, photo library picker, Photos read access, and live VisionKit data scanner (#252).
    public enum Photos {
        /// Photos library authorization / limitation (not the same as “picker UI may appear”).
        public enum ReadAccessLevel: Sendable, Equatable {
            case notDetermined
            case denied
            case limited
            case authorized
            /// Host OS does not expose `Photos` / read-status APIs for this binary.
            case unavailable
        }

        /// Camera capture / preview is possible (runtime probe; `false` on Simulator without camera).
        nonisolated public static var hasCamera: Bool {
            if let forced = testPhotosHasCamera { return forced }
            return detectPhotosHasCamera()
        }

        /// User can open a system photo / image picker (not full read access).
        nonisolated public static var isPhotoLibraryPickerAvailable: Bool {
            if let forced = testPhotosIsPhotoLibraryPickerAvailable { return forced }
            return detectPhotosLibraryPickerAvailable()
        }

        /// Photos library read/write authorization snapshot where `Photos` is linked.
        nonisolated public static var photoLibraryReadAccessLevel: ReadAccessLevel {
            detectPhotosLibraryReadAccessLevel()
        }

        /// Live data scanner (`DataScannerViewController`); iOS 16+ when VisionKit reports supported and available.
        nonisolated public static var supportsLiveDataScanner: Bool {
            if let forced = testPhotosSupportsLiveDataScanner { return forced }
            return detectSupportsLiveDataScanner()
        }

        public static func setTestHasCamera(_ value: Bool?) {
            setThreadOptionalBool(key: "testPhotosHasCamera", value: value)
        }

        public static func setTestIsPhotoLibraryPickerAvailable(_ value: Bool?) {
            setThreadOptionalBool(key: "testPhotosIsPhotoLibraryPickerAvailable", value: value)
        }

        public static func setTestSupportsLiveDataScanner(_ value: Bool?) {
            setThreadOptionalBool(key: "testPhotosSupportsLiveDataScanner", value: value)
        }
    }

    /// Shared thread-local `Bool?` override helper for namespaced surfaces (#253).
    private static func setThreadOptionalBool(key: String, value: Bool?) {
        if let value {
            Thread.current.threadDictionary[key] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: key)
        }
    }

    private static func resolvedBool(override: Bool?, detector: () -> Bool) -> Bool {
        if let forced = override { return forced }
        return detector()
    }

    /// Runs a MainActor-isolated sync probe only when already on the main thread.
    /// Returns `nil` when called off-main, so callers can safely fall back.
    private static func withMainActorProbe<T: Sendable>(_ probe: @MainActor () -> T) -> T? {
        guard Thread.isMainThread else { return nil }
        return MainActor.assumeIsolated {
            probe()
        }
    }

    #if canImport(Network)
    private static let networkPathLock = NSLock()
    private nonisolated(unsafe) static var networkPathSnapshot: NWPath?
    private static let networkPathMonitor: NWPathMonitor = {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            networkPathLock.lock()
            networkPathSnapshot = path
            networkPathLock.unlock()
        }
        monitor.start(queue: DispatchQueue(label: "SixLayerFramework.RuntimeCapabilityDetection.Network"))
        return monitor
    }()
    #endif

    private static func detectNetworkIsConstrained() -> Bool {
        #if canImport(Network)
        _ = networkPathMonitor
        networkPathLock.lock()
        let path = networkPathSnapshot
        networkPathLock.unlock()
        guard path != nil else { return false }
        return path?.isConstrained ?? false
        #else
        return false
        #endif
    }

    private static func detectNetworkIsExpensive() -> Bool {
        #if canImport(Network)
        _ = networkPathMonitor
        networkPathLock.lock()
        let path = networkPathSnapshot
        networkPathLock.unlock()
        guard path != nil else { return false }
        return path?.isExpensive ?? false
        #else
        return false
        #endif
    }

    private static func detectNetworkHasPathSnapshot() -> Bool {
        #if canImport(Network)
        _ = networkPathMonitor
        networkPathLock.lock()
        let hasPath = networkPathSnapshot != nil
        networkPathLock.unlock()
        return hasPath
        #else
        return false
        #endif
    }

    private static func detectMediaHasMicrophoneInput() -> Bool {
        // Single `#if` chain avoids nested `canImport` + `os` blocks that trip some toolchain parsers
        // (“further conditions after #else”) while preserving visionOS 2.1+ microphone adoption timing.
        #if !canImport(AVFoundation) || os(watchOS)
        return false
        #elseif os(visionOS)
        if #available(visionOS 2.1, *) {
            return AVCaptureDevice.default(for: .audio) != nil
        }
        return false
        #else
        return AVCaptureDevice.default(for: .audio) != nil
        #endif
    }

    private static func detectMediaSupportsScreenCapture() -> Bool {
        #if canImport(ReplayKit)
        #if os(iOS) || os(tvOS)
        return withMainActorProbe {
            RPScreenRecorder.shared().isAvailable
        } ?? false
        #else
        return false
        #endif
        #elseif canImport(ScreenCaptureKit)
        #if os(macOS)
        if #available(macOS 12.3, *) {
            return true
        }
        #endif
        return false
        #else
        return false
        #endif
    }

    private static func detectPasteboardCanReadStrings() -> Bool {
        // UIPasteboard is unavailable on tvOS and watchOS; use AppKit on macOS only.
        #if os(iOS) || os(visionOS)
        return withMainActorProbe {
            UIPasteboard.general.hasStrings
        } ?? false
        #elseif os(tvOS)
        // UIPasteboard is API_UNAVAILABLE on tvOS.
        return false
        #elseif os(macOS)
        return NSPasteboard.general.canReadObject(forClasses: [NSString.self], options: nil)
        #else
        return false
        #endif
    }

    private static func detectPasteboardCanWriteStrings() -> Bool {
        #if os(iOS) || os(visionOS)
        return withMainActorProbe {
            _ = UIPasteboard.general
            return true
        } ?? false
        #elseif os(tvOS)
        return false
        #elseif os(macOS)
        return true
        #else
        return false
        #endif
    }

    private static func detectPhotosHasCamera() -> Bool {
        #if os(iOS)
        return withMainActorProbe {
            UIImagePickerController.isSourceTypeAvailable(.camera)
        } ?? false
        #elseif os(macOS)
        #if canImport(AVFoundation)
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: AVMediaType.video,
            position: .unspecified
        )
        return !session.devices.isEmpty
        #else
        return false
        #endif
        #else
        return false
        #endif
    }

    private static func detectPhotosLibraryPickerAvailable() -> Bool {
        #if os(iOS)
        return withMainActorProbe {
            UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        } ?? false
        #elseif os(macOS)
        // `platformPhotoPicker_L4` uses `NSOpenPanel` for images on macOS; treat as available when AppKit exists.
        return true
        #else
        return false
        #endif
    }

    private static func detectPhotosLibraryReadAccessLevel() -> Photos.ReadAccessLevel {
        #if canImport(Photos)
        #if os(iOS) || os(macOS)
        if #available(iOS 14, macOS 11, *) {
            switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
            case .notDetermined:
                return .notDetermined
            case .restricted, .denied:
                return .denied
            case .limited:
                return .limited
            case .authorized:
                return .authorized
            @unknown default:
                return .unavailable
            }
        }
        #endif
        #endif
        return .unavailable
    }

    private static func detectSupportsLiveDataScanner() -> Bool {
        #if os(iOS)
        #if canImport(VisionKit)
        if #available(iOS 16.0, *) {
            // VisionKit scanner statics are MainActor-isolated on current SDKs.
            return withMainActorProbe {
                DataScannerViewController.isSupported && DataScannerViewController.isAvailable
            } ?? false
        }
        #endif
        #endif
        return false
    }

    private static func detectSupportsImageAnalyzer() -> Bool {
        #if os(iOS)
        #if canImport(VisionKit)
        if #available(iOS 16.0, *) {
            return withMainActorProbe {
                ImageAnalyzer.isSupported
            } ?? false
        }
        #endif
        #endif
        return false
    }

    private static func detectSupportsDocumentCamera() -> Bool {
        #if os(iOS)
        #if canImport(Vision)
        if #available(iOS 13.0, *) {
            return withMainActorProbe {
                VNDocumentCameraViewController.isSupported
            } ?? false
        }
        #endif
        #endif
        return false
    }

    /// Legacy top-level probe; prefer ``Vision/isFrameworkAvailable`` (GitHub #253).
    @available(*, deprecated, message: "Use RuntimeCapabilityDetection.Vision.isFrameworkAvailable (GitHub #253).")
    nonisolated public static var supportsVision: Bool {
        Vision.isFrameworkAvailable
    }

    /// Legacy top-level probe; prefer ``Vision/supportsOCR`` (GitHub #253).
    @available(*, deprecated, message: "Use RuntimeCapabilityDetection.Vision.supportsOCR (GitHub #253).")
    nonisolated public static var supportsOCR: Bool {
        Vision.supportsOCR
    }
    
    // MARK: - Security-Scoped Resource Detection
    
    /// Detects if security-scoped resource access is supported at runtime
    /// Security-scoped resources are used for accessing files outside the app's sandbox
    /// - **macOS**: Required for App Sandbox (accessing files outside sandbox)
    /// - **iOS**: Required for document picker (accessing files outside app's sandbox)
    /// - **Other platforms**: Not supported
    ///
    /// Prefer ``Files/supportsSecurityScopedResources`` (GitHub #253).
    /// This method actually checks if the API is available at runtime by testing
    /// if `URL.startAccessingSecurityScopedResource()` responds to the selector.
    /// Note: nonisolated - only checks API availability (no MainActor needed)
    @available(*, deprecated, message: "Use RuntimeCapabilityDetection.Files.supportsSecurityScopedResources (GitHub #253).")
    nonisolated public static var supportsSecurityScopedResources: Bool {
        Files.supportsSecurityScopedResources
    }
    
    /// Detects if security-scoped bookmark persistence is supported at runtime
    /// Bookmarks allow persisting access to files across app launches
    /// - **macOS**: Full support for bookmark persistence
    /// - **iOS**: No bookmark persistence support (security-scoped access is temporary)
    /// - **Other platforms**: Not supported
    ///
    /// Prefer ``Files/supportsSecurityScopedBookmarks`` (GitHub #253).
    /// This method actually checks if the bookmark APIs are available at runtime.
    /// Note: nonisolated - only checks API availability (no MainActor needed)
    @available(*, deprecated, message: "Use RuntimeCapabilityDetection.Files.supportsSecurityScopedBookmarks (GitHub #253).")
    nonisolated public static var supportsSecurityScopedBookmarks: Bool {
        Files.supportsSecurityScopedBookmarks
    }
    
    /// Runtime detection of security-scoped resource support
    /// Checks if URL.startAccessingSecurityScopedResource() is available
    /// Security-scoped resources are available on macOS 10.7+ and iOS 8.0+
    private static func detectSecurityScopedResourceSupport() -> Bool {
        #if os(macOS)
        // macOS 10.7+ supports security-scoped resources
        if #available(macOS 10.7, *) {
            return true
        }
        return false
        #elseif os(iOS)
        // iOS 8.0+ supports security-scoped resources
        if #available(iOS 8.0, *) {
            return true
        }
        return false
        #else
        // watchOS, tvOS, and visionOS do not support security-scoped resources
        return false
        #endif
    }
    
    /// Runtime detection of security-scoped bookmark support
    /// Checks if URL.bookmarkData() is available (macOS-only API)
    private static func detectSecurityScopedBookmarkSupport() -> Bool {
        // Bookmarks require bookmarkData(options:includingResourceValuesForKeys:relativeTo:)
        // which is a macOS-only API. Since this method has complex parameters,
        // we can't easily use responds(to:) to check for it.
        //
        // However, we know that:
        // 1. Bookmarks are only available on macOS
        // 2. Security-scoped resources are a prerequisite for bookmarks
        // 3. If security-scoped resources work on macOS, bookmarks should work too
        
        // First check if security-scoped resources are available (prerequisite)
        guard detectSecurityScopedResourceSupport() else {
            return false
        }
        
        // Detect macOS at runtime by checking for macOS-specific classes
        // NSWorkspace is macOS-specific and can be detected at runtime
        // NSClassFromString works on all platforms, so this is a true runtime check
        if NSClassFromString("NSWorkspace") != nil {
            // On macOS, if security-scoped resources work, bookmarks should work too
            // This is a reasonable assumption since they're part of the same API family
            // and bookmarkData is available on all macOS versions that support security-scoped resources
            return true
        }
        
        // On other platforms (iOS, watchOS, tvOS, visionOS), bookmarks are not supported
        // Even though iOS has security-scoped resources, it doesn't have bookmarkData
        return false
    }

    // MARK: - Test override hooks (public for consumer app tests; Resolves #311)

    private static func logIgnoredTestOverrideOnce(key: String, message: String) {
        if Thread.current.threadDictionary[key] == nil {
            Thread.current.threadDictionary[key] = true
            os_log("%{public}@", log: .default, type: .info, message)
        }
    }

    private static func writeTestTouchSupportOverride(_ value: Bool?) {
        #if os(iOS) || os(watchOS)
        switch value {
        case .some(false):
            logIgnoredTestOverrideOnce(
                key: "SixLayerFramework.didLogIgnoredTestTouchFalse",
                message: "SixLayerFramework: setTestTouchSupport(false) ignored on touch-first platform (primary touch is a platform guarantee)."
            )
        default:
            Thread.current.threadDictionary.removeObject(forKey: "SixLayerFramework.didLogIgnoredTestTouchFalse")
        }
        #endif
        if let value {
            Thread.current.threadDictionary["testTouchSupport"] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: "testTouchSupport")
        }
    }

    private static func writeTestAssistiveTouchOverride(_ value: Bool?) {
        if let value {
            Thread.current.threadDictionary["testAssistiveTouch"] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: "testAssistiveTouch")
        }
    }

    /// Override touch support detection for testing (thread-local).
    ///
    /// **iOS and watchOS:** `false` is ignored — touch is a platform guarantee. On other platforms,
    /// forcing touch off also clears AssistiveTouch (precursor dependency). Haptics are independent.
    public static func setTestTouchSupport(_ value: Bool?) {
        if value == false {
            writeTestAssistiveTouchOverride(false)
        }
        writeTestTouchSupportOverride(value)
    }

    /// Override haptic feedback detection for testing
    public static func setTestHapticFeedback(_ value: Bool?) {
        if let value {
            Thread.current.threadDictionary["testHapticFeedback"] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: "testHapticFeedback")
        }
    }

    /// Override hover detection for testing
    public static func setTestHover(_ value: Bool?) {
        if let value {
            Thread.current.threadDictionary["testHover"] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: "testHover")
        }
    }

    /// Override VoiceOver detection for testing
    public static func setTestVoiceOver(_ value: Bool?) {
        if let value {
            Thread.current.threadDictionary["testVoiceOver"] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: "testVoiceOver")
        }
    }

    /// Override Switch Control detection for testing
    public static func setTestSwitchControl(_ value: Bool?) {
        if let value {
            Thread.current.threadDictionary["testSwitchControl"] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: "testSwitchControl")
        }
    }

    /// Override AssistiveTouch detection for testing.
    ///
    /// Forcing AssistiveTouch on enables touch; unavailable on platforms that do not ship the feature.
    public static func setTestAssistiveTouch(_ value: Bool?) {
        guard let value else {
            writeTestAssistiveTouchOverride(nil)
            return
        }
        if value {
            guard currentPlatform.supportsAssistiveTouch else {
                logIgnoredTestOverrideOnce(
                    key: "SixLayerFramework.didLogIgnoredTestAssistiveTouchTrue",
                    message: "SixLayerFramework: setTestAssistiveTouch(true) ignored — AssistiveTouch is unavailable on this platform."
                )
                return
            }
            writeTestTouchSupportOverride(true)
            writeTestAssistiveTouchOverride(true)
            return
        }
        writeTestAssistiveTouchOverride(false)
    }

    /// Override high contrast mode detection for testing
    public static func setTestHighContrast(_ value: Bool?) {
        if let value {
            Thread.current.threadDictionary["testHighContrast"] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: "testHighContrast")
        }
    }

    #if os(iOS)
    /// Override iOS hover-device capability probe (separate from `setTestHover` result override).
    public static func setTestiOSHoverDeviceCapability(_ value: Bool?) {
        if let value {
            Thread.current.threadDictionary["testiOSHoverDeviceCapability"] = value
        } else {
            Thread.current.threadDictionary.removeObject(forKey: "testiOSHoverDeviceCapability")
        }
    }
    #endif

    /// Clear all capability overrides for testing (`nil` clears by **removing** thread-dictionary entries).
    public static func clearAllCapabilityOverrides() {
        setTestTouchSupport(nil)
        setTestHapticFeedback(nil)
        setTestHover(nil)
        setTestVoiceOver(nil)
        setTestSwitchControl(nil)
        setTestAssistiveTouch(nil)
        setTestHighContrast(nil)
        #if os(iOS)
        setTestiOSHoverDeviceCapability(nil)
        #endif
        Photos.setTestHasCamera(nil)
        Photos.setTestIsPhotoLibraryPickerAvailable(nil)
        Photos.setTestSupportsLiveDataScanner(nil)
        Vision.setTestIsFrameworkAvailable(nil)
        Vision.setTestSupportsOCR(nil)
        Vision.setTestSupportsImageAnalyzer(nil)
        Vision.setTestSupportsDocumentCamera(nil)
        Files.setTestSupportsSecurityScopedResources(nil)
        Files.setTestSupportsSecurityScopedBookmarks(nil)
        Network.setTestIsConstrained(nil)
        Network.setTestIsExpensive(nil)
        Network.setTestHasPathSnapshot(nil)
        Media.setTestHasMicrophoneInput(nil)
        Media.setTestSupportsScreenCapture(nil)
        Pasteboard.setTestCanReadStrings(nil)
        Pasteboard.setTestCanWriteStrings(nil)
        CapabilityOverride.clearThreadIsolationFromCurrentThread()
        RuntimeCapabilityHarness.scrubLegacyCapabilityKeysFromUserDefaultsStandard()
    }
}

// MARK: - Testing Configuration

/// Testing-specific capability detection with predictable defaults
public struct TestingCapabilityDetection {
    
    /// Whether we're currently in testing mode
    public static var isTestingMode: Bool {
        #if DEBUG
        // Check for XCTest environment variables
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil ||
               environment["XCTestSessionIdentifier"] != nil ||
               environment["XCTestBundlePath"] != nil ||
               NSClassFromString("XCTestCase") != nil
        #else
        return false
        #endif
    }
    
    /// Get testing defaults for each platform
    public static func getTestingDefaults(for platform: SixLayerPlatform) -> TestingCapabilityDefaults {
        switch platform {
        case .iOS:
            return TestingCapabilityDefaults(
                supportsTouch: true,
                supportsHapticFeedback: true,
                supportsHover: false, // Will be true for iPad in actual detection
                supportsVoiceOver: true, // iOS supports VoiceOver
                supportsSwitchControl: true, // iOS supports Switch Control
                supportsAssistiveTouch: true, // iOS supports AssistiveTouch
                supportsVision: true, // iOS supports Vision framework
                supportsOCR: true, // iOS supports OCR through Vision framework
                supportsSecurityScopedResources: true, // iOS supports security-scoped resources (document picker)
                supportsSecurityScopedBookmarks: false // iOS doesn't support bookmark persistence
            )
        case .macOS:
            return TestingCapabilityDefaults(
                supportsTouch: false, // Testing default - can be overridden
                supportsHapticFeedback: false,
                supportsHover: true,
                supportsVoiceOver: true, // macOS supports VoiceOver
                supportsSwitchControl: true, // macOS supports Switch Control
                supportsAssistiveTouch: false,
                supportsVision: true, // macOS supports Vision framework
                supportsOCR: true, // macOS supports OCR through Vision framework
                supportsSecurityScopedResources: true, // macOS supports security-scoped resources (App Sandbox)
                supportsSecurityScopedBookmarks: true // macOS supports bookmark persistence
            )
        case .watchOS:
            return TestingCapabilityDefaults(
                supportsTouch: true,
                supportsHapticFeedback: true,
                supportsHover: false,
                supportsVoiceOver: true, // Apple Watch supports VoiceOver
                supportsSwitchControl: true, // Apple Watch supports Switch Control
                supportsAssistiveTouch: true, // Apple Watch supports AssistiveTouch
                supportsVision: false, // Apple Watch doesn't support Vision framework
                supportsOCR: false, // Apple Watch doesn't support OCR
                supportsSecurityScopedResources: false, // watchOS doesn't support security-scoped resources
                supportsSecurityScopedBookmarks: false // watchOS doesn't support bookmark persistence
            )
        case .tvOS:
            return TestingCapabilityDefaults(
                supportsTouch: false,
                supportsHapticFeedback: false,
                supportsHover: false,
                supportsVoiceOver: true, // Apple TV supports VoiceOver
                supportsSwitchControl: true, // Apple TV supports Switch Control
                supportsAssistiveTouch: false, // Apple TV doesn't have AssistiveTouch
                supportsVision: false, // Apple TV doesn't support Vision framework
                supportsOCR: false, // Apple TV doesn't support OCR
                supportsSecurityScopedResources: false, // tvOS doesn't support security-scoped resources
                supportsSecurityScopedBookmarks: false // tvOS doesn't support bookmark persistence
            )
        case .visionOS:
            return TestingCapabilityDefaults(
                supportsTouch: false, // visionOS is spatial computing, not touchscreen
                supportsHapticFeedback: false, // visionOS doesn't have native haptic feedback
                supportsHover: true, // visionOS supports hover through hand tracking
                supportsVoiceOver: true, // Vision Pro supports VoiceOver
                supportsSwitchControl: true, // Vision Pro supports Switch Control
                supportsAssistiveTouch: false, // AssistiveTouch is iOS-specific, not available on visionOS
                supportsVision: true, // Vision Pro supports Vision framework
                supportsOCR: true, // Vision Pro supports OCR through Vision framework
                supportsSecurityScopedResources: false, // visionOS doesn't support security-scoped resources
                supportsSecurityScopedBookmarks: false // visionOS doesn't support bookmark persistence
            )
        }
    }
}

/// Testing capability defaults for predictable test behavior
public struct TestingCapabilityDefaults {
    public let supportsTouch: Bool
    public let supportsHapticFeedback: Bool
    public let supportsHover: Bool
    public let supportsVoiceOver: Bool
    public let supportsSwitchControl: Bool
    public let supportsAssistiveTouch: Bool
    public let supportsVision: Bool
    public let supportsOCR: Bool
    public let supportsSecurityScopedResources: Bool
    public let supportsSecurityScopedBookmarks: Bool
}

// MARK: - Configuration Override

/// Allows users to override capability detection for testing or special configurations
public struct CapabilityOverride {

    private static let touchThreadIsolationKey = "SixLayerFramework.CapabilityOverride.ThreadIsolation.TouchSupport"
    private static let hapticThreadIsolationKey = "SixLayerFramework.CapabilityOverride.ThreadIsolation.HapticSupport"
    private static let hoverThreadIsolationKey = "SixLayerFramework.CapabilityOverride.ThreadIsolation.HoverSupport"

    /// Clears thread-local `CapabilityOverride` values for the current thread (GitHub #236).
    public static func clearThreadIsolationFromCurrentThread() {
        Thread.current.threadDictionary.removeObject(forKey: touchThreadIsolationKey)
        Thread.current.threadDictionary.removeObject(forKey: hapticThreadIsolationKey)
        Thread.current.threadDictionary.removeObject(forKey: hoverThreadIsolationKey)
    }

    /// Override touch support (useful for testing with external touchscreens)
    public static var touchSupport: Bool? {
        get {
            if let number = Thread.current.threadDictionary[touchThreadIsolationKey] as? NSNumber {
                return number.boolValue
            }
            return UserDefaults.standard.object(forKey: "SixLayerFramework.Override.TouchSupport") as? Bool
        }
        set {
            if let newValue {
                Thread.current.threadDictionary[touchThreadIsolationKey] = NSNumber(value: newValue)
            } else {
                Thread.current.threadDictionary.removeObject(forKey: touchThreadIsolationKey)
            }
            UserDefaults.standard.removeObject(forKey: "SixLayerFramework.Override.TouchSupport")
        }
    }

    /// Override haptic feedback support
    public static var hapticSupport: Bool? {
        get {
            if let number = Thread.current.threadDictionary[hapticThreadIsolationKey] as? NSNumber {
                return number.boolValue
            }
            return UserDefaults.standard.object(forKey: "SixLayerFramework.Override.HapticSupport") as? Bool
        }
        set {
            if let newValue {
                Thread.current.threadDictionary[hapticThreadIsolationKey] = NSNumber(value: newValue)
            } else {
                Thread.current.threadDictionary.removeObject(forKey: hapticThreadIsolationKey)
            }
            UserDefaults.standard.removeObject(forKey: "SixLayerFramework.Override.HapticSupport")
        }
    }

    /// Override hover support
    public static var hoverSupport: Bool? {
        get {
            if let number = Thread.current.threadDictionary[hoverThreadIsolationKey] as? NSNumber {
                return number.boolValue
            }
            return UserDefaults.standard.object(forKey: "SixLayerFramework.Override.HoverSupport") as? Bool
        }
        set {
            if let newValue {
                Thread.current.threadDictionary[hoverThreadIsolationKey] = NSNumber(value: newValue)
            } else {
                Thread.current.threadDictionary.removeObject(forKey: hoverThreadIsolationKey)
            }
            UserDefaults.standard.removeObject(forKey: "SixLayerFramework.Override.HoverSupport")
        }
    }
}

// MARK: - Enhanced Runtime Detection with Overrides

public extension RuntimeCapabilityDetection {
    
    /// Touch support with override capability
    @MainActor
    static var supportsTouchWithOverride: Bool {
        if let override = CapabilityOverride.touchSupport {
            return override
        }
        return supportsTouch
    }
    
    /// Haptic feedback support with override capability
    @MainActor
    static var supportsHapticFeedbackWithOverride: Bool {
        if let override = CapabilityOverride.hapticSupport {
            return override
        }
        return supportsHapticFeedback
    }
    
    /// Hover support with override capability
    @MainActor
    static var supportsHoverWithOverride: Bool {
        if let override = CapabilityOverride.hoverSupport {
            return override
        }
        return supportsHover
    }
    
    /// Minimum touch target size for accessibility compliance
    /// Combines platform philosophy with runtime touch capability
    ///
    /// Apple HIG: Touch targets should be at least 44x44 points on touch-first platforms
    /// (iOS/watchOS). For non-touch-first platforms, if touch capability is detected,
    /// accessibility standards still apply.
    ///
    /// Note: nonisolated - this property considers both platform and runtime capability
    /// Uses PlatformStrategy to reduce code duplication (Issue #140)
    nonisolated static var minTouchTarget: CGFloat {
        // DTRT: Respect each platform's primary interaction model.
        //  - Touch-first (iOS/watchOS): always 44pt (Apple HIG).
        //  - Focus-first (tvOS): 60pt (Apple tvOS HIG focus target at 10-foot distance).
        //  - visionOS: always 60pt (Apple visionOS HIG gaze+pinch minimum).
        //  - Pointer-driven (macOS): 44pt if touch is detected at runtime, else 0pt.
        // Delegate to PlatformStrategy which already encodes these rules (Issue #237).
        return currentPlatform.minTouchTarget
    }
    
    /// Hover delay for platforms that support hover
    /// Returns platform-appropriate hover delay values, or 0.0 if hover is not supported.
    /// 
    /// This property checks `supportsHover` at runtime and returns 0.0 if hover is not available.
    /// If hover is supported, returns the platform-appropriate delay value.
    /// 
    /// Platform hover delays (when hover is supported):
    /// - macOS: 0.5s (mouse/trackpad hover)
    /// - visionOS: 0.5s (hand tracking hover)
    /// - iOS: 0.5s (iPad with Apple Pencil hover, 0.0 for iPhone - determined at runtime)
    /// - watchOS: 0.0s (no hover support)
    /// - tvOS: 0.0s (no hover support)
    /// 
    /// Note: nonisolated - this property only does platform switching, no MainActor APIs accessed
    /// Uses PlatformStrategy to reduce code duplication (Issue #140)
    /// PlatformStrategy.hoverDelay already checks runtime support, so we can use it directly
    nonisolated static var hoverDelay: TimeInterval {
        // PlatformStrategy.hoverDelay already checks RuntimeCapabilityDetection.supportsHover
        // and returns 0.0 if not supported, so we can use it directly
        return currentPlatform.hoverDelay
    }
}

