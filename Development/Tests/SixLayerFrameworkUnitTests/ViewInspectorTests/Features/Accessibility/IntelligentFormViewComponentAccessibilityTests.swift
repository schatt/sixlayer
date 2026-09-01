import Testing
import SwiftUI
@testable import SixLayerFramework

/// Hosted accessibility identifiers for IntelligentFormView / IntelligentDetailView.
/// VI lane only (#412). Always asserts; no `canImport(ViewInspector)` skip (#398).
@Suite("Intelligent Form View Component Accessibility", HostedViewTestIsolationTrait())
open class IntelligentFormViewComponentAccessibilityTests: BaseTestClass {

    @Test @MainActor func testIntelligentFormViewGeneratesAccessibilityIdentifiers() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            struct SampleData {
                let name: String
                let email: String
            }

            let sampleData = SampleData(name: "Test User", email: "test@example.com")
            let view = IntelligentFormView.generateForm(
                for: SampleData.self,
                initialData: sampleData,
                onSubmit: { _ in },
                onCancel: { }
            )

            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*IntelligentFormView.*",
                platform: SixLayerPlatform.current,
                componentName: "IntelligentFormView"
            )
            #expect(hasAccessibilityID, "IntelligentFormView should generate accessibility identifiers")
        }
    }

    /// Type-only form generation (no initialData) must still expose identifiers.
    @Test @MainActor func testTypeOnlyFormGenerationGeneratesAccessibilityIdentifiers() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            struct TestUser {
                let name: String
                let email: String
            }

            let view = IntelligentFormView.generateForm(
                for: TestUser.self,
                initialData: nil,
                onSubmit: { _ in },
                onCancel: { }
            )

            _ = TestSetupUtilities.hostRootPlatformView(view, forceLayout: true)
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "*IntelligentFormView*",
                platform: SixLayerPlatform.current,
                componentName: "IntelligentFormView"
            )
            #expect(hasAccessibilityID, "Type-only form shell should expose IntelligentFormView accessibility identifiers")
        }
    }

    /// Update form path (`generateForm(for: entity)`) must expose identifiers.
    @Test @MainActor func testUpdateFormPathGeneratesAccessibilityIdentifiers() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            struct SampleData {
                let name: String
                let email: String
            }

            let sampleData = SampleData(name: "Test User", email: "test@example.com")
            let view = IntelligentFormView.generateForm(
                for: sampleData,
                onUpdate: { _ in },
                onCancel: { }
            )

            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*IntelligentFormView.*",
                platform: SixLayerPlatform.current,
                componentName: "IntelligentFormView"
            )
            #expect(hasAccessibilityID, "Update form path should generate accessibility identifiers")
        }
    }

    /// Required-field form still generates identifiers (asterisk rendering is visual; ID is the unit/VI contract).
    @Test @MainActor func testIntelligentFormViewShowsAsteriskForRequiredFields() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            struct TestData {
                let name: String
                let email: String?
            }

            let testData = TestData(name: "Test User", email: "test@example.com")
            let view = IntelligentFormView.generateForm(
                for: TestData.self,
                initialData: testData,
                onSubmit: { _ in },
                onCancel: { }
            )

            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*IntelligentFormView.*",
                platform: SixLayerPlatform.current,
                componentName: "IntelligentFormView"
            )
            #expect(hasAccessibilityID, "IntelligentFormView with required fields should generate accessibility identifiers")
        }
    }

    @Test @MainActor func testIntelligentDetailViewGeneratesAccessibilityIdentifiers() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let detailData = IntelligentDetailData(
                id: "detail-1",
                title: "Intelligent Detail",
                content: "This is intelligent detail content",
                metadata: ["key": "value"]
            )

            let view = IntelligentDetailView.platformDetailView(for: detailData)

            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.current,
                componentName: "IntelligentDetailView"
            )
            #expect(hasAccessibilityID, "IntelligentDetailView should generate accessibility identifiers")
        }
    }
}

fileprivate struct IntelligentDetailData {
    let id: String
    let title: String
    let content: String
    let metadata: [String: String]
}
