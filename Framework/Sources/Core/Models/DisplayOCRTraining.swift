//
//  DisplayOCRTraining.swift
//  SixLayerFramework
//
//  Red gate for the display OCR label harness (#609). The types compile.
//  Clamping, crops, decode, and export stay absent so the new tests fail
//  at runtime.
//

import Combine
import CoreGraphics
import Foundation

public enum DisplayOCRTrainingOrigin: String, Codable, Sendable, Equatable {
    case topLeft
}

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

    public init(pixelRect: CGRect, imageWidth: Int, imageHeight: Int) {
        self.x = 0
        self.y = 0
        self.width = 0
        self.height = 0
    }

    public var unitClamped: DisplayOCRNormalizedBox? { nil }

    public func intersection(_ other: DisplayOCRNormalizedBox) -> DisplayOCRNormalizedBox? { nil }

    public func pixelRect(imageWidth: Int, imageHeight: Int) -> CGRect? { nil }

    public func containerRect(imagePixelSize: CGSize, containerSize: CGSize) -> CGRect { .zero }
}

public struct DisplayOCRTrainingRow: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var box: DisplayOCRNormalizedBox?
    public var decodedText: String
    public var confirmedText: String
    public var confidence: Float

    public init(
        id: UUID = UUID(),
        box: DisplayOCRNormalizedBox?,
        decodedText: String,
        confirmedText: String,
        confidence: Float
    ) {
        self.id = id
        self.box = box
        self.decodedText = decodedText
        self.confirmedText = confirmedText
        self.confidence = confidence
    }
}

public struct DisplayOCRTrainingLabel: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var origin: DisplayOCRTrainingOrigin
    public var imageFileName: String
    public var imagePixelWidth: Int
    public var imagePixelHeight: Int
    public var sourceName: String?
    public var panel: DisplayOCRNormalizedBox
    public var rows: [DisplayOCRTrainingRow]

    public init(
        schemaVersion: Int,
        origin: DisplayOCRTrainingOrigin,
        imageFileName: String,
        imagePixelWidth: Int,
        imagePixelHeight: Int,
        sourceName: String?,
        panel: DisplayOCRNormalizedBox,
        rows: [DisplayOCRTrainingRow]
    ) {
        self.schemaVersion = schemaVersion
        self.origin = origin
        self.imageFileName = imageFileName
        self.imagePixelWidth = imagePixelWidth
        self.imagePixelHeight = imagePixelHeight
        self.sourceName = sourceName
        self.panel = panel
        self.rows = rows
    }
}

public struct DisplayOCRTrainingPackage: Sendable, Equatable {
    public var label: DisplayOCRTrainingLabel
    public var imagePNG: Data

    public init(label: DisplayOCRTrainingLabel, imagePNG: Data) {
        self.label = label
        self.imagePNG = imagePNG
    }
}

public struct DisplayOCRTrainingExport: Sendable, Equatable {
    public var directory: URL
    public var package: DisplayOCRTrainingPackage

    public init(directory: URL, package: DisplayOCRTrainingPackage) {
        self.directory = directory
        self.package = package
    }
}

public enum DisplayOCRTrainingError: Error, Equatable, Sendable {
    case unreadableImage
    case emptyPanel
    case missingLabel
    case pngEncodingFailed
    case unreadablePackage
    case unsupportedSchema(Int)
    case writeFailed
}

public enum DisplayOCRTrainingDrawMode: String, CaseIterable, Sendable, Identifiable {
    case panel
    case row

    public var id: String { rawValue }
}

public enum DisplayOCRTrainingStatus: Equatable, Sendable {
    case unreadableImage
    case needsPanel
    case decoded
    case exported(URL)
    case exportFailed
}

public enum DisplayOCRTraining {
    public static let schemaVersion = 1
    public static let imageFileName = "image.png"
    public static let labelFileName = "label.json"

    public static func sanitizedSourceName(_ raw: String?) -> String? { nil }

    public static func normalizedBox(
        fromContainerRect rect: CGRect,
        imageSize: CGSize,
        containerSize: CGSize,
        minimumContainerEdge: CGFloat = 8
    ) -> DisplayOCRNormalizedBox? {
        nil
    }

    public static func crop(_ image: CGImage, to box: DisplayOCRNormalizedBox) -> CGImage? { nil }

    public static func draft(
        image: CGImage,
        panel: DisplayOCRNormalizedBox,
        rowBoxes: [DisplayOCRNormalizedBox],
        sourceName: String?,
        deskewMaximumDegrees: Double = 3
    ) -> DisplayOCRTrainingLabel? {
        nil
    }

    public static func confirming(
        _ label: DisplayOCRTrainingLabel,
        rowID: UUID,
        text: String
    ) -> DisplayOCRTrainingLabel {
        label
    }

    public static func package(
        label: DisplayOCRTrainingLabel,
        image: CGImage
    ) throws -> DisplayOCRTrainingPackage {
        throw DisplayOCRTrainingError.emptyPanel
    }

    public static func write(_ package: DisplayOCRTrainingPackage, to directory: URL) throws {
        throw DisplayOCRTrainingError.writeFailed
    }

    public static func read(from directory: URL) throws -> DisplayOCRTrainingPackage {
        throw DisplayOCRTrainingError.unreadablePackage
    }

    public static func label(from data: Data) throws -> DisplayOCRTrainingLabel {
        try JSONDecoder().decode(DisplayOCRTrainingLabel.self, from: data)
    }
}

@MainActor
public final class DisplayOCRTrainingSession: ObservableObject {
    @Published public private(set) var image: PlatformImage?
    @Published public private(set) var imagePixelSize: CGSize = .zero
    @Published public private(set) var sourceName: String?
    @Published public private(set) var panel: DisplayOCRNormalizedBox?
    @Published public private(set) var rowBoxes: [DisplayOCRNormalizedBox] = []
    @Published public private(set) var label: DisplayOCRTrainingLabel?
    @Published public var drawMode: DisplayOCRTrainingDrawMode = .panel
    @Published public private(set) var status: DisplayOCRTrainingStatus?

    public init() {}

    public func load(platformImage: PlatformImage, sourceName: String? = nil) {}

    public func load(cgImage: CGImage, sourceName: String? = nil) {}

    public func load(fileURL: URL) {}

    public func setPanel(_ box: DisplayOCRNormalizedBox) {}

    public func useFullFramePanel() {}

    @discardableResult
    public func addRowBox(_ box: DisplayOCRNormalizedBox) -> Bool { false }

    public func clearRowBoxes() {}

    @discardableResult
    public func applyDraw(containerRect: CGRect, containerSize: CGSize) -> Bool { false }

    @discardableResult
    public func decode() -> Bool { false }

    public func confirm(rowID: UUID, text: String) {}

    public func makePackage() throws -> DisplayOCRTrainingPackage {
        throw DisplayOCRTrainingError.missingLabel
    }

    public func failExport() {
        status = .exportFailed
    }

    @discardableResult
    public func exportToTemporaryDirectory() throws -> DisplayOCRTrainingExport {
        throw DisplayOCRTrainingError.missingLabel
    }
}
