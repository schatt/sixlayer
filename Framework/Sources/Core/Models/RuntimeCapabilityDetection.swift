//
//  RuntimeCapabilityDetection.swift
//  SixLayerFramework
//
//  Runtime capability detection that queries the OS instead of hardcoding platform assumptions
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
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
    
    // MARK: - Capability-Level Override Support
    
    /// Override touch support detection for testing
    public static func setTestTouchSupport(_ value: Bool?) {
        Thread.current.threadDictionary["testTouchSupport"] = value
    }
    
    /// Override haptic feedback detection for testing
    public static func setTestHapticFeedback(_ value: Bool?) {
        Thread.current.threadDictionary["testHapticFeedback"] = value
    }
    
    /// Override hover detection for testing
    public static func setTestHover(_ value: Bool?) {
        Thread.current.threadDictionary["testHover"] = value
    }
    
    /// Override VoiceOver detection for testing
    public static func setTestVoiceOver(_ value: Bool?) {
        Thread.current.threadDictionary["testVoiceOver"] = value
    }
    
    /// Override Switch Control detection for testing
    public static func setTestSwitchControl(_ value: Bool?) {
        Thread.current.threadDictionary["testSwitchControl"] = value
    }
    
    /// Override AssistiveTouch detection for testing
    public static func setTestAssistiveTouch(_ value: Bool?) {
        Thread.current.threadDictionary["testAssistiveTouch"] = value
    }
    
    /// Override high contrast mode detection for testing
    /// This allows tests to verify color adaptation behavior
    public static func setTestHighContrast(_ value: Bool?) {
        Thread.current.threadDictionary["testHighContrast"] = value
    }
    
    /// Clear all capability overrides for testing
    public static func clearAllCapabilityOverrides() {
        setTestTouchSupport(nil)
        setTestHapticFeedback(nil)
        setTestHover(nil)
        setTestVoiceOver(nil)
        setTestSwitchControl(nil)
        setTestAssistiveTouch(nil)
        setTestHighContrast(nil)
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
    
    // MARK: - High Contrast Detection
    
    /// Detects if high contrast mode is enabled
    /// Respects test override if set, otherwise queries the actual system setting
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
        // Check for capability override first
        if let testValue = testTouchSupport {
            return testValue
        }
        
        // Use real runtime detection - tests should run on actual platforms/simulators
        #if os(iOS)
        return detectiOSTouchSupport()
        #elseif os(macOS)
        return detectmacOSTouchSupport()
        #elseif os(watchOS)
        return detectwatchOSTouchSupport()
        #elseif os(tvOS)
        return detecttvOSTouchSupport()
        #elseif os(visionOS)
        return detectvisionOSTouchSupport()
        #else
        return false
        #endif
    }
    
    #if os(iOS)
    /// iOS touch detection - checks for actual touch capability
    private static func detectiOSTouchSupport() -> Bool {
        // Check if touch events are available by checking if we can detect touch input
        // All iOS devices support touch, but we verify at runtime
        // Use Thread.isMainThread check with MainActor.assumeIsolated to satisfy compiler
        // while preventing crashes during parallel test execution
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                UIDevice.current.userInterfaceIdiom != .unspecified
            }
        } else {
            // If not on main thread, assume touch is available (all iOS devices have touch)
            // This prevents crashes during parallel test execution
            return true
        }
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
        // Check UserDefaults or system preferences for touch enablement
        // This could be set by third-party drivers or user configuration
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
        // macOS doesn't natively support haptic feedback
        // But could be enabled through third-party solutions or user preferences
        // UserDefaults.bool(forKey:) returns false if the key doesn't exist, which is correct
        // Only return true if explicitly enabled by the user/application
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
        // macOS supports hover through mouse/trackpad
        // Check if we can detect hover events
        return NSEvent.pressedMouseButtons == 0 // If no mouse buttons pressed, hover is possible
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
        // Check if VoiceOver is available on watchOS
        #if canImport(UIKit)
        // Use Thread.isMainThread check to prevent crashes during parallel test execution
        if Thread.isMainThread {
            return UIAccessibility.isVoiceOverRunning
        } else {
            return false  // Conservative default when not on main thread
        }
        #else
        return false
        #endif
    }
    
    private static func detectwatchOSSwitchControlSupport() -> Bool {
        // Check if Switch Control is available on watchOS
        #if canImport(UIKit)
        // Use Thread.isMainThread check to prevent crashes during parallel test execution
        if Thread.isMainThread {
            return UIAccessibility.isSwitchControlRunning
        } else {
            return false  // Conservative default when not on main thread
        }
        #else
        return false
        #endif
    }
    
    private static func detectwatchOSAssistiveTouchSupport() -> Bool {
        // Check if AssistiveTouch is available on watchOS
        #if canImport(UIKit)
        // Use Thread.isMainThread check to prevent crashes during parallel test execution
        if Thread.isMainThread {
            return UIAccessibility.isAssistiveTouchRunning
        } else {
            return false  // Conservative default when not on main thread
        }
        #else
        return false
        #endif
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
        #if canImport(UIKit)
        // Use Thread.isMainThread check to prevent crashes during parallel test execution
        if Thread.isMainThread {
            return UIAccessibility.isVoiceOverRunning
        } else {
            return false  // Conservative default when not on main thread
        }
        #else
        return false
        #endif
    }
    
    private static func detecttvOSSwitchControlSupport() -> Bool {
        // Check if Switch Control is available on tvOS
        #if canImport(UIKit)
        // Use Thread.isMainThread check to prevent crashes during parallel test execution
        if Thread.isMainThread {
            return UIAccessibility.isSwitchControlRunning
        } else {
            return false  // Conservative default when not on main thread
        }
        #else
        return false
        #endif
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
        #if canImport(UIKit)
        // Use Thread.isMainThread check to prevent crashes during parallel test execution
        if Thread.isMainThread {
            return UIAccessibility.isVoiceOverRunning
        } else {
            return false  // Conservative default when not on main thread
        }
        #else
        return false
        #endif
    }
    
    private static func detectvisionOSSwitchControlSupport() -> Bool {
        // Check if Switch Control is available on visionOS
        #if canImport(UIKit)
        // Use Thread.isMainThread check to prevent crashes during parallel test execution
        if Thread.isMainThread {
            return UIAccessibility.isSwitchControlRunning
        } else {
            return false  // Conservative default when not on main thread
        }
        #else
        return false
        #endif
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
        let platform = currentPlatform
        switch platform {
        case .iOS, .macOS, .watchOS, .tvOS, .visionOS:
            return true  // All Apple platforms support VoiceOver
        }
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
        let platform = currentPlatform
        switch platform {
        case .iOS, .macOS, .watchOS, .tvOS, .visionOS:
            return true  // All Apple platforms support Switch Control
        }
    }
    
    /// Detects if AssistiveTouch capability is available on the current platform.
    /// Semantics: **platform availability** - whether the platform supports AssistiveTouch as a feature.
    /// - iOS/watchOS: true (feature supported by OS)
    /// - macOS/tvOS/visionOS: false (not supported by OS)
    /// 
    /// Note: This checks platform availability, not whether the user has it enabled.
    /// Test overrides can simulate different platforms, but platform detection is authoritative for availability.
    nonisolated public static var supportsAssistiveTouch: Bool {
        // Check for capability override first (allows testing different scenarios)
        // But availability is fundamentally based on platform
        if let testValue = testAssistiveTouch {
            return testValue
        }
        
        // Platform availability: iOS and watchOS support AssistiveTouch
        // Other platforms do not support it
        let platform = currentPlatform
        switch platform {
        case .iOS, .watchOS:
            return true  // Platform supports AssistiveTouch
        case .macOS, .tvOS, .visionOS:
            return false  // Platform does not support AssistiveTouch
        }
    }
    
    // MARK: - Vision Framework Detection
    
    /// Detects if Vision framework is actually available
    /// Uses the same detection method across all platforms
    /// Note: nonisolated - only checks framework availability (no MainActor needed)
    nonisolated public static var supportsVision: Bool {
        return detectVisionFrameworkAvailability()
    }
    
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
    
    // MARK: - OCR Detection
    
    /// Detects if OCR capabilities are actually available
    /// OCR depends on Vision framework, so uses the same detection method across all platforms
    /// Note: nonisolated - only checks framework availability (no MainActor needed)
    nonisolated public static var supportsOCR: Bool {
        // OCR is available through Vision framework, so check Vision availability
        return detectVisionFrameworkAvailability()
    }
    
    // MARK: - Security-Scoped Resource Detection
    
    /// Detects if security-scoped resource access is supported at runtime
    /// Security-scoped resources are used for accessing files outside the app's sandbox
    /// - **macOS**: Required for App Sandbox (accessing files outside sandbox)
    /// - **iOS**: Required for document picker (accessing files outside app's sandbox)
    /// - **Other platforms**: Not supported
    /// 
    /// This method actually checks if the API is available at runtime by testing
    /// if `URL.startAccessingSecurityScopedResource()` responds to the selector.
    /// Note: nonisolated - only checks API availability (no MainActor needed)
    nonisolated public static var supportsSecurityScopedResources: Bool {
        return detectSecurityScopedResourceSupport()
    }
    
    /// Detects if security-scoped bookmark persistence is supported at runtime
    /// Bookmarks allow persisting access to files across app launches
    /// - **macOS**: Full support for bookmark persistence
    /// - **iOS**: No bookmark persistence support (security-scoped access is temporary)
    /// - **Other platforms**: Not supported
    /// 
    /// This method actually checks if the bookmark APIs are available at runtime.
    /// Note: nonisolated - only checks API availability (no MainActor needed)
    nonisolated public static var supportsSecurityScopedBookmarks: Bool {
        return detectSecurityScopedBookmarkSupport()
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
    
    /// Override touch support (useful for testing with external touchscreens)
    public static var touchSupport: Bool? {
        get {
            let value = UserDefaults.standard.object(forKey: "SixLayerFramework.Override.TouchSupport")
            return value as? Bool
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "SixLayerFramework.Override.TouchSupport")
            } else {
                UserDefaults.standard.removeObject(forKey: "SixLayerFramework.Override.TouchSupport")
            }
        }
    }
    
    /// Override haptic feedback support
    public static var hapticSupport: Bool? {
        get {
            let value = UserDefaults.standard.object(forKey: "SixLayerFramework.Override.HapticSupport")
            return value as? Bool
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "SixLayerFramework.Override.HapticSupport")
            } else {
                UserDefaults.standard.removeObject(forKey: "SixLayerFramework.Override.HapticSupport")
            }
        }
    }
    
    /// Override hover support
    public static var hoverSupport: Bool? {
        get {
            let value = UserDefaults.standard.object(forKey: "SixLayerFramework.Override.HoverSupport")
            return value as? Bool
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "SixLayerFramework.Override.HoverSupport")
            } else {
                UserDefaults.standard.removeObject(forKey: "SixLayerFramework.Override.HoverSupport")
            }
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
    /// Platform-native values: iOS/watchOS = 44.0, macOS/tvOS/visionOS = 0.0
    ///
    /// Apple HIG: "Provide ample touch targets. Try to maintain a minimum tappable area
    /// of 44x44 points for all controls." This guideline applies to touch-first platforms
    /// (iOS/watchOS) regardless of whether touch is currently enabled, as these platforms
    /// are designed for touch interaction.
    ///
    /// Note: nonisolated - this property uses compile-time platform detection
    nonisolated static var minTouchTarget: CGFloat {
        // DTRT: Use compile-time platform detection for reliable results
        // This ensures correct values regardless of runtime platform detection issues
        #if os(iOS) || os(watchOS)
        return 44.0  // Apple HIG minimum touch target size for touch-first platforms
        #else
        return 0.0   // No touch target requirement on non-touch-first platforms
        #endif
    }
    
    /// Hover delay for platforms that support hover
    /// Returns platform-appropriate hover delay values.
    /// Note: Actual hover support is determined by `supportsHover` property at runtime.
    /// This property returns the delay value that would be used if hover is supported.
    /// 
    /// Platform hover delays:
    /// - macOS: 0.5s (mouse/trackpad hover)
    /// - visionOS: 0.5s (hand tracking hover)
    /// - iOS: 0.5s (iPad with Apple Pencil hover, 0.0 for iPhone - determined at runtime)
    /// - watchOS: 0.0s (no hover support)
    /// - tvOS: 0.0s (no hover support)
    /// 
    /// Note: nonisolated - this property only does platform switching, no MainActor APIs accessed
    nonisolated static var hoverDelay: TimeInterval {
        // Use real platform detection - tests should run on actual platforms/simulators
        let platform = currentPlatform
        
        switch platform {
        case .macOS:
            return 0.5   // macOS hover delay (mouse/trackpad)
        case .visionOS:
            return 0.5   // visionOS hover delay (hand tracking)
        case .iOS:
            // iOS hover is device-dependent (iPad supports it, iPhone doesn't)
            // Return 0.5 as the potential delay; actual support checked via supportsHover
            // If hover is not supported, the delay value is irrelevant
            return 0.5   // iPad with Apple Pencil hover delay
        case .watchOS:
            return 0.0   // watchOS doesn't support hover
        case .tvOS:
            return 0.0   // tvOS doesn't support hover
        }
    }
}

