//
//  DisplayOCRTrainingView.swift
//  SixLayerFramework
//
//  Display OCR label harness (#609). Hosts can also drive
//  ``DisplayOCRTrainingSession`` without this view.
//

import SwiftUI
import UniformTypeIdentifiers
#if os(iOS) || os(macOS) || os(visionOS)
import PhotosUI
#endif

/// Draw a panel and optional rows, confirm the seven-segment read, and export a label package.
/// A new photo starts from the reader's suggested boxes. Tap a box to select it, drag to move
/// or resize it, and remove the selected one. The export directory is the training library.
public struct DisplayOCRTrainingView: View {
    @ObservedObject private var session: DisplayOCRTrainingSession
    private let onExport: ((DisplayOCRTrainingPackage) -> Void)?

    @State private var importPresented = false
    @State private var exportFolderPresented = false
    @State private var dragRect: CGRect?
    @State private var dragStarted = false
    @State private var dragBasePanel: DisplayOCRNormalizedBox?
    @State private var dragBaseRows: [DisplayOCRNormalizedBox] = []
    #if os(iOS) || os(macOS) || os(visionOS)
    @State private var photoItem: PhotosPickerItem?
    #endif

    public init(
        session: DisplayOCRTrainingSession = DisplayOCRTrainingSession(),
        onExport: ((DisplayOCRTrainingPackage) -> Void)? = nil
    ) {
        self.session = session
        self.onExport = onExport
    }

    public var body: some View {
        let i18n = InternationalizationService()
        ScrollView {
            platformVStackContainer(alignment: .leading, spacing: 12) {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.title"))
                    .font(.headline)
                    .automaticCompliance(named: "DisplayOCRTrainingTitle")

                controls(i18n)
                canvas(i18n)
                readings(i18n)
                statusLine(i18n)
            }
            .padding()
        }
        .automaticCompliance(named: "DisplayOCRTrainingView")
        .modifier(DisplayOCRTrainingFileImporter(isPresented: $importPresented, session: session))
        .modifier(DisplayOCRTrainingExportFolderImporter(isPresented: $exportFolderPresented, session: session))
    }

    @ViewBuilder
    private func controls(_ i18n: InternationalizationService) -> some View {
        platformVStackContainer(alignment: .leading, spacing: 8) {
            platformHStackContainer(spacing: 8) {
                loadControls(i18n)
                Button(i18n.localizedString(for: "SixLayerFramework.ocr.training.fullFrame")) {
                    session.useFullFramePanel()
                }
                .disabled(session.image == nil)
                .automaticCompliance(named: "DisplayOCRTrainingFullFrame")
            }

            Picker(selection: $session.drawMode) {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.panel"))
                    .tag(DisplayOCRTrainingDrawMode.panel)
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.row"))
                    .tag(DisplayOCRTrainingDrawMode.row)
            } label: {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.draw"))
            }
            .pickerStyle(.segmented)
            .disabled(session.image == nil)
            .automaticCompliance(named: "DisplayOCRTrainingDrawMode")

            platformHStackContainer(spacing: 8) {
                Button(i18n.localizedString(for: "SixLayerFramework.ocr.training.decode")) {
                    _ = session.decode()
                }
                .disabled(session.panel == nil)
                .trainingProminentButton()
                .automaticCompliance(named: "DisplayOCRTrainingDecode")

                Button(i18n.localizedString(for: "SixLayerFramework.ocr.training.clearRows")) {
                    session.clearRowBoxes()
                }
                .disabled(session.rowBoxes.isEmpty)
                .automaticCompliance(named: "DisplayOCRTrainingClearRows")

                Button(i18n.localizedString(for: "SixLayerFramework.ocr.training.removeBox")) {
                    session.removeSelectedBox()
                }
                .disabled(session.selectedBox == nil)
                .automaticCompliance(named: "DisplayOCRTrainingRemoveBox")

                Button(i18n.localizedString(for: "SixLayerFramework.ocr.training.export")) {
                    exportPackage()
                }
                .disabled(session.label == nil)
                .trainingProminentButton()
                .automaticCompliance(named: "DisplayOCRTrainingExport")

                #if os(iOS) || os(macOS) || os(visionOS)
                Button(i18n.localizedString(for: "SixLayerFramework.ocr.training.chooseFolder")) {
                    exportFolderPresented = true
                }
                .automaticCompliance(named: "DisplayOCRTrainingChooseFolder")
                #endif
            }

            selectablePath(session.exportRoot.path)
                .automaticCompliance(named: "DisplayOCRTrainingExportRoot")

            DisplayOCRTrainingLibrarySummary(
                exampleCount: session.library.examples.count,
                rejectionCount: session.library.rejections.count
            )
        }
    }

