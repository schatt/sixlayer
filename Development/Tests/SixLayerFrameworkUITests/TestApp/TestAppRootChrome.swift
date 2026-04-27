//
//  TestAppRootChrome.swift
//  SixLayerFrameworkUITests
//
//  Shared window chrome for `SixLayerFrameworkTestApp_*` (UITest host + manual runs).
//

import SwiftUI
import SixLayerFramework

extension View {
    /// Fill the scene and paint grouped background so `WindowGroup` does not show raw black
    /// around hosts that do not expand (Form, ScrollView, nested stacks).
    @MainActor
    func testAppHostRootSurface() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                Color.platformGroupedBackground
                    .ignoresSafeArea()
            }
    }
}
