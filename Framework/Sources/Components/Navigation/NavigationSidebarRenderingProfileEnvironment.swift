//
//  NavigationSidebarRenderingProfileEnvironment.swift
//  SixLayerFramework
//
//  Issue #331: publish active NavigationSidebarProfile for custom sidebars.
//

import SwiftUI

private struct NavigationSidebarRenderingProfileKey: EnvironmentKey {
    static let defaultValue: NavigationSidebarProfile = .textSidebar
}

public extension EnvironmentValues {
    /// Active app-nav sidebar rendering profile (width-driven). Framework-owned lists
    /// step label ↔ icon-only from this value; custom `@ViewBuilder` sidebars may adapt.
    var navigationSidebarRenderingProfile: NavigationSidebarProfile {
        get { self[NavigationSidebarRenderingProfileKey.self] }
        set { self[NavigationSidebarRenderingProfileKey.self] = newValue }
    }
}
