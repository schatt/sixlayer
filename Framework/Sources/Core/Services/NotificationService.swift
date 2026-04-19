//
//  NotificationService.swift
//  SixLayerFramework
//
//  Cross-platform notification service implementation
//  Provides platform-appropriate alerts, badge management, notification center integration,
//  and Do Not Disturb support following the same pattern as InternationalizationService
//

import Foundation
import SwiftUI
import Combine

#if canImport(UserNotifications)
import UserNotifications
#endif

#if canImport(Intents)
import Intents
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Notification Service

/// Cross-platform notification service for managing notifications, badges, and alerts
/// Follows the same pattern as InternationalizationService and LocationService
@MainActor
public class NotificationService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current notification permission status
    @Published public private(set) var permissionStatus: NotificationPermissionStatus = .notDetermined
    
    /// Current notification settings
    @Published public private(set) var settings: NotificationSettings
    
    /// Current badge count
    @Published public private(set) var badgeCount: Int = 0
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    /// Whether Do Not Disturb is currently active
    @Published public private(set) var isDoNotDisturbActive: Bool = false
    
    // MARK: - Configuration
    
    /// Whether to automatically manage badge counts
    private let enableBadgeManagement: Bool
    
    /// Whether to respect Do Not Disturb settings
    private let respectDoNotDisturb: Bool
    
    /// Default notification sound name
    private let defaultSound: String?
    
    // MARK: - Initialization
    
    /// Initialize the notification service
    /// - Parameters:
    ///   - enableBadgeManagement: Whether to automatically manage badge counts (default: true)
    ///   - respectDoNotDisturb: Whether to respect Do Not Disturb settings (default: true)
    ///   - defaultSound: Default notification sound name (default: nil)
    public init(
        enableBadgeManagement: Bool = true,
        respectDoNotDisturb: Bool = true,
        defaultSound: String? = nil
    ) {
        self.enableBadgeManagement = enableBadgeManagement
        self.respectDoNotDisturb = respectDoNotDisturb
        self.defaultSound = defaultSound
        
        // Initialize settings
        self.settings = NotificationSettings(permissionStatus: .notDetermined)
        
        // Update status from system
        updatePermissionStatus()
        updateDoNotDisturbStatus()
    }
    
    // MARK: - Permission Management
    
    /// Request notification permission
    /// - Parameter options: Notification types to request (default: [.alert, .badge, .sound])
    /// - Returns: Permission status after request
    public func requestPermission(options: [NotificationType] = [.alert, .badge, .sound]) async -> NotificationPermissionStatus {
        #if os(iOS)
        return await requestIOSNotificationPermission(options: options)
        #elseif os(macOS)
        return await requestMacOSNotificationPermission(options: options)
        #else
        return .notDetermined
        #endif
    }
    
    /// Check current permission status
    /// - Returns: Current permission status
    public func checkPermissionStatus() -> NotificationPermissionStatus {
        updatePermissionStatus()
        return permissionStatus
    }
    
    // MARK: - Badge Management
    
    /// Update app badge count
    /// - Parameter count: Badge count (0 to clear)
    /// - Throws: NotificationServiceError if update fails
    public func updateBadge(_ count: Int) throws {
        guard enableBadgeManagement else { return }
        guard count >= 0 else {
            let error = NotificationServiceError.badgeUpdateFailed
            lastError = error
            throw error
        }
        
        badgeCount = count
        
        // In test environments, UNUserNotificationCenter.current() can assert/crash
        // Skip the actual badge update in test mode, but still track the count
        if Self.isTestEnvironment() {
            return
        }
        
        #if os(iOS)
        if #available(iOS 17.0, *) {
            // Use modern API for iOS 17+ (fire-and-forget async call)
            // Note: This is async but we can't make updateBadge async without breaking API
            let center = UNUserNotificationCenter.current()
            Task {
                try? await center.setBadgeCount(count)
            }
        } else {
            // Use legacy API for iOS < 17
            // Note: applicationIconBadgeNumber is deprecated in iOS 17.0, but required for iOS < 17 compatibility
            UIApplication.shared.applicationIconBadgeNumber = count
        }
        #elseif os(macOS)
        // macOS doesn't have badge numbers on the dock icon, but we track it for consistency
        #endif
    }
    
    /// Increment badge count
    /// - Throws: NotificationServiceError if update fails
    public func incrementBadge() throws {
        try updateBadge(badgeCount + 1)
    }
    
    /// Decrement badge count
    /// - Throws: NotificationServiceError if update fails
    public func decrementBadge() throws {
        try updateBadge(max(0, badgeCount - 1))
    }
    
    /// Clear badge
    /// - Throws: NotificationServiceError if update fails
    public func clearBadge() throws {
        try updateBadge(0)
    }
    
    // MARK: - Do Not Disturb
    
    /// Check if Do Not Disturb is active
    /// - Returns: True if Do Not Disturb is active
    public func checkDoNotDisturbStatus() -> Bool {
        updateDoNotDisturbStatus()
        return isDoNotDisturbActive
    }
    
    /// Check if Do Not Disturb would block a notification
    /// - Returns: True if Do Not Disturb is active and should block notifications
    private func isDoNotDisturbBlocking() -> Bool {
        return respectDoNotDisturb && isDoNotDisturbActive
    }
    
    /// Check if Do Not Disturb is being respected
    /// - Returns: True if Do Not Disturb respect is enabled
    public var isRespectingDoNotDisturb: Bool {
        return respectDoNotDisturb
    }
    
    // MARK: - Local Notifications
    
    /// Register notification categories with actions
    /// - Parameter categories: Array of notification categories to register
    public func registerCategories(_ categories: [NotificationCategory]) {
        // In test environments, UNUserNotificationCenter.current() can assert/crash on macOS
        // Skip the registration in test mode
        if Self.isTestEnvironment() {
            return
        }
        
        #if os(iOS) || os(macOS)
        if #available(iOS 10.0, macOS 10.14, *) {
            let center = UNUserNotificationCenter.current()
            let unCategories = categories.map { category in
                self.createUNNotificationCategory(from: category)
            }
            center.setNotificationCategories(Set(unCategories))
        }
        #endif
    }
    
    /// Schedule a local notification
    /// - Parameters:
    ///   - identifier: Unique identifier for the notification
    ///   - title: Notification title
    ///   - body: Notification body
    ///   - date: When to deliver the notification
    ///   - sound: Sound name (optional)
    ///   - badge: Badge count (optional)
    ///   - categoryIdentifier: Category identifier for actions (optional)
    /// - Throws: NotificationServiceError if scheduling fails
    public func scheduleLocalNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date,
        sound: String? = nil,
        badge: Int? = nil,
        categoryIdentifier: String? = nil
    ) throws {
        guard permissionStatus == .authorized || permissionStatus == .provisional else {
            let error = NotificationServiceError.permissionDenied
            lastError = error
            throw error
        }
        
        #if os(iOS) || os(macOS)
        if #available(iOS 10.0, macOS 10.14, *) {
            try scheduleUNNotification(
                identifier: identifier,
                title: title,
                body: body,
                date: date,
                sound: sound ?? defaultSound,
                badge: badge,
                categoryIdentifier: categoryIdentifier
            )
        } else {
            throw NotificationServiceError.notificationNotSupported
        }
        #else
        throw NotificationServiceError.notificationNotSupported
        #endif
    }
    
    /// Cancel a scheduled notification
    /// - Parameter identifier: Notification identifier
    public func cancelNotification(identifier: String) {
        // In test environments, UNUserNotificationCenter.current() can assert/crash on macOS
        // Skip the cancellation in test mode
        if Self.isTestEnvironment() {
            return
        }
        
        #if os(iOS) || os(macOS)
        if #available(iOS 10.0, macOS 10.14, *) {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        #endif
    }
    
    /// Cancel all scheduled notifications
    public func cancelAllNotifications() {
        // In test environments, UNUserNotificationCenter.current() can assert/crash on macOS
        // Skip the cancellation in test mode
        if Self.isTestEnvironment() {
            return
        }
        
        #if os(iOS) || os(macOS)
        if #available(iOS 10.0, macOS 10.14, *) {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
        }
        #endif
    }
    
    // MARK: - Sound Preferences
    
    /// Check if sound is enabled
    /// - Returns: True if sound is enabled and Do Not Disturb is not blocking
    public func isSoundEnabled() -> Bool {
        return settings.soundEnabled && !isDoNotDisturbBlocking()
    }
    
    // MARK: - Private Helpers
    
    /// Check if we're running in a test environment
    /// UNUserNotificationCenter.current() can assert/crash in test environments, especially on macOS
    private static func isTestEnvironment() -> Bool {
        #if DEBUG
        // Check for XCTest environment variables
        let environment = ProcessInfo.processInfo.environment
        if environment["XCTestConfigurationFilePath"] != nil ||
           environment["XCTestSessionIdentifier"] != nil ||
           environment["XCTestBundlePath"] != nil ||
           NSClassFromString("XCTestCase") != nil {
            return true
        }
        // Check for Swift Testing framework (Testing.Test class)
        if NSClassFromString("Testing.Test") != nil {
            return true
        }
        // Fallback: Use TestingCapabilityDetection if available
        return TestingCapabilityDetection.isTestingMode
        #else
        return false
        #endif
    }
    
    /// Update permission status from system
    private func updatePermissionStatus() {
        // In test environments, UNUserNotificationCenter.current() can assert/crash on macOS
        // Skip the permission check and default to .notDetermined
        if Self.isTestEnvironment() {
            permissionStatus = .notDetermined
            updateSettings()
            return
        }
        
        #if os(iOS) || os(macOS)
        if #available(iOS 10.0, macOS 10.14, *) {
            // UNUserNotificationCenter.current() can assert in test environments
            // We've already checked for test mode above, so this should be safe
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { [weak self] notificationSettings in
                // Extract the authorization status value before sending to MainActor
                let authStatus = notificationSettings.authorizationStatus
                Task { @MainActor in
                    guard let self = self else { return }
                    self.permissionStatus = self.mapUNAuthorizationStatus(authStatus)
                    self.updateSettings()
                }
            }
        } else {
            permissionStatus = .notDetermined
            updateSettings()
        }
        #else
        permissionStatus = .notDetermined
        updateSettings()
        #endif
    }
    
    /// Update Do Not Disturb status from system
    private func updateDoNotDisturbStatus() {
        #if os(iOS)
        Task { @MainActor in
            self.isDoNotDisturbActive = await self.checkIOSDoNotDisturbStatusAsync()
            self.updateSettings()
        }
        #elseif os(macOS)
        isDoNotDisturbActive = checkMacOSDoNotDisturbStatus()
        updateSettings()
        #else
        isDoNotDisturbActive = false
        updateSettings()
        #endif
    }
    
    /// Update settings struct with current state
    private func updateSettings() {
        settings = NotificationSettings(
            permissionStatus: permissionStatus,
            alertEnabled: settings.alertEnabled,
            badgeEnabled: settings.badgeEnabled,
            soundEnabled: settings.soundEnabled,
            doNotDisturbActive: isDoNotDisturbActive,
            scheduledDeliveryEnabled: settings.scheduledDeliveryEnabled
        )
    }
    
    /// Map UNNotificationAuthorizationStatus to NotificationPermissionStatus
    #if os(iOS) || os(macOS)
    private func mapUNAuthorizationStatus(_ status: UNAuthorizationStatus) -> NotificationPermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        default:
            // Handle .ephemeral (iOS 17+) and any future cases
            // Ephemeral authorization (temporary, app-specific) maps to authorized
            // We check the description since we can't pattern match on future enum cases
            let statusDescription = String(describing: status)
            if statusDescription.contains("ephemeral") {
                return .authorized
            }
            // For any other unknown cases, default to notDetermined
            return .notDetermined
        }
    }
    #endif
    
    #if os(iOS) || os(macOS)
    /// Schedule a UNNotification (UserNotifications surface is not available for local scheduling on tvOS).
    private func scheduleUNNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date,
        sound: String?,
        badge: Int?,
        categoryIdentifier: String?
    ) throws {
        // In test environments, UNUserNotificationCenter.current() can assert/crash on macOS
        // Skip the scheduling in test mode
        if Self.isTestEnvironment() {
            return
        }
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        // Set sound if provided
        if let soundName = sound {
            if soundName == "default" {
                content.sound = .default
            } else {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
            }
        } else {
            content.sound = .default
        }
        
        // Set badge if provided
        if let badgeCount = badge {
            content.badge = NSNumber(value: badgeCount)
        }
        
        // Set category identifier if provided
        if let categoryId = categoryIdentifier {
            content.categoryIdentifier = categoryId
        }
        
        // Create trigger for the date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        center.add(request) { [weak self] error in
            if let error = error {
                Task { @MainActor in
                    self?.lastError = NotificationServiceError.unknown(error)
                }
            }
        }
    }
    
    /// Create UNNotificationCategory from NotificationCategory
    private func createUNNotificationCategory(from category: NotificationCategory) -> UNNotificationCategory {
        let actions = category.actions.map { action in
            self.createUNNotificationAction(from: action)
        }
        
        var options: UNNotificationCategoryOptions = []
        if category.options.contains(.customDismissAction) {
            options.insert(.customDismissAction)
        }
        #if os(iOS)
        if category.options.contains(.allowInCarPlay) {
            options.insert(.allowInCarPlay)
        }
        // Note: .allowAnnouncement is deprecated in iOS 15.0+ and ignored
        #endif
        
        return UNNotificationCategory(
            identifier: category.identifier,
            actions: actions,
            intentIdentifiers: category.intentIdentifiers,
            options: options
        )
    }
    
    /// Create UNNotificationAction from NotificationAction
    private func createUNNotificationAction(from action: NotificationAction) -> UNNotificationAction {
        var options: UNNotificationActionOptions = []
        if action.options.contains(.authenticationRequired) {
            options.insert(.authenticationRequired)
        }
        if action.options.contains(.destructive) {
            options.insert(.destructive)
        }
        if action.options.contains(.foreground) {
            options.insert(.foreground)
        }
        
        return UNNotificationAction(
            identifier: action.identifier,
            title: action.title,
            options: options
        )
    }
    #endif
}

