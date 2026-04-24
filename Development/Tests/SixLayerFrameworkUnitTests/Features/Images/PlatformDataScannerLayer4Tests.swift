//
//  PlatformDataScannerLayer4Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Issue #252 — VisionKit live data scanner Layer 4 surface (gates on #253 `Photos.supportsLiveDataScanner`).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform data scanner Layer 4 (#252)", DefaultRuntimeCapabilityIsolationTrait())
struct PlatformDataScannerLayer4Tests {

    #if os(iOS)
    @Test @MainActor
    func testPlatformDataScannerContent_HostsWithoutCrashWhenScannerUnavailable() {
        RuntimeCapabilityDetection.Photos.setTestSupportsLiveDataScanner(false)
        let view = PlatformPhotoComponentsLayer4.platformDataScannerContent_L4(
            configuration: PlatformDataScannerConfiguration.default,
            bannerMessage: "Scan hint",
            sessionController: nil,
            onItemTap: { _ in }
        )
        let hosted = TestSetupUtilities.hostRootPlatformView(view, forceLayout: false)
        #expect(hosted != nil, "Scanner placeholder should host without crashing when RCD reports unavailable")
    }

    @Test @MainActor
    func testPlatformDataScannerInterface_CompilesWithSheetHelpers() {
        RuntimeCapabilityDetection.Photos.setTestSupportsLiveDataScanner(false)
        var presented = true
        let binding = Binding(
            get: { presented },
            set: { presented = $0 }
        )
        let sheet = PlatformPhotoComponentsLayer4.platformDataScannerInterface_L4AsSheet(
            isPresented: binding,
            configuration: PlatformDataScannerConfiguration.default,
            bannerMessage: "Hint",
            onItemTap: { _ in }
        )
        _ = TestSetupUtilities.hostRootPlatformView(sheet, forceLayout: false)
        #expect(Bool(true), "Sheet helper should construct and host")
    }
    #endif
}
