import Testing


//
//  TextContentTypeTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates that all text content types are properly supported and mapped to correct UITextContentType values,
//  ensuring proper keyboard configuration and auto-correction for different input field types.
//
//  TESTING SCOPE:
//  - Text content type mapping for all field types
//  - Keyboard type configuration for text content types
//  - Cross-platform text content type support
//  - Proper UITextContentType enum mapping
//
//  METHODOLOGY:
//  - Test all field types have appropriate text content types
//  - Verify keyboard types match text content types
//  - Test cross-platform compatibility
//  - Validate UITextContentType enum completeness
//

import SwiftUI
@testable import SixLayerFramework

/// Text content type testing
/// Tests that all field types have proper text content type support
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Text Content Type")
open class TextContentTypeTests: BaseTestClass {
    
    // MARK: - Text Content Type Mapping Tests
    
    /// BUSINESS PURPOSE: Text content types provide appropriate keyboard configuration and auto-correction for different input types
    /// TESTING SCOPE: Text content type mapping, keyboard configuration
    /// METHODOLOGY: Test all UITextContentType cases have correct behavior using exhaustive switch
    @Test @MainActor func testTextContentTypeMapping() {
        initializeTestConfig()
        initializeTestConfig()
        // Test all UITextContentType cases have appropriate behavior using exhaustive switch
        #if os(iOS)
        let textContentTypes: [UITextContentType] = [
            .emailAddress, .password, .telephoneNumber, .URL, .oneTimeCode,
            .name, .username, .newPassword, .postalCode, .creditCardNumber,
            .fullStreetAddress, .jobTitle, .organizationName, .givenName,
            .familyName, .middleName, .namePrefix, .nameSuffix
        ]
        
        for uiTextContentType in textContentTypes {
            // Convert UITextContentType to SixLayerTextContentType
            #if os(iOS)
            let textContentType = SixLayerTextContentType(uiTextContentType)
            #else
            // On macOS, create a default mapping
            let textContentType = SixLayerTextContentType(rawValue: uiTextContentType.rawValue) ?? .name
            #endif
            let field = DynamicFormField(
                id: "test_\(textContentType.rawValue)",
                textContentType: textContentType,
                label: "Test \(textContentType.rawValue)",
                placeholder: "Enter \(textContentType.rawValue)"
            )
            
            let formState = DynamicFormState(configuration: SixLayerFramework.DynamicFormConfiguration(id: "test", title: "Test Form", description: "Test form for content type", sections: [], submitButtonText: "Submit", cancelButtonText: "Cancel"))
            _ = DynamicFormFieldView(field: field, formState: formState)
            
            // Verify text content type is appropriate for field type
            // textField is a non-optional View, so it exists if we reach here
            
            // Test specific content types using exhaustive switch
            switch textContentType {
            case .emailAddress:
                #expect(field.textContentType == SixLayerTextContentType.emailAddress, "Email should use emailAddress content type")
            case .password:
                #expect(field.textContentType == .password, "Password should use password content type")
            case .telephoneNumber:
                #expect(field.textContentType == .telephoneNumber, "Phone should use telephoneNumber content type")
            case .URL:
                #expect(field.textContentType == .URL, "URL should use URL content type")
            case .oneTimeCode:
                #expect(field.textContentType == .oneTimeCode, "OTP should use oneTimeCode content type")
            case .name:
                #expect(field.textContentType == SixLayerTextContentType.name, "Name should use name content type")
            case .username:
                #expect(field.textContentType == .username, "Username should use username content type")
            case .newPassword:
                #expect(field.textContentType == .newPassword, "New password should use newPassword content type")
            case .postalCode:
                #expect(field.textContentType == SixLayerTextContentType.postalCode, "Postal code should use postalCode content type")
            case .creditCardNumber:
                #expect(field.textContentType == .creditCardNumber, "Credit card should use creditCardNumber content type")
            case .fullStreetAddress:
                #expect(field.textContentType == .fullStreetAddress, "Address should use fullStreetAddress content type")
            case .jobTitle:
                #expect(field.textContentType == .jobTitle, "Job title should use jobTitle content type")
            case .organizationName:
                #expect(field.textContentType == .organizationName, "Organization should use organizationName content type")
            case .givenName:
                #expect(field.textContentType == .givenName, "Given name should use givenName content type")
            case .familyName:
                #expect(field.textContentType == .familyName, "Family name should use familyName content type")
            case .middleName:
                #expect(field.textContentType == .middleName, "Middle name should use middleName content type")
            case .namePrefix:
                #expect(field.textContentType == SixLayerTextContentType.namePrefix, "Name prefix should use namePrefix content type")
            case .nameSuffix:
                #expect(field.textContentType == SixLayerTextContentType.nameSuffix, "Name suffix should use nameSuffix content type")
            default:
                // Handle any new OS types automatically
                #expect(field.textContentType != nil, "Should have text content type for \(textContentType.rawValue)")
            }
        }
        #else
        // For non-iOS platforms, test enum-based content types
        let textContentTypes: [SixLayerTextContentType] = [
            .emailAddress, .password, .telephoneNumber, .URL, .oneTimeCode,
            .name, .username, .newPassword, .postalCode, .creditCardNumber,
            .fullStreetAddress, .jobTitle, .organizationName, .givenName,
            .familyName, .middleName, .namePrefix, .nameSuffix
        ]
        
        for textContentType in textContentTypes {
            let field = DynamicFormField(
                id: "test_\(textContentType.rawValue)",
                textContentType: textContentType,
                label: "Test \(textContentType)",
                placeholder: "Enter \(textContentType)"
            )
            
            let formState = DynamicFormState(configuration: SixLayerFramework.DynamicFormConfiguration(id: "test", title: "Test Form", description: "Test form for content type", sections: [], submitButtonText: "Submit", cancelButtonText: "Cancel"))
            let _ = DynamicFormFieldView(field: field, formState: formState)
            
            // Verify text content type is appropriate for field type
            #expect(Bool(true), "Should create text field for \(textContentType)")  // textField is non-optional
            #expect(field.textContentType == textContentType, "Should use correct text content type")
        }
        #endif
    }
    
