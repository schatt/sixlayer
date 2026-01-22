//
//  PickerShadow.swift
//  SixLayerFramework
//
//  Shadow file to catch all direct Picker() calls in DEBUG builds
//  This forces us to use platformPicker() instead, ensuring consistent
//  accessibility identifier application (Issue #163)
//

import SwiftUI

#if DEBUG
// Shadow typealias to catch direct Picker() calls
// Forces use of platformPicker() instead for consistent accessibility (Issue #163)
// This prevents direct SwiftUI.Picker() calls and ensures platformPicker() is used
typealias Picker = DirectPickerCallForbidden_UsePlatformPickerInstead
#endif

/// Marker type to prevent direct Picker() calls
/// Use platformPicker() instead for automatic accessibility identifier application
enum DirectPickerCallForbidden_UsePlatformPickerInstead {
    // This type cannot be instantiated - it's only used as a typealias target
    // to catch direct Picker() calls at compile time
}
