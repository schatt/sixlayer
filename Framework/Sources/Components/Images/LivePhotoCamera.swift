//
//  LivePhotoCamera.swift
//  SixLayerFramework
//
//  Live Photo capture for the camera interface (#669).
//

import AVFoundation
import Foundation

/// Which camera the camera interface shows.
enum CameraCapturePath: Equatable, Sendable {
    /// The framework's capture view, which records Live Photos when it can.
    case livePhotoCamera
    /// The system camera (`UIImagePickerController`), still only.
    case systemCamera
}

enum LivePhotoCamera {
    // RED STUB (#669): deliberately wrong.
    static func capturePath(wantsMotion: Bool, authorization: CameraAuthorizationState) -> CameraCapturePath {
        authorization == .authorized ? .systemCamera : .livePhotoCamera
    }

    #if os(iOS)
    // RED STUB (#669): deliberately wrong.
    static func photoSettings(livePhotoSupported: Bool, movieDirectory: URL) -> AVCapturePhotoSettings {
        AVCapturePhotoSettings()
    }
    #endif
}

/// Pairs a capture's still and Live Photo movie, which arrive separately.
struct LivePhotoCaptureAssembly {
    private var image: PlatformImage?

    // RED STUB (#669): deliberately wrong.
    mutating func receivePhoto(_ image: PlatformImage?) {
        self.image = image
    }

    mutating func receiveMovie(_ url: URL?, error: (any Error)?) {}

    func selection() -> PlatformPhotoSelection? {
        PlatformPhotoSelection(image: image ?? PlatformImage())
    }
}
