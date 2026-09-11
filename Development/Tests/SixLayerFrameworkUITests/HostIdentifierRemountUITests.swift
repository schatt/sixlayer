//
//  HostIdentifierRemountUITests.swift
//  SixLayerFrameworkUITests
//
//  #473: macOS `accessibilityHostIdentifier` XCUI contract — query via
//  `descendants(.any)` + identifier (not typed otherElements/scrollViews),
//  stamp on an outer container, survive sheet dismiss + nested `.id` remount.
//

import XCTest
import SixLayerTestKit

/// Deep-link `-OpenHostIdentifierRemount`. Host stamps **only**
/// `accessibilityHostIdentifier` on the outer container (no plain
/// `.accessibilityIdentifier` on that same view).
@MainActor
final class HostIdentifierRemountUITests: SixLayerUITestCase {
    /// Keep in sync with `HostIdentifierRemountIDs` in the TestApp host (separate target).
    private enum IDs {
        static let land = "host-identifier-remount-host-root"
        static let host = "SixLayer.uitest.hostIdentifier.scrollHost"
        static let nested = "SixLayer.uitest.hostIdentifier.nested"
        static let presentSheet = "SixLayer.uitest.hostIdentifier.presentSheet"
        static let dismissSheet = "SixLayer.uitest.hostIdentifier.dismissSheet"
        static let remount = "SixLayer.uitest.hostIdentifier.remount"
        static let sheetContent = "SixLayer.uitest.hostIdentifier.sheetContent"
    }

