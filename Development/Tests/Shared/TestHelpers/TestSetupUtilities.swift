//
//  TestSetupUtilities.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Test setup utilities for configuring platform capabilities and creating test data
//

import Foundation
import SwiftUI
@testable import SixLayerFramework

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Test setup utilities for configuring test environments
public enum TestSetupUtilities {
    
    // MARK: - Platform Capability Configuration
    
    /// Set capabilities for a specific platform for testing
    /// This configures RuntimeCapabilityDetection test overrides based on platform
    public static func setCapabilitiesForPlatform(_ platform: SixLayerPlatform) {
        // Clear all existing overrides first
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        
        // Set capabilities based on platform
        switch platform {
        case .iOS:
            RuntimeCapabilityDetection.setTestTouchSupport(true)
            RuntimeCapabilityDetection.setTestHover(false) // iOS hover is device-dependent, default to false
            RuntimeCapabilityDetection.setTestHapticFeedback(true)
            RuntimeCapabilityDetection.setTestAssistiveTouch(false) // Can be enabled per test
            RuntimeCapabilityDetection.setTestVoiceOver(false) // Can be enabled per test
            RuntimeCapabilityDetection.setTestSwitchControl(false) // Can be enabled per test
        case .macOS:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestHover(true)
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestAssistiveTouch(false)
            RuntimeCapabilityDetection.setTestVoiceOver(false) // Can be enabled per test
            RuntimeCapabilityDetection.setTestSwitchControl(false) // Can be enabled per test
        case .watchOS:
            RuntimeCapabilityDetection.setTestTouchSupport(true)
            RuntimeCapabilityDetection.setTestHover(false)
            RuntimeCapabilityDetection.setTestHapticFeedback(true)
            RuntimeCapabilityDetection.setTestAssistiveTouch(false)
            RuntimeCapabilityDetection.setTestVoiceOver(false) // Can be enabled per test
            RuntimeCapabilityDetection.setTestSwitchControl(false) // Can be enabled per test
        case .tvOS:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestHover(false)
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestAssistiveTouch(false)
            RuntimeCapabilityDetection.setTestVoiceOver(false) // Can be enabled per test
            RuntimeCapabilityDetection.setTestSwitchControl(false) // Can be enabled per test
        case .visionOS:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestHover(true)
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestAssistiveTouch(false)
            RuntimeCapabilityDetection.setTestVoiceOver(false) // Can be enabled per test
            RuntimeCapabilityDetection.setTestSwitchControl(false) // Can be enabled per test
        }
    }
    
    // MARK: - Test Hints Creation
    
    /// Create test presentation hints with default values
    public static func createTestHints(
        dataType: DataTypeHint = .generic,
        presentationPreference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        context: PresentationContext = .dashboard
    ) -> PresentationHints {
        return PresentationHints(
            dataType: dataType,
            presentationPreference: presentationPreference,
            complexity: complexity,
            context: context
        )
    }
    
    // MARK: - View Hosting
    
    /// Host a SwiftUI view and return the platform root view for inspection
    @MainActor
    public static func hostRootPlatformView<V: View>(_ view: V) -> Any? {
        #if canImport(UIKit)
        let hostingController = UIHostingController(rootView: view)
        return hostingController.view
        #elseif canImport(AppKit)
        let hostingController = NSHostingController(rootView: view)
        return hostingController.view
        #else
        return nil
        #endif
    }
    
    // MARK: - Field Type Helpers
    
    /// Field type enum for test utilities
    public enum FieldType {
        case text
        case email
        case number
        case phone
        case date
        case url
        case textarea
        case select
        case multiselect
        case radio
        case checkbox
        case richtext
    }
    
    /// Convert FieldType to DynamicContentType
    public static func contentType(for fieldType: FieldType) -> DynamicContentType {
        switch fieldType {
        case .text:
            return .text
        case .email:
            return .email
        case .number:
            return .number
        case .phone:
            return .phone
        case .date:
            return .date
        case .url:
            return .url
        case .textarea:
            return .textarea
        case .select:
            return .select
        case .multiselect:
            return .multiselect
        case .radio:
            return .radio
        case .checkbox:
            return .checkbox
        case .richtext:
            return .richtext
        }
    }
    
    // MARK: - Test Field Creation
    
    /// Create a test form field with the specified parameters
    public static func createTestField(
        label: String,
        placeholder: String? = nil,
        value: String? = nil,
        isRequired: Bool = false,
        contentType: DynamicContentType,
        options: [String]? = nil
    ) -> DynamicFormField {
        let fieldId = label.lowercased().replacingOccurrences(of: " ", with: "_")
        return DynamicFormField(
            id: fieldId,
            contentType: contentType,
            label: label,
            placeholder: placeholder,
            isRequired: isRequired,
            options: options,
            defaultValue: value
        )
    }
    
    // MARK: - Test Environment Setup
    
    /// Setup test environment (placeholder - can be extended as needed)
    @MainActor
    public static func setupTestEnvironment() {
        // Clear any existing test overrides
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        // Additional setup can be added here as needed
    }
    
    /// Cleanup test environment (placeholder - can be extended as needed)
    @MainActor
    public static func cleanupTestEnvironment() {
        // Clear all test overrides
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        // Additional cleanup can be added here as needed
    }
}
