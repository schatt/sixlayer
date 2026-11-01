//
//  DisplayOCRTraining.swift
//  SixLayerFramework
//
//  Display OCR label harness (#609). Phase A: a photo, a panel box, optional
//  row boxes, the current seven-segment decode, and a package of image plus
//  confirmed text. Layout profiles and Core ML weights are later milestones.
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
        let rows: [DisplayOCRTrainingRow]
        if clipped.isEmpty {
            rows = panelRows(from: segmentRead(panelImage, deskewMaximumDegrees: deskewMaximumDegrees))
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

    private static func panelRows(from decoded: OCRResult) -> [DisplayOCRTrainingRow] {
        let lines = decoded.extractedText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let texts = lines.isEmpty ? [""] : lines
        return texts.map { labeledRow($0, box: nil, confidence: decoded.confidence) }
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

    private var bitmap: CGImage?

    public init() {}

    public func load(platformImage: PlatformImage, sourceName: String? = nil) {
        guard let oriented = platformImage.orientedCGImage() else {
            markUnreadableImage()
            return
        }
        load(cgImage: oriented, sourceName: sourceName)
    }

    public func load(cgImage: CGImage, sourceName: String? = nil) {
        bitmap = cgImage
        image = PlatformImage(cgImage: cgImage)
        imagePixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        self.sourceName = DisplayOCRTraining.sanitizedSourceName(sourceName)
        panel = nil
        rowBoxes = []
        label = nil
        status = nil
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
    }

    public func failExport() {
        status = .exportFailed
    }

    @discardableResult
    public func exportToTemporaryDirectory() throws -> DisplayOCRTrainingExport {
        let package = try makePackage()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("display-ocr-training", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try DisplayOCRTraining.write(package, to: directory)
        status = .exported(directory)
        return DisplayOCRTrainingExport(directory: directory, package: package)
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