// MARK: - View Extension for Platform-Appropriate Alerts

public extension View {
    /// Present a platform-appropriate alert using NotificationService
    /// - Parameters:
    ///   - isPresented: Binding to control alert presentation
    ///   - title: Alert title
    ///   - message: Alert message (optional)
    ///   - primaryAction: Primary action button
    ///   - secondaryAction: Secondary action button (optional)
    ///   - notificationService: NotificationService instance (optional, creates new if nil)
    /// - Returns: View with alert modifier
    func platformNotificationAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        primaryAction: Alert.Button,
        secondaryAction: Alert.Button? = nil,
        notificationService: NotificationService? = nil
    ) -> some View {
        let service = notificationService ?? NotificationService()
        
        // Check if Do Not Disturb would block
        let shouldShow = !service.isDoNotDisturbActive || !service.isRespectingDoNotDisturb
        
        let alert: Alert
        if let secondaryAction = secondaryAction {
            alert = Alert(
                title: Text(title),
                message: message.map { Text($0) },
                primaryButton: primaryAction,
                secondaryButton: secondaryAction
            )
        } else {
            alert = Alert(
                title: Text(title),
                message: message.map { Text($0) },
                dismissButton: primaryAction
            )
        }
        
        return self.alert(isPresented: shouldShow ? isPresented : .constant(false)) {
            alert
        }
        .environmentObject(service)
    }
    
    /// Present a platform-appropriate alert with RTL support
    /// - Parameters:
    ///   - isPresented: Binding to control alert presentation
    ///   - title: Alert title
    ///   - message: Alert message (optional)
    ///   - primaryAction: Primary action button
    ///   - secondaryAction: Secondary action button (optional)
    ///   - locale: Locale for RTL detection
    ///   - notificationService: NotificationService instance (optional)
    /// - Returns: View with alert modifier and RTL support
    func platformNotificationAlertRTL(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        primaryAction: Alert.Button,
        secondaryAction: Alert.Button? = nil,
        locale: Locale = Locale.current,
        notificationService: NotificationService? = nil
    ) -> some View {
        let service = notificationService ?? NotificationService()
        let i18n = InternationalizationService(locale: locale)
        let layoutDirection = i18n.getLayoutDirection()
        
        let alert: Alert
        if let secondaryAction = secondaryAction {
            alert = Alert(
                title: Text(title),
                message: message.map { Text($0) },
                primaryButton: primaryAction,
                secondaryButton: secondaryAction
            )
        } else {
            alert = Alert(
                title: Text(title),
                message: message.map { Text($0) },
                dismissButton: primaryAction
            )
        }
        
        return self.alert(isPresented: isPresented) {
            alert
        }
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, locale)
        .environmentObject(service)
    }
}

