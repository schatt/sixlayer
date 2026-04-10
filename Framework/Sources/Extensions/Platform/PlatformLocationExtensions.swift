//
//  PlatformLocationExtensions.swift
//  SixLayerFramework
//
//  Cross-platform location services extensions
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Cross-Platform Location Extensions

public extension CLAuthorizationStatus {
    /// Maps `CLAuthorizationStatus` to `PlatformLocationAuthorizationStatus` without referencing
    /// platform-only cases (e.g. `.authorizedWhenInUse` on iOS vs `.authorized` on macOS) at call sites.
    var platformLocationAuthorizationStatus: PlatformLocationAuthorizationStatus {
        #if os(iOS)
        switch self {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorizedWhenInUse:
            return .authorizedWhenInUse
        case .authorizedAlways:
            return .authorizedAlways
        @unknown default:
            return .notDetermined
        }
        #elseif os(macOS)
        switch self {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorized:
            return .authorized
        case .authorizedAlways:
            return .authorizedAlways
        @unknown default:
            return .notDetermined
        }
        #else
        return .notDetermined
        #endif
    }
}

public extension CLLocationManager {
    /// Cross-platform authorization status check
    var platformAuthorizationStatus: PlatformLocationAuthorizationStatus {
        authorizationStatus.platformLocationAuthorizationStatus
    }
}
