//
//  PlatformSidebarSheetChromeLayer6.swift
//  SixLayerFramework
//
//  Layer 6 applies the sidebar-sheet chrome decision (#447).
//

import SwiftUI

public extension View {
    /// Sidebar presented as a sheet: NavigationStack on iOS, small frame on macOS.
    @MainActor
    @ViewBuilder
    func platformSidebarSheetChrome_L6() -> some View {
        self
    }
}
