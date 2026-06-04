//
//  PlatformTestUtilities.swift
//  SixLayerFrameworkTests
//
//  Shared HIG expectation helpers for capability-sensitive tests (GitHub #251 section C).
//  **Control tests** own tri-state phases; this enum supplies per-platform law only —
//  see `.cursor/rules/capability-override-test-flows.mdc`.
//

import CoreGraphics
import Foundation
@testable import SixLayerFramework

/// Platform test utilities
public enum PlatformTestUtilities {
    
    /// Get OCR availability for a platform
    public static func getOCRAvailability(for platform: SixLayerPlatform) -> Bool {
        switch platform {
        case .iOS, .macOS:
            return true
        case .watchOS, .tvOS, .visionOS:
            return false
        }
    }
    
    /// Get Vision availability for a platform
    public static func getVisionAvailability(for platform: SixLayerPlatform) -> Bool {
        switch platform {
        case .iOS, .macOS:
            return true
        case .watchOS, .tvOS, .visionOS:
            return false
        }
    }

    /// HIG-correct expected minimum interactive-target size for a platform.
    ///
    /// Mirrors PlatformStrategy.minTouchTarget so tests assert the same
    /// per-platform contract the framework implements (Issue #237):
    /// - iOS: 44pt (Apple HIG explicit)
    /// - watchOS: 44pt (inherited; watchOS HIG does not publish a numeric
    ///   minimum, we use iOS's 44pt as a conservative accessibility-safe floor)
    /// - tvOS: 60pt (Apple tvOS HIG — focus engine at 10-foot viewing distance)
    /// - visionOS: 60pt (Apple visionOS HIG — gaze+pinch minimum; applies
    ///   independent of runtime hand-tracking direct-touch)
    /// - macOS: 44pt when runtime touch is detected (touch-screen Mac /
    ///   accessibility touch emulation), else 0pt
    ///
    /// If this helper and PlatformStrategy.minTouchTarget diverge, one of
    /// them is wrong — Apple HIG is authoritative.
    public static func expectedMinTouchTarget(
        for platform: SixLayerPlatform,
        touchDetected: Bool = RuntimeCapabilityDetection.supportsTouch
    ) -> CGFloat {
        switch platform {
        case .iOS, .watchOS:
            return 44.0
        case .tvOS, .visionOS:
            return 60.0
        case .macOS:
            return touchDetected ? 44.0 : 0.0
        }
    }

    /// Expected AssistiveTouch after `setTestAssistiveTouch(_:)` — only true when enabled and the host ships the feature (#311).
    public static func expectedAssistiveTouchAfterTestOverride(_ enabled: Bool) -> Bool {
        enabled && SixLayerPlatform.current.supportsAssistiveTouch
    }
}
