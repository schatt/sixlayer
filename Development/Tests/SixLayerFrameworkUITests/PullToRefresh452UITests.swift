//
//  PullToRefresh452UITests.swift
//  SixLayerFrameworkUITests
//
//  GitHub #452: Thin XCUI sentinel — pull-to-refresh fires onRefresh.
//

import XCTest

#if os(iOS)
@MainActor
final class PullToRefresh452UITests: SixLayerUITestCase {
    private nonisolated(unsafe) var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()
    }

    nonisolated override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    @MainActor
    private func launchHost() {
        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        localApp.launchArguments.append("-OpenPullToRefresh452")
        localApp.launch()
        app = localApp
        XCTAssertTrue(
            localApp.wait(for: .runningForeground, timeout: 8.0),
            "PullToRefresh452 host should be foreground after launch"
        )
        XCTAssertTrue(
            element(exactIdentifier: "PullToRefresh452_Host").waitForExistence(timeout: 8.0),
            "PullToRefresh452_Host land marker should exist"
        )
    }

    @MainActor
    private func element(exactIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", id))
            .firstMatch
    }

    /// Pull down on the list to trigger `.refreshable` / `platformIOSPullToRefresh`.
    @MainActor
    private func performPullToRefresh() {
        let list = app.tables.firstMatch
        let scroll = list.exists ? list : app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5.0), "Scrollable content for pull-to-refresh")

        let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
        let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    @MainActor
    func testPlatformIOSPullToRefreshFiresOnRefresh() {
        launchHost()

        let status = element(exactIdentifier: "PullToRefresh452_Status")
        XCTAssertTrue(status.waitForExistence(timeout: 5.0), "Status label should exist")
        XCTAssertEqual(status.value as? String ?? status.label, "idle", "Status starts idle")

        performPullToRefresh()

        // Deliberate red (#452): wrong expected value until green after confirming gesture works
        let predicate = NSPredicate(format: "value == %@ OR label == %@", "never-refreshed", "never-refreshed")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: status)
        let result = XCTWaiter.wait(for: [expectation], timeout: 8.0)
        XCTAssertEqual(result, .completed, "onRefresh should flip PullToRefresh452_Status (deliberate red expects never-refreshed)")
    }
}
#endif
