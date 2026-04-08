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
//  - Base key resolution (override > metadata > accessibility segment aligned with a11y ID > id)
//  - Namespace prefixing
//  - Role-specific key construction (label, placeholder, accessibilityLabel)
//  - Fallback behavior when resolver returns the key unchanged
//  - Issue #194: default base matches effective accessibility identifier segment
//

@Suite("Dynamic Form Localization Keys")
@MainActor
struct DynamicFormLocalizationKeyTests {
    
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
    func testLocalizationBaseKey_UsesSanitizedLabelSegmentWhenNoOverrideOrExplicitAccessibilityId() {
        // Given — Issue #194: default localization base matches accessibility identifier segment (sanitizeLabelText)
        let field = DynamicFormField(
            id: "fieldId",
            contentType: .text,
            label: "Email Address"
        )
        
        // When
        let base = field.localizationBaseKey(
            namespace: nil,
            localizationKeyBaseOverride: nil,
            accessibilityId: nil
        )
        
        // Then
        #expect(base == "email-address")
    }
    
    @Test
    func testLocalizationBaseKey_FallsBackToFieldIdWhenLabelSanitizesToEmpty() {
        // Given
        let field = DynamicFormField(
            id: "fieldId",
            contentType: .text,
            label: "@@@"
        )
        
        // When
        let base = field.localizationBaseKey(
            namespace: nil,
            localizationKeyBaseOverride: nil,
            accessibilityId: nil
        )
        
        // Then — segment empty after sanitize → use field id
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
    
    @Test
    func testLocalizationBaseKey_PrefersMetadataLocalizationKeyBaseOverSegment() {
        let field = DynamicFormField(
            id: "id1",
            contentType: .text,
            label: "Name",
            metadata: ["localizationKeyBase": "profile.fullName"]
        )
        let base = field.localizationBaseKey(
            namespace: nil,
            localizationKeyBaseOverride: nil,
            accessibilityId: nil
        )
        #expect(base == "profile.fullName")
    }
    
    @Test
    func testEffectiveAccessibilityIdentifierSegment_UsesMetadataOverride() {
        let field = DynamicFormField(
            id: "id1",
            contentType: .text,
            label: "Ignore Me",
            metadata: ["accessibilityIdentifierName": "user_email_field"]
        )
        #expect(field.effectiveAccessibilityIdentifierSegment == "user_email_field")
        let base = field.localizationBaseKey(
            namespace: "Form",
            localizationKeyBaseOverride: nil,
            accessibilityId: nil
        )
        #expect(base == "Form.user_email_field")
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
    
    @Test
    func testResolvedLocalizedDisplayString_UsesResolverWhenProvided() {
        let field = DynamicFormField(
            id: "x",
            contentType: .text,
            label: "Plain"
        )
        let resolver: (String) -> String = { key in
            key == "Screen.plain.label" ? "Étiquette" : key
        }
        let out = field.resolvedLocalizedDisplayString(
            role: .label,
            resolver: resolver,
            namespace: "Screen",
            fallback: "Plain"
        )
        #expect(out == "Étiquette")
    }
    
    @Test
    func testResolvedLocalizedDisplayString_SkipsResolverWhenNil() {
        let field = DynamicFormField(
            id: "x",
            contentType: .text,
            label: "Plain"
        )
        let out = field.resolvedLocalizedDisplayString(
            role: .label,
            resolver: nil,
            namespace: "Screen",
            fallback: "Plain"
        )
        #expect(out == "Plain")
    }
}

