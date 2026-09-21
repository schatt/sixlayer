import Foundation
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformExportActionsLayer4 pure resolution + imperative
 * fast paths (#467). Relocated from ViewInspectorTests so SLF-*-UnitTests execute them.
 * View-modifier a11y stays in ViewInspectorTests.
 */

@Suite("Platform Export Actions Layer4 Unit")
struct PlatformExportActionsLayer4UnitTests {

    @Test func enabledActions_csvPayloadOffersShareOnly() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("a,b\n1,2".utf8))
        let payload = makePayload(fileURL: csvURL)
        let actions = ExportActionResolution.enabledActions(payload: payload, options: .init())
        #expect(actions == [.share])
    }

    @Test func enabledActions_pdfPayloadOffersShareAndPrint() throws {
        let pdfURL = try makeTemporaryFile(named: "report.pdf", contents: minimalPDFData())
        let payload = makePayload(fileURL: pdfURL, jobName: "Trip Report")
        let actions = ExportActionResolution.enabledActions(payload: payload, options: .init())
        #if os(iOS) || os(macOS)
        #expect(actions == [.share, .print])
        #else
        #expect(actions == [.share])
        #endif
    }

    @Test func showsChooser_falseWhenOnlyShareEnabled() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("csv".utf8))
        let payload = makePayload(fileURL: csvURL)
        #expect(ExportActionResolution.showsChooser(payload: payload, options: .init()) == false)
    }

    @Test func showsChooser_trueWhenShareAndPrintEnabled() throws {
        let pdfURL = try makeTemporaryFile(named: "report.pdf", contents: minimalPDFData())
        let payload = makePayload(fileURL: pdfURL)
        #if os(iOS) || os(macOS)
        #expect(ExportActionResolution.showsChooser(payload: payload, options: .init()) == true)
        #else
        #expect(ExportActionResolution.showsChooser(payload: payload, options: .init()) == false)
        #endif
    }

    @Test func resolvePrintContent_usesExplicitPrintContent() {
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

    @Test func resolvePrintContent_derivesFromPDFURL() throws {
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

    @Test func resolvePrintContent_nilForNonPrintableFile() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("csv".utf8))
        let payload = makePayload(fileURL: csvURL)
        #expect(ExportActionResolution.resolvePrintContent(payload: payload) == nil)
    }

    @Test @MainActor func imperativeExportActions_shareOnlyFastPath() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("a,b".utf8))
        let payload = makePayload(fileURL: csvURL)
        let result = platformExportActions_L4(payload: payload, options: .init())
        if case .shared(let success)? = result {
            #expect(success == true)
        } else {
            Issue.record("Share-only CSV export should fast-path to .shared, got \(String(describing: result))")
        }
    }

    @Test @MainActor func imperativeExportActions_printOnlyFastPath() throws {
        let pdfURL = try makeTemporaryFile(named: "report.pdf", contents: minimalPDFData())
        let payload = makePayload(fileURL: pdfURL, jobName: "Trip Report")
        var options = ExportActionOptions()
        options.showsShare = false
        let result = platformExportActions_L4(payload: payload, options: options)
        #if os(iOS) || os(macOS)
        if case .printed(let success)? = result {
            #expect(success == true)
        } else {
            Issue.record("Print-only export should fast-path to .printed, got \(String(describing: result))")
        }
        #else
        #expect(result == nil, "Print-only export is unavailable on this platform")
        #endif
    }

    @Test @MainActor func imperativeExportActions_nilWhenNoEnabledActions() throws {
        let csvURL = try makeTemporaryFile(named: "report.csv", contents: Data("csv".utf8))
        let payload = makePayload(fileURL: csvURL)
        var options = ExportActionOptions()
        options.showsShare = false
        options.showsPrint = false
        let result = platformExportActions_L4(payload: payload, options: options)
        #expect(result == nil, "No enabled actions should return nil (not user cancel)")
    }

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
