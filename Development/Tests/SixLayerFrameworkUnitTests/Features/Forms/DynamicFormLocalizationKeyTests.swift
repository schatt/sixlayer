import Testing
import SwiftUI
@testable import SixLayerFramework

//
//  DynamicFormLocalizationKeyTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates DynamicFormField localization key resolution so that
//  accessibility identifiers can be safely used as the default
//  base for localization keys, with an explicit override when needed.
//
//  TESTING SCOPE:
//  - Base key resolution priority (override > accessibilityId > id)
//  - Namespace prefixing
//  - Role-specific key construction (label, placeholder, accessibilityLabel)
//  - Fallback behavior when resolver returns the key unchanged
//

@Suite("Dynamic Form Localization Keys")
@MainActor
open class DynamicFormLocalizationKeyTests: BaseTestClass {
    
    // MARK: - Helpers
    
    /// Simple resolver that echoes the key so we can assert on it explicitly.
    private func echoResolver(_ key: String) -> String { key }
    
    // MARK: - Base Key Resolution
    
    @Test
    func testLocalizationBaseKey_PrefersOverrideOverAccessibilityIdAndId() {
        // Given
        let field = DynamicFormField(
            id: "fieldId",
            contentType: .text,
            label: "Label"
        )
        
        // When
        let base = field.localizationBaseKey(
            namespace: nil,
            localizationKeyBaseOverride: "override.base",
            accessibilityId: "accessibility.id"
        )
        
        // Then
        #expect(base == "override.base")
    }
    
    @Test
    func testLocalizationBaseKey_UsesAccessibilityIdWhenNoOverride() {
        // Given
        let field = DynamicFormField(
            id: "fieldId",
            contentType: .text,
            label: "Label"
        )
        
        // When
        let base = field.localizationBaseKey(
            namespace: nil,
            localizationKeyBaseOverride: nil,
            accessibilityId: "accessibility.id"
        )
        
        // Then
        #expect(base == "accessibility.id")
    }
    
    @Test
    func testLocalizationBaseKey_FallsBackToFieldIdWhenNoOverrideOrAccessibilityId() {
        // Given
        let field = DynamicFormField(
            id: "fieldId",
            contentType: .text,
            label: "Label"
        )
        
        // When
        let base = field.localizationBaseKey(
            namespace: nil,
            localizationKeyBaseOverride: nil,
            accessibilityId: nil
        )
        
        // Then
        #expect(base == "fieldId")
    }
    
    @Test
    func testLocalizationBaseKey_AppliesNamespacePrefixWhenProvided() {
        // Given
        let field = DynamicFormField(
            id: "fieldId",
            contentType: .text,
            label: "Label"
        )
        
        // When
        let base = field.localizationBaseKey(
            namespace: "MyScreen",
            localizationKeyBaseOverride: nil,
            accessibilityId: "accessibility.id"
        )
        
        // Then
        #expect(base == "MyScreen.accessibility.id")
    }
    
    // MARK: - Role-specific Keys
    
    @Test
    func testLocalizationKey_BuildsRoleSpecificKeyFromBase() {
        // Given
        let field = DynamicFormField(
            id: "email",
            contentType: .email,
            label: "Email"
        )
        
        // When
        let labelKey = field.localizationKey(
            role: .label,
            namespace: "SignUp",
            localizationKeyBaseOverride: nil,
            accessibilityId: "emailField"
        )
        
        let placeholderKey = field.localizationKey(
            role: .placeholder,
            namespace: "SignUp",
            localizationKeyBaseOverride: nil,
            accessibilityId: "emailField"
        )
        
        // Then
        #expect(labelKey == "SignUp.emailField.label")
        #expect(placeholderKey == "SignUp.emailField.placeholder")
    }
    
    // MARK: - Resolver & Fallback Behavior
    
    @Test
    func testResolveLocalizedString_UsesResolverValueWhenDifferentFromKey() {
        // Given
        let field = DynamicFormField(
            id: "username",
            contentType: .text,
            label: "Username"
        )
        
        var resolvedKey: String?
        let resolver: (String) -> String = { key in
            resolvedKey = key
            return "Translated \(key)"
        }
        
        // When
        let result = field.resolveLocalizedString(
            role: .label,
            resolver: resolver,
            namespace: "Profile",
            localizationKeyBaseOverride: nil,
            accessibilityId: "usernameField",
            fallback: "Username"
        )
        
        // Then
        #expect(resolvedKey == "Profile.usernameField.label")
        #expect(result == "Translated Profile.usernameField.label")
    }
    
    @Test
    func testResolveLocalizedString_FallsBackWhenResolverEchoesKey() {
        // Given
        let field = DynamicFormField(
            id: "username",
            contentType: .text,
            label: "Username"
        )
        
        // When: resolver returns key unchanged
        let result = field.resolveLocalizedString(
            role: .label,
            resolver: echoResolver,
            namespace: "Profile",
            localizationKeyBaseOverride: nil,
            accessibilityId: "usernameField",
            fallback: "Username"
        )
        
        // Then
        #expect(result == "Username")
    }
}

