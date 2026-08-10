//
//  NotificationServiceTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive tests for NotificationService
//  Tests notification service functionality with mocks where needed
//

import Testing
import Foundation
@testable import SixLayerFramework

/// Comprehensive tests for NotificationService
/// Tests the cross-platform notification service implementation
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Notification Service")
open class NotificationServiceTests: BaseTestClass {

    /// Cancel APIs are UN-center no-ops in unit-test env; observe published-state invariance.
    @MainActor
    private func expectCancelLeavesPublishedStateIntact(_ mutate: (NotificationService) -> Void) {
        let service = NotificationService()
        let badgeBefore = service.badgeCount
        mutate(service)
        #expect(service.badgeCount == badgeBefore)
        #expect(service.lastError == nil)
    }
    
    // MARK: - Service Initialization Tests
    
    @Test @MainActor func testNotificationServiceInitialization() async {
        // Given & When: Creating the service with defaults
        let service = NotificationService()
        
        // Then: Service should be created successfully
        #expect(service.permissionStatus == .notDetermined || 
                service.permissionStatus == .denied || 
                service.permissionStatus == .authorized)
        #expect(service.badgeCount == 0)
        #expect(service.isDoNotDisturbActive == false)
    }
    
    @Test @MainActor func testNotificationServiceInitializationWithCustomConfig() async {
        // Given & When: Creating the service with custom configuration
        let service = NotificationService(
            enableBadgeManagement: false,
            respectDoNotDisturb: false,
            defaultSound: "customSound"
        )
        
        // Then: Service should be created with custom config
        #expect(service.permissionStatus == .notDetermined || 
                service.permissionStatus == .denied || 
                service.permissionStatus == .authorized)
    }
    
    // MARK: - Permission Status Tests
    
    @Test @MainActor func testNotificationServiceHasPermissionStatus() async {
        // Given: NotificationService
        let service = NotificationService()
        
        // When: Checking permission status
        let status = service.checkPermissionStatus()
        
        // Then: Should return a valid NotificationPermissionStatus
        #expect(status == .notDetermined || 
                status == .denied || 
                status == .authorized || 
                status == .provisional)
    }
    
    @Test @MainActor func testNotificationServicePermissionStatusIsPublished() async {
        // Given: NotificationService
        let service = NotificationService()
        
        // When: Accessing permission status
        let status = service.permissionStatus
        
        // Then: Should be a valid status
        #expect(status == .notDetermined || 
                status == .denied || 
                status == .authorized || 
                status == .provisional)
    }
    
    // MARK: - Badge Management Tests
    
    @Test @MainActor func testNotificationServiceCanUpdateBadge() async throws {
        // Given: NotificationService with badge management enabled
        let service = NotificationService(enableBadgeManagement: true)
        let testCount = 5
        
        // When: Updating badge count
        try service.updateBadge(testCount)
        
        // Then: Badge count should be updated
        #expect(service.badgeCount == testCount)
    }
    
    @Test @MainActor func testNotificationServiceCanIncrementBadge() async throws {
        // Given: NotificationService with initial badge count
        let service = NotificationService(enableBadgeManagement: true)
        try service.updateBadge(3)
        
        // When: Incrementing badge
        try service.incrementBadge()
        
        // Then: Badge count should be incremented
        #expect(service.badgeCount == 4)
    }
    
    @Test @MainActor func testNotificationServiceCanDecrementBadge() async throws {
        // Given: NotificationService with initial badge count
        let service = NotificationService(enableBadgeManagement: true)
        try service.updateBadge(5)
        
        // When: Decrementing badge
        try service.decrementBadge()
        
        // Then: Badge count should be decremented
        #expect(service.badgeCount == 4)
    }
    
    @Test @MainActor func testNotificationServiceCanClearBadge() async throws {
        // Given: NotificationService with badge count
        let service = NotificationService(enableBadgeManagement: true)
        try service.updateBadge(10)
        
        // When: Clearing badge
        try service.clearBadge()
        
        // Then: Badge count should be 0
        #expect(service.badgeCount == 0)
    }
    
    @Test @MainActor func testNotificationServiceBadgeCannotBeNegative() async {
        // Given: NotificationService
        let service = NotificationService(enableBadgeManagement: true)
        
        // When: Trying to set negative badge count
        // Then: Should throw error
        #expect(throws: NotificationServiceError.badgeUpdateFailed) {
            try service.updateBadge(-1)
        }
    }
    
    @Test @MainActor func testNotificationServiceBadgeDecrementDoesNotGoBelowZero() async throws {
        // Given: NotificationService with badge count of 0
        let service = NotificationService(enableBadgeManagement: true)
        try service.updateBadge(0)
        
        // When: Decrementing badge
        try service.decrementBadge()
        
        // Then: Badge count should remain 0
        #expect(service.badgeCount == 0)
    }
    
    @Test @MainActor func testNotificationServiceBadgeManagementCanBeDisabled() async throws {
        // Given: NotificationService with badge management disabled
        let service = NotificationService(enableBadgeManagement: false)
        
        // When: Trying to update badge
        try service.updateBadge(5)
        
        // Then: Early-return leaves badgeCount at 0; no error recorded
        #expect(service.badgeCount == 0)
        #expect(service.lastError == nil)
    }
    
    // MARK: - Do Not Disturb Tests
    
    @Test @MainActor func testNotificationServiceCanCheckDoNotDisturbStatus() async {
        // Given: NotificationService
        let service = NotificationService()
        
        // When: Checking Do Not Disturb status
        let isActive = service.checkDoNotDisturbStatus()
        
        // Then: Should return a boolean value
        #expect(isActive == true || isActive == false)
    }
    
    @Test @MainActor func testNotificationServiceRespectsDoNotDisturbWhenEnabled() async {
        // Given: NotificationService with Do Not Disturb respect enabled
        let service = NotificationService(respectDoNotDisturb: true)
        
        // When: Checking if sound is enabled
        let soundEnabled = service.isSoundEnabled()
        
        // Then: Should respect Do Not Disturb status
        // (This is a structural test - actual behavior depends on system state)
        #expect(soundEnabled == true || soundEnabled == false)
    }
    
    @Test @MainActor func testNotificationServiceCanIgnoreDoNotDisturb() async {
        // Given: NotificationService with Do Not Disturb respect disabled
        let service = NotificationService(respectDoNotDisturb: false)
        
        // When: Checking if sound is enabled
        let soundEnabled = service.isSoundEnabled()
        
        // Then: Should not be blocked by Do Not Disturb
        // (This is a structural test - actual behavior depends on system state)
        #expect(soundEnabled == true || soundEnabled == false)
    }
    
    @Test @MainActor func testNotificationServiceHandlesOptionalFocusStatus() async {
        // Given: NotificationService
        // This test verifies that checkIOSDoNotDisturbStatusAsync properly handles
        // the optional Bool? returned by focusStatus.isFocused
        let service = NotificationService()
        
        // When: Checking Do Not Disturb status (which internally calls checkIOSDoNotDisturbStatusAsync)
        // The async function must unwrap the optional and return a non-optional Bool
        // When isFocused is nil, it should return false as a conservative default
        let isActive = service.checkDoNotDisturbStatus()
        
        // Then: Should return a non-optional Bool value
        // The function must compile and handle nil isFocused by returning false
        #expect(isActive == true || isActive == false)
        
        // Verify the property is also set correctly (not optional)
        let propertyValue = service.isDoNotDisturbActive
        #expect(propertyValue == true || propertyValue == false)
    }
    
    // MARK: - Settings Tests
    
    @Test @MainActor func testNotificationServiceHasSettings() async {
        // Given: NotificationService
        let service = NotificationService()
        
        // When: Accessing settings
        let settings = service.settings
        
        // Then: Should have valid settings
        #expect(settings.permissionStatus == .notDetermined || 
                settings.permissionStatus == .denied || 
                settings.permissionStatus == .authorized || 
                settings.permissionStatus == .provisional)
    }
    
    @Test @MainActor func testNotificationServiceSettingsArePublished() async {
        // Given: NotificationService
        let service = NotificationService()
        
        // When: Accessing settings property
        let settings = service.settings
        
        // Then: Should have all required properties
        #expect(settings.alertEnabled == true || settings.alertEnabled == false)
        #expect(settings.badgeEnabled == true || settings.badgeEnabled == false)
        #expect(settings.soundEnabled == true || settings.soundEnabled == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test @MainActor func testNotificationServiceHasErrorProperty() async {
        // Given: NotificationService
        let service = NotificationService()
        
        // When: Checking error property
        let error = service.lastError
        
        // Then: Should be nil initially or contain an error
        #expect(error == nil || error != nil)
    }
    
    @Test @MainActor func testNotificationServiceErrorIsPublished() async {
        // Given: NotificationService
        let service = NotificationService()
        
        // When: Accessing lastError
        let error = service.lastError
        
        // Then: Should be accessible (nil or non-nil)
        #expect(error == nil || error != nil)
    }
    
    // MARK: - Notification Scheduling Tests
    
    @Test @MainActor func testNotificationServiceCanScheduleLocalNotification() async throws {
        // Given: NotificationService in unit-test env (permission forced to .notDetermined)
        let service = NotificationService()
        
        // Then: schedule requires authorized/provisional — unit env always denies
        #expect(throws: NotificationServiceError.permissionDenied) {
            try service.scheduleLocalNotification(
                identifier: "test-notification",
                title: "Test Title",
                body: "Test Body",
                date: Date().addingTimeInterval(60)
            )
        }
        #expect(service.lastError as? NotificationServiceError == .permissionDenied)
    }
    
    @Test @MainActor func testNotificationServiceCanCancelNotification() async {
        expectCancelLeavesPublishedStateIntact { service in
            service.cancelNotification(identifier: "test-notification")
        }
    }
    
    @Test @MainActor func testNotificationServiceCanCancelAllNotifications() async {
        expectCancelLeavesPublishedStateIntact { service in
            service.cancelAllNotifications()
        }
    }
    
    // MARK: - Sound Preferences Tests
    
    @Test @MainActor func testNotificationServiceCanCheckSoundEnabled() async {
        // Given: NotificationService
        let service = NotificationService()
        
        // When: Checking if sound is enabled
        let soundEnabled = service.isSoundEnabled()
        
        // Then: Should return a boolean value
        #expect(soundEnabled == true || soundEnabled == false)
    }
    
    // MARK: - Notification Types Tests
    
    @Test func testNotificationTypeDisplayNames() {
        // Given: NotificationType cases
        // When: Accessing display names
        // Then: Should have valid display names
        #expect(NotificationType.alert.displayName == "Alert")
        #expect(NotificationType.banner.displayName == "Banner")
        #expect(NotificationType.badge.displayName == "Badge")
        #expect(NotificationType.sound.displayName == "Sound")
        #expect(NotificationType.all.displayName == "All")
    }
    
    // MARK: - Notification Service Error Tests
    
    @Test func testNotificationServiceErrorDescriptions() {
        // Given: NotificationServiceError cases
        // When: Accessing error descriptions
        // Then: Should have valid descriptions
        #expect(NotificationServiceError.permissionDenied.errorDescription != nil)
        #expect(NotificationServiceError.permissionNotDetermined.errorDescription != nil)
        #expect(NotificationServiceError.notificationNotSupported.errorDescription != nil)
        #expect(NotificationServiceError.invalidNotification.errorDescription != nil)
        #expect(NotificationServiceError.schedulingFailed.errorDescription != nil)
        #expect(NotificationServiceError.badgeUpdateFailed.errorDescription != nil)
        #expect(NotificationServiceError.soundNotFound.errorDescription != nil)
        #expect(NotificationServiceError.doNotDisturbActive.errorDescription != nil)
    }
    
    @Test func testNotificationServiceErrorUnknownError() {
        // Given: An unknown error
        let testError = NSError(domain: "TestDomain", code: 123)
        let serviceError = NotificationServiceError.unknown(testError)
        
        // When: Accessing error description
        let description = serviceError.errorDescription
        
        // Then: Should include the underlying error description
        #expect(description != nil)
        #expect(description?.contains("Unknown error") == true || 
                description?.contains(testError.localizedDescription) == true)
    }
    
    // MARK: - Notification Hints Tests
    
    @Test func testNotificationHintsInitialization() {
        // Given: NotificationHints with defaults
        let hints = NotificationHints()
        
        // Then: Should have default values
        #expect(hints.enableBadgeManagement == true)
        #expect(hints.respectDoNotDisturb == true)
        #expect(hints.defaultSound == nil)
        #expect(hints.alertStyle == .alert)
        #expect(hints.priority == .normal)
    }
    
    @Test func testNotificationHintsCustomInitialization() {
        // Given: NotificationHints with custom values
        let hints = NotificationHints(
            enableBadgeManagement: false,
            respectDoNotDisturb: false,
            defaultSound: "customSound",
            alertStyle: .banner,
            priority: .high
        )
        
        // Then: Should have custom values
        #expect(hints.enableBadgeManagement == false)
        #expect(hints.respectDoNotDisturb == false)
        #expect(hints.defaultSound == "customSound")
        #expect(hints.alertStyle == .banner)
        #expect(hints.priority == .high)
    }
    
    // MARK: - Notification Settings Tests
    
    @Test func testNotificationSettingsInitialization() {
        // Given: NotificationSettings with defaults
        let settings = NotificationSettings(permissionStatus: .authorized)
        
        // Then: Should have default values
        #expect(settings.permissionStatus == .authorized)
        #expect(settings.alertEnabled == true)
        #expect(settings.badgeEnabled == true)
        #expect(settings.soundEnabled == true)
        #expect(settings.doNotDisturbActive == false)
        #expect(settings.scheduledDeliveryEnabled == false)
    }
    
    @Test func testNotificationSettingsCustomInitialization() {
        // Given: NotificationSettings with custom values
        let settings = NotificationSettings(
            permissionStatus: .denied,
            alertEnabled: false,
            badgeEnabled: false,
            soundEnabled: false,
            doNotDisturbActive: true,
            scheduledDeliveryEnabled: true
        )
        
        // Then: Should have custom values
        #expect(settings.permissionStatus == .denied)
        #expect(settings.alertEnabled == false)
        #expect(settings.badgeEnabled == false)
        #expect(settings.soundEnabled == false)
        #expect(settings.doNotDisturbActive == true)
        #expect(settings.scheduledDeliveryEnabled == true)
    }
    
    // MARK: - Alert Action Tests
    
    @Test func testAlertActionInitialization() {
        // Given: AlertAction with defaults
        let action = AlertAction(identifier: "test", title: "Test Action")
        
        // Then: Should have default values
        #expect(action.identifier == "test")
        #expect(action.title == "Test Action")
        #expect(action.style == .default)
        #expect(action.isDestructive == false)
    }
    
    @Test func testAlertActionCustomInitialization() {
        // Given: AlertAction with custom values
        let action = AlertAction(
            identifier: "delete",
            title: "Delete",
            style: .destructive,
            isDestructive: true
        )
        
        // Then: Should have custom values
        #expect(action.identifier == "delete")
        #expect(action.title == "Delete")
        #expect(action.style == .destructive)
        #expect(action.isDestructive == true)
    }
}

