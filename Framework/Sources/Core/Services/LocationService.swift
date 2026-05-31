//
//  LocationService.swift
//  SixLayerFramework
//
//  Cross-platform location service implementation
//  Properly handles actor isolation for Swift 6 strict concurrency
//

import Foundation
import CoreLocation
import Combine

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Location Service Protocol

/// Protocol defining the interface for location services
@MainActor
public protocol LocationServiceProtocol {
    /// Current authorization status
    var authorizationStatus: CLAuthorizationStatus { get }

    /// Whether location services are enabled
    var isLocationEnabled: Bool { get }

    /// Any error that occurred
    var error: Error? { get }

    /// Request location authorization
    func requestAuthorization() async throws

    /// Start location updates
    func startUpdatingLocation()

    /// Stop location updates
    func stopUpdatingLocation()

    /// Get current location
    func getCurrentLocation() async throws -> CLLocation
}

// MARK: - Location Service Errors

public enum LocationServiceError: LocalizedError {
    case servicesDisabled
    case unauthorized
    case denied
    case restricted
    case authorizationTimeout
    case locationTimeout
    case unknown

    public var errorDescription: String? {
        let i18n = InternationalizationService()
        switch self {
        case .servicesDisabled:
            return i18n.localizedString(for: "SixLayerFramework.location.servicesDisabled")
        case .unauthorized:
            return i18n.localizedString(for: "SixLayerFramework.location.unauthorized")
        case .denied:
            return i18n.localizedString(for: "SixLayerFramework.location.denied")
        case .restricted:
            return i18n.localizedString(for: "SixLayerFramework.location.restricted")
        case .authorizationTimeout:
            return i18n.localizedString(for: "SixLayerFramework.location.authorizationTimeout")
        case .locationTimeout:
            return i18n.localizedString(for: "SixLayerFramework.location.locationTimeout")
        case .unknown:
            return i18n.localizedString(for: "SixLayerFramework.location.unknown")
        }
    }
}

// MARK: - Cross-Platform Location Service

