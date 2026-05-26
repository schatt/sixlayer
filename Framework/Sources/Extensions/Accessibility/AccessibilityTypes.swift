import Foundation
import SwiftUI

// MARK: - Accessibility Settings Types

/// Accessibility settings configuration
public struct AccessibilitySettings: Sendable, Equatable {
    public var voiceOverSupport: Bool
    public var keyboardNavigation: Bool
    public var highContrastMode: Bool
    public var dynamicType: Bool
    public var preferredContentSize: SixLayerContentSizeCategory
    public var reducedMotion: Bool
    public var hapticFeedback: Bool
    
    public init(
        voiceOverSupport: Bool = true,
        keyboardNavigation: Bool = true,
        highContrastMode: Bool = true,
        dynamicType: Bool = true,
        preferredContentSize: SixLayerContentSizeCategory = .large,
        reducedMotion: Bool = true,
        hapticFeedback: Bool = true
    ) {
        self.voiceOverSupport = voiceOverSupport
        self.keyboardNavigation = keyboardNavigation
        self.highContrastMode = highContrastMode
        self.dynamicType = dynamicType
        self.preferredContentSize = preferredContentSize
        self.reducedMotion = reducedMotion
        self.hapticFeedback = hapticFeedback
    }
}

/// Accessibility compliance metrics
public struct AccessibilityComplianceMetrics {
    public var voiceOverCompliance: ComplianceLevel
    public var keyboardCompliance: ComplianceLevel
    public var contrastCompliance: ComplianceLevel
    public var motionCompliance: ComplianceLevel
    public var overallComplianceScore: Double
    
    public init(
        voiceOverCompliance: ComplianceLevel = .basic,
        keyboardCompliance: ComplianceLevel = .basic,
        contrastCompliance: ComplianceLevel = .basic,
        motionCompliance: ComplianceLevel = .basic,
        overallComplianceScore: Double = 0.0
    ) {
        self.voiceOverCompliance = voiceOverCompliance
        self.keyboardCompliance = keyboardCompliance
        self.contrastCompliance = contrastCompliance
        self.motionCompliance = motionCompliance
        self.overallComplianceScore = overallComplianceScore
    }
}

/// Compliance level for accessibility standards
public enum ComplianceLevel: CaseIterable {
    case basic
    case intermediate
    case advanced
    case expert
    
