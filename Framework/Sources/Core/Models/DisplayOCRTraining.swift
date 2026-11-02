//
//  DisplayOCRTraining.swift
//  SixLayerFramework
//
//  Display OCR training (#609). Phase A writes one confirmed example.
//  Opening a new photo suggests a panel and rows from the seven-segment
//  reader. A saved example keeps the boxes and text the user confirmed.
//  Phase B reads the export directory as a library of those examples.
//  Phase C trains a panel localizer from that library on macOS.
//

import Combine
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

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

/// One labeled photo. Boxes are fractions of the full image, origin top-left.
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

/// One confirmed package inside a training library.
public struct DisplayOCRTrainingLibraryExample: Sendable, Equatable {
    public var directory: URL
    public var package: DisplayOCRTrainingPackage

    public init(directory: URL, package: DisplayOCRTrainingPackage) {
        self.directory = directory
        self.package = package
    }
}

/// A child folder that is not a usable example.
public struct DisplayOCRTrainingLibraryRejection: Sendable, Equatable {
    public var directory: URL
    public var error: DisplayOCRTrainingError

    public init(directory: URL, error: DisplayOCRTrainingError) {
        self.directory = directory
        self.error = error
    }
}

/// The examples and rejected folders in one export directory.
public struct DisplayOCRTrainingLibrary: Sendable, Equatable {
    public var examples: [DisplayOCRTrainingLibraryExample]
    public var rejections: [DisplayOCRTrainingLibraryRejection]

