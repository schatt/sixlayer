import Testing
import SwiftUI
@testable import SixLayerFramework

/// Proves BaseTestClass non-ViewInspector fallbacks observe hostability (Issue #382).
/// Compiles on all unit lanes; the `#else` stubs are what run when ViewInspector is not linked (tvOS/visionOS).
/// NOTE: Not marked @MainActor on class — parallel-safe; methods use `@Test @MainActor`.
@Suite("BaseTestClass hostability fallback", HostedViewTestIsolationTrait())
open class BaseTestClassHostabilityFallbackTests: BaseTestClass {

    @Test @MainActor func verifyViewContainsAtLeastOneVStack_requiresHostableVStack() {
        let view = VStack { Text("382-hostability") }
        verifyViewContainsAtLeastOneVStack(view, testName: "382-vstack-hostability")
    }

    @Test @MainActor func verifyViewContainsText_requiresHostableView() {
        let view = Text("382-text-hostability")
        verifyViewContainsText(view, expectedText: "382-text-hostability", testName: "382-text-hostability")
    }

    @Test @MainActor func tryWithFirstVStack_requiresHostableViewWithoutInvokingBody() {
        let view = VStack { Text("382-try-vstack") }
        var bodyInvoked = false
        tryWithFirstVStack(view, testName: "382-try-vstack") { _ in
            bodyInvoked = true
        }
        #if canImport(ViewInspector)
        #expect(bodyInvoked, "With ViewInspector, body should run on a found VStack")
        #else
        #expect(!bodyInvoked, "Without ViewInspector, body must not be faked (#382)")
        #endif
    }
}
