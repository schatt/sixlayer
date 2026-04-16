//
//  RuntimeCapabilityHarness.swift
//  SixLayerFramework
//
//  Test- and concurrency-safe overrides for runtime capability *preferences* that
//  were previously read only from `UserDefaults.standard` (GitHub #236).
//
//  Uses `Thread.current.threadDictionary` (not `@TaskLocal`) so
//  `RuntimeCapabilityDetection` can consult values from `nonisolated` entry points
//  on the same OS thread as `@MainActor` / synchronous test bodies.
//

import Foundation

// MARK: - macOS preference simulation (harness)

public enum RuntimeCapabilityHarness: Sendable {

    private static let macOSTouchEnabledHarnessKey = "SixLayerFramework.RuntimeHarness.macOSTouchEnabledPreference"
    private static let macOSHapticEnabledHarnessKey = "SixLayerFramework.RuntimeHarness.macOSHapticEnabledPreference"

    /// When non-`nil`, macOS `SixLayerFramework.TouchEnabled` resolves to this value for the **current thread**
    /// instead of reading `UserDefaults.standard`.
    public static var macOSTouchEnabledPreference: Bool? {
        get {
            guard let number = Thread.current.threadDictionary[macOSTouchEnabledHarnessKey] as? NSNumber else {
                return nil
            }
            return number.boolValue
        }
        set {
            if let value = newValue {
                Thread.current.threadDictionary[macOSTouchEnabledHarnessKey] = NSNumber(value: value)
            } else {
                Thread.current.threadDictionary.removeValue(forKey: macOSTouchEnabledHarnessKey)
            }
        }
    }

    /// When non-`nil`, macOS `SixLayerFramework.HapticEnabled` resolves to this value for the **current thread**
    /// instead of reading `UserDefaults.standard`.
    public static var macOSHapticEnabledPreference: Bool? {
        get {
            guard let number = Thread.current.threadDictionary[macOSHapticEnabledHarnessKey] as? NSNumber else {
                return nil
            }
            return number.boolValue
        }
        set {
            if let value = newValue {
                Thread.current.threadDictionary[macOSHapticEnabledHarnessKey] = NSNumber(value: value)
            } else {
                Thread.current.threadDictionary.removeValue(forKey: macOSHapticEnabledHarnessKey)
            }
        }
    }

    /// Removes harness preference keys from the current thread (typically after each test invocation).
    public static func removeHarnessPreferenceKeysFromCurrentThread() {
        Thread.current.threadDictionary.removeValue(forKey: macOSTouchEnabledHarnessKey)
        Thread.current.threadDictionary.removeValue(forKey: macOSHapticEnabledHarnessKey)
    }

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

    /// Clears thread-local `CapabilityOverride` values, harness prefs on this thread, and legacy `standard` keys.
    /// Suitable as the first step of a unit-test scoping wrapper (GitHub #236).
    public static func resetCapabilityIsolationForCurrentThreadAndStandardDefaults() {
        CapabilityOverride.clearThreadIsolationFromCurrentThread()
        removeHarnessPreferenceKeysFromCurrentThread()
        scrubLegacyCapabilityKeysFromUserDefaultsStandard()
    }
}
