//
//  ViewInspectorHierarchyHelpers.swift
//  SixLayerFrameworkTests
//
//  Deep hierarchy walks for internal ViewInspector tests (#314).
//  Kept in the test target — not part of the public SixLayerViewInspectorTestKit API (#327).
//

import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
@testable import ViewInspector

/// Collect `viewType` matches after unwrapping AnyView boundaries (Issue #178 / #314).
@MainActor
public func findAllInViewHierarchy<V: View, T: ViewInspector.KnownViewType>(
    _ view: V,
    _ viewType: T.Type,
    maxAnyViewUnwrapDepth: Int = 12
) -> [ViewInspector.InspectableView<T>] {
    AccessibilityIdentifierConfig.withUnhostedInspection {
        if let inspected = try? view.inspect().view(V.self) {
            var results = inspected.findAll(viewType)
            if results.isEmpty, let vStack = try? firstVStackInHierarchy(inspected) {
                results = vStack.findAll(viewType)
            }
            if results.isEmpty, let scroll = try? inspected.scrollView() {
                results = scroll.findAll(viewType)
            }
            if results.isEmpty {
                results = findAllInViewHierarchyErased(AnyView(view), viewType, maxAnyViewUnwrapDepth: maxAnyViewUnwrapDepth)
            }
            return results
        }
        return findAllInViewHierarchyErased(AnyView(view), viewType, maxAnyViewUnwrapDepth: maxAnyViewUnwrapDepth)
    }
}

@MainActor
private func findAllInViewHierarchyErased<T: ViewInspector.KnownViewType>(
    _ view: AnyView,
    _ viewType: T.Type,
    maxAnyViewUnwrapDepth: Int = 12
) -> [ViewInspector.InspectableView<T>] {
    guard let inspected = try? view.inspect() else { return [] }
    var results: [ViewInspector.InspectableView<T>] = []

    func merge(_ batch: [ViewInspector.InspectableView<T>]) {
        results.append(contentsOf: batch)
    }

    func mergeDeep(_ root: ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) {
        merge(root.findAll(viewType, where: { _ in true }))
        if let scroll = try? root.scrollView() {
            merge(scroll.findAll(viewType, where: { _ in true }))
            if let lazy = try? scroll.lazyVStack() {
                merge(lazy.findAll(viewType, where: { _ in true }))
            }
            if let vStack = try? scroll.vStack() {
                merge(vStack.findAll(viewType, where: { _ in true }))
            }
        }
        if let lazy = try? root.lazyVStack() {
            merge(lazy.findAll(viewType, where: { _ in true }))
        }
        if let forEach = try? root.forEach() {
            merge(forEach.findAll(viewType, where: { _ in true }))
        }
    }

    func searchAnyViewRoot(_ root: ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>) {
        merge(root.findAll(viewType, where: { _ in true }))
        if let scroll = try? root.scrollView() {
            merge(scroll.findAll(viewType, where: { _ in true }))
        }
        if let lazy = try? root.lazyVStack() {
            merge(lazy.findAll(viewType, where: { _ in true }))
        }
        if let vStack = try? root.vStack() {
            merge(vStack.findAll(viewType, where: { _ in true }))
        }
    }

    mergeDeep(inspected)
    if let vStack = try? firstVStackInHierarchy(inspected) {
        merge(vStack.findAll(viewType, where: { _ in true }))
    }
    if let scroll = try? inspected.scrollView() {
        merge(scroll.findAll(viewType, where: { _ in true }))
    }

    var anyRoot: ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>? = try? inspected.anyView()
    var depth = 0
    while depth < maxAnyViewUnwrapDepth, let root = anyRoot {
        searchAnyViewRoot(root)
        anyRoot = try? root.anyView()
        depth += 1
    }

    return results
}

/// Find a button whose label matches any of the given strings (deep hierarchy walk — #314).
@MainActor
public func findButtonInViewHierarchy(
    _ view: some View,
    labels: [String]
) -> ViewInspector.InspectableView<ViewInspector.ViewType.Button>? {
    let wanted = Set(labels)
    for button in findAllInViewHierarchy(view, ViewInspector.ViewType.Button.self) {
        for label in buttonLabelStrings(button) where wanted.contains(label) {
            return button
        }
    }
    return nil
}

@MainActor
private func buttonLabelStrings(
    _ button: ViewInspector.InspectableView<ViewInspector.ViewType.Button>
) -> [String] {
    var strings: [String] = []
    if let labelView = try? button.labelView(),
       let text = try? labelView.find(ViewInspector.ViewType.Text.self).string() {
        strings.append(text)
    }
    for textView in button.findAll(ViewInspector.ViewType.Text.self) {
        if let s = try? textView.string(), !s.isEmpty {
            strings.append(s)
        }
    }
    return strings
}

#endif // canImport(ViewInspector)
