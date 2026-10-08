//
//  PlatformModifierCapabilityMatrix.swift
//  SixLayerFramework
//
//  Capability spine for secondary-platform View modifiers (GitHub #448).
//  Branch on this matrix. Use `#if` only when `apiUnavailable` is true.
//  When the branch is `.stubIdentity`, return `self` — do not clone an iOS modifier.
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

    /// Resolve modifier capabilities from detection inputs.
    ///
    /// - touch, hover, haptics: passed through from `RuntimeCapabilityDetection`
    /// - keyboard: `SixLayerPlatform.supportsKeyboardNavigation` (macOS, tvOS)
    /// - spatial: `platform == .visionOS` (no runtime probe)
    /// - pointer: macOS or visionOS hover. iOS pencil hover stays on `hover` only
    /// - pullToRefresh: touch on iOS or macOS. watchOS touch does not imply it
    /// - swipe: touch, except tvOS where `DragGesture` is unavailable (#237)
    public static func resolved(_ reading: PlatformModifierCapabilityReading) -> PlatformModifierCapabilityMatrix {
        let platform = reading.platform
        let touch = reading.supportsTouch
        let hover = reading.supportsHover
        return PlatformModifierCapabilityMatrix(
            platform: platform,
            pointer: (platform == .macOS || platform == .visionOS) && hover,
            hover: hover,
            haptics: reading.supportsHapticFeedback,
            pullToRefresh: touch && (platform == .iOS || platform == .macOS),
            keyboard: reading.supportsKeyboardNavigation,
            spatial: platform == .visionOS,
            touch: touch,
            swipe: touch && platform != .tvOS
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

    /// Apply when the capability is on and the API exists; skip when the SDK lacks the API; otherwise identity.
    public func branch(for capability: PlatformModifierCapability) -> PlatformModifierBranch {
        if Self.apiUnavailable(capability, on: platform) {
            return .skipUnavailableAPI
        }
        if supports(capability) {
            return .apply
        }
        return .stubIdentity
    }

    /// SwiftUI API for `capability` is missing on `platform`.
    /// Unit lanes skip the observation. Do not compile an iOS clone under `#else`.
    public static func apiUnavailable(
        _ capability: PlatformModifierCapability,
        on platform: SixLayerPlatform
    ) -> Bool {
        switch capability {
        case .swipe:
            // DragGesture-based swipe is unavailable on tvOS (#237).
            return platform == .tvOS
        case .pullToRefresh:
            // `refreshable` is not in the watchOS or tvOS SDK.
            return platform == .tvOS || platform == .watchOS
        case .spatial:
            return platform != .visionOS
        case .hover, .pointer:
            // `onHover` is not in the watchOS or tvOS SDK.
            return platform == .tvOS || platform == .watchOS
        case .keyboard:
            // watchOS has no keyboard-shortcut or focus-navigation API.
            // tvOS keyboard means the focus engine, which is present.
            return platform == .watchOS
        case .haptics, .touch:
            return false
        }
    }
}
