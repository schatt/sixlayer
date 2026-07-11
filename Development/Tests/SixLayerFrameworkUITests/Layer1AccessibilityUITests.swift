//
//  Layer1AccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for Layer 1 platform*_L1 function accessibility
//  Implements Issue #166: Complete accessibility for Layer 1 platform* methods
//
//  #316: deep-link via `-OpenLayer1Category=…` — no UI Test Views home, no swipe discovery.
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

    /// Launch arg slug: `Data-Presentation` (spaces → hyphens).
    private static func categoryArg(_ categoryName: String) -> String {
        categoryName.replacingOccurrences(of: " ", with: "-")
    }

    private static func sectionMarkerId(_ categoryName: String) -> String {
        "Layer1_Section_\(categoryName.replacingOccurrences(of: " ", with: ""))"
    }

    @MainActor
    private func launchLayer1Category(_ categoryName: String) {
        if let running = app, running.state != .notRunning {
            running.terminate()
        }
        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        localApp.launchArguments.append("-OpenLayer1Category=\(Self.categoryArg(categoryName))")
        localApp.launch()
        app = localApp
        XCTAssertEqual(localApp.state, .runningForeground, "Layer1 host should be foreground")
        let marker = Self.sectionMarkerId(categoryName)
        XCTAssertTrue(
            element(matchingIdentifier: marker).exists,
            "Layer1 section '\(marker)' should exist at launch (-OpenLayer1Category=\(Self.categoryArg(categoryName)))"
        )
    }

    @MainActor
    private func element(matchingIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", id)).firstMatch
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
        let byButton = app.buttons[title].firstMatch
        let byLabel = app.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
        let el: XCUIElement
        if byButton.exists {
            el = byButton
        } else if byLabel.exists {
            el = byLabel
        } else {
            XCTFail("\(elementName) with title '\(title)' should exist at category launch (no scroll)")
            return
        }
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
            let itemCollection = app.descendants(matching: .any).matching(identifier: "platformPresentItemCollection_L1")
            XCTAssertGreaterThan(itemCollection.count, 0, "Data Presentation should expose platformPresentItemCollection_L1")
            for i in 0..<min(itemCollection.count, 5) {
                let el = itemCollection.element(boundBy: i)
                if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentItemCollection_L1") }
            }
            let numericData = app.descendants(matching: .any).matching(identifier: "platformPresentNumericData_L1")
            for i in 0..<min(numericData.count, 3) {
                let el = numericData.element(boundBy: i)
                if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentNumericData_L1") }
            }
            let formData = app.descendants(matching: .any).matching(identifier: "platformPresentFormData_L1")
            for i in 0..<min(formData.count, 3) {
                let el = formData.element(boundBy: i)
                if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentFormData_L1") }
            }

        case "Navigation":
            let navStack = app.descendants(matching: .any).matching(identifier: "platformPresentNavigationStack_L1")
            XCTAssertGreaterThan(navStack.count, 0, "Navigation should expose platformPresentNavigationStack_L1")
            for i in 0..<min(navStack.count, 3) {
                let el = navStack.element(boundBy: i)
                if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentNavigationStack_L1") }
            }

        case "Photos":
            let photoCapture = app.descendants(matching: .any).matching(identifier: "platformPhotoCapture_L1")
            XCTAssertGreaterThan(photoCapture.count, 0, "Photos should expose platformPhotoCapture_L1")
            for i in 0..<min(photoCapture.count, 2) {
                let el = photoCapture.element(boundBy: i)
                if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPhotoCapture_L1") }
            }

        case "Security":
            let secureContent = app.descendants(matching: .any).matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "SixLayer.main.ui")
            )
            XCTAssertGreaterThan(
                secureContent.count,
                0,
                "Security examples should expose SixLayer automatic accessibility identifiers (#245)"
            )

        case "OCR":
            let ocrDisambiguation = app.descendants(matching: .any).matching(identifier: "platformOCRWithDisambiguation_L1")
            XCTAssertGreaterThan(ocrDisambiguation.count, 0, "OCR should expose platformOCRWithDisambiguation_L1")
            for i in 0..<min(ocrDisambiguation.count, 2) {
                let el = ocrDisambiguation.element(boundBy: i)
                if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformOCRWithDisambiguation_L1") }
            }

        case "Notifications":
            XCTAssertTrue(
                app.staticTexts["Notification Functions"].exists,
                "Notifications category should show the Notification Functions section"
            )
            let documentsNotificationAPIs = app.staticTexts
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "platformRequestNotificationPermission_L1"))
                .firstMatch
            XCTAssertTrue(
                documentsNotificationAPIs.exists,
                "Notifications category should surface documented Layer 1 notification API names in the UI"
            )

        case "Internationalization":
            let i18nSurfaces = app.descendants(matching: .any).matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "SixLayer.main.ui")
            )
            XCTAssertGreaterThan(
                i18nSurfaces.count,
                0,
                "Internationalization examples should expose SixLayer automatic accessibility identifiers (#245)"
            )

        case "Data Analysis":
            let analyze = app.descendants(matching: .any).matching(identifier: "platformAnalyzeDataFrame_L1")
            XCTAssertGreaterThan(analyze.count, 0, "Data Analysis should expose platformAnalyzeDataFrame_L1")
            for i in 0..<min(analyze.count, 2) {
                let el = analyze.element(boundBy: i)
                if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformAnalyzeDataFrame_L1") }
            }

        default:
            XCTFail("Unknown Layer1 category: \(category)")
        }
    }

    // MARK: - Per-category deep-link tests (#316)

    @MainActor
    func testLayer1_dataPresentation_accessibilitySurfaces() throws {
        launchLayer1Category("Data Presentation")
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

    // MARK: - Card components (Issue #191) — deep-link Data Presentation only

    @MainActor
    func testItemCollectionCards_ExposeSingleTappableElements() throws {
        launchLayer1Category("Data Presentation")
        for title in ["Item 1", "Item 2", "Item 3"] {
            assertSingleTappableCard(
                title: title,
                elementName: "platformPresentItemCollection_L1 card"
            )
        }
    }

    @MainActor
    func testResponsiveCard_ExposesSingleTappableElement() throws {
        launchLayer1Category("Data Presentation")
        assertSingleTappableCard(
            title: "Card Title",
            elementName: "platformResponsiveCard_L1 card"
        )
    }
}
