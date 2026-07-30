//
//  SixLayerTestKit.swift
//  SixLayerTestKit
//
//  Main entry point for SixLayer testing utilities
//

import Foundation
import SwiftUI
import SixLayerFramework

/// Main test kit class providing access to all SixLayer testing utilities
@MainActor
public class SixLayerTestKit {

    // MARK: - Service Mocks

    /// Service test doubles for mocking SixLayer services
    public let serviceMocks: ServiceMocks

    // MARK: - Form & Navigation Helpers

    /// Helpers for testing forms and navigation
    public let formHelper: FormTestHelper
    public let navigationHelper: NavigationTestHelper

    // MARK: - Layer Flow Utilities

    /// Utilities for driving Layer 1→6 flows deterministically
    public let layerFlowDriver: LayerFlowDriver

    // MARK: - Initialization

    public init() {
        self.serviceMocks = ServiceMocks()
        self.formHelper = FormTestHelper()
        self.navigationHelper = NavigationTestHelper()
        self.layerFlowDriver = LayerFlowDriver()
    }
}

// MARK: - Service Mocks Container

/// Container for all service test doubles
@MainActor
public class ServiceMocks {

    /// CloudKit service mock
    public let cloudKitService: CloudKitServiceMock

    /// Notification service mock
    public let notificationService: NotificationServiceMock

    /// Security service mock
    public let securityService: SecurityServiceMock

    /// Internationalization service mock
    public let internationalizationService: InternationalizationServiceMock

    /// Barcode service mock
    public let barcodeService: BarcodeServiceMock

    /// OCR service mock
    public let ocrService: OCRServiceMock

    /// Location service mock
    public let locationService: LocationServiceMock

    init() {
        self.cloudKitService = CloudKitServiceMock()
        self.notificationService = NotificationServiceMock()
        self.securityService = SecurityServiceMock()
        self.internationalizationService = InternationalizationServiceMock()
        self.barcodeService = BarcodeServiceMock()
        self.ocrService = OCRServiceMock()
        self.locationService = LocationServiceMock()
    }
}

// MARK: - Test Data Generators

/// Utilities for generating test data
public class TestDataGenerator {

    /// Generate random test string
    public static func randomString(length: Int = 10) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    /// Generate random email
    public static func randomEmail() -> String {
        return "\(randomString(length: 8))@\(randomString(length: 5)).com"
    }

    /// Generate random phone number
    public static func randomPhoneNumber() -> String {
        return "+1\(Int.random(in: 2000000000...9999999999))"
    }

    /// Generate random date within range
    public static func randomDate(in range: ClosedRange<Date> = Date.distantPast...Date.distantFuture) -> Date {
        let timeInterval = Date().timeIntervalSince(range.lowerBound) + Double.random(in: 0...range.upperBound.timeIntervalSince(range.lowerBound))
        return range.lowerBound.addingTimeInterval(timeInterval)
    }
}

// MARK: - Test Environment Setup

/// Helper for setting up test environments
public class TestEnvironment {

    /// Create a test environment with mock services
    @MainActor
    public static func createTestEnvironment(with testKit: SixLayerTestKit) -> EnvironmentValues {
        let environment = EnvironmentValues()

        // Note: internationalizationService is not available as an environment value
        // Mock services should be injected directly into views/components being tested
        // rather than through environment values

        return environment
    }

    /// Create test design system for consistent UI testing
    public static func createTestDesignSystem() -> DesignSystem {
        return SixLayerDesignSystem()
    }
}