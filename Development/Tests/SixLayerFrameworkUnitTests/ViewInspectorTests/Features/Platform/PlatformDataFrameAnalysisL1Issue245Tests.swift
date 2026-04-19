import Testing
import SwiftUI
import TabularData
@testable import SixLayerFramework

@Suite("Platform DataFrame Analysis L1 Issue245")
open class PlatformDataFrameAnalysisL1Issue245Tests: BaseTestClass {

    private nonisolated static func issue245_namedAutomaticComplianceFingerprint(componentName: String) -> String {
        "NAMED MODIFIER DEBUG: body() called for '\(componentName)'"
    }

    private func makeDataFrame() -> DataFrame {
        var dataFrame = DataFrame()
        dataFrame.append(column: Column(name: "name", contents: ["Alice", "Bob", "Charlie"]))
        dataFrame.append(column: Column(name: "value", contents: [1, 2, 3]))
        return dataFrame
    }

    @Test @MainActor
    func testIssue245_dataFrameCustomVisualizationWrappersDoNotUseNamedAutomaticComplianceModifier() async {
        let dataFrame = makeDataFrame()
        let views: [(name: String, view: AnyView)] = [
            (
                "platformAnalyzeDataFrame_L1",
                AnyView(platformAnalyzeDataFrame_L1(dataFrame: dataFrame) { content in
                    platformVStackContainer {
                        Text("Custom Analysis")
                        content
                    }
                })
            ),
            (
                "platformCompareDataFrames_L1",
                AnyView(platformCompareDataFrames_L1(dataFrames: [dataFrame, dataFrame]) { content in
                    platformVStackContainer {
                        Text("Custom Comparison")
                        content
                    }
                })
            ),
            (
                "platformAssessDataQuality_L1",
                AnyView(platformAssessDataQuality_L1(dataFrame: dataFrame) { content in
                    platformVStackContainer {
                        Text("Custom Quality")
                        content
                    }
                })
            )
        ]

        for wrapper in views {
            let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
            AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
                let host = Self.hostRootPlatformView(
                    wrapper.view,
                    forceLayout: true,
                    accessibilityIdentifierConfig: isolated
                )
                #expect(host != nil, "\(wrapper.name) custom wrapper should host")
                let log = isolated.getDebugLog()
                let fingerprint = Self.issue245_namedAutomaticComplianceFingerprint(componentName: wrapper.name)
                #expect(
                    !log.contains(fingerprint),
                    "\(wrapper.name) custom wrapper must not use NamedAutomaticComplianceModifier (issue #245); log sample: \(String(log.suffix(400)))"
                )
            }
        }
    }

    @Test @MainActor
    func testIssue245_dataFrameDefaultViewsDoNotUseNamedAutomaticComplianceModifier() async {
        let dataFrame = makeDataFrame()
        let views: [(name: String, view: AnyView)] = [
            ("platformAnalyzeDataFrame_L1", AnyView(platformAnalyzeDataFrame_L1(dataFrame: dataFrame))),
            ("platformCompareDataFrames_L1", AnyView(platformCompareDataFrames_L1(dataFrames: [dataFrame, dataFrame]))),
            ("platformAssessDataQuality_L1", AnyView(platformAssessDataQuality_L1(dataFrame: dataFrame)))
        ]

        for wrapper in views {
            let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
            AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
                let host = Self.hostRootPlatformView(
                    wrapper.view,
                    forceLayout: true,
                    accessibilityIdentifierConfig: isolated
                )
                #expect(host != nil, "\(wrapper.name) default view should host")
                let log = isolated.getDebugLog()
                let fingerprint = Self.issue245_namedAutomaticComplianceFingerprint(componentName: wrapper.name)
                #expect(
                    !log.contains(fingerprint),
                    "\(wrapper.name) default entry must not use NamedAutomaticComplianceModifier (issue #245); use identifierName path; log sample: \(String(log.suffix(400)))"
                )
            }
        }
    }
}
