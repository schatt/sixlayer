//
//  OCRCategoryDUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #200: Category D UI backfill for OCR disambiguation and overlay outcomes.
//  Strict TDD: add tests first; host should fail until TestApp support exists.
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

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenOCRCategoryD")
            localApp.launch()
            instance.app = localApp

            XCTAssertTrue(
                localApp.staticTexts[IDs.hostTitle].waitForExistence(timeout: 6.0),
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

    @MainActor
    private func button(containingLabel fragment: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS %@", fragment)
        return app.buttons.matching(predicate).firstMatch
    }

    func testCategoryD_disambiguationFlow_showsAlternativesAndReflectsSelection() throws {
        let prompt = app.staticTexts[IDs.disambiguationPrompt]
        XCTAssertTrue(prompt.waitForExistence(timeout: 4.0), "Disambiguation prompt should be visible")

        let firstCandidate = button(containingLabel: IDs.candidateFirstLabelFragment)
        let secondCandidate = button(containingLabel: IDs.candidateSecondLabelFragment)
        XCTAssertTrue(firstCandidate.waitForExistence(timeout: 4.0), "First OCR candidate should exist")
        XCTAssertTrue(secondCandidate.waitForExistence(timeout: 4.0), "Second OCR candidate should exist")

        let selectionState = app.staticTexts[IDs.selectionState]
        XCTAssertTrue(selectionState.waitForExistence(timeout: 4.0), "Selection state label should exist")
        XCTAssertEqual(selectionState.label, "Selected candidate: none")

        secondCandidate.tap()
        XCTAssertEqual(selectionState.label, "Selected candidate: Category D Candidate 2")
    }

    func testCategoryD_overlayFlow_presentAndDismiss_updatesOutcomeState() throws {
        let overlayState = app.staticTexts[IDs.overlayState]
        XCTAssertTrue(overlayState.waitForExistence(timeout: 4.0), "Overlay state label should exist")
        XCTAssertEqual(overlayState.label, "Overlay state: hidden")

        let openOverlay = app.buttons[IDs.openOverlayButton]
        XCTAssertTrue(openOverlay.waitForExistence(timeout: 4.0), "Open overlay action should exist")
        openOverlay.tap()
        XCTAssertEqual(overlayState.label, "Overlay state: presented")

        let done = app.buttons[IDs.overlayDoneButton]
        XCTAssertTrue(done.waitForExistence(timeout: 4.0), "Overlay dismiss action should exist")
        done.tap()
        XCTAssertEqual(overlayState.label, "Overlay state: dismissed")
    }
}
