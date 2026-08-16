import Testing


//
//  AccessibilityTypesTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates accessibility types and enums functionality and comprehensive type system validation,
//  ensuring proper accessibility type definitions and enum behavior across all supported platforms.
//
//  TESTING SCOPE:
//  - Accessibility type definitions and enum validation
//  - Platform-specific accessibility type behavior
//  - Accessibility type conversion and mapping
//  - Accessibility type consistency and validation
//  - Cross-platform accessibility type compatibility
//  - Edge cases and error handling for accessibility types
//
//  METHODOLOGY:
//  - Test accessibility type definitions and enum validation
//  - Verify platform-specific accessibility type behavior using switch statements
//  - Test accessibility type conversion and mapping functionality
//  - Validate accessibility type consistency and validation
//  - Test cross-platform accessibility type compatibility
//  - Test edge cases and error handling for accessibility types
//
//  QUALITY ASSESSMENT: ✅ GOOD
//  - ✅ Good: Uses proper business logic testing with enum validation
//  - ✅ Good: Tests all accessibility types comprehensively
//  - ✅ Good: Validates enum cases and counts properly
//  - 🔧 Action Required: Add platform-specific behavior testing
//  - 🔧 Action Required: Add accessibility type conversion testing
//

import SwiftUI
@testable import SixLayerFramework

/// Comprehensive tests for all accessibility types and enums
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Accessibility Types")
open class AccessibilityTypesTests: BaseTestClass {
    
    // MARK: - Platform-Specific Business Logic Tests
    
    @Test func testAccessibilityTypesAcrossPlatforms() {
        // Given: Platform-specific accessibility type expectations
        let platform = SixLayerPlatform.current
        
        // When: Testing accessibility types on different platforms
        // Then: Test platform-specific business logic
        switch platform {
        case .iOS:
            // iOS should support comprehensive accessibility types
            #expect(VoiceOverAnnouncementType.allCases.count >= 6, "iOS should support comprehensive VoiceOver announcement types")
            #expect(VoiceOverGestureType.allCases.count >= 24, "iOS should support comprehensive VoiceOver gesture types")
            #expect(VoiceOverCustomActionType.allCases.count >= 17, "iOS should support comprehensive VoiceOver custom action types")
            
            // Test iOS-specific accessibility type behavior
            #expect(VoiceOverAnnouncementType.allCases.contains(.element), "iOS should support element announcements")
            #expect(VoiceOverAnnouncementType.allCases.contains(.action), "iOS should support action announcements")
            #expect(VoiceOverGestureType.allCases.contains(.singleTap), "iOS should support single tap gestures")
            #expect(VoiceOverGestureType.allCases.contains(.doubleTap), "iOS should support double tap gestures")
            
        case .macOS:
            // macOS should support keyboard-focused accessibility types
            #expect(VoiceOverAnnouncementType.allCases.count >= 6, "macOS should support comprehensive VoiceOver announcement types")
            #expect(VoiceOverGestureType.allCases.count >= 24, "macOS should support comprehensive VoiceOver gesture types")
            #expect(VoiceOverCustomActionType.allCases.count >= 17, "macOS should support comprehensive VoiceOver custom action types")
            
            // Test macOS-specific accessibility type behavior
            #expect(VoiceOverAnnouncementType.allCases.contains(.element), "macOS should support element announcements")
            #expect(VoiceOverAnnouncementType.allCases.contains(.state), "macOS should support state announcements")
            #expect(VoiceOverGestureType.allCases.contains(.rotor), "macOS should support rotor gestures")
            #expect(VoiceOverCustomActionType.allCases.contains(.activate), "macOS should support activate actions")
            
        case .watchOS:
            // watchOS should have simplified accessibility types
            #expect(VoiceOverAnnouncementType.allCases.count >= 6, "watchOS should support comprehensive VoiceOver announcement types")
            #expect(VoiceOverGestureType.allCases.count >= 24, "watchOS should support comprehensive VoiceOver gesture types")
            #expect(VoiceOverCustomActionType.allCases.count >= 17, "watchOS should support comprehensive VoiceOver custom action types")
            
            // Test watchOS-specific accessibility type behavior
            #expect(VoiceOverAnnouncementType.allCases.contains(.element), "watchOS should support element announcements")
            #expect(VoiceOverGestureType.allCases.contains(.singleTap), "watchOS should support single tap gestures")
            #expect(VoiceOverCustomActionType.allCases.contains(.activate), "watchOS should support activate actions")
            
        case .tvOS:
            // tvOS should support focus-based accessibility types
            #expect(VoiceOverAnnouncementType.allCases.count >= 6, "tvOS should support comprehensive VoiceOver announcement types")
            #expect(VoiceOverGestureType.allCases.count >= 24, "tvOS should support comprehensive VoiceOver gesture types")
            #expect(VoiceOverCustomActionType.allCases.count >= 17, "tvOS should support comprehensive VoiceOver custom action types")
            
            // Test tvOS-specific accessibility type behavior
            #expect(VoiceOverAnnouncementType.allCases.contains(.element), "tvOS should support element announcements")
            #expect(VoiceOverGestureType.allCases.contains(.rotor), "tvOS should support rotor gestures")
            #expect(VoiceOverCustomActionType.allCases.contains(.activate), "tvOS should support activate actions")
            
        case .visionOS:
            // visionOS should support spatial accessibility types
            #expect(VoiceOverAnnouncementType.allCases.count >= 6, "visionOS should support comprehensive VoiceOver announcement types")
            #expect(VoiceOverGestureType.allCases.count >= 24, "visionOS should support comprehensive VoiceOver gesture types")
            #expect(VoiceOverCustomActionType.allCases.count >= 17, "visionOS should support comprehensive VoiceOver custom action types")
            
            // Test visionOS-specific accessibility type behavior
            #expect(VoiceOverAnnouncementType.allCases.contains(.element), "visionOS should support element announcements")
            #expect(VoiceOverGestureType.allCases.contains(.singleTap), "visionOS should support single tap gestures")
            #expect(VoiceOverCustomActionType.allCases.contains(.activate), "visionOS should support activate actions")
        }
    }
    