    public var rawValue: Int {
        switch self {
        case .basic: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}

// MARK: - Accessibility Testing Types

/// Result of accessibility audit
public struct AccessibilityAuditResult {
    public let complianceLevel: ComplianceLevel
    public let issues: [AccessibilityIssue]
    public let recommendations: [String]
    public let score: Double
    public let complianceMetrics: AccessibilityComplianceMetrics
    
    public init(complianceLevel: ComplianceLevel, issues: [AccessibilityIssue] = [], recommendations: [String] = [], score: Double = 0.0, complianceMetrics: AccessibilityComplianceMetrics) {
        self.complianceLevel = complianceLevel
        self.issues = issues
        self.recommendations = recommendations
        self.score = score
        self.complianceMetrics = complianceMetrics
    }
}

/// Accessibility issue found during audit
public struct AccessibilityIssue {
    public let severity: IssueSeverity
    public let description: String
    public let element: String
    public let suggestion: String
    
    public init(severity: IssueSeverity, description: String, element: String, suggestion: String) {
        self.severity = severity
        self.description = description
        self.element = element
        self.suggestion = suggestion
    }
}

/// Severity level of accessibility issue
public enum IssueSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - VoiceOver Types

/// VoiceOver announcement types
public enum VoiceOverAnnouncementType: String, CaseIterable {
    case element = "element"
    case action = "action"
    case state = "state"
    case hint = "hint"
    case value = "value"
    case custom = "custom"
}

/// VoiceOver navigation modes
public enum VoiceOverNavigationMode: String, CaseIterable {
    case automatic = "automatic"
    case manual = "manual"
    case custom = "custom"
}

/// VoiceOver gesture types
public enum VoiceOverGestureType: String, CaseIterable {
    case singleTap = "singleTap"
    case doubleTap = "doubleTap"
    case tripleTap = "tripleTap"
    case swipeLeft = "swipeLeft"
    case swipeRight = "swipeRight"
    case swipeUp = "swipeUp"
    case swipeDown = "swipeDown"
    case twoFingerTap = "twoFingerTap"
    case twoFingerSwipeLeft = "twoFingerSwipeLeft"
    case twoFingerSwipeRight = "twoFingerSwipeRight"
    case twoFingerSwipeUp = "twoFingerSwipeUp"
    case twoFingerSwipeDown = "twoFingerSwipeDown"
    case threeFingerTap = "threeFingerTap"
    case threeFingerSwipeLeft = "threeFingerSwipeLeft"
    case threeFingerSwipeRight = "threeFingerSwipeRight"
    case threeFingerSwipeUp = "threeFingerSwipeUp"
    case threeFingerSwipeDown = "threeFingerSwipeDown"
    case fourFingerTap = "fourFingerTap"
    case fourFingerSwipeLeft = "fourFingerSwipeLeft"
    case fourFingerSwipeRight = "fourFingerSwipeRight"
    case fourFingerSwipeUp = "fourFingerSwipeUp"
    case fourFingerSwipeDown = "fourFingerSwipeDown"
    case rotor = "rotor"
    case custom = "custom"
}

/// VoiceOver custom action types
public enum VoiceOverCustomActionType: String, CaseIterable {
    case activate = "activate"
    case edit = "edit"
    case delete = "delete"
    case select = "select"
    case deselect = "deselect"
    case expand = "expand"
    case collapse = "collapse"
    case show = "show"
    case hide = "hide"
    case play = "play"
    case pause = "pause"
    case stop = "stop"
    case next = "next"
    case previous = "previous"
    case first = "first"
    case last = "last"
    case custom = "custom"
}

/// VoiceOver announcement priority
public enum VoiceOverAnnouncementPriority: String, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
}

/// VoiceOver announcement timing
public enum VoiceOverAnnouncementTiming: String, CaseIterable {
    case immediate = "immediate"
    case delayed = "delayed"
    case queued = "queued"
    case interrupt = "interrupt"
}

/// VoiceOver element traits
public struct VoiceOverElementTraits: OptionSet, Sendable {
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    public static let button = VoiceOverElementTraits(rawValue: 1 << 0)
    public static let link = VoiceOverElementTraits(rawValue: 1 << 1)
    public static let header = VoiceOverElementTraits(rawValue: 1 << 2)
    public static let searchField = VoiceOverElementTraits(rawValue: 1 << 3)
    public static let image = VoiceOverElementTraits(rawValue: 1 << 4)
    public static let selected = VoiceOverElementTraits(rawValue: 1 << 5)
    public static let playsSound = VoiceOverElementTraits(rawValue: 1 << 6)
    public static let keyboardKey = VoiceOverElementTraits(rawValue: 1 << 7)
    public static let staticText = VoiceOverElementTraits(rawValue: 1 << 8)
    public static let summaryElement = VoiceOverElementTraits(rawValue: 1 << 9)
    public static let notEnabled = VoiceOverElementTraits(rawValue: 1 << 10)
    public static let updatesFrequently = VoiceOverElementTraits(rawValue: 1 << 11)
    public static let startsMediaSession = VoiceOverElementTraits(rawValue: 1 << 12)
    public static let adjustable = VoiceOverElementTraits(rawValue: 1 << 13)
    public static let allowsDirectInteraction = VoiceOverElementTraits(rawValue: 1 << 14)
    public static let causesPageTurn = VoiceOverElementTraits(rawValue: 1 << 15)
    public static let tabBar = VoiceOverElementTraits(rawValue: 1 << 16)
    public static let textEntry = VoiceOverElementTraits(rawValue: 1 << 17)
    public static let none: VoiceOverElementTraits = []
    public static let all = VoiceOverElementTraits(rawValue: UInt64.max)
}

/// VoiceOver configuration
public struct VoiceOverConfiguration {
    public let announcementType: VoiceOverAnnouncementType
    public let navigationMode: VoiceOverNavigationMode
    public let gestureSensitivity: VoiceOverGestureSensitivity
    public let announcementPriority: VoiceOverAnnouncementPriority
    public let announcementTiming: VoiceOverAnnouncementTiming
    public let enableCustomActions: Bool
    public let enableGestureRecognition: Bool
    public let enableRotorSupport: Bool
    public let enableHapticFeedback: Bool
    