    @ViewBuilder
    private func loadControls(_ i18n: InternationalizationService) -> some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        PhotosPicker(selection: $photoItem, matching: .images) {
            Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.photoLibrary"))
        }
        .trainingBorderedButton()
        .automaticCompliance(named: "DisplayOCRTrainingPhotoLibrary")
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                await loadPhoto(item)
            }
        }

        Button(i18n.localizedString(for: "SixLayerFramework.ocr.training.loadFile")) {
            importPresented = true
        }
        .trainingBorderedButton()
        .automaticCompliance(named: "DisplayOCRTrainingLoadFile")
        #else
        EmptyView()
        #endif
    }

    @ViewBuilder
    private func canvas(_ i18n: InternationalizationService) -> some View {
        if let image = session.image {
            GeometryReader { geometry in
                let size = geometry.size
                drawingStack(image: image, containerSize: size)
            }
            .frame(height: 320)
            .automaticCompliance(named: "DisplayOCRTrainingCanvas")
        } else {
            Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.noImage"))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                .automaticCompliance(named: "DisplayOCRTrainingNoImage")
        }
    }

    @ViewBuilder
    private func drawingStack(image: PlatformImage, containerSize: CGSize) -> some View {
        let stack = ZStack(alignment: .topLeading) {
            image.platformImageView()
                .resizable()
                .scaledToFit()
                .frame(width: containerSize.width, height: containerSize.height)
                .automaticCompliance(named: "DisplayOCRTrainingImage")

            if let panel = session.panel {
                boxOutline(
                    panel,
                    color: .orange,
                    containerSize: containerSize,
                    name: "DisplayOCRTrainingPanel",
                    selected: session.selectedBox == .panel
                )
            }
            ForEach(Array(session.rowBoxes.enumerated()), id: \.offset) { index, box in
                boxOutline(
                    box,
                    color: .blue,
                    containerSize: containerSize,
                    name: "DisplayOCRTrainingRowBox",
                    selected: session.selectedBox == .row(index)
                )
                .accessibilityLabel("\(index + 1)")
            }
            if let dragRect, dragRect.width > 0, dragRect.height > 0 {
                Rectangle()
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: dragRect.width, height: dragRect.height)
                    .offset(x: dragRect.minX, y: dragRect.minY)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())

        #if os(tvOS)
        stack
        #else
        stack.gesture(drawGesture(containerSize: containerSize))
        #endif
    }

    #if !os(tvOS)
    private func drawGesture(containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if !dragStarted {
                    dragStarted = true
                    dragBasePanel = session.panel
                    dragBaseRows = session.rowBoxes
                }
                let distance = hypot(value.translation.width, value.translation.height)
                guard distance >= 8 else {
                    dragRect = nil
                    return
                }
                let adjusted = session.adjust(
                    from: value.startLocation,
                    to: value.location,
                    containerSize: containerSize,
                    basePanel: dragBasePanel,
                    baseRows: dragBaseRows
                )
                dragRect = adjusted ? nil : Self.rect(from: value.startLocation, to: value.location)
            }
            .onEnded { value in
                let distance = hypot(value.translation.width, value.translation.height)
                if distance < 8 {
                    session.selectBox(at: value.startLocation, containerSize: containerSize)
                } else if dragRect != nil {
                    let rect = Self.rect(from: value.startLocation, to: value.location)
                    _ = session.applyDraw(containerRect: rect, containerSize: containerSize)
                }
                dragRect = nil
                dragStarted = false
                dragBasePanel = nil
                dragBaseRows = []
            }
    }
    #endif

    private func boxOutline(
        _ box: DisplayOCRNormalizedBox,
        color: Color,
        containerSize: CGSize,
        name: String,
        selected: Bool
    ) -> some View {
        let rect = box.containerRect(imagePixelSize: session.imagePixelSize, containerSize: containerSize)
        return Rectangle()
            .fill(color.opacity(selected ? 0.22 : 0.12))
            .overlay(Rectangle().stroke(color, lineWidth: selected ? 4 : 2))
            .frame(width: max(rect.width, 1), height: max(rect.height, 1))
            .offset(x: rect.minX, y: rect.minY)
            .allowsHitTesting(false)
            .automaticCompliance(named: name)
    }

    @ViewBuilder
    private func readings(_ i18n: InternationalizationService) -> some View {
        if let rows = session.label?.rows, !rows.isEmpty {
            ForEach(rows) { row in
                DisplayOCRTrainingRowEditor(
                    row: row,
                    decodedTitle: i18n.localizedString(for: "SixLayerFramework.ocr.training.decoded"),
                    confirmedTitle: i18n.localizedString(for: "SixLayerFramework.ocr.training.confirmed")
                ) { text in
                    session.confirm(rowID: row.id, text: text)
                }
            }
        } else if session.image != nil, session.panel == nil {
            Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.needsPanel"))
                .font(.caption)
                .foregroundColor(.secondary)
                .automaticCompliance(named: "DisplayOCRTrainingNeedsPanel")
        }
    }

    @ViewBuilder
    private func statusLine(_ i18n: InternationalizationService) -> some View {
        switch session.status {
        case .unreadableImage:
            Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.unreadable"))
                .foregroundColor(.red)
                .automaticCompliance(named: "DisplayOCRTrainingStatus")
        case .needsPanel:
            Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.needsPanel"))
                .font(.caption)
                .foregroundColor(.secondary)
                .automaticCompliance(named: "DisplayOCRTrainingStatus")
        case .exportFailed:
            Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.exportFailed"))
                .foregroundColor(.red)
                .automaticCompliance(named: "DisplayOCRTrainingStatus")
        case .exported(let url):
            platformVStackContainer(alignment: .leading, spacing: 4) {
                Text(i18n.localizedString(for: "SixLayerFramework.ocr.training.exported"))
                    .font(.caption)
                selectablePath(url.path)
            }
            .automaticCompliance(named: "DisplayOCRTrainingStatus")
        case .decoded, nil:
            EmptyView()
        }
    }

    @ViewBuilder
    private func selectablePath(_ path: String) -> some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        Text(path)
            .font(.caption)
            .textSelection(.enabled)
        #else
        Text(path)
            .font(.caption)
        #endif
    }

    private func exportPackage() {
        do {
            let exported = try session.export()
            onExport?(exported.package)
        } catch {
            session.failExport()
        }
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    private func loadPhoto(_ item: PhotosPickerItem) async {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = PlatformImage(data: data) {
            session.load(platformImage: image)
        } else {
            session.markUnreadableImage()
        }
        photoItem = nil
    }
    #endif

    private static func rect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}

