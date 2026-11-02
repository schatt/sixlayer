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
        TestSetupUtilities.hostExpectingNamedCompliance("platformAnalyzeDataFrame_L1") {
            platformAnalyzeDataFrame_L1(dataFrame: tinyFrame())
        }
    }

    @Test @MainActor
    func compareAndQualityL1Host() {
        let frame = tinyFrame()
        TestSetupUtilities.hostExpectingPlatformRoot {
            platformCompareDataFrames_L1(dataFrames: [frame, frame])
        }
        TestSetupUtilities.hostExpectingPlatformRoot {
            platformAssessDataQuality_L1(dataFrame: frame)
        }
    }

    @Test @MainActor
    func analyzeDataFrameL1CustomVisualizationWrapsWithoutNamedRoot() {
        let (hosted, log) = TestSetupUtilities.hostRootPlatformViewNamedDebugLog(
            platformAnalyzeDataFrame_L1(dataFrame: tinyFrame()) { inner in
                AnyView(inner.padding())
            }
        )
        #if os(watchOS) || os(visionOS)
        #expect(hosted == nil, "unit harness cannot host on this platform (#379/#380)")
        #expect(log.isEmpty)
        #else
        #expect(hosted != nil)
        #expect(
            !log.contains("NamedAutomaticComplianceModifier"),
            "custom visualization wrapper must stay anonymous (#245). log=\(String(log.suffix(400)))"
        )
        #endif
    }
}
