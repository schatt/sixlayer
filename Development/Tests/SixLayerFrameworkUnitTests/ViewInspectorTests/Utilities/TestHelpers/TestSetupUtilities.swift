//
//  TestSetupUtilities.swift
//  SixLayerFrameworkTests
//
//  Centralized test setup and platform mocking utilities
//  Following DRY principles to avoid duplicating setup code across test files
//

import SwiftUI
import Testing
@testable import SixLayerFramework

/// Centralized test setup utilities for consistent platform mocking across all tests
public class TestSetupUtilities {
    
    // MARK: - Singleton
    
    @MainActor
    public static let shared = TestSetupUtilities()
    
    private init() {}
    
    // MARK: - Test Environment Setup
    
    /// Sets up the testing environment with predictable platform capabilities
    /// Call this in setUp() methods of test classes
    /// Note: nonisolated - only accesses thread-local storage (no MainActor needed)
    nonisolated public func setupTestingEnvironment() {
        // TestingCapabilityDetection.isTestingMode is automatically enabled in test environment
        // Reset any existing overrides (thread-local storage, no MainActor needed)
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    /// Cleans up the testing environment
    /// Call this in tearDown() methods of test classes
    /// Note: nonisolated - only accesses thread-local storage (no MainActor needed)
    nonisolated public func cleanupTestingEnvironment() {
        // Clear all overrides (thread-local storage, no MainActor needed)
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    // MARK: - Platform Capability Simulation
    
    /// Sets up capabilities to match iOS-like platform (touch and haptic support)
    /// Note: Tests should run on actual iOS simulators for iOS-specific behavior
    public func simulateiOSCapabilities() {
        overrideCapabilities(touch: true, haptic: true, hover: false, voiceOver: true, switchControl: true, assistiveTouch: true)
    }
    
    /// Sets up capabilities to match macOS-like platform (hover support, no touch/haptic)
    /// Note: Tests should run on actual macOS for macOS-specific behavior
    public func simulateMacOSCapabilities() {
        overrideCapabilities(touch: false, haptic: false, hover: true, voiceOver: true, switchControl: true, assistiveTouch: false)
    }
    
    /// Sets up capabilities to match watchOS-like platform (touch and haptic support)
    /// Note: Tests should run on actual watchOS simulators for watchOS-specific behavior
    public func simulateWatchOSCapabilities() {
        overrideCapabilities(touch: true, haptic: true, hover: false, voiceOver: true, switchControl: true, assistiveTouch: true)
    }
    
    /// Sets up capabilities to match tvOS-like platform (accessibility only, no touch/hover/haptic)
    /// Note: Tests should run on actual tvOS simulators for tvOS-specific behavior
    public func simulateTVOSCapabilities() {
        overrideCapabilities(touch: false, haptic: false, hover: false, voiceOver: true, switchControl: true, assistiveTouch: false)
    }
    
    /// Sets up capabilities to match visionOS-like platform (hover support)
    /// Note: Tests should run on actual visionOS simulators for visionOS-specific behavior
    public func simulateVisionOSCapabilities() {
        overrideCapabilities(touch: false, haptic: false, hover: true, voiceOver: true, switchControl: true, assistiveTouch: false)
    }
    
    // MARK: - Capability Override
    
    /// Overrides specific capabilities for testing edge cases
    /// - Parameters:
    ///   - touch: Touch support override
    ///   - haptic: Haptic feedback override
    ///   - hover: Hover support override
    ///   - voiceOver: VoiceOver support override
    ///   - switchControl: Switch Control support override
    ///   - assistiveTouch: AssistiveTouch support override
    public func overrideCapabilities(
        touch: Bool? = nil,
        haptic: Bool? = nil,
        hover: Bool? = nil,
        voiceOver: Bool? = nil,
        switchControl: Bool? = nil,
        assistiveTouch: Bool? = nil
    ) {
        if let touch = touch {
            RuntimeCapabilityDetection.setTestTouchSupport(touch)
        }
        if let haptic = haptic {
            RuntimeCapabilityDetection.setTestHapticFeedback(haptic)
        }
        if let hover = hover {
            RuntimeCapabilityDetection.setTestHover(hover)
        }
        if let voiceOver = voiceOver {
            RuntimeCapabilityDetection.setTestVoiceOver(voiceOver)
        }
        if let switchControl = switchControl {
            RuntimeCapabilityDetection.setTestSwitchControl(switchControl)
        }
        if let assistiveTouch = assistiveTouch {
            RuntimeCapabilityDetection.setTestAssistiveTouch(assistiveTouch)
        }
    }
    
    /// Clears all capability overrides
    /// Note: nonisolated - only accesses thread-local storage (no MainActor needed)
    nonisolated public func clearAllCapabilityOverrides() {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    // MARK: - Common Test Scenarios
    
    /// Sets up a touch-enabled platform (iOS/watchOS)
    public func setupTouchEnabledPlatform() {
        simulateiOSCapabilities()
    }
    
    /// Sets up a hover-enabled platform (macOS)
    public func setupHoverEnabledPlatform() {
        simulateMacOSCapabilities()
    }
    
    /// Sets up an accessibility-only platform (tvOS)
    public func setupAccessibilityOnlyPlatform() {
        simulateTVOSCapabilities()
    }
    
    /// Sets up a vision-enabled platform (visionOS)
    public func setupVisionEnabledPlatform() {
        simulateVisionOSCapabilities()
    }
    
    // MARK: - Test Assertion Helpers
    
    /// Asserts that the current platform configuration matches expected capabilities
    /// - Parameters:
    ///   - touch: Expected touch support
    ///   - haptic: Expected haptic support
    ///   - hover: Expected hover support
    ///   - voiceOver: Expected VoiceOver support
    ///   - switchControl: Expected Switch Control support
    ///   - assistiveTouch: Expected AssistiveTouch support
    ///   - file: File name for assertion
    ///   - line: Line number for assertion
    @MainActor
    public func assertPlatformCapabilities(
        touch: Bool? = nil,
        haptic: Bool? = nil,
        hover: Bool? = nil,
        voiceOver: Bool? = nil,
        switchControl: Bool? = nil,
        assistiveTouch: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if let touch = touch {
            #expect(RuntimeCapabilityDetection.supportsTouch == touch, "Touch support should be \(touch)", )
        }
        if let haptic = haptic {
            #expect(RuntimeCapabilityDetection.supportsHapticFeedback == haptic, "Haptic support should be \(haptic)", )
        }
        if let hover = hover {
            #expect(RuntimeCapabilityDetection.supportsHover == hover, "Hover support should be \(hover)", )
        }
        if let voiceOver = voiceOver {
            #expect(RuntimeCapabilityDetection.supportsVoiceOver == voiceOver, "VoiceOver support should be \(voiceOver)", )
        }
        if let switchControl = switchControl {
            #expect(RuntimeCapabilityDetection.supportsSwitchControl == switchControl, "Switch Control support should be \(switchControl)", )
        }
        if let assistiveTouch = assistiveTouch {
            #expect(RuntimeCapabilityDetection.supportsAssistiveTouch == assistiveTouch, "AssistiveTouch support should be \(assistiveTouch)", )
        }
    }
    
    // MARK: - Test Field Creation Utilities
    
    /// Helper function to create DynamicFormField with proper binding for tests
    /// DRY principle: Centralized field creation to avoid duplication across test files
    public static func createTestField(
        label: String,
        placeholder: String? = nil,
        value: String = "",
        isRequired: Bool = false,
        contentType: DynamicContentType = .text
    ) -> DynamicFormField {
        return DynamicFormField(
            id: label.lowercased().replacingOccurrences(of: " ", with: "_"),
            contentType: contentType,
            label: label,
            placeholder: placeholder,
            isRequired: isRequired,
            defaultValue: value
        )
    }
    
    // MARK: - Card Expansion Configuration Utilities
    
    /// Get card expansion platform configuration for testing
    /// DRY principle: Centralized card configuration to avoid duplication
    /// 
    /// ⚠️ ARCHITECTURAL CONSTRAINT: This function should ONLY be used for testing card-specific functionality.
    /// For general platform capability testing, use RuntimeCapabilityDetection directly.
    /// Card config should ONLY be used by card display functions in production code.
    @MainActor
    static func getCardExpansionPlatformConfig(
        supportsHapticFeedback: Bool? = nil,
        supportsHover: Bool? = nil,
        supportsTouch: Bool? = nil,
        supportsVoiceOver: Bool? = nil,
        supportsSwitchControl: Bool? = nil,
        supportsAssistiveTouch: Bool? = nil,
        minTouchTarget: CGFloat? = nil,
        hoverDelay: TimeInterval? = nil,
        animationEasing: Animation? = nil
    ) -> SixLayerFramework.CardExpansionPlatformConfig {
        // Use the framework's CardExpansionPlatformConfig
        return SixLayerFramework.CardExpansionPlatformConfig(
            supportsHapticFeedback: supportsHapticFeedback ?? false,
            supportsHover: supportsHover ?? false,
            supportsTouch: supportsTouch ?? true,
            supportsVoiceOver: supportsVoiceOver ?? true,
            supportsSwitchControl: supportsSwitchControl ?? true,
            supportsAssistiveTouch: supportsAssistiveTouch ?? true,
            minTouchTarget: minTouchTarget ?? 44.0,
            hoverDelay: hoverDelay ?? 0.1,
            animationEasing: animationEasing ?? .easeInOut(duration: 0.3)
        )
    }
    
    /// Asserts that a card expansion config matches expected capabilities
    /// 
    /// ⚠️ ARCHITECTURAL CONSTRAINT: This function should ONLY be used for testing card-specific functionality.
    /// For general platform capability testing, use RuntimeCapabilityDetection directly.
    /// Card config should ONLY be used by card display functions in production code.
    /// 
    /// - Parameters:
    ///   - config: The card expansion configuration to test
    ///   - touch: Expected touch support
    ///   - haptic: Expected haptic support
    ///   - hover: Expected hover support
    ///   - voiceOver: Expected VoiceOver support
    ///   - switchControl: Expected Switch Control support
    ///   - assistiveTouch: Expected AssistiveTouch support
    ///   - file: File name for assertion
    ///   - line: Line number for assertion
    func assertCardExpansionConfig(
        _ config: SixLayerFramework.CardExpansionPlatformConfig,
        touch: Bool? = nil,
        haptic: Bool? = nil,
        hover: Bool? = nil,
        voiceOver: Bool? = nil,
        switchControl: Bool? = nil,
        assistiveTouch: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // NOTE: Thread/Actor Isolation Issue - getCardExpansionPlatformConfig() may not be accessing test defaults
        // due to thread/actor isolation with Thread.current.threadDictionary. The framework code correctly uses
        // RuntimeCapabilityDetection, but the test platform may not be accessible from the MainActor context.
        // Tests should handle platform-specific behavior in the test itself, not in this assertion helper.
        if let touch = touch {
            #expect(config.supportsTouch == touch, "Card config touch support should be \(touch) (thread/actor isolation issue with test platform)", )
        }
        if let haptic = haptic {
            #expect(config.supportsHapticFeedback == haptic, "Card config haptic support should be \(haptic) (thread/actor isolation issue with test platform)", )
        }
        if let hover = hover {
            #expect(config.supportsHover == hover, "Card config hover support should be \(hover) (thread/actor isolation issue with test platform)", )
        }
        if let voiceOver = voiceOver {
            #expect(config.supportsVoiceOver == voiceOver, "Card config VoiceOver support should be \(voiceOver) (thread/actor isolation issue with test platform)", )
        }
        if let switchControl = switchControl {
            #expect(config.supportsSwitchControl == switchControl, "Card config Switch Control support should be \(switchControl) (thread/actor isolation issue with test platform)", )
        }
        if let assistiveTouch = assistiveTouch {
            #expect(config.supportsAssistiveTouch == assistiveTouch, "Card config AssistiveTouch support should be \(assistiveTouch) (thread/actor isolation issue with test platform)", )
        }
    }
    
}

