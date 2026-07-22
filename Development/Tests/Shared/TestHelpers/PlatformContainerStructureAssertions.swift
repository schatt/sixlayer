//
//  PlatformContainerStructureAssertions.swift
//  SixLayerFrameworkTests
//
//  Cross-platform structural checks for container APIs where ViewInspector may be absent (#219).
//  Prefers ViewInspector when linked; falls back to UIKit subtree heuristics on tvOS/visionOS/iOS.
//

import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Cheap, truthful structural assertions for platform container helpers (Issue #219).
public enum PlatformContainerStructureAssertions {

    // MARK: - Public API

    /// Returns whether `view` hosts a SwiftUI `Form` (directly or via `platformFormContainer`).
    @MainActor
    public static func containsForm<V: View>(_ view: V) -> Bool {
        // Deliberate stub for #219 red: always false until green implementation.
        false
    }

    /// Returns whether `view` contains a SwiftUI `Section`.
    @MainActor
    public static func containsSection<V: View>(_ view: V) -> Bool {
        // Deliberate stub for #219 red: always false until green implementation.
        false
    }

    /// Returns whether `view` contains a SwiftUI `VStack` and no `Section`.
    @MainActor
    public static func containsVStackWithoutSection<V: View>(_ view: V) -> Bool {
        // Deliberate stub for #219 red: always false until green implementation.
        false
    }
}
