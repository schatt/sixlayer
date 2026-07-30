//
//  FieldLayout385UITests.swift
//  SixLayerFrameworkUITests
//
//  GitHub #385: Observe ModalFormView checkbox packing (side-by-side) and
//  shared column leading edge (minX) in a real window.
//

import XCTest

@MainActor
final class FieldLayout385UITests: XCTestCase {
    private var app: XCUIApplication!

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
        localApp.launchArguments.append("-OpenFieldLayout385")
        localApp.launch()
        app = localApp
        #if os(macOS)
        localApp.activate()
        #endif
        XCTAssertTrue(
            localApp.wait(for: .runningForeground, timeout: 8.0),
            "FL385 host should be foreground after launch"
        )
        XCTAssertTrue(
            element(exactIdentifier: "FL385_Host").waitForExistence(timeout: 8.0),
            "FL385_Host should exist at launch"
        )
    }

    @MainActor
    private func element(exactIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", id))
            .firstMatch
    }

    /// Prefer switch/toggle; fall back to any descendant with the field label.
    @MainActor
    private func checkbox(labeled label: String) -> XCUIElement {
        let asSwitch = app.switches[label]
        if asSwitch.waitForExistence(timeout: 2.0) {
            return asSwitch
        }
        let asToggle = app.toggles[label]
        if asToggle.waitForExistence(timeout: 2.0) {
            return asToggle
        }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    /// Packing places B beside A (greater minX); column peers A/C and B/D share leading edges.
    @MainActor
    func testModalFormCheckboxPackingAndColumnAlignment() {
        launchHost()

        let a = checkbox(labeled: "FL385 A")
        let b = checkbox(labeled: "FL385 B")
        let c = checkbox(labeled: "FL385 C")
        let d = checkbox(labeled: "FL385 D")

        XCTAssertTrue(a.waitForExistence(timeout: 8.0), "FL385 A should exist")
        XCTAssertTrue(b.waitForExistence(timeout: 8.0), "FL385 B should exist")
        XCTAssertTrue(c.waitForExistence(timeout: 8.0), "FL385 C should exist")
        XCTAssertTrue(d.waitForExistence(timeout: 8.0), "FL385 D should exist")

        let frameA = a.frame
        let frameB = b.frame
        let frameC = c.frame
        let frameD = d.frame

        // Side-by-side packing (not a single vertical stack).
        XCTAssertGreaterThan(
            frameB.minX,
            frameA.minX + 20,
            "B should pack beside A (minX), not stack under it — A=\(frameA) B=\(frameB)"
        )

        // Shared column leading edges.
        XCTAssertEqual(
            frameA.minX,
            frameC.minX,
            accuracy: 2.0,
            "Column 0 checkboxes A and C should share leading edge — A=\(frameA) C=\(frameC)"
        )
        XCTAssertEqual(
            frameB.minX,
            frameD.minX,
            accuracy: 2.0,
            "Column 1 checkboxes B and D should share leading edge — B=\(frameB) D=\(frameD)"
        )
    }
}
