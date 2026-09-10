//
//  PlatformSidebarSheetChromeLayer6.swift
//  SixLayerFramework
//
//  Layer 6 applies sidebar-sheet and overlay-detail chrome decisions (#447).
//  Compile-time `#if os` mirrors `platformSidebarSheetChrome(for:)` /
//  `platformOverlayDetailChrome(for:)` so each platform binary's `some View`
//  subject type does not encode unused branches (ViewBuilder + runtime switch
//  left NavigationStack in Mirror on non-iOS and broke host observation).
//

import SwiftUI

public extension View {
    /// Sidebar presented as a sheet: NavigationStack on iOS, small frame on macOS.
    /// Apply path matches `platformSidebarSheetChrome(for: .current)`.
    @MainActor
    func platformSidebarSheetChrome_L6() -> some View {
        #if os(iOS)
        NavigationStack {
            self
        }
        #elseif os(macOS)
        self.platformPresentationFrame(sizes: [.small])
        #else
        self
        #endif
    }

    /// Compact overlay detail: NavigationStack on iOS and macOS.
    /// Apply path matches `platformOverlayDetailChrome(for: .current)`.
    @MainActor
    func platformOverlayDetailChrome_L6() -> some View {
        #if os(iOS) || os(macOS)
        NavigationStack {
            self
        }
        #else
        self
        #endif
    }
}
