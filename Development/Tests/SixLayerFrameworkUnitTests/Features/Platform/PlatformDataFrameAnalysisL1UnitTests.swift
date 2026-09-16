import SwiftUI
import TabularData
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformDataFrameAnalysisL1 (#466).
 * Hosts public L1 entry points; engine depth stays in DataFrameAnalysisEngineTests.
 */

@Suite("Platform DataFrame Analysis L1 Unit", HostedViewTestIsolationTrait())
struct PlatformDataFrameAnalysisL1UnitTests {

    private func tinyFrame() -> DataFrame {
        var frame = DataFrame()
        frame.append(column: Column(name: "value", contents: [1, 2, 3]))
        return frame
    }

    @Test
    func analysisHintsDefaultsAndFocusAreas() {
        let hints = DataFrameAnalysisHints()
        #expect(hints.analysisDepth == .comprehensive)
        #expect(hints.includeRecommendations == true)
        #expect(DataFrameFocusArea.allCases.count == 8)
        #expect(AnalysisDepth.allCases.count == 4)
    }

    @Test @MainActor
    func analyzeDataFrameL1UsesIdentifierName() {
        #if os(watchOS)
        return
        #else
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        isolated.enableDebugLogging = true
        isolated.clearDebugLog()
        let view = platformAnalyzeDataFrame_L1(dataFrame: tinyFrame())
        let hosted = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: isolated
            )
        }
        #expect(hosted != nil)
        let log = isolated.getDebugLog()
        #expect(
            log.contains("platformAnalyzeDataFrame_L1"),
            "analyze L1 must use identifierName path. log=\(String(log.suffix(400)))"
        )
        #endif
    }

    @Test @MainActor
    func compareAndQualityL1Host() {
        #if os(watchOS)
        return
        #else
        let frame = tinyFrame()
        let compare = platformCompareDataFrames_L1(dataFrames: [frame, frame])
        let quality = platformAssessDataQuality_L1(dataFrame: frame)
        #expect(TestSetupUtilities.hostRootPlatformView(compare, forceLayout: true) != nil)
        #expect(TestSetupUtilities.hostRootPlatformView(quality, forceLayout: true) != nil)
        #endif
    }

    @Test @MainActor
    func analyzeDataFrameL1CustomVisualizationWrapsWithoutNamedRoot() {
        #if os(watchOS)
        return
        #else
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        isolated.enableDebugLogging = true
        isolated.clearDebugLog()
        let view = platformAnalyzeDataFrame_L1(dataFrame: tinyFrame()) { inner in
            AnyView(inner.padding())
        }
        let hosted = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: isolated
            )
        }
        #expect(hosted != nil)
        let log = isolated.getDebugLog()
        #expect(
            !log.contains("NamedAutomaticComplianceModifier"),
            "custom visualization wrapper must stay anonymous (#245). log=\(String(log.suffix(400)))"
        )
        #endif
    }
}
