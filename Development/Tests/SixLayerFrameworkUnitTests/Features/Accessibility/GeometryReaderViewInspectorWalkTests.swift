import Testing
import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// Release-gate regression (#408): ViewInspector `findAll` into `GeometryReader` must not
/// SIGTRAP via `GeometryProxy` `unsafeBitCast` on iOS 27 Simulator.
/// Hosted platform IDs remain the cheapest truthful observation path.
@Suite("GeometryReader ViewInspector Walk", HostedViewTestIsolationTrait())
open class GeometryReaderViewInspectorWalkTests: BaseTestClass {

    private struct GeometryReaderNamedHost: View {
        var body: some View {
            GeometryReader { _ in
                Text("GeometryReader walk probe")
            }
            .automaticCompliance(named: "GeometryReaderWalkProbe")
        }
    }

    @Test @MainActor func geometryReader_namedCompliance_viewInspectorWalkDoesNotTrap() async {
        initializeTestConfig()
        guard let config = testConfig else {
            Issue.record("testConfig missing after initializeTestConfig()")
            return
        }

        await runWithTaskLocalConfig {
            let view = GeometryReaderNamedHost()
            let hostedRoot = hostRootPlatformView(
                view,
                forceLayout: true,
                exposeContentAccessibility: true,
                accessibilityIdentifierConfig: config
            )
            #expect(hostedRoot != nil, "Hosting GeometryReader + named compliance must not trap (#408)")

            #if canImport(ViewInspector)
            // Release-gate crash site: ClassifiedView findAll → GeometryReader.view() →
            // GeometryProxy.init() unsafeBitCast (#408). Surviving this call is the red/green.
            let inspectedIds = AccessibilityTestUtilities.allAccessibilityIdentifiersFromViewInspector(view)
            #else
            let inspectedIds: [String] = []
            #endif

            let observed = getAccessibilityIdentifierForTest(view: view, hostedRoot: hostedRoot)
            #expect(
                observed.map { !$0.isEmpty } ?? false,
                "Hosted a11y helpers must still observe an identifier for GeometryReader + named compliance (#408); observed=\(String(describing: observed)) inspected=\(inspectedIds)"
            )

            let compliant = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                platform: .iOS,
                componentName: "GeometryReaderWalkProbe"
            )
            #expect(compliant, "testComponentComplianceSinglePlatform must not SIGTRAP on GeometryReader (#408)")
        }
    }
}
