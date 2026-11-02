//
//  DisplayOCRPanelModel.swift
//  SixLayerFramework
//
//  Phase C (#609). A panel localizer trained from the Phase B library.
//  Annotation boxes are normalized, origin top-left, anchor at the center,
//  which is the Create ML object-detector default.
//

import CoreGraphics
import Foundation

/// One image row in a Create ML object-detector annotation file.
public struct DisplayOCRPanelAnnotation: Codable, Equatable, Sendable {
    public var imagefilename: String
    public var annotation: [DisplayOCRPanelObjectAnnotation]

    public init(imagefilename: String, annotation: [DisplayOCRPanelObjectAnnotation]) {
        self.imagefilename = imagefilename
        self.annotation = annotation
    }
}

public struct DisplayOCRPanelObjectAnnotation: Codable, Equatable, Sendable {
    public var label: String
    public var coordinates: DisplayOCRPanelCoordinates

    public init(label: String, coordinates: DisplayOCRPanelCoordinates) {
        self.label = label
        self.coordinates = coordinates
    }
}

public struct DisplayOCRPanelCoordinates: Codable, Equatable, Sendable {
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
}

/// Where `writeTrainingSet` put the images and the annotation JSON.
public struct DisplayOCRPanelTrainingSet: Equatable, Sendable {
    public var imageDirectory: URL
    public var annotationFile: URL

    public init(imageDirectory: URL, annotationFile: URL) {
        self.imageDirectory = imageDirectory
        self.annotationFile = annotationFile
    }
}

public enum DisplayOCRPanelModelError: Error, Equatable, Sendable {
    case emptyLibrary
    case trainingRequiresMacOS
    case trainingFailed(String)
}

/// Progress of the Mac training action on the trainer screen.
public enum DisplayOCRPanelTrainingState: Equatable, Sendable {
    case idle
    case running
    case ready(URL)
    case emptyLibrary
    case requiresMacOS
    case failed(String)
}

struct DisplayOCRPanelCandidate: Equatable, Sendable {
    var label: String
    var confidence: Float
    var box: CGRect
}

/// Supplies a digit-panel rect in top-left pixels. Nil means the caller
/// keeps the classical panel finder.
public struct DisplayOCRPanelLocator: @unchecked Sendable {
    private let region: (CGImage) -> CGRect?

    public init(region: @escaping (CGImage) -> CGRect?) {
        self.region = region
    }

    public func panelRegion(in image: CGImage) -> CGRect? {
        region(image)
    }
}

public enum DisplayOCRPanelModel {
    public static let panelLabel = "panel"
    public static let modelFileName = "PanelLocalizer.mlmodel"
    public static let annotationFileName = "annotations.json"
    static let minimumConfidence: Float = 0.3

    static func chosenVisionBox(from candidates: [DisplayOCRPanelCandidate]) -> CGRect? {
        _ = candidates
        return nil
    }

    /// Vision's normalized box is bottom-left. The trainer and the segment
    /// crop use top-left pixels.
    public static func topLeftPixelRect(
        visionBox: CGRect,
        imageWidth: Int,
        imageHeight: Int
    ) -> CGRect? {
        _ = (visionBox, imageWidth, imageHeight)
        return .zero
    }

    public static func writeTrainingSet(
        _ library: DisplayOCRTrainingLibrary,
        to directory: URL
    ) throws -> DisplayOCRPanelTrainingSet {
        _ = library
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let annotation = directory.appendingPathComponent(annotationFileName)
        try Data("[]".utf8).write(to: annotation, options: .atomic)
        return DisplayOCRPanelTrainingSet(imageDirectory: directory, annotationFile: annotation)
    }
}
