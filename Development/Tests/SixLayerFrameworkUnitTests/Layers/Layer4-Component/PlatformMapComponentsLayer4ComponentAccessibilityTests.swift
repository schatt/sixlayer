//
//  PlatformMapComponentsLayer4ComponentAccessibilityTests.swift
//  SixLayerFrameworkUnitTests
//
//  Accessibility tests for Layer 4 Map platform*_L4 components.
//  Issue #169: Complete accessibility for Layer 4 platform* methods.
//

import Testing
import SwiftUI
#if canImport(MapKit)
import MapKit
#endif
@testable import SixLayerFramework

@Suite("Platform Map Components Layer 4 Accessibility")
open class PlatformMapComponentsLayer4ComponentAccessibilityTests: BaseTestClass {

#if canImport(MapKit)
    @Test @MainActor func testPlatformMapViewL4GeneratesAccessibilityIdentifiers() async {
        if #available(iOS 17.0, macOS 14.0, *) {
            let position = Binding.constant(MapCameraPosition.automatic)
            let view = PlatformMapComponentsLayer4.platformMapView_L4(position: position, annotations: [])
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "platformMapView_L4"
            )
            #expect(hasAccessibilityID, "platformMapView_L4 should generate accessibility identifiers")
        }
    }

    @Test @MainActor func testPlatformMapViewWithCurrentLocationL4GeneratesAccessibilityIdentifiers() async {
        if #available(iOS 17.0, macOS 14.0, *) {
            let locationService = LocationService()
            let view = PlatformMapComponentsLayer4.platformMapViewWithCurrentLocation_L4(
                locationService: locationService,
                showCurrentLocation: true
            )
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "platformMapViewWithCurrentLocation_L4"
            )
            #expect(hasAccessibilityID, "platformMapViewWithCurrentLocation_L4 should generate accessibility identifiers")
        }
    }
#endif
}
