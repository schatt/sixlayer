import Foundation
import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformOCRDisambiguationLayer1 (#466).
 * L1 uses a mock processor (no Vision); observe host + onResult callback.
 * Replaces the emptied placeholder suite that only had TODOs.
 */

@Suite("OCR Disambiguation L1 Unit", HostedViewTestIsolationTrait())
@MainActor
struct OCRDisambiguationL1UnitTests {

    @Test
    func disambiguationL1InvokesOnResultWithMockCandidates() async {
        #if os(watchOS)
        return
        #else
        let box = ResultBox()
        let view = platformOCRWithDisambiguation_L1(
            image: PlatformImage(),
            context: OCRContext()
        ) { result in
            box.value = result
        }
        let hosted = TestSetupUtilities.hostRootPlatformView(view, forceLayout: true)
        #expect(hosted != nil, "OCR disambiguation L1 must host")

        let deadline = Date().addingTimeInterval(2.0)
        while box.value == nil, Date() < deadline {
            await Task.yield()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        #expect(box.value != nil, "mock processImage should call onResult")
        guard let result = box.value else { return }
        #expect(!result.candidates.isEmpty, "mock result should include candidates")
        #endif
    }

    @Test
    func disambiguationL1ConfigurationOverloadHosts() {
        #if os(watchOS)
        return
        #else
        let view = platformOCRWithDisambiguation_L1(
            image: PlatformImage(),
            context: OCRContext(),
            configuration: OCRDisambiguationConfiguration(),
            onResult: { _ in }
        )
        let hosted = TestSetupUtilities.hostRootPlatformView(view, forceLayout: true)
        #expect(hosted != nil)
        #endif
    }
}

@MainActor
private final class ResultBox {
    var value: OCRDisambiguationResult?
}
