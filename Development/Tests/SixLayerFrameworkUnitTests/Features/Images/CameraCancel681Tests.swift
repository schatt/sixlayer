import Testing
import Foundation
@testable import SixLayerFramework

//
//  CameraCancel681Tests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Still-only `platformCameraInterface_L4(onImageCaptured:)` must accept
//  `onCancel` and forward it to the system camera (#681).
//
//  TESTING SCOPE:
//  - The Layer 4 still-only builder passes Cancel through to CameraView
//

#if os(iOS)
import UIKit

@Suite("Still-only camera onCancel (#681)")
@MainActor
struct CameraCancel681Tests {

    @Test func stillOnlyLayer4CameraForwardsCancel() {
        var cancelled = 0
        let camera = stillOnlyCameraViewForLayer4(
            onImageCaptured: { _ in },
            onCancel: { cancelled += 1 }
        )

        camera.makeCoordinator().imagePickerControllerDidCancel(UIImagePickerController())

        #expect(cancelled == 1)
    }

    @Test func stillOnlyLayer4CameraOmitsCancelWhenNil() {
        let camera = stillOnlyCameraViewForLayer4(
            onImageCaptured: { _ in },
            onCancel: nil
        )

        camera.makeCoordinator().imagePickerControllerDidCancel(UIImagePickerController())

        #expect(camera.onCancel == nil)
    }
}
#endif
