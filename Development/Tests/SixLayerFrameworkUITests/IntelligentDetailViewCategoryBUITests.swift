//
//  IntelligentDetailViewCategoryBUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #198: Category B UI backfill for IntelligentDetailView visible content.
//  Content must be in the accessibility tree at launch — do not scroll to find it (#316).
//
//  #348: land on exact host-root; single-predicate text presence (no sequential OR wait ladder).
//  #374: one shared app process for the class (same launch args every method).
//

import XCTest

@MainActor
final class IntelligentDetailViewCategoryBUITests: XCTestCase {
    private enum Copy {
        static let defaultTitle = "Category B Item"
        static let defaultSubtitle = "Category B Subtitle"
        static let customFieldPrefix = "Custom Field:"
        static let nilTitle = "Nil Item"
        static let nilDescription = "Nil Description"
    }

    private enum Host {
        static let rootIdentifier = "category-b-detail-host-root"
    }

    var app: XCUIApplication!
    private static var sharedApp: XCUIApplication?

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            if let existing = Self.sharedApp, existing.state == .runningForeground {
                instance.app = existing
                return
            }
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenDetailViewCategoryB")
            localApp.launch()
            Self.sharedApp = localApp
            instance.app = localApp

            XCTAssertTrue(
                localApp.waitForHostRootIdentifier(Host.rootIdentifier),
                "Category B host should appear with -OpenDetailViewCategoryB"
            )
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    override class func tearDown() {
        if let running = sharedApp, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        sharedApp = nil
        super.tearDown()
    }

    /// One XCUI query for exact text in label/value/title — avoids sequential wait ladders (#348 / #316).
    @MainActor
    private func assertAccessibleTextExists(_ text: String, timeout: TimeInterval = 2.0, _ message: String) {
        // Exact substring match in one query — IntelligentDetailView demotes labels on macOS (#316);
        // avoid sequential wait ladders (#348). Keep strings short/known to limit CONTAINS cost.
        let pred = NSPredicate(
            format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@ OR title CONTAINS[c] %@",
            text, text, text
        )
        XCTAssertTrue(
            app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: timeout),
            message
        )
    }

    func testCategoryB_defaultDetailView_showsTitleAndSubtitle() throws {
        assertAccessibleTextExists(Copy.defaultTitle, "Default detail title should be in the accessibility tree")
        assertAccessibleTextExists(Copy.defaultSubtitle, "Default detail subtitle should be in the accessibility tree")
    }

    func testCategoryB_customFieldView_showsCustomMarker() throws {
        // IntelligentDetailView reparents customFieldView; literal ids are unreliable here.
        // Assert visible marker text with the single-predicate helper (#348).
        assertAccessibleTextExists(
            Copy.customFieldPrefix,
            "Custom field rendering should expose the custom marker text"
        )
    }

    func testCategoryB_nilValueData_showsRemainingVisibleContent() throws {
        assertAccessibleTextExists(Copy.nilTitle, "Nil-value detail title should be in the accessibility tree")
        assertAccessibleTextExists(Copy.nilDescription, "Nil-value detail description should be in the accessibility tree")
    }
}
