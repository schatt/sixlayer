import Testing
import Foundation
import AVFoundation
@testable import SixLayerFramework

//
//  LivePhotoCamera669Tests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  The camera captures Live Photos so seven-segment OCR gets several frames
//  of one shot (#669). The system camera stays only as a fallback.
//
//  TESTING SCOPE:
//  - Which camera runs for each caller and authorization state
//  - Capture settings ask for a movie only when Live Photo is supported
//  - The still and the movie, which arrive separately, pair into one selection
//

@Suite("Live Photo camera (#669)")
struct LivePhotoCamera669Tests {

    // MARK: Capture path

    @Test func imageOnlyCallersKeepTheSystemCamera() {
        #expect(LivePhotoCamera.capturePath(wantsMotion: false, authorization: .authorized) == .systemCamera)
        #expect(LivePhotoCamera.capturePath(wantsMotion: false, authorization: .notDetermined) == .systemCamera)
    }

    @Test func selectionCallersGetTheLivePhotoCamera() {
        #expect(LivePhotoCamera.capturePath(wantsMotion: true, authorization: .authorized) == .livePhotoCamera)
        #expect(LivePhotoCamera.capturePath(wantsMotion: true, authorization: .notDetermined) == .livePhotoCamera)
    }

    @Test(arguments: [CameraAuthorizationState.denied, .restricted, .unavailable])
    func noUsableCameraFallsBackToTheSystemPicker(_ state: CameraAuthorizationState) {
        #expect(LivePhotoCamera.capturePath(wantsMotion: true, authorization: state) == .systemCamera)
    }

    // MARK: Capture settings

    #if os(iOS)
    @Test func supportedCaptureWritesAMovieIntoTheDirectory() throws {
        let directory = FileManager.default.temporaryDirectory

        let first = LivePhotoCamera.photoSettings(livePhotoSupported: true, movieDirectory: directory)
        let second = LivePhotoCamera.photoSettings(livePhotoSupported: true, movieDirectory: directory)

        let firstURL = try #require(first.livePhotoMovieFileURL)
        let secondURL = try #require(second.livePhotoMovieFileURL)
        #expect(firstURL.pathExtension == "mov")
        #expect(firstURL.deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL)
        #expect(firstURL != secondURL, "each shot needs its own movie file")
    }

    @Test func unsupportedCaptureIsStillOnly() {
        let settings = LivePhotoCamera.photoSettings(
            livePhotoSupported: false,
            movieDirectory: FileManager.default.temporaryDirectory
        )

        #expect(settings.livePhotoMovieFileURL == nil)
    }
    #endif

    // MARK: Pairing the still and the movie

    @Test func stillAndMoviePairIntoOneSelection() throws {
        let movie = URL(fileURLWithPath: "/tmp/live-669.mov")
        var assembly = LivePhotoCaptureAssembly()

        assembly.receivePhoto(TestMovie.solidImage(gray: 90))
        assembly.receiveMovie(movie, error: nil)

        let selection = try #require(assembly.selection())
        #expect(selection.livePhotoMovieURL == movie)
        #expect(Int(selection.image.size.width) == TestMovie.width)
    }

    @Test func movieMayArriveBeforeTheStill() throws {
        let movie = URL(fileURLWithPath: "/tmp/live-669.mov")
        var assembly = LivePhotoCaptureAssembly()

        assembly.receiveMovie(movie, error: nil)
        assembly.receivePhoto(TestMovie.solidImage(gray: 90))

        let selection = try #require(assembly.selection())
        #expect(selection.livePhotoMovieURL == movie)
    }

    @Test func failedMovieStillDeliversTheStill() throws {
        var assembly = LivePhotoCaptureAssembly()

        assembly.receivePhoto(TestMovie.solidImage(gray: 90))
        assembly.receiveMovie(URL(fileURLWithPath: "/tmp/partial-669.mov"), error: CocoaError(.fileWriteUnknown))

        let selection = try #require(assembly.selection())
        #expect(selection.livePhotoMovieURL == nil)
    }

    @Test func noStillMeansNoSelection() {
        var assembly = LivePhotoCaptureAssembly()

        assembly.receivePhoto(nil)
        assembly.receiveMovie(URL(fileURLWithPath: "/tmp/live-669.mov"), error: nil)

        #expect(assembly.selection() == nil)
    }

    // MARK: Use Photo / Retake

    @Test func usePhotoDeliversThePendingSelection() {
        var confirmation = LivePhotoCaptureConfirmation()
        let movie = URL(fileURLWithPath: "/tmp/live-669-confirm.mov")
        let pending = PlatformPhotoSelection(image: TestMovie.solidImage(gray: 40), livePhotoMovieURL: movie)

        confirmation.offer(pending)

        let delivered = confirmation.usePhoto()
        #expect(delivered?.livePhotoMovieURL == movie)
        #expect(confirmation.usePhoto() == nil, "Use Photo clears the pending shot")
    }