    public init(
        announcementType: VoiceOverAnnouncementType = .element,
        navigationMode: VoiceOverNavigationMode = .automatic,
        gestureSensitivity: VoiceOverGestureSensitivity = .medium,
        announcementPriority: VoiceOverAnnouncementPriority = .normal,
        announcementTiming: VoiceOverAnnouncementTiming = .immediate,
        enableCustomActions: Bool = true,
        enableGestureRecognition: Bool = true,
        enableRotorSupport: Bool = true,
        enableHapticFeedback: Bool = true
    ) {
        self.announcementType = announcementType
        self.navigationMode = navigationMode
        self.gestureSensitivity = gestureSensitivity
        self.announcementPriority = announcementPriority
        self.announcementTiming = announcementTiming
        self.enableCustomActions = enableCustomActions
        self.enableGestureRecognition = enableGestureRecognition
        self.enableRotorSupport = enableRotorSupport
        self.enableHapticFeedback = enableHapticFeedback
    }
}

/// VoiceOver gesture sensitivity levels
public enum VoiceOverGestureSensitivity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// VoiceOver custom action
public struct VoiceOverCustomAction {
    public let name: String
    public let type: VoiceOverCustomActionType
    public let handler: () -> Void
    
    public init(name: String, type: VoiceOverCustomActionType, handler: @escaping () -> Void) {
        self.name = name
        self.type = type
        self.handler = handler
    }
}

/// VoiceOver announcement
public struct VoiceOverAnnouncement {
    public let message: String
    public let type: VoiceOverAnnouncementType
    public let priority: VoiceOverAnnouncementPriority
    public let timing: VoiceOverAnnouncementTiming
    public let delay: TimeInterval
    
    public init(
        message: String,
        type: VoiceOverAnnouncementType = .element,
        priority: VoiceOverAnnouncementPriority = .normal,
        timing: VoiceOverAnnouncementTiming = .immediate,
        delay: TimeInterval = 0.0
    ) {
        self.message = message
        self.type = type
        self.priority = priority
        self.timing = timing
        self.delay = delay
    }
}

// MARK: - Switch Control Types

/// Switch Control action types
public enum SwitchControlActionType: String, CaseIterable {
    case select = "select"
    case moveNext = "moveNext"
    case movePrevious = "movePrevious"
    case moveUp = "moveUp"
    case moveDown = "moveDown"
    case moveLeft = "moveLeft"
    case moveRight = "moveRight"
    case activate = "activate"
    case edit = "edit"
    case delete = "delete"
    case custom = "custom"
}

/// Switch Control navigation patterns
public enum SwitchControlNavigationPattern: String, CaseIterable {
    case linear = "linear"
    case grid = "grid"
    case custom = "custom"
}


/// Switch Control custom action
public struct SwitchControlCustomAction {
    public let name: String
    public let type: SwitchControlActionType
    public let gesture: SwitchControlGestureType
    public let handler: () -> Void
    
    public init(
        name: String,
        type: SwitchControlActionType,
        gesture: SwitchControlGestureType,
        handler: @escaping () -> Void
    ) {
        self.name = name
        self.type = type
        self.gesture = gesture
        self.handler = handler
    }
}


// MARK: - AssistiveTouch Types

/// AssistiveTouch action types
public enum AssistiveTouchActionType: String, CaseIterable {
    case home = "home"
    case back = "back"
    case menu = "menu"
    case custom = "custom"
}


/// AssistiveTouch custom action
public struct AssistiveTouchCustomAction {
    public let name: String
    public let type: AssistiveTouchActionType
    public let gesture: AssistiveTouchGestureType
    public let intensity: AssistiveTouchGestureIntensity
    public let handler: () -> Void
    
