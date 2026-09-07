import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane gap coverage for IntelligentCardExpansion Layer5/L6 (#457).
 * Focus: L6 platform routing via `.body` subject types + tighter L5 performance
 * defaults on the current host (cross-platform simulation is not supported).
 */

@Suite("Intelligent Card Expansion L5/L6 Unit Gaps", DefaultRuntimeCapabilityIsolationTrait())
struct IntelligentCardExpansionL5L6UnitGapTests {

    private struct GapItem: Identifiable {
        let id: String
    }

    private let sampleItem = GapItem(id: "gap-1")

    // MARK: - Layer 6 platform routing

    @Test @MainActor
    func platformAwareExpandableCardViewRoutesToHostPlatformImplementation() {
        let view = PlatformAwareExpandableCardView(
            item: sampleItem,
            expansionStrategy: .hoverExpand
        )
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "PlatformAwareExpandableCardView")
        #if os(iOS)
        BaseTestClass.expectViewSubjectTypeContains(view.body, rootViewName: "iOSExpandableCardView")
        #elseif os(macOS)
        BaseTestClass.expectViewSubjectTypeContains(view.body, rootViewName: "macOSExpandableCardView")
        #else
        BaseTestClass.expectViewSubjectTypeContains(view.body, rootViewName: "NativeExpandableCardView")
        #endif
    }

    #if os(iOS)
    @Test @MainActor
    func iOSExpandableCardViewWrapsNativeExpandableCardView() {
        let view = iOSExpandableCardView(item: sampleItem, expansionStrategy: .hoverExpand)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "iOSExpandableCardView")
        BaseTestClass.expectViewSubjectTypeContains(view.body, rootViewName: "NativeExpandableCardView")
    }
    #endif

    #if os(macOS)
    @Test @MainActor
    func macOSExpandableCardViewWrapsNativeExpandableCardView() {
        let view = macOSExpandableCardView(item: sampleItem, expansionStrategy: .hoverExpand)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "macOSExpandableCardView")
        BaseTestClass.expectViewSubjectTypeContains(view.body, rootViewName: "NativeExpandableCardView")
    }
    #endif

    @Test @MainActor
    func visionOSExpandableCardViewAppliesFocusableModifier() {
        let view = visionOSExpandableCardView(item: sampleItem, expansionStrategy: .hoverExpand)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "visionOSExpandableCardView")
        BaseTestClass.expectViewSubjectTypeContains(view.body, rootViewName: "NativeExpandableCardView")
        BaseTestClass.expectViewSubjectTypeContains(view.body, rootViewName: "FocusableModifier")
    }

    @Test @MainActor
    func nativeExpandableCardViewConstructsForAllExpansionStrategies() {
        for strategy in ExpansionStrategy.allCases {
            let view = NativeExpandableCardView(
                item: sampleItem,
                expansionStrategy: strategy,
                platformConfig: CardExpansionPlatformConfig(),
                performanceConfig: CardExpansionPerformanceConfig(),
                accessibilityConfig: CardExpansionAccessibilityConfig()
            )
            BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NativeExpandableCardView")
        }
    }

    // MARK: - Layer 5 performance defaults (host platform)

    @Test @MainActor
    func getCardExpansionPerformanceConfigMatchesHostPlatformDefaults() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()

        let config = getCardExpansionPerformanceConfig()
        #expect(config.supportsSmoothAnimations)
        #expect(config.memoryOptimization)
        #expect(config.lazyLoading)

        switch SixLayerPlatform.current {
        case .iOS:
            #expect(config.targetFrameRate == 60)
            #expect(config.maxAnimationDuration == 0.25 || config.maxAnimationDuration == 0.3)
        case .macOS:
            #expect(config.targetFrameRate == 60)
            #expect(config.maxAnimationDuration == 0.3)
        case .visionOS:
            #expect(config.targetFrameRate == 90)
            #expect(config.maxAnimationDuration == 0.4)
        case .watchOS:
            #expect(config.targetFrameRate == 60)
            #expect(config.maxAnimationDuration == 0.15)
        case .tvOS:
            #expect(config.targetFrameRate == 60)
            #expect(config.maxAnimationDuration == 0.4)
        }
    }

    @Test
    func cardExpansionPerformanceConfigCustomInitializerStoresValues() {
        let config = CardExpansionPerformanceConfig(
            targetFrameRate: 120,
            maxAnimationDuration: 0.5,
            supportsSmoothAnimations: false,
            memoryOptimization: false,
            lazyLoading: false
        )
        #expect(config.targetFrameRate == 120)
        #expect(config.maxAnimationDuration == 0.5)
        #expect(!config.supportsSmoothAnimations)
        #expect(!config.memoryOptimization)
        #expect(!config.lazyLoading)
    }
}