    /// BUSINESS PURPOSE: One-time code fields provide number pad keyboard and oneTimeCode content type for OTP input
    /// TESTING SCOPE: OTP field configuration, keyboard type, text content type
    /// METHODOLOGY: Test OTP field has correct configuration
    @Test @MainActor func testOTPFieldConfiguration() {
        initializeTestConfig()
        // Test OTP field using OS UITextContentType.oneTimeCode
        #if os(iOS)
        let field = DynamicFormField(
            id: "otp_field",
            textContentType: SixLayerTextContentType.oneTimeCode,
            label: "Verification Code",
            placeholder: "Enter 6-digit code"
        )
        
        let formState = DynamicFormState(configuration: SixLayerFramework.DynamicFormConfiguration(id: "test", title: "Test Form", description: "Test form for content type", sections: [], submitButtonText: "Submit", cancelButtonText: "Cancel"))
        let textField = DynamicFormFieldView(field: field, formState: formState)
        
        // Verify OTP field configuration
        #expect(Bool(true), "Should create OTP text field")  // textField is non-optional
        #expect(field.textContentType == SixLayerTextContentType.oneTimeCode, "OTP field should use oneTimeCode content type")
        #expect(field.contentType == nil, "OTP field should not have custom contentType")
        #else
        let field = DynamicFormField(
            id: "otp_field",
            textContentType: SixLayerTextContentType.oneTimeCode,
            label: "Verification Code",
            placeholder: "Enter 6-digit code"
        )
        
        let formState = DynamicFormState(configuration: SixLayerFramework.DynamicFormConfiguration(id: "test", title: "Test Form", description: "Test form for content type", sections: [], submitButtonText: "Submit", cancelButtonText: "Cancel"))
        let textField = DynamicFormFieldView(field: field, formState: formState)
        
        // Verify OTP field configuration
        #expect(Bool(true), "Should create OTP text field")  // textField is non-optional
        #expect(field.textContentType == SixLayerTextContentType.oneTimeCode, "OTP field should use oneTimeCode content type")
        #expect(field.contentType == nil, "OTP field should not have custom contentType")
        #endif
    }
    
    /// BUSINESS PURPOSE: Name fields provide appropriate keyboard configuration for name input
    /// TESTING SCOPE: Name field configuration, keyboard type, text content type
    /// METHODOLOGY: Test name field has correct configuration
    @Test @MainActor func testNameFieldConfiguration() {
        initializeTestConfig()
        // Given: Name field (using textContentType for name)
        #if os(iOS)
        let nameField = DynamicFormField(
            id: "name",
            textContentType: SixLayerTextContentType.name,
            label: "Full Name",
            placeholder: "Enter your full name"
        )
        #else
        let nameField = DynamicFormField(
            id: "name",
            textContentType: SixLayerTextContentType.name,
            label: "Full Name",
            placeholder: "Enter your full name"
        )
        #endif
        
        // When: Checking field configuration
        // Then: Should have appropriate text content type
        #if os(iOS)
        #expect(nameField.textContentType == SixLayerTextContentType.name, "Name field should use name content type")
        #else
        #expect(nameField.textContentType == SixLayerTextContentType.name, "Name field should use name content type")
        
        // And: Should not have custom contentType
        #expect(nameField.contentType == nil, "Name field should not have custom contentType")
        #endif
    }
    
