//
//  PlatformMapComponentsLayer4.swift
//  SixLayerFramework
//
//  Layer 4: Component - Platform Map Components
//
//  This layer provides platform-aware UI components for displaying maps and locations.
//  Uses the modern SwiftUI Map API with Annotation (iOS 17+, macOS 14+).
//

import SwiftUI
import CoreLocation
#if canImport(MapKit)
import MapKit
#endif

/// Layer 4: Component - Platform Map Components
///
/// This layer provides platform-aware UI components specifically designed for displaying maps
/// and geographic data. It uses the modern SwiftUI Map API with Annotation.
///
/// Note: MapCameraPosition and MapContent are SwiftUI types that require iOS 17+ / macOS 14+
/// Since our minimum macOS version is 15, these types are always available
#if os(iOS) || os(macOS)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public enum PlatformMapComponentsLayer4 {
    
    // MARK: - Map View Components
    
    /// Creates a platform-specific map view
    /// Uses modern SwiftUI Map API with Annotation (iOS 17+, macOS 14+)
    /// Falls back gracefully on unsupported platforms
    /// Note: Requires @MainActor because Map is a View
    @ViewBuilder
    @MainActor
    public static func platformMapView_L4(
        position: Binding<MapCameraPosition>,
        @MapContentBuilder content: () -> some MapContent
    ) -> some View {
        #if os(iOS) || os(macOS)
        // Use modern SwiftUI Map API (requires iOS 17+, macOS 14+)
        // Since minimum macOS is 15, Map types are always available
        Map(position: position) {
            content()
        }
        .automaticCompliance(named: "platformMapView_L4")
        #else
        // MapKit not available - provide fallback UI
        UnsupportedPlatformMapView()
            .automaticCompliance(named: "platformMapView_L4")
        #endif
    }
    
    /// Creates a platform-specific map view with annotations
    /// Convenience method that wraps annotations in MapContentBuilder
    /// Note: Requires @MainActor because Map is a View
    @ViewBuilder
    @MainActor
    public static func platformMapView_L4(
        position: Binding<MapCameraPosition>,
        annotations: [MapAnnotationData],
        onAnnotationTapped: ((MapAnnotationData) -> Void)? = nil
    ) -> some View {
        #if os(iOS) || os(macOS)
        // Use modern SwiftUI Map API (requires iOS 17+, macOS 14+)
        Map(position: position) {
            ForEach(annotations) { annotation in
                Annotation(annotation.title, coordinate: annotation.coordinate) {
                    annotation.content
                        .onTapGesture {
                            onAnnotationTapped?(annotation)
                        }
                }
            }
        }
        .automaticCompliance(named: "platformMapView_L4")
        #else
        // MapKit not available
        UnsupportedPlatformMapView()
            .automaticCompliance(named: "platformMapView_L4")
        #endif
    }
    
    // MARK: - LocationService Integration
    
    /// Creates a map view that automatically centers on the user's current location
    /// Integrates with LocationService to get and display current location
    /// Note: Requires @MainActor because MapViewWithLocationService is a View
    @ViewBuilder
    @MainActor
    public static func platformMapViewWithCurrentLocation_L4(
        locationService: LocationService,
        showCurrentLocation: Bool = true,
        additionalAnnotations: [MapAnnotationData] = [],
        onAnnotationTapped: ((MapAnnotationData) -> Void)? = nil
    ) -> some View {
        MapViewWithLocationService(
            locationService: locationService,
            showCurrentLocation: showCurrentLocation,
            additionalAnnotations: additionalAnnotations,
            onAnnotationTapped: onAnnotationTapped
        )
        .automaticCompliance(named: "platformMapViewWithCurrentLocation_L4")
    }
}
#endif

// MARK: - Supporting Types

/// Cross-platform map annotation data
#if os(iOS) || os(macOS)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#endif
public struct MapAnnotationData: Identifiable {
    public let id = UUID()
    public let title: String
    public let coordinate: CLLocationCoordinate2D
    public let content: AnyView
    
    public init(title: String, coordinate: CLLocationCoordinate2D, content: some View) {
        self.title = title
        self.coordinate = coordinate
        self.content = AnyView(content)
    }
}

// Note: Legacy support for iOS 16/macOS 13 is not provided
// This component requires iOS 17+ / macOS 14+ for the modern Map API
// If you need support for older versions, consider using the deprecated MapAnnotation API
// or provide a custom implementation

