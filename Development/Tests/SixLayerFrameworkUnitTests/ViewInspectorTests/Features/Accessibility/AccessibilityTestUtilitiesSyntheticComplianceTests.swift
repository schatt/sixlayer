import Testing
import SwiftUI
@testable import SixLayerFramework

/// Harness-level tests for synthetic ID recovery when anonymous `.automaticCompliance()` suppresses wrapper IDs (#222).
@Suite("AccessibilityTestUtilities synthetic anonymous compliance")
struct AccessibilityTestUtilitiesSyntheticComplianceTests {

    @Test @MainActor
    func getAccessibilityIdentifierReadsNamespacedIDFromDebugLog() {
        let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        let view = Text("Save")
            .automaticCompliance(accessibilityLabel: "Save document")
        let root = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
            TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: config
            )
        }
        let identifier = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
            getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
        }
        #expect(identifier?.contains("SixLayer") == true, "Expected namespaced ID from debug log; got \(identifier ?? "nil")")
    }

    @Test @MainActor
    func syntheticIdentifierMatchesPatternForExplicitIdentifierNameCompliance() {
        let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        let field = DynamicFormField(
            id: "username",
            contentType: .text,
            label: "Username",
            isRequired: true
        )
        let formState = DynamicFormState(configuration: DynamicFormConfiguration(
            id: "test", title: "Test", sections: [], submitButtonText: "Submit"
        ))
        let view = DynamicFormFieldView(field: field, formState: formState)

        let ids = AccessibilityTestUtilities.testingSyntheticAutomaticComplianceIdentifiers(
            view: view,
            config: config
        )

        #expect(
            ids.contains(where: {
                AccessibilityTestUtilities.identifierMatchesExpectedPattern($0, expectedPattern: "SixLayer.main.ui.*username*")
            }),
            "Expected synthetic ID from automaticCompliance(identifierName:) on field row; got: \(ids)"
        )
    }

    @Test @MainActor
    func syntheticIdentifierMatchesPatternForNamedAutomaticCompliance() {
        let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        let view = Image(systemName: "photo")
            .automaticCompliance(named: "Image")

        let ids = AccessibilityTestUtilities.testingSyntheticAutomaticComplianceIdentifiers(
            view: view,
            config: config
        )

        #expect(
            ids.contains(where: {
                AccessibilityTestUtilities.identifierMatchesExpectedPattern($0, expectedPattern: "SixLayer.main.ui.*Image*")
            }),
            "Expected synthetic ID for automaticCompliance(named:); got: \(ids)"
        )
    }

    @Test @MainActor
    func syntheticIdentifierMatchesSixLayerUiGlobForAnonymousImageCompliance() {
        let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        let view = Image(systemName: "photo")
            .automaticCompliance()

        let ids = AccessibilityTestUtilities.testingSyntheticAutomaticComplianceIdentifiers(
            view: view,
            config: config
        )

        #expect(
            ids.contains(where: {
                AccessibilityTestUtilities.identifierMatchesExpectedPattern($0, expectedPattern: "SixLayer.*ui")
            }),
            "Expected synthetic ID for anonymous Image automaticCompliance; got: \(ids)"
        )
    }

    @Test @MainActor
    func syntheticIdentifierMatchesSixLayerUiGlobForAnonymousButtonCompliance() {
        let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        let view = Button("Test Button") { }
            .automaticCompliance()

        let ids = AccessibilityTestUtilities.testingSyntheticAutomaticComplianceIdentifiers(
            view: view,
            config: config
        )

        #expect(
            ids.contains(where: {
                AccessibilityTestUtilities.identifierMatchesExpectedPattern($0, expectedPattern: "SixLayer.*ui")
            }),
            "Expected synthetic ID for anonymous Button automaticCompliance; got: \(ids)"
        )
    }
}