    public init(
        examples: [DisplayOCRTrainingLibraryExample] = [],
        rejections: [DisplayOCRTrainingLibraryRejection] = []
    ) {
        self.examples = examples
        self.rejections = rejections
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

/// The panel, or one row box, that the user has selected.
public enum DisplayOCRTrainingBoxTarget: Equatable, Sendable {
    case panel
    case row(Int)
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
    public static let exportDirectoryName = "display-ocr-training"

    /// `<current directory>/display-ocr-training`. The caller can replace this
    /// with a directory the user picked.
    public static func defaultExportRoot(
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    ) -> URL {
        currentDirectory.appendingPathComponent(exportDirectoryName, isDirectory: true)
    }

    /// A display name with no path. Nil for empty, `.`, or `..`.
    ///
    /// Path components are taken from the string. `URL(fileURLWithPath:)` is
    /// not used: it resolves `..` against the process working directory.
    public static func sanitizedSourceName(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let base = (raw as NSString).lastPathComponent
        if base == "." || base == ".." { return nil }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_ "))
        let scalars = base.unicodeScalars.filter { allowed.contains($0) }
        let name = String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty || name == "." || name == ".." { return nil }
        if name.count > 120 { return String(name.prefix(120)) }
        return name
    }

    /// True when the file panel was dismissed without a choice.
    public static func importerCancelled(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        guard let cocoa = error as? CocoaError else { return false }
        return cocoa.code == .userCancelled
    }

    /// Map a drag in an aspect-fit container to a top-left image box.
    /// Drags shorter than `minimumContainerEdge` on either side are ignored.
    public static func normalizedBox(
        fromContainerRect rect: CGRect,
        imageSize: CGSize,
        containerSize: CGSize,
        minimumContainerEdge: CGFloat = 8
    ) -> DisplayOCRNormalizedBox? {
        guard rect.width >= minimumContainerEdge, rect.height >= minimumContainerEdge else { return nil }
        let frame = OCRBoundingBoxLayout.aspectFitImageFrame(
            imageSize: imageSize,
            containerSize: containerSize
        )
        guard frame.width > 0, frame.height > 0 else { return nil }
        let hit = rect.intersection(frame)
        guard !hit.isNull, !hit.isEmpty,
              hit.width >= minimumContainerEdge,
              hit.height >= minimumContainerEdge else { return nil }
        return DisplayOCRNormalizedBox(
            x: (hit.minX - frame.minX) / frame.width,
            y: (hit.minY - frame.minY) / frame.height,
            width: hit.width / frame.width,
            height: hit.height / frame.height
        ).unitClamped
    }

    /// Map Vision boxes (origin bottom-left, fractions of the panel crop)
    /// into top-left rows on the photo. Boxes in one row are unioned.
    public static func rowBoxes(
        fromVisionBoxes boxes: [CGRect],
        panel: DisplayOCRNormalizedBox
    ) -> [DisplayOCRNormalizedBox] {
        guard let panel = panel.unitClamped, panel.width > 0, panel.height > 0 else { return [] }
        let mapped = boxes.compactMap { photoBox(fromVisionBox: $0, panel: panel) }
        return clusteredRows(mapped)
    }

    /// Gray crop in the same top-left order ``SevenSegmentOCR`` reads.
    public static func crop(_ image: CGImage, to box: DisplayOCRNormalizedBox) -> CGImage? {
        guard let rect = box.pixelRect(imageWidth: image.width, imageHeight: image.height) else { return nil }
        return DisplayOCRBitmap.crop(image, pixelRect: rect)
    }

    /// Decode `panel`. Row boxes are cropped on their own. An empty row list
    /// becomes one row per decoded line, or one blank row when the read is empty.
    public static func draft(
        image: CGImage,
        panel: DisplayOCRNormalizedBox,
        rowBoxes: [DisplayOCRNormalizedBox],
        sourceName: String?,
        deskewMaximumDegrees: Double = 3
    ) -> DisplayOCRTrainingLabel? {
        guard let panelBox = panel.unitClamped,
              let panelImage = crop(image, to: panelBox) else { return nil }
        let clipped = rowBoxes.compactMap { box -> DisplayOCRNormalizedBox? in
            guard let clamped = box.unitClamped else { return nil }
            guard let hit = clamped.intersection(panelBox) else { return nil }
            guard hit.pixelRect(imageWidth: image.width, imageHeight: image.height) != nil else { return nil }
            return hit
        }
        let panelRead = segmentRead(panelImage, deskewMaximumDegrees: deskewMaximumDegrees)
        let lineRows = panelRows(from: panelRead)
        let rows: [DisplayOCRTrainingRow]
        if clipped.isEmpty {
            rows = lineRows
        } else if let paired = rowsPairedWithPanelLines(lineRows, boxes: clipped) {
            // A crop of one LCD line is turned 180° by the reader. One box per
            // panel line keeps that line's text and the box the user is editing.
            rows = paired
        } else {
            rows = clipped.compactMap { box in
                guard let rowImage = crop(image, to: box) else { return nil }
                let decoded = segmentRead(rowImage, deskewMaximumDegrees: deskewMaximumDegrees)
                return labeledRow(decoded.extractedText, box: box, confidence: decoded.confidence)
            }
        }
        guard !rows.isEmpty else { return nil }
        return DisplayOCRTrainingLabel(
            schemaVersion: schemaVersion,
            origin: .topLeft,
            imageFileName: imageFileName,
            imagePixelWidth: image.width,
            imagePixelHeight: image.height,
            sourceName: sanitizedSourceName(sourceName),
            panel: panelBox,
            rows: rows
        )
    }

    /// Replace confirmed text for `rowID`. The decoded text stays.
    public static func confirming(
        _ label: DisplayOCRTrainingLabel,
        rowID: UUID,
        text: String
    ) -> DisplayOCRTrainingLabel {
        guard let index = label.rows.firstIndex(where: { $0.id == rowID }) else { return label }
        var updated = label
        updated.rows[index].confirmedText = text
        return updated
    }

    /// PNG plus a label whose image name is the package file, not a caller path.
    public static func package(
        label: DisplayOCRTrainingLabel,
        image: CGImage
    ) throws -> DisplayOCRTrainingPackage {
        guard let panel = label.panel.unitClamped else { throw DisplayOCRTrainingError.emptyPanel }
        guard let png = DisplayOCRBitmap.pngData(image) else { throw DisplayOCRTrainingError.pngEncodingFailed }
        let stored = storedLabel(label, image: image, panel: panel)
        return DisplayOCRTrainingPackage(label: stored, imagePNG: png)
    }

    /// Writes `image.png` and `label.json` inside `directory`. Names are fixed.
    public static func write(_ package: DisplayOCRTrainingPackage, to directory: URL) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else { throw DisplayOCRTrainingError.writeFailed }
        } else {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                throw DisplayOCRTrainingError.writeFailed
            }
        }
        var label = package.label
        label.imageFileName = imageFileName
        label.schemaVersion = schemaVersion
        label.origin = .topLeft
        label.sourceName = sanitizedSourceName(label.sourceName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json: Data
        do {
            json = try encoder.encode(label)
            try package.imagePNG.write(to: directory.appendingPathComponent(imageFileName), options: .atomic)
            try json.write(to: directory.appendingPathComponent(labelFileName), options: .atomic)
        } catch {
            throw DisplayOCRTrainingError.writeFailed
        }
    }

