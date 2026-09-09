//
//  PlatformSidebarSheetChromeLayer6.swift
//  SixLayerFramework
//
//  Layer 6 applies sidebar-sheet and overlay-detail chrome decisions (#447).
//

import SwiftUI

public extension View {
    /// Sidebar presented as a sheet: NavigationStack on iOS, small frame on macOS.
    @MainActor
    @ViewBuilder
    func platformSidebarSheetChrome_L6() -> some View {
        switch platformSidebarSheetChrome(for: .current) {
        case .navigationStackWrapped:
            NavigationStack {
                self
            }
        case .presentationFramed:
            self.platformPresentationFrame(sizes: [.small])
        case .unmodified:
            self
        }
    }

    /// Compact overlay detail: NavigationStack on iOS and macOS.
    @MainActor
    @ViewBuilder
    func platformOverlayDetailChrome_L6() -> some View {
        switch platformOverlayDetailChrome(for: .current) {
        case .navigationStackWrapped:
            NavigationStack {
                self
            }
        case .unmodified:
            self
        }
    }
}
