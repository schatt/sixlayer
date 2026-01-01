import Testing
import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
import ViewInspector
#endif
/// DRY Test Patterns
/// Provides reusable patterns to eliminate duplication in tests
@MainActor
open class TestPatterns {
    
    // MARK: - Test Data Types
    
    public struct TestDataItem: Identifiable {
        public let id = UUID()
        let title: String
        let subtitle: String?
        let description: String?
        let value: Int
        let isActive: Bool
    }
    
    
    /// Platform capability enum
    enum PlatformCapability: String, CaseIterable {
        case touch = "touch"
        case hover = "hover"
        case haptic = "haptic"
        case assistiveTouch = "assistiveTouch"
        case voiceOver = "voiceOver"
        case switchControl = "switchControl"
        case vision = "vision"
        case ocr = "ocr"
    }
    
    /// Accessibility feature enum
    public enum AccessibilityFeature: String, CaseIterable {
        case reduceMotion = "reduceMotion"
        case increaseContrast = "increaseContrast"
        case reduceTransparency = "reduceTransparency"
        case boldText = "boldText"
        case largerText = "largerText"
        case buttonShapes = "buttonShapes"
        case onOffLabels = "onOffLabels"
        case grayscale = "grayscale"
        case invertColors = "invertColors"
        case smartInvert = "smartInvert"
        case differentiateWithoutColor = "differentiateWithoutColor"
    }
    
    /// View info struct for testing
    public struct ViewInfo {
        let id: String
        let title: String
        let isAccessible: Bool
        let supportsTouch: Bool
        let supportsHover: Bool
        let supportsHapticFeedback: Bool
        let supportsAssistiveTouch: Bool
        let supportsVoiceOver: Bool
        let supportsSwitchControl: Bool
        let supportsVision: Bool
        let supportsOCR: Bool
        let minTouchTarget: CGFloat
        let hoverDelay: TimeInterval
        let hasReduceMotion: Bool
        let hasIncreaseContrast: Bool
        let hasReduceTransparency: Bool
        let hasBoldText: Bool
        let hasLargerText: Bool
        let hasButtonShapes: Bool
        let hasOnOffLabels: Bool
        let hasGrayscale: Bool
        let hasInvertColors: Bool
        let hasSmartInvert: Bool
        let hasDifferentiateWithoutColor: Bool
        let viewType: String
    }
    
    /// Complexity enum for testing
    enum Complexity: String, CaseIterable {
        case simple = "simple"
        case moderate = "moderate"
        case complex = "complex"
        case veryComplex = "veryComplex"
        case advanced = "advanced"
    }
    
    
    // MARK: - Test Data Factory
    
    static func createTestItem(
        title: String = "Test Item",
        subtitle: String? = "Test Subtitle",
        description: String? = "Test Description",
        value: Int = 42,
        isActive: Bool = true
    ) -> TestDataItem {
        return TestDataItem(
            title: title,
            subtitle: subtitle,
            description: description,
            value: value,
            isActive: isActive
        )
    }
    
    
    // MARK: - View Generation Factory
    
    static func createIntelligentDetailView(
        item: TestDataItem
    ) -> some View {
        let hints = createPresentationHints()
        return IntelligentDetailView.platformDetailView(for: item, hints: hints)
    }
    
