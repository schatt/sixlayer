//
//  GlareFusion.swift
//  SixLayerFramework
//
//  Combine the frames of a Live Photo so glare, which moves between frames
//  while the display does not, drops out before seven-segment OCR (#673).
//

import CoreGraphics
import Foundation

public enum GlareFusion {
    // RED STUB (#673): deliberately wrong. Returns the first frame.
    public static func fuse(frames: [PlatformImage]) -> PlatformImage? {
        frames.first
    }
}
