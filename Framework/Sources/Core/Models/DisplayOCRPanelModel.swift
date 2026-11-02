//
//  DisplayOCRPanelModel.swift
//  SixLayerFramework
//
//  Phase C (#609). A panel localizer trained from the Phase B library.
//  Annotation boxes are normalized, origin top-left, anchor at the center,
//  which is the Create ML object-detector default. Create ML training runs
//  on macOS. Loading the model uses Core ML on every platform that has Vision.
//

import CoreGraphics
import Foundation

#if canImport(CoreML) && canImport(Vision) && !os(watchOS)
import CoreML
import Vision
#endif

#if os(macOS)
import CreateML
#endif

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

extension DisplayOCRPanelModelError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyLibrary:
            return "Export a labeled photo before training."
        case .trainingRequiresMacOS:
            return "Train the panel model on a Mac."
        case .trainingFailed(let message):
            return message
        }
    }
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

    /// A compiled or uncompiled model at `url`. Nil when the file is missing
    /// or is not a Core ML model. The caller then uses the classical finder.
    public static func coreML(modelAt url: URL) -> DisplayOCRPanelLocator? {
        #if canImport(CoreML) && canImport(Vision) && !os(watchOS)
        DisplayOCRPanelModel.locator(modelAt: url)
        #else
        _ = url
        return nil
        #endif
    }
}

public enum DisplayOCRPanelModel {
    public static let panelLabel = "panel"
    public static let modelFileName = "PanelLocalizer.mlmodel"
    public static let annotationFileName = "annotations.json"
    static let minimumConfidence: Float = 0.3

    /// The panel box with the highest confidence at or above ``minimumConfidence``.
    /// Other labels are ignored.
    static func chosenVisionBox(from candidates: [DisplayOCRPanelCandidate]) -> CGRect? {
        candidates
            .filter { $0.label == panelLabel && $0.confidence >= minimumConfidence }
            .max { $0.confidence < $1.confidence }?
            .box
    }

    /// Vision's normalized box is bottom-left. The trainer and the segment
    /// crop use top-left pixels.
    public static func topLeftPixelRect(
        visionBox: CGRect,
        imageWidth: Int,
        imageHeight: Int
    ) -> CGRect? {
        guard imageWidth > 0, imageHeight > 0 else { return nil }
        let width = visionBox.width * CGFloat(imageWidth)
        let height = visionBox.height * CGFloat(imageHeight)
        guard width > 0, height > 0 else { return nil }
        let x = visionBox.minX * CGFloat(imageWidth)
        let y = (1 - visionBox.maxY) * CGFloat(imageHeight)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    /// Annotation rows for every example whose panel meets the image.
    /// The image name is the example folder plus `.png`, because every
    /// package file is named `image.png`.
    public static func annotations(from library: DisplayOCRTrainingLibrary) -> [DisplayOCRPanelAnnotation] {
        var seen: Set<String> = []
        var rows: [DisplayOCRPanelAnnotation] = []
        for example in library.examples {
            guard let panel = example.package.label.panel.unitClamped else { continue }
            let name = example.directory.lastPathComponent
            guard !name.isEmpty, name != ".", name != ".." else { continue }
            let filename = name + ".png"
            guard seen.insert(filename).inserted else { continue }
            rows.append(DisplayOCRPanelAnnotation(
                imagefilename: filename,
                annotation: [
                    DisplayOCRPanelObjectAnnotation(
                        label: panelLabel,
                        coordinates: DisplayOCRPanelCoordinates(
                            x: panel.x + panel.width / 2,
                            y: panel.y + panel.height / 2,
                            width: panel.width,
                            height: panel.height
                        )
                    )
                ]
            ))
        }
        return rows
    }

    /// Copy labeled images and write `annotations.json`. The image directory
    /// holds only those images, so Create ML does not try to train on the JSON.
    public static func writeTrainingSet(
        _ library: DisplayOCRTrainingLibrary,
        to directory: URL
    ) throws -> DisplayOCRPanelTrainingSet {
        let rows = annotations(from: library)
        guard !rows.isEmpty else { throw DisplayOCRPanelModelError.emptyLibrary }
        let images = directory.appendingPathComponent("images", isDirectory: true)
        try FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)
        let wanted = Set(rows.map(\.imagefilename))
        for example in library.examples {
            let filename = example.directory.lastPathComponent + ".png"
            guard wanted.contains(filename) else { continue }
            try example.package.imagePNG.write(
                to: images.appendingPathComponent(filename),
                options: .atomic
            )
        }
        let annotation = directory.appendingPathComponent(annotationFileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(rows).write(to: annotation, options: .atomic)
        return DisplayOCRPanelTrainingSet(imageDirectory: images, annotationFile: annotation)
    }

    #if os(macOS)
    /// Train an object detector and write `PanelLocalizer.mlmodel` into `directory`.
    /// There is no holdout split: a small labeled set is the whole training set.
    public static func train(
        library: DisplayOCRTrainingLibrary,
        writingModelTo directory: URL,
        maxIterations: Int = 30
    ) throws -> URL {
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("display-ocr-panel-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        let set = try writeTrainingSet(library, to: scratch)
        var parameters = MLObjectDetector.ModelParameters()
        parameters.validation = .none
        parameters.maxIterations = max(1, maxIterations)
        parameters.algorithm = .transferLearning(.objectPrint(revision: 1))
        let detector: MLObjectDetector
        do {
            detector = try MLObjectDetector(
                trainingData: .directoryWithImages(
                    at: set.imageDirectory,
                    annotationFile: set.annotationFile
                ),
                parameters: parameters,
                annotationType: .boundingBox(units: .normalized, origin: .topLeft, anchor: .center)
            )
        } catch {
            throw DisplayOCRPanelModelError.trainingFailed(error.localizedDescription)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try write(detector.model, to: directory.appendingPathComponent(modelFileName))
    }

    private static func write(_ model: MLModel, to destination: URL) throws -> URL {
        let partial = destination.deletingLastPathComponent()
            .appendingPathComponent(destination.lastPathComponent + ".partial")
        if FileManager.default.fileExists(atPath: partial.path) {
            try FileManager.default.removeItem(at: partial)
        }
        do {
            try model.write(to: partial)
            if FileManager.default.fileExists(atPath: destination.path) {
                _ = try FileManager.default.replaceItemAt(destination, withItemAt: partial)
            } else {
                try FileManager.default.moveItem(at: partial, to: destination)
            }
        } catch {
            try? FileManager.default.removeItem(at: partial)
            throw DisplayOCRPanelModelError.trainingFailed(error.localizedDescription)
        }
        return destination
    }
    #endif

    #if canImport(CoreML) && canImport(Vision) && !os(watchOS)
    static func locator(modelAt url: URL) -> DisplayOCRPanelLocator? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let model = try? MLModel(contentsOf: url),
              let visionModel = try? VNCoreMLModel(for: model) else {
            return nil
        }
        return DisplayOCRPanelLocator { image in
            region(in: image, model: visionModel)
        }
    }

    private static func region(in image: CGImage, model: VNCoreMLModel) -> CGRect? {
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .scaleFill
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        let observations = request.results as? [VNRecognizedObjectObservation] ?? []
        let candidates = observations.flatMap { observation in
            observation.labels.map { label in
                DisplayOCRPanelCandidate(
                    label: label.identifier,
                    confidence: label.confidence,
                    box: observation.boundingBox
                )
            }
        }
        guard let visionBox = chosenVisionBox(from: candidates) else { return nil }
        return topLeftPixelRect(
            visionBox: visionBox,
            imageWidth: image.width,
            imageHeight: image.height
        )
    }
    #endif
}
