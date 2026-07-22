//
//  OCRCategoryDUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #200: Category D UI backfill for OCR disambiguation and overlay outcomes.
//  #373: one shared app process for the class (same launch args every method).
//

import XCTest

@MainActor
final class OCRCategoryDUITests: XCTestCase {
    private enum IDs {
        static let hostTitle = "Category D OCR Coverage"
        static let disambiguationPrompt = "category-d-disambiguation-prompt"
        static let candidateFirstLabelFragment = "Category D Candidate 1"
        static let candidateSecondLabelFragment = "Category D Candidate 2"
        static let selectionState = "category-d-selection-state"
        static let openOverlayButton = "category-d-open-overlay"
        static let overlayState = "category-d-overlay-state"
        static let overlayDoneButton = "category-d-overlay-done"
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
            localApp.launchArguments.append("-OpenOCRCategoryD")
            localApp.launch()
            Self.sharedApp = localApp
            instance.app = localApp

            XCTAssertTrue(
                localApp.staticTexts[IDs.hostTitle].waitForExistence(timeout: 2.5),
                "Category D OCR host should appear with -OpenOCRCategoryD"
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

    @MainActor
    private func button(containingLabel fragment: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS %@", fragment)
        return app.buttons.matching(predicate).firstMatch
    }

    func testCategoryD_disambiguationFlow_showsAlternativesAndReflectsSelection() throws {
        let prompt = app.staticTexts[IDs.disambiguationPrompt]
        XCTAssertTrue(prompt.waitForExistence(timeout: 1.5), "Disambiguation prompt should be visible")

        let firstCandidate = button(containingLabel: IDs.candidateFirstLabelFragment)
        let secondCandidate = button(containingLabel: IDs.candidateSecondLabelFragment)
        XCTAssertTrue(firstCandidate.waitForExistence(timeout: 1.5), "First OCR candidate should exist")
        XCTAssertTrue(secondCandidate.waitForExistence(timeout: 1.5), "Second OCR candidate should exist")

        let selectionState = app.descendants(matching: .any)[IDs.selectionState]
        XCTAssertTrue(selectionState.waitForExistence(timeout: 1.5), "Selection state label should exist")
        XCTAssertEqual(selectionState.xcuiAccessibleText, "Selected candidate: none")

        secondCandidate.tap()
        XCTAssertEqual(selectionState.xcuiAccessibleText, "Selected candidate: Category D Candidate 2")
    }

    func testCategoryD_overlayFlow_presentAndDismiss_updatesOutcomeState() throws {
        let overlayState = app.descendants(matching: .any)[IDs.overlayState]
        XCTAssertTrue(overlayState.waitForExistence(timeout: 1.5), "Overlay state label should exist")
        XCTAssertEqual(overlayState.xcuiAccessibleText, "Overlay state: hidden")

        let openOverlay = app.buttons[IDs.openOverlayButton]
        XCTAssertTrue(openOverlay.waitForExistence(timeout: 1.5), "Open overlay action should exist")
        openOverlay.tap()
        XCTAssertEqual(overlayState.xcuiAccessibleText, "Overlay state: presented")

        let done = app.buttons[IDs.overlayDoneButton]
        XCTAssertTrue(done.waitForExistence(timeout: 1.5), "Overlay dismiss action should exist")
        done.tap()
        XCTAssertEqual(overlayState.xcuiAccessibleText, "Overlay state: dismissed")
    }
}
