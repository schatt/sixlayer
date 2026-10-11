//
//  PlatformContainerStructureAssertions.swift
//  SixLayerFrameworkTests
//
//  Cross-platform structural checks for container APIs where ViewInspector may be absent (#219).
//  Prefers ViewInspector when linked; falls back to UIKit subtree heuristics on tvOS/visionOS/iOS.
//  watchOS cannot host: observe* returns `.unavailable` instead of a false absence (#379).
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

    /// Hosting or type-name result. `.unavailable` means this lane did not look
    /// (watchOS has no hosting controller — #379). That is not an observed `false`.
    public enum ContainerStructureObservation: Equatable {
        case observed(Bool)
        case unavailable
    }

    // MARK: - Public API

    /// Hostability for this lane. watchOS unit tests have no hosting controller, so the
    /// result is `.unavailable` rather than a false "not hostable" (#379).
    @MainActor
    public static func observeHostability<V: View>(_ view: V) -> ContainerStructureObservation {
        #if os(watchOS)
        return .unavailable
        #else
        return .observed(isHostable(view))
        #endif
    }

    /// `Form` presence. On watchOS a root type-name hit is `.observed(true)`; a miss is
    /// `.unavailable` because this lane cannot walk a hosted subtree (#379).
    @MainActor
    public static func observeContainsForm<V: View>(_ view: V) -> ContainerStructureObservation {
        #if os(watchOS)
        return watchTypeNameObservation(view, presentToken: "Form<")
        #else
        return .observed(containsForm(view))
        #endif
    }

    /// `Section` presence. Same watchOS rule as `observeContainsForm` (#379).
    @MainActor
    public static func observeContainsSection<V: View>(_ view: V) -> ContainerStructureObservation {
        #if os(watchOS)
        return watchTypeNameObservation(view, presentToken: "Section<")
        #else
        return .observed(containsSection(view))
        #endif
    }

    /// `VStack` without `Section`. On watchOS a root `Section<` is an observed negative,
    /// a root `VStack<` is an observed positive, and anything else was not looked inside (#379).
    @MainActor
    public static func observeContainsVStackWithoutSection<V: View>(_ view: V) -> ContainerStructureObservation {
        #if os(watchOS)
        let name = String(describing: type(of: view))
        if name.contains("Section<") { return .observed(false) }
        if name.contains("VStack<") { return .observed(true) }
        return .unavailable
        #else
        return .observed(containsVStackWithoutSection(view))
        #endif
    }

    #if os(watchOS)
    private static func watchTypeNameObservation<V: View>(
        _ view: V,
        presentToken: String
    ) -> ContainerStructureObservation {
        if typeNameContains(view, token: presentToken) { return .observed(true) }
        return .unavailable
    }
    #endif

    /// Returns whether `view` hosts a SwiftUI `Form` (directly or via `platformFormContainer`).
    @MainActor
    public static func containsForm<V: View>(_ view: V) -> Bool {
        #if canImport(ViewInspector)
        // Successful inspection must decide here (including empty → false). Only fall through
        // to UIKit when inspection itself fails (e.g. ViewInspector not usable for the view).
        if let found = withInspectedView(AnyView(view), perform: { inspected -> Bool? in
            !inspected.findAll(ViewType.Form.self).isEmpty
        }) {
            return found
        }
        #endif
        if typeNameContains(view, token: "Form<") { return true }
        #if canImport(UIKit) && !os(watchOS)
        return hostedSubtreeIndicatesSwiftUIForm(view)
        #else
        // watchOS cannot host. `false` here is not an observation — use observeContainsForm (#379).
        return false
        #endif
    }

    /// Returns whether `view` contains a SwiftUI `Section`.
    @MainActor
    public static func containsSection<V: View>(_ view: V) -> Bool {
        #if canImport(ViewInspector)
        if let found = withInspectedView(AnyView(view), perform: { inspected -> Bool? in
            !inspected.findAll(ViewType.Section.self).isEmpty
        }) {
            return found
        }
        #endif
        if typeNameContains(view, token: "Section<") { return true }
        #if canImport(UIKit) && !os(watchOS)
        return hostedSubtreeIndicatesSwiftUISection(view)
        #else
        // watchOS cannot host. `false` here is not an observation — use observeContainsSection (#379).
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
            return !hasSection && hasVStack
        }) {
            return result
        }
        #endif
        let name = String(describing: type(of: view))
        if name.contains("Section<") { return false }
        if name.contains("VStack<") { return true }
        #if canImport(UIKit) && !os(watchOS)
        return hostedSubtreeIndicatesInsetVStackWithoutSection(view)
        #else
        // watchOS cannot host. `false` here is not an observation — use observeContainsVStackWithoutSection (#379).
        return false
        #endif
    }

    /// Cheap hostability smoke: ViewInspector when linked, else UIKit hosting (#219).
    @MainActor
    public static func isHostable<V: View>(_ view: V) -> Bool {
        #if canImport(ViewInspector)
        if withInspectedView(AnyView(view), perform: { _ in true }) != nil {
            return true
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        return TestSetupUtilities.hostRootPlatformView(view) != nil
        #else
        // watchOS cannot host. `false` here is not an observation — use observeHostability (#379).
        return false
        #endif
    }

    private static func typeNameContains<V: View>(_ view: V, token: String) -> Bool {
        String(describing: type(of: view)).contains(token)
    }

    // MARK: - UIKit fallback (tvOS/visionOS and when ViewInspector traversal fails)

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

    @MainActor
    private static func uiViewSubtree(_ view: UIView, matches: (String) -> Bool) -> Bool {
        let typeName = String(describing: type(of: view))
        if matches(typeName) { return true }
        return view.subviews.contains { uiViewSubtree($0, matches: matches) }
    }
    #endif
}
