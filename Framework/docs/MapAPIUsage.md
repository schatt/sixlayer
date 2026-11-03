# Map API Usage Guide

## Modern SwiftUI Map API (iOS 17+)

**⚠️ Important**: The deprecated `MapAnnotation` API should not be used. Always use `Annotation` with `MapContentBuilder` instead.

### Deprecated API (Do Not Use)
```swift
// ❌ DEPRECATED - Do not use
Map(coordinateRegion: $region, annotationItems: locations) { location in
    MapAnnotation(coordinate: location.coordinate) {
        // Custom view
    }
}
```

### Modern API (Use This)
```swift
// ✅ CORRECT - Use Annotation with MapContentBuilder
import SwiftUI
import MapKit

struct MapView: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    let locations: [Location]
    
    var body: some View {
        Map(position: $position) {
            ForEach(locations) { location in
                Annotation(location.name, coordinate: location.coordinate) {
                    // Custom annotation view
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(location.name)
                            .font(.caption)
                    }
                }
            }
        }
    }
}
```

### Key Changes

1. **Map Initialization**:
   - Old: `Map(coordinateRegion:annotationItems:)`
   - New: `Map(position:)` with `MapCameraPosition`

2. **Annotations**:
   - Old: `MapAnnotation(coordinate:)`
   - New: `Annotation(title, coordinate:)` within `MapContentBuilder`

3. **Position Binding**:
   - Old: `@State private var region: MKCoordinateRegion`
   - New: `@State private var position: MapCameraPosition`

### Benefits of Modern API

- **Better Performance**: More efficient rendering
- **Enhanced Flexibility**: Better customization options
- **Future-Proof**: Aligned with latest SwiftUI developments
- **iOS 17+ Compatibility**: Required for modern iOS versions

### Platform Support

- **iOS**: 17.0+ ✅ Fully supported
- **macOS**: 14.0+ ✅ Supported (Note: Some testing frameworks may have conditional compilation issues)
- **tvOS**: 17.0+ ⚠️ Limited support
- **watchOS**: 10.0+ ⚠️ Limited support (consider using `WKInterfaceMap` from WatchKit instead)

### Cross-Platform Considerations

**⚠️ Important**: The SwiftUI `Map` API has significant cross-platform differences:

1. **macOS Considerations**:
   - SwiftUI `Map` is available on macOS 14.0+ (Sonoma) using the modern API with `Annotation`
   - The deprecated `MapAnnotation`, `MapMarker`, and `MapPin` types are available on macOS (since macOS 11.0)
   - **Verified**: All Map types (`MapAnnotation`, `MapMarker`, `MapPin`, `VideoPlayer`, `SignInWithAppleButton`) compile successfully on macOS SDK 26.2
   - ViewInspector Issue #405: Investigation shows build succeeds on macOS SDK 26.2. The issue may be related to:
     - Internal SwiftUI types (`_MapAnnotationData`, `_DefaultAnnotatedMapContent`) that ViewInspector relies on
     - Build configuration differences when ViewInspector is used as a dependency
     - Possible SDK version differences (26.0 vs 26.2)
   - For production code, use the modern `Map` API with `Annotation` which works on macOS 14.0+ with proper availability checks

2. **watchOS Limitations**:
   - SwiftUI `Map` is not natively supported on watchOS
   - Use `WKInterfaceMap` from WatchKit for map functionality on watchOS
   - Requires imperative approach rather than declarative SwiftUI

3. **tvOS Limitations**:
   - Limited SwiftUI Map support on tvOS
   - May require custom solutions or UIKit components

4. **Best Practices for Cross-Platform**:
   ```swift
   #if os(iOS)
   import MapKit
   import SwiftUI
   
   struct MapView: View {
       @State private var position = MapCameraPosition.region(...)
       
       var body: some View {
           Map(position: $position) {
               // Annotations
           }
       }
   }
   #elseif os(macOS)
   // Use AppKit/MapKit bridging or alternative implementation
   #elseif os(watchOS)
   // Use WKInterfaceMap from WatchKit
   #else
   // Platform not supported - provide fallback UI
   #endif
   ```

5. **Availability Checks**:
   ```swift
   if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
       // Use SwiftUI Map
   } else {
       // Fallback to platform-specific map implementations
   }
   ```

## Framework Integration

The SixLayer Framework provides `PlatformMapComponentsLayer4` for cross-platform map support:

### Basic Usage

```swift
import SixLayerFramework
import MapKit

struct MyMapView: View {
    @State private var position = MapCameraPosition.automatic
    
    var body: some View {
        platformMapView_L4(position: $position) {
            Annotation("Location", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)) {
                Image(systemName: "mappin.circle.fill")
            }
        }
    }
}
```

### With Annotations Array

```swift
let annotations = [
    MapAnnotationData(
        title: "Point 1",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        content: Image(systemName: "mappin")
    )
]

platformMapView_L4(position: $position, annotations: annotations)
```

### With Selection Binding

Use the selection overload to sync list ↔ marker selection the same way as raw `Map(position:selection:)`. Tag markers (or annotations) with a `Hashable` value:

```swift
@State private var position = MapCameraPosition.automatic
@State private var selectedPlaceID: String?

platformMapView_L4(position: $position, selection: $selectedPlaceID) {
    ForEach(places) { place in
        Marker(place.name, coordinate: place.coordinate)
            .tag(place.id)
    }
}
```

Existing position-only and annotations overloads are unchanged.

### With LocationService Integration

```swift
@StateObject private var locationService = LocationService()

platformMapViewWithCurrentLocation_L4(
    locationService: locationService,
    showCurrentLocation: true
)
```

### Examples

See `Framework/Examples/MapUsageExample.swift` for complete examples.

### References

- [Apple Documentation: Map](https://developer.apple.com/documentation/mapkit/map)
- [Apple Documentation: Annotation](https://developer.apple.com/documentation/mapkit/annotation)
- [Apple Documentation: MapCameraPosition](https://developer.apple.com/documentation/mapkit/mapcameraposition)

