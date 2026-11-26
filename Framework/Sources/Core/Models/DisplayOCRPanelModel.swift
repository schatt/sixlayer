//
//  DisplayOCRPanelModel.swift
//  SixLayerFramework
//
//  Runtime panel localizer load (#609 / #706). Create ML *training* lives in
//  display-ocr-lab. Apps pass a trained model via `DisplayOCRPanelLocator.coreML`
//  into `OCRContext.panelLocator`.
//

import CoreGraphics
import Foundation

#if canImport(CoreML) && canImport(Vision) && !os(watchOS)
import CoreML
import Vision
#endif

struct DisplayOCRPanelCandidate: Equatable, Sendable {
    var label: String
    var confidence: Float
    var box: CGRect
}

/// Supplies a digit-panel rect in top-left pixels. Nil means the caller
/// keeps the classical panel finder.
public struct DisplayOCRPanelLocator: @unchecked Sendable {
    public static let panelLabel = "panel"
    public static let modelFileName = "PanelLocalizer.mlmodel"
    static let minimumConfidence: Float = 0.3

    private let region: (CGImage) -> CGRect?

    public init(region: @escaping (CGImage) -> CGRect?) {
        self.region = region
    }

    public func panelRegion(in image: CGImage) -> CGRect? {
        region(image)
    }

    /// Load a custom trained panel model for OCR. Pass the result as
    /// `OCRContext.panelLocator`. Returns nil when the file is missing or
    /// is not a Core ML model — the caller then uses the classical finder.
    public static func coreML(modelAt url: URL) -> DisplayOCRPanelLocator? {
        #if canImport(CoreML) && canImport(Vision) && !os(watchOS)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let model = loadableModel(at: url),
              let visionModel = try? VNCoreMLModel(for: model) else {
            return nil
        }
        return DisplayOCRPanelLocator { image in
            region(in: image, model: visionModel)
        }
        #else
        _ = url
        return nil
        #endif
    }

    /// Vision's normalized box is bottom-left. Segment crop uses top-left pixels.
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

    /// The panel box with the highest confidence at or above ``minimumConfidence``.
    static func chosenVisionBox(from candidates: [DisplayOCRPanelCandidate]) -> CGRect? {
        candidates
            .filter { $0.label == panelLabel && $0.confidence >= minimumConfidence }
            .max { $0.confidence < $1.confidence }?
            .box
    }

    #if canImport(CoreML) && canImport(Vision) && !os(watchOS)
    private static let modelLock = NSLock()
    nonisolated(unsafe) private static var compiledModelURLs: [String: URL] = [:]

    private static func loadableModel(at url: URL) -> MLModel? {
        let key = url.standardizedFileURL.path
        modelLock.lock()
        let cached = compiledModelURLs[key]
        modelLock.unlock()
        if let cached,
           FileManager.default.fileExists(atPath: cached.path),
           let model = try? MLModel(contentsOf: cached) {
            return model
        }
        let compiledURL: URL
        if url.pathExtension == "mlmodelc" {
            compiledURL = url
        } else {
            guard let compiled = try? MLModel.compileModel(at: url) else { return nil }
            compiledURL = compiled
        }
        guard let model = try? MLModel(contentsOf: compiledURL) else { return nil }
        modelLock.lock()
        compiledModelURLs[key] = compiledURL
        modelLock.unlock()
        return model
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
