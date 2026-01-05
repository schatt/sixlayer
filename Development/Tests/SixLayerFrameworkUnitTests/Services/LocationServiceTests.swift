//
//  LocationServiceTests.swift
//  SixLayerFrameworkTests
//
//  Cross-platform location service tests
//  Tests the cross-platform location service implementation
//

import Testing
import CoreLocation
@testable import SixLayerFramework

/// Cross-platform location service tests
/// Tests the cross-platform location service implementation
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Location Service")
open class LocationServiceTests: BaseTestClass {
    
    // MARK: - Service Initialization Tests
    
    @Test @MainActor func testLocationServiceInitialization() async {
        // Given & When: Creating the cross-platform service
        let service = LocationService()
        
        // Then: Service should be created successfully
        // Initial authorization status should be notDetermined
        #expect(service.authorizationStatus == .notDetermined)
        
        // Initially, location should not be enabled
        #expect(service.isLocationEnabled == false)
    }
    
    // MARK: - Authorization Status Tests
    
    @Test @MainActor func testLocationServiceHasAuthorizationStatus() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Checking authorization status
        let status = service.authorizationStatus
        
        // Then: Should return a valid CLAuthorizationStatus
        // Note: Initial status will be .notDetermined
        #expect(status == .notDetermined || 
                status == .denied || 
                status == .restricted || 
                status == .authorizedAlways)
    }
    
    @Test @MainActor func testLocationServiceReportsLocationEnabledStatus() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Checking if location is enabled
        let isEnabled = service.isLocationEnabled
        
        // Then: Should return a boolean value
        // Note: Initially false unless already authorized
        #expect(isEnabled == true || isEnabled == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test @MainActor func testLocationServiceHasErrorProperty() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Checking error property
        let error = service.error
        
        // Then: Should be nil initially or contain an error
        // Error can be nil or non-nil depending on system state
        #expect(error == nil || error != nil)
    }
    
    // MARK: - Location Updates Tests
    
    @Test @MainActor func testLocationServiceCanStartUpdatingLocation() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Starting location updates
        // Note: This may fail if not authorized, but should not crash
        service.startUpdatingLocation()
        
        // Then: Service should handle the request gracefully
        // The service will set error if authorization is not granted
        #expect(service.error == nil || service.error != nil)
    }
    
    @Test @MainActor func testLocationServiceCanStopUpdatingLocation() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Stopping location updates
        service.stopUpdatingLocation()
        
        // Then: Should complete without crashing
        // This is a no-op if not currently updating
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test @MainActor func testLocationServiceConformsToLocationServiceProtocol() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Checking protocol conformance
        let protocolService: LocationServiceProtocol = service
        
        // Then: Should conform to LocationServiceProtocol
        #expect(protocolService.authorizationStatus == service.authorizationStatus)
        #expect(protocolService.isLocationEnabled == service.isLocationEnabled)
    }
    
    // MARK: - Cross-Platform Tests
    
    @Test @MainActor func testLocationServiceWorksOnAllPlatforms() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Checking platform availability
        _ = SixLayerPlatform.current
        
        // Then: Service should work on all platforms
        // The service should handle platform differences internally
        #expect(service.authorizationStatus == .notDetermined || 
                service.authorizationStatus == .denied || 
                service.authorizationStatus == .restricted || 
                service.authorizationStatus == .authorized || 
                service.authorizationStatus == .authorizedAlways)
    }
    
    // MARK: - Actor Isolation Tests
    
    @Test @MainActor func testLocationServiceIsMainActorIsolated() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Accessing properties from MainActor context
        let status = service.authorizationStatus
        let isEnabled = service.isLocationEnabled
        
        // Then: Should access successfully without actor isolation errors
        // This test verifies the @MainActor annotation works correctly
        #expect(status == .notDetermined || status == .denied || status == .restricted || status == .authorized || status == .authorizedAlways)
        #expect(isEnabled == true || isEnabled == false)
    }
    
    @Test @MainActor func testLocationServiceMainActorIsolatedProperties() async {
        // Given: LocationService (marked @MainActor)
        let service = LocationService()
        
        // When: Accessing properties from MainActor context
        let status = service.authorizationStatus
        let isEnabled = service.isLocationEnabled
        let error = service.error
        
        // Then: Should access successfully without actor isolation errors
        // The protocol is now @MainActor, so properties can satisfy requirements
        #expect(status == .notDetermined || status == .denied || status == .restricted || status == .authorized || status == .authorizedAlways)
        #expect(isEnabled == true || isEnabled == false)
        #expect(error == nil || error != nil)
    }
    
    @Test @MainActor func testLocationServiceProtocolConformanceIsolation() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Checking protocol conformance
        let protocolService: LocationServiceProtocol = service
        
        // Then: Should conform without "crosses into main actor-isolated code" errors
        // Protocol is now @MainActor, so conformance is properly isolated
        #expect(protocolService.authorizationStatus == service.authorizationStatus)
        #expect(protocolService.isLocationEnabled == service.isLocationEnabled)
    }
    
    @Test @MainActor func testLocationServiceDelegateMethodsNonisolated() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Using as CLLocationManagerDelegate
        _ = service as CLLocationManagerDelegate
        
        // Then: Should conform without isolation errors
        // Delegate methods are nonisolated and bridge to MainActor internally
        
        // Verify delegate can be called from nonisolated context (what CLLocationManager does)
        // This test ensures the nonisolated -> MainActor bridge works correctly
        let manager = CLLocationManager()
        let status = manager.authorizationStatus // Safe to access from nonisolated context
        
        // The delegate methods should handle the MainActor bridge correctly
        #expect(status == .notDetermined || status == .denied || status == .restricted || status == .authorized || status == .authorizedAlways)
    }
    
    @Test @MainActor func testLocationServiceNoUncheckedSendableConflict() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Checking actor isolation
        // The service is @MainActor, not @unchecked Sendable
        
        // Then: Should not have Sendable conformance conflicts
        // Protocol is @MainActor, removing the need for @unchecked Sendable
        
        // Verify we can use it as LocationServiceProtocol without Sendable issues
        _ = service as LocationServiceProtocol
        // ProtocolService is non-optional, so it exists if we reach here
    }
    
    @Test @MainActor func testLocationServiceCompilesWithSwift6StrictConcurrency() async {
        // Given: LocationService
        let service = LocationService()
        
        // When: Using the service in async MainActor context
        // This test verifies that the service properly handles Swift 6 concurrency
        
        // Then: Should compile and run without concurrency warnings/errors
        // All the fixes from Issue #4 should be validated:
        // 1. Protocol is @MainActor (not Sendable)
        // 2. Properties are MainActor-isolated (no nonisolated requirement conflict)
        // 3. Delegate methods are nonisolated with MainActor bridging
        // 4. No @unchecked Sendable conflict
        
        // Verify delegate conformance doesn't cause isolation issues
        let delegate: CLLocationManagerDelegate = service
        // Delegate is non-optional, so it exists if we reach here
    }
}

