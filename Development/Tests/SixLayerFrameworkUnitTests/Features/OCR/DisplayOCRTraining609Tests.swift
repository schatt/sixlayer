//
//  DisplayOCRTraining609Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Display OCR label harness (#609). Boxes are top-left normalized fractions
//  of the full image. Decode uses the current seven-segment reader on the crop.
//

import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import Testing
#if canImport(ViewInspector)
import ViewInspector
#endif
@testable import SixLayerFramework

@Suite("Display OCR training labels (#609)")
struct DisplayOCRTraining609Tests {

    @Test func unitClampClipsToTheUnitSquareAndDropsEmptyBoxes() {
        let clipped = DisplayOCRNormalizedBox(x: -0.2, y: 0.2, width: 0.5, height: 2).unitClamped
        #expect(clipped?.x == 0)
        #expect(clipped?.y == 0.2)
        #expect(abs((clipped?.width ?? -1) - 0.3) < 0.000_001)
        #expect(abs((clipped?.height ?? -1) - 0.8) < 0.000_001)
        #expect(DisplayOCRNormalizedBox(x: 0, y: 0, width: 0, height: 1).unitClamped == nil)
        #expect(DisplayOCRNormalizedBox(x: 1.2, y: 0, width: 0.2, height: 0.2).unitClamped == nil)
    }

    @Test func intersectionClipsARowToThePanel() {
        let panel = DisplayOCRNormalizedBox(x: 0, y: 0, width: 0.5, height: 0.5)
        let row = DisplayOCRNormalizedBox(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        let hit = row.intersection(panel)
        #expect(hit?.x == 0.25)
        #expect(hit?.y == 0.25)
        #expect(hit?.width == 0.25)
        #expect(hit?.height == 0.25)
        let outside = DisplayOCRNormalizedBox(x: 0.8, y: 0.8, width: 0.2, height: 0.2)
        #expect(outside.intersection(panel) == nil)
    }

    @Test func pixelRectRoundTripsAnIntegerPlacement() {
        let box = DisplayOCRNormalizedBox(
            pixelRect: CGRect(x: 40, y: 50, width: 82, height: 122),
            imageWidth: 400,
            imageHeight: 360
        )
        #expect(box.pixelRect(imageWidth: 400, imageHeight: 360) == CGRect(x: 40, y: 50, width: 82, height: 122))
    }

    @Test func cropKeepsTheTopRowOfTheBitmap() throws {
        let image = grayImage(width: 4, height: 2, pixels: [9, 9, 9, 9, 3, 3, 3, 3])
        let top = DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 0.5)
        let bottom = DisplayOCRNormalizedBox(x: 0, y: 0.5, width: 1, height: 0.5)
        let topCrop = try #require(DisplayOCRTraining.crop(image, to: top))
        let bottomCrop = try #require(DisplayOCRTraining.crop(image, to: bottom))
        #expect(topCrop.width == 4)
        #expect(topCrop.height == 1)
        #expect(providerBytes(topCrop) == [9, 9, 9, 9])
        #expect(bottomCrop.height == 1)
        #expect(providerBytes(bottomCrop) == [3, 3, 3, 3])
    }

    @Test func normalizedBoxMapsALetterboxedDragOntoTheImage() {
        let imageSize = CGSize(width: 200, height: 100)
        let containerSize = CGSize(width: 200, height: 200)
        let box = DisplayOCRTraining.normalizedBox(
            fromContainerRect: CGRect(x: 0, y: 50, width: 100, height: 50),
            imageSize: imageSize,
            containerSize: containerSize
        )
        #expect(box != nil)
        #expect(abs((box?.x ?? -1) - 0) < 0.001)
        #expect(abs((box?.y ?? -1) - 0) < 0.001)
        #expect(abs((box?.width ?? -1) - 0.5) < 0.001)
        #expect(abs((box?.height ?? -1) - 0.5) < 0.001)

        let margin = DisplayOCRTraining.normalizedBox(
            fromContainerRect: CGRect(x: 0, y: 0, width: 40, height: 20),
            imageSize: imageSize,
            containerSize: containerSize
        )
        #expect(margin == nil)

        let sliver = DisplayOCRTraining.normalizedBox(
            fromContainerRect: CGRect(x: 10, y: 60, width: 4, height: 4),
            imageSize: imageSize,
            containerSize: containerSize
        )
        #expect(sliver == nil)
    }

