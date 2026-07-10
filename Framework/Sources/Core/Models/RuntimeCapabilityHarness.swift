//
//  RuntimeCapabilityHarness.swift
//  SixLayerFramework
//
//  Test- and concurrency-safe overrides for runtime capability *preferences* and
//  `setTest*` simulation hooks (GitHub #236, #315).
//
//  macOS preference shadowing and `setTest*` overrides use `@TaskLocal` so values
//  propagate with the Swift Testing `provideScope` → test body task (including
//  `@MainActor` tests). Mutable override state lives in a reference-type bag bound
//  once per test scope so sync setters can mutate in place without reassigning
//  `@TaskLocal` from synchronous functions.
//

import Foundation

// MARK: - Mutable capability override bag (per-task via @TaskLocal)

/// Per-test mutable storage for `RuntimeCapabilityDetection.setTest*` hooks.
public final class CapabilityTestOverrideBag: @unchecked Sendable {
    public var testTouchSupport: Bool?
    public var testHapticFeedback: Bool?
    public var testHover: Bool?
    public var testVoiceOver: Bool?
    public var testSwitchControl: Bool?
    public var testAssistiveTouch: Bool?
    public var testHighContrast: Bool?

    public var testPhotosHasCamera: Bool?
    public var testPhotosIsPhotoLibraryPickerAvailable: Bool?
    public var testPhotosSupportsLiveDataScanner: Bool?

    public var testVisionIsFrameworkAvailable: Bool?
    public var testVisionSupportsOCR: Bool?
    public var testVisionSupportsImageAnalyzer: Bool?
    public var testVisionSupportsDocumentCamera: Bool?

    public var testFilesSupportsSecurityScopedResources: Bool?
    public var testFilesSupportsSecurityScopedBookmarks: Bool?

    #if os(iOS)
    public var testiOSHoverDeviceCapability: Bool?
    #endif

    public var testNetworkIsConstrained: Bool?
    public var testNetworkIsExpensive: Bool?
    public var testNetworkHasPathSnapshot: Bool?

    public var testMediaHasMicrophoneInput: Bool?
    public var testMediaSupportsScreenCapture: Bool?

    public var testPasteboardCanReadStrings: Bool?
    public var testPasteboardCanWriteStrings: Bool?

    public var loggedIgnoredTestOverrideKeys: [String] = []

    public init() {}

    public func clearAll() {
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
        loggedIgnoredTestOverrideKeys = []
    }
}

// MARK: - macOS preference simulation (harness)

public enum RuntimeCapabilityHarness: Sendable {

    /// When non-`nil`, macOS `SixLayerFramework.TouchEnabled` resolves to this value for the
    /// current task instead of reading `UserDefaults.standard`.
    @TaskLocal public static var macOSTouchEnabledPreference: Bool?

    /// When non-`nil`, macOS `SixLayerFramework.HapticEnabled` resolves to this value for the
    /// current task instead of reading `UserDefaults.standard`.
    @TaskLocal public static var macOSHapticEnabledPreference: Bool?

    /// Per-task mutable bag for `setTest*` overrides. Bound for each test by
    /// ``DefaultRuntimeCapabilityIsolationTrait`` or ``withCapabilityTestOverrideBag(_:)``.
    @TaskLocal public static var capabilityTestOverrideBag: CapabilityTestOverrideBag?

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

    /// Clears all `setTest*` overrides on the current task's bag when present.
    public static func clearAllTestCapabilityOverrides() {
        capabilityTestOverrideBag?.clearAll()
    }

    /// Runs `body` with a fresh ``CapabilityTestOverrideBag`` bound for the current task.
    public static func withCapabilityTestOverrideBag<T>(
        _ body: () throws -> T
    ) rethrows -> T {
        let bag = CapabilityTestOverrideBag()
        return try $capabilityTestOverrideBag.withValue(bag, operation: body)
    }

    /// Clears thread-local `CapabilityOverride` values and legacy `standard` keys.
    /// Suitable as part of a unit-test scoping wrapper (GitHub #236).
    public static func resetCapabilityIsolationForCurrentThreadAndStandardDefaults() {
        CapabilityOverride.clearThreadIsolationFromCurrentThread()
        scrubLegacyCapabilityKeysFromUserDefaultsStandard()
    }
}
