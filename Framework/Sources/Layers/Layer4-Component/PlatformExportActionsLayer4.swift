import SwiftUI

// MARK: - Export Action Types (Issue #300 stubs — red phase)

public enum ExportActionKind: Equatable, Sendable {
    case share
    case print
}

public enum ExportActionResult: Equatable, Sendable {
    case cancelled
    case shared(Bool)
    case printed(Bool)
}

public struct ExportActionOptions: Sendable {
    public var showsShare: Bool = true
    public var showsPrint: Bool = true
    public var showsCopyPath: Bool = false

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
    #else
    public let excludedShareActivities: [Any]? = nil
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
        jobName: String? = nil,
        excludedShareActivities: [Any]? = nil
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
        _ = payload
        _ = options
        return []
    }

    static func showsChooser(
        payload: ExportActionPayload,
        options: ExportActionOptions
    ) -> Bool {
        _ = payload
        _ = options
        return true
    }

    static func resolvePrintContent(payload: ExportActionPayload) -> PrintContent? {
        _ = payload
        return nil
    }
}

public extension View {
    func platformExportActions_L4(
        isPresented: Binding<Bool>,
        payload: ExportActionPayload?,
        options: ExportActionOptions = .init(),
        onComplete: ((ExportActionResult) -> Void)? = nil
    ) -> some View {
        self.automaticCompliance(named: "platformExportActions_L4")
    }
}

@MainActor
@discardableResult
public func platformExportActions_L4(
    payload: ExportActionPayload,
    options: ExportActionOptions = .init(),
    from sourceView: (any View)? = nil,
    onComplete: ((ExportActionResult) -> Void)? = nil
) -> ExportActionResult? {
    _ = payload
    _ = options
    _ = sourceView
    _ = onComplete
    return nil
}
