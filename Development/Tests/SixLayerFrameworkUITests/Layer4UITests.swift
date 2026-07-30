//
//  Layer4UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 4 (Component) UI tests: one test method per L4 component.
//  #316: deep-link via `-OpenLayer4Examples` + `-L4Section=…` (or overlay-only host).
//  No scroll-as-discovery; exact accessibilityIdentifier queries; `.exists` (fail-fast).
//  #372: reuse the app process when the deep-link launch-arg key matches the previous test
//  (XCTestCase is per-method — session is static). Relaunch only when the key changes.
//

import XCTest
@testable import SixLayerFramework

/// Layer 4 component tests: one test per L4 API. Contract = full contract (behavior, structure, a11y).
/// Deep-link launch args isolate hosts; process is reused across methods that share the same key (#372).
@MainActor
final class Layer4UITests: XCTestCase {
    nonisolated(unsafe) private var app: XCUIApplication!

    /// Per-process session (instances are per test method).
    nonisolated(unsafe) private static var sharedApp: XCUIApplication?
    nonisolated(unsafe) private static var sharedLaunchKey: String?

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()
        // No launch here — each test deep-links its section (#316); may reuse session (#372).
    }

    nonisolated override func tearDownWithError() throws {
        // Keep shared session alive for the next method with the same launch key (#372).
        app = nil
        try super.tearDownWithError()
    }

    override class func tearDown() {
        MainActor.assumeIsolated {
            if let running = sharedApp, running.state != .notRunning {
                running.terminate()
                _ = running.wait(for: .notRunning, timeout: 5)
            }
            sharedApp = nil
            sharedLaunchKey = nil
        }
        super.tearDown()
    }

    private static func l4ContractIdentifier(sanitizedName: String, elementType: String) -> String {
        "SixLayer.main.ui.\(sanitizedName).\(elementType)"
    }

    private static func l4SectionHeaderId(_ section: String) -> String {
        switch section {
        case "presentation": return "L4ContractSection_L4Presentation"
        case "navigation": return "L4ContractSection_L4Navigation"
        case "overlay": return "L4ContractSection_L4OverlayAccessibility"
        case "system": return "L4ContractSection_L4System"
        case "controls": return "L4ContractSection_L4Controls"
        case "form": return "L4ContractSection_L4Form"
        case "list": return "L4ContractSection_L4List"
        default:
            preconditionFailure("Unknown L4 section: \(section)")
        }
    }

    @MainActor
    private func launchL4Contract(section: String) {
        let key = "OpenLayer4Examples|L4Section=\(section)|noSkipAnimations"
        // Navigation tests push destinations and leave the section land off-screen — always
        // fresh launch for that section (single path; no try-reuse-then-relaunch ladder) (#370).
        let canReuse = section != "navigation"
            && Self.sharedApp?.state == .runningForeground
            && Self.sharedLaunchKey == key
        if canReuse, let existing = Self.sharedApp {
            app = existing
            let headerId = Self.l4SectionHeaderId(section)
            XCTAssertTrue(
                element(matchingIdentifier: headerId).waitForExistence(timeout: 8.0),
                "L4 section '\(headerId)' should still exist (reused launch, -L4Section=\(section))"
            )
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
        localApp.launchArguments.removeAll(where: { $0 == "-SkipAnimations" })
        localApp.launchArguments.append("-OpenLayer4Examples")
        localApp.launchArguments.append("-L4Section=\(section)")
        localApp.launch()
        app = localApp
        #if os(macOS)
        localApp.activate()
        #endif
        XCTAssertTrue(
            localApp.wait(for: .runningForeground, timeout: 8.0),
            "L4 contract host should be foreground after launch"
        )
        let headerId = Self.l4SectionHeaderId(section)
        XCTAssertTrue(
            element(matchingIdentifier: headerId).waitForExistence(timeout: 8.0),
            "L4 section '\(headerId)' should exist at launch (-L4Section=\(section))"
        )
        Self.sharedApp = localApp
        Self.sharedLaunchKey = key
    }

    @MainActor
    private func element(matchingIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", id)).firstMatch
    }

    @MainActor
    private func tapByNormalizedCenter(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    @MainActor
    private func launchOverlayAccessibilityHost() {
        let key = "OpenLayer4OverlayAccessibility|noSkipAnimations"
        if let existing = Self.sharedApp,
           existing.state == .runningForeground,
           Self.sharedLaunchKey == key {
            app = existing
            // Prior overlay tests may leave the sidebar open — reset to dismissed.
            let closeSidebar = element(matchingIdentifier: "L4OverlayCloseSidebar")
            if closeSidebar.exists {
                tapByNormalizedCenter(closeSidebar)
            }
            XCTAssertTrue(
                element(matchingIdentifier: "L4OverlayShowSidebar").waitForExistence(timeout: 8.0),
                "L4OverlayShowSidebar should exist (reused overlay host)"
            )
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
        localApp.launchArguments.removeAll(where: { $0 == "-SkipAnimations" })
        localApp.launchArguments.append("-OpenLayer4OverlayAccessibility")
        localApp.launch()
        app = localApp
        #if os(macOS)
        localApp.activate()
        #endif
        XCTAssertTrue(
            localApp.wait(for: .runningForeground, timeout: 8.0),
            "Overlay host should be foreground after launch"
        )
        XCTAssertTrue(
            element(matchingIdentifier: "L4OverlayShowSidebar").waitForExistence(timeout: 8.0),
            "L4OverlayShowSidebar should exist at launch (-OpenLayer4OverlayAccessibility)"
        )
        Self.sharedApp = localApp
        Self.sharedLaunchKey = key
    }

    @MainActor
    private func l4OverlayExpandSidebarElement() -> XCUIElement {
        element(matchingIdentifier: "L4OverlayShowSidebar")
    }

    @MainActor
    private func l4OverlayCloseSidebarElement() -> XCUIElement {
        element(matchingIdentifier: "L4OverlayCloseSidebar")
    }

    @MainActor
    private func assertContractControl(
        sanitizedIdentifierName: String,
        identifierElementType: String,
        componentName: String,
        expectedType: XCUIElement.ElementType? = nil
    ) {
        let identifier = Self.l4ContractIdentifier(
            sanitizedName: sanitizedIdentifierName,
            elementType: identifierElementType
        )
        let el = element(matchingIdentifier: identifier)
        XCTAssertTrue(el.exists, "\(componentName): exact id '\(identifier)' should exist")
        guard let expectedType else { return }
        let typeOK = el.elementType == expectedType
            || el.descendants(matching: expectedType).firstMatch.exists
            || (expectedType == .switch && (el.elementType == .checkBox
                || el.descendants(matching: .checkBox).firstMatch.exists))
        XCTAssertTrue(typeOK, "\(componentName) must present as \(expectedType). Found: \(el.elementType)")
    }

    @MainActor
    private func waitForIdentifier(_ id: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element(matchingIdentifier: id).exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return false
    }

    @MainActor
    private func waitForStaticTextInForeground(_ text: String, timeout: TimeInterval) -> Bool {
        // Host stamps exact accessibilityIdentifier matching the contract string (#351).
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element(matchingIdentifier: text).exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return false
    }

    @MainActor
    private func waitForL4SheetDismissControl(timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let close = element(matchingIdentifier: "L4SheetClose")
            if close.exists { return close }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return nil
    }

    @MainActor
    private func waitForDestinationContent(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element(matchingIdentifier: "L4NavDestinationContent").exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return false
    }

    @MainActor
    private func dismissStraySystemSheetIfNeeded() {
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.exists { cancel.tap() }
        let close = app.navigationBars.buttons["Close"].firstMatch
        if close.exists { close.tap() }
    }

    /// Fail with nearby identifier samples so the next xcresult failure text carries real a11y ids (#316).
    @MainActor
    private func assertExactIdentifierExists(
        _ id: String,
        message: String,
        nearbyHint: String
    ) {
        if element(matchingIdentifier: id).exists { return }
        let matches = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", nearbyHint))
        let limit = min(matches.count, 25)
        var samples: [String] = []
        for i in 0..<limit {
            let el = matches.element(boundBy: i)
            let value = el.identifier
            if !value.isEmpty { samples.append(value) }
        }
        // Also sample a few non-empty ids under the section header for context.
        let anyWithId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier != %@", ""))
        let anyLimit = min(anyWithId.count, 40)
        var allSamples: [String] = []
        for i in 0..<anyLimit {
            let value = anyWithId.element(boundBy: i).identifier
            if !value.isEmpty { allSamples.append(value) }
        }
        XCTFail(
            "\(message). Missing exact id '\(id)'. Nearby(\(nearbyHint)): \(samples). Sample ids: \(Array(allSamples.prefix(25)))"
        )
    }

    // MARK: - Controls

    @MainActor
    func testL4_platformButton() throws {
        launchL4Contract(section: "controls")
        assertContractControl(
            sanitizedIdentifierName: "l4contractbutton",
            identifierElementType: "Button",
            componentName: "platformButton",
            expectedType: .button
        )
    }

    @MainActor
    func testL4_platformTextField() throws {
        launchL4Contract(section: "controls")
        assertContractControl(
            sanitizedIdentifierName: "l4contracttextfield",
            identifierElementType: "TextField",
            componentName: "platformTextField",
            expectedType: .textField
        )
    }

    @MainActor
    func testL4_platformPicker() throws {
        launchL4Contract(section: "controls")
        // TestApp sets includeElementTypes=true → named picker without type hint gets `.View`.
        let pickerId = "SixLayer.main.ui.l4contractpicker.View"
        assertExactIdentifierExists(
            pickerId,
            message: "platformPicker: exact generated id should exist",
            nearbyHint: "picker"
        )
    }

    @MainActor
    func testL4_platformSecureField() throws {
        launchL4Contract(section: "controls")
        assertContractControl(
            sanitizedIdentifierName: "l4contractsecurefield",
            identifierElementType: "SecureField",
            componentName: "platformSecureField",
            expectedType: .secureTextField
        )
    }

    @MainActor
    func testL4_platformToggle() throws {
        launchL4Contract(section: "controls")
        assertContractControl(
            sanitizedIdentifierName: "l4contracttoggle",
            identifierElementType: "Toggle",
            componentName: "platformToggle",
            expectedType: .switch
        )
    }

    @MainActor
    func testL4_platformTextEditor() throws {
        launchL4Contract(section: "controls")
        assertContractControl(
            sanitizedIdentifierName: "l4contracttexteditor",
            identifierElementType: "TextEditor",
            componentName: "platformTextEditor",
            expectedType: .textView
        )
    }

    @MainActor
    func testL4_platformDatePicker() throws {
        launchL4Contract(section: "controls")
        XCTAssertTrue(
            app.staticTexts["L4ContractDatePicker"].exists
                || app.buttons["L4ContractDatePicker"].exists
                || element(matchingIdentifier: "L4ContractDatePicker").exists,
            "platformDatePicker: L4ContractDatePicker label must exist at controls launch"
        )
    }

    // MARK: - Form

    @MainActor
    func testL4_platformForm() throws {
        launchL4Contract(section: "form")
        XCTAssertTrue(element(matchingIdentifier: "L4ContractSection_L4Form").exists,
                      "platformForm: L4 Form section header should exist")
        XCTAssertTrue(element(matchingIdentifier: "L4FormSectionContract").exists,
                      "platformForm: form must contain section with header (contract structure)")
    }

    @MainActor
    func testL4_platformFormSection() throws {
        launchL4Contract(section: "form")
        XCTAssertTrue(element(matchingIdentifier: "L4FormSectionContract").exists,
                      "platformFormSection: section header must be visible (contract structure)")
    }

    @MainActor
    func testL4_platformFormField() throws {
        launchL4Contract(section: "form")
        XCTAssertTrue(
            app.staticTexts["L4FormFieldContract"].exists
                || element(matchingIdentifier: "L4FormFieldContract").exists,
            "platformFormField: label must exist (contract structure)"
        )
        XCTAssertTrue(app.staticTexts["Field content"].exists,
                      "platformFormField: content must exist (contract structure)")
    }

    @MainActor
    func testL4_platformFormFieldGroup() throws {
        launchL4Contract(section: "form")
        XCTAssertTrue(
            app.staticTexts["L4FormFieldGroupContract"].exists
                || element(matchingIdentifier: "L4FormFieldGroupContract").exists,
            "platformFormFieldGroup: title must exist (contract structure)"
        )
    }

    @MainActor
    func testL4_platformValidationMessage() throws {
        launchL4Contract(section: "form")
        XCTAssertTrue(app.staticTexts["L4ValidationMessageContract"].exists,
                      "platformValidationMessage: message text must be visible (contract structure)")
    }

    // MARK: - List

    @MainActor
    func testL4_platformListRow() throws {
        launchL4Contract(section: "list")
        // includeElementTypes=true → …platformListRow.<sanitized>.View
        let rowId = "SixLayer.main.ui.platformListRow.l4listrowcontract.View"
        assertExactIdentifierExists(
            rowId,
            message: "platformListRow: exact generated id must exist",
            nearbyHint: "platformListRow"
        )
    }

    @MainActor
    func testL4_platformListSectionHeader() throws {
        launchL4Contract(section: "list")
        let headerId = "SixLayer.main.ui.platformListSectionHeader.l4listsectionheadercontract.View"
        assertExactIdentifierExists(
            headerId,
            message: "platformListSectionHeader: exact generated id must exist",
            nearbyHint: "platformListSectionHeader"
        )
    }

    @MainActor
    func testL4_platformListEmptyState() throws {
        launchL4Contract(section: "list")
        let emptyId = "SixLayer.main.ui.platformListEmptyState.l4listemptystatecontract.View"
        assertExactIdentifierExists(
            emptyId,
            message: "platformListEmptyState: exact generated id must exist",
            nearbyHint: "platformListEmptyState"
        )
    }

    @MainActor
    func testL4_platformRowActions_L4() throws {
        launchL4Contract(section: "list")
        let rowId = "SixLayer.main.ui.platformListRow.l4rowactionscontractrow.View"
        assertExactIdentifierExists(
            rowId,
            message: "platformRowActions_L4: contract row generated id must exist",
            nearbyHint: "platformListRow"
        )
        assertExactIdentifierExists(
            "SixLayer.main.ui.platformRowActions_L4.View",
            message: "platformRowActions_L4: actions wrapper generated id must exist",
            nearbyHint: "platformRowActions"
        )
    }

    // MARK: - Presentation

    @MainActor
    func testL4_platformSheet_L4() throws {
        launchL4Contract(section: "presentation")
        let sheetButton = element(matchingIdentifier: "L4ContractSheet")
        XCTAssertTrue(sheetButton.exists, "Sheet button L4ContractSheet should exist")
        tapByNormalizedCenter(sheetButton)
        let closeControl = waitForL4SheetDismissControl(timeout: 2.5)
        XCTAssertNotNil(closeControl,
                        "platformSheet_L4: sheet host should expose dismiss control (contract structure)")
        guard let close = closeControl else { return }
        XCTAssertTrue(waitForStaticTextInForeground("L4SheetContentContract", timeout: 2.0),
                      "platformSheet_L4: sheet content must be visible when presented (contract behavior)")
        tapByNormalizedCenter(close)
    }

    @MainActor
    func testL4_platformPopover_L4() throws {
        launchL4Contract(section: "presentation")
        let popoverButton = element(matchingIdentifier: "L4ContractPopover")
        XCTAssertTrue(popoverButton.exists, "Popover button L4ContractPopover should exist")
        tapByNormalizedCenter(popoverButton)
        XCTAssertTrue(waitForStaticTextInForeground("L4PopoverContentContract", timeout: 2.5),
                      "platformPopover_L4: popover content must be visible when presented (contract behavior)")
    }

    // MARK: - Navigation

    @MainActor
    func testL4_platformNavigationTitle_L4() throws {
        launchL4Contract(section: "navigation")
        let navLink = element(matchingIdentifier: "L4NavLinkContract")
        XCTAssertTrue(navLink.exists, "Nav link L4NavLinkContract should exist")
        tapByNormalizedCenter(navLink)
        let deadline = Date().addingTimeInterval(2.0)
        var titleVisible = false
        while Date() < deadline {
            if app.navigationBars["L4NavTitleContract"].exists {
                titleVisible = true
                break
            }
            // macOS may expose the title as a static text rather than a nav-bar match.
            if app.staticTexts["L4NavTitleContract"].exists {
                titleVisible = true
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertTrue(titleVisible,
                      "platformNavigationTitle_L4: destination title L4NavTitleContract must appear")
        XCTAssertTrue(waitForDestinationContent(timeout: 2.0),
                      "platformNavigationTitle_L4: destination content should be visible")
    }

    @MainActor
    func testL4_platformNavigationLink_L4() throws {
        launchL4Contract(section: "navigation")
        let navLink = element(matchingIdentifier: "L4NavLinkContract")
        XCTAssertTrue(navLink.exists, "platformNavigationLink: L4NavLinkContract should exist")
        tapByNormalizedCenter(navLink)
        XCTAssertTrue(waitForDestinationContent(timeout: 2.0),
                      "platformNavigationLink_L4: navigating to destination should show content")
    }

    @MainActor
    func testL4_platformImplementNavigationStack_L4() throws {
        launchL4Contract(section: "navigation")
        // xcresult recording shows L4NavStackContractRoot on-screen at launch.
        XCTAssertTrue(
            element(matchingIdentifier: "L4NavStackContractRoot").exists
                || app.staticTexts["L4NavStackContractRoot"].exists,
            "platformImplementNavigationStack_L4: stack root content must be visible"
        )
        // Observed via failure dump in /tmp/316-l4-id-dump-*.xcresult (#316):
        // platformImplementNavigationStack_L4 titles stamp …l4navstackcontract.l4navstackcontract.Header
        let titleId = "SixLayer.main.ui.l4navstackcontract.l4navstackcontract.Header"
        assertExactIdentifierExists(
            titleId,
            message: "platformImplementNavigationStack_L4: inner navigation title should be exposed",
            nearbyHint: "l4navstackcontract"
        )
    }

    @MainActor
    func testL4_platformNavigationBarTitleDisplayMode_L4() throws {
        launchL4Contract(section: "presentation")
        XCTAssertTrue(
            app.navigationBars["Layer 4 Examples"].exists
                || element(matchingIdentifier: "L4ContractSheet").exists,
            "platformNavigationBarTitleDisplayMode_L4: root nav bar or L4 contract anchor should exist"
        )
    }

    // MARK: - Overlay accessibility

    @MainActor
    func testL4_overlayAccessibility_hidesUnderlyingContent_whenOverlayPresented() throws {
        launchOverlayAccessibilityHost()
        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.exists, "overlay contract: L4OverlayShowSidebar should exist")
        let detailAction = element(matchingIdentifier: "L4OverlayDetailAction")
        XCTAssertTrue(detailAction.exists, "overlay contract: L4OverlayDetailAction should exist before overlay opens")
        tapByNormalizedCenter(showSidebarButton)
        XCTAssertTrue(element(matchingIdentifier: "L4OverlaySidebarContent").exists,
                      "overlay contract: L4OverlaySidebarContent should be presented in overlay")
        XCTAssertFalse(detailAction.isHittable,
                       "overlay contract: underlying detail action should not be hittable while overlay is active")
    }

    @MainActor
    func testL4_overlayAccessibility_returnsFocusToExpandButton_onDismiss() throws {
        launchOverlayAccessibilityHost()
        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.exists, "overlay contract: L4OverlayShowSidebar should exist")
        tapByNormalizedCenter(showSidebarButton)
        XCTAssertTrue(element(matchingIdentifier: "L4OverlaySidebarContent").exists,
                      "overlay contract: L4OverlaySidebarContent should be presented in overlay")
        let closeSidebarButton = l4OverlayCloseSidebarElement()
        XCTAssertTrue(closeSidebarButton.exists, "overlay contract: L4OverlayCloseSidebar should exist in overlay")
        tapByNormalizedCenter(closeSidebarButton)
        XCTAssertTrue(showSidebarButton.exists, "overlay contract: expand affordance should remain available after dismiss")
        XCTAssertTrue(showSidebarButton.isHittable, "overlay contract: focus/interaction should return to expand affordance after dismiss")
    }

    @MainActor
    func testL4_overlayAccessibility_modalRootVisible_whenPresented() throws {
        launchOverlayAccessibilityHost()
        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.exists, "overlay contract: L4OverlayShowSidebar should exist")
        tapByNormalizedCenter(showSidebarButton)
        XCTAssertTrue(element(matchingIdentifier: "L4OverlayModalRoot").exists,
                      "overlay contract: L4OverlayModalRoot should be exposed for a11y navigation")
    }

    @MainActor
    func testL4_overlayAccessibility_closeAffordanceHasExplicitAccessibilityLabel() throws {
        launchOverlayAccessibilityHost()
        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.exists, "overlay contract: L4OverlayShowSidebar should exist")
        tapByNormalizedCenter(showSidebarButton)
        let closeSidebarElement = l4OverlayCloseSidebarElement()
        XCTAssertTrue(closeSidebarElement.exists, "overlay contract: L4OverlayCloseSidebar should be exposed")
        XCTAssertEqual(closeSidebarElement.label, "Close sidebar",
                       "overlay contract: close affordance should expose explicit accessibility label")
    }

    @MainActor
    func testL4_overlayAccessibility_sidebarContentHidden_afterDismiss() throws {
        launchOverlayAccessibilityHost()
        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.exists, "overlay contract: L4OverlayShowSidebar should exist")
        tapByNormalizedCenter(showSidebarButton)
        let modalRoot = element(matchingIdentifier: "L4OverlayModalRoot")
        XCTAssertTrue(modalRoot.exists, "overlay contract: L4OverlayModalRoot should be exposed while overlay is active")
        let sidebarContent = element(matchingIdentifier: "L4OverlaySidebarContent")
        XCTAssertTrue(sidebarContent.exists, "overlay contract: L4OverlaySidebarContent should be exposed while overlay is active")
        let closeSidebarButton = l4OverlayCloseSidebarElement()
        XCTAssertTrue(closeSidebarButton.exists, "overlay contract: L4OverlayCloseSidebar should exist")
        tapByNormalizedCenter(closeSidebarButton)
        XCTAssertFalse(modalRoot.exists, "overlay contract: modal root should be removed after dismiss")
        XCTAssertFalse(sidebarContent.exists, "overlay contract: sidebar content should not remain exposed after dismiss")
        XCTAssertTrue(showSidebarButton.isHittable, "overlay contract: expand affordance should be hittable after dismiss")
    }

    // MARK: - System

    @MainActor
    func testL4_platformCopyToClipboard_L4() throws {
        launchL4Contract(section: "system")
        let copyButton = element(matchingIdentifier: "L4ContractCopy")
        XCTAssertTrue(copyButton.exists, "platformCopyToClipboard_L4: L4ContractCopy should exist")
        tapByNormalizedCenter(copyButton)
    }

    @MainActor
    func testL4_platformPrint_L4() throws {
        launchL4Contract(section: "system")
        let printButton = element(matchingIdentifier: "L4ContractPrint")
        XCTAssertTrue(printButton.exists, "platformPrint_L4: L4ContractPrint should exist")
        tapByNormalizedCenter(printButton)
        dismissStraySystemSheetIfNeeded()
        XCTAssertTrue(element(matchingIdentifier: "L4ContractPrint").exists,
                      "platformPrint_L4: contract screen must be reachable after print")
    }

    @MainActor
    func testL4_platformExportActions_L4() throws {
        launchL4Contract(section: "system")
        let exportButton = element(matchingIdentifier: "L4ContractExportActions")
        XCTAssertTrue(exportButton.exists, "platformExportActions_L4: L4ContractExportActions should exist")
        tapByNormalizedCenter(exportButton)
        dismissStraySystemSheetIfNeeded()
        XCTAssertTrue(element(matchingIdentifier: "L4ContractExportActions").exists,
                      "platformExportActions_L4: contract screen must be reachable after export")
    }

    @MainActor
    func testL4_platformOpenURL_L4() throws {
        launchL4Contract(section: "system")
        let openButton = element(matchingIdentifier: "L4ContractOpenURL")
        XCTAssertTrue(openButton.exists, "platformOpenURL_L4: L4ContractOpenURL should exist")
        tapByNormalizedCenter(openButton)
        XCTAssertTrue(
            waitForStaticTextInForeground("L4ContractOpenURLResult:true", timeout: 2.5)
                || element(matchingIdentifier: "L4ContractOpenURLResult").exists,
            "platformOpenURL_L4: invocation should produce deterministic contract result"
        )
    }

    @MainActor
    func testL4_platformRegisterForRemoteNotifications_L4() throws {
        launchL4Contract(section: "system")
        let registerButton = element(matchingIdentifier: "L4ContractRegisterRemoteNotifications")
        XCTAssertTrue(registerButton.exists, "platformRegisterForRemoteNotifications_L4: button should exist")
        tapByNormalizedCenter(registerButton)
        XCTAssertTrue(
            waitForStaticTextInForeground("L4ContractRegisterRemoteNotificationsResult:true", timeout: 2.5)
                || element(matchingIdentifier: "L4ContractRegisterRemoteNotificationsResult").exists,
            "platformRegisterForRemoteNotifications_L4: invocation should produce deterministic contract result"
        )
    }

    @MainActor
    func testL4_platformCloudKitSyncStatus_L4() throws {
        launchL4Contract(section: "system")
        let exactId = element(matchingIdentifier: "platformCloudKitSyncStatus_L4")
        XCTAssertTrue(exactId.exists, "platformCloudKitSyncStatus_L4: contract view must expose stable a11y identifier")
    }

    @MainActor
    func testL4_platformCloudKitProgress_L4() throws {
        launchL4Contract(section: "system")
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitProgress_L4"))
            .firstMatch
        XCTAssertTrue(containsId.exists, "platformCloudKitProgress_L4: view must expose contract a11y identifier")
    }

    @MainActor
    func testL4_platformCloudKitAccountStatus_L4() throws {
        launchL4Contract(section: "system")
        // Framework may prefix; one CONTAINS query — not exact||CONTAINS ladder (#351).
        let el = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitAccountStatus_L4"))
            .firstMatch
        XCTAssertTrue(el.exists, "platformCloudKitAccountStatus_L4: view must expose contract a11y identifier")
    }

    @MainActor
    func testL4_platformCloudKitServiceStatus_L4() throws {
        launchL4Contract(section: "system")
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitServiceStatus_L4"))
            .firstMatch
        XCTAssertTrue(containsId.exists, "platformCloudKitServiceStatus_L4: composite view must expose contract a11y identifier")
    }

    @MainActor
    func testL4_platformCloudKitSyncButton_L4() throws {
        launchL4Contract(section: "system")
        let el = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitSyncButton_L4"))
            .firstMatch
        XCTAssertTrue(el.exists, "platformCloudKitSyncButton_L4: button must expose contract a11y identifier")
    }

    @MainActor
    func testL4_platformCloudKitStatusBadge_L4() throws {
        launchL4Contract(section: "system")
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitStatusBadge_L4"))
            .firstMatch
        XCTAssertTrue(containsId.exists, "platformCloudKitStatusBadge_L4: badge must expose contract a11y identifier")
    }

    #if os(iOS)
    @MainActor
    func testL4_platformPhotoPicker_L4() throws {
        launchL4Contract(section: "system")
        // Host mounts under -UITesting without requiring Button/@State (iOS 26 Form; #368).
        assertExactIdentifierExists(
            "platformPhotoPicker_L4",
            message: "platformPhotoPicker_L4: picker subtree must expose contract a11y identifier",
            nearbyHint: "photoPicker"
        )
        XCTAssertTrue(element(matchingIdentifier: "L4ContractPhotoPickerOpen").exists,
                      "platformPhotoPicker_L4: L4ContractPhotoPickerOpen must remain available")
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.exists { cancel.tap() }
        XCTAssertTrue(element(matchingIdentifier: "L4ContractPhotoPickerOpen").exists,
                      "platformPhotoPicker_L4: must return to contract root after dismiss")
    }
    #endif

    @MainActor
    func testL4_platformPhotoDisplay_L4() throws {
        launchL4Contract(section: "system")
        let photoView = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformPhotoDisplay"))
            .firstMatch
        XCTAssertTrue(photoView.exists, "platformPhotoDisplay_L4: view must have a11y identifier (contract a11y)")
    }
}