    public init(
        name: String,
        type: AssistiveTouchActionType,
        gesture: AssistiveTouchGestureType,
        intensity: AssistiveTouchGestureIntensity = .medium,
        handler: @escaping () -> Void
    ) {
        self.name = name
        self.type = type
        self.gesture = gesture
        self.intensity = intensity
        self.handler = handler
    }
}


// MARK: - Eye Tracking Types

/// Eye tracking calibration levels
public enum EyeTrackingCalibrationLevel: String, CaseIterable {
    case basic = "basic"
    case standard = "standard"
    case advanced = "advanced"
    case expert = "expert"
}

/// Eye tracking interaction types
public enum EyeTrackingInteractionType: String, CaseIterable {
    case gaze = "gaze"
    case dwell = "dwell"
    case blink = "blink"
    case wink = "wink"
    case custom = "custom"
}

/// Eye tracking focus management
public enum EyeTrackingFocusManagement: String, CaseIterable {
    case automatic = "automatic"
    case manual = "manual"
    case hybrid = "hybrid"
}

/// Eye tracking configuration
public struct EyeTrackingConfiguration {
    public let calibrationLevel: EyeTrackingCalibrationLevel
    public let interactionType: EyeTrackingInteractionType
    public let focusManagement: EyeTrackingFocusManagement
    public let dwellTime: TimeInterval
    public let enableHapticFeedback: Bool
    public let enableAudioFeedback: Bool
    
    public init(
        calibrationLevel: EyeTrackingCalibrationLevel = .standard,
        interactionType: EyeTrackingInteractionType = .dwell,
        focusManagement: EyeTrackingFocusManagement = .automatic,
        dwellTime: TimeInterval = 1.0,
        enableHapticFeedback: Bool = true,
        enableAudioFeedback: Bool = false
    ) {
        self.calibrationLevel = calibrationLevel
        self.interactionType = interactionType
        self.focusManagement = focusManagement
        self.dwellTime = dwellTime
        self.enableHapticFeedback = enableHapticFeedback
        self.enableAudioFeedback = enableAudioFeedback
    }
}


// MARK: - Voice Control Types

/// Voice Control command types
public enum VoiceControlCommandType: String, CaseIterable {
    case tap = "tap"
    case swipe = "swipe"
    case scroll = "scroll"
    case zoom = "zoom"
    case select = "select"
    case edit = "edit"
    case delete = "delete"
    case custom = "custom"
}

/// Voice Control feedback types
public enum VoiceControlFeedbackType: String, CaseIterable {
    case audio = "audio"
    case haptic = "haptic"
    case visual = "visual"
    case combined = "combined"
}

/// Voice Control custom command
public struct VoiceControlCustomCommand {
    public let phrase: String
    public let type: VoiceControlCommandType
    public let handler: () -> Void
    
    public init(phrase: String, type: VoiceControlCommandType, handler: @escaping () -> Void) {
        self.phrase = phrase
        self.type = type
        self.handler = handler
    }
}

/// Voice Control configuration
public struct VoiceControlConfiguration {
    public let enableCustomCommands: Bool
    public let feedbackType: VoiceControlFeedbackType
    public let enableAudioFeedback: Bool
    public let enableHapticFeedback: Bool
    public let enableVisualFeedback: Bool
    public let commandTimeout: TimeInterval
    
    public init(
        enableCustomCommands: Bool = true,
        feedbackType: VoiceControlFeedbackType = .combined,
        enableAudioFeedback: Bool = true,
        enableHapticFeedback: Bool = true,
        enableVisualFeedback: Bool = true,
        commandTimeout: TimeInterval = 5.0
    ) {
        self.enableCustomCommands = enableCustomCommands
        self.feedbackType = feedbackType
        self.enableAudioFeedback = enableAudioFeedback
        self.enableHapticFeedback = enableHapticFeedback
        self.enableVisualFeedback = enableVisualFeedback
        self.commandTimeout = commandTimeout
    }
}

/// Voice Control command result
public struct VoiceControlCommandResult {
    public let success: Bool
    public let action: String?
    public let error: String?
    public let feedback: String?
    
