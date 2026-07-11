//
//  Layer1AccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for Layer 1 platform*_L1 function accessibility
//  Implements Issue #166: Complete accessibility for Layer 1 platform* methods
//
//  #316: deep-link via `-OpenLayer1Category=…` + optional `-L1Section=…` —
//  no UI Test Views home, no swipe discovery, no OR-fallback query chains.
//

import XCTest
@testable import SixLayerFramework

/// XCUITest tests for Layer 1 accessibility features.
@MainActor
final class Layer1AccessibilityUITests: XCTestCase {
    nonisolated(unsafe) private var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()
        // No launch — each test deep-links its category (#316).
    }

    nonisolated override func tearDownWithError() throws {
        if let running = app, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        app = nil
        try super.tearDownWithError()
    }

    private static func categoryArg(_ categoryName: String) -> String {
        categoryName.replacingOccurrences(of: " ", with: "-")
    }

    @MainActor
    private func launchLayer1Category(_ categoryName: String, section: String? = nil) {
        if let running = app, running.state != .notRunning {
            running.terminate()
        }
        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        localApp.launchArguments.append("-OpenLayer1Category=\(Self.categoryArg(categoryName))")
        if let section {
            localApp.launchArguments.append("-L1Section=\(section)")
        }
        localApp.launch()
        app = localApp
        XCTAssertEqual(localApp.state, .runningForeground, "Layer1 host should be foreground")
        XCTAssertTrue(
            app.navigationBars[categoryName].exists
                || app.staticTexts[categoryName].exists,
            "Layer1 category '\(categoryName)' nav title should exist at launch (-OpenLayer1Category=\(Self.categoryArg(categoryName)))"
        )
    }

    @MainActor
    private func element(identifierContains substring: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", substring))
            .firstMatch
    }

    @MainActor
    private func assertExactIdentifierExists(_ identifier: String, context: String) {
        let el = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(el.exists, "\(context): missing exact id '\(identifier)'")
    }

    @MainActor
    private func verifyAccessibilityIdentifier(_ element: XCUIElement, functionName: String) {
        XCTAssertFalse(
            element.identifier.isEmpty,
            "\(functionName) should have accessibility identifier. Found: '\(element.identifier)'"
        )
    }

    /// Single-tappable card contract without scroll-as-discovery (#316).
    @MainActor
    private func assertSingleTappableCard(title: String, elementName: String) {
        let el = app.buttons[title].firstMatch
        XCTAssertTrue(
            el.exists,
            "\(elementName) with title '\(title)' should exist at section launch (no scroll)"
        )
        el.verifyAccessibilityContract(
            elementName: elementName,
            expectedType: .button,
            requireLabel: true
        )
    }

    @MainActor
    private func assertCategorySurfaces(_ category: String) {
        switch category {
        case "Data Presentation":
            assertExactIdentifierExists("L1_Section_Items", context: "Data Presentation items section")
            let itemCollection = element(identifierContains: "platformPresentItemCollection_L1")
            XCTAssertTrue(itemCollection.exists, "Data Presentation should expose platformPresentItemCollection_L1")
            verifyAccessibilityIdentifier(itemCollection, functionName: "platformPresentItemCollection_L1")

        case "Navigation":
            let navStack = element(identifierContains: "platformPresentNavigationStack_L1")
            XCTAssertTrue(navStack.exists, "Navigation should expose platformPresentNavigationStack_L1")
            verifyAccessibilityIdentifier(navStack, functionName: "platformPresentNavigationStack_L1")

        case "Photos":
            let photoCapture = element(identifierContains: "platformPhotoCapture_L1")
            XCTAssertTrue(photoCapture.exists, "Photos should expose platformPhotoCapture_L1")
            verifyAccessibilityIdentifier(photoCapture, functionName: "platformPhotoCapture_L1")

        case "Security":
            XCTAssertTrue(
                element(identifierContains: "SixLayer.main.ui").exists,
                "Security examples should expose SixLayer automatic accessibility identifiers (#245)"
            )

        case "OCR":
            let ocr = element(identifierContains: "platformOCRWithDisambiguation_L1")
            XCTAssertTrue(ocr.exists, "OCR should expose platformOCRWithDisambiguation_L1")
            verifyAccessibilityIdentifier(ocr, functionName: "platformOCRWithDisambiguation_L1")

        case "Notifications":
            assertExactIdentifierExists(
                "L1_NotificationAPI_platformRequestNotificationPermission_L1",
                context: "Notifications API surface"
            )

        case "Internationalization":
            XCTAssertTrue(
                element(identifierContains: "SixLayer.main.ui").exists,
                "Internationalization examples should expose SixLayer automatic accessibility identifiers (#245)"
            )

        case "Data Analysis":
            let analyze = element(identifierContains: "platformAnalyzeDataFrame_L1")
            XCTAssertTrue(analyze.exists, "Data Analysis should expose platformAnalyzeDataFrame_L1")
            verifyAccessibilityIdentifier(analyze, functionName: "platformAnalyzeDataFrame_L1")

        default:
            XCTFail("Unknown Layer1 category: \(category)")
        }
    }

    // MARK: - Per-category deep-link tests (#316)

    @MainActor
    func testLayer1_dataPresentation_accessibilitySurfaces() throws {
        launchLayer1Category("Data Presentation", section: "items")
        assertCategorySurfaces("Data Presentation")
    }

    @MainActor
    func testLayer1_navigation_accessibilitySurfaces() throws {
        launchLayer1Category("Navigation")
        assertCategorySurfaces("Navigation")
    }

    @MainActor
    func testLayer1_photos_accessibilitySurfaces() throws {
        launchLayer1Category("Photos")
        assertCategorySurfaces("Photos")
    }

    @MainActor
    func testLayer1_security_accessibilitySurfaces() throws {
        launchLayer1Category("Security")
        assertCategorySurfaces("Security")
    }

    @MainActor
    func testLayer1_ocr_accessibilitySurfaces() throws {
        launchLayer1Category("OCR")
        assertCategorySurfaces("OCR")
    }

    @MainActor
    func testLayer1_notifications_accessibilitySurfaces() throws {
        launchLayer1Category("Notifications")
        assertCategorySurfaces("Notifications")
    }

    @MainActor
    func testLayer1_internationalization_accessibilitySurfaces() throws {
        launchLayer1Category("Internationalization")
        assertCategorySurfaces("Internationalization")
    }

    @MainActor
    func testLayer1_dataAnalysis_accessibilitySurfaces() throws {
        launchLayer1Category("Data Analysis")
        assertCategorySurfaces("Data Analysis")
    }

    // MARK: - Card components (Issue #191)

    @MainActor
    func testItemCollectionCards_ExposeSingleTappableElements() throws {
        launchLayer1Category("Data Presentation", section: "items")
        assertExactIdentifierExists("L1_Section_Items", context: "Item collection host")
        for title in ["Item 1", "Item 2", "Item 3"] {
            assertSingleTappableCard(
                title: title,
                elementName: "platformPresentItemCollection_L1 card"
            )
        }
    }

    @MainActor
    func testResponsiveCard_ExposesSingleTappableElement() throws {
        launchLayer1Category("Data Presentation", section: "responsiveCard")
        assertExactIdentifierExists("L1_Section_ResponsiveCard", context: "Responsive card host")
        assertSingleTappableCard(
            title: "Card Title",
            elementName: "platformResponsiveCard_L1 card"
        )
    }
}