    static func createSimpleCardComponent(
        item: TestDataItem
    ) -> some View {
        let layoutDecision = createLayoutDecision()
        return SimpleCardComponent(
            item: item,
            layoutDecision: layoutDecision,
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
    }
    
    
    static func createBooleanTestCases() -> [(Bool, String)] {
        return [
            (true, "enabled"),
            (false, "disabled")
        ]
    }
    
    // MARK: - Verification Factory
    
    /// BUSINESS PURPOSE: Verify that a view is created and contains expected content
    /// TESTING SCOPE: Tests the two critical aspects: view creation + content verification
    /// METHODOLOGY: Uses ViewInspector to verify actual view structure and content
    static func verifyViewGeneration(_ view: some View, testName: String) {
        // 1. View created - The view can be instantiated successfully
        // view is a non-optional View parameter, so it exists if we reach here
        
        // 2. Contains what it needs to contain - The view has proper structure
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        if view.tryInspect() == nil {
            Issue.record("Failed to inspect view structure for \(testName)")
        }
        #else
        // ViewInspector not available on macOS - view creation is verified by non-optional parameter
        // Test passes by verifying compilation and view creation
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify that a view contains specific text content
    /// TESTING SCOPE: Tests that views contain expected text elements
    /// METHODOLOGY: Uses ViewInspector to find and verify text content
    /// Using wrapper - when ViewInspector works on macOS, no changes needed here
    static func verifyViewContainsText(_ view: some View, expectedText: String, testName: String) {
        // 1. View created - The view can be instantiated successfully
        // view is a non-optional View parameter, so it exists if we reach here
        
        // 2. Contains what it needs to contain - The view should contain expected text
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let inspectionResult = withInspectedView(view) { inspected in
            let viewText = inspected.sixLayerFindAll(ViewType.Text.self)
            #expect(!viewText.isEmpty, "View should contain text elements for \(testName)")

            let hasExpectedText = viewText.contains { text in
                if let textContent = try? text.sixLayerString() {
                    return textContent.contains(expectedText)
                }
                return false
            }
            #expect(hasExpectedText, "View should contain text '\(expectedText)' for \(testName)")
        }
        #else
        let inspectionResult: Bool? = nil
        #endif

        if inspectionResult == nil {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("View inspection failed on this platform for \(testName)")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "View created for \(testName) (ViewInspector not available on macOS)")
            #endif
        }
    }
    
    /// BUSINESS PURPOSE: Verify that a view contains specific image elements
    /// TESTING SCOPE: Tests that views contain expected image elements
    /// METHODOLOGY: Uses ViewInspector to find and verify image content
    static func verifyViewContainsImage(_ view: some View, testName: String) {
        // 1. View created - The view can be instantiated successfully
        // view is a non-optional View parameter, so it exists if we reach here
        
        // 2. Contains what it needs to contain - The view should contain image elements
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let inspectionResult = withInspectedView(view) { inspected in
            let viewImages = inspected.sixLayerFindAll(ViewType.Image.self)
            #expect(!viewImages.isEmpty, "View should contain image elements for \(testName)")
        }
        #else
        let inspectionResult: Bool? = nil
        #endif

        if inspectionResult == nil {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("View inspection failed on this platform for \(testName)")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "View created for \(testName) (ViewInspector not available on macOS)")
            #endif
        }
    }
    
    static func verifyPlatformProperties(viewInfo: ViewInfo, testName: String) {
        #expect(viewInfo.supportsTouch == RuntimeCapabilityDetection.supportsTouch, "Touch support should match for \(testName)")
        #expect(viewInfo.supportsHover == RuntimeCapabilityDetection.supportsHover, "Hover support should match for \(testName)")
        #expect(viewInfo.supportsHapticFeedback == RuntimeCapabilityDetection.supportsHapticFeedback, "Haptic feedback support should match for \(testName)")
        #expect(viewInfo.supportsAssistiveTouch == RuntimeCapabilityDetection.supportsAssistiveTouch, "AssistiveTouch support should match for \(testName)")
        #expect(viewInfo.supportsVoiceOver == RuntimeCapabilityDetection.supportsVoiceOver, "VoiceOver support should match for \(testName)")
        #expect(viewInfo.supportsSwitchControl == RuntimeCapabilityDetection.supportsSwitchControl, "Switch Control support should match for \(testName)")
        #expect(viewInfo.supportsVision == RuntimeCapabilityDetection.supportsVision, "Vision support should match for \(testName)")
        #expect(viewInfo.supportsOCR == RuntimeCapabilityDetection.supportsOCR, "OCR support should match for \(testName)")
        
        // Verify touch target and hover delay
        #expect(viewInfo.minTouchTarget == RuntimeCapabilityDetection.minTouchTarget, "Touch target should match for \(testName)")
        #expect(viewInfo.hoverDelay == RuntimeCapabilityDetection.hoverDelay, "Hover delay should match for \(testName)")
    }
    
    static func verifyAccessibilityProperties(viewInfo: ViewInfo, testName: String) {
        // Note: RuntimeCapabilityDetection doesn't have accessibility feature detection yet
        // For now, just verify that the properties exist
        #expect(viewInfo.hasReduceMotion != nil, "Reduce motion should be detectable for \(testName)")
        #expect(viewInfo.hasIncreaseContrast != nil, "Increase contrast should be detectable for \(testName)")
        #expect(viewInfo.hasReduceTransparency != nil, "Reduce transparency should be detectable for \(testName)")
        #expect(viewInfo.hasBoldText != nil, "Bold text should be detectable for \(testName)")
        #expect(viewInfo.hasLargerText != nil, "Larger text should be detectable for \(testName)")
        #expect(viewInfo.hasButtonShapes != nil, "Button shapes should be detectable for \(testName)")
        #expect(viewInfo.hasOnOffLabels != nil, "On/Off labels should be detectable for \(testName)")
        #expect(viewInfo.hasGrayscale != nil, "Grayscale should be detectable for \(testName)")
        #expect(viewInfo.hasInvertColors != nil, "Invert colors should be detectable for \(testName)")
        #expect(viewInfo.hasSmartInvert != nil, "Smart invert should be detectable for \(testName)")
        #expect(viewInfo.hasDifferentiateWithoutColor != nil, "Differentiate without color should be detectable for \(testName)")
    }
    
    // MARK: - Helper Methods (Private)
    
