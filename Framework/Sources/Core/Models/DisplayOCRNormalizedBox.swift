//
//  DisplayOCRNormalizedBox.swift
//  SixLayerFramework
//
//  Shared geometry for runtime OCR panel/row boxes (#609 / #706).
//  Lab/training authoring lives in display-ocr-lab; this type stays in
//  SixLayer because `OCRResult` / SevenSegmentOCR emit it.
//

import CoreGraphics
import Foundation

/// Top-left of the bitmap. `y` grows downward, matching the image as displayed.
public enum DisplayOCRTrainingOrigin: String, Codable, Sendable, Equatable {
    case topLeft
}

/// A rectangle as fractions of the full image. Origin is the top-left.
public struct DisplayOCRNormalizedBox: Codable, Sendable, Equatable, Hashable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Fractions of `imageWidth` and `imageHeight`. The rect is top-left pixels.
    public init(pixelRect: CGRect, imageWidth: Int, imageHeight: Int) {
        let safeWidth = max(imageWidth, 1)
        let safeHeight = max(imageHeight, 1)
        self.x = Double(pixelRect.minX) / Double(safeWidth)
        self.y = Double(pixelRect.minY) / Double(safeHeight)
        self.width = Double(pixelRect.width) / Double(safeWidth)
        self.height = Double(pixelRect.height) / Double(safeHeight)
    }

    /// The overlap with the unit square, or nil when that overlap is empty.
    public var unitClamped: DisplayOCRNormalizedBox? {
        let left = min(max(x, 0), 1)
        let top = min(max(y, 0), 1)
        let right = min(max(x + width, 0), 1)
        let bottom = min(max(y + height, 0), 1)
        guard right > left, bottom > top else { return nil }
        return DisplayOCRNormalizedBox(x: left, y: top, width: right - left, height: bottom - top)
    }

    /// Overlap of two boxes, or nil when they do not meet.
    public func intersection(_ other: DisplayOCRNormalizedBox) -> DisplayOCRNormalizedBox? {
        let left = max(x, other.x)
        let top = max(y, other.y)
        let right = min(x + width, other.x + other.width)
        let bottom = min(y + height, other.y + other.height)
        guard right > left, bottom > top else { return nil }
        return DisplayOCRNormalizedBox(
            x: left,
            y: top,
            width: right - left,
            height: bottom - top
        ).unitClamped
    }

    /// Intersection-over-union of two normalized boxes (#677).
    public func iou(_ other: DisplayOCRNormalizedBox) -> Double {
        let areaSelf = width * height
        let areaOther = other.width * other.height
        guard areaSelf > 0, areaOther > 0 else { return 0 }
        guard let overlap = intersection(other) else { return 0 }
        let intersectionArea = overlap.width * overlap.height
        let unionArea = areaSelf + areaOther - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }

    /// Top-left pixel rect. Nil when the box misses the image.
    public func pixelRect(imageWidth: Int, imageHeight: Int) -> CGRect? {
        guard imageWidth > 0, imageHeight > 0, let box = unitClamped else { return nil }
        let x0 = Self.nearestPixel(box.x, span: imageWidth)
        let y0 = Self.nearestPixel(box.y, span: imageHeight)
        let x1 = Self.nearestPixel(box.x + box.width, span: imageWidth)
        let y1 = Self.nearestPixel(box.y + box.height, span: imageHeight)
        guard x1 > x0, y1 > y0 else { return nil }
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    /// Where this box sits inside an aspect-fit image frame.
    public func containerRect(imagePixelSize: CGSize, containerSize: CGSize) -> CGRect {
        let frame = OCRBoundingBoxLayout.aspectFitImageFrame(
            imageSize: imagePixelSize,
            containerSize: containerSize
        )
        guard frame.width > 0, frame.height > 0 else { return .zero }
        return CGRect(
            x: frame.minX + x * frame.width,
            y: frame.minY + y * frame.height,
            width: width * frame.width,
            height: height * frame.height
        )
    }

    private static func nearestPixel(_ fraction: Double, span: Int) -> Int {
        let value = (fraction * Double(span)).rounded(.toNearestOrAwayFromZero)
        return min(max(Int(value), 0), span)
    }
}
