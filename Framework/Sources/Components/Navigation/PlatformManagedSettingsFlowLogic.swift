//
//  PlatformManagedSettingsFlowLogic.swift
//  SixLayerFramework
//
//  Cross-platform settings flow routing rules (testable without SwiftUI).
//  Issue #209: managed platform settings flow — unified routing / sub-panes.
//

import Foundation
import SwiftUI

/// Top-level settings shell policy for a given ``DeviceType``.
public enum PlatformManagedSettingsTopLevelShellPolicy: Equatable, Sendable {
    /// Sidebar + detail visible together.
    case splitSidebarDetail
    /// Category list pushes into detail when selected.
    case stackWithSelectionPush
    /// Fallback for platforms that do not use managed top-level shell routing by default.
    case unsupportedSidebarFallback
}

// MARK: - PlatformManagedSettingsFlowLogic

/// Routing policy helpers for the default settings (master–detail) experience.
///
/// Higher-level views (e.g. Layer 4) compose these rules with `platformSettingsContainer_L4`.
/// Issue: https://github.com/schatt/sixlayer/issues/209
public enum PlatformManagedSettingsFlowLogic: Sendable {

    /// Recommended top-level selection when the settings UI first appears.
    ///
    /// - **Split-style** (e.g. iPad, macOS): first pane when the list is non-empty so the detail column is not blank.
    /// - **Phone**: `nil` so the user starts on the category list (push/stack applies after a choice).
    public static func recommendedInitialTopSelection<ID: Hashable & Sendable>(
        panes: [ID],
        deviceType: DeviceType
    ) -> ID? {
        guard let first = panes.first else { return nil }
        switch deviceType {
        case .pad, .mac:
            return first
        case .phone, .tv, .watch, .car, .vision:
            return nil
        }
    }

    /// Whether the top-level settings shell behaves like split view (sidebar + detail visible together).
    public static func usesSplitStyleTopLevelSettingsShell(deviceType: DeviceType) -> Bool {
        switch deviceType {
        case .pad, .mac:
            return true
        case .phone, .tv, .watch, .car, .vision:
            return false
        }
    }

    /// Explicit top-level settings shell policy for managed flow.
    public static func topLevelSettingsShellPolicy(
        deviceType: DeviceType
    ) -> PlatformManagedSettingsTopLevelShellPolicy {
        switch deviceType {
        case .pad, .mac:
            return .splitSidebarDetail
        case .phone, .car:
            return .stackWithSelectionPush
        case .tv, .watch, .vision:
            return .unsupportedSidebarFallback
        }
    }

    /// Whether hierarchical sub-panes inside the detail context should use a system stack (push / pop).
    ///
    /// **watchOS** is included with phone / pad / mac: drill-down settings use stack-style navigation.
    /// **tvOS**, **CarPlay**, and **vision** use `false` when templates or non-stack detail chrome are preferred (see issue #211 matrix tests).
    public static func subPaneNavigationUsesSystemStack(deviceType: DeviceType) -> Bool {
        switch deviceType {
        case .phone, .pad, .mac, .watch:
            return true
        case .tv, .car, .vision:
            return false
        }
    }

    /// Binding for ``View/navigationDestination(isPresented:content:)`` on iPhone settings so **system back**
    /// clears `selectedCategory` instead of swapping root views without a navigation pop.
    ///
    /// - Returns: `nil` when `selectedCategory` is absent (caller shows sidebar only).
    @MainActor
    public static func iPhoneTopLevelDetailNavigationIsPresented(
        selectedCategory: Binding<AnyHashable?>?
    ) -> Binding<Bool>? {
        guard let selectedCategory else { return nil }
        return Binding(
            get: { selectedCategory.wrappedValue != nil },
            set: { isPresented in
                if !isPresented {
                    selectedCategory.wrappedValue = nil
                }
            }
        )
    }

    /// Selects a top-level settings pane and clears sub-pane depth so pushed routes do not carry across categories.
    ///
    /// Call from sidebar row actions when using ``PlatformManagedSettingsDetailNavigationState`` in the detail column.
    public static func selectTopLevelPane<ID: Hashable & Sendable, SubID: Hashable & Sendable>(
        _ id: ID,
        topLevel: inout PlatformManagedSettingsTopLevelState<ID>,
        detailNavigation: inout PlatformManagedSettingsDetailNavigationState<SubID>
    ) {
        topLevel.selectTopLevel(id)
        detailNavigation.popToRoot()
    }
}
