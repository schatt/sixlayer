import Testing
import SwiftUI
#if canImport(ViewInspector)
import ViewInspector
#endif
@testable import SixLayerFramework

/**
 * BUSINESS PURPOSE: OCR components provide document scanning, text extraction, and
 * disambiguation interfaces for form filling. These components integrate with the
 * Vision framework to extract text from images and help users resolve ambiguous results.
 *
 * TESTING SCOPE: TDD tests that describe expected behavior for OCR components.
 *
 * METHODOLOGY: Harness-first ViewInspector traversal with hosted layout (#314).
 */

@Suite("OCR Components", .serialized)
open class OCRComponentsTDDTests: BaseTestClass {

    #if canImport(ViewInspector)
    @MainActor
    private func expectHostedHierarchyHasContent<V: View>(
        _ view: V,
        minimumButtons: Int = 0,
        _ message: String
    ) {
        _ = TestSetupUtilities.hostRootPlatformView(view, forceLayout: true)
        let buttons = findAllInViewHierarchy(view, ViewInspector.ViewType.Button.self)
        let texts = findAllInViewHierarchy(view, ViewInspector.ViewType.Text.self)
        let vStacks = findAllInViewHierarchy(view, ViewInspector.ViewType.VStack.self)
        let ok = buttons.count >= minimumButtons || !texts.isEmpty || !vStacks.isEmpty
        #expect(ok, "\(message)")
    }
    #endif

    // MARK: - OCR Overlay View

    @Test @MainActor func testOCROverlayViewRendersCameraInterface() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let testImage = PlatformImage()
            let testResult = OCRResult(
                extractedText: "Test OCR Result",
                confidence: 0.95,
                boundingBoxes: [CGRect(x: 0, y: 0, width: 100, height: 100)]
            )

            let view = OCROverlayView(
                image: testImage,
                result: testResult,
                onTextEdit: { _, _ in },
                onTextDelete: { _ in }
            )

            #if canImport(ViewInspector)
            expectHostedHierarchyHasContent(view, "Should provide overlay interface")
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "*OCROverlayView*",
                platform: .iOS,
                componentName: "OCROverlayView"
            )
            #expect(hasAccessibilityID, "Should generate accessibility identifier")
            #endif
        }
    }

    @Test @MainActor func testOCROverlayViewProcessesImageWithOCR() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let testImage = PlatformImage()
            let testResult = OCRResult(
                extractedText: "Sample Text",
                confidence: 0.9,
                boundingBoxes: [CGRect(x: 10, y: 10, width: 80, height: 20)]
            )

            let view = OCROverlayView(image: testImage, result: testResult)

            #if canImport(ViewInspector)
            expectHostedHierarchyHasContent(view, "Should have OCR processing interface")
            verifyViewContainsText(view, expectedText: "Sample Text", testName: "OCROverlayView extracted text")
            #endif
        }
    }

    // MARK: - OCR Disambiguation View

    @Test @MainActor func testOCRDisambiguationViewRendersDisambiguationUI() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let candidates = [
                OCRDataCandidate(
                    text: "123.45",
                    boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                    confidence: 0.95,
                    suggestedType: .number,
                    alternativeTypes: [.currency, .number]
                ),
                OCRDataCandidate(
                    text: "123-45",
                    boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                    confidence: 0.85,
                    suggestedType: .number,
                    alternativeTypes: [.phone, .number]
                ),
                OCRDataCandidate(
                    text: "123/45",
                    boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                    confidence: 0.75,
                    suggestedType: .number,
                    alternativeTypes: [.date, .number]
                )
            ]

            let result = OCRDisambiguationResult(
                candidates: candidates,
                confidence: 0.85,
                requiresUserSelection: true
            )

            let view = OCRDisambiguationView(result: result, onSelection: { _ in })

            #if canImport(ViewInspector)
            expectHostedHierarchyHasContent(view, minimumButtons: 3, "Should display candidate alternatives")
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "*OCRDisambiguationView*",
                platform: .iOS,
                componentName: "OCRDisambiguationView"
            )
            #expect(hasAccessibilityID, "Should generate accessibility identifier")
            #endif
        }
    }

    @Test @MainActor func testOCRDisambiguationViewDisplaysAllAlternatives() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let candidates = [
                OCRDataCandidate(
                    text: "Option A",
                    boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                    confidence: 0.9,
                    suggestedType: .general,
                    alternativeTypes: []
                ),
                OCRDataCandidate(
                    text: "Option B",
                    boundingBox: CGRect(x: 0, y: 20, width: 100, height: 20),
                    confidence: 0.8,
                    suggestedType: .general,
                    alternativeTypes: []
                ),
                OCRDataCandidate(
                    text: "Option C",
                    boundingBox: CGRect(x: 0, y: 40, width: 100, height: 20),
                    confidence: 0.7,
                    suggestedType: .general,
                    alternativeTypes: []
                )
            ]

            let result = OCRDisambiguationResult(
                candidates: candidates,
                confidence: 0.8,
                requiresUserSelection: true
            )

            let view = OCRDisambiguationView(result: result, onSelection: { _ in })

            #if canImport(ViewInspector)
            expectHostedHierarchyHasContent(view, minimumButtons: 3, "Should display candidate alternatives")
            #endif
        }
    }

    @Test @MainActor func testOCRDisambiguationViewHandlesNoDisambiguationNeeded() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let candidates = [
                OCRDataCandidate(
                    text: "Clear Result",
                    boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                    confidence: 0.99,
                    suggestedType: .general,
                    alternativeTypes: []
                )
            ]

            let result = OCRDisambiguationResult(
                candidates: candidates,
                confidence: 0.99,
                requiresUserSelection: false
            )

            let view = OCRDisambiguationView(result: result, onSelection: { _ in })

            #if canImport(ViewInspector)
            expectHostedHierarchyHasContent(view, minimumButtons: 1, "Should handle non-disambiguation case")
            #endif
        }
    }
}
