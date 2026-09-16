import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformInternationalizationL1 (#466).
 * Calls L1 presenters/RTL shells (service logic already covered elsewhere).
 */

@Suite("Platform Internationalization L1 Unit", HostedViewTestIsolationTrait())
struct PlatformInternationalizationL1UnitTests {

    private var enUS: InternationalizationHints {
        InternationalizationHints(
            locale: Locale(identifier: "en_US"),
            currencyCode: "USD",
            decimalPlaces: 2
        )
    }

    @Test @MainActor
    func localizedNumberCurrencyDatePresentersHost() {
        #if os(watchOS)
        return
        #else
        let number = platformPresentLocalizedNumber_L1(number: 1234.5, hints: enUS)
        let currency = platformPresentLocalizedCurrency_L1(amount: 12.34, hints: enUS)
        let date = platformPresentLocalizedDate_L1(date: Date(timeIntervalSince1970: 0), hints: enUS)
        let time = platformPresentLocalizedTime_L1(date: Date(timeIntervalSince1970: 0), hints: enUS)
        let percent = platformPresentLocalizedPercentage_L1(value: 0.25, hints: enUS)
        let plural = platformPresentLocalizedPlural_L1(word: "item", count: 2, hints: enUS)
        let text = platformPresentLocalizedText_L1(text: "Hello", hints: enUS)
        let content = platformPresentLocalizedContent_L1(content: Text("Body"), hints: enUS)
        for view in [number, currency, date, time, percent, plural, text, content] {
            let hosted = TestSetupUtilities.hostRootPlatformView(view, forceLayout: true)
            #expect(hosted != nil)
        }
        #endif
    }

    @Test @MainActor
    func rtlShellsHostWithArabicLocale() {
        #if os(watchOS)
        return
        #else
        let hints = InternationalizationHints(locale: Locale(identifier: "ar"))
        let container = platformRTLContainer_L1(content: Text("م"), hints: hints)
        let h = platformRTLHStack_L1(content: { Text("a"); Text("b") }, hints: hints)
        let v = platformRTLVStack_L1(content: { Text("a"); Text("b") }, hints: hints)
        for view in [container, h, v] {
            let hosted = TestSetupUtilities.hostRootPlatformView(view, forceLayout: true)
            #expect(hosted != nil)
        }
        #endif
    }

    @Test @MainActor
    func localizedTextFieldHostsWithIdentifierName() {
        #if os(watchOS)
        return
        #else
        var value = ""
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        isolated.enableDebugLogging = true
        isolated.clearDebugLog()
        let view = platformLocalizedTextField_L1(
            title: "Name",
            text: Binding(get: { value }, set: { value = $0 }),
            hints: enUS
        )
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
            log.contains("platformLocalizedTextField_L1"),
            "localized text field must use identifierName path. log=\(String(log.suffix(400)))"
        )
        #endif
    }

    @Test
    func internationalizationHintsDefaultsAreStable() {
        let hints = InternationalizationHints()
        // Deliberate red (#466): wrong default so first run fails.
        #expect(hints.currencyCode == "EUR")
        #expect(hints.enableRTL == true)
        #expect(hints.dateStyle == .medium)
    }
}
