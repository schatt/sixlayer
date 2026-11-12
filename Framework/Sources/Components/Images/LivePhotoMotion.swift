//
//  LivePhotoMotion.swift
//  SixLayerFramework
//
//  Live Photo motion for picked and captured photos (#668).
//  Several frames of one shot let seven-segment OCR fuse away glare that
//  moves between frames while the digits stay put.
//

import AVFoundation
import Foundation
#if os(iOS) || os(macOS)
import Photos
#endif
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A picked or captured photo, plus its Live Photo movie when there is one.
public struct PlatformPhotoSelection: Sendable {
    public let image: PlatformImage
    /// The Live Photo's paired movie, copied to a temporary file the caller
    /// owns. Nil for a still photo or when the movie could not be copied.
    /// Read frames with ``LivePhotoFrames/frames(fromMovieAt:count:)``.
    public let livePhotoMovieURL: URL?

    public init(image: PlatformImage, livePhotoMovieURL: URL? = nil) {
        self.image = image
        self.livePhotoMovieURL = livePhotoMovieURL
    }

    /// The selection for `image`. The movie is only loaded when it is wanted,
    /// so callers that take a plain image never pay for a movie copy.
    static func resolve(
        image: PlatformImage,
        includeLivePhotoMotion: Bool,
        loadLivePhotoMovie: () async -> URL?
    ) async -> PlatformPhotoSelection {
        guard includeLivePhotoMotion else {
            return PlatformPhotoSelection(image: image)
        }
        return PlatformPhotoSelection(image: image, livePhotoMovieURL: await loadLivePhotoMovie())
    }
}

/// Frames from a Live Photo movie.
public enum LivePhotoFrames {
    /// `count` frames spread evenly over the movie, oldest first, upright.
    ///
    /// Each frame comes from the middle of one of `count` equal slices of the
    /// movie, which keeps clear of the first and last frames. Throws when the
    /// movie cannot be read.
    public static func frames(fromMovieAt url: URL, count: Int) async throws -> [PlatformImage] {
        guard count > 0 else { return [] }
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        var images: [PlatformImage] = []
        images.reserveCapacity(count)
        for time in sampleTimes(duration: duration, count: count) {
            let (cgImage, _) = try await generator.image(at: time)
            images.append(PlatformImage(cgImage: cgImage))
        }
        return images
    }

    static func sampleTimes(duration: CMTime, count: Int) -> [CMTime] {
        let seconds = max(0, duration.seconds.isFinite ? duration.seconds : 0)
        return (0..<count).map { index in
            CMTime(seconds: seconds * (Double(index) + 0.5) / Double(count), preferredTimescale: 600)
        }
    }
}

#if os(iOS) || os(macOS)
/// Loads a Photos picker result as a ``PlatformPhotoSelection``.
enum PhotoPickerSelectionLoader {
    /// Nil when the item is not an image.
    static func selection(
        from provider: NSItemProvider,
        includeLivePhotoMotion: Bool
    ) async -> PlatformPhotoSelection? {
        guard let image = await stillImage(from: provider) else { return nil }
        return await PlatformPhotoSelection.resolve(
            image: image,
            includeLivePhotoMotion: includeLivePhotoMotion,
            loadLivePhotoMovie: { await pairedMovie(from: provider) }
        )
    }

    private static func stillImage(from provider: NSItemProvider) async -> PlatformImage? {
        #if os(iOS)
        let imageClass = UIImage.self
        #else
        let imageClass = NSImage.self
        #endif
        guard provider.canLoadObject(ofClass: imageClass) else { return nil }
        return await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: imageClass) { object, _ in
                // System boundary conversion: UIImage / NSImage → PlatformImage
                #if os(iOS)
                let image = (object as? UIImage).map(PlatformImage.init(uiImage:))
                #else
                let image = (object as? NSImage).map(PlatformImage.init(nsImage:))
                #endif
                continuation.resume(returning: image)
            }
        }
    }

    /// Copies a Live Photo's paired movie to a new temporary file. Needs no
    /// photo library permission: the resource comes from the picked item.
    private static func pairedMovie(from provider: NSItemProvider) async -> URL? {
        guard provider.canLoadObject(ofClass: PHLivePhoto.self) else { return nil }
        return await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: PHLivePhoto.self) { object, _ in
                guard let livePhoto = object as? PHLivePhoto,
                      let movie = PHAssetResource.assetResources(for: livePhoto)
                        .first(where: { $0.type == .pairedVideo }) else {
                    continuation.resume(returning: nil)
                    return
                }
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("LivePhotoMotion-\(UUID().uuidString).mov")
                PHAssetResourceManager.default().writeData(for: movie, toFile: url, options: nil) { error in
                    continuation.resume(returning: error == nil ? url : nil)
                }
            }
        }
    }
}
#endif
