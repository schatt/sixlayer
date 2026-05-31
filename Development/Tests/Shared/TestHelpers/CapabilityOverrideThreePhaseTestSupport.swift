//
//  CapabilityOverrideThreePhaseTestSupport.swift
//  Optional narrow TDD: Layer 5 config vs thread-local `setTest*`. Primary tri-value tests live on controls.
//  GitHub #251 section C — tracking: https://github.com/schatt/sixlayer/issues/251
//

import Testing
@testable import SixLayerFramework

/// **Narrow TDD plumbing** for `getCardExpansionPlatformConfig()` — not a substitute for **control** tests.
/// Tri-value behavior that users see (sizes, hover, haptics, etc.) should be exercised **next to each control**
/// (see `.cursor/rules/capability-override-test-flows.mdc`). This helper only drives **current → disabled → enabled**
/// thread-local flags and checks Layer 5 config **policy / propagation** for regression on wiring.
///
/// **Touch (especially macOS):** intrinsic `supportsTouch` may be true or false; we do **not** assert a single
/// expected boolean. We assert **`minTouchTarget`** tracks **effective** touch via `PlatformTestUtilities`
/// (HIG floor: e.g. mac 0pt when off, 44pt when on). On iOS/watchOS, `setTestTouchSupport(false)` is nonsensical
/// and ignored — the same law still holds (touch-first → floor stays 44pt).
///
/// **Haptic / VoiceOver / Switch / Assistive:** `CardExpansionPlatformConfig` mostly **transports** booleans into
/// downstream code; tri-state proves those fields track overrides. **Behavioral** “does this control do the
/// right thing when haptics are off?” belongs with the **control** tests that consume the config.
///
/// **Hover:** we assert **delay policy** with hover (`hoverDelay` is 0 without hover; otherwise matches
/// `RuntimeCapabilityDetection.hoverDelay`, which centralizes platform delay).
public enum CapabilityOverrideThreePhaseTestSupport {

    // MARK: - Touch → min touch target (consumer law)

    @MainActor
    public static func assertCardExpansionMirrorsRuntimeTouchThroughPhases() {
        func assertMinTouchTargetFollowsEffectiveTouch() {
            let platform = SixLayerPlatform.current
            let effectiveTouch = RuntimeCapabilityDetection.supportsTouch
            let config = getCardExpansionPlatformConfig()
            let expectedMin = PlatformTestUtilities.expectedMinTouchTarget(
                for: platform,
                touchDetected: effectiveTouch
            )
            #expect(
                config.minTouchTarget == expectedMin,
                "Layer 5 consumer: minTouchTarget must match HIG for effective touch on \(platform) (effective=\(effectiveTouch))"
            )
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        assertMinTouchTargetFollowsEffectiveTouch()

        RuntimeCapabilityDetection.setTestTouchSupport(false)
        assertMinTouchTargetFollowsEffectiveTouch()

        RuntimeCapabilityDetection.setTestTouchSupport(true)
        assertMinTouchTargetFollowsEffectiveTouch()

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }

    // MARK: - Transport (config tracks detection for downstream behavior tests elsewhere)

