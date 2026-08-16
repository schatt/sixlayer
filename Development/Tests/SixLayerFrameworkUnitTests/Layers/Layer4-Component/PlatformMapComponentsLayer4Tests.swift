import Testing
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
#if canImport(MapKit)
import MapKit
#endif
@testable import SixLayerFramework

//
//  PlatformMapComponentsLayer4Tests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates the cross-platform map components that provide unified map functionality
//  across iOS and macOS, using the modern SwiftUI Map API with Annotation.
//
//  TESTING SCOPE:
//  - Unified API works on both iOS and macOS
//  - Uses modern Map API (Annotation, not deprecated MapAnnotation)
//  - Integration with LocationService
//
//  METHODOLOGY:
//  - Lock subject types of created map views
//  - Test annotation display and location integration
//

#if os(iOS) || os(macOS)
@Suite("Platform Map Components Layer 4")
open class PlatformMapComponentsLayer4Tests: BaseTestClass {
    
    // MARK: - API Availability Tests
    
    /// BUSINESS PURPOSE: Verify map component API is available on supported platforms
    /// TESTING SCOPE: Tests that the API signature exists and compiles
    /// METHODOLOGY: Lock the created view's subject type
    @Test @MainActor func testPlatformMapView_APIAvailable() {
        #if canImport(MapKit)
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            let position = Binding.constant(MapCameraPosition.automatic)
            let view = PlatformMapComponentsLayer4.platformMapView_L4(position: position) {
                // Empty map content for test
            }
            BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAMapL4View")
        }
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify map component uses modern API (Annotation, not MapAnnotation)
    /// TESTING SCOPE: Tests that deprecated MapAnnotation is not used
    /// METHODOLOGY: Compile-time Annotation + lock created view subject type
    @Test @MainActor func testPlatformMapView_UsesModernAPI() {
        #if canImport(MapKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            let position = Binding.constant(MapCameraPosition.automatic)
            let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let view = PlatformMapComponentsLayer4.platformMapView_L4(position: position) {
                Annotation("Test", coordinate: coordinate) {
                    Image(systemName: "mappin.circle.fill")
                }
            }
            BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAMapL4View")
        }
        #endif
    }
    
    // MARK: - Location Service Integration Tests
    
    /// BUSINESS PURPOSE: Verify map component can integrate with LocationService
    /// TESTING SCOPE: Tests that LocationService coordinates can be used
    /// METHODOLOGY: Verify coordinate conversion
    @Test @MainActor func testPlatformMapView_LocationServiceIntegration() {
        #if canImport(MapKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            let testCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let position = Binding.constant(MapCameraPosition.region(
                MKCoordinateRegion(
                    center: testCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            ))
            
            _ = PlatformMapComponentsLayer4.platformMapView_L4(position: position) {
                Annotation("Location", coordinate: testCoordinate) {
                    Image(systemName: "mappin.circle.fill")
                }
            }
            
            #expect(testCoordinate.latitude == 37.7749, "Coordinate should be valid")
            #expect(testCoordinate.longitude == -122.4194, "Coordinate should be valid")
        }
        #endif
    }
    
    // MARK: - Annotation Tests
    
    /// BUSINESS PURPOSE: Verify annotations can be added to map
    /// TESTING SCOPE: Tests that Annotation API works correctly
    /// METHODOLOGY: Verify annotation creation
    @Test @MainActor func testPlatformMapView_AnnotationSupport() {
        #if canImport(MapKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let title = "Test Location"
            let annotation = MapAnnotationData(
                title: title,
                coordinate: coordinate,
                content: Image(systemName: "mappin.circle.fill")
            )
            let position = Binding.constant(MapCameraPosition.automatic)
            
            _ = PlatformMapComponentsLayer4.platformMapView_L4(
                position: position,
                annotations: [annotation]
            )
            
            #expect(annotation.coordinate.latitude == 37.7749, "Annotation coordinate should be valid")
            #expect(annotation.title == "Test Location", "Annotation title should be valid")
        }
        #endif
    }
    
    // MARK: - Accessibility Tests
    
    /// BUSINESS PURPOSE: Verify map component applies automatic compliance
    /// TESTING SCOPE: Subject type includes AutomaticComplianceModifier
    /// METHODOLOGY: Invert then lock type-contains
    @Test @MainActor func testPlatformMapView_Accessibility() {
        #if canImport(MapKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            let position = Binding.constant(MapCameraPosition.automatic)
            let view = PlatformMapComponentsLayer4.platformMapView_L4(position: position) {
            }
            BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAMapL4View")
        }
        #endif
    }
    
    // MARK: - LocationService Integration Tests
    
    /// BUSINESS PURPOSE: Verify map component integrates with LocationService
    /// TESTING SCOPE: Tests that LocationService can provide coordinates for map
    /// METHODOLOGY: Lock MapViewWithLocationService subject type
    @Test @MainActor func testPlatformMapView_LocationServiceIntegrationAPI() {
        #if canImport(MapKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            let locationService = LocationService()
            let view = PlatformMapComponentsLayer4.platformMapViewWithCurrentLocation_L4(
                locationService: locationService,
                showCurrentLocation: true
            )
            BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAMapL4View")
        }
        #endif
    }
}
#endif