extension View {
    @ViewBuilder
    fileprivate func trainingProminentButton() -> some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        self.buttonStyle(.borderedProminent)
        #else
        self
        #endif
    }

    @ViewBuilder
    fileprivate func trainingBorderedButton() -> some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        self.buttonStyle(.bordered)
        #else
        self
        #endif
    }
}

private struct DisplayOCRTrainingRowEditor: View {
    let row: DisplayOCRTrainingRow
    let decodedTitle: String
    let confirmedTitle: String
    let onConfirm: (String) -> Void

    @State private var text: String

    init(
        row: DisplayOCRTrainingRow,
        decodedTitle: String,
        confirmedTitle: String,
        onConfirm: @escaping (String) -> Void
    ) {
        self.row = row
        self.decodedTitle = decodedTitle
        self.confirmedTitle = confirmedTitle
        self.onConfirm = onConfirm
        _text = State(initialValue: row.confirmedText)
    }

    var body: some View {
        platformVStackContainer(alignment: .leading, spacing: 4) {
            Text(decodedTitle)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(row.decodedText.isEmpty ? "—" : row.decodedText)
                .font(.body)
                .automaticCompliance(named: "DisplayOCRTrainingDecoded")
            TextField(confirmedTitle, text: $text)
                .platformTextFieldStyle()
                .automaticCompliance(named: "DisplayOCRTrainingConfirmed")
                .onChange(of: text) { _, newValue in
                    onConfirm(newValue)
                }
        }
    }
}

/// File open is unavailable on tvOS and watchOS. Those hosts load the session directly.
private struct DisplayOCRTrainingFileImporter: ViewModifier {
    @Binding var isPresented: Bool
    let session: DisplayOCRTrainingSession

    func body(content: Content) -> some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        content.fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                session.load(fileURL: url)
            case .failure(let error):
                guard !DisplayOCRTraining.importerCancelled(error) else { return }
                session.markUnreadableImage()
            }
        }
        #else
        let _ = session
        content
        #endif
    }
}

/// Folder choice for the package root. Dismissing the panel leaves the current root.
private struct DisplayOCRTrainingExportFolderImporter: ViewModifier {
    @Binding var isPresented: Bool
    let session: DisplayOCRTrainingSession

    func body(content: Content) -> some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        content.fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                session.setExportRoot(url)
            case .failure:
                break
            }
        }
        #else
        let _ = (isPresented, session)
        content
        #endif
    }
}

/// How many confirmed examples are in the export directory, and how many folders were skipped.
struct DisplayOCRTrainingLibrarySummary: View {
    let exampleCount: Int
    let rejectionCount: Int

    var body: some View {
        let i18n = InternationalizationService()
        VStack(alignment: .leading, spacing: 4) {
            Text(i18n.localizedString(
                for: "SixLayerFramework.ocr.training.libraryCount",
                arguments: ["\(exampleCount)"]
            ))
            .font(.caption)
            .automaticCompliance(named: "DisplayOCRTrainingLibraryCount")

            if rejectionCount > 0 {
                Text(i18n.localizedString(
                    for: "SixLayerFramework.ocr.training.librarySkipped",
                    arguments: ["\(rejectionCount)"]
                ))
                .font(.caption)
                .foregroundColor(.secondary)
                .automaticCompliance(named: "DisplayOCRTrainingLibrarySkipped")
            }
        }
    }
}