    @MainActor
    public static func assertCardExpansionMirrorsRuntimeHapticThroughPhases() {
        func mirror() {
            let config = getCardExpansionPlatformConfig()
            #expect(config.supportsHapticFeedback == RuntimeCapabilityDetection.supportsHapticFeedback)
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        mirror()

        RuntimeCapabilityDetection.setTestHapticFeedback(false)
        mirror()
        #expect(!RuntimeCapabilityDetection.supportsHapticFeedback)

        RuntimeCapabilityDetection.setTestHapticFeedback(true)
        mirror()
        #expect(RuntimeCapabilityDetection.supportsHapticFeedback)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }

    @MainActor
    public static func assertCardExpansionMirrorsRuntimeHoverThroughPhases() {
        func assertHoverDelayConsumerLaw() {
            let config = getCardExpansionPlatformConfig()
            let hover = RuntimeCapabilityDetection.supportsHover
            #expect(config.supportsHover == hover)
            #expect(config.hoverDelay == RuntimeCapabilityDetection.hoverDelay)
            if !hover {
                #expect(config.hoverDelay == 0, "Layer 5 consumer: no hover → no hover delay budget")
            }
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        assertHoverDelayConsumerLaw()

        RuntimeCapabilityDetection.setTestHover(false)
        assertHoverDelayConsumerLaw()
        #expect(!RuntimeCapabilityDetection.supportsHover)

        RuntimeCapabilityDetection.setTestHover(true)
        assertHoverDelayConsumerLaw()
        #expect(RuntimeCapabilityDetection.supportsHover)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }

    @MainActor
    public static func assertCardExpansionMirrorsRuntimeVoiceOverThroughPhases() {
        func mirror() {
            let config = getCardExpansionPlatformConfig()
            #expect(config.supportsVoiceOver == RuntimeCapabilityDetection.supportsVoiceOver)
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        mirror()

        RuntimeCapabilityDetection.setTestVoiceOver(false)
        mirror()
        #expect(!RuntimeCapabilityDetection.supportsVoiceOver)

        RuntimeCapabilityDetection.setTestVoiceOver(true)
        mirror()
        #expect(RuntimeCapabilityDetection.supportsVoiceOver)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }

    @MainActor
    public static func assertCardExpansionMirrorsRuntimeSwitchControlThroughPhases() {
        func mirror() {
            let config = getCardExpansionPlatformConfig()
            #expect(config.supportsSwitchControl == RuntimeCapabilityDetection.supportsSwitchControl)
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        mirror()

        RuntimeCapabilityDetection.setTestSwitchControl(false)
        mirror()
        #expect(!RuntimeCapabilityDetection.supportsSwitchControl)

        RuntimeCapabilityDetection.setTestSwitchControl(true)
        mirror()
        #expect(RuntimeCapabilityDetection.supportsSwitchControl)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }

    @MainActor
    public static func assertCardExpansionMirrorsRuntimeAssistiveTouchThroughPhases() {
        func mirror() {
            let config = getCardExpansionPlatformConfig()
            #expect(config.supportsAssistiveTouch == RuntimeCapabilityDetection.supportsAssistiveTouch)
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        mirror()

        RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        mirror()
        #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch)

        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        mirror()
        #expect(RuntimeCapabilityDetection.supportsAssistiveTouch)

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }

    /// Cleared overrides: `minTouchTarget` / `hoverDelay` still follow helpers / centralized hover delay.
    @MainActor
    public static func assertCardExpansionMinTouchAndHoverDelayMatchHelpersWhenCleared() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }
        let platform = SixLayerPlatform.current
        let config = getCardExpansionPlatformConfig()
        let expectedMin = PlatformTestUtilities.expectedMinTouchTarget(
            for: platform,
            touchDetected: RuntimeCapabilityDetection.supportsTouch
        )
        #expect(config.minTouchTarget == expectedMin)
        #expect(config.hoverDelay == RuntimeCapabilityDetection.hoverDelay)
    }

    @MainActor
    public static func runAllTriStateAssertionsForCardExpansionPlatformConfig() {
        assertCardExpansionMirrorsRuntimeTouchThroughPhases()
        assertCardExpansionMirrorsRuntimeHapticThroughPhases()
        assertCardExpansionMirrorsRuntimeHoverThroughPhases()
        assertCardExpansionMirrorsRuntimeVoiceOverThroughPhases()
        assertCardExpansionMirrorsRuntimeSwitchControlThroughPhases()
        assertCardExpansionMirrorsRuntimeAssistiveTouchThroughPhases()
        assertCardExpansionMinTouchAndHoverDelayMatchHelpersWhenCleared()
    }
}