    /// Immediate child folders of `root`. A valid child is one example.
    /// A symlink or a folder that is not a package is reported. A file is ignored.
    /// One bad child does not drop the others. A missing `root` is an empty library.
    public static func library(in root: URL) -> DisplayOCRTrainingLibrary {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return DisplayOCRTrainingLibrary()
        }
        let children: [URL]
        do {
            children = try fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isSymbolicLinkKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return DisplayOCRTrainingLibrary()
        }
        var examples: [DisplayOCRTrainingLibraryExample] = []
        var rejections: [DisplayOCRTrainingLibraryRejection] = []
        for child in children {
            switch classify(child, in: root) {
            case .example(let package):
                examples.append(DisplayOCRTrainingLibraryExample(directory: child, package: package))
            case .rejection(let error):
                rejections.append(DisplayOCRTrainingLibraryRejection(directory: child, error: error))
            case .ignored:
                break
            }
        }
        examples.sort { $0.directory.lastPathComponent < $1.directory.lastPathComponent }
        rejections.sort { $0.directory.lastPathComponent < $1.directory.lastPathComponent }
        return DisplayOCRTrainingLibrary(examples: examples, rejections: rejections)
    }

    public static func read(from directory: URL) throws -> DisplayOCRTrainingPackage {
        let imageURL = directory.appendingPathComponent(imageFileName)
        let labelURL = directory.appendingPathComponent(labelFileName)
        let imageData: Data
        let labelData: Data
        do {
            imageData = try Data(contentsOf: imageURL)
            labelData = try Data(contentsOf: labelURL)
        } catch {
            throw DisplayOCRTrainingError.unreadablePackage
        }
        let label = try label(from: labelData)
        return DisplayOCRTrainingPackage(label: label, imagePNG: imageData)
    }

    public static func label(from data: Data) throws -> DisplayOCRTrainingLabel {
        let label: DisplayOCRTrainingLabel
        do {
            label = try JSONDecoder().decode(DisplayOCRTrainingLabel.self, from: data)
        } catch {
            throw DisplayOCRTrainingError.unreadablePackage
        }
        guard label.schemaVersion == schemaVersion else {
            throw DisplayOCRTrainingError.unsupportedSchema(label.schemaVersion)
        }
        guard label.origin == .topLeft, label.imageFileName == imageFileName else {
            throw DisplayOCRTrainingError.unreadablePackage
        }
        guard label.panel.unitClamped != nil else { throw DisplayOCRTrainingError.emptyPanel }
        return label
    }

    private static func storedLabel(
        _ label: DisplayOCRTrainingLabel,
        image: CGImage,
        panel: DisplayOCRNormalizedBox
    ) -> DisplayOCRTrainingLabel {
        DisplayOCRTrainingLabel(
            schemaVersion: schemaVersion,
            origin: .topLeft,
            imageFileName: imageFileName,
            imagePixelWidth: image.width,
            imagePixelHeight: image.height,
            sourceName: sanitizedSourceName(label.sourceName),
            panel: panel,
            rows: label.rows
        )
    }

    /// The user already drew the crop, so the decoder must not search for another panel.
    private static func segmentRead(_ image: CGImage, deskewMaximumDegrees: Double) -> OCRResult {
        SevenSegmentOCR.decode(
            cgImage: image,
            deskewMaximumDegrees: deskewMaximumDegrees,
            localizeDigitPanel: false
        )
    }

    private static func labeledRow(
        _ text: String,
        box: DisplayOCRNormalizedBox?,
        confidence: Float
    ) -> DisplayOCRTrainingRow {
        DisplayOCRTrainingRow(
            box: box,
            decodedText: text,
            confirmedText: text,
            confidence: confidence
        )
    }

    private enum LibraryChild {
        case example(DisplayOCRTrainingPackage)
        case rejection(DisplayOCRTrainingError)
        case ignored
    }

    private static func classify(_ child: URL, in root: URL) -> LibraryChild {
        if symbolicLink(child) || !contained(child, in: root) {
            return .rejection(.unreadablePackage)
        }
        guard directory(child) else { return .ignored }
        if isModelPackage(child) { return .ignored }
        do {
            return .example(try read(from: child))
        } catch let error as DisplayOCRTrainingError {
            return .rejection(error)
        } catch {
            return .rejection(.unreadablePackage)
        }
    }

    /// A Core ML package sitting in the library root is not an example folder.
    private static func isModelPackage(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        if name == DisplayOCRPanelModel.modelFileName { return true }
        if name == DisplayOCRPanelModel.modelFileName + ".partial" { return true }
        return name.hasSuffix(".mlmodel") || name.hasSuffix(".mlmodelc")
    }

    private static func symbolicLink(_ url: URL) -> Bool {
        if let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]), values.isSymbolicLink == true {
            return true
        }
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return false
        }
        let type = attributes[.type] as? FileAttributeType
        return type == .typeSymbolicLink
    }

    private static func directory(_ url: URL) -> Bool {
        if let values = try? url.resourceValues(forKeys: [.isDirectoryKey]), let isDirectory = values.isDirectory {
            return isDirectory
        }
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    /// `child` stays inside `root` after resolving links. A sibling prefix does not count.
    private static func contained(_ child: URL, in root: URL) -> Bool {
        let rootPath = resolvedPath(root)
        let childPath = resolvedPath(child)
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        return childPath.hasPrefix(prefix)
    }

    private static func resolvedPath(_ url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }

    private static func panelRows(from decoded: OCRResult) -> [DisplayOCRTrainingRow] {
        let lines = decoded.extractedText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let texts = lines.isEmpty ? [""] : lines
        return texts.map { labeledRow($0, box: nil, confidence: decoded.confidence) }
    }

    /// Glyph rows become the line boxes only when there is one glyph row per line.
    /// Otherwise the lines stay and no extra boxes are shown.
    static func aligningSuggestion(
        lines: [DisplayOCRTrainingRow],
        glyphs: [DisplayOCRNormalizedBox]
    ) -> (boxes: [DisplayOCRNormalizedBox], rows: [DisplayOCRTrainingRow]) {
        guard !lines.isEmpty, lines.count == glyphs.count else {
            return ([], lines)
        }
        let rows = zip(lines, glyphs).map { line, glyph in
            var line = line
            line.box = glyph
            return line
        }
        return (glyphs, rows)
    }

    /// One box per panel line. The returned rows stay in the order the boxes were
    /// drawn. Nil when a line is blank or the counts differ, so a tighter crop
    /// is still read on its own.
    private static func rowsPairedWithPanelLines(
        _ lines: [DisplayOCRTrainingRow],
        boxes: [DisplayOCRNormalizedBox]
    ) -> [DisplayOCRTrainingRow]? {
        guard lines.count > 1, lines.count == boxes.count else { return nil }
        guard lines.allSatisfy({ !$0.decodedText.isEmpty }) else { return nil }
        guard stacked(boxes), wideRows(boxes) else { return nil }
        let ranked = boxes.indices.sorted { lhs, rhs in
            let left = boxes[lhs]
            let right = boxes[rhs]
            if left.y == right.y { return left.x < right.x }
            return left.y < right.y
        }
        var assigned: [DisplayOCRTrainingRow?] = Array(repeating: nil, count: boxes.count)
        for (rank, index) in ranked.enumerated() {
            let line = lines[rank]
            assigned[index] = labeledRow(line.decodedText, box: boxes[index], confidence: line.confidence)
        }
        let rows = assigned.compactMap { $0 }
        guard rows.count == boxes.count else { return nil }
        return rows
    }

    /// True when each box sits under the previous one. Side-by-side digits stay
    /// on their own crops.
    private static func stacked(_ boxes: [DisplayOCRNormalizedBox]) -> Bool {
        let ordered = boxes.sorted { $0.y < $1.y }
        guard ordered.count > 1 else { return false }
        for pair in zip(ordered, ordered.dropFirst()) {
            let overlap = min(pair.0.y + pair.0.height, pair.1.y + pair.1.height) - max(pair.0.y, pair.1.y)
            let shorter = min(pair.0.height, pair.1.height)
            if shorter > 0, overlap > shorter * 0.5 { return false }
        }
        return true
    }

    /// A line of digits is wider than it is tall. A single digit is not.
    private static func wideRows(_ boxes: [DisplayOCRNormalizedBox]) -> Bool {
        boxes.allSatisfy { $0.width > $0.height * 1.5 }
    }

    fileprivate static let unitSquare = DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1)

    /// Vision's y is the bottom of the glyph. The trainer's y is the top.
    private static func photoBox(
        fromVisionBox box: CGRect,
        panel: DisplayOCRNormalizedBox
    ) -> DisplayOCRNormalizedBox? {
        guard box.width > 0, box.height > 0 else { return nil }
        let topLeftY = 1 - Double(box.minY + box.height)
        let photo = DisplayOCRNormalizedBox(
            x: panel.x + Double(box.minX) * panel.width,
            y: panel.y + topLeftY * panel.height,
            width: Double(box.width) * panel.width,
            height: Double(box.height) * panel.height
        )
        return photo.intersection(panel)
    }

    private static func clusteredRows(_ boxes: [DisplayOCRNormalizedBox]) -> [DisplayOCRNormalizedBox] {
        let ordered = boxes.sorted { lhs, rhs in
            if lhs.y == rhs.y { return lhs.x < rhs.x }
            return lhs.y < rhs.y
        }
        var rows: [DisplayOCRNormalizedBox] = []
        for box in ordered {
            if let last = rows.last, sharesRow(last, box) {
                rows[rows.count - 1] = union(last, box)
            } else {
                rows.append(box)
            }
        }
        return rows
    }

    private static func sharesRow(_ lhs: DisplayOCRNormalizedBox, _ rhs: DisplayOCRNormalizedBox) -> Bool {
        let top = max(lhs.y, rhs.y)
        let bottom = min(lhs.y + lhs.height, rhs.y + rhs.height)
        return bottom > top
    }

    private static func union(_ lhs: DisplayOCRNormalizedBox, _ rhs: DisplayOCRNormalizedBox) -> DisplayOCRNormalizedBox {
        let left = min(lhs.x, rhs.x)
        let top = min(lhs.y, rhs.y)
        let right = max(lhs.x + lhs.width, rhs.x + rhs.width)
        let bottom = max(lhs.y + lhs.height, rhs.y + rhs.height)
        return DisplayOCRNormalizedBox(x: left, y: top, width: right - left, height: bottom - top)
    }

    fileprivate static func rowsInside(
        _ rows: [DisplayOCRNormalizedBox],
        panel: DisplayOCRNormalizedBox,
        imageWidth: Int,
        imageHeight: Int
    ) -> [DisplayOCRNormalizedBox] {
        rows.compactMap { row in
            guard let hit = row.intersection(panel) else { return nil }
            guard hit.pixelRect(imageWidth: imageWidth, imageHeight: imageHeight) != nil else { return nil }
            return hit
        }
    }

    fileprivate static func hit(
        at point: CGPoint,
        containerSize: CGSize,
        imageSize: CGSize,
        panel: DisplayOCRNormalizedBox?,
        rows: [DisplayOCRNormalizedBox]
    ) -> BoxHit? {
        let frame = OCRBoundingBoxLayout.aspectFitImageFrame(
            imageSize: imageSize,
            containerSize: containerSize
        )
        guard frame.width > 0, frame.height > 0 else { return nil }
        let x = (point.x - frame.minX) / frame.width
        let y = (point.y - frame.minY) / frame.height
        for (index, row) in rows.enumerated().reversed() {
            if let edges = edges(atX: x, y: y, box: row, frame: frame) {
                return BoxHit(target: .row(index), edges: edges)
            }
        }
        if let panel, let edges = edges(atX: x, y: y, box: panel, frame: frame) {
            return BoxHit(target: .panel, edges: edges)
        }
        return nil
    }

    /// Move keeps the size and stops at `bounds`. An edge drag clips to `bounds`.
    fileprivate static func placed(
        _ box: DisplayOCRNormalizedBox,
        edges: BoxEdges,
        dx: Double,
        dy: Double,
        within bounds: DisplayOCRNormalizedBox
    ) -> DisplayOCRNormalizedBox? {
        if edges.isEmpty {
            let maxX = bounds.x + bounds.width - box.width
            let maxY = bounds.y + bounds.height - box.height
            return DisplayOCRNormalizedBox(
                x: min(max(box.x + dx, bounds.x), max(bounds.x, maxX)),
                y: min(max(box.y + dy, bounds.y), max(bounds.y, maxY)),
                width: box.width,
                height: box.height
            )
        }
        var x = box.x
        var y = box.y
        var width = box.width
        var height = box.height
        if edges.contains(.left) {
            let right = x + width
            let next = min(max(x + dx, bounds.x), right)
            x = next
            width = right - next
        } else if edges.contains(.right) {
            let next = min(max(x + width + dx, x), bounds.x + bounds.width)
            width = next - x
        }
        if edges.contains(.top) {
            let bottom = y + height
            let next = min(max(y + dy, bounds.y), bottom)
            y = next
            height = bottom - next
        } else if edges.contains(.bottom) {
            let next = min(max(y + height + dy, y), bounds.y + bounds.height)
            height = next - y
        }
        let resized = DisplayOCRNormalizedBox(x: x, y: y, width: width, height: height)
        return resized.intersection(bounds)
    }

    private static func edges(
        atX x: CGFloat,
        y: CGFloat,
        box: DisplayOCRNormalizedBox,
        frame: CGRect
    ) -> BoxEdges? {
        let fx = Double(x)
        let fy = Double(y)
        let slop = 0.000_1
        guard fx + slop >= box.x, fy + slop >= box.y,
              fx <= box.x + box.width + slop,
              fy <= box.y + box.height + slop else { return nil }
        let slopX = Double(min(12, box.width * frame.width / 3) / frame.width)
        let slopY = Double(min(12, box.height * frame.height / 3) / frame.height)
        var edges = BoxEdges()
        if fx - box.x <= slopX { edges.insert(.left) }
        if box.x + box.width - fx <= slopX { edges.insert(.right) }
        if fy - box.y <= slopY { edges.insert(.top) }
        if box.y + box.height - fy <= slopY { edges.insert(.bottom) }
        if edges.contains(.left), edges.contains(.right) {
            edges.remove(.left)
            edges.remove(.right)
        }
        if edges.contains(.top), edges.contains(.bottom) {
            edges.remove(.top)
            edges.remove(.bottom)
        }
        return edges
    }

    fileprivate struct BoxEdges: OptionSet {
        let rawValue: Int
        static let left = BoxEdges(rawValue: 1 << 0)
        static let right = BoxEdges(rawValue: 1 << 1)
        static let top = BoxEdges(rawValue: 1 << 2)
        static let bottom = BoxEdges(rawValue: 1 << 3)
    }

    fileprivate struct BoxHit {
        var target: DisplayOCRTrainingBoxTarget
        var edges: BoxEdges
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
    @Published public private(set) var exportRoot: URL = DisplayOCRTraining.defaultExportRoot()
    @Published public private(set) var library = DisplayOCRTrainingLibrary()
    @Published public private(set) var selectedBox: DisplayOCRTrainingBoxTarget?
    @Published public private(set) var panelTraining: DisplayOCRPanelTrainingState = .idle

    private var bitmap: CGImage?

    public init() {
        refreshLibrary()
    }

    public func load(platformImage: PlatformImage, sourceName: String? = nil) {
        guard let oriented = platformImage.orientedCGImage() else {
            markUnreadableImage()
            return
        }
        load(cgImage: oriented, sourceName: sourceName)
    }

    public func load(cgImage: CGImage, sourceName: String? = nil) {
        show(cgImage, sourceName: sourceName, suggesting: true)
    }

    /// Show a saved example. The stored boxes and confirmed text stay; a new suggestion does not replace them.
    public func restore(cgImage: CGImage, label saved: DisplayOCRTrainingLabel, sourceName: String? = nil) {
        show(cgImage, sourceName: sourceName ?? saved.sourceName, suggesting: false)
        guard bitmap != nil, let kept = saved.panel.unitClamped else { return }
        panel = kept
        let width = Int(imagePixelSize.width)
        let height = Int(imagePixelSize.height)
        var restored = saved
        restored.panel = kept
        restored.rows = saved.rows.map { row in
            var row = row
            row.box = clipped(row.box, to: kept, imageWidth: width, imageHeight: height)
            return row
        }
        rowBoxes = restored.rows.compactMap(\.box)
        label = restored
        status = .decoded
    }

    private func clipped(
        _ box: DisplayOCRNormalizedBox?,
        to panel: DisplayOCRNormalizedBox,
        imageWidth: Int,
        imageHeight: Int
    ) -> DisplayOCRNormalizedBox? {
        guard let hit = box?.unitClamped?.intersection(panel) else { return nil }
        guard hit.pixelRect(imageWidth: imageWidth, imageHeight: imageHeight) != nil else { return nil }
        return hit
    }

    private func show(_ cgImage: CGImage, sourceName rawName: String?, suggesting: Bool) {
        bitmap = cgImage
        image = PlatformImage(cgImage: cgImage)
        imagePixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        sourceName = DisplayOCRTraining.sanitizedSourceName(rawName)
        panel = nil
        rowBoxes = []
        label = nil
        status = nil
        selectedBox = nil
        if suggesting {
            suggestBoxes(in: cgImage)
        }
    }

    /// The classical reader proposes a panel and glyph rows. No panel means no suggestion.
    private func suggestBoxes(in image: CGImage) {
        guard let region = SevenSegmentOCR.digitPanelRegion(in: image) else { return }
        let suggested = DisplayOCRNormalizedBox(
            pixelRect: region,
            imageWidth: image.width,
            imageHeight: image.height
        )
        guard let panelBox = suggested.unitClamped,
              panelBox.pixelRect(imageWidth: image.width, imageHeight: image.height) != nil else { return }
        panel = panelBox
        var glyphs: [DisplayOCRNormalizedBox] = []
        if let crop = DisplayOCRTraining.crop(image, to: panelBox) {
            let read = SevenSegmentOCR.decode(
                cgImage: crop,
                deskewMaximumDegrees: 0,
                localizeDigitPanel: false
            )
            glyphs = DisplayOCRTraining.rowBoxes(fromVisionBoxes: read.boundingBoxes, panel: panelBox)
        }
        // A crop of one line is read upside down or not at all. The panel read
        // is the digit string; the glyph rows are only the boxes.
        rowBoxes = []
        guard decode(), var drafted = label else {
            rowBoxes = glyphs
            return
        }
        let aligned = DisplayOCRTraining.aligningSuggestion(lines: drafted.rows, glyphs: glyphs)
        drafted.rows = aligned.rows
        rowBoxes = aligned.boxes
        label = drafted
    }

    public func load(fileURL: URL) {
        do {
            let data = try platformSecurityScopedAccess(url: fileURL) { url -> Data in
                try Data(contentsOf: url)
            }
            guard let loaded = PlatformImage(data: data) else {
                markUnreadableImage()
                return
            }
            load(platformImage: loaded, sourceName: fileURL.lastPathComponent)
        } catch {
            markUnreadableImage()
        }
    }

    public func setPanel(_ box: DisplayOCRNormalizedBox) {
        guard bitmap != nil, let clamped = box.unitClamped else { return }
        panel = clamped
        rowBoxes = []
        label = nil
        status = nil
        selectedBox = nil
    }

    /// Replace the panel and clip rows to it. A row that falls outside is removed.
    public func updatePanel(_ box: DisplayOCRNormalizedBox) {
        guard bitmap != nil, let clamped = box.unitClamped else { return }
        panel = clamped
        rowBoxes = DisplayOCRTraining.rowsInside(
            rowBoxes,
            panel: clamped,
            imageWidth: Int(imagePixelSize.width),
            imageHeight: Int(imagePixelSize.height)
        )
        label = nil
        status = nil
        if case .row(let index) = selectedBox, rowBoxes.indices.contains(index) == false {
            selectedBox = nil
        }
    }

    public func useFullFramePanel() {
        setPanel(DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1))
    }

    @discardableResult
    public func addRowBox(_ box: DisplayOCRNormalizedBox) -> Bool {
        guard bitmap != nil, let panel else { return false }
        guard let clipped = box.unitClamped?.intersection(panel) else { return false }
        guard clipped.pixelRect(
            imageWidth: Int(imagePixelSize.width),
            imageHeight: Int(imagePixelSize.height)
        ) != nil else { return false }
        rowBoxes.append(clipped)
        label = nil
        status = nil
        return true
    }

    public func clearRowBoxes() {
        rowBoxes = []
        label = nil
        status = nil
        if case .row = selectedBox {
            selectedBox = nil
        }
    }

    public func selectBox(at point: CGPoint, containerSize: CGSize) {
        selectedBox = DisplayOCRTraining.hit(
            at: point,
            containerSize: containerSize,
            imageSize: imagePixelSize,
            panel: panel,
            rows: rowBoxes
        )?.target
    }

    public func removeSelectedBox() {
        switch selectedBox {
        case .panel:
            panel = nil
            rowBoxes = []
            label = nil
            status = nil
            selectedBox = nil
        case .row(let index) where rowBoxes.indices.contains(index):
            rowBoxes.remove(at: index)
            label = nil
            status = nil
            selectedBox = nil
        default:
            selectedBox = nil
        }
    }

    /// Drag `start` on a box from the snapshot. A miss returns false so the caller can draw a new box.
    @discardableResult
    public func adjust(
        from start: CGPoint,
        to end: CGPoint,
        containerSize: CGSize,
        basePanel: DisplayOCRNormalizedBox?,
        baseRows: [DisplayOCRNormalizedBox]
    ) -> Bool {
        guard bitmap != nil, imagePixelSize.width > 0, imagePixelSize.height > 0 else { return false }
        guard let hit = DisplayOCRTraining.hit(
            at: start,
            containerSize: containerSize,
            imageSize: imagePixelSize,
            panel: basePanel,
            rows: baseRows
        ) else { return false }
        let frame = OCRBoundingBoxLayout.aspectFitImageFrame(
            imageSize: imagePixelSize,
            containerSize: containerSize
        )
        guard frame.width > 0, frame.height > 0 else { return false }
        let dx = Double(end.x - start.x) / Double(frame.width)
        let dy = Double(end.y - start.y) / Double(frame.height)
        let imageWidth = Int(imagePixelSize.width)
        let imageHeight = Int(imagePixelSize.height)
        switch hit.target {
        case .panel:
            guard let base = basePanel else { return false }
            guard let next = DisplayOCRTraining.placed(
                base,
                edges: hit.edges,
                dx: dx,
                dy: dy,
                within: DisplayOCRTraining.unitSquare
            ), next.pixelRect(imageWidth: imageWidth, imageHeight: imageHeight) != nil else { return false }
            panel = next
            rowBoxes = DisplayOCRTraining.rowsInside(
                baseRows,
                panel: next,
                imageWidth: imageWidth,
                imageHeight: imageHeight
            )
            selectedBox = .panel
        case .row(let index):
            guard let limit = (basePanel ?? panel)?.unitClamped, baseRows.indices.contains(index) else { return false }
            panel = limit
            var rows = baseRows
            if let next = DisplayOCRTraining.placed(
                baseRows[index],
                edges: hit.edges,
                dx: dx,
                dy: dy,
                within: limit
            ), next.pixelRect(imageWidth: imageWidth, imageHeight: imageHeight) != nil {
                rows[index] = next
                selectedBox = .row(index)
            } else {
                rows.remove(at: index)
                selectedBox = nil
            }
            rowBoxes = rows
        }
        label = nil
        status = nil
        return true
    }

    @discardableResult
    public func applyDraw(containerRect: CGRect, containerSize: CGSize) -> Bool {
        guard bitmap != nil, imagePixelSize.width > 0, imagePixelSize.height > 0 else { return false }
        guard let box = DisplayOCRTraining.normalizedBox(
            fromContainerRect: containerRect,
            imageSize: imagePixelSize,
            containerSize: containerSize
        ) else { return false }
        switch drawMode {
        case .panel:
            setPanel(box)
            return panel != nil
        case .row:
            return addRowBox(box)
        }
    }

    @discardableResult
    public func decode() -> Bool {
        guard let bitmap, let panel else {
            status = .needsPanel
            return false
        }
        guard let drafted = DisplayOCRTraining.draft(
            image: bitmap,
            panel: panel,
            rowBoxes: rowBoxes,
            sourceName: sourceName
        ) else {
            status = .needsPanel
            return false
        }
        label = drafted
        status = .decoded
        return true
    }

    public func confirm(rowID: UUID, text: String) {
        guard let label else { return }
        let updated = DisplayOCRTraining.confirming(label, rowID: rowID, text: text)
        guard updated != label else { return }
        self.label = updated
    }

    public func makePackage() throws -> DisplayOCRTrainingPackage {
        guard let bitmap, let label else { throw DisplayOCRTrainingError.missingLabel }
        return try DisplayOCRTraining.package(label: label, image: bitmap)
    }

    public func markUnreadableImage() {
        bitmap = nil
        image = nil
        imagePixelSize = .zero
        sourceName = nil
        panel = nil
        rowBoxes = []
        label = nil
        status = .unreadableImage
        selectedBox = nil
    }

    public func failExport() {
        status = .exportFailed
    }

    /// Train a panel localizer from the current library into the export root.
    /// Create ML runs on macOS, off the main thread. An empty library does not start.
    public func trainPanelModel() {
        guard panelTraining != .running else { return }
        #if os(macOS)
        let examples = library
        guard !examples.examples.isEmpty else {
            panelTraining = .emptyLibrary
            return
        }
        let root = exportRoot
        panelTraining = .running
        Task { [weak self] in
            let state = await Self.trainedPanelState(library: examples, root: root)
            self?.panelTraining = state
        }
        #else
        panelTraining = .requiresMacOS
        #endif
    }

    #if os(macOS)
    nonisolated private static func trainedPanelState(
        library: DisplayOCRTrainingLibrary,
        root: URL
    ) async -> DisplayOCRPanelTrainingState {
        await Task.detached(priority: .userInitiated) {
            do {
                let url = try DisplayOCRPanelModel.train(library: library, writingModelTo: root)
                return DisplayOCRPanelTrainingState.ready(url)
            } catch let error as DisplayOCRPanelModelError {
                switch error {
                case .emptyLibrary:
                    return .emptyLibrary
                case .trainingRequiresMacOS:
                    return .requiresMacOS
                case .trainingFailed(let message):
                    return .failed(message)
                }
            } catch {
                return .failed(error.localizedDescription)
            }
        }.value
    }
    #endif

    /// Use `url` as the directory that holds package folders. An existing file is ignored.
    public func setExportRoot(_ url: URL) {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue {
            return
        }
        exportRoot = url
        refreshLibrary()
    }

    /// Write `image.png` and `label.json` in a new folder under ``exportRoot``.
    public func export() throws -> DisplayOCRTrainingExport {
        try platformSecurityScopedAccess(url: exportRoot) { root in
            try writePackage(under: root)
        }
    }

    @discardableResult
    public func exportToTemporaryDirectory() throws -> DisplayOCRTrainingExport {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(DisplayOCRTraining.exportDirectoryName, isDirectory: true)
        return try writePackage(under: root)
    }

    private func writePackage(under root: URL) throws -> DisplayOCRTrainingExport {
        let package = try makePackage()
        let directory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try DisplayOCRTraining.write(package, to: directory)
        status = .exported(directory)
        refreshLibrary()
        return DisplayOCRTrainingExport(directory: directory, package: package)
    }

    private func refreshLibrary() {
        library = platformSecurityScopedAccess(url: exportRoot) { root in
            DisplayOCRTraining.library(in: root)
        }
    }
}

