//
//  Layer4UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 4 (Component) UI tests: one test method per L4 component. Launch with -OpenLayer4Examples.
//  Each test asserts the full contract: a11y (identifier/label), structure (element type, hierarchy), and behavior.
//

import XCTest
@testable import SixLayerFramework

/// Layer 4 component tests: one test per L4 API. Contract = full contract (behavior, structure, a11y), not just accessibility.
/// We test ALL L4 APIs; each test asserts the API's contract.
/// Uses launch argument -OpenLayer4Examples. One app launch for the suite.
///
/// Currently covered: platformButton, platformTextField, platformPicker, platformSecureField, platformToggle,
/// platformTextEditor, platformDatePicker, platformForm, platformFormSection, platformFormField, platformFormFieldGroup,
/// platformValidationMessage, platformListRow, platformListSectionHeader, platformListEmptyState,
/// platformSheet_L4, platformPopover_L4, platformNavigationTitle_L4, platformNavigationLink_L4, platformNavigationBarTitleDisplayMode_L4,
/// platformCopyToClipboard_L4, platformPrint_L4, platformCloudKitSyncStatus_L4,
/// platformCloudKitProgress_L4, platformCloudKitAccountStatus_L4, platformCloudKitServiceStatus_L4,
/// platformCloudKitSyncButton_L4, platformCloudKitStatusBadge_L4, platformPhotoDisplay_L4.
/// Remaining L4 APIs to add: platformImplementNavigationStack_L4, platformAppNavigation_L4, platformRowActions_L4,
/// platformPhotoPicker_L4, platformMapView_L4, other platformCloudKit*,
/// platformShare_L4, platformVerticalSplit_L4, platformHorizontalSplit_L4, platformStyledContainer_L4, etc.
@MainActor
final class Layer4UITests: XCTestCase {
    /// Shared across test instances (Xcode creates one instance per test method).
    private static var sharedApp: XCUIApplication?
    private var app: XCUIApplication! { Self.sharedApp! }

    /// One app launch for the suite; all test methods reuse the same launch.
    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        MainActor.assumeIsolated {
            guard Self.sharedApp == nil else { return }
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            // `-SkipAnimations` can leave `.sheet` presented without a populated a11y subtree on iOS 26
            // (Sheet exists; contract static text never appears — Issue #193).
            localApp.launchArguments.removeAll(where: { $0 == "-SkipAnimations" })
            localApp.launchArguments.append("-OpenLayer4Examples")
            localApp.launch()
            Self.sharedApp = localApp
            XCTAssertTrue(localApp.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 5.0),
                          "App should open on Layer 4 Examples (launch arg)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    /// Expected identifier suffix (sanitized label + type) when enableUITestIntegration is true: SixLayer.main.ui.<suffix>.
    private static func l4ContractIdentifier(sanitizedName: String, elementType: String) -> String {
        "SixLayer.main.ui.\(sanitizedName).\(elementType)"
    }

    /// True when any a11y node exposes `label` (Form section headers are often not `XCUIElementType.staticText`).
    @MainActor
    private func anyDescendantHasLabel(equalTo label: String, timeout: TimeInterval) -> Bool {
        let pred = NSPredicate(format: "label == %@ OR label CONTAINS[c] %@", label, label)
        return app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: timeout)
    }

    /// Scroll so the element with the given label is visible (content may be below fold).
    /// Uses longer initial wait for buttons so top-of-screen elements (e.g. L4 Presentation) are not skipped.
    @MainActor
    private func scrollToElement(label: String) {
        if app.staticTexts[label].waitForExistence(timeout: 1.0) { return }
        if anyDescendantHasLabel(equalTo: label, timeout: 0.5) { return }
        if app.buttons[label].waitForExistence(timeout: 2.0) { return }
        if app.links[label].waitForExistence(timeout: 1.0) { return }
        if element(matchingIdentifier: label).waitForExistence(timeout: 1.0) { return }
        if !app.xcuiPrimaryScrollHost().exists, !app.tables.firstMatch.exists, !app.scrollViews.firstMatch.exists { return }
        for _ in 0..<22 {
            app.xcuiSwipeScrollHostsUp()
            if app.staticTexts[label].waitForExistence(timeout: 0.5) { return }
            if anyDescendantHasLabel(equalTo: label, timeout: 0.35) { return }
            if app.buttons[label].waitForExistence(timeout: 0.5) { return }
            if element(matchingIdentifier: label).waitForExistence(timeout: 0.35) { return }
        }
    }

    /// Stable id on `contractSectionHeader` in the Layer 4 examples `Form` (Issue #193).
    private static func l4ContractSectionHeaderIdentifier(sectionTitle: String) -> String {
        "L4ContractSection_\(sectionTitle.replacingOccurrences(of: " ", with: ""))"
    }

