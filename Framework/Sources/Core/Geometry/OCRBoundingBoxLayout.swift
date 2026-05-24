import CoreGraphics

/// Converts Vision OCR bounding boxes into layout coordinates for overlay rendering.
public enum OCRBoundingBoxLayout {

    /// Vision normalized rect (origin bottom-left) → image pixel rect (origin top-left).
    public static func visionNormalizedToImagePixels(_ rect: CGRect, imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        return CGRect(
            x: rect.origin.x * imageSize.width,
            y: (1.0 - rect.origin.y - rect.height) * imageSize.height,
            width: rect.width * imageSize.width,
            height: rect.height * imageSize.height
        )
    }

    /// Frame occupied by an aspect-fit image inside a container.
    public static func aspectFitImageFrame(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }

        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        if imageAspect > containerAspect {
            let width = containerSize.width
            let height = width / imageAspect
            let y = (containerSize.height - height) / 2
            return CGRect(x: 0, y: y, width: width, height: height)
        }

        let height = containerSize.height
        let width = height * imageAspect
        let x = (containerSize.width - width) / 2
        return CGRect(x: x, y: 0, width: width, height: height)
    }

    /// Map an image-pixel rect into container coordinates for a fitted image frame.
    public static func imagePixelRectToContainer(
        _ rect: CGRect,
        imageFrame: CGRect,
        imageSize: CGSize
    ) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scaleX = imageFrame.width / imageSize.width
        let scaleY = imageFrame.height / imageSize.height
        return CGRect(
            x: imageFrame.origin.x + rect.origin.x * scaleX,
            y: imageFrame.origin.y + rect.origin.y * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )
    }

    /// Vision normalized rect → container coordinates for aspect-fit layout.
    public static func visionNormalizedToContainer(
        _ rect: CGRect,
        imageSize: CGSize,
        containerSize: CGSize
    ) -> CGRect {
        let imageFrame = aspectFitImageFrame(imageSize: imageSize, containerSize: containerSize)
        let pixelRect = visionNormalizedToImagePixels(rect, imageSize: imageSize)
        return imagePixelRectToContainer(pixelRect, imageFrame: imageFrame, imageSize: imageSize)
    }
}