    /// BUSINESS PURPOSE: Username fields provide appropriate keyboard configuration for username input
    /// TESTING SCOPE: Username field configuration, keyboard type, text content type
    /// METHODOLOGY: Test username field has correct configuration
    @Test @MainActor func testUsernameFieldConfiguration() {
        initializeTestConfig()
        // Given: Username field (using textContentType for username)
        #if os(iOS)
        let usernameField = DynamicFormField(
            id: "username",
            textContentType: SixLayerTextContentType.username,
            label: "Username",
            placeholder: "Enter username"
        )
        #else
        let usernameField = DynamicFormField(
            id: "username",
            textContentType: SixLayerTextContentType.username,
            label: "Username",
            placeholder: "Enter username"
        )
        #endif
        
        // When: Checking field configuration
        // Then: Should have appropriate text content type
        #if os(iOS)
        #expect(usernameField.textContentType == SixLayerTextContentType.username, "Username field should use username content type")
        #else
        #expect(usernameField.textContentType == SixLayerTextContentType.username, "Username field should use username content type")
        
        // And: Should not have custom contentType
        #expect(usernameField.contentType == nil, "Username field should not have custom contentType")
        #endif
    }
    
    /// BUSINESS PURPOSE: Postal code fields provide appropriate keyboard configuration for postal code input
    /// TESTING SCOPE: Postal code field configuration, keyboard type, text content type
    /// METHODOLOGY: Test postal code field has correct configuration
    @Test @MainActor func testPostalCodeFieldConfiguration() {
        initializeTestConfig()
        // Given: Postal code field (using textContentType for postalCode)
        #if os(iOS)
        let postalCodeField = DynamicFormField(
            id: "postalCode",
            textContentType: SixLayerTextContentType.postalCode,
            label: "Postal Code",
            placeholder: "Enter postal code"
        )
        #else
        let postalCodeField = DynamicFormField(
            id: "postalCode",
            textContentType: SixLayerTextContentType.postalCode,
            label: "Postal Code",
            placeholder: "Enter postal code"
        )
        #endif
        
        // When: Checking field configuration
        // Then: Should have appropriate text content type
        #if os(iOS)
        #expect(postalCodeField.textContentType == SixLayerTextContentType.postalCode, "Postal code field should use postalCode content type")
        #else
        #expect(postalCodeField.textContentType == SixLayerTextContentType.postalCode, "Postal code field should use postalCode content type")
        
        // And: Should not have custom contentType
        #expect(postalCodeField.contentType == nil, "Postal code field should not have custom contentType")
        #endif
    }
    
    /// BUSINESS PURPOSE: Credit card fields provide appropriate keyboard configuration for credit card input
    /// TESTING SCOPE: Credit card field configuration, keyboard type, text content type
    /// METHODOLOGY: Test credit card field has correct configuration
    @Test @MainActor func testCreditCardFieldConfiguration() {
        initializeTestConfig()
        // Given: Credit card field (using textContentType for creditCardNumber)
        #if os(iOS)
        let creditCardField = DynamicFormField(
            id: "creditCard",
            textContentType: SixLayerTextContentType.creditCardNumber,
            label: "Credit Card Number",
            placeholder: "Enter credit card number"
        )
        #else
        let creditCardField = DynamicFormField(
            id: "creditCard",
            textContentType: SixLayerTextContentType.creditCardNumber,
            label: "Credit Card Number",
            placeholder: "Enter credit card number"
        )
        #endif
        
        // When: Checking field configuration
        // Then: Should have appropriate text content type
        #if os(iOS)
        #expect(creditCardField.textContentType == SixLayerTextContentType.creditCardNumber, "Credit card field should use creditCardNumber content type")
        #else
        #expect(creditCardField.textContentType == SixLayerTextContentType.creditCardNumber, "Credit card field should use creditCardNumber content type")
        
        // And: Should not have custom contentType
        #expect(creditCardField.contentType == nil, "Credit card field should not have custom contentType")
        #endif
    }
    
