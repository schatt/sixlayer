//
//  MapUsageExample.swift
//  SixLayerFramework
//
//  Example usage of the Platform Map Components Layer 4
//  Demonstrates modern SwiftUI Map API with Annotation
//

import SwiftUI
#if canImport(MapKit)
import MapKit
#endif
@testable import SixLayerFramework

/// Example: Basic map view with annotations
@available(iOS 17.0, macOS 14.0, *)
struct BasicMapExample: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    var body: some View {
        platformMapView_L4(position: $position) {
            Annotation("San Francisco", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    Text("SF")
                        .font(.caption)
                }
            }
        }
    }
}

/// Example: Map with selection binding (list ↔ marker sync via `.tag`)
@available(iOS 17.0, macOS 14.0, *)
struct SelectionBindingMapExample: View {
    @State private var position = MapCameraPosition.automatic
    @State private var selectedPlaceID: String?

    private let places: [(id: String, name: String, coordinate: CLLocationCoordinate2D)] = [
        ("gg", "Golden Gate Bridge", CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783)),
        ("al", "Alcatraz Island", CLLocationCoordinate2D(latitude: 37.8267, longitude: -122.4230)),
    ]

    var body: some View {
        platformMapView_L4(position: $position, selection: $selectedPlaceID) {
            ForEach(places, id: \.id) { place in
                Marker(place.name, coordinate: place.coordinate)
                    .tag(place.id)
            }
        }
    }
}

/// Example: Map with multiple annotations
@available(iOS 17.0, macOS 14.0, *)
struct MultipleAnnotationsMapExample: View {
    @State private var position = MapCameraPosition.automatic
    
    let annotations: [MapAnnotationData] = [
        MapAnnotationData(
            title: "Golden Gate Bridge",
            coordinate: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783),
            content: Image(systemName: "bridge.fill")
                .foregroundColor(.orange)
        ),
        MapAnnotationData(
            title: "Alcatraz Island",
            coordinate: CLLocationCoordinate2D(latitude: 37.8267, longitude: -122.4230),
            content: Image(systemName: "building.columns.fill")
                .foregroundColor(.blue)
        )
    ]
    
    var body: some View {
        platformMapView_L4(
            position: $position,
            annotations: annotations,
            onAnnotationTapped: { annotation in
                print("Tapped: \(annotation.title)")
            }
        )
    }
}

/// Example: Map with current location using LocationService
@available(iOS 17.0, macOS 14.0, *)
struct CurrentLocationMapExample: View {
    @StateObject private var locationService = LocationService()
    
    var body: some View {
        platformMapViewWithCurrentLocation_L4(
            locationService: locationService,
            showCurrentLocation: true,
            additionalAnnotations: [
                MapAnnotationData(
                    title: "Nearby Point",
                    coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                    content: Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                )
            ]
        )
        .onAppear {
            Task {
                // LocationService will automatically request permissions and load location
            }
        }
    }
}

/// Example: Custom annotation view
@available(iOS 17.0, macOS 14.0, *)
struct CustomAnnotationMapExample: View {
    @State private var position = MapCameraPosition.automatic
    
    var body: some View {
        platformMapView_L4(position: $position) {
            Annotation("Custom Location", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)) {
                VStack(spacing: 4) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                    Text("Custom")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                }
            }
        }
    }
}