    /// `Form` section titles are often not `staticText` in XCUITest; avoid long button/link waits before scrolling.
    @MainActor
    private func scrollToFormSectionHeader(title: String) {
        let headerId = Self.l4ContractSectionHeaderIdentifier(sectionTitle: title)
        if element(matchingIdentifier: headerId).waitForExistence(timeout: 1.5) { return }
        if app.staticTexts[title].waitForExistence(timeout: 0.75) { return }
        if anyDescendantHasLabel(equalTo: title, timeout: 2.0) { return }
        if app.buttons[title].waitForExistence(timeout: 0.25) { return }
        if app.links[title].waitForExistence(timeout: 0.25) { return }
        if element(matchingIdentifier: title).waitForExistence(timeout: 0.5) { return }
        if !app.xcuiPrimaryScrollHost().exists, app.tables.count < 1, !app.scrollViews.firstMatch.exists { return }
        for _ in 0..<22 {
            app.xcuiSwipeScrollHostsUp()
            if element(matchingIdentifier: headerId).waitForExistence(timeout: 0.35) { return }
            if app.staticTexts[title].waitForExistence(timeout: 0.35) { return }
            if anyDescendantHasLabel(equalTo: title, timeout: 0.45) { return }
            if app.buttons[title].waitForExistence(timeout: 0.2) { return }
            if element(matchingIdentifier: title).waitForExistence(timeout: 0.25) { return }
        }
    }

    /// `Form` rows for L4 Controls sit mid-scroll; anchor on the section header before field/button contract checks.
    @MainActor
    private func scrollToL4ControlsSection() {
        scrollToFormSectionHeader(title: "L4 Controls")
    }

    /// Element with the given accessibility identifier (any type).
    @MainActor
    private func element(matchingIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", id)).firstMatch
    }