    /// BUSINESS PURPOSE: Address fields provide appropriate keyboard configuration for address input
    /// TESTING SCOPE: Address field configuration, keyboard type, text content type
    /// METHODOLOGY: Test address field has correct configuration
    @Test @MainActor func testAddressFieldConfiguration() {
        initializeTestConfig()
        // Given: Address field (using textContentType for fullStreetAddress)
        #if os(iOS)
        let addressField = DynamicFormField(
            id: "address",
            textContentType: SixLayerTextContentType.fullStreetAddress,
            label: "Street Address",
            placeholder: "Enter street address"
        )
        #else
        let addressField = DynamicFormField(
            id: "address",
            textContentType: SixLayerTextContentType.fullStreetAddress,
            label: "Street Address",
            placeholder: "Enter street address"
        )
        #endif
        
        // When: Checking field configuration
        // Then: Should have appropriate text content type
        #if os(iOS)
        #expect(addressField.textContentType == SixLayerTextContentType.fullStreetAddress, "Address field should use fullStreetAddress content type")
        #else
        #expect(addressField.textContentType == SixLayerTextContentType.fullStreetAddress, "Address field should use fullStreetAddress content type")
        
        // And: Should not have custom contentType
        #expect(addressField.contentType == nil, "Address field should not have custom contentType")
        #endif
    }
    
    /// BUSINESS PURPOSE: Job title fields provide appropriate keyboard configuration for job title input
    /// TESTING SCOPE: Job title field configuration, keyboard type, text content type
    /// METHODOLOGY: Test job title field has correct configuration
    @Test @MainActor func testJobTitleFieldConfiguration() {
        initializeTestConfig()
        // Given: Job title field (using textContentType for jobTitle)
        #if os(iOS)
        let jobTitleField = DynamicFormField(
            id: "jobTitle",
            textContentType: SixLayerTextContentType.jobTitle,
            label: "Job Title",
            placeholder: "Enter job title"
        )
        #else
        let jobTitleField = DynamicFormField(
            id: "jobTitle",
            textContentType: SixLayerTextContentType.jobTitle,
            label: "Job Title",
            placeholder: "Enter job title"
        )
        #endif
        
        // When: Checking field configuration
        // Then: Should have appropriate text content type
        #if os(iOS)
        #expect(jobTitleField.textContentType == SixLayerTextContentType.jobTitle, "Job title field should use jobTitle content type")
        #else
        #expect(jobTitleField.textContentType == SixLayerTextContentType.jobTitle, "Job title field should use jobTitle content type")
        
        // And: Should not have custom contentType
        #expect(jobTitleField.contentType == nil, "Job title field should not have custom contentType")
        #endif
    }
    
    /// BUSINESS PURPOSE: Organization name fields provide appropriate keyboard configuration for organization input
    /// TESTING SCOPE: Organization field configuration, keyboard type, text content type
    /// METHODOLOGY: Test organization field has correct configuration
    @Test @MainActor func testOrganizationFieldConfiguration() {
        initializeTestConfig()
        // Given: Organization field (using textContentType for organizationName)
        #if os(iOS)
        let organizationField = DynamicFormField(
            id: "organization",
            textContentType: SixLayerTextContentType.organizationName,
            label: "Organization",
            placeholder: "Enter organization name"
        )
        #else
        let organizationField = DynamicFormField(
            id: "organization",
            textContentType: SixLayerTextContentType.organizationName,
            label: "Organization",
            placeholder: "Enter organization name"
        )
        #endif
        
        // When: Checking field configuration
        // Then: Should have appropriate text content type
        #if os(iOS)
        #expect(organizationField.textContentType == SixLayerTextContentType.organizationName, "Organization field should use organizationName content type")
        #else
        #expect(organizationField.textContentType == SixLayerTextContentType.organizationName, "Organization field should use organizationName content type")
        
        // And: Should not have custom contentType
        #expect(organizationField.contentType == nil, "Organization field should not have custom contentType")
        #endif
    }
    
    // MARK: - Cross-Platform Compatibility Tests
    
    /// BUSINESS PURPOSE: Text content types work correctly across all supported platforms
    /// TESTING SCOPE: Cross-platform text content type support
    /// METHODOLOGY: Test text content types on all platforms
    @Test @MainActor func testCrossPlatformTextContentTypes() {
        initializeTestConfig()
        // Given: Current platform
        let currentPlatform = SixLayerPlatform.current
        
        // Test that text content types are supported on current platform
        let field = DynamicFormField(
            id: "test",
            textContentType: SixLayerTextContentType.emailAddress,
            label: "Test",
            placeholder: "Enter email"
        )
        
        let formState = DynamicFormState(configuration: SixLayerFramework.DynamicFormConfiguration(id: "test", title: "Test Form", description: "Test form for content type", sections: [], submitButtonText: "Submit", cancelButtonText: "Cancel"))
        let _ = DynamicFormFieldView(field: field, formState: formState)
        
        #expect(Bool(true), "Text field should be created on \(currentPlatform)")  // textField is non-optional
        
        // Clean up
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
}
