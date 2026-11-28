//
//  DisplayOCRLabelHarnessL1Smoke609Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Smoke coverage for platformDisplayOCRLabelHarness_L1 and export document (#609).
//

import Foundation
import Testing
import SwiftUI
@testable import SixLayerFramework

@Suite("Display OCR label harness L1 (#609)")
struct DisplayOCRLabelHarnessL1Smoke609Tests {

    @Test @MainActor func layer1HarnessEntryPointIsConstructible() {
        var exported: DisplayOCRLabelPackage?
        let view = platformDisplayOCRLabelHarness_L1(deskewMaximumDegrees: 2) { package in
            exported = package
        }
        #expect(exported == nil)
        withExtendedLifetime(view) { built in
            let name = String(describing: type(of: built))
            #expect(!name.isEmpty)
        }
    }

    @Test func labelDocumentPreservesPackageForJSONExport() throws {
        let package = DisplayOCRLabelPackage(
            imagePNGData: Data([1, 2, 3]),
            panelBoundingBox: DisplayOCRLabelRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            rows: [DisplayOCRLabeledRow(boundingBox: nil, confirmedText: "12.34")],
            segmentDeskewMaximumDegrees: 3
        )
        let document = DisplayOCRLabelDocument(package: package)
        let decoded = try DisplayOCRLabelPackage.decode(from: try document.package.encodedJSON())
        #expect(decoded == package)
        #expect(DisplayOCRLabelDocument.placeholder.package.rows.isEmpty)
    }
}
