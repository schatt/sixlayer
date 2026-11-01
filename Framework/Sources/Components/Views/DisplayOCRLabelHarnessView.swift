//
//  DisplayOCRLabelHarnessView.swift
//  SixLayerFramework
//
//  Phase A display OCR label harness UI (#609).
//

import SwiftUI
import UniformTypeIdentifiers

/// Interactive harness: load a photo, draw panel/row ROIs, run ``OCRProcessingMode/ssocr``, confirm text, export.
public struct DisplayOCRLabelHarnessView: View {
    public enum DrawMode: String, CaseIterable, Identifiable, Sendable {
        case panel
        case row

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .panel: return "Panel ROI"
            case .row: return "Row ROI"
            }
        }
    }

    private let deskewMaximumDegrees: Double
    private let ocrService: OCRServiceProtocol
    private let onExport: (DisplayOCRLabelPackage) -> Void

    @State private var image: PlatformImage?
    @State private var showPicker = false
    @State private var drawMode: DrawMode = .panel
    @State private var panelNormalized: CGRect?
    @State private var rowNormalizedRects: [CGRect] = []
    @State private var rowTexts: [String] = []
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var isDecoding = false
    @State private var statusMessage: String?
    @State private var exportDocument = DisplayOCRLabelDocument.placeholder
    @State private var showExporter = false

    public init(
        deskewMaximumDegrees: Double = 3,
        ocrService: OCRServiceProtocol? = nil,
        onExport: @escaping (DisplayOCRLabelPackage) -> Void = { _ in }
    ) {
        self.deskewMaximumDegrees = deskewMaximumDegrees
        self.ocrService = ocrService ?? OCRServiceFactory.create()
        self.onExport = onExport
    }

    public var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 12) {
            controls
            imageCanvas
            rowEditors
            exportControls
            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .automaticCompliance(named: "DisplayOCRLabelStatus")
            }
        }
        .padding()
        .sheet(isPresented: $showPicker) {
            UnifiedImagePicker { selected in
                resetLabels(keepingImage: selected)
                showPicker = false
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: $exportDocument,
            contentType: .json,
            defaultFilename: "display-ocr-label"
        ) { result in
            if case .failure(let error) = result {
                statusMessage = error.localizedDescription
            } else {
                statusMessage = "Exported label package"
            }
        }
        .automaticCompliance(named: "DisplayOCRLabelHarnessView")
    }

    private var controls: some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            HStack {
                Button("Load Photo") { showPicker = true }
                    .automaticCompliance(named: "DisplayOCRLabelLoadPhoto")
                Picker("Draw", selection: $drawMode) {
                    ForEach(DrawMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .automaticCompliance(named: "DisplayOCRLabelDrawMode")
            }
            HStack {
                Button("Decode .ssocr") {
                    Task { await decodePanel() }
                }
                .disabled(image == nil || panelNormalized == nil || isDecoding)
                .automaticCompliance(named: "DisplayOCRLabelDecode")
                Button("Clear ROIs") {
                    panelNormalized = nil
                    rowNormalizedRects = []
                    rowTexts = []
                    statusMessage = nil
                }
                .disabled(image == nil)
                .automaticCompliance(named: "DisplayOCRLabelClearROIs")
            }
        }
    }

    private var imageCanvas: some View {
        Group {
            if let image {
                GeometryReader { geometry in
                    let containerSize = geometry.size
                    let imageSize = image.size
                    ZStack(alignment: .topLeading) {
                        image.platformImageView()
                            .resizable()
                            .scaledToFit()
                            .frame(width: containerSize.width, height: containerSize.height)
                            .automaticCompliance(named: "DisplayOCRLabelImage")

                        if let panelNormalized {
                            roiOverlay(
                                panelNormalized,
                                color: .green,
                                imageSize: imageSize,
                                containerSize: containerSize
                            )
                        }
                        ForEach(Array(rowNormalizedRects.enumerated()), id: \.offset) { _, rect in
                            roiOverlay(
                                rect,
                                color: .orange,
                                imageSize: imageSize,
                                containerSize: containerSize
                            )
                        }
                        if let dragStart, let dragCurrent {
                            let live = normalizedRect(
                                from: dragStart,
                                to: dragCurrent,
                                imageSize: imageSize,
                                containerSize: containerSize
                            )
                            roiOverlay(
                                live,
                                color: .yellow,
                                imageSize: imageSize,
                                containerSize: containerSize
                            )
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(dragGesture(imageSize: imageSize, containerSize: containerSize))
                }
                .frame(minHeight: 240)
                .aspectRatio(max(image.size.width, 1) / max(image.size.height, 1), contentMode: .fit)
            } else {
                Text("Load a display photo to begin labeling.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .automaticCompliance(named: "DisplayOCRLabelEmpty")
            }
        }
    }

    private var rowEditors: some View {
        Group {
            if !rowTexts.isEmpty {
                platformVStackContainer(alignment: .leading, spacing: 8) {
                    Text("Confirmed rows")
                        .font(.headline)
                    ForEach(Array(rowTexts.enumerated()), id: \.offset) { index, _ in
                        TextField("Row \(index + 1)", text: binding(forRow: index))
                            .automaticCompliance(named: "DisplayOCRLabelRowText\(index)")
                    }
                }
            }
        }
    }

    private var exportControls: some View {
        Button("Export Label Package") {
            exportCurrentPackage()
        }
        .disabled(image == nil || panelNormalized == nil || rowTexts.isEmpty)
        .automaticCompliance(named: "DisplayOCRLabelExport")
    }

    private func roiOverlay(
        _ normalized: CGRect,
        color: Color,
        imageSize: CGSize,
        containerSize: CGSize
    ) -> some View {
        let displayRect = OCRBoundingBoxLayout.visionNormalizedToContainer(
            normalized,
            imageSize: imageSize,
            containerSize: containerSize
        )
        return Rectangle()
            .stroke(color, lineWidth: 2)
            .background(Rectangle().fill(color.opacity(0.12)))
            .frame(width: max(displayRect.width, 0), height: max(displayRect.height, 0))
            .offset(x: displayRect.origin.x, y: displayRect.origin.y)
            .allowsHitTesting(false)
    }

    private func dragGesture(imageSize: CGSize, containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = value.startLocation
                }
                dragCurrent = value.location
            }
            .onEnded { value in
                let start = dragStart ?? value.startLocation
                let end = value.location
                let normalized = normalizedRect(
                    from: start,
                    to: end,
                    imageSize: imageSize,
                    containerSize: containerSize
                )
                commitROI(normalized)
                dragStart = nil
                dragCurrent = nil
            }
    }

    private func normalizedRect(
        from start: CGPoint,
        to end: CGPoint,
        imageSize: CGSize,
        containerSize: CGSize
    ) -> CGRect {
        let containerRect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        return OCRBoundingBoxLayout.containerRectToVisionNormalized(
            containerRect,
            imageSize: imageSize,
            containerSize: containerSize
        )
    }

    private func commitROI(_ normalized: CGRect) {
        guard normalized.width > 0.002, normalized.height > 0.002 else { return }
        switch drawMode {
        case .panel:
            panelNormalized = normalized
            statusMessage = "Panel ROI set"
        case .row:
            rowNormalizedRects.append(normalized)
            if rowTexts.count < rowNormalizedRects.count {
                rowTexts.append("")
            }
            statusMessage = "Row ROI added (\(rowNormalizedRects.count))"
        }
    }

    @MainActor
    private func decodePanel() async {
        guard let image, let panelNormalized else { return }
        isDecoding = true
        defer { isDecoding = false }
        do {
            let result = try await DisplayOCRLabelHarness.decode(
                image: image,
                panelNormalizedRect: panelNormalized,
                deskewMaximumDegrees: deskewMaximumDegrees,
                service: ocrService
            )
            let texts = DisplayOCRLabelHarness.rowTexts(from: result)
            rowTexts = texts.isEmpty ? [result.extractedText].filter { !$0.isEmpty } : texts
            while rowNormalizedRects.count > rowTexts.count {
                rowNormalizedRects.removeLast()
            }
            statusMessage = rowTexts.isEmpty ? "Decode returned no rows" : "Decoded \(rowTexts.count) row(s)"
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func exportCurrentPackage() {
        guard let image, let panelNormalized else { return }
        let rows: [(boundingBox: CGRect?, confirmedText: String)] = rowTexts.enumerated().map { index, text in
            let box = index < rowNormalizedRects.count ? rowNormalizedRects[index] : nil
            return (boundingBox: box, confirmedText: text)
        }
        guard let package = DisplayOCRLabelHarness.makePackage(
            image: image,
            panelNormalizedRect: panelNormalized,
            rows: rows,
            deskewMaximumDegrees: deskewMaximumDegrees
        ) else {
            statusMessage = "Could not encode image PNG"
            return
        }
        exportDocument = DisplayOCRLabelDocument(package: package)
        onExport(package)
        showExporter = true
        statusMessage = "Ready to export"
    }

    private func resetLabels(keepingImage newImage: PlatformImage) {
        image = newImage
        panelNormalized = nil
        rowNormalizedRects = []
        rowTexts = []
        statusMessage = "Photo loaded"
    }

    private func binding(forRow index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < rowTexts.count else { return "" }
                return rowTexts[index]
            },
            set: { newValue in
                while rowTexts.count <= index {
                    rowTexts.append("")
                }
                rowTexts[index] = newValue
            }
        )
    }
}

/// FileDocument wrapper so ``fileExporter`` can write the JSON package.
public struct DisplayOCRLabelDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json] }

    public var package: DisplayOCRLabelPackage

    public static var placeholder: DisplayOCRLabelDocument {
        DisplayOCRLabelDocument(
            package: DisplayOCRLabelPackage(
                imagePNGData: Data(),
                panelBoundingBox: DisplayOCRLabelRect(x: 0, y: 0, width: 1, height: 1),
                rows: []
            )
        )
    }

    public init(package: DisplayOCRLabelPackage) {
        self.package = package
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.package = try DisplayOCRLabelPackage.decode(from: data)
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try package.encodedJSON()
        return .init(regularFileWithContents: data)
    }
}