// MARK: - iOS Implementation

#if os(iOS)
extension NotificationService {
    /// Request notification permission on iOS
    private func requestIOSNotificationPermission(options: [NotificationType]) async -> NotificationPermissionStatus {
        // In test environments, UNUserNotificationCenter.current() can assert/crash on macOS
        // Skip the permission request in test mode
        if Self.isTestEnvironment() {
            permissionStatus = .notDetermined
            updateSettings()
            return .notDetermined
        }
        
        guard #available(iOS 10.0, *) else {
            permissionStatus = .notDetermined
            updateSettings()
            return .notDetermined
        }
        
        let center = UNUserNotificationCenter.current()
        
        // Convert NotificationType to UNAuthorizationOptions
        var authOptions: UNAuthorizationOptions = []
        for option in options {
            switch option {
            case .alert:
                authOptions.insert(.alert)
            case .badge:
                authOptions.insert(.badge)
            case .sound:
                authOptions.insert(.sound)
            case .banner:
                authOptions.insert(.alert) // Banner is a type of alert
            case .all:
                authOptions = [.alert, .badge, .sound]
            }
        }
        
        do {
            let granted = try await center.requestAuthorization(options: authOptions)
            if granted {
                // Check the actual authorization status
                let settings = await center.notificationSettings()
                permissionStatus = mapUNAuthorizationStatus(settings.authorizationStatus)
            } else {
                permissionStatus = .denied
            }
            updateSettings()
            return permissionStatus
        } catch {
            lastError = NotificationServiceError.unknown(error)
            permissionStatus = .denied
            updateSettings()
            return .denied
        }
    }
    
    /// Check Do Not Disturb status on iOS (async version)
    @available(iOS 15.0, *)
    private func checkIOSDoNotDisturbStatusAsync() async -> Bool {
        #if os(iOS)
        // Use INFocusStatusCenter to check Focus status (includes Do Not Disturb)
        let focusStatusCenter = INFocusStatusCenter.default
        
        // focusStatus is a synchronous property, not async/throwing
        let focusStatus = focusStatusCenter.focusStatus
        // isFocused is optional Bool?, so unwrap with nil-coalescing to default to false
        // This is a conservative default when Focus status is unavailable
        return focusStatus.isFocused ?? false
        #else
        return false
        #endif
    }
    
    /// Check Do Not Disturb status on iOS (sync fallback)
    private func checkIOSDoNotDisturbStatus() -> Bool {
        #if os(iOS)
        if #available(iOS 15.0, *) {
            // For sync access, we can't reliably check without async API
            // Return false as conservative default
            // The async version will update this properly
            return false
        } else {
            // iOS < 15 doesn't have Focus API
            return false
        }
        #else
        return false
        #endif
    }
}
#endif