    @Test func draftDecodesThePanelCropAndIgnoresTheOtherDigit() throws {
        let frame = twoDigitFrame()
        let panel = DisplayOCRNormalizedBox(
            pixelRect: frame.two,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        )
        let label = try #require(DisplayOCRTraining.draft(
            image: frame.image,
            panel: panel,
            rowBoxes: [],
            sourceName: "../../pump.jpg"
        ))
        #expect(label.schemaVersion == DisplayOCRTraining.schemaVersion)
        #expect(label.origin == .topLeft)
        #expect(label.imageFileName == DisplayOCRTraining.imageFileName)
        #expect(label.imagePixelWidth == frame.image.width)
        #expect(label.imagePixelHeight == frame.image.height)
        #expect(label.sourceName == "pump.jpg")
        #expect(label.rows.count == 1)
        #expect(label.rows[0].box == nil)
        #expect(label.rows[0].decodedText == "2")
        #expect(label.rows[0].confirmedText == "2")
    }

    @Test func draftDecodesEachRowBoxOnItsOwnCrop() throws {
        let frame = twoDigitFrame()
        let full = DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1)
        let two = DisplayOCRNormalizedBox(
            pixelRect: frame.two,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        )
        let seven = DisplayOCRNormalizedBox(
            pixelRect: frame.seven,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        )
        let label = try #require(DisplayOCRTraining.draft(
            image: frame.image,
            panel: full,
            rowBoxes: [seven, two],
            sourceName: nil
        ))
        #expect(label.rows.map(\.decodedText) == ["7", "2"])
        #expect(label.rows.map(\.confirmedText) == ["7", "2"])
        #expect(label.rows[0].box != nil)
        #expect(label.rows[1].box != nil)
    }

    @Test func draftDropsARowBoxOutsideThePanel() throws {
        let frame = twoDigitFrame()
        let panel = DisplayOCRNormalizedBox(
            pixelRect: frame.two,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        )
        let seven = DisplayOCRNormalizedBox(
            pixelRect: frame.seven,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        )
        let label = try #require(DisplayOCRTraining.draft(
            image: frame.image,
            panel: panel,
            rowBoxes: [seven],
            sourceName: nil
        ))
        #expect(label.rows.map(\.decodedText) == ["2"])
        #expect(label.rows[0].box == nil)
    }

    @Test func confirmingEditsTheLabelWithoutChangingTheDecode() throws {
        let frame = twoDigitFrame()
        let panel = DisplayOCRNormalizedBox(
            pixelRect: frame.two,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        )
        let label = try #require(DisplayOCRTraining.draft(
            image: frame.image,
            panel: panel,
            rowBoxes: [],
            sourceName: nil
        ))
        let rowID = try #require(label.rows.first?.id)
        let edited = DisplayOCRTraining.confirming(label, rowID: rowID, text: "8\"1")
        #expect(edited.rows[0].confirmedText == "8\"1")
        #expect(edited.rows[0].decodedText == "2")
        let missed = DisplayOCRTraining.confirming(label, rowID: UUID(), text: "nope")
        #expect(missed == label)
    }

    @Test func sanitizedSourceNameDropsPathComponents() {
        #expect(DisplayOCRTraining.sanitizedSourceName("../../etc/passwd") == "passwd")
        #expect(DisplayOCRTraining.sanitizedSourceName("..") == nil)
        #expect(DisplayOCRTraining.sanitizedSourceName("pump photo.JPG") == "pump photo.JPG")
        #expect(DisplayOCRTraining.sanitizedSourceName(nil) == nil)
    }

    @Test func importerCancelLeavesTheCurrentPhotoAlone() {
        #expect(DisplayOCRTraining.importerCancelled(CancellationError()))
        #expect(DisplayOCRTraining.importerCancelled(CocoaError(.userCancelled)))
        #expect(DisplayOCRTraining.importerCancelled(CocoaError(.fileReadNoSuchFile)) == false)
    }

    @Test func packageRoundTripWritesOnlyThePackageFiles() throws {
        let frame = twoDigitFrame()
        let panel = DisplayOCRNormalizedBox(
            pixelRect: frame.two,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        )
        var label = try #require(DisplayOCRTraining.draft(
            image: frame.image,
            panel: panel,
            rowBoxes: [],
            sourceName: "../../etc/passwd"
        ))
        label = DisplayOCRTraining.confirming(label, rowID: try #require(label.rows.first?.id), text: "8\"1")
        label.imageFileName = "../escape.png"
        let package = try DisplayOCRTraining.package(label: label, image: frame.image)
        #expect(package.label.imageFileName == DisplayOCRTraining.imageFileName)
        #expect(package.label.sourceName == "passwd")
        #expect(package.label.rows[0].confirmedText == "8\"1")
        #expect(package.label.rows[0].decodedText == "2")

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("display-ocr-training-test-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try DisplayOCRTraining.write(package, to: directory)
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
        #expect(names == [DisplayOCRTraining.imageFileName, DisplayOCRTraining.labelFileName])

        let loaded = try DisplayOCRTraining.read(from: directory)
        #expect(loaded.label.rows[0].confirmedText == "8\"1")
        #expect(loaded.label.rows[0].decodedText == "2")
        #expect(loaded.label.sourceName == "passwd")
        #expect(loaded.label.imagePixelWidth == frame.image.width)
        #expect(loaded.label.imagePixelHeight == frame.image.height)
        let reopened = try #require(cgImage(fromPNG: loaded.imagePNG))
        #expect(reopened.width == frame.image.width)
        #expect(reopened.height == frame.image.height)
    }

    @Test func readerRejectsANewerSchema() throws {
        let json = """
        {"imageFileName":"image.png","imagePixelHeight":2,"imagePixelWidth":2,"origin":"topLeft","panel":{"height":1,"width":1,"x":0,"y":0},"rows":[],"schemaVersion":2}
        """
        let data = try #require(json.data(using: .utf8))
        #expect(throws: DisplayOCRTrainingError.unsupportedSchema(2)) {
            try DisplayOCRTraining.label(from: data)
        }
    }

    @Test @MainActor func sessionDrawsDecodesConfirmsAndExports() throws {
        let frame = twoDigitFrame()
        let session = DisplayOCRTrainingSession()
        session.load(cgImage: frame.image, sourceName: "../../roll.png")
        #expect(session.sourceName == "roll.png")
        #expect(session.imagePixelSize == CGSize(width: frame.image.width, height: frame.image.height))

        let panel = DisplayOCRNormalizedBox(
            pixelRect: frame.two,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        )
        let container = CGSize(width: 400, height: 400)
        let drag = panel.containerRect(imagePixelSize: session.imagePixelSize, containerSize: container)
        #expect(session.applyDraw(containerRect: drag, containerSize: container))
        #expect(session.panel != nil)
        #expect(session.decode())
        let rowID = try #require(session.label?.rows.first?.id)
        #expect(session.label?.rows.first?.decodedText == "2")
        session.confirm(rowID: rowID, text: "2.0")
        #expect(session.label?.rows.first?.confirmedText == "2.0")
        #expect(session.label?.rows.first?.decodedText == "2")

        let exported = try session.exportToTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: exported.directory) }
        #expect(exported.package.label.rows.first?.confirmedText == "2.0")
        let names = try FileManager.default.contentsOfDirectory(atPath: exported.directory.path).sorted()
        #expect(names == [DisplayOCRTraining.imageFileName, DisplayOCRTraining.labelFileName])
        if case .exported(let url) = session.status {
            #expect(url == exported.directory)
        } else {
            Issue.record("Export should record the package directory")
        }
    }

    @Test @MainActor func sessionLoadsAPhotoFileAndUsesTheFullFrame() throws {
        let image = grayImage(width: 4, height: 2, pixels: [9, 9, 9, 9, 3, 3, 3, 3])
        let png = try #require(pngData(image))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("display-ocr-load-\(UUID().uuidString).png")
        try png.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let session = DisplayOCRTrainingSession()
        session.load(fileURL: url)
        #expect(session.imagePixelSize.width == 4)
        #expect(session.imagePixelSize.height == 2)
        session.useFullFramePanel()
        #expect(session.panel?.x == 0)
        #expect(session.panel?.y == 0)
        #expect(session.panel?.width == 1)
        #expect(session.panel?.height == 1)
        #expect(session.decode())
        #expect(session.label?.rows.count == 1)
        #expect(session.label?.rows.first?.decodedText == "")
    }

    @Test func defaultExportRootIsASubdirectoryOfTheCurrentDirectory() {
        let current = URL(fileURLWithPath: "/tmp/pump-session", isDirectory: true)
        let root = DisplayOCRTraining.defaultExportRoot(currentDirectory: current)
        #expect(root.lastPathComponent == DisplayOCRTraining.exportDirectoryName)
        #expect(
            root.deletingLastPathComponent().standardizedFileURL.path
                == current.standardizedFileURL.path
        )
    }

    @Test @MainActor func exportWritesThePackageInsideTheSelectedDirectory() throws {
        let frame = twoDigitFrame()
        let session = DisplayOCRTrainingSession()
        session.load(cgImage: frame.image, sourceName: "pump.png")
        let panel = DisplayOCRNormalizedBox(
            pixelRect: frame.two,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        )
        session.setPanel(panel)
        #expect(session.decode())

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("display-ocr-chosen-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        session.setExportRoot(root)
        let exported = try session.export()

        let exportedPath = exported.directory.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        #expect(exportedPath.hasPrefix(rootPath + "/"))
        #expect(exported.directory.lastPathComponent != DisplayOCRTraining.imageFileName)
        let names = try FileManager.default.contentsOfDirectory(atPath: exported.directory.path).sorted()
        #expect(names == [DisplayOCRTraining.imageFileName, DisplayOCRTraining.labelFileName])
        #expect(session.exportRoot.standardizedFileURL.path == rootPath)
    }

    @Test @MainActor func aNewSessionUsesTheCurrentDirectoryExportRoot() {
        let session = DisplayOCRTrainingSession()
        #expect(
            session.exportRoot.standardizedFileURL.path
                == DisplayOCRTraining.defaultExportRoot().standardizedFileURL.path
        )
    }

    @Test func libraryKeepsDifferentShotsAndReportsBadFolders() throws {
        let root = try makeDirectory("display-ocr-library")
        defer { try? FileManager.default.removeItem(at: root) }
        let wide = DisplayOCRNormalizedBox(x: 0.1, y: 0.2, width: 0.7, height: 0.3)
        let narrow = DisplayOCRNormalizedBox(x: 0.55, y: 0.05, width: 0.2, height: 0.8)
        let priceRow = DisplayOCRNormalizedBox(x: 0.12, y: 0.22, width: 0.4, height: 0.12)
        try writeExample(
            confirmed: "12.9",
            panel: wide,
            row: priceRow,
            imageWidth: 8,
            imageHeight: 4,
            to: root.appendingPathComponent("close-shot", isDirectory: true)
        )
        try writeExample(
            confirmed: "3.50",
            panel: narrow,
            row: nil,
            imageWidth: 5,
            imageHeight: 9,
            to: root.appendingPathComponent("far-shot", isDirectory: true)
        )
        try writeExample(
            confirmed: "777",
            panel: wide,
            row: nil,
            imageWidth: 4,
            imageHeight: 2,
            to: root.appendingPathComponent("deeper/inner", isDirectory: true)
        )
        let outside = FileManager.default.temporaryDirectory
            .appendingPathComponent("display-ocr-outside-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: outside) }
        try writeExample(
            confirmed: "999",
            panel: narrow,
            row: nil,
            imageWidth: 4,
            imageHeight: 2,
            to: outside
        )
        try FileManager.default.createSymbolicLink(
            at: root.appendingPathComponent("escape"),
            withDestinationURL: outside
        )
        try FileManager.default.createSymbolicLink(
            at: root.appendingPathComponent("alias"),
            withDestinationURL: root.appendingPathComponent("close-shot", isDirectory: true)
        )
        try writeBadSchema(to: root.appendingPathComponent("bad-schema", isDirectory: true))
        try writeLabelOnly(to: root.appendingPathComponent("missing-image", isDirectory: true))
        let missingLabel = root.appendingPathComponent("missing-label", isDirectory: true)
        try FileManager.default.createDirectory(at: missingLabel, withIntermediateDirectories: true)
        try Data("not a label".utf8).write(to: missingLabel.appendingPathComponent("image.png"))
        try Data("notes".utf8).write(to: root.appendingPathComponent("notes.txt"))

        let library = DisplayOCRTraining.library(in: root)
        func packages(confirmed text: String) -> [DisplayOCRTrainingPackage] {
            library.examples.compactMap { example in
                example.package.label.rows.first?.confirmedText == text ? example.package : nil
            }
        }
        let closeShot = packages(confirmed: "12.9")
        let farShot = packages(confirmed: "3.50")
        #expect(library.examples.count == 2)
        #expect(closeShot.count == 1)
        #expect(closeShot.first?.label.panel == wide.unitClamped)
        #expect(closeShot.first?.label.rows.first?.box == priceRow)
        #expect(closeShot.first?.label.imagePixelWidth == 8)
        #expect(closeShot.first?.imagePNG.isEmpty == false)
        #expect(farShot.count == 1)
        #expect(farShot.first?.label.panel == narrow.unitClamped)
        #expect(farShot.first?.label.rows.first?.box == nil)
        #expect(farShot.first?.label.imagePixelHeight == 9)
        #expect(packages(confirmed: "777").isEmpty)
        #expect(packages(confirmed: "999").isEmpty)
        #expect(rejection(in: library, named: "bad-schema") == .unsupportedSchema(2))
        #expect(rejection(in: library, named: "missing-image") == .unreadablePackage)
        #expect(rejection(in: library, named: "missing-label") == .unreadablePackage)
        #expect(rejection(in: library, named: "deeper") == .unreadablePackage)
        #expect(rejection(in: library, named: "escape") == .unreadablePackage)
        #expect(rejection(in: library, named: "alias") == .unreadablePackage)
        #expect(library.rejections.contains { $0.directory.lastPathComponent == "notes.txt" } == false)
        #expect(library.examples.contains { $0.directory.lastPathComponent == "notes.txt" } == false)

        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("display-ocr-missing-\(UUID().uuidString)", isDirectory: true)
        let empty = DisplayOCRTraining.library(in: missing)
        #expect(empty.examples.isEmpty)
        #expect(empty.rejections.isEmpty)
    }

    @Test @MainActor func exportJoinsTheTrainingLibrary() throws {
        let root = try makeDirectory("display-ocr-join")
        defer { try? FileManager.default.removeItem(at: root) }
        try writeExample(
            confirmed: "9.99",
            panel: DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1),
            row: nil,
            imageWidth: 4,
            imageHeight: 2,
            to: root.appendingPathComponent("already", isDirectory: true)
        )
        try writeBadSchema(to: root.appendingPathComponent("bad-schema", isDirectory: true))

        let frame = twoDigitFrame()
        let session = DisplayOCRTrainingSession()
        session.load(cgImage: frame.image, sourceName: "pump.png")
        session.setPanel(DisplayOCRNormalizedBox(
            pixelRect: frame.two,
            imageWidth: frame.image.width,
            imageHeight: frame.image.height
        ))
        #expect(session.decode())
        let rowID = try #require(session.label?.rows.first?.id)
        session.confirm(rowID: rowID, text: "2.0")
        session.setExportRoot(root)
        #expect(session.library.examples.count == 1)
        #expect(session.library.rejections.count == 1)
        _ = try session.export()

        let confirmed = Set(session.library.examples.map { $0.package.label.rows[0].confirmedText })
        #expect(confirmed == ["9.99", "2.0"])
        #expect(session.library.examples.count == 2)
        #expect(session.library.rejections.count == 1)
    }

    @Test @MainActor func librarySummaryShowsHowManyExamplesJoined() {
        let i18n = InternationalizationService()
        #expect(
            i18n.localizedString(
                for: "SixLayerFramework.ocr.training.libraryCount",
                arguments: ["2"]
            ) == "Library · 2"
        )
        #expect(
            i18n.localizedString(
                for: "SixLayerFramework.ocr.training.librarySkipped",
                arguments: ["1"]
            ) == "Skipped · 1"
        )
        #if canImport(ViewInspector)
        let summary = DisplayOCRTrainingLibrarySummary(exampleCount: 2, rejectionCount: 1)
        let values = findAllInViewHierarchy(summary, ViewInspector.ViewType.Text.self)
            .compactMap { try? $0.string() }
        #expect(values.contains("Library · 2"))
        #expect(values.contains("Skipped · 1"))
        let quiet = DisplayOCRTrainingLibrarySummary(exampleCount: 2, rejectionCount: 0)
        let quietValues = findAllInViewHierarchy(quiet, ViewInspector.ViewType.Text.self)
            .compactMap { try? $0.string() }
        #expect(quietValues.contains("Library · 2"))
        #expect(quietValues.contains { $0.hasPrefix("Skipped") } == false)
        #endif
    }

    @Test func visionBoxesMapOntoThePanelAsTopLeftRows() {
        let panel = DisplayOCRNormalizedBox(x: 0.1, y: 0.2, width: 0.5, height: 0.4)
        let upper = CGRect(x: 0.1, y: 0.6, width: 0.3, height: 0.2)
        let lowerLeft = CGRect(x: 0.1, y: 0.0, width: 0.2, height: 0.25)
        let lowerRight = CGRect(x: 0.4, y: 0.05, width: 0.2, height: 0.2)
        let rows = DisplayOCRTraining.rowBoxes(
            fromVisionBoxes: [lowerRight, upper, lowerLeft],
            panel: panel
        )
        #expect(rows.count == 2)
        #expect(abs(rows[0].x - 0.15) < 0.000_001)
        #expect(abs(rows[0].y - 0.28) < 0.000_001)
        #expect(abs(rows[0].width - 0.15) < 0.000_001)
        #expect(abs(rows[0].height - 0.08) < 0.000_001)
        #expect(abs(rows[1].x - 0.15) < 0.000_001)
        #expect(abs(rows[1].y - 0.5) < 0.000_001)
        #expect(abs(rows[1].width - 0.25) < 0.000_001)
        #expect(abs(rows[1].height - 0.1) < 0.000_001)
    }

    @Test @MainActor func removingOneRowLeavesTheOthers() {
        let session = squareSession()
        session.setPanel(DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1))
        #expect(session.addRowBox(DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.2, height: 0.1)))
        #expect(session.addRowBox(DisplayOCRNormalizedBox(x: 0.1, y: 0.4, width: 0.2, height: 0.1)))
        let container = CGSize(width: 100, height: 100)
        session.selectBox(at: CGPoint(x: 20, y: 15), containerSize: container)
        #expect(session.selectedBox == .row(0))
        session.removeSelectedBox()
        #expect(session.rowBoxes.count == 1)
        #expect(abs(session.rowBoxes[0].y - 0.4) < 0.001)
        #expect(session.selectedBox == nil)
    }

    @Test @MainActor func removingThePanelClearsItsRows() {
        let session = squareSession()
        session.setPanel(DisplayOCRNormalizedBox(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
        #expect(session.addRowBox(DisplayOCRNormalizedBox(x: 0.25, y: 0.62, width: 0.15, height: 0.1)))
        session.selectBox(at: CGPoint(x: 50, y: 50), containerSize: CGSize(width: 100, height: 100))
        #expect(session.selectedBox == .panel)
        session.removeSelectedBox()
        #expect(session.panel == nil)
        #expect(session.rowBoxes.isEmpty)
    }

    @Test @MainActor func shrinkingThePanelClipsARowAndDropsOneOutside() {
        let session = squareSession()
        session.setPanel(DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1))
        #expect(session.addRowBox(DisplayOCRNormalizedBox(x: 0.1, y: 0.1, width: 0.2, height: 0.2)))
        #expect(session.addRowBox(DisplayOCRNormalizedBox(x: 0.7, y: 0.7, width: 0.2, height: 0.2)))
        session.updatePanel(DisplayOCRNormalizedBox(x: 0, y: 0, width: 0.5, height: 0.5))
        #expect(session.panel?.width == 0.5)
        #expect(session.rowBoxes.count == 1)
        #expect(abs(session.rowBoxes[0].x - 0.1) < 0.001)
        #expect(abs(session.rowBoxes[0].width - 0.2) < 0.001)
        #expect(session.label == nil)
    }

    @Test @MainActor func draggingMovesABoxAndAnEdgeResizesIt() {
        let session = squareSession()
        let panel = DisplayOCRNormalizedBox(x: 0.2, y: 0.2, width: 0.5, height: 0.5)
        session.setPanel(panel)
        #expect(session.addRowBox(DisplayOCRNormalizedBox(x: 0.45, y: 0.55, width: 0.2, height: 0.1)))
        #expect(session.decode())
        let container = CGSize(width: 100, height: 100)
        #expect(session.adjust(
            from: CGPoint(x: 45, y: 45),
            to: CGPoint(x: 55, y: 45),
            containerSize: container,
            basePanel: panel,
            baseRows: session.rowBoxes
        ))
        #expect(abs((session.panel?.x ?? 0) - 0.3) < 0.001)
        #expect(abs((session.panel?.width ?? 0) - 0.5) < 0.001)
        #expect(session.label == nil)
        #expect(session.adjust(
            from: CGPoint(x: 30, y: 45),
            to: CGPoint(x: 20, y: 45),
            containerSize: container,
            basePanel: session.panel,
            baseRows: session.rowBoxes
        ))
        #expect(abs((session.panel?.x ?? 1) - 0.2) < 0.001)
        #expect(abs((session.panel?.width ?? 0) - 0.6) < 0.001)
        #expect(session.adjust(
            from: CGPoint(x: 55, y: 60),
            to: CGPoint(x: 0, y: 60),
            containerSize: container,
            basePanel: session.panel,
            baseRows: session.rowBoxes
        ))
        #expect(session.rowBoxes[0].x == session.panel?.x)
        #expect(abs(session.rowBoxes[0].width - 0.2) < 0.001)
        #expect(session.adjust(
            from: CGPoint(x: 1, y: 1),
            to: CGPoint(x: 40, y: 40),
            containerSize: container,
            basePanel: session.panel,
            baseRows: session.rowBoxes
        ) == false)
    }

    @Test @MainActor func openingASealedPanelSuggestsBoxesAndDigits() throws {
        let frame = sealedFrame()
        let session = DisplayOCRTrainingSession()
        session.load(cgImage: frame.image)
        let panel = try #require(session.panel)
        let width = Double(frame.image.width)
        let height = Double(frame.image.height)
        #expect(abs(panel.x * width - Double(frame.originX)) < 24)
        #expect(abs(panel.y * height - Double(frame.originY)) < 24)
        #expect(session.rowBoxes.isEmpty == false)
        for row in session.rowBoxes {
            let overlap = row.intersection(panel)
            #expect(overlap != nil)
            if let overlap {
                #expect(abs(overlap.x - row.x) < 0.001)
                #expect(abs(overlap.width - row.width) < 0.001)
                #expect(abs(overlap.y - row.y) < 0.001)
                #expect(abs(overlap.height - row.height) < 0.001)
            }
        }
        let text = session.label?.rows.map(\.confirmedText).joined(separator: "\n") ?? ""
        #expect(text.contains("32.88"))
        #expect(text.contains("8.022"))
        #expect(session.decode())
        let refreshed = session.label?.rows.map(\.confirmedText).joined(separator: "\n") ?? ""
        #expect(refreshed.contains("32.88"))
        #expect(refreshed.contains("8.022"))
    }

    @Test @MainActor func openingABlankPhotoSuggestsNothing() {
        let image = grayImage(width: 4, height: 2, pixels: [UInt8](repeating: 180, count: 8))
        let session = DisplayOCRTrainingSession()
        session.load(cgImage: image)
        #expect(session.panel == nil)
        #expect(session.rowBoxes.isEmpty)
        #expect(session.label == nil)
    }

    @Test @MainActor func restoringALabelDoesNotReplaceItWithASuggestion() throws {
        let frame = sealedFrame()
        let kept = DisplayOCRNormalizedBox(x: 0, y: 0, width: 1, height: 1)
        let label = DisplayOCRTrainingLabel(
            schemaVersion: DisplayOCRTraining.schemaVersion,
            origin: .topLeft,
            imageFileName: DisplayOCRTraining.imageFileName,
            imagePixelWidth: frame.image.width,
            imagePixelHeight: frame.image.height,
            sourceName: "pump.png",
            panel: kept,
            rows: [
                DisplayOCRTrainingRow(
                    box: nil,
                    decodedText: "1",
                    confirmedText: "KEEP",
                    confidence: 1
                )
            ]
        )
        let session = DisplayOCRTrainingSession()
        session.restore(cgImage: frame.image, label: label)
        #expect(session.panel == kept)
        #expect(session.rowBoxes.isEmpty)
        #expect(session.label?.rows.first?.confirmedText == "KEEP")
    }

    // MARK: - Fixtures

    private func makeDirectory(_ prefix: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func writeExample(
        confirmed: String,
        panel: DisplayOCRNormalizedBox,
        row: DisplayOCRNormalizedBox?,
        imageWidth: Int,
        imageHeight: Int,
        to directory: URL
    ) throws {
        let pixels = [UInt8](repeating: 40, count: imageWidth * imageHeight)
        let image = grayImage(width: imageWidth, height: imageHeight, pixels: pixels)
        let label = DisplayOCRTrainingLabel(
            schemaVersion: DisplayOCRTraining.schemaVersion,
            origin: .topLeft,
            imageFileName: DisplayOCRTraining.imageFileName,
            imagePixelWidth: imageWidth,
            imagePixelHeight: imageHeight,
            sourceName: "pump.png",
            panel: panel,
            rows: [
                DisplayOCRTrainingRow(
                    box: row,
                    decodedText: confirmed,
                    confirmedText: confirmed,
                    confidence: 1
                )
            ]
        )
        let package = try DisplayOCRTraining.package(label: label, image: image)
        try DisplayOCRTraining.write(package, to: directory)
    }

    private func writeBadSchema(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let json = """
        {"imageFileName":"image.png","imagePixelHeight":2,"imagePixelWidth":2,"origin":"topLeft","panel":{"height":1,"width":1,"x":0,"y":0},"rows":[],"schemaVersion":2}
        """
        try Data(json.utf8).write(to: directory.appendingPathComponent(DisplayOCRTraining.labelFileName))
        try Data("png".utf8).write(to: directory.appendingPathComponent(DisplayOCRTraining.imageFileName))
    }

    private func writeLabelOnly(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let json = """
        {"imageFileName":"image.png","imagePixelHeight":2,"imagePixelWidth":2,"origin":"topLeft","panel":{"height":1,"width":1,"x":0,"y":0},"rows":[],"schemaVersion":1}
        """
        try Data(json.utf8).write(to: directory.appendingPathComponent(DisplayOCRTraining.labelFileName))
    }

    private func rejection(
        in library: DisplayOCRTrainingLibrary,
        named name: String
    ) -> DisplayOCRTrainingError? {
        library.rejections.first { $0.directory.lastPathComponent == name }?.error
    }

    @MainActor
    private func squareSession() -> DisplayOCRTrainingSession {
        let session = DisplayOCRTrainingSession()
        session.load(cgImage: grayImage(
            width: 100,
            height: 100,
            pixels: [UInt8](repeating: 180, count: 10_000)
        ))
        return session
    }

    private func sealedFrame() -> (image: CGImage, originX: Int, originY: Int) {
        let panel = SegmentPanel.render(
            rows: [sealedAtoms("32.88"), sealedAtoms("8.022")],
            bezelLevel: 40,
            bezelWidth: 8
        )
        let originX = 80
        let originY = 100
        let image = embed(
            panel,
            originX: originX,
            originY: originY,
            canvasWidth: 1200,
            canvasHeight: 900
        )
        return (image, originX, originY)
    }

    private func sealedAtoms(_ text: String) -> [SegmentPanel.Atom] {
        text.map { character in
            switch character {
            case "0"..."9":
                return .digit(sealedDigit(Int(String(character)) ?? 0))
            case ".":
                return .period
            default:
                return .gap(0)
            }
        }
    }

    private func sealedDigit(_ value: Int) -> SevenSegmentPattern {
        switch value {
        case 0: return [.a, .b, .c, .d, .e, .f]
        case 1: return [.b, .c]
        case 2: return [.a, .b, .d, .e, .g]
        case 3: return [.a, .b, .c, .d, .g]
        case 4: return [.b, .c, .f, .g]
        case 5: return [.a, .c, .d, .f, .g]
        case 6: return [.a, .c, .d, .e, .f, .g]
        case 7: return [.a, .b, .c]
        case 8: return [.a, .b, .c, .d, .e, .f, .g]
        default: return [.a, .b, .c, .d, .f, .g]
        }
    }

    private func embed(
        _ panel: CGImage,
        originX: Int,
        originY: Int,
        canvasWidth: Int,
        canvasHeight: Int
    ) -> CGImage {
        var pixels = [UInt8](repeating: 180, count: canvasWidth * canvasHeight)
        let panelWidth = panel.width
        let panelHeight = panel.height
        if let provider = panel.dataProvider,
           let data = provider.data,
           CFDataGetLength(data) >= panelWidth * panelHeight,
           let bytes = CFDataGetBytePtr(data) {
            let rowBytes = panel.bytesPerRow
            for y in 0..<panelHeight {
                let destY = originY + y
                guard destY >= 0, destY < canvasHeight else { continue }
                for x in 0..<panelWidth {
                    let destX = originX + x
                    guard destX >= 0, destX < canvasWidth else { continue }
                    pixels[destY * canvasWidth + destX] = bytes[y * rowBytes + x]
                }
            }
        }
        return grayImage(width: canvasWidth, height: canvasHeight, pixels: pixels)
    }

    private func twoDigitFrame() -> (image: CGImage, two: CGRect, seven: CGRect) {
        let two = sprite([.a, .b, .d, .e, .g])
        let seven = sprite([.a, .b, .c])
        let canvasWidth = 400
        let canvasHeight = 360
        let twoOrigin = (x: 24, y: 20)
        let sevenOrigin = (x: 220, y: 180)
        var pixels = [UInt8](repeating: 214, count: canvasWidth * canvasHeight)
        blit(two, into: &pixels, canvasWidth: canvasWidth, canvasHeight: canvasHeight, originX: twoOrigin.x, originY: twoOrigin.y)
        blit(seven, into: &pixels, canvasWidth: canvasWidth, canvasHeight: canvasHeight, originX: sevenOrigin.x, originY: sevenOrigin.y)
        let image = grayImage(width: canvasWidth, height: canvasHeight, pixels: pixels)
        return (
            image,
            CGRect(x: twoOrigin.x, y: twoOrigin.y, width: two.width, height: two.height),
            CGRect(x: sevenOrigin.x, y: sevenOrigin.y, width: seven.width, height: seven.height)
        )
    }

    /// One digit, same cell geometry the seven-segment fixtures use.
    private func sprite(_ pattern: SevenSegmentPattern) -> (pixels: [UInt8], width: Int, height: Int) {
        let cellWidth = 50
        let cellHeight = 90
        let stroke = 12
        let padding = 16
        let width = cellWidth + padding * 2
        let height = cellHeight + padding * 2
        var pixels = [UInt8](repeating: 214, count: width * height)
        let x = padding
        let y = padding
        var rects: [CGRect] = []
        if pattern == [.b, .c] {
            rects = [CGRect(x: x + cellWidth - stroke, y: y, width: stroke, height: cellHeight)]
        } else {
            let mid = y + cellHeight / 2 - stroke / 2
            if pattern.contains(.a) { rects.append(CGRect(x: x + stroke, y: y, width: cellWidth - 2 * stroke, height: stroke)) }
            if pattern.contains(.b) { rects.append(CGRect(x: x + cellWidth - stroke, y: y + stroke, width: stroke, height: cellHeight / 2 - stroke)) }
            if pattern.contains(.c) { rects.append(CGRect(x: x + cellWidth - stroke, y: y + cellHeight / 2, width: stroke, height: cellHeight / 2 - stroke)) }
            if pattern.contains(.d) { rects.append(CGRect(x: x + stroke, y: y + cellHeight - stroke, width: cellWidth - 2 * stroke, height: stroke)) }
            if pattern.contains(.e) { rects.append(CGRect(x: x, y: y + cellHeight / 2, width: stroke, height: cellHeight / 2 - stroke)) }
            if pattern.contains(.f) { rects.append(CGRect(x: x, y: y + stroke, width: stroke, height: cellHeight / 2 - stroke)) }
            if pattern.contains(.g) { rects.append(CGRect(x: x + stroke, y: mid, width: cellWidth - 2 * stroke, height: stroke)) }
        }
        for rect in rects {
            fill(&pixels, width: width, height: height, rect: rect, value: 22)
        }
        return (pixels, width, height)
    }

    private func blit(
        _ sprite: (pixels: [UInt8], width: Int, height: Int),
        into pixels: inout [UInt8],
        canvasWidth: Int,
        canvasHeight: Int,
        originX: Int,
        originY: Int
    ) {
        for y in 0..<sprite.height {
            let destY = originY + y
            guard destY >= 0, destY < canvasHeight else { continue }
            for x in 0..<sprite.width {
                let destX = originX + x
                guard destX >= 0, destX < canvasWidth else { continue }
                pixels[destY * canvasWidth + destX] = sprite.pixels[y * sprite.width + x]
            }
        }
    }

    private func fill(_ pixels: inout [UInt8], width: Int, height: Int, rect: CGRect, value: UInt8) {
        let x0 = max(0, Int(rect.minX))
        let y0 = max(0, Int(rect.minY))
        let x1 = min(width, Int(rect.maxX.rounded(.up)))
        let y1 = min(height, Int(rect.maxY.rounded(.up)))
        guard x1 > x0, y1 > y0 else { return }
        for y in y0..<y1 {
            for x in x0..<x1 {
                pixels[y * width + x] = value
            }
        }
    }

    private func grayImage(width: Int, height: Int, pixels: [UInt8]) -> CGImage {
        let data = Data(pixels) as CFData
        let provider = CGDataProvider(data: data)!
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
        )!
    }

    private func providerBytes(_ image: CGImage) -> [UInt8] {
        guard let data = image.dataProvider?.data else { return [] }
        let bytes = CFDataGetBytePtr(data)
        let rowBytes = image.bytesPerRow
        var pixels = [UInt8]()
        pixels.reserveCapacity(image.width * image.height)
        for y in 0..<image.height {
            for x in 0..<image.width {
                if let bytes {
                    pixels.append(bytes[y * rowBytes + x])
                }
            }
        }
        return pixels
    }

    private func pngData(_ image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            "public.png" as CFString,
            1,
            nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    private func cgImage(fromPNG data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
