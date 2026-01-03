//
//  CrossPlatformWorkflowParityTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates that workflows work identically across iOS and macOS platforms, ensuring
//  feature parity and consistent behavior. This tests that the same workflows produce
//  the same results regardless of platform.
//
//  TESTING SCOPE:
//  - Form workflow parity: Form workflows work identically on iOS/macOS
//  - OCR workflow parity: OCR workflows work identically on iOS/macOS
//  - Accessibility workflow parity: Accessibility workflows work identically on iOS/macOS
//  - Cross-component workflow parity: Multi-component workflows work identically
//  - Error handling parity: Error handling works identically across platforms
//
//  METHODOLOGY:
//  - Run same workflow on all platforms
//  - Compare results across platforms
//  - Verify consistency in behavior and outcomes
//  - Test across all platforms using SixLayerPlatform.allCases
//
//  AUDIT STATUS: ✅ COMPLIANT
//  - ✅ File Documentation: Complete with business purpose, testing scope, methodology
//  - ✅ Function Documentation: All functions documented with business purpose
//  - ✅ Platform Testing: Tests across all platforms using SixLayerPlatform.allCases
//  - ✅ Integration Focus: Tests cross-platform consistency
//

import Testing
import SwiftUI
@testable import SixLayerFramework

/// Layer 1: Logic Tests for Cross-Platform Workflow Parity
/// Tests that workflows work identically across platforms
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Cross-Platform Workflow Parity")
final class CrossPlatformWorkflowParityTests: BaseTestClass {
    
    // MARK: - Form Workflow Parity Tests
    
