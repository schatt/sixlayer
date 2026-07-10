import SwiftUI

#if os(iOS)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Platform Export Actions Layer 4 (Issue #300)

/// Composes share and print for file export flows without folding print into share.
///
/// **Cross-Platform Behavior:**
/// - **Single action enabled:** Fast-paths directly to share or print (no chooser).
/// - **Share + Print enabled:** Presents a compact chooser (`confirmationDialog` on v1).
/// - **CSV / non-printable files:** Share only when print content cannot be resolved.
///
/// **Temp file lifecycle:** Caller owns `fileURL` creation and cleanup after `onComplete`.
///
/// - SeeAlso: ``platformShare_L4(items:from:excludedActivityTypes:onComplete:)``
/// - SeeAlso: ``platformPrint_L4(content:options:)``

public enum ExportActionKind: Equatable, Sendable, CaseIterable {
    case share
    case print
}

public enum ExportActionResult: Equatable, Sendable {
    case cancelled
    case shared(Bool)
    case printed(Bool)
}

public struct ExportActionOptions: Sendable {
    public var showsShare: Bool
    public var showsPrint: Bool
    public var showsCopyPath: Bool

    public init(
        showsShare: Bool = true,
        showsPrint: Bool = true,
        showsCopyPath: Bool = false
    ) {
        self.showsShare = showsShare
        self.showsPrint = showsPrint
        self.showsCopyPath = showsCopyPath
    }
}

public struct ExportActionPayload: @unchecked Sendable {
    public let fileURL: URL
    public let printContent: PrintContent?
    public let jobName: String?
    #if os(iOS)
    public let excludedShareActivities: [UIActivity.ActivityType]?
    #endif

    #if os(iOS)
    public init(
        fileURL: URL,
        printContent: PrintContent? = nil,
        jobName: String? = nil,
        excludedShareActivities: [UIActivity.ActivityType]? = nil
    ) {
        self.fileURL = fileURL
        self.printContent = printContent
        self.jobName = jobName
        self.excludedShareActivities = excludedShareActivities
    }
    #else
    public init(
        fileURL: URL,
        printContent: PrintContent? = nil,
        jobName: String? = nil
    ) {
        self.fileURL = fileURL
        self.printContent = printContent
        self.jobName = jobName
    }
    #endif
}

enum ExportActionResolution {
    static func enabledActions(
        payload: ExportActionPayload,
        options: ExportActionOptions
    ) -> [ExportActionKind] {
        var actions: [ExportActionKind] = []
        if options.showsShare {
            actions.append(.share)
        }
        if options.showsPrint, resolvePrintContent(payload: payload) != nil {
            actions.append(.print)
        }
        return actions
    }

    static func showsChooser(
        payload: ExportActionPayload,
        options: ExportActionOptions
    ) -> Bool {
        enabledActions(payload: payload, options: options).count > 1
    }

    static func resolvePrintContent(payload: ExportActionPayload) -> PrintContent? {
        if let printContent = payload.printContent {
            return printContent
        }
        guard isPrintableFileURL(payload.fileURL) else {
            return nil
        }
        guard let data = try? Data(contentsOf: payload.fileURL) else {
            return nil
        }
        switch payload.fileURL.pathExtension.lowercased() {
        case "pdf":
            return .pdf(data)
        case "png", "jpg", "jpeg", "heic", "gif", "webp", "tiff", "tif":
            #if os(iOS)
            if let image = UIImage(data: data) {
                return .image(PlatformImage(uiImage: image))
            }
            #elseif os(macOS)
            if let image = NSImage(data: data) {
                return .image(PlatformImage(nsImage: image))
            }
            #endif
            return nil
        default:
            return nil
        }
    }

    static func isPrintableFileURL(_ url: URL) -> Bool {
        switch url.pathExtension.lowercased() {
        case "pdf", "png", "jpg", "jpeg", "heic", "gif", "webp", "tiff", "tif":
            return true
        default:
            return false
        }
    }
}

@MainActor
enum ExportActionExecutor {
    static func perform(
        payload: ExportActionPayload,
        options: ExportActionOptions,
        from sourceView: (any View)? = nil,
        onComplete: ((ExportActionResult) -> Void)? = nil
    ) -> ExportActionResult? {
        let actions = ExportActionResolution.enabledActions(payload: payload, options: options)
        guard actions.count == 1, let action = actions.first else {
            return nil
        }

        switch action {
        case .share:
            return performShare(payload: payload, from: sourceView, onComplete: onComplete)
        case .print:
            return performPrint(payload: payload, onComplete: onComplete)
        }
    }

    private static func performShare(
        payload: ExportActionPayload,
        from sourceView: (any View)?,
        onComplete: ((ExportActionResult) -> Void)?
    ) -> ExportActionResult {
        #if os(iOS)
        let success = platformShare_L4(
            items: [payload.fileURL],
            from: sourceView,
            excludedActivityTypes: payload.excludedShareActivities,
            onComplete: { completed in
                onComplete?(.shared(completed))
            }
        )
        #else
        let success = platformShare_L4(
            items: [payload.fileURL],
            from: sourceView,
            onComplete: { completed in
                onComplete?(.shared(completed))
            }
        )
        #endif
        return .shared(success)
    }

