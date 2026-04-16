//
//  RuntimeCapabilityHarness.swift
//  SixLayerFramework
//
//  Test- and concurrency-safe overrides for runtime capability *preferences* that
//  were previously read only from `UserDefaults.standard` (GitHub #236).
//
//  macOS preference shadowing uses `@TaskLocal` so values propagate with the Swift
//  Testing `provideScope` → test body task (including `@MainActor` tests), unlike
//  `Thread.current.threadDictionary` which is tied to the OS thread that set it.
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

    /// Clears thread-local `CapabilityOverride` values and legacy `standard` keys.
    /// Suitable as part of a unit-test scoping wrapper (GitHub #236).
    public static func resetCapabilityIsolationForCurrentThreadAndStandardDefaults() {
        CapabilityOverride.clearThreadIsolationFromCurrentThread()
        scrubLegacyCapabilityKeysFromUserDefaultsStandard()
    }
}
