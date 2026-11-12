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
}
