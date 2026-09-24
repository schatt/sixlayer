//
//  FileUploadValidationUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for FileUploadValidation (#403).
//

import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import SixLayerFramework

@Suite("FileUploadValidation (#403)")
struct FileUploadValidationUnitTests {

    @Test func isTypeAllowed_acceptsExactAndConformingTypes() {
        #expect(FileUploadValidation.isTypeAllowed(.png, allowed: [.image]))
        #expect(FileUploadValidation.isTypeAllowed(.pdf, allowed: [.pdf]))
        #expect(!FileUploadValidation.isTypeAllowed(.pdf, allowed: [.image]))
        #expect(FileUploadValidation.isTypeAllowed(.plainText, allowed: []))
    }

    @Test func isSizeAllowed_respectsMaxWhenConfigured() {
        #expect(FileUploadValidation.isSizeAllowed(500, max: nil))
        #expect(FileUploadValidation.isSizeAllowed(500, max: 1000))
        #expect(FileUploadValidation.isSizeAllowed(1000, max: 1000))
        #expect(!FileUploadValidation.isSizeAllowed(1001, max: 1000))
    }

    @Test func accepted_filtersByTypeAndSize() {
        let ok = FileInfo(name: "a.png", size: 100, type: .png, url: nil)
        let tooBig = FileInfo(name: "b.png", size: 5000, type: .png, url: nil)
        let wrongType = FileInfo(name: "c.pdf", size: 100, type: .pdf, url: nil)

        let accepted = FileUploadValidation.accepted(
            from: [ok, tooBig, wrongType],
            allowedTypes: [.image],
            maxFileSize: 1000
        )
        #expect(accepted.map(\.name) == ["a.png"])
    }
}

@Suite("FileUploadArea hosts (#403)", HostedViewTestIsolationTrait())
struct FileUploadAreaHostUnitTests {

    @Test @MainActor
    func fileUploadAreaUsesNamedCompliance() {
        hostExpectingNamedCompliance("FileUploadArea") {
            FileUploadArea(
                isDragOver: .constant(false),
                selectedFiles: .constant([]),
                allowedTypes: [.image],
                maxFileSize: 1024,
                onFilesSelected: { _ in }
            )
        }
    }

    @MainActor
    private func hostExpectingNamedCompliance<V: View>(
        _ name: String,
        @ViewBuilder _ view: () -> V
    ) {
        #if os(watchOS)
        return
        #else
        let (hosted, log) = TestSetupUtilities.hostRootPlatformViewNamedDebugLog(view())
        #expect(hosted != nil)
        #expect(
            log.contains(name),
            "named compliance \(name) must appear in debug log"
        )
        #endif
    }
}