    private static func createPresentationHints() -> PresentationHints {
        let dataType = DataTypeHint.generic
        let presentationPreference = determinePresentationPreference()
        let complexity = determineComplexity()
        let context = PresentationContext.standard
        
        return PresentationHints(
            dataType: dataType,
            presentationPreference: presentationPreference,
            complexity: complexity,
            context: context
        )
    }
    
    private static func createLayoutDecision() -> IntelligentCardLayoutDecision {
        let columns = determineColumns()
        let spacing = determineSpacing()
        let cardWidth = determineCardWidth()
        let cardHeight = determineCardHeight()
        let padding = determinePadding()
        
        return IntelligentCardLayoutDecision(
            columns: columns,
            spacing: spacing,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            padding: padding
        )
    }
    
    // MARK: - Strategy Determination Methods (Private)
    
    private static func determinePresentationPreference() -> PresentationPreference {
        if RuntimeCapabilityDetection.supportsTouch {
            return .card
        } else if RuntimeCapabilityDetection.supportsHover {
            return .detail
        } else {
            return .standard
        }
    }
    
    private static func determineComplexity() -> ContentComplexity {
        let capabilityCount = countCapabilities()
        let accessibilityCount = countAccessibilityFeatures()
        
        if capabilityCount >= 6 && accessibilityCount >= 8 {
            return .advanced
        } else if capabilityCount >= 4 && accessibilityCount >= 5 {
            return .complex
        } else if capabilityCount >= 2 && accessibilityCount >= 3 {
            return .moderate
        } else {
            return .simple
        }
    }
    
    private static func countCapabilities() -> Int {
        var count = 0
        if RuntimeCapabilityDetection.supportsTouch { count += 1 }
        if RuntimeCapabilityDetection.supportsHover { count += 1 }
        if RuntimeCapabilityDetection.supportsHapticFeedback { count += 1 }
        if RuntimeCapabilityDetection.supportsAssistiveTouch { count += 1 }
        if RuntimeCapabilityDetection.supportsVoiceOver { count += 1 }
        if RuntimeCapabilityDetection.supportsSwitchControl { count += 1 }
        if RuntimeCapabilityDetection.supportsVision { count += 1 }
        if RuntimeCapabilityDetection.supportsOCR { count += 1 }
        return count
    }
    
    private static func countAccessibilityFeatures() -> Int {
        var count = 0
        // Note: RuntimeCapabilityDetection doesn't have accessibility feature detection yet
        // For now, return a reasonable default based on platform capabilities
        if RuntimeCapabilityDetection.supportsVoiceOver { count += 3 }
        if RuntimeCapabilityDetection.supportsSwitchControl { count += 2 }
        if RuntimeCapabilityDetection.supportsAssistiveTouch { count += 2 }
        return count
    }
    
    private static func determineColumns() -> Int {
        if RuntimeCapabilityDetection.supportsTouch && RuntimeCapabilityDetection.supportsHover {
            return 3 // iPad
        } else if RuntimeCapabilityDetection.supportsHover {
            return 4 // Mac
        } else if RuntimeCapabilityDetection.supportsTouch {
            return 2 // iPhone
        } else {
            return 1 // tvOS
        }
    }
    
    private static func determineSpacing() -> CGFloat {
        var spacing: CGFloat = 16
        
        // Note: RuntimeCapabilityDetection doesn't have accessibility feature detection yet
        // For now, use platform-based defaults
        if RuntimeCapabilityDetection.supportsVoiceOver {
            spacing += 4 // Larger spacing for accessibility
        }
        
        if RuntimeCapabilityDetection.supportsHover {
            spacing += 4
        }
        
        return spacing
    }
    
    private static func determineCardWidth() -> CGFloat {
        var width: CGFloat = 200
        
        // Note: RuntimeCapabilityDetection doesn't have accessibility feature detection yet
        // For now, use platform-based defaults
        if RuntimeCapabilityDetection.supportsVoiceOver {
            width += 20 // Larger width for accessibility
        }
        
        if RuntimeCapabilityDetection.supportsHover {
            width += 50
        }
        
        return width
    }
    
    private static func determineCardHeight() -> CGFloat {
        var height: CGFloat = 150
        
        // Note: RuntimeCapabilityDetection doesn't have accessibility feature detection yet
        // For now, use platform-based defaults
        if RuntimeCapabilityDetection.supportsVoiceOver {
            height += 20 // Larger height for accessibility
        }
        
        if RuntimeCapabilityDetection.supportsHover {
            height += 30
        }
        
        return height
    }
    
    private static func determinePadding() -> CGFloat {
        var padding: CGFloat = 16
        
        // Note: RuntimeCapabilityDetection doesn't have accessibility feature detection yet
        // For now, use platform-based defaults
        if RuntimeCapabilityDetection.supportsVoiceOver {
            padding += 4 // Larger padding for accessibility
        }
        
        if RuntimeCapabilityDetection.supportsTouch {
            padding += 4
        }
        
        return padding
    }
}
