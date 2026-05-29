import Testing
import SwiftUI
@testable import SixLayerFramework

//
//  PlatformExportActionsLayer4Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Issue #300: platformExportActions_L4 — compose share + print for file export.
//

@Suite("Platform Export Actions Layer 4")
open class PlatformExportActionsLayer4Tests: BaseTestClass {

    // MARK: - Resolution logic (unit)

    @Test func testEnabledActions_csvPayloadOffersShareOnly() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("a,b\n1,2".utf8))
        let payload = makePayload(fileURL: csvURL)

        let actions = ExportActionResolution.enabledActions(payload: payload, options: .init())

        #expect(actions == [.share])
    }

    @Test func testEnabledActions_pdfPayloadOffersShareAndPrint() throws {
        let pdfURL = try makeTemporaryFile(named: "report.pdf", contents: minimalPDFData())
        let payload = makePayload(fileURL: pdfURL, jobName: "Trip Report")

        let actions = ExportActionResolution.enabledActions(payload: payload, options: .init())

        #expect(actions == [.share, .print])
    }

    @Test func testShowsChooser_falseWhenOnlyShareEnabled() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("csv".utf8))
        let payload = makePayload(fileURL: csvURL)

        #expect(
            ExportActionResolution.showsChooser(payload: payload, options: .init()) == false
        )
    }

    @Test func testShowsChooser_trueWhenShareAndPrintEnabled() throws {
        let pdfURL = try makeTemporaryFile(named: "report.pdf", contents: minimalPDFData())
        let payload = makePayload(fileURL: pdfURL)

        #expect(
            ExportActionResolution.showsChooser(payload: payload, options: .init()) == true
        )
    }

    @Test func testResolvePrintContent_usesExplicitPrintContent() {
        let pdfData = minimalPDFData()
        let payload = ExportActionPayload(
            fileURL: URL(fileURLWithPath: "/tmp/unused.pdf"),
            printContent: .pdf(pdfData),
            jobName: nil
        )

        let resolved = ExportActionResolution.resolvePrintContent(payload: payload)

        if case .pdf(let data) = resolved {
            #expect(data == pdfData)
        } else {
            Issue.record("Expected explicit PDF print content")
        }
    }

    @Test func testResolvePrintContent_derivesFromPDFURL() throws {
        let pdfData = minimalPDFData()
        let pdfURL = try makeTemporaryFile(named: "report.pdf", contents: pdfData)
        let payload = makePayload(fileURL: pdfURL)

        let resolved = ExportActionResolution.resolvePrintContent(payload: payload)

        if case .pdf(let data) = resolved {
            #expect(data == pdfData)
        } else {
            Issue.record("Expected PDF content derived from file URL")
        }
    }

    @Test func testResolvePrintContent_nilForNonPrintableFile() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("csv".utf8))
        let payload = makePayload(fileURL: csvURL)

        #expect(ExportActionResolution.resolvePrintContent(payload: payload) == nil)
    }

    // MARK: - Imperative share (#300 adjunct)

    @Test @MainActor func testImperativePlatformShare_returnsBool() throws {
        let fileURL = try makeTemporaryFile(named: "share.txt", contents: Data("share me".utf8))
        #if os(iOS)
        let result = platformShare_L4(
            items: [fileURL],
            from: nil,
            excludedActivityTypes: nil,
            onComplete: nil
        )
        #else
        let result = platformShare_L4(items: [fileURL], from: nil, onComplete: nil)
        #endif
        #expect(type(of: result) == Bool.self)
        #expect(result == true, "Imperative share should succeed in unit test host")
    }

    // MARK: - Imperative export actions

    @Test @MainActor func testImperativeExportActions_shareOnlyFastPath() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("a,b".utf8))
        let payload = makePayload(fileURL: csvURL)

        let result = platformExportActions_L4(payload: payload, options: .init())

        if case .shared(let success)? = result {
            #expect(success == true)
        } else {
            Issue.record("Share-only CSV export should fast-path to .shared, got \(String(describing: result))")
        }
    }

    @Test @MainActor func testImperativeExportActions_printOnlyFastPath() throws {
        let pdfURL = try makeTemporaryFile(named: "report.pdf", contents: minimalPDFData())
        let payload = makePayload(fileURL: pdfURL, jobName: "Trip Report")
        var options = ExportActionOptions()
        options.showsShare = false

        let result = platformExportActions_L4(payload: payload, options: options)

        if case .printed(let success)? = result {
            #expect(success == true)
        } else {
            Issue.record("Print-only export should fast-path to .printed, got \(String(describing: result))")
        }
    }

    @Test @MainActor func testImperativeExportActions_nilWhenNoEnabledActions() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("csv".utf8))
        let payload = makePayload(fileURL: csvURL)
        var options = ExportActionOptions()
        options.showsShare = false
        options.showsPrint = false

        let result = platformExportActions_L4(payload: payload, options: options)

        #expect(result == nil, "No enabled actions should return nil (not user cancel)")
    }

    // MARK: - View modifier

    @Test @MainActor func testPlatformExportActionsModifier_generatesAccessibilityIdentifiers() {
        let view = Text("Export")
            .platformExportActions_L4(
                isPresented: .constant(false),
                payload: nil,
                options: .init(),
                onComplete: nil
            )
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformExportActions_L4"
        )
        #expect(hasAccessibilityID, "platformExportActions_L4 should generate accessibility identifiers")
    }

    // MARK: - Helpers

    private func makePayload(
        fileURL: URL,
        printContent: PrintContent? = nil,
        jobName: String? = nil
    ) -> ExportActionPayload {
        #if os(iOS)
        ExportActionPayload(
            fileURL: fileURL,
            printContent: printContent,
            jobName: jobName,
            excludedShareActivities: nil
        )
        #else
        ExportActionPayload(
            fileURL: fileURL,
            printContent: printContent,
            jobName: jobName
        )
        #endif
    }

    private func minimalPDFData() -> Data {
        Data(
            """
            %PDF-1.1
            1 0 obj<<>>endobj
            trailer<<>>
            %%EOF
            """.utf8
        )
    }

    private func makeTemporaryFile(named name: String, contents: Data) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent(UUID().uuidString + "-" + name)
        try contents.write(to: url)
        return url
    }
}
