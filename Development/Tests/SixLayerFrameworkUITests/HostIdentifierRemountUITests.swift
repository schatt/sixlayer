//
//  HostIdentifierRemountUITests.swift
//  SixLayerFrameworkUITests
//
//  #473: macOS `accessibilityHostIdentifier` XCUI contract — query via
//  `descendants(.any)` + identifier (not typed otherElements/scrollViews),
//  stamp on an outer container, survive sheet dismiss + nested `.id` remount.
//

import XCTest

/// Deep-link `-OpenHostIdentifierRemount`. Host stamps **only**
/// `accessibilityHostIdentifier` on the outer container (no plain
/// `.accessibilityIdentifier` on that same view).
@MainActor
final class HostIdentifierRemountUITests: SixLayerUITestCase {
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
        let host = element(identifier: IDs.host)
        XCTAssertTrue(
            host.waitForExistence(timeout: 2.5),
            "Host id '\(IDs.host)' must resolve via descendants(.any) from accessibilityHostIdentifier alone"
        )
        #if os(macOS)
        XCTAssertEqual(
            host.elementType,
            .staticText,
            "macOS accessibilityHostIdentifier is a Text leaf (StaticText). Do not query otherElements or scrollViews."
        )
        #else
        XCTAssertEqual(
            host.elementType,
            .other,
            "iOS accessibilityHostIdentifier is Color.clear + .ignore (.other)"
        )
        #endif

        XCTAssertTrue(
            element(identifier: IDs.nested).waitForExistence(timeout: 2.0),
            "Nested content id should exist before sheet"
        )

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

        XCTAssertTrue(
            element(identifier: IDs.nested).waitForExistence(timeout: 2.5),
            "Nested content should exist after .id remount"
        )
        XCTAssertTrue(
            app.waitForHostRootIdentifier(IDs.host, timeout: 2.5),
            "Host id '\(IDs.host)' must still resolve via descendants(.any) after sheet dismiss and nested .id remount"
        )
    }

    @MainActor
    private func element(identifier: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", identifier))
            .firstMatch
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
