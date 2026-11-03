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
        #if os(watchOS) || os(visionOS)
        TestSetupUtilities.hostExpectingPlatformRoot {
            platformOCRWithDisambiguation_L1(
                image: PlatformImage(),
                context: OCRContext()
            ) { _ in }
        }
        #else
        let box = ResultBox()
        let view = platformOCRWithDisambiguation_L1(
            image: PlatformImage(),
            context: OCRContext()
        ) { result in
            box.value = result
        }
        TestSetupUtilities.hostExpectingPlatformRoot { view }

        let got = await waitForResult(box, timeout: 2.0)
        #expect(got, "mock processImage should call onResult")
        guard let result = box.value else { return }
        #expect(!result.candidates.isEmpty, "mock result should include candidates")
        #endif
    }

    @Test
    func disambiguationL1ConfigurationOverloadHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            platformOCRWithDisambiguation_L1(
                image: PlatformImage(),
                context: OCRContext(),
                configuration: OCRDisambiguationConfiguration(),
                onResult: { _ in }
            )
        }
    }
}

@MainActor
private final class ResultBox {
    var value: OCRDisambiguationResult?
}

@MainActor
private func waitForResult(_ box: ResultBox, timeout: TimeInterval) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while box.value == nil, Date() < deadline {
        await Task.yield()
        pumpMainRunLoop(for: 0.05)
    }
    return box.value != nil
}

private func pumpMainRunLoop(for duration: TimeInterval) {
    let deadline = Date().addingTimeInterval(duration)
    while Date() < deadline {
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }
}
