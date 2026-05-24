import SwiftUI

/// Layer 3: Strategy - OCR Overlay Configuration
/// 
/// This configuration struct defines the strategy for OCR overlay behavior,
/// allowing different approaches based on user preferences and platform capabilities.
public struct OCROverlayConfiguration {
    public let allowsEditing: Bool
    public let allowsDeletion: Bool
    public let showConfidenceIndicators: Bool
    public let showBoundingBoxes: Bool
    public let highlightColor: Color
    public let editingColor: Color
    public let lowConfidenceThreshold: Float
    public let highConfidenceThreshold: Float
    
    public init(
        allowsEditing: Bool = true,
        allowsDeletion: Bool = true,
        showConfidenceIndicators: Bool = true,
        showBoundingBoxes: Bool = true,
        highlightColor: Color = .yellow,
        editingColor: Color = .green,
        lowConfidenceThreshold: Float = 0.7,
        highConfidenceThreshold: Float = 0.9
    ) {
        self.allowsEditing = allowsEditing
        self.allowsDeletion = allowsDeletion
        self.showConfidenceIndicators = showConfidenceIndicators
        self.showBoundingBoxes = showBoundingBoxes
        self.highlightColor = highlightColor
        self.editingColor = editingColor
        self.lowConfidenceThreshold = lowConfidenceThreshold
        self.highConfidenceThreshold = highConfidenceThreshold
    }
}
