import Foundation
import SixLayerFramework

/// Defensive approach: Use enums instead of string literals to prevent runtime crashes
enum CapabilityType: String, CaseIterable {
    case touchOnly = "Touch Only"
    case hoverOnly = "Hover Only"
    case allCapabilities = "All Capabilities"
    case noCapabilities = "No Capabilities"

    /// Human-readable display name for logging and testing
    var displayName: String {
        return self.rawValue
    }

    /// Safe factory method that can't fail at runtime
    static func from(string: String) -> CapabilityType? {
        return CapabilityType(rawValue: string)
    }
}

enum AccessibilityType: String, CaseIterable {
    case noAccessibility = "No Accessibility"
    case allAccessibility = "All Accessibility"

    /// Human-readable display name for logging and testing
    var displayName: String {
        return self.rawValue
    }

    /// Safe factory method that can't fail at runtime
    static func from(string: String) -> AccessibilityType? {
        return AccessibilityType(rawValue: string)
    }
}

/// Defensive test pattern that prevents crashes
struct DefensiveTestPatterns {

    /// Safe capability override for capability types using RuntimeCapabilityDetection
    static func setCapabilitiesForType(_ type: CapabilityType) {
        switch type {
        case .touchOnly:
            RuntimeCapabilityDetection.setTestTouchSupport(true)
            RuntimeCapabilityDetection.setTestHapticFeedback(true)
            RuntimeCapabilityDetection.setTestHover(false)
        case .hoverOnly:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestHover(true)
        case .allCapabilities:
            RuntimeCapabilityDetection.setTestTouchSupport(true)
            RuntimeCapabilityDetection.setTestHapticFeedback(true)
            RuntimeCapabilityDetection.setTestHover(true)
        case .noCapabilities:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestHover(false)
        }
    }

    /// Safe capability override for accessibility types using RuntimeCapabilityDetection
    static func setCapabilitiesForAccessibilityType(_ type: AccessibilityType) {
        // For accessibility testing, override accessibility capabilities
        switch type {
        case .noAccessibility:
            RuntimeCapabilityDetection.setTestVoiceOver(false)
            RuntimeCapabilityDetection.setTestSwitchControl(false)
            RuntimeCapabilityDetection.setTestAssistiveTouch(false)
        case .allAccessibility:
            RuntimeCapabilityDetection.setTestVoiceOver(true)
            RuntimeCapabilityDetection.setTestSwitchControl(true)
            RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        }
    }

    /// Defensive test case creation with compile-time safety
    static func createDefensiveCapabilityTestCases() -> [(CapabilityType, () -> Void)] {
        return CapabilityType.allCases.map { type in
            (type, { setCapabilitiesForType(type) })
        }
    }

    /// Defensive test case creation with compile-time safety
    static func createDefensiveAccessibilityTestCases() -> [(AccessibilityType, () -> Void)] {
        return AccessibilityType.allCases.map { type in
            (type, { setCapabilitiesForAccessibilityType(type) })
        }
    }
}

/// Detailed error types for better debugging
enum ValidationError: Error, CustomStringConvertible {
    case invalidCapabilityName(provided: String, validOptions: [String])
    case invalidAccessibilityName(provided: String, validOptions: [String])

    var description: String {
        switch self {
        case .invalidCapabilityName(let provided, let validOptions):
            return """
            Invalid capability name: "\(provided)"
            Valid options: \(validOptions.joined(separator: ", "))
            """
        case .invalidAccessibilityName(let provided, let validOptions):
            return """
            Invalid accessibility name: "\(provided)"
            Valid options: \(validOptions.joined(separator: ", "))
            """
        }
    }
}