private enum DisplayOCRBitmap {
    static func crop(_ image: CGImage, pixelRect: CGRect) -> CGImage? {
        guard let gray = read(image) else { return nil }
        let x0 = max(0, min(gray.width, Int(pixelRect.minX.rounded(.down))))
        let y0 = max(0, min(gray.height, Int(pixelRect.minY.rounded(.down))))
        let x1 = max(x0, min(gray.width, Int(pixelRect.maxX.rounded(.up))))
        let y1 = max(y0, min(gray.height, Int(pixelRect.maxY.rounded(.up))))
        let width = x1 - x0
        let height = y1 - y0
        guard width > 0, height > 0 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height)
        for y in 0..<height {
            let source = (y0 + y) * gray.width + x0
            pixels.replaceSubrange(
                (y * width)..<((y + 1) * width),
                with: gray.pixels[source..<(source + width)]
            )
        }
        return make(pixels: pixels, width: width, height: height)
    }

    static func pngData(_ image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    /// Same gray read as `SevenSegmentOCR`, so a crop's top row is the decoder's top row.
    private static func read(_ image: CGImage) -> (pixels: [UInt8], width: Int, height: Int)? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return nil }
        let count = width * height
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        pointer.initialize(repeating: 0, count: count)
        defer { pointer.deallocate() }
        guard let context = CGContext(
            data: pointer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (Array(UnsafeBufferPointer(start: pointer, count: count)), width, height)
    }

    private static func make(pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        guard width > 0, height > 0, pixels.count == width * height else { return nil }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
