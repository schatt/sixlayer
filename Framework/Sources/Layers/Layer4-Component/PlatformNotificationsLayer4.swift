import SwiftUI

#if os(iOS)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Platform Notifications Layer 4: Component Implementation

/// Platform-agnostic helpers for remote notification registration
///
/// ## Cross-Platform Behavior
///
/// ### Remote Notification Registration (`platformRegisterForRemoteNotifications_L4`)
/// **Semantic Purpose**: Register the app to receive remote push notifications
/// - **iOS**: Uses `UIApplication.shared.registerForRemoteNotifications()`
///   - Registers with Apple Push Notification service (APNs)
///   - Requires notification permissions to be granted first
///   - Device token is delivered via `UIApplicationDelegate` methods
/// - **macOS**: Uses `NSApplication.shared.registerForRemoteNotifications()`
///   - Registers with Apple Push Notification service (APNs)
///   - Requires notification permissions to be granted first (macOS 10.14+)
///   - Device token is delivered via `NSApplicationDelegate` methods
///
/// **When to Use**: After requesting and receiving notification permissions, register for remote notifications
/// **Prerequisites**: Notification permissions must be granted before calling this function
///
/// **Note**: This function only initiates registration. The actual device token is delivered
/// asynchronously via the app delegate methods:
/// - iOS: `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
/// - macOS: `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
///
/// Error handling is done via:
/// - iOS: `application(_:didFailToRegisterForRemoteNotificationsWithError:)`
/// - macOS: `application(_:didFailToRegisterForRemoteNotificationsWithError:)`

// MARK: - Remote Notification Registration

/// Register the app to receive remote push notifications
///
/// **Cross-Platform Behavior:**
/// - **iOS**: Calls `UIApplication.shared.registerForRemoteNotifications()`
/// - **macOS**: Calls `NSApplication.shared.registerForRemoteNotifications()` (macOS 10.14+)
///
/// **Prerequisites:**
/// - Notification permissions must be granted before calling this function
/// - App delegate must implement token delivery methods
///
/// **Use For**: Registering for remote push notifications after permissions are granted
///
/// - Returns: `true` if registration was initiated, `false` otherwise
@MainActor
@discardableResult
public func platformRegisterForRemoteNotifications_L4() -> Bool {
    #if os(iOS)
    return platformRegisterForRemoteNotificationsiOS()
    #elseif os(macOS)
    return platformRegisterForRemoteNotificationsMacOS()
    #else
    return false
    #endif
}

// MARK: - iOS Implementation

#if os(iOS)
/// iOS remote notification registration
@MainActor
private func platformRegisterForRemoteNotificationsiOS() -> Bool {
    // Don't actually register during unit tests
    #if DEBUG
    if NSClassFromString("XCTest") != nil {
        // Running in test environment - return success without registering
        return true
    }
    #endif
    
    // Register for remote notifications
    // Note: Calling this multiple times is safe - the system handles re-registration gracefully
    UIApplication.shared.registerForRemoteNotifications()
    return true
}
#endif

// MARK: - macOS Implementation

#if os(macOS)
/// macOS remote notification registration
@MainActor
private func platformRegisterForRemoteNotificationsMacOS() -> Bool {
    // Don't actually register during unit tests
    #if DEBUG
    if NSClassFromString("XCTest") != nil {
        // Running in test environment - return success without registering
        return true
    }
    #endif
    
    // Check if remote notifications are supported (macOS 10.14+)
    if #available(macOS 10.14, *) {
        // Register for remote notifications
        NSApplication.shared.registerForRemoteNotifications()
        return true
    } else {
        // Remote notifications not supported on macOS < 10.14
        return false
    }
}
#endif

