//
//  AppNavigationPaneDescriptor.swift
//  SixLayerFramework
//
//  Issue #331: structured app-nav sidebar item descriptors and section builders.
//

import Foundation

/// Structured app-navigation sidebar row (title + SF Symbol). Framework-owned lists can
/// step down to icon-only chrome when ``NavigationSidebarProfile/iconRail`` is active.
public struct AppNavigationPaneDescriptor<ID: Hashable & Sendable>: Sendable {
    public let id: ID
    public let titleKey: String
    public let systemImage: String
    public let section: String?

    public init(
        id: ID,
        titleKey: String,
        systemImage: String,
        section: String? = nil
    ) {
        self.id = id
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.section = section
    }
}

public enum AppNavigationPaneSectionBuilderError: Error, Equatable, Sendable {
    case duplicatePaneID(String)
}

public enum AppNavigationPaneSectionBuilder: Sendable {
    /// Groups descriptors by first-seen section order. Duplicate IDs throw.
    public static func groupedBySection<ID: Hashable & Sendable>(
        _ descriptors: [AppNavigationPaneDescriptor<ID>]
    ) throws -> [(section: String?, descriptors: [AppNavigationPaneDescriptor<ID>])] {
        // Deliberately wrong stub for TDD red (#331); replaced in green.
        _ = descriptors
        return []
    }
}

/// How a framework-owned app-nav sidebar row should render for the active profile (#331).
public enum AppNavigationSidebarRowPresentation: Sendable, Equatable {
    case labeled
    case compactLabeled
    case iconOnly

    public static func forProfile(_ profile: NavigationSidebarProfile) -> AppNavigationSidebarRowPresentation {
        // Deliberately wrong stub for TDD red (#331); replaced in green.
        _ = profile
        return .labeled
    }
}

/// Accessibility helpers for icon-rail rows (#331).
public enum AppNavigationSidebarRowAccessibility: Sendable {
    public static func iconOnlyLabel<ID: Hashable & Sendable>(
        for pane: AppNavigationPaneDescriptor<ID>
    ) -> String {
        // Deliberately wrong stub for TDD red (#331); replaced in green.
        _ = pane
        return ""
    }
}