/// Cross-platform location service implementation
/// Properly handles actor isolation for Swift 6 strict concurrency
@MainActor
public final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {

    /// Fixed coordinate for test / UI-test hosts — matches `MapViewExample` defaults.
    static let stubTestCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    // MARK: - Public Properties

    public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public private(set) var isLocationEnabled: Bool = false
    public private(set) var error: Error?

    // MARK: - Private Properties

    private let locationManager: CLLocationManager
    private var authorizationContinuation: CheckedContinuation<Void, Error>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var locationServicesEnabled: Bool?

    // MARK: - Initialization

    public override init() {
        self.locationManager = CLLocationManager()
        super.init()

        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
        updateLocationEnabledStatus()
        refreshLocationServicesEnabledStatus()
    }

    // MARK: - LocationServiceProtocol Implementation

    public func requestAuthorization() async throws {
        if Self.shouldSkipRealLocationServices() {
            applySyntheticAuthorizationForTesting()
            return
        }

        // Check if we can request authorization
        let servicesEnabled = await Self.checkLocationServicesEnabled()
        locationServicesEnabled = servicesEnabled
        updateLocationEnabledStatus()
        guard servicesEnabled else {
            throw LocationServiceError.servicesDisabled
        }

        // Request authorization (platform-specific)
        #if os(iOS)
        locationManager.requestWhenInUseAuthorization()
        #elseif os(macOS)
        locationManager.requestAlwaysAuthorization()
        #else
        // Other platforms may not support location services
        throw LocationServiceError.servicesDisabled
        #endif

        // Wait for authorization response
        try await withCheckedThrowingContinuation { continuation in
            self.authorizationContinuation = continuation

            // Set a timeout in case the user doesn't respond
            // In test mode, use a shorter timeout to prevent test hangs
            let timeoutNanoseconds: UInt64 = Self.isTestMode ? 1_000_000_000 : 30_000_000_000 // 1 second in tests, 30 seconds in production
            
            Task {
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
                if let continuation = self.authorizationContinuation {
                    self.authorizationContinuation = nil
                    continuation.resume(throwing: LocationServiceError.authorizationTimeout)
                }
            }
        }
    }

    public func startUpdatingLocation() {
        if Self.shouldSkipRealLocationServices() {
            return
        }

        // Check authorization status (platform-specific)
        guard hasLocationAuthorization else {
            error = LocationServiceError.unauthorized
            return
        }

        if locationServicesEnabled == false {
            error = LocationServiceError.servicesDisabled
            return
        }

        #if os(iOS) || os(macOS)
        locationManager.startUpdatingLocation()
        #endif
    }

    public func stopUpdatingLocation() {
        #if os(iOS) || os(macOS)
        locationManager.stopUpdatingLocation()
        #endif
    }

    public func getCurrentLocation() async throws -> CLLocation {
        if Self.shouldSkipRealLocationServices() {
            if !hasLocationAuthorization {
                applySyntheticAuthorizationForTesting()
            }
            return Self.stubLocationForTesting()
        }

        // Check authorization status (platform-specific)
        guard hasLocationAuthorization else {
            throw LocationServiceError.unauthorized
        }

        let servicesEnabled = await Self.checkLocationServicesEnabled()
        locationServicesEnabled = servicesEnabled
        updateLocationEnabledStatus()
        guard servicesEnabled else {
            throw LocationServiceError.servicesDisabled
        }

        #if os(iOS) || os(macOS)
        // Start location updates temporarily
        locationManager.startUpdatingLocation()
        #else
        throw LocationServiceError.servicesDisabled
        #endif

        // Wait for a location update
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation

            // Set a timeout
            // In test mode, use a shorter timeout to prevent test hangs
            let timeoutNanoseconds: UInt64 = Self.isTestMode ? 1_000_000_000 : 10_000_000_000 // 1 second in tests, 10 seconds in production
            
            Task {
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
                if let continuation = self.locationContinuation {
                    self.locationContinuation = nil
                    continuation.resume(throwing: LocationServiceError.locationTimeout)
                }
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            refreshLocationServicesEnabledStatus()

            // Resume authorization continuation if waiting
            if let continuation = authorizationContinuation {
                authorizationContinuation = nil
                switch authorizationStatus {
                case .authorizedAlways:
                    continuation.resume()
                #if os(iOS)
                case .authorizedWhenInUse:
                    continuation.resume()
                #endif
                case .denied:
                    continuation.resume(throwing: LocationServiceError.denied)
                case .restricted:
                    continuation.resume(throwing: LocationServiceError.restricted)
                case .notDetermined:
                    // Still waiting
                    break
                @unknown default:
                    continuation.resume(throwing: LocationServiceError.unknown)
                }
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            // Resume location continuation if waiting
            if let continuation = locationContinuation, let location = locations.last {
                locationContinuation = nil
                locationManager.stopUpdatingLocation()
                continuation.resume(returning: location)
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error

            // Resume continuations with error
            if let continuation = authorizationContinuation {
                authorizationContinuation = nil
                continuation.resume(throwing: error)
            }

            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Private Methods

    /// Skip CoreLocation permission prompts in XCTest, XCUITest hosts, and the framework test app.
    private static func shouldSkipRealLocationServices() -> Bool {
        // XCUITest host: XCTest runs out-of-process; env vars are unset, but the driver passes these.
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            return true
        }
        if ProcessInfo.processInfo.environment["XCUI_TESTING"] == "1" {
            return true
        }
        if isInProcessTestEnvironment {
            return true
        }
        // Manual TestApp runs (Product → Run) and CI hosts without entitlements / stable TCC.
        if Bundle.main.bundleIdentifier == "com.sixlayer.framework.test-app" {
            return true
        }
        return false
    }

    private static var isInProcessTestEnvironment: Bool {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["XCTestConfigurationFilePath"] != nil ||
           environment["XCTestSessionIdentifier"] != nil ||
           environment["XCTestBundlePath"] != nil ||
           NSClassFromString("XCTestCase") != nil {
            return true
        }
        if NSClassFromString("Testing.Test") != nil {
            return true
        }
        return TestingCapabilityDetection.isTestingMode
        #else
        return false
        #endif
    }

    private static var isTestMode: Bool {
        shouldSkipRealLocationServices()
    }

    private func applySyntheticAuthorizationForTesting() {
        #if os(iOS)
        authorizationStatus = .authorizedWhenInUse
        #elseif os(macOS)
        authorizationStatus = .authorizedAlways
        #endif
        locationServicesEnabled = true
        updateLocationEnabledStatus()
    }

    private static func stubLocationForTesting() -> CLLocation {
        CLLocation(
            coordinate: stubTestCoordinate,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
    }

    private var hasLocationAuthorization: Bool {
        #if os(iOS)
        return authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
        #elseif os(macOS)
        return authorizationStatus == .authorizedAlways || authorizationStatus == .authorized
        #else
        return false
        #endif
    }

    /// Runs the potentially blocking CoreLocation services check away from the main actor.
    nonisolated private static func checkLocationServicesEnabled() async -> Bool {
        #if os(iOS) || os(macOS)
        return await Task.detached(priority: .utility) {
            CLLocationManager.locationServicesEnabled()
        }.value
        #else
        return false
        #endif
    }

    private func updateLocationEnabledStatus() {
        isLocationEnabled = hasLocationAuthorization && (locationServicesEnabled ?? false)
    }

    private func refreshLocationServicesEnabledStatus() {
        Task { @MainActor [weak self] in
            let servicesEnabled = await Self.checkLocationServicesEnabled()
            self?.locationServicesEnabled = servicesEnabled
            self?.updateLocationEnabledStatus()
        }
    }
}

// MARK: - Thread Safety

// LocationService is marked @MainActor and implements proper async/await patterns,
// making it safe to use within the main actor context

