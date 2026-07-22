//
//  Layer1AccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for Layer 1 platform*_L1 function accessibility
//  Implements Issue #166: Complete accessibility for Layer 1 platform* methods
//
//  #316: deep-link via `-OpenLayer1Category=…` + optional `-L1Section=…` —
//  no UI Test Views home, no swipe discovery, no OR-fallback query chains.
//  #372: reuse the app process when category/section launch-arg key matches.
//

import XCTest
@testable import SixLayerFramework

/// XCUITest tests for Layer 1 accessibility features.
@MainActor
final class Layer1AccessibilityUITests: XCTestCase {
    nonisolated(unsafe) private var app: XCUIApplication!

    nonisolated(unsafe) private static var sharedApp: XCUIApplication?
    nonisolated(unsafe) private static var sharedLaunchKey: String?

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()
        // No launch — each test deep-links its category (#316); may reuse session (#372).
    }

    nonisolated override func tearDownWithError() throws {
        // Keep shared session alive for the next method with the same launch key (#372).
        app = nil
        try super.tearDownWithError()
    }

    override class func tearDown() {
        if let running = sharedApp, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        sharedApp = nil
        sharedLaunchKey = nil
        super.tearDown()
    }

    private static func categoryArg(_ categoryName: String) -> String {
        categoryName.replacingOccurrences(of: " ", with: "-")
    }

    @MainActor
    private func launchLayer1Category(_ categoryName: String, section: String? = nil) {
        let categoryKey = Self.categoryArg(categoryName)
        let key: String
        if let section {
            key = "OpenLayer1Category=\(categoryKey)|L1Section=\(section)"
        } else {
            key = "OpenLayer1Category=\(categoryKey)"
        }

        if let existing = Self.sharedApp,
           existing.state == .runningForeground,
           Self.sharedLaunchKey == key {
            app = existing
            if let section {
                assertSectionMarker(section, categoryName: categoryName, reused: true)
            } else {
                assertCategoryMarker(categoryName, reused: true)
            }
            return
        }

        if let running = Self.sharedApp, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        Self.sharedApp = nil
        Self.sharedLaunchKey = nil

        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        localApp.launchArguments.append("-OpenLayer1Category=\(categoryKey)")
        if let section {
            localApp.launchArguments.append("-L1Section=\(section)")
        }
        localApp.launch()
        Self.sharedApp = localApp
        Self.sharedLaunchKey = key
        app = localApp
        XCTAssertEqual(localApp.state, .runningForeground, "Layer1 host should be foreground")

        if let section {
            assertSectionMarker(section, categoryName: categoryName, reused: false)
        } else {
            assertCategoryMarker(categoryName, reused: false)
        }
    }

    @MainActor
    private func assertSectionMarker(_ section: String, categoryName: String, reused: Bool) {
        let marker: String
        switch section {
        case "items": marker = "L1_Section_Items"
        case "emptyItems": marker = "L1_Section_EmptyItems"
        case "emptyWrap1": marker = "L1_Section_EmptyWrap1"
        case "emptyWrapExact1": marker = "L1_Section_EmptyWrapExact1"
        case "emptyWrap2": marker = "L1_Section_EmptyWrap2"
        case "emptyWrap3": marker = "L1_Section_EmptyWrap3"
        case "emptyWrap4": marker = "L1_Section_EmptyWrap4"
        case "responsiveCard": marker = "L1_Section_ResponsiveCard"
        case "navStack": marker = "L1_Section_NavStack"
        case "appNav": marker = "L1_Section_AppNav"
        default: marker = "L1_Section_\(section)"
        }
        let el = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", marker))
            .firstMatch
        let reuseNote = reused ? " (reused launch)" : ""
        XCTAssertTrue(
            el.waitForExistence(timeout: reused ? 0.5 : 2),
            "Layer1 section marker '\(marker)' should exist\(reuseNote) (-OpenLayer1Category=\(Self.categoryArg(categoryName)) -L1Section=\(section))"
        )
    }

    @MainActor
    private func assertCategoryMarker(_ categoryName: String, reused: Bool) {
        let categoryMarker = "L1_Category_\(Self.categoryArg(categoryName))"
        let markerEl = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", categoryMarker))
            .firstMatch
        let timeout: TimeInterval = reused ? 0.5 : 2
        if markerEl.waitForExistence(timeout: timeout) { return }
        let anyWithId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier != %@", ""))
        let sampleLimit = min(anyWithId.count, 30)
        var samples: [String] = []
        for i in 0..<sampleLimit {
            let value = anyWithId.element(boundBy: i).identifier
            if !value.isEmpty { samples.append(value) }
        }
        let reuseNote = reused ? " (reused launch)" : ""
        XCTFail(
            "Layer1 category marker '\(categoryMarker)' should exist\(reuseNote) (-OpenLayer1Category=\(Self.categoryArg(categoryName))). Sample ids: \(samples)"
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
        if el.exists { return }
        let matches = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", identifier))
        let nearbyLimit = min(matches.count, 15)
        var nearby: [String] = []
        for i in 0..<nearbyLimit {
            let value = matches.element(boundBy: i).identifier
            if !value.isEmpty { nearby.append(value) }
        }
        let anyWithId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier != %@", ""))
        let sampleLimit = min(anyWithId.count, 25)
        var samples: [String] = []
        for i in 0..<sampleLimit {
            let value = anyWithId.element(boundBy: i).identifier
            if !value.isEmpty { samples.append(value) }
        }
        XCTFail("\(context): missing exact id '\(identifier)'. Nearby: \(nearby). Sample ids: \(samples)")
    }

    @MainActor
    private func assertIdentifierContains(_ substring: String, context: String) {
        let el = element(identifierContains: substring)
        if el.exists { return }
        let anyWithId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier != %@", ""))
        let sampleLimit = min(anyWithId.count, 30)
        var samples: [String] = []
        for i in 0..<sampleLimit {
            let value = anyWithId.element(boundBy: i).identifier
            if !value.isEmpty { samples.append(value) }
        }
        XCTFail("\(context): missing identifier CONTAINS '\(substring)'. Sample ids: \(samples)")
    }

    /// Single-tappable card contract without scroll-as-discovery (#316).
    /// macOS XCUI often surfaces list-card labels as `"Item 1."` (trailing period); match with BEGINSWITH.
    @MainActor
    private func assertSingleTappableCard(title: String, elementName: String) {
        let el = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", title))
            .firstMatch
        if el.exists {
            el.verifyAccessibilityContract(
                elementName: elementName,
                expectedType: .button,
                requireLabel: true
            )
            return
        }
        let allButtons = app.buttons
        let buttonLimit = min(allButtons.count, 20)
        var buttonSamples: [String] = []
        for i in 0..<buttonLimit {
            let b = allButtons.element(boundBy: i)
            buttonSamples.append("label=\(b.label) id=\(b.identifier)")
        }
        XCTFail(
            "\(elementName) with title BEGINSWITH '\(title)' should exist at section launch (no scroll). buttons: \(buttonSamples)"
        )
    }

    @MainActor
    private func assertCategorySurfaces(_ category: String) {
        switch category {
        case "Data Presentation":
            assertExactIdentifierExists("L1_Section_Items", context: "Data Presentation items section")
            assertIdentifierContains("platformPresentItemCollection_L1", context: "Data Presentation item collection")

        case "Navigation":
            assertIdentifierContains("platformPresentNavigationStack_L1", context: "Navigation stack")

        case "Photos":
            assertIdentifierContains("platformPhotoCapture_L1", context: "Photo capture")

        case "Security":
            assertIdentifierContains("SixLayer.main.ui", context: "Security examples")

        case "OCR":
            assertIdentifierContains("platformOCRWithDisambiguation_L1", context: "OCR")

        case "Notifications":
            assertExactIdentifierExists(
                "L1_NotificationAPI_platformRequestNotificationPermission_L1",
                context: "Notifications API surface"
            )

        case "Internationalization":
            assertIdentifierContains("SixLayer.main.ui", context: "Internationalization examples")

        case "Data Analysis":
            assertIdentifierContains("platformAnalyzeDataFrame_L1", context: "Data Analysis")

        case "Barcode":
            assertExactIdentifierExists("L1_Section_BarcodeScanning", context: "Barcode scanning section")
            assertExactIdentifierExists("L1_Barcode_NoTestImage", context: "Barcode host without auto Vision scan")

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
        launchLayer1Category("Navigation", section: "navStack")
        assertExactIdentifierExists("L1_Section_NavStack", context: "Navigation stack host")
        assertIdentifierContains("platformPresentNavigationStack_L1", context: "Navigation stack")
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

    @MainActor
    func testLayer1_barcode_accessibilitySurfaces() throws {
        // Thin land only — do not mount platformScanBarcode_L1 (.task Vision hang). Refs #369.
        launchLayer1Category("Barcode")
        assertCategorySurfaces("Barcode")
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

    // MARK: - Empty collection hint a11y ids (#359)

    /// Presentation-hint empty-state identifiers must remain queryable under
    /// `platformPresentItemCollection_L1` (not collapsed into the collection surface id).
    /// Ids must match `EmptyItemCollectionHintIdentifierExamples` in the TestApp harness.
    @MainActor
    func testEmptyItemCollection_hintAccessibilityIdentifiersRemainQueryable() throws {
        launchLayer1Category("Data Presentation", section: "emptyItems")
        assertExactIdentifierExists("L1_Section_EmptyItems", context: "Empty item collection host")
        assertExactIdentifierExists(
            "SixLayer.uitest.collectionEmpty.EmptyStateTitle",
            context: "emptyStateTitleAccessibilityIdentifier"
        )
        assertExactIdentifierExists(
            "SixLayer.uitest.collectionEmpty.EmptyStateCreateButton",
            context: "createButtonAccessibilityIdentifier"
        )
    }

    // MARK: - Empty-state destination wrapper bisect (#360 / CarManager #757)

    /// Asserts hint empty-state ids after launching a wrapper-ladder section.
    /// Ids must match `EmptyStateWrapperBisectIDs` in the TestApp harness.
    @MainActor
    private func assertEmptyStateHintIdsQueryable(section: String, sectionMarker: String) {
        launchLayer1Category("Data Presentation", section: section)
        assertExactIdentifierExists(sectionMarker, context: "\(section) host")
        assertExactIdentifierExists(
            "SixLayer.uitest.collectionEmpty.EmptyStateTitle",
            context: "\(section) emptyStateTitleAccessibilityIdentifier"
        )
        assertExactIdentifierExists(
            "SixLayer.uitest.collectionEmpty.EmptyStateCreateButton",
            context: "\(section) createButtonAccessibilityIdentifier"
        )
    }

    @MainActor
    func testEmptyStateWrapperBisect_step1_named_hintIdsRemainQueryable() throws {
        assertEmptyStateHintIdsQueryable(section: "emptyWrap1", sectionMarker: "L1_Section_EmptyWrap1")
    }

    /// Mirror of emptyWrap1 with `.exactNamed` on the collection container (#364).
    /// Nested EmptyState* hint ids must remain queryable (host-sentinel parity with `.named`).
    @MainActor
    func testEmptyStateWrapperBisect_exactNamed_hintIdsRemainQueryable() throws {
        assertEmptyStateHintIdsQueryable(section: "emptyWrapExact1", sectionMarker: "L1_Section_EmptyWrapExact1")
    }

    @MainActor
    func testEmptyStateWrapperBisect_step2_namedPlusNavTitle_hintIdsRemainQueryable() throws {
        assertEmptyStateHintIdsQueryable(section: "emptyWrap2", sectionMarker: "L1_Section_EmptyWrap2")
    }

    @MainActor
    func testEmptyStateWrapperBisect_step3_outerScrollHost_hintIdsRemainQueryable() throws {
        assertEmptyStateHintIdsQueryable(section: "emptyWrap3", sectionMarker: "L1_Section_EmptyWrap3")
    }

    @MainActor
    func testEmptyStateWrapperBisect_step4_outerContain_hintIdsRemainQueryable() throws {
        assertEmptyStateHintIdsQueryable(section: "emptyWrap4", sectionMarker: "L1_Section_EmptyWrap4")
    }
}
