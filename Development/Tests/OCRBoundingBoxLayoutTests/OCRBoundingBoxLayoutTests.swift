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
}