    @Test func retakeClearsWithoutDelivering() {
        var confirmation = LivePhotoCaptureConfirmation()
        confirmation.offer(PlatformPhotoSelection(image: TestMovie.solidImage(gray: 40)))

        confirmation.retake()

        #expect(confirmation.usePhoto() == nil)
    }

    @Test func retakeDeletesTheCallerOwnedMovie() throws {
        let movie = FileManager.default.temporaryDirectory
            .appendingPathComponent("LivePhotoMotion-retake-\(UUID().uuidString).mov")
        try Data([0x00]).write(to: movie)
        var confirmation = LivePhotoCaptureConfirmation()
        confirmation.offer(PlatformPhotoSelection(image: TestMovie.solidImage(gray: 40), livePhotoMovieURL: movie))

        confirmation.retake()

        #expect(!FileManager.default.fileExists(atPath: movie.path))
    }
}

#if os(iOS)
import UIKit

/// The capture view replaces the system camera, which has a Cancel button.
@Suite("Live Photo camera cancel (#669)")
@MainActor
struct LivePhotoCameraCancel669Tests {
    static let cancelIdentifier = "SixLayer.main.ui.platformCameraInterface_L4.cancel"

    private func control(_ identifier: String, in view: UIView) -> UIControl? {
        if let control = view as? UIControl, control.accessibilityIdentifier == identifier { return control }
        for subview in view.subviews {
            if let found = control(identifier, in: subview) { return found }
        }
        return nil
    }

    @Test func cancelButtonReportsCancel() throws {
        var cancelled = 0
        let controller = LivePhotoCameraViewController(
            onSelection: { _ in },
            onCancel: { cancelled += 1 },
            onUnavailable: {}
        )
        controller.loadViewIfNeeded()

        let cancel = try #require(control(Self.cancelIdentifier, in: controller.view))
        #expect(cancel.accessibilityLabel?.isEmpty == false)
        cancel.sendActions(for: .touchUpInside)

        #expect(cancelled == 1)
    }

    @Test func noCancelCallbackMeansNoCancelButton() {
        let controller = LivePhotoCameraViewController(
            onSelection: { _ in },
            onCancel: nil,
            onUnavailable: {}
        )
        controller.loadViewIfNeeded()

        #expect(control(Self.cancelIdentifier, in: controller.view) == nil)
    }

    /// The fallback system camera must report its own Cancel the same way.
    @Test func systemCameraFallbackReportsCancel() {
        var cancelled = 0
        let camera = CameraView(onImageCaptured: { _ in }, onCancel: { cancelled += 1 })

        camera.makeCoordinator().imagePickerControllerDidCancel(UIImagePickerController())

        #expect(cancelled == 1)
    }
}

/// Review after a shot matches the system camera's Use Photo / Retake.
@Suite("Live Photo camera confirmation (#669)")
@MainActor
struct LivePhotoCameraConfirmation669Tests {
    static let usePhotoIdentifier = "SixLayer.main.ui.platformCameraInterface_L4.usePhoto"
    static let retakeIdentifier = "SixLayer.main.ui.platformCameraInterface_L4.retake"

    private func control(_ identifier: String, in view: UIView) -> UIControl? {
        if let control = view as? UIControl, control.accessibilityIdentifier == identifier { return control }
        for subview in view.subviews {
            if let found = control(identifier, in: subview) { return found }
        }
        return nil
    }

    @Test func usePhotoDeliversTheSelection() throws {
        var selections: [PlatformPhotoSelection] = []
        let controller = LivePhotoCameraViewController(
            onSelection: { selections.append($0) },
            onCancel: nil,
            onUnavailable: {}
        )
        controller.loadViewIfNeeded()
        let pending = PlatformPhotoSelection(image: TestMovie.solidImage(gray: 55))

        controller.offerReviewForTesting(pending)

        let usePhoto = try #require(control(Self.usePhotoIdentifier, in: controller.view))
        usePhoto.sendActions(for: .touchUpInside)

        #expect(selections.count == 1)
        #expect(control(Self.usePhotoIdentifier, in: controller.view) == nil)
    }

    @Test func retakeKeepsTheCameraWithoutDelivering() throws {
        var selections: [PlatformPhotoSelection] = []
        let controller = LivePhotoCameraViewController(
            onSelection: { selections.append($0) },
            onCancel: nil,
            onUnavailable: {}
        )
        controller.loadViewIfNeeded()
        controller.offerReviewForTesting(PlatformPhotoSelection(image: TestMovie.solidImage(gray: 55)))

        let retake = try #require(control(Self.retakeIdentifier, in: controller.view))
        retake.sendActions(for: .touchUpInside)

        #expect(selections.isEmpty)
        #expect(control(Self.retakeIdentifier, in: controller.view) == nil)
    }
}
#endif
