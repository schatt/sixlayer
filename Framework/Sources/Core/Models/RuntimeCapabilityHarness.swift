//
//  RuntimeCapabilityHarness.swift
//  SixLayerFramework
//
//  Test- and concurrency-safe overrides for runtime capability *preferences* and
//  `setTest*` simulation hooks (GitHub #236, #315).
//
//  Values use `@TaskLocal` so they propagate with the Swift Testing `provideScope`
//  → test body task (including `@MainActor` tests), unlike `Thread.current.threadDictionary`
//  which is tied to the OS thread that set it and leaks under parallel Swift Testing.
//

import Foundation

// MARK: - macOS preference simulation (harness)

public enum RuntimeCapabilityHarness: Sendable {

    /// When non-`nil`, macOS `SixLayerFramework.TouchEnabled` resolves to this value for the
    /// current task instead of reading `UserDefaults.standard`.
    @TaskLocal public static var macOSTouchEnabledPreference: Bool?

    /// When non-`nil`, macOS `SixLayerFramework.HapticEnabled` resolves to this value for the
    /// current task instead of reading `UserDefaults.standard`.
    @TaskLocal public static var macOSHapticEnabledPreference: Bool?

    // MARK: - `setTest*` capability overrides (@TaskLocal)

    @TaskLocal public static var testTouchSupport: Bool?
    @TaskLocal public static var testHapticFeedback: Bool?
    @TaskLocal public static var testHover: Bool?
    @TaskLocal public static var testVoiceOver: Bool?
    @TaskLocal public static var testSwitchControl: Bool?
    @TaskLocal public static var testAssistiveTouch: Bool?
    @TaskLocal public static var testHighContrast: Bool?

    @TaskLocal public static var testPhotosHasCamera: Bool?
    @TaskLocal public static var testPhotosIsPhotoLibraryPickerAvailable: Bool?
    @TaskLocal public static var testPhotosSupportsLiveDataScanner: Bool?

    @TaskLocal public static var testVisionIsFrameworkAvailable: Bool?
    @TaskLocal public static var testVisionSupportsOCR: Bool?
    @TaskLocal public static var testVisionSupportsImageAnalyzer: Bool?
    @TaskLocal public static var testVisionSupportsDocumentCamera: Bool?

    @TaskLocal public static var testFilesSupportsSecurityScopedResources: Bool?
    @TaskLocal public static var testFilesSupportsSecurityScopedBookmarks: Bool?

    #if os(iOS)
    @TaskLocal public static var testiOSHoverDeviceCapability: Bool?
    #endif

    @TaskLocal public static var testNetworkIsConstrained: Bool?
    @TaskLocal public static var testNetworkIsExpensive: Bool?
    @TaskLocal public static var testNetworkHasPathSnapshot: Bool?

    @TaskLocal public static var testMediaHasMicrophoneInput: Bool?
    @TaskLocal public static var testMediaSupportsScreenCapture: Bool?

    @TaskLocal public static var testPasteboardCanReadStrings: Bool?
    @TaskLocal public static var testPasteboardCanWriteStrings: Bool?

    /// Dedupes one-time os_log lines for ignored `setTest*` calls within the current task.
    @TaskLocal public static var loggedIgnoredTestOverrideKeys: [String]?

    /// Keys used for macOS capability *simulation* and `CapabilityOverride` persistence on `UserDefaults.standard`.
    public static let legacyCapabilityUserDefaultsKeys: [String] = [
        "SixLayerFramework.TouchEnabled",
        "SixLayerFramework.HapticEnabled",
        "SixLayerFramework.Override.TouchSupport",
        "SixLayerFramework.Override.HapticSupport",
        "SixLayerFramework.Override.HoverSupport",
    ]

    /// Clears legacy capability keys from `UserDefaults.standard` for the current process.
    public static func scrubLegacyCapabilityKeysFromUserDefaultsStandard() {
        for key in legacyCapabilityUserDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    /// Clears all `@TaskLocal` `setTest*` overrides on the current task.
    public static func clearAllTestCapabilityOverrides() {
        testTouchSupport = nil
        testHapticFeedback = nil
        testHover = nil
        testVoiceOver = nil
        testSwitchControl = nil
        testAssistiveTouch = nil
        testHighContrast = nil
        testPhotosHasCamera = nil
        testPhotosIsPhotoLibraryPickerAvailable = nil
        testPhotosSupportsLiveDataScanner = nil
        testVisionIsFrameworkAvailable = nil
        testVisionSupportsOCR = nil
        testVisionSupportsImageAnalyzer = nil
        testVisionSupportsDocumentCamera = nil
        testFilesSupportsSecurityScopedResources = nil
        testFilesSupportsSecurityScopedBookmarks = nil
        #if os(iOS)
        testiOSHoverDeviceCapability = nil
        #endif
        testNetworkIsConstrained = nil
        testNetworkIsExpensive = nil
        testNetworkHasPathSnapshot = nil
        testMediaHasMicrophoneInput = nil
        testMediaSupportsScreenCapture = nil
        testPasteboardCanReadStrings = nil
        testPasteboardCanWriteStrings = nil
        loggedIgnoredTestOverrideKeys = nil
    }

    /// Clears thread-local `CapabilityOverride` values and legacy `standard` keys.
    /// Suitable as part of a unit-test scoping wrapper (GitHub #236).
    public static func resetCapabilityIsolationForCurrentThreadAndStandardDefaults() {
        CapabilityOverride.clearThreadIsolationFromCurrentThread()
        scrubLegacyCapabilityKeysFromUserDefaultsStandard()
    }
}
