//
//  OCRVisionMinimumTextHeight288Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Configurable Vision minimumTextHeight for pump LCD on full-resolution photos (GitHub #288).
//

import Testing
@testable import SixLayerFramework

@Suite("OCR Vision minimumTextHeight (#288)")
struct OCRVisionMinimumTextHeight288Tests {

    @Test func defaultVisionMinimumTextHeight_matchesPumpLCDDefault() {
        let context = OCRContext()
        #expect(context.visionMinimumTextHeight == OCRVisionDefaults.minimumTextHeight)
        #expect(context.visionMinimumTextHeight == 0.003)
    }

    /// Apps may pass `0.01` for receipt-style documents when less small-text noise is desired.
    @Test func customVisionMinimumTextHeight_isPreserved() {
        let context = OCRContext(visionMinimumTextHeight: 0.01)
        #expect(context.visionMinimumTextHeight == 0.01)
    }
}
