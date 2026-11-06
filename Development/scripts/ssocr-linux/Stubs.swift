import Foundation
public final class CGImage {
    public let width: Int, height: Int, gray: [UInt8]
    public init(width: Int, height: Int, gray: [UInt8]) { self.width = width; self.height = height; self.gray = gray }
}
public struct DisplayOCRPanelLocator { func panelRegion(in: CGImage) -> CGRect? { nil } }
public enum TextType: Hashable { case number }
public enum OCRTextRole { case segment, label }
public struct OCRRecognizedText { public typealias Role = OCRTextRole; public var text: String; public var boundingBox: CGRect; public var confidence: Float; public var role: OCRTextRole }
public struct OCRResult {
    public var extractedText: String; public var confidence: Float
    public var boundingBoxes: [CGRect]; public var recognizedTexts: [OCRRecognizedText]
    public init(extractedText: String, confidence: Float, boundingBoxes: [CGRect] = [], textTypes: [TextType: String] = [:], recognizedTexts: [OCRRecognizedText] = []) {
        self.extractedText = extractedText; self.confidence = confidence; self.boundingBoxes = boundingBoxes; self.recognizedTexts = recognizedTexts
    }
}
