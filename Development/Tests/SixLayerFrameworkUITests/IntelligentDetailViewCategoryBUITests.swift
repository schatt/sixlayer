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
            if let running = Self.sharedApp, running.state != .notRunning {
                running.terminate()
                _ = running.wait(for: .notRunning, timeout: 5)
            }
            Self.sharedApp = nil

            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenDetailViewCategoryB")
            localApp.launch()
            instance.app = localApp

            XCTAssertTrue(
                localApp.waitForHostRootIdentifier(Host.rootIdentifier),
                "Category B host should appear with -OpenDetailViewCategoryB"
            )
            Self.sharedApp = localApp
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    override class func tearDown() {
        MainActor.assumeIsolated {
            if let running = sharedApp, running.state != .notRunning {
                running.terminate()
                _ = running.wait(for: .notRunning, timeout: 5)
            }
            sharedApp = nil
        }
        super.tearDown()
    }

    /// Prefer staticTexts with CONTAINS — avoid all-descendants CONTAINS (macOS snapshot hang #370).
    @MainActor
    private func assertAccessibleTextExists(_ text: String, timeout: TimeInterval = 2.0, _ message: String) {
        let exact = app.staticTexts[text].firstMatch
        if exact.waitForExistence(timeout: min(timeout, 1.0)) {
            return
        }
        let contains = NSPredicate(
            format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@",
            text, text
        )
        XCTAssertTrue(
            app.staticTexts.matching(contains).firstMatch.waitForExistence(timeout: timeout),
            message
        )
    }

    func testCategoryB_defaultDetailView_showsTitleAndSubtitle() throws {
        assertAccessibleTextExists(Copy.defaultTitle, "Default detail title should be in the accessibility tree")
        assertAccessibleTextExists(Copy.defaultSubtitle, "Default detail subtitle should be in the accessibility tree")
    }

    func testCategoryB_customFieldView_showsCustomMarker() throws {
        // IntelligentDetailView + automaticCompliance can demote customFieldView out of
        // staticTexts on macOS; scoped all-descendants CONTAINS for this unique prefix is
        // OK (broad CONTAINS on common titles hung — #370).
        let pred = NSPredicate(
            format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@ OR identifier == %@",
            "Custom Field:", "Custom Field:", "category-b-custom-field"
        )
        XCTAssertTrue(
            app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: 8.0),
            "Custom field rendering should expose 'Custom Field:' (label/value) or category-b-custom-field"
        )
    }

    func testCategoryB_nilValueData_showsRemainingVisibleContent() throws {
        assertAccessibleTextExists(Copy.nilTitle, "Nil-value detail title should be in the accessibility tree")
        assertAccessibleTextExists(Copy.nilDescription, "Nil-value detail description should be in the accessibility tree")
    }
}
