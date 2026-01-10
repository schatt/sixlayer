//
//  PlatformNotificationL1.swift
//  SixLayerFramework
//
//  Layer 1 Semantic Intent functions for Notifications
//  Provides high-level notification interfaces following SixLayer architecture
//

import Foundation
import SwiftUI

// MARK: - Layer 1 Notification Functions

/// Request notification permission with platform-appropriate handling
/// - Parameter hints: Notification configuration hints
/// - Returns: Permission status after request
@MainActor
public func platformRequestNotificationPermission_L1(
    hints: NotificationHints = NotificationHints()
) async -> NotificationPermissionStatus {
    let notification = NotificationService(
        respectDoNotDisturb: hints.respectDoNotDisturb
    )
    return await notification.requestPermission()
}

/// Show notification with platform-appropriate style and RTL support
/// - Parameters:
///   - title: Notification title
///   - body: Notification body
///   - hints: Notification configuration hints
///   - locale: Locale for RTL detection (optional)
/// - Throws: NotificationServiceError if notification cannot be shown
@MainActor
public func platformShowNotification_L1(
    title: String,
    body: String,
    hints: NotificationHints = NotificationHints(),
    locale: Locale? = nil
) async throws {
    let notification = NotificationService(
        respectDoNotDisturb: hints.respectDoNotDisturb,
        defaultSound: hints.defaultSound
    )
    
    // Request permission if not already granted
    let status = await notification.requestPermission()
    guard status == .authorized || status == .provisional else {
        throw NotificationServiceError.permissionDenied
    }
    
    // Check RTL for title and body
    let i18n = InternationalizationService(locale: locale ?? Locale.current)
    let _ = i18n.textDirection(for: title) // Reserved for future RTL support
    let _ = i18n.textDirection(for: body) // Reserved for future RTL support
    
    // Schedule immediate notification
    // Note: UNNotificationContent doesn't directly support RTL, but the system
    // will handle RTL text automatically based on the locale
    try notification.scheduleLocalNotification(
        identifier: UUID().uuidString,
        title: title,
        body: body,
        date: Date(),
        sound: hints.defaultSound
    )
}

/// Update app badge count
/// - Parameters:
///   - count: Badge count (0 to clear)
///   - hints: Notification configuration hints
/// - Throws: NotificationServiceError if badge update fails
@MainActor
public func platformUpdateBadge_L1(
    count: Int,
    hints: NotificationHints = NotificationHints()
) throws {
    let notification = NotificationService(
        enableBadgeManagement: hints.enableBadgeManagement
    )
    try notification.updateBadge(count)
}

/// Present platform-appropriate alert with RTL support
/// Note: This provides the service and RTL context. Actual alert presentation
/// should use SwiftUI's .alert() modifier with the service.
/// - Parameters:
///   - title: Alert title
///   - message: Alert message
///   - hints: Notification configuration hints
///   - locale: Locale for RTL detection (optional)
/// - Returns: View with notification service and RTL environment
/// Note: Requires @MainActor because NotificationService is ObservableObject with @Published properties
@MainActor
public func platformPresentAlert_L1(
    title: String,
    message: String? = nil,
    hints: NotificationHints = NotificationHints(),
    locale: Locale? = nil
) -> AnyView {
    let notification = NotificationService(
        respectDoNotDisturb: hints.respectDoNotDisturb
    )
    
    // Check RTL for title and message
    let i18n = InternationalizationService(locale: locale ?? Locale.current)
    let _ = i18n.textDirection(for: title) // Reserved for future RTL support
    let layoutDirection = i18n.getLayoutDirection()
    
    // If message provided, check its direction too
    if let message = message {
        let _ = i18n.textDirection(for: message) // Reserved for future RTL support
        // Use the dominant direction or mixed
    }
    
    // Return view with RTL support and notification service
    return AnyView(EmptyView()
        .environmentObject(notification)
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, locale ?? Locale.current)
        .automaticCompliance(named: "platformPresentAlert_L1"))
}

