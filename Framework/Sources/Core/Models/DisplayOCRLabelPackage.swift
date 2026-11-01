//
//  DisplayOCRLabelPackage.swift
//  SixLayerFramework
//
//  Export package for display OCR label harness Phase A (#609).
//

import CoreGraphics
import Foundation

/// Vision-normalized rectangle (origin bottom-left), Codable for label export.
public struct DisplayOCRLabelRect: Codable, Sendable, Equatable {
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

    public init(_ rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.width
        self.height = rect.height
    }

    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

/// One confirmed display row inside a label package.
public struct DisplayOCRLabeledRow: Codable, Sendable, Equatable {
    public var boundingBox: DisplayOCRLabelRect?
    public var confirmedText: String

    public init(boundingBox: DisplayOCRLabelRect?, confirmedText: String) {
        self.boundingBox = boundingBox
        self.confirmedText = confirmedText
    }
}

/// Image + normalized ROIs + confirmed digit strings for fixtures / Core ML datasets (#609).
public struct DisplayOCRLabelPackage: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var imagePNGData: Data
    public var panelBoundingBox: DisplayOCRLabelRect
    public var rows: [DisplayOCRLabeledRow]
    public var segmentDeskewMaximumDegrees: Double?

    public init(
        schemaVersion: Int = DisplayOCRLabelPackage.currentSchemaVersion,
        imagePNGData: Data,
        panelBoundingBox: DisplayOCRLabelRect,
        rows: [DisplayOCRLabeledRow],
        segmentDeskewMaximumDegrees: Double? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.imagePNGData = imagePNGData
        self.panelBoundingBox = panelBoundingBox
        self.rows = rows
        self.segmentDeskewMaximumDegrees = segmentDeskewMaximumDegrees
    }

    public func encodedJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    public static func decode(from data: Data) throws -> DisplayOCRLabelPackage {
        try JSONDecoder().decode(DisplayOCRLabelPackage.self, from: data)
    }
}
