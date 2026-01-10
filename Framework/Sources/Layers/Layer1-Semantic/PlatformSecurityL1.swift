//
//  PlatformSecurityL1.swift
//  SixLayerFramework
//
//  Layer 1 Semantic Intent functions for Security & Privacy
//  Provides high-level security interfaces following SixLayer architecture
//

import Foundation
import SwiftUI

// MARK: - Layer 1 Security Functions

/// Present secure content with biometric authentication
/// - Parameters:
///   - content: The content to present
///   - hints: Security hints
/// - Returns: SwiftUI view with security service
public func platformPresentSecureContent_L1<Content: View>(
    content: Content,
    hints: SecurityHints = SecurityHints()
) -> AnyView {
    let security = SecurityService(
        biometricPolicy: hints.biometricPolicy,
        encryptionKey: hints.encryptionKey,
        enablePrivacyIndicators: hints.enablePrivacyIndicators
    )
    
    return AnyView(content
        .environmentObject(security)
        .environment(\.securityService, security)
        .automaticCompliance(named: "platformPresentSecureContent_L1"))
}

/// Present secure text field with automatic secure entry
/// - Parameters:
///   - title: The field title
///   - text: Binding to the text value
///   - hints: Security hints
/// - Returns: SwiftUI view with secure text field
public func platformPresentSecureTextField_L1(
    title: String,
    text: Binding<String>,
    hints: SecurityHints = SecurityHints()
) -> AnyView {
    let security = SecurityService(
        biometricPolicy: hints.biometricPolicy,
        encryptionKey: hints.encryptionKey,
        enablePrivacyIndicators: hints.enablePrivacyIndicators
    )
    if hints.enableSecureTextEntry {
        security.enableSecureTextEntry(for: title)
    }
    
    return AnyView(SecureField(title, text: text)
        .environmentObject(security)
        .environment(\.securityService, security)
        .automaticCompliance(named: "platformPresentSecureTextField_L1"))
}

/// Request biometric authentication
/// - Parameters:
///   - reason: Reason for authentication (shown to user)
///   - hints: Security hints
/// - Returns: True if authentication succeeded
@MainActor
public func platformRequestBiometricAuth_L1(
    reason: String,
    hints: SecurityHints = SecurityHints()
) async throws -> Bool {
    let security = SecurityService(biometricPolicy: hints.biometricPolicy)
    return try await security.authenticateWithBiometrics(reason: reason)
}

/// Show privacy indicator
/// - Parameters:
///   - type: Type of privacy resource in use
///   - isActive: Whether the resource is currently active
///   - hints: Security hints
/// - Returns: Empty view (indicator is shown via system APIs)
public func platformShowPrivacyIndicator_L1(
    type: PrivacyPermissionType,
    isActive: Bool,
    hints: SecurityHints = SecurityHints()
) -> some View {
    let security = SecurityService(enablePrivacyIndicators: hints.enablePrivacyIndicators)
    security.showPrivacyIndicator(type, isActive: isActive)
    
    return EmptyView() // Indicator is shown via system APIs
}