// MARK: - macOS Implementation

#if os(macOS)
extension NotificationService {
    /// Request notification permission on macOS
    private func requestMacOSNotificationPermission(options: [NotificationType]) async -> NotificationPermissionStatus {
        // In test environments, UNUserNotificationCenter.current() can assert/crash on macOS
        // Skip the permission request in test mode
        if Self.isTestEnvironment() {
            permissionStatus = .notDetermined
            updateSettings()
            return .notDetermined
        }
        
        guard #available(macOS 10.14, *) else {
            permissionStatus = .notDetermined
            updateSettings()
            return .notDetermined
        }
        
        let center = UNUserNotificationCenter.current()
        
        // Convert NotificationType to UNAuthorizationOptions
        var authOptions: UNAuthorizationOptions = []
        for option in options {
            switch option {
            case .alert:
                authOptions.insert(.alert)
            case .badge:
                authOptions.insert(.badge)
            case .sound:
                authOptions.insert(.sound)
            case .banner:
                authOptions.insert(.alert) // Banner is a type of alert
            case .all:
                authOptions = [.alert, .badge, .sound]
            }
        }
        
        do {
            let granted = try await center.requestAuthorization(options: authOptions)
            if granted {
                // Check the actual authorization status
                let settings = await center.notificationSettings()
                permissionStatus = mapUNAuthorizationStatus(settings.authorizationStatus)
            } else {
                permissionStatus = .denied
            }
            updateSettings()
            return permissionStatus
        } catch {
            lastError = NotificationServiceError.unknown(error)
            permissionStatus = .denied
            updateSettings()
            return .denied
        }
    }
    
    /// Check Do Not Disturb status on macOS
    private func checkMacOSDoNotDisturbStatus() -> Bool {
        #if os(macOS)
        if #available(macOS 12.0, *) {
            // macOS 12+ uses Focus modes similar to iOS
            // Check via system preferences or Focus status
            // Note: macOS doesn't have a direct public API, but we can check
            // the notification center's delivery settings
            
            // For macOS, we check if notifications are being suppressed
            // This is an approximation since there's no direct API
            // In practice, macOS Focus/DND status requires reading system files
            // which may not be reliable or allowed
            
            // Return false as a conservative default
            // Apps should respect user notification preferences regardless
            return false
        } else {
            // macOS < 12 uses older Do Not Disturb system
            // No reliable API available
            return false
        }
        #else
        return false
        #endif
    }
}
#endif