    nonisolated(unsafe) private var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenHostIdentifierRemount")
            localApp.launch()
            instance.app = localApp
            XCTAssertEqual(localApp.state, .runningForeground, "HostIdentifierRemount host should be foreground")
            XCTAssertTrue(
                localApp.waitForHostRootIdentifier(IDs.land, timeout: 8.0),
                "Land marker '\(IDs.land)' should exist (-OpenHostIdentifierRemount)"
            )
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            if instance.app.state != .notRunning {
                instance.app.terminate()
                _ = instance.app.wait(for: .notRunning, timeout: 5)
            }
            instance.app = nil
        }
        try super.tearDownWithError()
    }

    /// Resolve host ids with `.any` + `identifier ==` — the macOS Text sentinel is
    /// `StaticText`, not `Other` / `ScrollView` (#370 / #473).
    @MainActor
    func testHostIdentifier_onlyStamp_survivesSheetDismissAndNestedRemount() throws {
        XCTAssertTrue(
            app.waitForAccessibilityIdentifier(IDs.host, timeout: 2.5),
            "Host id '\(IDs.host)' must resolve via descendants(.any) from accessibilityHostIdentifier alone"
        )
        assertHostAXTypeAndTypedQueries(context: "before sheet")

        let nested = element(identifier: IDs.nested)
        XCTAssertTrue(nested.waitForExistence(timeout: 2.0), "Nested content id should exist before sheet")
        XCTAssertEqual(
            nested.xcuiAccessibleText,
            "Nested 0",
            "Nested content should start at epoch 0 so remount can be observed"
        )
        assertHostIsLeafNotParent(context: "before sheet")
        #if os(macOS)
        assertHostDoesNotExposeIdentifierAsAccessibleText(context: "before sheet")
        #endif

        let present = element(identifier: IDs.presentSheet)
        XCTAssertTrue(present.waitForExistence(timeout: 2.0), "Present-sheet control should exist")
        tapByNormalizedCenter(present)

        let sheet = element(identifier: IDs.sheetContent)
        XCTAssertTrue(sheet.waitForExistence(timeout: 2.5), "Sheet content should appear")

        let dismiss = element(identifier: IDs.dismissSheet)
        XCTAssertTrue(dismiss.waitForExistence(timeout: 2.0), "Sheet dismiss control should exist")
        tapByNormalizedCenter(dismiss)

        let sheetGoneDeadline = Date().addingTimeInterval(2.5)
        while sheet.exists, Date() < sheetGoneDeadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertFalse(sheet.exists, "Sheet should dismiss before remount")

        let remount = element(identifier: IDs.remount)
        XCTAssertTrue(remount.waitForExistence(timeout: 2.0), "Remount control should exist on the parent after dismiss")
        tapByNormalizedCenter(remount)

        let nestedAfter = element(identifier: IDs.nested)
        XCTAssertTrue(nestedAfter.waitForExistence(timeout: 2.5), "Nested content should exist after .id remount")
        XCTAssertEqual(
            nestedAfter.xcuiAccessibleText,
            "Nested 1",
            "Remount must change nested identity (epoch 0 → 1); a no-op remount is not the contract"
        )
        XCTAssertTrue(
            app.waitForAccessibilityIdentifier(IDs.host, timeout: 2.5),
            "Host id '\(IDs.host)' must still resolve via descendants(.any) after sheet dismiss and nested .id remount"
        )
        assertHostAXTypeAndTypedQueries(context: "after remount")
        assertHostIsLeafNotParent(context: "after remount")
        #if os(macOS)
        assertHostDoesNotExposeIdentifierAsAccessibleText(context: "after remount")
        #endif
    }

    /// Both-direction AX contract: `.any` already waited; typed slots must match the documented type.
    @MainActor
    private func assertHostAXTypeAndTypedQueries(context: String) {
        let host = element(identifier: IDs.host)
        #if os(macOS)
        XCTAssertEqual(
            host.elementType,
            .staticText,
            "\(context): macOS accessibilityHostIdentifier is a Text leaf (StaticText)"
        )
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "identifier == %@", IDs.host)).firstMatch.exists,
            "\(context): macOS host id should match staticTexts (documented AX type)"
        )
        XCTAssertFalse(
            app.otherElements.matching(NSPredicate(format: "identifier == %@", IDs.host)).firstMatch.exists,
            "\(context): macOS host id must not require otherElements"
        )
        XCTAssertFalse(
            app.scrollViews.matching(NSPredicate(format: "identifier == %@", IDs.host)).firstMatch.exists,
            "\(context): macOS host id must not require scrollViews"
        )
        #else
        XCTAssertEqual(
            host.elementType,
            .other,
            "\(context): iOS accessibilityHostIdentifier is Color.clear + .ignore (.other)"
        )
        XCTAssertTrue(
            app.otherElements.matching(NSPredicate(format: "identifier == %@", IDs.host)).firstMatch.exists,
            "\(context): iOS host id should match otherElements (documented AX type)"
        )
        XCTAssertFalse(
            app.staticTexts.matching(NSPredicate(format: "identifier == %@", IDs.host)).firstMatch.exists,
            "\(context): iOS host id should not appear as StaticText"
        )
        #endif
    }

    /// The host stamp is a background leaf. Nested contract ids must be found from `app`, not as
    /// descendants of the host element (#473).
    @MainActor
    private func assertHostIsLeafNotParent(context: String) {
        let host = element(identifier: IDs.host)
        let nestedUnderHost = host.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", IDs.nested))
            .firstMatch
        XCTAssertFalse(
            nestedUnderHost.exists,
            "\(context): host sentinel is not a parent of nested content; do not query host.descendants for child ids"
        )
        XCTAssertTrue(
            element(identifier: IDs.nested).exists,
            "\(context): nested id must still resolve from the application (sibling of the sentinel)"
        )
    }

    /// macOS Text sentinel must not advertise the contract id as its accessible name (VoiceOver).
    @MainActor
    private func assertHostDoesNotExposeIdentifierAsAccessibleText(context: String) {
        let host = element(identifier: IDs.host)
        XCTAssertNotEqual(
            host.xcuiAccessibleText,
            IDs.host,
            "\(context): macOS host sentinel must not use the identifier as VoiceOver label/value"
        )
    }

    @MainActor
    private func element(identifier: String) -> XCUIElement {
        app.elementMatchingAccessibilityIdentifier(identifier)
    }

    @MainActor
    private func tapByNormalizedCenter(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