    public init(success: Bool, action: String? = nil, error: String? = nil, feedback: String? = nil) {
        self.success = success
        self.action = action
        self.error = error
        self.feedback = feedback
    }
}

/// Voice Control navigation types
public enum VoiceControlNavigationType: String, CaseIterable {
    case tap = "tap"
    case swipe = "swipe"
    case scroll = "scroll"
    case zoom = "zoom"
    case select = "select"
    case navigate = "navigate"
    case back = "back"
    case home = "home"
    case menu = "menu"
}

/// Voice Control gesture types
public enum VoiceControlGestureType: String, CaseIterable {
    case tap = "tap"
    case doubleTap = "doubleTap"
    case longPress = "longPress"
    case swipeLeft = "swipeLeft"
    case swipeRight = "swipeRight"
    case swipeUp = "swipeUp"
    case swipeDown = "swipeDown"
    case pinch = "pinch"
    case rotate = "rotate"
    case scroll = "scroll"
}

/// Voice Control command recognition
public struct VoiceControlCommandRecognition {
    public let phrase: String
    public let confidence: Double
    public let timestamp: Date
    public let recognizedCommand: VoiceControlCommandType?
    
    public init(phrase: String, confidence: Double, timestamp: Date = Date(), recognizedCommand: VoiceControlCommandType? = nil) {
        self.phrase = phrase
        self.confidence = confidence
        self.timestamp = timestamp
        self.recognizedCommand = recognizedCommand
    }
}

/// Voice Control compliance result
public struct VoiceControlCompliance {
    public let isCompliant: Bool
    public let issues: [String]
    public let score: Double
    
    public init(isCompliant: Bool, issues: [String] = [], score: Double = 0.0) {
        self.isCompliant = isCompliant
        self.issues = issues
        self.score = score
    }
}

// MARK: - Material Accessibility Types

/// Material contrast levels
public enum MaterialContrastLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case maximum = "maximum"
}


/// Material accessibility configuration
public struct MaterialAccessibilityConfiguration {
    public let contrastLevel: MaterialContrastLevel
    public let enableHighContrastAlternatives: Bool
    public let enableVoiceOverDescriptions: Bool
    public let enableSwitchControlSupport: Bool
    public let enableAssistiveTouchSupport: Bool
    
    public init(
        contrastLevel: MaterialContrastLevel = .medium,
        enableHighContrastAlternatives: Bool = true,
        enableVoiceOverDescriptions: Bool = true,
        enableSwitchControlSupport: Bool = true,
        enableAssistiveTouchSupport: Bool = true
    ) {
        self.contrastLevel = contrastLevel
        self.enableHighContrastAlternatives = enableHighContrastAlternatives
        self.enableVoiceOverDescriptions = enableVoiceOverDescriptions
        self.enableSwitchControlSupport = enableSwitchControlSupport
        self.enableAssistiveTouchSupport = enableAssistiveTouchSupport
    }
}


// MARK: - Platform Accessibility Extensions

// Platform extensions are already defined in CrossPlatformOptimizationLayer6.swift

// MARK: - Accessibility Testing Utilities

/// Accessibility testing utilities
public struct AccessibilityTesting {
    /// Audit view accessibility compliance
        static func auditViewAccessibility<Content: View>(_ content: Content) -> AccessibilityAuditResult {
        // This is a placeholder implementation
        // In a real implementation, this would analyze the view hierarchy
        // and check for accessibility compliance
        
        let complianceMetrics = AccessibilityComplianceMetrics(
            voiceOverCompliance: .basic,
            keyboardCompliance: .basic,
            contrastCompliance: .basic,
            motionCompliance: .basic,
            overallComplianceScore: 75.0
        )
        
        return AccessibilityAuditResult(
            complianceLevel: .basic,
            issues: [],
            recommendations: ["Add accessibility labels", "Ensure keyboard navigation"],
            score: 75.0,
            complianceMetrics: complianceMetrics
        )
    }
}