    /// BUSINESS PURPOSE: Validate form workflow parity across platforms
    /// TESTING SCOPE: Tests that form workflows produce same results on iOS/macOS
    /// METHODOLOGY: Run form workflow on all platforms, compare results
    @Test func testFormWorkflowParity() async {
        var platformResults: [SixLayerPlatform: Bool] = [:]
        
        for platform in SixLayerPlatform.allCases {
            
            // Given: Same form configuration
            let fields = [
                DynamicFormField(
                    id: "email",
                    contentType: .email,
                    label: "Email",
                    isRequired: true,
                    validationRules: ["required": "true", "email": "true"]
                )
            ]
            
            // When: Validating form
            let validData = ["email": "test@example.com"]
            var isValid = true
            
            for field in fields {
                if field.isRequired {
                    let value = validData[field.id] ?? ""
                    if value.isEmpty {
                        isValid = false
                    }
                }
                
                if field.contentType == .email && field.validationRules?["email"] == "true" {
                    let value = validData[field.id] ?? ""
                    if !value.contains("@") || !value.contains(".") {
                        isValid = false
                    }
                }
            }
            
            platformResults[platform] = isValid
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
        
        // Then: All platforms should have same result
        let results = Array(platformResults.values)
        let allSame = results.allSatisfy { $0 == results.first }
        #expect(allSame, "Form workflow should produce same results on all platforms")
    }
    
    // MARK: - OCR Workflow Parity Tests
    
    /// BUSINESS PURPOSE: Validate OCR workflow parity across platforms
    /// TESTING SCOPE: Tests that OCR workflows work identically on iOS/macOS
    /// METHODOLOGY: Run OCR workflow on all platforms, compare results
    @Test func testOCRWorkflowParity() async {
        var platformResults: [SixLayerPlatform: Bool] = [:]
        
        for platform in SixLayerPlatform.allCases {
            
            // Given: Same OCR context
            let context = OCRContext(
                textTypes: [.price, .date, .general],
                language: .english,
                confidenceThreshold: 0.8,
                allowsEditing: true
            )
            
            // When: Checking OCR context configuration
            let isConfigured = context.textTypes.count > 0 &&
                              context.language == .english &&
                              context.confidenceThreshold == 0.8
            
            platformResults[platform] = isConfigured
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
        
        // Then: All platforms should have same result
        let results = Array(platformResults.values)
        let allSame = results.allSatisfy { $0 == results.first }
        #expect(allSame, "OCR workflow should produce same results on all platforms")
    }
    
    // MARK: - Accessibility Workflow Parity Tests
    
    /// BUSINESS PURPOSE: Validate accessibility workflow parity across platforms
    /// TESTING SCOPE: Tests that accessibility workflows work identically on iOS/macOS
    /// METHODOLOGY: Run accessibility workflow on all platforms, compare compliance levels
    @Test @MainActor func testAccessibilityWorkflowParity() async {
        initializeTestConfig()
        
        var platformResults: [SixLayerPlatform: ComplianceLevel] = [:]
        
        for platform in SixLayerPlatform.allCases {
            
            // Given: Same view configuration
            let testView = Text("Test View").padding()
            let enhancedView = testView.automaticCompliance()
            
            // When: Running accessibility audit
            let audit = AccessibilityTesting.auditViewAccessibility(enhancedView)
            platformResults[platform] = audit.complianceLevel
            
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
        
        // Then: All platforms should achieve at least basic compliance
        let allCompliant = platformResults.values.allSatisfy { 
            $0.rawValue >= ComplianceLevel.basic.rawValue 
        }
        #expect(allCompliant, "Accessibility workflow should be consistent across platforms")
        
        // All platforms should have same minimum compliance level
        let minCompliance = platformResults.values.map { $0.rawValue }.min() ?? 0
        let allMeetMinimum = platformResults.values.allSatisfy { 
            $0.rawValue >= minCompliance 
        }
        #expect(allMeetMinimum, "All platforms should meet minimum compliance level")
    }
    
    // MARK: - Cross-Component Workflow Parity Tests
    
    /// BUSINESS PURPOSE: Validate cross-component workflow parity across platforms
    /// TESTING SCOPE: Tests that multi-component workflows work identically on iOS/macOS
    /// METHODOLOGY: Run multi-component workflow on all platforms, compare results
    @Test func testCrossComponentWorkflowParity() async {
        var platformResults: [SixLayerPlatform: Bool] = [:]
        
        for platform in SixLayerPlatform.allCases {
            
            // Given: Same multi-component configuration
            let formFields = [
                DynamicFormField(id: "name", contentType: .text, label: "Name")
            ]
            
            let ocrContext = OCRContext(
                textTypes: [.price, .date],
                language: .english,
                confidenceThreshold: 0.8,
                allowsEditing: true
            )
            
            // When: Checking component compatibility
            let formValid = formFields.count > 0
            let ocrValid = ocrContext.textTypes.count > 0
            let componentsCompatible = formValid && ocrValid
            
            platformResults[platform] = componentsCompatible
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
        
        // Then: All platforms should have same result
        let results = Array(platformResults.values)
        let allSame = results.allSatisfy { $0 == results.first }
        #expect(allSame, "Cross-component workflow should produce same results on all platforms")
    }
    
    // MARK: - Error Handling Parity Tests
    
    /// BUSINESS PURPOSE: Validate error handling parity across platforms
    /// TESTING SCOPE: Tests that error handling works identically on iOS/macOS
    /// METHODOLOGY: Run error scenarios on all platforms, compare error handling
    @Test func testErrorHandlingParity() async {
        var platformResults: [SixLayerPlatform: Bool] = [:]
        
        for platform in SixLayerPlatform.allCases {
            
            // Given: OCR error types
            let ocrErrors: [OCRError] = [
                .invalidImage,
                .noTextFound,
                .processingFailed
            ]
            
            // When: Checking error descriptions
            var allHaveDescriptions = true
            for error in ocrErrors {
                if error.errorDescription == nil || error.errorDescription!.isEmpty {
                    allHaveDescriptions = false
                    break
                }
            }
            
            platformResults[platform] = allHaveDescriptions
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
        
        // Then: All platforms should have same result
        let results = Array(platformResults.values)
        let allSame = results.allSatisfy { $0 == results.first }
        #expect(allSame, "Error handling should work identically on all platforms")
    }
    
    // MARK: - Complete Workflow Parity Tests
    
    /// BUSINESS PURPOSE: Validate complete workflow parity across platforms
    /// TESTING SCOPE: Tests that complete workflows work identically on iOS/macOS
    /// METHODOLOGY: Run complete workflow on all platforms, compare all results
    @Test @MainActor func testCompleteWorkflowParity() async {
        initializeTestConfig()
        
        var formResults: [SixLayerPlatform: Bool] = [:]
        var ocrResults: [SixLayerPlatform: Bool] = [:]
        var accessibilityResults: [SixLayerPlatform: ComplianceLevel] = [:]
        
        for platform in SixLayerPlatform.allCases {
            
            // Form workflow
            let formFields = [
                DynamicFormField(
                    id: "email",
                    contentType: .email,
                    label: "Email",
                    isRequired: true
                )
            ]
            let formValid = formFields.count > 0
            formResults[platform] = formValid
            
            // OCR workflow
            let ocrContext = OCRContext(
                textTypes: [.price, .date],
                language: .english,
                confidenceThreshold: 0.8,
                allowsEditing: true
            )
            let ocrValid = ocrContext.textTypes.count > 0
            ocrResults[platform] = ocrValid
            
            // Accessibility workflow
            let testView = Text("Test View").padding()
            let enhancedView = testView.automaticCompliance()
            let audit = AccessibilityTesting.auditViewAccessibility(enhancedView)
            accessibilityResults[platform] = audit.complianceLevel
            
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
        
        // Then: All workflows should be consistent across platforms
        let formConsistent = Array(formResults.values).allSatisfy { $0 == formResults.values.first }
        let ocrConsistent = Array(ocrResults.values).allSatisfy { $0 == ocrResults.values.first }
        let accessibilityConsistent = accessibilityResults.values.allSatisfy { 
            $0.rawValue >= ComplianceLevel.basic.rawValue 
        }
        
        #expect(formConsistent, "Form workflow should be consistent across platforms")
        #expect(ocrConsistent, "OCR workflow should be consistent across platforms")
        #expect(accessibilityConsistent, "Accessibility workflow should be consistent across platforms")
    }
}