    private static func performPrint(
        payload: ExportActionPayload,
        onComplete: ((ExportActionResult) -> Void)?
    ) -> ExportActionResult? {
        guard let printContent = ExportActionResolution.resolvePrintContent(payload: payload) else {
            return nil
        }
        var printOptions = PrintOptions()
        printOptions.jobName = payload.jobName
        let success = platformPrint_L4(content: printContent, options: printOptions)
        onComplete?(.printed(success))
        return .printed(success)
    }
}

// MARK: - View Modifier

public extension View {
    func platformExportActions_L4(
        isPresented: Binding<Bool>,
        payload: ExportActionPayload?,
        options: ExportActionOptions = .init(),
        onComplete: ((ExportActionResult) -> Void)? = nil
    ) -> some View {
        modifier(
            PlatformExportActionsL4Modifier(
                isPresented: isPresented,
                payload: payload,
                options: options,
                onComplete: onComplete
            )
        )
    }
}

private struct PlatformExportActionsL4Modifier: ViewModifier {
    @Binding var isPresented: Bool
    let payload: ExportActionPayload?
    let options: ExportActionOptions
    let onComplete: ((ExportActionResult) -> Void)?

    @State private var showChooser = false
    @State private var activePayload: ExportActionPayload?
    @State private var showShareSheet = false

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                guard newValue else { return }
                guard let payload else {
                    isPresented = false
                    return
                }
                beginPresentation(with: payload)
            }
            .confirmationDialog(
                exportActionsDialogTitle,
                isPresented: $showChooser,
                titleVisibility: .visible
            ) {
                Button(exportActionsShareTitle) {
                    guard let activePayload else { return }
                    presentShare(for: activePayload)
                }
                .accessibilityIdentifier("SixLayer.main.ui.platformExportActions_L4.share")

                Button(exportActionsPrintTitle) {
                    guard let activePayload else { return }
                    presentPrint(for: activePayload)
                }
                .accessibilityIdentifier("SixLayer.main.ui.platformExportActions_L4.print")

                Button(exportActionsCancelTitle, role: .cancel) {
                    finish(.cancelled)
                }
                .accessibilityIdentifier("SixLayer.main.ui.platformExportActions_L4.cancel")
            } message: {
                Text(exportActionsDialogMessage)
            }
            .modifier(ExportActionShareSheetModifier(
                isPresented: $showShareSheet,
                payload: activePayload,
                onComplete: { success in
                    finish(.shared(success))
                }
            ))
            .automaticCompliance(named: "platformExportActions_L4")
    }

    private func beginPresentation(with payload: ExportActionPayload) {
        activePayload = payload
        if ExportActionResolution.showsChooser(payload: payload, options: options) {
            showChooser = true
            return
        }

        let actions = ExportActionResolution.enabledActions(payload: payload, options: options)
        guard let onlyAction = actions.first else {
            finish(nil)
            return
        }

        switch onlyAction {
        case .share:
            presentShare(for: payload)
        case .print:
            presentPrint(for: payload)
        }
    }

    private func presentShare(for payload: ExportActionPayload) {
        #if os(macOS)
        let success = platformShare_L4(
            items: [payload.fileURL],
            from: nil,
            onComplete: { completed in
                finish(.shared(completed))
            }
        )
        if !success {
            finish(.shared(false))
        }
        #else
        showShareSheet = true
        #endif
    }

    private func presentPrint(for payload: ExportActionPayload) {
        guard let printContent = ExportActionResolution.resolvePrintContent(payload: payload) else {
            finish(nil)
            return
        }
        var printOptions = PrintOptions()
        printOptions.jobName = payload.jobName
        let success = platformPrint_L4(content: printContent, options: printOptions)
        finish(.printed(success))
    }

    private func finish(_ result: ExportActionResult?) {
        showChooser = false
        showShareSheet = false
        isPresented = false
        activePayload = nil
        if let result {
            onComplete?(result)
        }
    }
}

private struct ExportActionShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let payload: ExportActionPayload?
    let onComplete: (Bool) -> Void

    func body(content: Content) -> some View {
        #if os(iOS)
        content.sheet(isPresented: $isPresented) {
            if let payload {
                ExportActionShareSheetHost(
                    items: [payload.fileURL],
                    excludedActivityTypes: payload.excludedShareActivities,
                    onComplete: onComplete
                )
            } else {
                EmptyView()
            }
        }
        #else
        content
        #endif
    }
}

#if os(iOS)
private struct ExportActionShareSheetHost: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        if let excludedActivityTypes {
            controller.excludedActivityTypes = excludedActivityTypes
        }
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Imperative API

/// Presents export actions for a generated file.
///
/// Returns `nil` when nothing can be presented (invalid payload / no enabled actions).
/// Returns `.cancelled` only when the user dismisses chooser or downstream UI without completing.
@MainActor
@discardableResult
public func platformExportActions_L4(
    payload: ExportActionPayload,
    options: ExportActionOptions = .init(),
    from sourceView: (any View)? = nil,
    onComplete: ((ExportActionResult) -> Void)? = nil
) -> ExportActionResult? {
    if ExportActionResolution.showsChooser(payload: payload, options: options) {
        return nil
    }
    return ExportActionExecutor.perform(
        payload: payload,
        options: options,
        from: sourceView,
        onComplete: onComplete
    )
}

// MARK: - Copy Path (optional)

private var exportActionsDialogTitle: String { "Export" }
private var exportActionsDialogMessage: String { "What would you like to do with this file?" }
private var exportActionsShareTitle: String { "Share" }
private var exportActionsPrintTitle: String { "Print" }
private var exportActionsCancelTitle: String { "Cancel" }
