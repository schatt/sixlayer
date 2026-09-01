//
//  PlatformDataScannerSessionControllerTests.swift
//  SixLayerFrameworkUnitTests
//
//  Issue #418 — session APIs throw scannerNotAttached when nothing is attached.
//  Capability is RuntimeCapabilityDetection.Photos.supportsLiveDataScanner (#253 / #415).
//

import Testing
@testable import SixLayerFramework

@Suite("Platform data scanner session controller (#418)")
struct PlatformDataScannerSessionControllerTests {

    @Test @MainActor
    func testSessionControllerStartScanningThrowsWhenNoLiveScannerAttached() {
        let controller = PlatformDataScannerSessionController()
        #expect(throws: PlatformDataScannerError.scannerNotAttached) {
            try controller.startScanning()
        }
    }

    @Test @MainActor
    func testSessionControllerCapturePhotoThrowsWhenNoLiveScannerAttached() async {
        let controller = PlatformDataScannerSessionController()
        await #expect(throws: PlatformDataScannerError.scannerNotAttached) {
            try await controller.capturePhoto()
        }
    }

    @Test @MainActor
    func testSessionControllerStopScanningDoesNotTrapWhenNoLiveScannerAttached() {
        let controller = PlatformDataScannerSessionController()
        controller.stopScanning()
        #expect(controller.liveScannerViewController == nil)
    }
}
