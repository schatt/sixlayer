//
//  UITestHostLandMarker.swift
//  SixLayerFrameworkUITests
//
//  Stable XCUI deep-link land markers for TestApp hosts.
//
//  Prefer a leaf Text with a direct `accessibilityIdentifier` (same pattern as CatA
//  `sectionMarker`). Host-sentinel `.exactNamed` → `Color.clear` + `.ignore` is a poor
//  first-paint wait target on macOS XCUI (#370): shared-launch suites fail the first
//  `waitForHostRootIdentifier` then pass later methods that query other ids.
//

import SwiftUI

/// Leaf land marker for XCUI deep-link readiness (`waitForHostRootIdentifier`).
func uiTestHostLandMarker(_ identifier: String, title: String) -> some View {
    Text(title)
        .font(.headline)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(title)
}