    @Test func testAccessibilityTypeConversionAndMapping() {
        // Given: Different accessibility types for conversion testing
        let announcementType = VoiceOverAnnouncementType.element
        let gestureType = VoiceOverGestureType.singleTap
        let actionType = VoiceOverCustomActionType.activate
        
        // When: Converting accessibility types
        let announcementString = announcementType.rawValue
        let gestureString = gestureType.rawValue
        let actionString = actionType.rawValue
        
        // Then: Test business logic for type conversion
        
        // Test business logic: String conversion should be reversible
        #expect(VoiceOverAnnouncementType(rawValue: announcementString) == announcementType, 
                      "Announcement type conversion should be reversible")
        #expect(VoiceOverGestureType(rawValue: gestureString) == gestureType, 
                      "Gesture type conversion should be reversible")
        #expect(VoiceOverCustomActionType(rawValue: actionString) == actionType, 
                      "Action type conversion should be reversible")
        
        // Test business logic: All enum cases should be convertible
        for announcementType in VoiceOverAnnouncementType.allCases {
            #expect(VoiceOverAnnouncementType(rawValue: announcementType.rawValue) != nil, 
                          "All announcement types should be convertible")
        }
        
        for gestureType in VoiceOverGestureType.allCases {
            #expect(VoiceOverGestureType(rawValue: gestureType.rawValue) != nil, 
                          "All gesture types should be convertible")
        }
        
        for actionType in VoiceOverCustomActionType.allCases {
            #expect(VoiceOverCustomActionType(rawValue: actionType.rawValue) != nil, 
                          "All action types should be convertible")
        }
    }
    
    @Test func testAccessibilityTypeConsistencyAndValidation() {
        // Given: Accessibility types for consistency testing
        let announcementTypes = VoiceOverAnnouncementType.allCases
        let gestureTypes = VoiceOverGestureType.allCases
        let actionTypes = VoiceOverCustomActionType.allCases
        
        // When: Validating accessibility type consistency
        // Then: Test business logic for type consistency
        #expect(announcementTypes.count > 0, "Should have at least one announcement type")
        #expect(gestureTypes.count > 0, "Should have at least one gesture type")
        #expect(actionTypes.count > 0, "Should have at least one action type")
        
        // Test business logic: All types should have unique raw values
        let announcementRawValues = Set(announcementTypes.map { $0.rawValue })
        #expect(announcementRawValues.count == announcementTypes.count, 
                      "All announcement types should have unique raw values")
        
        let gestureRawValues = Set(gestureTypes.map { $0.rawValue })
        #expect(gestureRawValues.count == gestureTypes.count, 
                      "All gesture types should have unique raw values")
        
        let actionRawValues = Set(actionTypes.map { $0.rawValue })
        #expect(actionRawValues.count == actionTypes.count, 
                      "All action types should have unique raw values")
        
        // Test business logic: All types should be case iterable
        #expect(announcementTypes.contains(.element), "Should contain element announcement type")
        #expect(gestureTypes.contains(.singleTap), "Should contain single tap gesture type")
        #expect(actionTypes.contains(.activate), "Should contain activate action type")
    }
    
    // MARK: - VoiceOver Types Tests
    
    @Test func testVoiceOverAnnouncementType() {
        let types = VoiceOverAnnouncementType.allCases
        #expect(types.count == 6)
        #expect(types.contains(.element))
        #expect(types.contains(.action))
        #expect(types.contains(.state))
        #expect(types.contains(.hint))
        #expect(types.contains(.value))
        #expect(types.contains(.custom))
    }
    
    @Test func testVoiceOverNavigationMode() {
        let modes = VoiceOverNavigationMode.allCases
        #expect(modes.count == 3)
        #expect(modes.contains(.automatic))
        #expect(modes.contains(.manual))
        #expect(modes.contains(.custom))
    }
    
    @Test func testVoiceOverGestureType() {
        let gestures = VoiceOverGestureType.allCases
        #expect(gestures.count == 24)
        #expect(gestures.contains(.singleTap))
        #expect(gestures.contains(.doubleTap))
        #expect(gestures.contains(.tripleTap))
        #expect(gestures.contains(.rotor))
        #expect(gestures.contains(.custom))
    }
    
    @Test func testVoiceOverCustomActionType() {
        let actions = VoiceOverCustomActionType.allCases
        #expect(actions.count == 17)
        #expect(actions.contains(.activate))
        #expect(actions.contains(.edit))
        #expect(actions.contains(.delete))
        #expect(actions.contains(.play))
        #expect(actions.contains(.pause))
        #expect(actions.contains(.custom))
    }
    
    @Test func testVoiceOverAnnouncementPriority() {
        let priorities = VoiceOverAnnouncementPriority.allCases
        #expect(priorities.count == 4)
        #expect(priorities.contains(.low))
        #expect(priorities.contains(.normal))
        #expect(priorities.contains(.high))
        #expect(priorities.contains(.critical))
    }
    
    @Test func testVoiceOverAnnouncementTiming() {
        let timings = VoiceOverAnnouncementTiming.allCases
        #expect(timings.count == 4)
        #expect(timings.contains(.immediate))
        #expect(timings.contains(.delayed))
        #expect(timings.contains(.queued))
        #expect(timings.contains(.interrupt))
    }
    
    @Test func testVoiceOverElementTraits() {
        let traits = VoiceOverElementTraits.all
        #expect(traits.rawValue != 0)
        
        let button = VoiceOverElementTraits.button
        let link = VoiceOverElementTraits.link
        let header = VoiceOverElementTraits.header
        
        #expect(button.contains(.button))
        #expect(link.contains(.link))
        #expect(header.contains(.header))
        
        let combined = button.union(link).union(header)
        #expect(combined.contains(.button))
        #expect(combined.contains(.link))
        #expect(combined.contains(.header))
    }
    
    @Test func testVoiceOverConfiguration() {
        let config = VoiceOverConfiguration()
        #expect(config.announcementType == .element)
        #expect(config.navigationMode == .automatic)
        #expect(config.gestureSensitivity == .medium)
        #expect(config.announcementPriority == .normal)
        #expect(config.announcementTiming == .immediate)
        #expect(config.enableCustomActions)
        #expect(config.enableGestureRecognition)
        #expect(config.enableRotorSupport)
        #expect(config.enableHapticFeedback)
    }
    
    @Test func testVoiceOverGestureSensitivity() {
        let sensitivities = VoiceOverGestureSensitivity.allCases
        #expect(sensitivities.count == 3)
        #expect(sensitivities.contains(.low))
        #expect(sensitivities.contains(.medium))
        #expect(sensitivities.contains(.high))
    }
    
    @Test func testVoiceOverCustomAction() {
        var actionExecuted = false
        let action = VoiceOverCustomAction(
            name: "Test Action",
            type: .activate
        ) {
            actionExecuted = true
        }
        
        #expect(action.name == "Test Action")
        #expect(action.type == .activate)
        action.handler()
        #expect(actionExecuted)
    }
    
    @Test func testVoiceOverAnnouncement() {
        let announcement = VoiceOverAnnouncement(
            message: "Test message",
            type: .element,
            priority: .normal,
            timing: .immediate,
            delay: 0.5
        )
        
        #expect(announcement.message == "Test message")
        #expect(announcement.type == .element)
        #expect(announcement.priority == .normal)
        #expect(announcement.timing == .immediate)
        #expect(announcement.delay == 0.5)
    }
    
    // MARK: - Switch Control Types Tests
    
    @Test func testSwitchControlActionType() {
        let actions = SwitchControlActionType.allCases
        #expect(actions.count == 11)
        #expect(actions.contains(.select))
        #expect(actions.contains(.moveNext))
        #expect(actions.contains(.movePrevious))
        #expect(actions.contains(.activate))
        #expect(actions.contains(.custom))
    }
    
    @Test func testSwitchControlNavigationPattern() {
        let patterns = SwitchControlNavigationPattern.allCases
        #expect(patterns.count == 3)
        #expect(patterns.contains(.linear))
        #expect(patterns.contains(.grid))
        #expect(patterns.contains(.custom))
    }
    
    @Test func testSwitchControlGestureType() {
        let gestures = SwitchControlGestureType.allCases
        #expect(gestures.count == 7)
        #expect(gestures.contains(.singleTap))
        #expect(gestures.contains(.doubleTap))
        #expect(gestures.contains(.longPress))
        #expect(gestures.contains(.swipeLeft))
        #expect(gestures.contains(.swipeRight))
        #expect(gestures.contains(.swipeUp))
        #expect(gestures.contains(.swipeDown))
    }
    
    @Test func testSwitchControlGestureIntensity() {
        let intensities = SwitchControlGestureIntensity.allCases
        #expect(intensities.count == 3)
        #expect(intensities.contains(.light))
        #expect(intensities.contains(.medium))
        #expect(intensities.contains(.heavy))
    }
    
    @Test func testSwitchControlGesture() {
        let gesture = SwitchControlGesture(
            type: .singleTap,
            intensity: .medium
        )
        
        #expect(gesture.type == .singleTap)
        #expect(gesture.intensity == .medium)
        // timestamp is non-optional Date, so just verify it exists
        let _ = gesture.timestamp
    }
    
    @Test func testSwitchControlAction() {
        var actionExecuted = false
        let action = SwitchControlAction(
            name: "Test Action",
            gesture: .singleTap
        ) {
            actionExecuted = true
        }
        
        #expect(action.name == "Test Action")
        #expect(action.gesture == .singleTap)
        action.action()
        #expect(actionExecuted)
    }
    
    @Test func testSwitchControlFocusResult() {
        let successResult = SwitchControlFocusResult(
            success: true,
            focusedElement: "Test Element"
        )
        
        #expect(successResult.success)
        #expect(successResult.focusedElement as? String == "Test Element")
        #expect(successResult.error == nil)
        
        let failureResult = SwitchControlFocusResult(
            success: false,
            error: "Test Error"
        )
        
        #expect(!failureResult.success)
        #expect(failureResult.focusedElement == nil)
        #expect(failureResult.error == "Test Error")
    }
    
    @Test func testSwitchControlGestureResult() {
        let successResult = SwitchControlGestureResult(
            success: true,
            action: "Test Action"
        )
        
        #expect(successResult.success)
        #expect(successResult.action == "Test Action")
        #expect(successResult.error == nil)
        
        let failureResult = SwitchControlGestureResult(
            success: false,
            error: "Test Error"
        )
        
        #expect(!failureResult.success)
        #expect(failureResult.action == nil)
        #expect(failureResult.error == "Test Error")
    }
    
    @Test func testSwitchControlCompliance() {
        let compliant = SwitchControlCompliance(
            isCompliant: true,
            issues: [],
            score: 100.0
        )
        
        #expect(compliant.isCompliant)
        #expect(compliant.issues.isEmpty)
        #expect(compliant.score == 100.0)
        
        let nonCompliant = SwitchControlCompliance(
            isCompliant: false,
            issues: ["Issue 1", "Issue 2"],
            score: 50.0
        )
        
        #expect(!nonCompliant.isCompliant)
        #expect(nonCompliant.issues.count == 2)
        #expect(nonCompliant.score == 50.0)
    }
    
    // MARK: - AssistiveTouch Types Tests
    
    @Test func testAssistiveTouchActionType() {
        let actions = AssistiveTouchActionType.allCases
        #expect(actions.count == 4)
        #expect(actions.contains(.home))
        #expect(actions.contains(.back))
        #expect(actions.contains(.menu))
        #expect(actions.contains(.custom))
    }
    
    @Test func testAssistiveTouchGestureSensitivity() {
        let sensitivities = AssistiveTouchGestureSensitivity.allCases
        #expect(sensitivities.count == 3)
        #expect(sensitivities.contains(.low))
        #expect(sensitivities.contains(.medium))
        #expect(sensitivities.contains(.high))
    }
    
    @Test func testAssistiveTouchMenuStyle() {
        let styles = AssistiveTouchMenuStyle.allCases
        #expect(styles.count == 3)
        #expect(styles.contains(.floating))
        #expect(styles.contains(.docked))
        #expect(styles.contains(.contextual))
    }
    
    @Test func testAssistiveTouchGestureType() {
        let gestures = AssistiveTouchGestureType.allCases
        #expect(gestures.count == 7)
        #expect(gestures.contains(.singleTap))
        #expect(gestures.contains(.doubleTap))
        #expect(gestures.contains(.longPress))
        #expect(gestures.contains(.swipeLeft))
        #expect(gestures.contains(.swipeRight))
        #expect(gestures.contains(.swipeUp))
        #expect(gestures.contains(.swipeDown))
    }
    
    @Test func testAssistiveTouchGestureIntensity() {
        let intensities = AssistiveTouchGestureIntensity.allCases
        #expect(intensities.count == 3)
        #expect(intensities.contains(.light))
        #expect(intensities.contains(.medium))
        #expect(intensities.contains(.heavy))
    }
    
    @Test func testAssistiveTouchConfig() {
        let config = AssistiveTouchConfig()
        #expect(config.enableIntegration)
        #expect(config.enableCustomActions)
        #expect(config.enableMenuSupport)
        #expect(config.enableGestureRecognition)
        #expect(config.gestureSensitivity == .medium)
        #expect(config.menuStyle == .floating)
    }
    
    @Test func testAssistiveTouchGesture() {
        let gesture = AssistiveTouchGesture(
            type: .singleTap,
            intensity: .medium
        )
        
        #expect(gesture.type == .singleTap)
        #expect(gesture.intensity == .medium)
        // timestamp is non-optional Date, so just verify it exists
        let _ = gesture.timestamp
    }
    
    @Test func testAssistiveTouchAction() {
        var actionExecuted = false
        let action = AssistiveTouchAction(
            name: "Test Action",
            gesture: .singleTap
        ) {
            actionExecuted = true
        }
        
        #expect(action.name == "Test Action")
        #expect(action.gesture == .singleTap)
        action.action()
        #expect(actionExecuted)
    }
    
    @Test func testAssistiveTouchMenuAction() {
        let actions = AssistiveTouchMenuAction.allCases
        #expect(actions.count == 3)
        #expect(actions.contains(.show))
        #expect(actions.contains(.hide))
        #expect(actions.contains(.toggle))
    }
    
    @Test func testAssistiveTouchMenuResult() {
        let successResult = AssistiveTouchMenuResult(
            success: true,
            menuElement: "Test Menu"
        )
        
        #expect(successResult.success)
        #expect(successResult.menuElement as? String == "Test Menu")
        #expect(successResult.error == nil)
        
        let failureResult = AssistiveTouchMenuResult(
            success: false,
            error: "Test Error"
        )
        
        #expect(!failureResult.success)
        #expect(failureResult.menuElement == nil)
        #expect(failureResult.error == "Test Error")
    }
    
    @Test func testAssistiveTouchGestureResult() {
        let successResult = AssistiveTouchGestureResult(
            success: true,
            action: "Test Action"
        )
        
        #expect(successResult.success)
        #expect(successResult.action == "Test Action")
        #expect(successResult.error == nil)
        
        let failureResult = AssistiveTouchGestureResult(
            success: false,
            error: "Test Error"
        )
        
        #expect(!failureResult.success)
        #expect(failureResult.action == nil)
        #expect(failureResult.error == "Test Error")
    }
    
    @Test func testAssistiveTouchCompliance() {
        let compliant = AssistiveTouchCompliance(
            isCompliant: true,
            issues: [],
            score: 100.0
        )
        
        #expect(compliant.isCompliant)
        #expect(compliant.issues.isEmpty)
        #expect(compliant.score == 100.0)
        
        let nonCompliant = AssistiveTouchCompliance(
            isCompliant: false,
            issues: ["Issue 1", "Issue 2"],
            score: 50.0
        )
        
        #expect(!nonCompliant.isCompliant)
        #expect(nonCompliant.issues.count == 2)
        #expect(nonCompliant.score == 50.0)
    }
    
    // MARK: - Eye Tracking Types Tests
    
    @Test func testEyeTrackingCalibrationLevel() {
        let levels = EyeTrackingCalibrationLevel.allCases
        #expect(levels.count == 4)
        #expect(levels.contains(.basic))
        #expect(levels.contains(.standard))
        #expect(levels.contains(.advanced))
        #expect(levels.contains(.expert))
    }
    
    @Test func testEyeTrackingInteractionType() {
        let types = EyeTrackingInteractionType.allCases
        #expect(types.count == 5)
        #expect(types.contains(.gaze))
        #expect(types.contains(.dwell))
        #expect(types.contains(.blink))
        #expect(types.contains(.wink))
        #expect(types.contains(.custom))
    }
    
    @Test func testEyeTrackingFocusManagement() {
        let management = EyeTrackingFocusManagement.allCases
        #expect(management.count == 3)
        #expect(management.contains(.automatic))
        #expect(management.contains(.manual))
        #expect(management.contains(.hybrid))
    }
    
    @Test func testEyeTrackingConfiguration() {
        let config = EyeTrackingConfiguration()
        #expect(config.calibrationLevel == .standard)
        #expect(config.interactionType == .dwell)
        #expect(config.focusManagement == .automatic)
        #expect(config.dwellTime == 1.0)
        #expect(config.enableHapticFeedback)
        #expect(!config.enableAudioFeedback)
    }
    
    @Test func testEyeTrackingSensitivity() {
        let sensitivities = EyeTrackingSensitivity.allCases
        #expect(sensitivities.count == 4)
        #expect(sensitivities.contains(.low))
        #expect(sensitivities.contains(.medium))
        #expect(sensitivities.contains(.high))
        #expect(sensitivities.contains(.adaptive))
        
        #expect(EyeTrackingSensitivity.low.threshold == 0.8)
        #expect(EyeTrackingSensitivity.medium.threshold == 0.6)
        #expect(EyeTrackingSensitivity.high.threshold == 0.4)
        #expect(EyeTrackingSensitivity.adaptive.threshold == 0.6)
    }
    
    @Test func testEyeTrackingCalibration() {
        let calibration = EyeTrackingCalibration()
        #expect(!calibration.isCalibrated)
        #expect(calibration.accuracy == 0.0)
        #expect(calibration.lastCalibrationDate == nil)
        #expect(calibration.calibrationPoints.isEmpty)
        
        let calibrated = EyeTrackingCalibration(
            isCalibrated: true,
            accuracy: 0.85,
            lastCalibrationDate: Date(),
            calibrationPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)]
        )
        
        #expect(calibrated.isCalibrated)
        #expect(calibrated.accuracy == 0.85)
        #expect(calibrated.lastCalibrationDate != nil)
        #expect(calibrated.calibrationPoints.count == 2)
    }
    
    @Test func testEyeTrackingGazeEvent() {
        let position = CGPoint(x: 100, y: 200)
        let timestamp = Date()
        let event = EyeTrackingGazeEvent(
            position: position,
            timestamp: timestamp,
            confidence: 0.85,
            isStable: true
        )
        
        #expect(event.position == position)
        #expect(event.timestamp == timestamp)
        #expect(event.confidence == 0.85)
        #expect(event.isStable)
    }
    
    @Test func testEyeTrackingDwellEvent() {
        let targetView = AnyView(Text("Test"))
        let position = CGPoint(x: 100, y: 200)
        let duration: TimeInterval = 2.5
        let timestamp = Date()
        
        let event = EyeTrackingDwellEvent(
            targetView: targetView,
            position: position,
            duration: duration,
            timestamp: timestamp
        )
        
        #expect(event.position == position)
        #expect(event.duration == duration)
        #expect(event.timestamp == timestamp)
    }
    
    @Test func testEyeTrackingConfig() {
        let config = EyeTrackingConfig()
        #expect(config.sensitivity == .medium)
        #expect(config.dwellTime == 1.0)
        #expect(config.visualFeedback)
        #expect(config.hapticFeedback)
        #expect(!config.calibration.isCalibrated)
    }
    
    // MARK: - Voice Control Types Tests
    
    @Test func testVoiceControlCommandType() {
        let types = VoiceControlCommandType.allCases
        #expect(types.count == 8)
        #expect(types.contains(.tap))
        #expect(types.contains(.swipe))
        #expect(types.contains(.scroll))
        #expect(types.contains(.zoom))
        #expect(types.contains(.select))
        #expect(types.contains(.edit))
        #expect(types.contains(.delete))
        #expect(types.contains(.custom))
    }
    
    @Test func testVoiceControlFeedbackType() {
        let types = VoiceControlFeedbackType.allCases
        #expect(types.count == 4)
        #expect(types.contains(.audio))
        #expect(types.contains(.haptic))
        #expect(types.contains(.visual))
        #expect(types.contains(.combined))
    }
    
    @Test func testVoiceControlCustomCommand() {
        var commandExecuted = false
        let command = VoiceControlCustomCommand(
            phrase: "Test command",
            type: .tap
        ) {
            commandExecuted = true
        }
        
        #expect(command.phrase == "Test command")
        #expect(command.type == .tap)
        command.handler()
        #expect(commandExecuted)
    }
    
    @Test func testVoiceControlConfiguration() {
        let config = VoiceControlConfiguration()
        #expect(config.enableCustomCommands)
        #expect(config.feedbackType == .combined)
        #expect(config.enableAudioFeedback)
        #expect(config.enableHapticFeedback)
        #expect(config.enableVisualFeedback)
        #expect(config.commandTimeout == 5.0)
    }
    
    @Test func testVoiceControlCommandResult() {
        let successResult = VoiceControlCommandResult(
            success: true,
            action: "Test Action",
            feedback: "Test Feedback"
        )
        
        #expect(successResult.success)
        #expect(successResult.action == "Test Action")
        #expect(successResult.feedback == "Test Feedback")
        #expect(successResult.error == nil)
        
        let failureResult = VoiceControlCommandResult(
            success: false,
            error: "Test Error"
        )
        
        #expect(!failureResult.success)
        #expect(failureResult.action == nil)
        #expect(failureResult.feedback == nil)
        #expect(failureResult.error == "Test Error")
    }
    
    @Test func testVoiceControlNavigationType() {
        let types = VoiceControlNavigationType.allCases
        #expect(types.count == 9)
        #expect(types.contains(.tap))
        #expect(types.contains(.swipe))
        #expect(types.contains(.scroll))
        #expect(types.contains(.zoom))
        #expect(types.contains(.select))
        #expect(types.contains(.navigate))
        #expect(types.contains(.back))
        #expect(types.contains(.home))
        #expect(types.contains(.menu))
    }
    
    @Test func testVoiceControlGestureType() {
        let types = VoiceControlGestureType.allCases
        #expect(types.count == 10)
        #expect(types.contains(.tap))
        #expect(types.contains(.doubleTap))
        #expect(types.contains(.longPress))
        #expect(types.contains(.swipeLeft))
        #expect(types.contains(.swipeRight))
        #expect(types.contains(.swipeUp))
        #expect(types.contains(.swipeDown))
        #expect(types.contains(.pinch))
        #expect(types.contains(.rotate))
        #expect(types.contains(.scroll))
    }
    
    @Test func testVoiceControlCommandRecognition() {
        let recognition = VoiceControlCommandRecognition(
            phrase: "Test phrase",
            confidence: 0.85,
            recognizedCommand: .tap
        )
        
        #expect(recognition.phrase == "Test phrase")
        #expect(recognition.confidence == 0.85)
        #expect(recognition.recognizedCommand == .tap)
        // timestamp is non-optional, so it exists if we reach here
        let _ = recognition.timestamp
    }
    
    @Test func testVoiceControlCompliance() {
        let compliant = VoiceControlCompliance(
            isCompliant: true,
            issues: [],
            score: 100.0
        )
        
        #expect(compliant.isCompliant)
        #expect(compliant.issues.isEmpty)
        #expect(compliant.score == 100.0)
        
        let nonCompliant = VoiceControlCompliance(
            isCompliant: false,
            issues: ["Issue 1", "Issue 2"],
            score: 50.0
        )
        
        #expect(!nonCompliant.isCompliant)
        #expect(nonCompliant.issues.count == 2)
        #expect(nonCompliant.score == 50.0)
    }
    
    // MARK: - Material Accessibility Types Tests
    
    @Test func testMaterialContrastLevel() {
        let levels = MaterialContrastLevel.allCases
        #expect(levels.count == 4)
        #expect(levels.contains(.low))
        #expect(levels.contains(.medium))
        #expect(levels.contains(.high))
        #expect(levels.contains(.maximum))
    }
    
    
    @Test func testMaterialAccessibilityConfiguration() {
        let config = MaterialAccessibilityConfiguration()
        #expect(config.contrastLevel == .medium)
        #expect(config.enableHighContrastAlternatives)
        #expect(config.enableVoiceOverDescriptions)
        #expect(config.enableSwitchControlSupport)
        #expect(config.enableAssistiveTouchSupport)
    }
    
    
    
    
    
    
    
    
    
    // MARK: - Basic Accessibility Types Tests
    
    @Test func testComplianceLevel() {
        let levels = ComplianceLevel.allCases
        #expect(levels.count == 4)
        #expect(levels.contains(.basic))
        #expect(levels.contains(.intermediate))
        #expect(levels.contains(.advanced))
        #expect(levels.contains(.expert))
        
        #expect(ComplianceLevel.basic.rawValue == 1)
        #expect(ComplianceLevel.intermediate.rawValue == 2)
        #expect(ComplianceLevel.advanced.rawValue == 3)
        #expect(ComplianceLevel.expert.rawValue == 4)
    }
    
    @Test func testIssueSeverity() {
        let severities = IssueSeverity.allCases
        #expect(severities.count == 4)
        #expect(severities.contains(.low))
        #expect(severities.contains(.medium))
        #expect(severities.contains(.high))
        #expect(severities.contains(.critical))
    }
    
    @Test func testAccessibilitySettings() {
        let settings = SixLayerFramework.AccessibilitySettings()
        #expect(settings.voiceOverSupport)
        #expect(settings.keyboardNavigation)
        #expect(settings.highContrastMode)
        #expect(settings.dynamicType)
        #expect(settings.reducedMotion)
        #expect(settings.hapticFeedback)
    }
    
    @Test func testAccessibilityComplianceMetrics() {
        let metrics = AccessibilityComplianceMetrics()
        #expect(metrics.voiceOverCompliance == .basic)
        #expect(metrics.keyboardCompliance == .basic)
        #expect(metrics.contrastCompliance == .basic)
        #expect(metrics.motionCompliance == .basic)
        #expect(metrics.overallComplianceScore == 0.0)
    }
    
    @Test func testAccessibilityAuditResult() {
        let metrics = AccessibilityComplianceMetrics()
        let result = AccessibilityAuditResult(
            complianceLevel: .basic,
            issues: [],
            recommendations: ["Recommendation 1"],
            score: 75.0,
            complianceMetrics: metrics
        )
        
        #expect(result.complianceLevel == .basic)
        #expect(result.issues.isEmpty)
        #expect(result.recommendations.count == 1)
        #expect(result.score == 75.0)
        #expect(result.complianceMetrics.voiceOverCompliance == .basic)
    }
    
    @Test func testAccessibilityIssue() {
        let issue = AccessibilityIssue(
            severity: .high,
            description: "Test issue",
            element: "Test element",
            suggestion: "Test suggestion"
        )
        
        #expect(issue.severity == .high)
        #expect(issue.description == "Test issue")
        #expect(issue.element == "Test element")
        #expect(issue.suggestion == "Test suggestion")
    }
}
