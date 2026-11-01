import CoreGraphics
import Testing
@testable import SixLayerFramework

@Suite
struct OCRBoundingBoxLayoutTests {

    @Test func visionNormalizedToImagePixels_flipsVisionOriginToTopLeft() {
        let imageSize = CGSize(width: 200, height: 100)
        let normalized = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.3)

        let pixelRect = OCRBoundingBoxLayout.visionNormalizedToImagePixels(normalized, imageSize: imageSize)

        #expect(pixelRect.origin.x == 20)
        #expect(pixelRect.origin.y == 50)
        #expect(pixelRect.width == 100)
        #expect(pixelRect.height == 30)
    }

    @Test func aspectFitImageFrame_letterboxesWideImage() {
        let imageSize = CGSize(width: 400, height: 200)
        let containerSize = CGSize(width: 200, height: 200)

        let frame = OCRBoundingBoxLayout.aspectFitImageFrame(
            imageSize: imageSize,
            containerSize: containerSize
        )

        #expect(frame.width == 200)
        #expect(frame.height == 100)
        #expect(frame.origin.x == 0)
        #expect(frame.origin.y == 50)
    }

    @Test func imagePixelRectToContainer_scalesIntoFittedFrame() {
        let imageSize = CGSize(width: 100, height: 100)
        let containerSize = CGSize(width: 200, height: 100)
        let imageFrame = OCRBoundingBoxLayout.aspectFitImageFrame(
            imageSize: imageSize,
            containerSize: containerSize
        )
        let pixelRect = CGRect(x: 10, y: 20, width: 30, height: 40)

        let containerRect = OCRBoundingBoxLayout.imagePixelRectToContainer(
            pixelRect,
            imageFrame: imageFrame,
            imageSize: imageSize
        )

        #expect(containerRect.origin.x == 60)
        #expect(containerRect.origin.y == 20)
        #expect(containerRect.width == 30)
        #expect(containerRect.height == 40)
    }

    @Test func imagePixelsToVisionNormalized_roundTripsWithVisionToPixels() {
        let imageSize = CGSize(width: 200, height: 100)
        let normalized = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.3)
        let pixels = OCRBoundingBoxLayout.visionNormalizedToImagePixels(normalized, imageSize: imageSize)
        let back = OCRBoundingBoxLayout.imagePixelsToVisionNormalized(pixels, imageSize: imageSize)
        #expect(abs(back.origin.x - normalized.origin.x) < 0.0001)
        #expect(abs(back.origin.y - normalized.origin.y) < 0.0001)
        #expect(abs(back.width - normalized.width) < 0.0001)
        #expect(abs(back.height - normalized.height) < 0.0001)
    }

    @Test func containerRectToVisionNormalized_roundTripsWithVisionToContainer() {
        let imageSize = CGSize(width: 400, height: 200)
        let containerSize = CGSize(width: 200, height: 200)
        let normalized = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        let containerRect = OCRBoundingBoxLayout.visionNormalizedToContainer(
            normalized,
            imageSize: imageSize,
            containerSize: containerSize
        )
        let back = OCRBoundingBoxLayout.containerRectToVisionNormalized(
            containerRect,
            imageSize: imageSize,
            containerSize: containerSize
        )
        #expect(abs(back.origin.x - normalized.origin.x) < 0.0001)
        #expect(abs(back.origin.y - normalized.origin.y) < 0.0001)
        #expect(abs(back.width - normalized.width) < 0.0001)
        #expect(abs(back.height - normalized.height) < 0.0001)
    }
}
