//
//  PlatformManagedSettingsFlowLogic.swift
//  SixLayerFramework
//
//  Cross-platform settings flow routing rules (testable without SwiftUI).
//  Issue #209: managed platform settings flow — unified routing / sub-panes.
//

import Foundation
import SwiftUI

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

    /// Whether hierarchical sub-panes inside the detail context should use a system stack (push / pop).
    public static func subPaneNavigationUsesSystemStack(deviceType: DeviceType) -> Bool {
        switch deviceType {
        case .phone, .pad, .mac:
            return true
        case .tv, .watch, .car, .vision:
            return false
        }
    }

    /// Binding for ``View/navigationDestination(isPresented:content:)`` on iPhone settings so **system back**
    /// clears `selectedCategory` instead of swapping root views without a navigation pop.
    ///
    /// - Returns: `nil` when `selectedCategory` is absent (caller shows sidebar only).
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
}