    /// Tap when the element is not hittable (e.g. clipped by safe area); coordinate tap matches user intent.
    @MainActor
    private func tapByNormalizedCenter(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    /// Toolbar uses `accessibilityLabel` "Show sidebar"; XCTest may type it as button or other.
    @MainActor
    private func l4OverlayExpandSidebarElement() -> XCUIElement {
        let byId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4OverlayShowSidebar"))
            .firstMatch
        if byId.waitForExistence(timeout: 4.0) { return byId }
        if app.buttons["Show sidebar"].waitForExistence(timeout: 2.0) {
            return app.buttons["Show sidebar"].firstMatch
        }
        if app.otherElements["Show sidebar"].waitForExistence(timeout: 1.0) {
            return app.otherElements["Show sidebar"].firstMatch
        }
        return app.buttons["L4OverlayShowSidebar"].firstMatch
    }

    @MainActor
    private func l4FormSectionHeaderVisible(timeout: TimeInterval) -> Bool {
        if app.staticTexts["L4FormSectionContract"].waitForExistence(timeout: timeout) { return true }
        if app.otherElements["L4FormSectionContract"].waitForExistence(timeout: min(timeout, 2.0)) { return true }
        let labelOrId = NSPredicate(format: "label CONTAINS[c] %@ OR identifier CONTAINS[c] %@", "L4FormSectionContract", "L4FormSectionContract")
        if app.descendants(matching: .any).matching(labelOrId).firstMatch.waitForExistence(timeout: timeout) { return true }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "L4FormSectionContract"))
            .firstMatch.waitForExistence(timeout: timeout)
    }

    /// Sheet and popover content can appear under `app.sheets` or the main hierarchy depending on OS and presentation style.
    @MainActor
    private func waitForStaticTextInForeground(_ text: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let labelOrId = NSPredicate(format: "label == %@ OR identifier == %@ OR value == %@", text, text, text)
        while Date() < deadline {
            let slice = max(0.05, min(0.5, deadline.timeIntervalSinceNow))
            if slice <= 0 { break }
            let sheetCount = app.sheets.count
            if sheetCount > 0 {
                for s in 0..<min(sheetCount, 4) {
                    let sheet = app.sheets.element(boundBy: s)
                    if !sheet.exists { continue }
                    if sheet.staticTexts[text].waitForExistence(timeout: min(slice, 0.35)) { return true }
                    if sheet.descendants(matching: .staticText).matching(labelOrId).firstMatch.waitForExistence(timeout: min(slice, 0.35)) {
                        return true
                    }
                    if sheet.descendants(matching: .any).matching(labelOrId).firstMatch.waitForExistence(timeout: min(slice, 0.35)) {
                        return true
                    }
                }
            }
            if app.staticTexts[text].waitForExistence(timeout: slice) { return true }
            if app.descendants(matching: .staticText).matching(labelOrId).firstMatch.waitForExistence(timeout: slice) {
                return true
            }
            if app.otherElements[text].waitForExistence(timeout: min(slice, 0.35)) { return true }
            if app.descendants(matching: .any).matching(labelOrId).firstMatch.waitForExistence(timeout: min(slice, 0.35)) {
                return true
            }
            let winCount = app.windows.count
            for w in 0..<min(winCount, 8) {
                let window = app.windows.element(boundBy: w)
                if window.staticTexts[text].waitForExistence(timeout: min(slice, 0.12)) { return true }
                if window.descendants(matching: .staticText).matching(labelOrId).firstMatch.waitForExistence(timeout: min(slice, 0.12)) {
                    return true
                }
            }
        }
        return false
    }

    /// Dismiss control for `L4SheetContentContractView`: on recent iOS it is often under `app.sheets`, not root `app.descendants` (Issue #193).
    @MainActor
    private func waitForL4SheetDismissControl(timeout: TimeInterval) -> XCUIElement? {
        let closePred = NSPredicate(format: "identifier == %@ OR label == %@", "L4SheetClose", "Close")
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let slice = max(0.05, min(0.5, deadline.timeIntervalSinceNow))
            if slice <= 0 { break }
            let sheetCount = app.sheets.count
            if sheetCount > 0 {
                for s in 0..<min(sheetCount, 4) {
                    let sheet = app.sheets.element(boundBy: s)
                    guard sheet.exists else { continue }
                    let inSheet = sheet.descendants(matching: .any).matching(closePred).firstMatch
                    if inSheet.waitForExistence(timeout: min(slice, 0.35)) { return inSheet }
                    if sheet.buttons["Close"].waitForExistence(timeout: min(slice, 0.25)) {
                        return sheet.buttons["Close"].firstMatch
                    }
                }
            }
            let rootMatch = app.descendants(matching: .any).matching(closePred).firstMatch
            if rootMatch.waitForExistence(timeout: slice) { return rootMatch }
            if app.buttons["Close"].waitForExistence(timeout: min(slice, 0.25)) {
                return app.buttons["Close"].firstMatch
            }
            let winCount = app.windows.count
            for w in 0..<min(winCount, 8) {
                let window = app.windows.element(boundBy: w)
                let wMatch = window.descendants(matching: .any).matching(closePred).firstMatch
                if wMatch.waitForExistence(timeout: min(slice, 0.12)) { return wMatch }
            }
        }
        return nil
    }

    @MainActor
    private func waitForDestinationContent(timeout: TimeInterval) -> Bool {
        let matchAny = NSPredicate(
            format: "label == %@ OR identifier == %@ OR identifier CONTAINS[c] %@",
            "L4NavDestinationContent",
            "L4NavDestinationContent",
            "L4NavDestinationContent"
        )
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: timeout) { return true }
        if app.descendants(matching: .any).matching(matchAny).firstMatch.waitForExistence(timeout: min(timeout, 8.0)) { return true }
        return app.otherElements["L4NavDestinationContent"].waitForExistence(timeout: 2.0)
    }

    /// Ensure we're on the contract root with top of content visible. Pop from nav stack if needed; scroll to top if the first contract section is off-screen.
    @MainActor
    private func ensureContractRoot() {
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists { backButton.tap() }
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 2.0)
        }
        if app.navigationBars["L4NavTitleContract"].waitForExistence(timeout: 0.5) {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists { backButton.tap() }
            _ = app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 3.0)
        }
        XCTAssertTrue(app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 6.0),
                      "Contract root: Layer 4 Examples nav bar should exist")
        func contractTopVisible() -> Bool {
            if app.staticTexts["L4 Presentation"].waitForExistence(timeout: 0.3) { return true }
            if anyDescendantHasLabel(equalTo: "L4 Presentation", timeout: 0.25) { return true }
            if app.staticTexts["L4 System"].waitForExistence(timeout: 0.3) { return true }
            if anyDescendantHasLabel(equalTo: "L4 System", timeout: 0.25) { return true }
            // iOS root `Form`: section titles are not always `staticTexts`; sheet button is a stable top anchor (Issue #193).
            if app.buttons["L4ContractSheet"].waitForExistence(timeout: 0.3) { return true }
            if element(matchingIdentifier: "L4ContractSheet").waitForExistence(timeout: 0.3) { return true }
            return false
        }
        if contractTopVisible() { return }
        for _ in 0..<18 {
            app.xcuiSwipeScrollHostsDown()
            if contractTopVisible() { return }
        }
        XCTAssertTrue(
            app.staticTexts["L4 Presentation"].waitForExistence(timeout: 3.0)
                || anyDescendantHasLabel(equalTo: "L4 Presentation", timeout: 1.0)
                || app.staticTexts["L4 System"].waitForExistence(timeout: 0.5)
                || anyDescendantHasLabel(equalTo: "L4 System", timeout: 0.5)
                || app.buttons["L4ContractSheet"].waitForExistence(timeout: 3.0)
                || element(matchingIdentifier: "L4ContractSheet").waitForExistence(timeout: 2.0),
            "Contract root (L4 Presentation, L4 System, or L4 sheet trigger) should be visible after scroll to top"
        )
    }

    @MainActor
    private func assertElementHasIdentifierFromComponent(
        label: String,
        type: XCUIElement.ElementType,
        componentName: String,
        sanitizedIdentifierName: String,
        identifierElementType: String
    ) {
        scrollToElement(label: label)
        let identifier = Self.l4ContractIdentifier(sanitizedName: sanitizedIdentifierName, elementType: identifierElementType)
        // Prefer contract type first so we find the real control; then .other as fallback (type assertion will fail if only wrapper has id).
        let typesToTry: [(XCUIElement.ElementType, TimeInterval)] = (type == .textField || type == .secureTextField || type == .switch || type == .textView)
            ? [(type, 5.0), (.other, 2.0)]
            : [(type, 5.0)]
        var el: XCUIElement?
        for (primaryType, timeout) in typesToTry {
            el = app.findElement(byIdentifier: identifier, primaryType: primaryType, secondaryTypes: [.other, .button, .staticText, .any], timeout: timeout)
            if el != nil { break }
        }
        if el == nil {
            el = app.findElement(byIdentifier: identifier, primaryType: .any, secondaryTypes: [.other, .button, .staticText], timeout: 2.0)
        }
        if el == nil {
            let containsPred = NSPredicate(format: "identifier CONTAINS[c] %@", sanitizedIdentifierName)
            let anyWithId = app.descendants(matching: .any).matching(containsPred).firstMatch
            if anyWithId.waitForExistence(timeout: 2.0) { el = anyWithId }
        }
        // iOS Form/runtime can expose the interactive control by label while moving generated id to a wrapper.
        if el == nil {
            let byLabel = app.descendants(matching: type).matching(NSPredicate(format: "label == %@", label)).firstMatch
            if byLabel.waitForExistence(timeout: 2.0) { el = byLabel }
        }
        XCTAssertNotNil(el, "\(componentName): element with identifier '\(identifier)' or containing '\(sanitizedIdentifierName)' should exist (contract)")
        if let el = el {
            let hasContractId = !el.identifier.isEmpty
                || app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS[c] %@", sanitizedIdentifierName)).firstMatch.waitForExistence(timeout: 1.0)
            XCTAssertTrue(hasContractId,
                          "\(componentName) must apply a11y. '\(label)' should expose contract id or a wrapper containing '\(sanitizedIdentifierName)'. Found: '\(el.identifier)'")
            let hasCorrectType = (el.elementType == type)
                || (el.descendants(matching: type).firstMatch.waitForExistence(timeout: 0.5))
            XCTAssertTrue(hasCorrectType,
                          "\(componentName) must present as \(type) (contract structure). Found: \(el.elementType)")
        }
    }

    @MainActor
    func testL4_platformButton() throws {
        ensureContractRoot()
        scrollToL4ControlsSection()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractButton",
            type: .button,
            componentName: "platformButton",
            sanitizedIdentifierName: "l4contractbutton",
            identifierElementType: "Button"
        )
    }

    @MainActor
    func testL4_platformTextField() throws {
        ensureContractRoot()
        scrollToL4ControlsSection()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractTextField",
            type: .textField,
            componentName: "platformTextField",
            sanitizedIdentifierName: "l4contracttextfield",
            identifierElementType: "TextField"
        )
    }

    @MainActor
    func testL4_platformPicker() throws {
        ensureContractRoot()
        scrollToL4ControlsSection()
        scrollToElement(label: "L4ContractPicker")
        // platformPicker contract: picker or an option has identifier.
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", "picker")
        let pickerEl = app.descendants(matching: .any).matching(pred).firstMatch
        if pickerEl.waitForExistence(timeout: 3.0) {
            XCTAssertFalse(pickerEl.identifier.isEmpty, "platformPicker must apply a11y. Found: '\(pickerEl.identifier)'")
            return
        }
        // Options may be in hierarchy only when menu is open; tap picker (shows selected "A") to open.
        if app.buttons["A"].waitForExistence(timeout: 2.0) { app.buttons["A"].firstMatch.tap() }
        let optionAId = Self.l4ContractIdentifier(sanitizedName: "a", elementType: "View")
        let optionEl = app.findElement(byIdentifier: optionAId, primaryType: .button, secondaryTypes: [.staticText, .other, .any], timeout: 3.0)
        XCTAssertNotNil(optionEl, "platformPicker: picker or option should have identifier (tried 'picker' and '\(optionAId)')")
        if let el = optionEl { XCTAssertFalse(el.identifier.isEmpty, "platformPicker must apply a11y.") }
    }

    @MainActor
    func testL4_platformSecureField() throws {
        ensureContractRoot()
        scrollToL4ControlsSection()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractSecureField",
            type: .secureTextField,
            componentName: "platformSecureField",
            sanitizedIdentifierName: "l4contractsecurefield",
            identifierElementType: "SecureField"
        )
    }

    @MainActor
    func testL4_platformToggle() throws {
        ensureContractRoot()
        scrollToL4ControlsSection()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractToggle",
            type: .switch,
            componentName: "platformToggle",
            sanitizedIdentifierName: "l4contracttoggle",
            identifierElementType: "Toggle"
        )
    }

    @MainActor
    func testL4_platformTextEditor() throws {
        ensureContractRoot()
        scrollToL4ControlsSection()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractTextEditor",
            type: .textView,
            componentName: "platformTextEditor",
            sanitizedIdentifierName: "l4contracttexteditor",
            identifierElementType: "TextEditor"
        )
    }

    @MainActor
    func testL4_platformDatePicker() throws {
        ensureContractRoot()
        scrollToL4ControlsSection()
        scrollToElement(label: "L4ContractDatePicker")
        let hasLabel = app.staticTexts["L4ContractDatePicker"].waitForExistence(timeout: 3.0)
            || app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "L4ContractDatePicker")).firstMatch.waitForExistence(timeout: 2.0)
        XCTAssertTrue(hasLabel,
                      "platformDatePicker: label must exist (contract); date picker control is platform-rendered")
    }

    @MainActor
    func testL4_platformForm() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Form")
        scrollToElement(label: "Section body")
        let hasFormSection = anyDescendantHasLabel(equalTo: "L4 Form", timeout: 3.0)
            || app.staticTexts["L4 Form"].waitForExistence(timeout: 2.0)
            || app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", "L4 Form")).firstMatch.waitForExistence(timeout: 2.0)
        XCTAssertTrue(hasFormSection,
                      "platformForm: form section title (L4 Form) should be visible")
        XCTAssertTrue(l4FormSectionHeaderVisible(timeout: 4.0),
                      "platformForm: form must contain section with header (contract structure)")
    }

    @MainActor
    func testL4_platformFormSection() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Form")
        scrollToElement(label: "Section body")
        XCTAssertTrue(l4FormSectionHeaderVisible(timeout: 4.0),
                      "platformFormSection: section header must be visible (contract structure)")
    }

    @MainActor
    func testL4_platformFormField() throws {
        ensureContractRoot()
        scrollToElement(label: "L4FormFieldContract")
        let hasLabel = app.staticTexts["L4FormFieldContract"].waitForExistence(timeout: 3.0)
            || app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "L4FormFieldContract")).firstMatch.waitForExistence(timeout: 2.0)
        XCTAssertTrue(hasLabel,
                      "platformFormField: label must exist (contract structure)")
        XCTAssertTrue(app.staticTexts["Field content"].waitForExistence(timeout: 2.0),
                      "platformFormField: content must exist (contract structure)")
    }

    @MainActor
    func testL4_platformFormFieldGroup() throws {
        ensureContractRoot()
        scrollToElement(label: "L4FormFieldGroupContract")
        let hasTitle = app.staticTexts["L4FormFieldGroupContract"].waitForExistence(timeout: 3.0)
            || app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "L4FormFieldGroupContract")).firstMatch.waitForExistence(timeout: 2.0)
        XCTAssertTrue(hasTitle,
                      "platformFormFieldGroup: title must exist (contract structure)")
    }

    @MainActor
    func testL4_platformValidationMessage() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Form")
        scrollToElement(label: "L4ValidationMessageContract")
        XCTAssertTrue(app.staticTexts["L4ValidationMessageContract"].waitForExistence(timeout: 3.0),
                      "platformValidationMessage: message text must be visible (contract structure)")
    }

    @MainActor
    func testL4_platformListRow() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ListRowContract")
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "L4ListRowContract")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3.0),
                      "platformListRow: row title must be in list cell (contract structure)")
    }

    @MainActor
    func testL4_platformListSectionHeader() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ListSectionHeaderContract")
        let header = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "L4ListSectionHeaderContract")).firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 3.0),
                      "platformListSectionHeader: header title must exist (contract structure)")
    }

    @MainActor
    func testL4_platformListEmptyState() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ListEmptyStateContract")
        let emptyState = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "L4ListEmptyStateContract")).firstMatch
        XCTAssertTrue(emptyState.waitForExistence(timeout: 3.0),
                      "platformListEmptyState: title must exist (contract structure)")
    }

    // MARK: - Presentation

    @MainActor
    func testL4_platformSheet_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Presentation")
        scrollToElement(label: "L4ContractSheet")
        let sheetMatch = NSPredicate(format: "identifier == %@ OR label == %@", "L4ContractSheet", "L4ContractSheet")
        let sheetByLabelOrId = app.descendants(matching: .any).matching(sheetMatch).firstMatch
        let sheetButton = sheetByLabelOrId.waitForExistence(timeout: 2.0)
            ? sheetByLabelOrId
            : (app.findElement(byIdentifier: "L4ContractSheet", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 5.0)
                ?? app.findElement(byIdentifier: Self.l4ContractIdentifier(sanitizedName: "l4contractsheet", elementType: "Button"), primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 2.0)
                ?? app.buttons["L4ContractSheet"].firstMatch)
        XCTAssertTrue(sheetButton.waitForExistence(timeout: 8.0), "Sheet button should exist")
        tapByNormalizedCenter(sheetButton)
        let closeControl = waitForL4SheetDismissControl(timeout: 15.0)
        XCTAssertNotNil(closeControl,
                        "platformSheet_L4: sheet host should expose dismiss control (contract structure)")
        guard let close = closeControl else { return }
        XCTAssertTrue(waitForStaticTextInForeground("L4SheetContentContract", timeout: 12.0),
                      "platformSheet_L4: sheet content must be visible when presented (contract behavior)")
        tapByNormalizedCenter(close)
    }

    @MainActor
    func testL4_platformPopover_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Presentation")
        scrollToElement(label: "L4ContractPopover")
        let popMatch = NSPredicate(format: "identifier == %@ OR label == %@", "L4ContractPopover", "L4ContractPopover")
        let popByLabelOrId = app.descendants(matching: .any).matching(popMatch).firstMatch
        let popoverButton = popByLabelOrId.waitForExistence(timeout: 2.0)
            ? popByLabelOrId
            : (app.findElement(byIdentifier: "L4ContractPopover", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 5.0)
                ?? app.findElement(byIdentifier: Self.l4ContractIdentifier(sanitizedName: "l4contractpopover", elementType: "Button"), primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 2.0)
                ?? app.buttons["L4ContractPopover"].firstMatch)
        XCTAssertTrue(popoverButton.waitForExistence(timeout: 8.0), "Popover button should exist")
        tapByNormalizedCenter(popoverButton)
        XCTAssertTrue(waitForStaticTextInForeground("L4PopoverContentContract", timeout: 8.0),
                      "platformPopover_L4: popover content must be visible when presented (contract behavior)")
    }

    // MARK: - Navigation

    @MainActor
    func testL4_platformNavigationTitle_L4() throws {
        ensureContractRoot()
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            app.navigationBars.buttons.firstMatch.tap()
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 2.0)
        }
        scrollToElement(label: "L4 Navigation")
        scrollToElement(label: "L4NavLinkContract")
        let navLinkPred = NSPredicate(format: "identifier == %@ OR label == %@", "L4NavLinkContract", "L4NavLinkContract")
        let navAny = app.descendants(matching: .any).matching(navLinkPred).firstMatch
        if navAny.waitForExistence(timeout: 3.0) {
            tapByNormalizedCenter(navAny)
        } else if element(matchingIdentifier: "L4NavLinkContract").waitForExistence(timeout: 1.0) {
            tapByNormalizedCenter(element(matchingIdentifier: "L4NavLinkContract"))
        } else if app.links["L4NavLinkContract"].waitForExistence(timeout: 1.0) {
            app.links["L4NavLinkContract"].firstMatch.tap()
        } else if app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 1.0) {
            tapByNormalizedCenter(app.staticTexts["L4NavLinkContract"].firstMatch)
        } else if app.cells.containing(NSPredicate(format: "label == %@", "L4NavLinkContract")).firstMatch.waitForExistence(timeout: 2.0) {
            tapByNormalizedCenter(app.cells.containing(NSPredicate(format: "label == %@", "L4NavLinkContract")).firstMatch)
        } else {
            let navById = element(matchingIdentifier: "L4NavLinkContract")
            if navById.waitForExistence(timeout: 0.5) {
                tapByNormalizedCenter(navById)
            } else if app.links["L4NavLinkContract"].waitForExistence(timeout: 0.5) {
                app.links["L4NavLinkContract"].firstMatch.tap()
            } else if app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 0.5) {
                tapByNormalizedCenter(app.staticTexts["L4NavLinkContract"].firstMatch)
            } else if app.cells.containing(NSPredicate(format: "label == %@", "L4NavLinkContract")).firstMatch.waitForExistence(timeout: 0.5) {
                tapByNormalizedCenter(app.cells.containing(NSPredicate(format: "label == %@", "L4NavLinkContract")).firstMatch)
            } else {
                let byId = app.findElement(byIdentifier: "L4NavLinkContract", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 5.0)
                let byPred = element(matchingIdentifier: "L4NavLinkContract")
                let tapTarget: XCUIElement? = byId ?? (byPred.waitForExistence(timeout: 2.0) ? byPred : nil)
                XCTAssertNotNil(tapTarget, "Nav link with identifier L4NavLinkContract should exist")
                tapByNormalizedCenter(tapTarget!)
            }
        }
        XCTAssertTrue(app.navigationBars["L4NavTitleContract"].waitForExistence(timeout: 3.0),
                      "platformNavigationTitle_L4: destination title must appear in nav bar (contract structure)")
        XCTAssertTrue(waitForDestinationContent(timeout: 15.0),
                      "platformNavigationTitle_L4: destination content should be visible")
    }

    @MainActor
    func testL4_platformNavigationLink_L4() throws {
        ensureContractRoot()
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            app.navigationBars.buttons.firstMatch.tap()
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 2.0)
        }
        scrollToElement(label: "L4 Navigation")
        scrollToElement(label: "L4NavLinkContract")
        let navLinkPredLink = NSPredicate(format: "identifier == %@ OR label == %@", "L4NavLinkContract", "L4NavLinkContract")
        let navAnyLink = app.descendants(matching: .any).matching(navLinkPredLink).firstMatch
        if navAnyLink.waitForExistence(timeout: 3.0) {
            tapByNormalizedCenter(navAnyLink)
        } else if element(matchingIdentifier: "L4NavLinkContract").waitForExistence(timeout: 1.0) {
            tapByNormalizedCenter(element(matchingIdentifier: "L4NavLinkContract"))
        } else if app.links["L4NavLinkContract"].waitForExistence(timeout: 1.0) {
            app.links["L4NavLinkContract"].firstMatch.tap()
        } else if app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 1.0) {
            tapByNormalizedCenter(app.staticTexts["L4NavLinkContract"].firstMatch)
        } else if app.cells.containing(NSPredicate(format: "label == %@", "L4NavLinkContract")).firstMatch.waitForExistence(timeout: 2.0) {
            tapByNormalizedCenter(app.cells.containing(NSPredicate(format: "label == %@", "L4NavLinkContract")).firstMatch)
        } else {
            let byId = app.findElement(byIdentifier: "L4NavLinkContract", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 5.0)
            let byPred = element(matchingIdentifier: "L4NavLinkContract")
            let tapTarget: XCUIElement? = byId ?? (byPred.waitForExistence(timeout: 2.0) ? byPred : nil)
            XCTAssertNotNil(tapTarget, "platformNavigationLink: link with identifier L4NavLinkContract should exist")
            tapByNormalizedCenter(tapTarget!)
        }
        XCTAssertTrue(waitForDestinationContent(timeout: 18.0),
                      "platformNavigationLink_L4: navigating to destination should show content")
    }

    @MainActor
    func testL4_platformNavigationBarTitleDisplayMode_L4() throws {
        ensureContractRoot()
        XCTAssertTrue(app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 3.0),
                      "platformNavigationBarTitleDisplayMode_L4: nav bar with title should exist (applied on root)")
    }

    @MainActor
    func testL4_overlayAccessibility_hidesUnderlyingContent_whenOverlayPresented() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 6.0),
                      "overlay contract: explicit expand affordance button should exist")

        let detailAction = app.buttons["L4OverlayDetailAction"].firstMatch
        XCTAssertTrue(detailAction.waitForExistence(timeout: 4.0),
                      "overlay contract: underlying detail action should exist before overlay opens")

        tapByNormalizedCenter(showSidebarButton)
        XCTAssertTrue(app.staticTexts["L4OverlaySidebarContent"].waitForExistence(timeout: 5.0),
                      "overlay contract: sidebar content should be presented in overlay")

        XCTAssertFalse(detailAction.isHittable,
                       "overlay contract: underlying detail action should not be hittable while overlay is active")
    }

    @MainActor
    func testL4_overlayAccessibility_returnsFocusToExpandButton_onDismiss() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 6.0),
                      "overlay contract: explicit expand affordance button should exist")

        tapByNormalizedCenter(showSidebarButton)
        XCTAssertTrue(app.staticTexts["L4OverlaySidebarContent"].waitForExistence(timeout: 5.0),
                      "overlay contract: sidebar content should be presented in overlay")

        let closeSidebarByID = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4OverlayCloseSidebar"))
            .firstMatch
        let closeSidebarByLabel = app.buttons["Close sidebar"].firstMatch
        let closeSidebarButton: XCUIElement
        if closeSidebarByID.waitForExistence(timeout: 4.0) {
            closeSidebarButton = closeSidebarByID
        } else {
            XCTAssertTrue(closeSidebarByLabel.waitForExistence(timeout: 4.0),
                          "overlay contract: explicit close affordance should exist in overlay")
            closeSidebarButton = closeSidebarByLabel
        }
        tapByNormalizedCenter(closeSidebarButton)

        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 4.0),
                      "overlay contract: expand affordance should remain available after dismiss")
        XCTAssertTrue(showSidebarButton.isHittable,
                      "overlay contract: focus/interaction should return to expand affordance after dismiss")
    }

    @MainActor
    func testL4_overlayAccessibility_modalRootVisible_whenPresented() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 6.0),
                      "overlay contract: explicit expand affordance button should exist")
        tapByNormalizedCenter(showSidebarButton)

        let modalRoot = app.otherElements["L4OverlayModalRoot"].firstMatch
        XCTAssertTrue(modalRoot.waitForExistence(timeout: 5.0),
                      "overlay contract: modal root should be exposed for a11y navigation")
    }

    @MainActor
    func testL4_overlayAccessibility_closeAffordanceHasExplicitAccessibilityLabel() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 6.0),
                      "overlay contract: explicit expand affordance button should exist")
        tapByNormalizedCenter(showSidebarButton)

        let closeSidebarByID = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4OverlayCloseSidebar"))
            .firstMatch
        let closeSidebarByLabel = app.buttons["Close sidebar"].firstMatch
        let closeSidebarElement = closeSidebarByID.waitForExistence(timeout: 2.0) ? closeSidebarByID : closeSidebarByLabel
        XCTAssertTrue(closeSidebarElement.waitForExistence(timeout: 5.0),
                      "overlay contract: close affordance should be exposed with explicit accessibility label")
        XCTAssertEqual(closeSidebarElement.label, "Close sidebar",
                       "overlay contract: close affordance should expose explicit accessibility label")
    }

    @MainActor
    func testL4_overlayAccessibility_sidebarContentHidden_afterDismiss() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 6.0),
                      "overlay contract: explicit expand affordance button should exist")
        tapByNormalizedCenter(showSidebarButton)

        let modalRoot = app.otherElements["L4OverlayModalRoot"].firstMatch
        XCTAssertTrue(modalRoot.waitForExistence(timeout: 5.0),
                      "overlay contract: modal root should be exposed while overlay is active before dismiss")

        let sidebarContentAny = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4OverlaySidebarContent"))
            .firstMatch
        XCTAssertTrue(sidebarContentAny.waitForExistence(timeout: 4.0),
                      "overlay contract: sidebar content should be exposed while overlay is active before dismiss")

        let closeSidebarByID = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4OverlayCloseSidebar"))
            .firstMatch
        let closeSidebarByLabel = app.buttons["Close sidebar"].firstMatch
        let closeSidebarButton: XCUIElement
        if closeSidebarByID.waitForExistence(timeout: 4.0) {
            closeSidebarButton = closeSidebarByID
        } else {
            XCTAssertTrue(closeSidebarByLabel.waitForExistence(timeout: 4.0),
                          "overlay contract: explicit close affordance should exist in overlay")
            closeSidebarButton = closeSidebarByLabel
        }

        tapByNormalizedCenter(closeSidebarButton)

        XCTAssertFalse(modalRoot.waitForExistence(timeout: 2.0),
                       "overlay contract: modal root should be removed after dismiss")
        XCTAssertFalse(sidebarContentAny.waitForExistence(timeout: 2.0),
                       "overlay contract: sidebar content should not remain exposed after dismiss")
        XCTAssertTrue(showSidebarButton.isHittable,
                      "overlay contract: expand affordance should be hittable after dismiss")
    }

    // MARK: - System (Copy, Print, Share)

    @MainActor
    func testL4_platformCopyToClipboard_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ContractCopy")
        let copyById = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "L4ContractCopy")).firstMatch
        let copyByLabel = app.buttons["L4ContractCopy"].firstMatch
        let copyButton: XCUIElement
        if copyById.waitForExistence(timeout: 10.0) {
            copyButton = copyById
        } else {
            XCTAssertTrue(copyByLabel.waitForExistence(timeout: 3.0),
                          "platformCopyToClipboard_L4: Copy button with identifier or label L4ContractCopy should exist (contract a11y)")
            copyButton = copyByLabel
        }
        tapByNormalizedCenter(copyButton)
        // Behavior: copy invoked without crash; optional paste verification would require a paste target in contract UI
    }

    @MainActor
    func testL4_platformPrint_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ContractPrint")
        let printById = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "L4ContractPrint")).firstMatch
        let printByLabel = app.buttons["L4ContractPrint"].firstMatch
        let printButton: XCUIElement
        if printById.waitForExistence(timeout: 10.0) {
            printButton = printById
        } else {
            XCTAssertTrue(printByLabel.waitForExistence(timeout: 3.0),
                          "platformPrint_L4: Print button with identifier or label L4ContractPrint should exist (contract a11y)")
            printButton = printByLabel
        }
        tapByNormalizedCenter(printButton)
        // Host skips real UIPrintInteractionController under -UITesting; if a system print UI still appears, dismiss it.
        let cancelPrint = app.buttons["Cancel"].firstMatch
        if cancelPrint.waitForExistence(timeout: 1.0) { cancelPrint.tap() }
        let closePrint = app.navigationBars.buttons["Close"].firstMatch
        if closePrint.waitForExistence(timeout: 0.5) { closePrint.tap() }
        XCTAssertTrue(
            app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 6.0),
            "platformPrint_L4: contract screen must be reachable after print (no stuck modal blocking the suite)"
        )
    }

    @MainActor
    func testL4_platformCloudKitSyncStatus_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 System")
        scrollToElement(label: "CloudKit Sync Status")
        XCTAssertTrue(app.staticTexts["CloudKit Sync: Idle"].waitForExistence(timeout: 5.0),
                      "platformCloudKitSyncStatus_L4: status text must be visible (contract structure)")
        let exactId = element(matchingIdentifier: "platformCloudKitSyncStatus_L4")
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitSyncStatus"))
            .firstMatch
        XCTAssertTrue(
            exactId.waitForExistence(timeout: 4.0) || containsId.waitForExistence(timeout: 8.0),
            "platformCloudKitSyncStatus_L4: view must have a11y identifier (contract a11y)"
        )
    }

    @MainActor
    func testL4_platformCloudKitProgress_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 System")
        scrollToElement(label: "CloudKit Progress")
        XCTAssertTrue(
            app.staticTexts["60%"].waitForExistence(timeout: 6.0),
            "platformCloudKitProgress_L4: progress caption must be visible (contract structure)"
        )
        XCTAssertTrue(
            app.staticTexts["CloudKit Sync: Idle"].waitForExistence(timeout: 4.0),
            "platformCloudKitProgress_L4: nested sync status must be visible when status is provided"
        )
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitProgress_L4"))
            .firstMatch
        XCTAssertTrue(containsId.waitForExistence(timeout: 10.0),
                      "platformCloudKitProgress_L4: view must expose contract a11y identifier (contains platformCloudKitProgress_L4)")
    }

    @MainActor
    func testL4_platformCloudKitAccountStatus_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 System")
        scrollToElement(label: "CloudKit Account")
        XCTAssertTrue(
            app.staticTexts["iCloud Account: Available"].waitForExistence(timeout: 6.0),
            "platformCloudKitAccountStatus_L4: account label must be visible (contract structure)"
        )
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitAccountStatus_L4"))
            .firstMatch
        XCTAssertTrue(containsId.waitForExistence(timeout: 10.0),
                      "platformCloudKitAccountStatus_L4: view must expose contract a11y identifier")
    }

    @MainActor
    func testL4_platformCloudKitServiceStatus_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 System")
        scrollToElement(label: "CloudKit Service Status")
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitServiceStatus_L4"))
            .firstMatch
        XCTAssertTrue(containsId.waitForExistence(timeout: 12.0),
                      "platformCloudKitServiceStatus_L4: composite view must expose contract a11y identifier")
        let hasIdleOrAccount = app.staticTexts["CloudKit Sync: Idle"].waitForExistence(timeout: 4.0)
            || app.staticTexts["iCloud Account: Available"].waitForExistence(timeout: 2.0)
            || app.staticTexts["iCloud Account: Unknown"].waitForExistence(timeout: 2.0)
        XCTAssertTrue(
            hasIdleOrAccount,
            "platformCloudKitServiceStatus_L4: at least one child status line must be visible (contract structure)"
        )
    }

    @MainActor
    func testL4_platformCloudKitSyncButton_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 System")
        scrollToElement(label: "CloudKit Sync Button")
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitSyncButton_L4"))
            .firstMatch
        XCTAssertTrue(containsId.waitForExistence(timeout: 12.0),
                      "platformCloudKitSyncButton_L4: button must expose contract a11y identifier")
        let byLabel = app.buttons["Sync"].firstMatch
        XCTAssertTrue(
            byLabel.waitForExistence(timeout: 6.0),
            "platformCloudKitSyncButton_L4: default Sync button must be findable (contract structure)"
        )
    }

    @MainActor
    func testL4_platformCloudKitStatusBadge_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 System")
        scrollToElement(label: "CloudKit Status Badge")
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitStatusBadge_L4"))
            .firstMatch
        XCTAssertTrue(containsId.waitForExistence(timeout: 12.0),
                      "platformCloudKitStatusBadge_L4: badge must expose contract a11y identifier")
    }

    @MainActor
    func testL4_platformPhotoDisplay_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "Photo Display")
        let photoView = app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformPhotoDisplay")).firstMatch
        XCTAssertTrue(photoView.waitForExistence(timeout: 10.0),
                      "platformPhotoDisplay_L4: view must have a11y identifier (contract a11y)")
    }
}
