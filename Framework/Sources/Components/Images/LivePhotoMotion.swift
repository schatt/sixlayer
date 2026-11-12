//
//  LivePhotoMotion.swift
//  SixLayerFramework
//
//  Live Photo motion for picked and captured photos (#668).
//

import AVFoundation
import Foundation

/// A picked or captured photo, plus its Live Photo movie when one was asked for.
public struct PlatformPhotoSelection: Sendable {
    public let image: PlatformImage
    /// The Live Photo's paired movie, copied to a temporary file the caller owns.
    public let livePhotoMovieURL: URL?

    public init(image: PlatformImage, livePhotoMovieURL: URL? = nil) {
        self.image = image
        self.livePhotoMovieURL = livePhotoMovieURL
    }

    // RED STUB (#668): deliberately wrong.
    static func resolve(
        image: PlatformImage,
        includeLivePhotoMotion: Bool,
        loadLivePhotoMovie: () async -> URL?
    ) async -> PlatformPhotoSelection {
        PlatformPhotoSelection(image: PlatformImage(), livePhotoMovieURL: await loadLivePhotoMovie())
    }
}

/// Frames from a Live Photo movie.
public enum LivePhotoFrames {
    // RED STUB (#668): deliberately wrong.
    public static func frames(fromMovieAt url: URL, count: Int) async throws -> [PlatformImage] {
        []
    }
}
