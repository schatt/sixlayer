//
//  PlatformModifierCapabilityMatrix.swift
//  SixLayerFramework
//
//  Capability spine for secondary-platform View modifiers (GitHub #448).
//  Deliberate stub: branches are wrong until the contract is implemented.
//

import Foundation

/// View-modifier capabilities secondary platforms consult instead of cloning iOS.
public enum PlatformModifierCapability: String, CaseIterable, Sendable {
    case pointer
    case hover
    case haptics
    case pullToRefresh
    case keyboard
    case spatial
    case touch
    case swipe
}

/// What a modifier does with one capability on the current platform.
public enum PlatformModifierBranch: String, Equatable, Sendable {
    /// Capability is present and the SwiftUI API exists. Apply the platform behavior.
    case apply
    /// API exists; capability is absent. Return `self`. Do not clone an iOS modifier.
    case stubIdentity
    /// SwiftUI API is not in this platform SDK. Guard with `#if`. Unit tests skip the observation.
    case skipUnavailableAPI
}

/// Detection inputs the matrix resolves. Pass live `RuntimeCapabilityDetection` values
/// from `PlatformModifierCapabilityMatrix.current`; tests inject readings directly.
public struct PlatformModifierCapabilityReading: Equatable, Sendable {
    public var platform: SixLayerPlatform
    public var supportsTouch: Bool
    public var supportsHover: Bool
    public var supportsHapticFeedback: Bool
    public var supportsKeyboardNavigation: Bool

    public init(
        platform: SixLayerPlatform,
        supportsTouch: Bool,
        supportsHover: Bool,
        supportsHapticFeedback: Bool,
        supportsKeyboardNavigation: Bool
    ) {
        self.platform = platform
        self.supportsTouch = supportsTouch
        self.supportsHover = supportsHover
        self.supportsHapticFeedback = supportsHapticFeedback
        self.supportsKeyboardNavigation = supportsKeyboardNavigation
    }

    /// Documented intrinsic reading before device-specific probes
    /// (iPad pencil hover, macOS touchscreen, macOS haptic preference).
    public static func intrinsic(for platform: SixLayerPlatform) -> PlatformModifierCapabilityReading {
        switch platform {
        case .iOS:
            return PlatformModifierCapabilityReading(
                platform: .iOS,
                supportsTouch: true,
                supportsHover: false,
                supportsHapticFeedback: true,
                supportsKeyboardNavigation: false
            )
        case .macOS:
            return PlatformModifierCapabilityReading(
                platform: .macOS,
                supportsTouch: false,
                supportsHover: true,
                supportsHapticFeedback: false,
                supportsKeyboardNavigation: true
            )
        case .watchOS:
            return PlatformModifierCapabilityReading(
                platform: .watchOS,
                supportsTouch: true,
                supportsHover: false,
                supportsHapticFeedback: true,
                supportsKeyboardNavigation: false
            )
        case .tvOS:
            return PlatformModifierCapabilityReading(
                platform: .tvOS,
                supportsTouch: false,
                supportsHover: false,
                supportsHapticFeedback: false,
                supportsKeyboardNavigation: true
            )
        case .visionOS:
            return PlatformModifierCapabilityReading(
                platform: .visionOS,
                supportsTouch: false,
                supportsHover: true,
                supportsHapticFeedback: false,
                supportsKeyboardNavigation: false
            )
        }
    }
}

/// Resolved modifier capabilities for one reading.
public struct PlatformModifierCapabilityMatrix: Equatable, Sendable {
    public var platform: SixLayerPlatform
    public var pointer: Bool
    public var hover: Bool
    public var haptics: Bool
    public var pullToRefresh: Bool
    public var keyboard: Bool
    public var spatial: Bool
    public var touch: Bool
    public var swipe: Bool

    public init(
        platform: SixLayerPlatform,
        pointer: Bool,
        hover: Bool,
        haptics: Bool,
        pullToRefresh: Bool,
        keyboard: Bool,
        spatial: Bool,
        touch: Bool,
        swipe: Bool
    ) {
        self.platform = platform
        self.pointer = pointer
        self.hover = hover
        self.haptics = haptics
        self.pullToRefresh = pullToRefresh
        self.keyboard = keyboard
        self.spatial = spatial
        self.touch = touch
        self.swipe = swipe
    }

    /// Wrong on purpose (#448 red). Real resolution lands in the green commit.
    public static func resolved(_ reading: PlatformModifierCapabilityReading) -> PlatformModifierCapabilityMatrix {
        PlatformModifierCapabilityMatrix(
            platform: reading.platform,
            pointer: false,
            hover: false,
            haptics: false,
            pullToRefresh: false,
            keyboard: false,
            spatial: false,
            touch: false,
            swipe: false
        )
    }

    public static var current: PlatformModifierCapabilityMatrix {
        let platform = SixLayerPlatform.current
        return resolved(
            PlatformModifierCapabilityReading(
                platform: platform,
                supportsTouch: RuntimeCapabilityDetection.supportsTouch,
                supportsHover: RuntimeCapabilityDetection.supportsHover,
                supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
                supportsKeyboardNavigation: platform.supportsKeyboardNavigation
            )
        )
    }

    public func supports(_ capability: PlatformModifierCapability) -> Bool {
        switch capability {
        case .pointer: return pointer
        case .hover: return hover
        case .haptics: return haptics
        case .pullToRefresh: return pullToRefresh
        case .keyboard: return keyboard
        case .spatial: return spatial
        case .touch: return touch
        case .swipe: return swipe
        }
    }

    /// Wrong on purpose: every capability stubs, including ones whose API is missing.
    public func branch(for capability: PlatformModifierCapability) -> PlatformModifierBranch {
        _ = capability
        return .stubIdentity
    }

    public static func apiUnavailable(
        _ capability: PlatformModifierCapability,
        on platform: SixLayerPlatform
    ) -> Bool {
        _ = capability
        _ = platform
        return false
    }
}
