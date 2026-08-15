//
//  PlatformDataScannerSessionControllerTests.swift
//  SixLayerFrameworkUnitTests
//
//  Issue #415 — session APIs throw scannerNotAttached on iOS and
//  platformUnsupported when VisionKit DataScannerViewController is not linked
//  (Mac Catalyst and non-iOS).
//

import Testing
@testable import SixLayerFramework

@Suite("Platform data scanner session controller (#415)")
struct PlatformDataScannerSessionControllerTests {

    @Test @MainActor
    func testSessionControllerStartScanningThrowsWhenNoLiveScannerAttached() {
        let controller = PlatformDataScannerSessionController()
        #if os(iOS) && !targetEnvironment(macCatalyst)
        #expect(throws: PlatformDataScannerError.scannerNotAttached) {
            try controller.startScanning()
        }
        #else
        #expect(throws: PlatformDataScannerError.platformUnsupported) {
            try controller.startScanning()
        }
        #endif
    }

    @Test @MainActor
    func testSessionControllerCapturePhotoThrowsWhenNoLiveScannerAttached() async {
        let controller = PlatformDataScannerSessionController()
        #if os(iOS) && !targetEnvironment(macCatalyst)
        await #expect(throws: PlatformDataScannerError.scannerNotAttached) {
            try await controller.capturePhoto()
        }
        #else
        await #expect(throws: PlatformDataScannerError.platformUnsupported) {
            try await controller.capturePhoto()
        }
        #endif
    }

    @Test @MainActor
    func testSessionControllerStopScanningDoesNotTrapWhenNoLiveScannerAttached() {
        let controller = PlatformDataScannerSessionController()
        controller.stopScanning()
        #expect(controller.liveScannerViewController == nil)
    }
}
