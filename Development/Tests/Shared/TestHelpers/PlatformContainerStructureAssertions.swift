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
        #if canImport(ViewInspector)
        if let found = withInspectedView(AnyView(view), perform: { inspected in
            inspected.findAll(ViewType.Form.self).isEmpty ? nil : true
        }) {
            return found
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        return hostedSubtreeIndicatesSwiftUIForm(view)
        #else
        return false
        #endif
    }

    /// Returns whether `view` contains a SwiftUI `Section`.
    @MainActor
    public static func containsSection<V: View>(_ view: V) -> Bool {
        #if canImport(ViewInspector)
        if let found = withInspectedView(AnyView(view), perform: { inspected in
            inspected.findAll(ViewType.Section.self).isEmpty ? nil : true
        }) {
            return found
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        return hostedSubtreeIndicatesSwiftUISection(view)
        #else
        return false
        #endif
    }

    /// Returns whether `view` contains a SwiftUI `VStack` and no `Section`.
    @MainActor
    public static func containsVStackWithoutSection<V: View>(_ view: V) -> Bool {
        #if canImport(ViewInspector)
        if let result = withInspectedView(AnyView(view), perform: { inspected -> Bool? in
            let hasSection = !inspected.findAll(ViewType.Section.self).isEmpty
            let hasVStack = !inspected.findAll(ViewType.VStack.self).isEmpty
            return (!hasSection && hasVStack) ? true : nil
        }) {
            return result
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        return hostedSubtreeIndicatesInsetVStackWithoutSection(view)
        #else
        return false
        #endif
    }

    // MARK: - UIKit fallback (visionOS and when ViewInspector traversal fails)

    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    private static func hostedSubtreeIndicatesSwiftUIForm<V: View>(_ view: V) -> Bool {
        guard let root = TestSetupUtilities.hostRootPlatformView(view) as? UIView else { return false }
        return uiViewSubtree(root) { typeName in
            typeName.contains("List") || typeName.contains("Form") || typeName.contains("CollectionView")
        }
    }

    @MainActor
    private static func hostedSubtreeIndicatesSwiftUISection<V: View>(_ view: V) -> Bool {
        guard let root = TestSetupUtilities.hostRootPlatformView(view) as? UIView else { return false }
        return uiViewSubtree(root) { typeName in
            typeName.contains("Section") || typeName.contains("ListSection")
        }
    }

    @MainActor
    private static func hostedSubtreeIndicatesInsetVStackWithoutSection<V: View>(_ view: V) -> Bool {
        guard let root = TestSetupUtilities.hostRootPlatformView(view) as? UIView else { return false }
        let hasSection = uiViewSubtree(root) { typeName in
            typeName.contains("Section") || typeName.contains("ListSection")
        }
        guard !hasSection else { return false }
        return uiViewSubtree(root) { typeName in
            typeName.contains("Stack") || typeName.contains("Layout")
        }
    }

    private static func uiViewSubtree(_ view: UIView, matches: (String) -> Bool) -> Bool {
        let typeName = String(describing: type(of: view))
        if matches(typeName) { return true }
        return view.subviews.contains { uiViewSubtree($0, matches: matches) }
    }
    #endif
}