// MARK: - LocationService Integration View

#if os(iOS) || os(macOS)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private struct MapViewWithLocationService: View {
    let locationService: LocationService
    let showCurrentLocation: Bool
    let additionalAnnotations: [MapAnnotationData]
    let onAnnotationTapped: ((MapAnnotationData) -> Void)?
    
    @State private var position: MapCameraPosition = .automatic
    @State private var currentLocation: CLLocation?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    var body: some View {
        Group {
            if isLoading {
                let i18n = InternationalizationService()
                ProgressView(i18n.localizedString(for: "SixLayerFramework.status.loadingLocation"))
            } else if let error = errorMessage {
                platformVStackContainer(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                platformMapView_L4(position: $position, annotations: allAnnotations, onAnnotationTapped: onAnnotationTapped)
            }
        }
        .task {
            await loadCurrentLocation()
        }
        .onChange(of: currentLocation) {
            updateCameraPosition()
        }
        .automaticCompliance(named: "MapViewWithLocationService")
    }
    
    private var allAnnotations: [MapAnnotationData] {
        var annotations = additionalAnnotations
        
        if showCurrentLocation, let location = currentLocation {
            let currentLocationAnnotation = MapAnnotationData(
                title: "Current Location",
                coordinate: location.coordinate,
                content: Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            )
            annotations.insert(currentLocationAnnotation, at: 0)
        }
        
        return annotations
    }
    
    private func loadCurrentLocation() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Update authorization status
            await MainActor.run {
                authorizationStatus = locationService.authorizationStatus
            }
            
            // Request authorization if needed
            if authorizationStatus == .notDetermined {
                try await locationService.requestAuthorization()
                await MainActor.run {
                    authorizationStatus = locationService.authorizationStatus
                }
            }
            
            // Get current location
            let location = try await locationService.getCurrentLocation()
            await MainActor.run {
                currentLocation = location
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func updateCameraPosition() {
        guard let location = currentLocation else { return }
        
        #if canImport(MapKit)
        self.position = MapCameraPosition.region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
        #endif
    }
}
#endif

// MARK: - Unsupported Platform Fallback

private struct UnsupportedPlatformMapView: View {
    var body: some View {
        platformVStackContainer(spacing: 16) {
            Image(systemName: "map")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Map not available on this platform")
                .foregroundColor(.secondary)
        }
        .padding()
        .automaticCompliance(named: "UnsupportedPlatformMapView")
    }
}

// MARK: - Convenience Functions (Global)

#if os(iOS) || os(macOS)
/// Creates a platform-specific map view (convenience wrapper)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
/// Note: Requires @MainActor because it calls main-actor isolated methods
@ViewBuilder
@MainActor
public func platformMapView_L4(
    position: Binding<MapCameraPosition>,
    @MapContentBuilder content: () -> some MapContent
) -> some View {
    PlatformMapComponentsLayer4.platformMapView_L4(position: position, content: content)
}

/// Creates a platform-specific map view with annotations (convenience wrapper)
/// Note: Requires @MainActor because it calls main-actor isolated methods
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@ViewBuilder
@MainActor
public func platformMapView_L4(
    position: Binding<MapCameraPosition>,
    annotations: [MapAnnotationData],
    onAnnotationTapped: ((MapAnnotationData) -> Void)? = nil
) -> some View {
    PlatformMapComponentsLayer4.platformMapView_L4(
        position: position,
        annotations: annotations,
        onAnnotationTapped: onAnnotationTapped
    )
}

/// Creates a map view that automatically centers on the user's current location (convenience wrapper)
/// Note: Requires @MainActor because it calls main-actor isolated methods
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@ViewBuilder
@MainActor
public func platformMapViewWithCurrentLocation_L4(
    locationService: LocationService,
    showCurrentLocation: Bool = true,
    additionalAnnotations: [MapAnnotationData] = [],
    onAnnotationTapped: ((MapAnnotationData) -> Void)? = nil
) -> some View {
    PlatformMapComponentsLayer4.platformMapViewWithCurrentLocation_L4(
    locationService: locationService,
    showCurrentLocation: showCurrentLocation,
    additionalAnnotations: additionalAnnotations,
    onAnnotationTapped: onAnnotationTapped
    )
}
#endif

