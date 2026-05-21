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
/// Uses launch argument `-OpenLayer4Examples`. Each test launches (and tears down) its own `XCUIApplication` so
/// **parallel** and **random** ordering do not share mutable UI state; one failure cannot strand later tests on a bad screen.
///
/// Currently covered: platformButton, platformTextField, platformPicker, platformSecureField, platformToggle,
/// platformTextEditor, platformDatePicker, platformForm, platformFormSection, platformFormField, platformFormFieldGroup,
/// platformValidationMessage, platformListRow, platformListSectionHeader, platformListEmptyState,
/// platformSheet_L4, platformPopover_L4, platformNavigationTitle_L4, platformNavigationLink_L4, platformNavigationBarTitleDisplayMode_L4,
/// platformCopyToClipboard_L4, platformPrint_L4, platformCloudKitSyncStatus_L4,
/// platformCloudKitProgress_L4, platformCloudKitAccountStatus_L4, platformCloudKitServiceStatus_L4,
/// platformCloudKitSyncButton_L4, platformCloudKitStatusBadge_L4, platformPhotoDisplay_L4,
/// platformImplementNavigationStack_L4, platformRowActions_L4, platformPhotoPicker_L4 (iOS UITest only).
/// Remaining L4 APIs to add: platformAppNavigation_L4 (partially exercised via overlay contract),
/// platformMapView_L4,
/// platformShare_L4, platformVerticalSplit_L4, platformHorizontalSplit_L4, platformStyledContainer_L4, etc.
@MainActor
final class Layer4UITests: XCTestCase {
    /// Fresh host per test method (required for parallel + random execution; avoids cross-test UI coupling).
    /// `nonisolated(unsafe)` so `nonisolated` XCTest hooks can assign without `self` isolation diagnostics; XCTest
    /// serializes `setUp` / test / `tearDown` per instance on the main thread for UI tests.
    nonisolated(unsafe) private var app: XCUIApplication!
    private static let quickWait: TimeInterval = 0.35
    /// UITest fail-fast: bounded launch + scroll work so a bad host does not burn CI minutes (Refs #261).
    private static let rootReadyTimeout: TimeInterval = 3.0
    /// Deep `Form` hosts need more than a handful of swipes; still capped (Refs #261).
    /// Root `Form` is tall (overlay ~400pt + full L4 sections); shallow caps miss L4 Controls / System (#261).
    private static let maxScrollAttempts = 18
    private static let maxL4SystemScrollAttempts = 20

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            // `-SkipAnimations` can leave `.sheet` presented without a populated a11y subtree on iOS 26
            // (Sheet exists; contract static text never appears — Issue #193).
            localApp.launchArguments.removeAll(where: { $0 == "-SkipAnimations" })
            localApp.launchArguments.append("-OpenLayer4Examples")
            localApp.launch()
            instance.app = localApp
            XCTAssertTrue(
                localApp.wait(for: .runningForeground, timeout: Self.rootReadyTimeout),
                "App should reach foreground after launch (Layer 4 contract host)"
            )
            let contractRootReady = instance.waitForContractRoot(timeout: Self.rootReadyTimeout)
            XCTAssertTrue(
                contractRootReady,
                "App should open on Layer 4 contract host (-OpenLayer4Examples): L4ContractSheet / L4 Presentation / nav title"
            )
        }
    }

    nonisolated override func tearDownWithError() throws {
        if let runningApp = app, runningApp.state != .notRunning {
            runningApp.terminate()
            _ = runningApp.wait(for: .notRunning, timeout: 5)
        }
        app = nil
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

    /// Fail fast on known root anchors instead of chaining long waits for each one.
    @MainActor
    private func waitForContractRoot(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.buttons["L4ContractSheet"].exists { return true }
            if app.staticTexts["L4 Presentation"].exists { return true }
            if app.navigationBars["Layer 4 Examples"].exists { return true }
            if app.staticTexts["Layer 4 Examples"].exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.quickWait))
        }
        return false
    }

    /// `Label` / grouped controls often surface as `other` with a combined accessibility label, not `XCUIElementType.staticText`.
    @MainActor
    private func waitForCombinedAccessibilityLabel(equalTo text: String, timeout: TimeInterval) -> Bool {
        let pred = NSPredicate(format: "label == %@", text)
        return app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: timeout)
    }

    /// SF Symbol `Label` rows often expose VoiceOver-style labels that **contain** the contract summary but are not `==`.
    @MainActor
    private func waitForCombinedAccessibilityLabel(containing text: String, timeout: TimeInterval) -> Bool {
        let pred = NSPredicate(format: "label CONTAINS[c] %@", text)
        return app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: timeout)
    }

    /// List / Form contract titles: match `staticText`, grouped `other`, or generated identifier fragments.
    @MainActor
    private func l4ContractLabelOrIdentifierVisible(title: String, timeout: TimeInterval = 2.0) -> Bool {
        let pred = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "label == %@", title),
            NSPredicate(format: "label CONTAINS[c] %@", title),
            NSPredicate(format: "identifier CONTAINS[c] %@", title),
        ])
        return app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: timeout)
    }

    /// After the L4 List section header is on-screen, nudge past the header chrome so embedded `List` rows resolve.
    @MainActor
    private func nudgeScrollAfterL4ListSectionHeader() {
        for _ in 0..<2 {
            app.xcuiSwipeScrollHostsUp()
        }
    }

    /// Scroll so the element with the given label is visible (content may be below fold).
    /// Bounded `maxScrollAttempts` so a wrong scroll host fails fast instead of long idle loops (Refs #261).
    @MainActor
    private func scrollToElement(label: String, maxAttempts: Int = maxScrollAttempts) {
        if app.staticTexts[label].waitForExistence(timeout: Self.quickWait) { return }
        if anyDescendantHasLabel(equalTo: label, timeout: Self.quickWait) { return }
        if app.buttons[label].waitForExistence(timeout: Self.quickWait) { return }
        if app.links[label].waitForExistence(timeout: Self.quickWait) { return }
        if element(matchingIdentifier: label).waitForExistence(timeout: Self.quickWait) { return }
        if !app.xcuiPrimaryScrollHost().exists, !app.tables.firstMatch.exists, !app.scrollViews.firstMatch.exists { return }
        for _ in 0..<maxAttempts {
            app.xcuiSwipeScrollHostsUp()
            if app.staticTexts[label].waitForExistence(timeout: Self.quickWait) { return }
            if anyDescendantHasLabel(equalTo: label, timeout: Self.quickWait) { return }
            if app.buttons[label].waitForExistence(timeout: Self.quickWait) { return }
            if element(matchingIdentifier: label).waitForExistence(timeout: Self.quickWait) { return }
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
        scrollToContractIdentifier(headerId, maxAttempts: Self.maxScrollAttempts)
        if element(matchingIdentifier: headerId).waitForExistence(timeout: Self.quickWait) { return }
        if anyDescendantHasLabel(equalTo: title, timeout: Self.quickWait) { return }
        if app.staticTexts[title].waitForExistence(timeout: Self.quickWait) { return }
    }

    /// `Form` rows for L4 Controls sit mid-scroll; anchor on the section header before field/button contract checks.
    @MainActor
    private func scrollToL4ControlsSection() {
        scrollToFormSectionHeader(title: "L4 Controls")
    }

    /// Rows below the L4 Controls header can stay off-screen until the Form scrolls a few more notches (iOS 26).
    @MainActor
    private func nudgeScrollInsideL4ControlsSection() {
        for _ in 0..<5 {
            app.xcuiSwipeScrollHostsUp()
        }
    }

    /// Captions and controls under L4 System often sit below the section header in the root Form.
    @MainActor
    private func nudgeScrollInsideL4SystemSection() {
        for _ in 0..<3 {
            app.xcuiSwipeScrollHostsUp()
        }
    }

    /// L4 Controls contract rows (secure field, editor, date picker) sit below the section header.
    @MainActor
    private func scrollToL4ControlsContracts() {
        scrollToL4ControlsSection()
        nudgeScrollInsideL4ControlsSection()
        scrollToContractIdentifier("SixLayer.main.ui.l4contractsecurefield.SecureField", maxAttempts: 14)
    }

    /// CloudKit + photo picker rows are deep in L4 System (after clipboard/print/url rows and overlay above).
    @MainActor
    private func scrollToL4SystemCloudKitContracts() {
        scrollToFormSectionHeader(title: "L4 System")
        scrollToContractIdentifier("L4ContractCopy", maxAttempts: Self.maxL4SystemScrollAttempts)
        nudgeScrollInsideL4SystemSection()
        scrollToElement(label: "CloudKit Sync: Idle", maxAttempts: Self.maxL4SystemScrollAttempts)
    }

    /// Scroll until a contract accessibility identifier is on-screen (L4 System rows are deep under overlay section).
    @MainActor
    private func scrollToContractIdentifier(_ identifier: String, maxAttempts: Int = Layer4UITests.maxScrollAttempts) {
        let node = element(matchingIdentifier: identifier)
        if node.waitForExistence(timeout: Self.quickWait) { return }
        let contains = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", identifier))
            .firstMatch
        if contains.waitForExistence(timeout: Self.quickWait) { return }
        if !app.xcuiPrimaryScrollHost().exists, !app.tables.firstMatch.exists, !app.scrollViews.firstMatch.exists { return }
        for _ in 0..<maxAttempts {
            app.xcuiSwipeScrollHostsUp()
            if node.waitForExistence(timeout: Self.quickWait) { return }
            if contains.waitForExistence(timeout: Self.quickWait) { return }
        }
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
        if byId.waitForExistence(timeout: 1.5) { return byId }
        if app.buttons["Show sidebar"].waitForExistence(timeout: 1.0) {
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
        if app.descendants(matching: .any).matching(matchAny).firstMatch.waitForExistence(timeout: min(timeout, 2.5)) { return true }
        return app.otherElements["L4NavDestinationContent"].waitForExistence(timeout: 1.0)
    }

    /// Ensure we're on the contract root with top of content visible. Pop from nav stack if needed; scroll to top if the first contract section is off-screen.
    @MainActor
    private func ensureContractRoot() {
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists { backButton.tap() }
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 1.0)
        }
        if app.navigationBars["L4NavTitleContract"].waitForExistence(timeout: 0.5) {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists { backButton.tap() }
            _ = waitForContractRoot(timeout: 1.0)
        }
        XCTAssertTrue(
            waitForContractRoot(timeout: 1.2),
            "Contract root: Layer 4 Examples nav bar or L4 contract anchors (L4ContractSheet / L4 Presentation) should exist"
        )
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
        for _ in 0..<Self.maxScrollAttempts {
            app.xcuiSwipeScrollHostsDown()
            if contractTopVisible() { return }
        }
        XCTAssertTrue(
            app.staticTexts["L4 Presentation"].waitForExistence(timeout: 1.2)
                || anyDescendantHasLabel(equalTo: "L4 Presentation", timeout: 1.0)
                || app.staticTexts["L4 System"].waitForExistence(timeout: 0.5)
                || anyDescendantHasLabel(equalTo: "L4 System", timeout: 0.5)
                || app.buttons["L4ContractSheet"].waitForExistence(timeout: 1.2)
                || element(matchingIdentifier: "L4ContractSheet").waitForExistence(timeout: 1.0),
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
        let hostExplicitId = identifier
        // Prefer contract type first so we find the real control; then .other as fallback (type assertion will fail if only wrapper has id).
        let typesToTry: [(XCUIElement.ElementType, TimeInterval)] = (type == .textField || type == .secureTextField || type == .switch || type == .textView)
            ? [(type, 1.8), (.other, 0.9)]
            : [(type, 1.8)]
        var el: XCUIElement?
        if element(matchingIdentifier: hostExplicitId).waitForExistence(timeout: 1.2) {
            el = element(matchingIdentifier: hostExplicitId)
        }
        for (primaryType, timeout) in typesToTry where el == nil {
            el = app.findElement(byIdentifier: identifier, primaryType: primaryType, secondaryTypes: [.other, .button, .staticText, .any], timeout: timeout)
            if el != nil { break }
        }
        if el == nil {
            el = app.findElement(byIdentifier: identifier, primaryType: .any, secondaryTypes: [.other, .button, .staticText], timeout: 1.0)
        }
        if el == nil {
            let containsPred = NSPredicate(format: "identifier CONTAINS[c] %@", sanitizedIdentifierName)
            let anyWithId = app.descendants(matching: .any).matching(containsPred).firstMatch
            if anyWithId.waitForExistence(timeout: 1.0) { el = anyWithId }
        }
        // iOS Form/runtime can expose the interactive control by label while moving generated id to a wrapper.
        if el == nil {
            let byLabel = app.descendants(matching: type).matching(NSPredicate(format: "label == %@", label)).firstMatch
            if byLabel.waitForExistence(timeout: 1.0) { el = byLabel }
        }
        if el == nil {
            let byLabelAny = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@ OR label CONTAINS[c] %@", label, label, label)).firstMatch
            if byLabelAny.waitForExistence(timeout: 1.2) { el = byLabelAny }
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
        let pickerPredicates: [NSPredicate] = [
            NSPredicate(format: "identifier CONTAINS[c] %@", "picker"),
            NSPredicate(format: "identifier CONTAINS[c] %@", "Picker"),
            NSPredicate(format: "identifier CONTAINS[c] %@", "platformPicker"),
            NSPredicate(format: "identifier CONTAINS[c] %@", "L4ContractPicker"),
        ]
        for pred in pickerPredicates {
            let pickerEl = app.descendants(matching: .any).matching(pred).firstMatch
            if pickerEl.waitForExistence(timeout: 1.2) {
                XCTAssertFalse(pickerEl.identifier.isEmpty, "platformPicker must apply a11y. Found: '\(pickerEl.identifier)'")
                return
            }
        }
        // Menu-style picker: invocation surface may be a button showing the selected value.
        if app.buttons["A"].waitForExistence(timeout: 1.0) { app.buttons["A"].firstMatch.tap() }
        let menuByLabel = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "L4ContractPicker")).firstMatch
        if menuByLabel.waitForExistence(timeout: 1.0) {
            XCTAssertFalse(menuByLabel.identifier.isEmpty, "platformPicker menu must expose a11y identifier")
            return
        }
        let optionAId = Self.l4ContractIdentifier(sanitizedName: "a", elementType: "View")
        let optionEl = app.findElement(byIdentifier: optionAId, primaryType: .button, secondaryTypes: [.staticText, .other, .any], timeout: 1.2)
        XCTAssertNotNil(optionEl, "platformPicker: picker or option should have identifier (tried picker ids, menu label, and '\(optionAId)')")
        if let el = optionEl { XCTAssertFalse(el.identifier.isEmpty, "platformPicker must apply a11y.") }
    }

    @MainActor
    func testL4_platformSecureField() throws {
        ensureContractRoot()
        scrollToL4ControlsContracts()
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
        scrollToL4ControlsContracts()
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
        scrollToL4ControlsContracts()
        scrollToElement(label: "L4ContractDatePicker")
        let hasLabel = app.staticTexts["L4ContractDatePicker"].waitForExistence(timeout: 2.5)
            || app.buttons["L4ContractDatePicker"].waitForExistence(timeout: 1.5)
            || app.datePickers.firstMatch.waitForExistence(timeout: 2.0)
            || app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "L4ContractDatePicker")).firstMatch.waitForExistence(timeout: 1.5)
            || app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", "L4ContractDatePicker")).firstMatch.waitForExistence(timeout: 2.5)
        XCTAssertTrue(hasLabel,
                      "platformDatePicker: label must exist (contract); date picker control is platform-rendered")
    }

    @MainActor
    func testL4_platformForm() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Form")
        scrollToElement(label: "Section body")
        let hasFormSection = anyDescendantHasLabel(equalTo: "L4 Form", timeout: 1.2)
            || app.staticTexts["L4 Form"].waitForExistence(timeout: 1.0)
            || app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", "L4 Form")).firstMatch.waitForExistence(timeout: 1.0)
        XCTAssertTrue(hasFormSection,
                      "platformForm: form section title (L4 Form) should be visible")
        XCTAssertTrue(l4FormSectionHeaderVisible(timeout: 1.5),
                      "platformForm: form must contain section with header (contract structure)")
    }

    @MainActor
    func testL4_platformFormSection() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Form")
        scrollToElement(label: "Section body")
        XCTAssertTrue(l4FormSectionHeaderVisible(timeout: 1.5),
                      "platformFormSection: section header must be visible (contract structure)")
    }

    @MainActor
    func testL4_platformFormField() throws {
        ensureContractRoot()
        scrollToElement(label: "L4FormFieldContract")
        let hasLabel = app.staticTexts["L4FormFieldContract"].waitForExistence(timeout: 1.2)
            || app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "L4FormFieldContract")).firstMatch.waitForExistence(timeout: 1.0)
        XCTAssertTrue(hasLabel,
                      "platformFormField: label must exist (contract structure)")
        XCTAssertTrue(app.staticTexts["Field content"].waitForExistence(timeout: 1.0),
                      "platformFormField: content must exist (contract structure)")
    }

    @MainActor
    func testL4_platformFormFieldGroup() throws {
        ensureContractRoot()
        scrollToElement(label: "L4FormFieldGroupContract")
        let hasTitle = app.staticTexts["L4FormFieldGroupContract"].waitForExistence(timeout: 1.2)
            || app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "L4FormFieldGroupContract")).firstMatch.waitForExistence(timeout: 1.0)
        XCTAssertTrue(hasTitle,
                      "platformFormFieldGroup: title must exist (contract structure)")
    }

    @MainActor
    func testL4_platformValidationMessage() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Form")
        scrollToElement(label: "L4ValidationMessageContract")
        XCTAssertTrue(app.staticTexts["L4ValidationMessageContract"].waitForExistence(timeout: 1.2),
                      "platformValidationMessage: message text must be visible (contract structure)")
    }

    @MainActor
    func testL4_platformListRow() throws {
        ensureContractRoot()
        scrollToFormSectionHeader(title: "L4 List")
        nudgeScrollAfterL4ListSectionHeader()
        scrollToElement(label: "L4ListRowContract")
        XCTAssertTrue(l4ContractLabelOrIdentifierVisible(title: "L4ListRowContract", timeout: 2.0),
                      "platformListRow: row title must be in list cell (contract structure)")
    }

    @MainActor
    func testL4_platformListSectionHeader() throws {
        ensureContractRoot()
        scrollToFormSectionHeader(title: "L4 List")
        nudgeScrollAfterL4ListSectionHeader()
        scrollToElement(label: "L4ListSectionHeaderContract")
        XCTAssertTrue(l4ContractLabelOrIdentifierVisible(title: "L4ListSectionHeaderContract", timeout: 2.0),
                      "platformListSectionHeader: header title must exist (contract structure)")
    }

    @MainActor
    func testL4_platformListEmptyState() throws {
        ensureContractRoot()
        scrollToFormSectionHeader(title: "L4 List")
        nudgeScrollAfterL4ListSectionHeader()
        scrollToElement(label: "L4ListEmptyStateContract")
        XCTAssertTrue(l4ContractLabelOrIdentifierVisible(title: "L4ListEmptyStateContract", timeout: 2.0),
                      "platformListEmptyState: title must exist (contract structure)")
    }

    @MainActor
    func testL4_platformRowActions_L4() throws {
        ensureContractRoot()
        scrollToFormSectionHeader(title: "L4 List")
        nudgeScrollAfterL4ListSectionHeader()
        scrollToElement(label: "L4RowActionsContractRow")
        XCTAssertTrue(l4ContractLabelOrIdentifierVisible(title: "L4RowActionsContractRow", timeout: 2.0),
                      "platformRowActions_L4: contract row must be visible (contract structure)")
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformRowActions_L4"))
            .firstMatch
        XCTAssertTrue(containsId.waitForExistence(timeout: 2.5),
                      "platformRowActions_L4: row must expose contract a11y identifier")
    }

    // MARK: - Presentation

    @MainActor
    func testL4_platformSheet_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Presentation")
        scrollToElement(label: "L4ContractSheet")
        let sheetMatch = NSPredicate(format: "identifier == %@ OR label == %@", "L4ContractSheet", "L4ContractSheet")
        let sheetByLabelOrId = app.descendants(matching: .any).matching(sheetMatch).firstMatch
        let sheetButton = sheetByLabelOrId.waitForExistence(timeout: 1.0)
            ? sheetByLabelOrId
            : (app.findElement(byIdentifier: "L4ContractSheet", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 1.0)
                ?? app.findElement(byIdentifier: Self.l4ContractIdentifier(sanitizedName: "l4contractsheet", elementType: "Button"), primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 1.0)
                ?? app.buttons["L4ContractSheet"].firstMatch)
        XCTAssertTrue(sheetButton.waitForExistence(timeout: 2.5), "Sheet button should exist")
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
        ensureContractRoot()
        scrollToElement(label: "L4 Presentation")
        scrollToElement(label: "L4ContractPopover")
        let popMatch = NSPredicate(format: "identifier == %@ OR label == %@", "L4ContractPopover", "L4ContractPopover")
        let popByLabelOrId = app.descendants(matching: .any).matching(popMatch).firstMatch
        let popoverButton = popByLabelOrId.waitForExistence(timeout: 1.0)
            ? popByLabelOrId
            : (app.findElement(byIdentifier: "L4ContractPopover", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 1.0)
                ?? app.findElement(byIdentifier: Self.l4ContractIdentifier(sanitizedName: "l4contractpopover", elementType: "Button"), primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 1.0)
                ?? app.buttons["L4ContractPopover"].firstMatch)
        XCTAssertTrue(popoverButton.waitForExistence(timeout: 2.5), "Popover button should exist")
        tapByNormalizedCenter(popoverButton)
        XCTAssertTrue(waitForStaticTextInForeground("L4PopoverContentContract", timeout: 2.5),
                      "platformPopover_L4: popover content must be visible when presented (contract behavior)")
    }

    // MARK: - Navigation

    @MainActor
    func testL4_platformNavigationTitle_L4() throws {
        ensureContractRoot()
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            app.navigationBars.buttons.firstMatch.tap()
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 1.0)
        }
        scrollToElement(label: "L4 Navigation")
        scrollToElement(label: "L4NavLinkContract")
        let navLinkPred = NSPredicate(format: "identifier == %@ OR label == %@", "L4NavLinkContract", "L4NavLinkContract")
        let navAny = app.descendants(matching: .any).matching(navLinkPred).firstMatch
        if navAny.waitForExistence(timeout: 1.2) {
            tapByNormalizedCenter(navAny)
        } else if element(matchingIdentifier: "L4NavLinkContract").waitForExistence(timeout: 1.0) {
            tapByNormalizedCenter(element(matchingIdentifier: "L4NavLinkContract"))
        } else if app.links["L4NavLinkContract"].waitForExistence(timeout: 1.0) {
            app.links["L4NavLinkContract"].firstMatch.tap()
        } else if app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 1.0) {
            tapByNormalizedCenter(app.staticTexts["L4NavLinkContract"].firstMatch)
        } else if app.cells.containing(NSPredicate(format: "label == %@", "L4NavLinkContract")).firstMatch.waitForExistence(timeout: 1.0) {
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
                let byId = app.findElement(byIdentifier: "L4NavLinkContract", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 1.0)
                let byPred = element(matchingIdentifier: "L4NavLinkContract")
                let tapTarget: XCUIElement? = byId ?? (byPred.waitForExistence(timeout: 1.0) ? byPred : nil)
                XCTAssertNotNil(tapTarget, "Nav link with identifier L4NavLinkContract should exist")
                tapByNormalizedCenter(tapTarget!)
            }
        }
        XCTAssertTrue(app.navigationBars["L4NavTitleContract"].waitForExistence(timeout: 1.2),
                      "platformNavigationTitle_L4: destination title must appear in nav bar (contract structure)")
        XCTAssertTrue(waitForDestinationContent(timeout: 2.0),
                      "platformNavigationTitle_L4: destination content should be visible")
    }

    @MainActor
    func testL4_platformNavigationLink_L4() throws {
        ensureContractRoot()
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            app.navigationBars.buttons.firstMatch.tap()
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 1.0)
        }
        scrollToElement(label: "L4 Navigation")
        scrollToElement(label: "L4NavLinkContract")
        let navLinkPredLink = NSPredicate(format: "identifier == %@ OR label == %@", "L4NavLinkContract", "L4NavLinkContract")
        let navAnyLink = app.descendants(matching: .any).matching(navLinkPredLink).firstMatch
        if navAnyLink.waitForExistence(timeout: 1.2) {
            tapByNormalizedCenter(navAnyLink)
        } else if element(matchingIdentifier: "L4NavLinkContract").waitForExistence(timeout: 1.0) {
            tapByNormalizedCenter(element(matchingIdentifier: "L4NavLinkContract"))
        } else if app.links["L4NavLinkContract"].waitForExistence(timeout: 1.0) {
            app.links["L4NavLinkContract"].firstMatch.tap()
        } else if app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 1.0) {
            tapByNormalizedCenter(app.staticTexts["L4NavLinkContract"].firstMatch)
        } else if app.cells.containing(NSPredicate(format: "label == %@", "L4NavLinkContract")).firstMatch.waitForExistence(timeout: 1.0) {
            tapByNormalizedCenter(app.cells.containing(NSPredicate(format: "label == %@", "L4NavLinkContract")).firstMatch)
        } else {
            let byId = app.findElement(byIdentifier: "L4NavLinkContract", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 1.0)
            let byPred = element(matchingIdentifier: "L4NavLinkContract")
            let tapTarget: XCUIElement? = byId ?? (byPred.waitForExistence(timeout: 1.0) ? byPred : nil)
            XCTAssertNotNil(tapTarget, "platformNavigationLink: link with identifier L4NavLinkContract should exist")
            tapByNormalizedCenter(tapTarget!)
        }
        XCTAssertTrue(waitForDestinationContent(timeout: 2.0),
                      "platformNavigationLink_L4: navigating to destination should show content")
    }

    @MainActor
    func testL4_platformImplementNavigationStack_L4() throws {
        ensureContractRoot()
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists { backButton.tap() }
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 1.0)
        }
        if app.navigationBars["L4NavTitleContract"].waitForExistence(timeout: 0.5) {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists { backButton.tap() }
            _ = app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 1.2)
        }
        scrollToElement(label: "L4 Navigation")
        scrollToElement(label: "Navigation Stack Contract")
        XCTAssertTrue(
            app.staticTexts["L4NavStackContractRoot"].waitForExistence(timeout: 2.0),
            "platformImplementNavigationStack_L4: stack root content must be visible (contract structure)"
        )
        let innerBar = app.navigationBars["L4NavStackContract"].firstMatch
        XCTAssertTrue(
            innerBar.waitForExistence(timeout: 1.5)
                || app.staticTexts["L4NavStackContract"].waitForExistence(timeout: 1.5),
            "platformImplementNavigationStack_L4: inner navigation title should be exposed (contract structure)"
        )
    }

    @MainActor
    func testL4_platformNavigationBarTitleDisplayMode_L4() throws {
        ensureContractRoot()
        XCTAssertTrue(
            app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 1.2)
                || app.buttons["L4ContractSheet"].waitForExistence(timeout: 1.0),
            "platformNavigationBarTitleDisplayMode_L4: root nav bar or L4 contract anchor should exist (applied on root)"
        )
    }

    @MainActor
    func testL4_overlayAccessibility_hidesUnderlyingContent_whenOverlayPresented() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 1.0),
                      "overlay contract: explicit expand affordance button should exist")

        let detailAction = app.buttons["L4OverlayDetailAction"].firstMatch
        XCTAssertTrue(detailAction.waitForExistence(timeout: 1.5),
                      "overlay contract: underlying detail action should exist before overlay opens")

        tapByNormalizedCenter(showSidebarButton)
        XCTAssertTrue(app.staticTexts["L4OverlaySidebarContent"].waitForExistence(timeout: 1.0),
                      "overlay contract: sidebar content should be presented in overlay")

        XCTAssertFalse(detailAction.isHittable,
                       "overlay contract: underlying detail action should not be hittable while overlay is active")
    }

    @MainActor
    func testL4_overlayAccessibility_returnsFocusToExpandButton_onDismiss() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 1.0),
                      "overlay contract: explicit expand affordance button should exist")

        tapByNormalizedCenter(showSidebarButton)
        XCTAssertTrue(app.staticTexts["L4OverlaySidebarContent"].waitForExistence(timeout: 1.0),
                      "overlay contract: sidebar content should be presented in overlay")

        let closeSidebarByID = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4OverlayCloseSidebar"))
            .firstMatch
        let closeSidebarByLabel = app.buttons["Close sidebar"].firstMatch
        let closeSidebarButton: XCUIElement
        if closeSidebarByID.waitForExistence(timeout: 1.5) {
            closeSidebarButton = closeSidebarByID
        } else {
            XCTAssertTrue(closeSidebarByLabel.waitForExistence(timeout: 1.5),
                          "overlay contract: explicit close affordance should exist in overlay")
            closeSidebarButton = closeSidebarByLabel
        }
        tapByNormalizedCenter(closeSidebarButton)

        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 1.5),
                      "overlay contract: expand affordance should remain available after dismiss")
        XCTAssertTrue(showSidebarButton.isHittable,
                      "overlay contract: focus/interaction should return to expand affordance after dismiss")
    }

    @MainActor
    func testL4_overlayAccessibility_modalRootVisible_whenPresented() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 1.0),
                      "overlay contract: explicit expand affordance button should exist")
        tapByNormalizedCenter(showSidebarButton)

        let modalRoot = app.otherElements["L4OverlayModalRoot"].firstMatch
        XCTAssertTrue(modalRoot.waitForExistence(timeout: 1.0),
                      "overlay contract: modal root should be exposed for a11y navigation")
    }

    @MainActor
    func testL4_overlayAccessibility_closeAffordanceHasExplicitAccessibilityLabel() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 1.0),
                      "overlay contract: explicit expand affordance button should exist")
        tapByNormalizedCenter(showSidebarButton)

        let closeSidebarByID = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4OverlayCloseSidebar"))
            .firstMatch
        let closeSidebarByLabel = app.buttons["Close sidebar"].firstMatch
        let closeSidebarElement = closeSidebarByID.waitForExistence(timeout: 1.0) ? closeSidebarByID : closeSidebarByLabel
        XCTAssertTrue(closeSidebarElement.waitForExistence(timeout: 1.0),
                      "overlay contract: close affordance should be exposed with explicit accessibility label")
        XCTAssertEqual(closeSidebarElement.label, "Close sidebar",
                       "overlay contract: close affordance should expose explicit accessibility label")
    }

    @MainActor
    func testL4_overlayAccessibility_sidebarContentHidden_afterDismiss() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Overlay Accessibility")

        let showSidebarButton = l4OverlayExpandSidebarElement()
        XCTAssertTrue(showSidebarButton.waitForExistence(timeout: 1.0),
                      "overlay contract: explicit expand affordance button should exist")
        tapByNormalizedCenter(showSidebarButton)

        let modalRoot = app.otherElements["L4OverlayModalRoot"].firstMatch
        XCTAssertTrue(modalRoot.waitForExistence(timeout: 1.0),
                      "overlay contract: modal root should be exposed while overlay is active before dismiss")

        let sidebarContentAny = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4OverlaySidebarContent"))
            .firstMatch
        XCTAssertTrue(sidebarContentAny.waitForExistence(timeout: 1.5),
                      "overlay contract: sidebar content should be exposed while overlay is active before dismiss")

        let closeSidebarByID = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4OverlayCloseSidebar"))
            .firstMatch
        let closeSidebarByLabel = app.buttons["Close sidebar"].firstMatch
        let closeSidebarButton: XCUIElement
        if closeSidebarByID.waitForExistence(timeout: 1.5) {
            closeSidebarButton = closeSidebarByID
        } else {
            XCTAssertTrue(closeSidebarByLabel.waitForExistence(timeout: 1.5),
                          "overlay contract: explicit close affordance should exist in overlay")
            closeSidebarButton = closeSidebarByLabel
        }

        tapByNormalizedCenter(closeSidebarButton)

        XCTAssertFalse(modalRoot.waitForExistence(timeout: 1.0),
                       "overlay contract: modal root should be removed after dismiss")
        XCTAssertFalse(sidebarContentAny.waitForExistence(timeout: 1.0),
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
        if copyById.waitForExistence(timeout: 2.5) {
            copyButton = copyById
        } else {
            XCTAssertTrue(copyByLabel.waitForExistence(timeout: 1.2),
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
        if printById.waitForExistence(timeout: 2.5) {
            printButton = printById
        } else {
            XCTAssertTrue(printByLabel.waitForExistence(timeout: 1.2),
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
            app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 1.0)
                || app.buttons["L4ContractSheet"].waitForExistence(timeout: 1.2),
            "platformPrint_L4: contract screen must be reachable after print (no stuck modal blocking the suite)"
        )
    }

    @MainActor
    func testL4_platformOpenURL_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ContractOpenURL")
        let openById = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4ContractOpenURL"))
            .firstMatch
        let openByLabel = app.buttons["L4ContractOpenURL"].firstMatch
        let openButton: XCUIElement
        if openById.waitForExistence(timeout: 2.5) {
            openButton = openById
        } else {
            XCTAssertTrue(openByLabel.waitForExistence(timeout: 1.2),
                          "platformOpenURL_L4: invocation surface button should exist with contract identifier/label")
            openButton = openByLabel
        }
        tapByNormalizedCenter(openButton)
        XCTAssertTrue(app.staticTexts["L4ContractOpenURLResult:true"].waitForExistence(timeout: 1.0),
                      "platformOpenURL_L4: invocation should produce deterministic contract result text")
    }

    @MainActor
    func testL4_platformRegisterForRemoteNotifications_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ContractRegisterRemoteNotifications")
        let registerById = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "L4ContractRegisterRemoteNotifications"))
            .firstMatch
        let registerByLabel = app.buttons["L4ContractRegisterRemoteNotifications"].firstMatch
        let registerButton: XCUIElement
        if registerById.waitForExistence(timeout: 2.5) {
            registerButton = registerById
        } else {
            XCTAssertTrue(registerByLabel.waitForExistence(timeout: 1.2),
                          "platformRegisterForRemoteNotifications_L4: invocation surface button should exist with contract identifier/label")
            registerButton = registerByLabel
        }
        tapByNormalizedCenter(registerButton)
        XCTAssertTrue(app.staticTexts["L4ContractRegisterRemoteNotificationsResult:true"].waitForExistence(timeout: 1.0),
                      "platformRegisterForRemoteNotifications_L4: invocation should produce deterministic contract result text")
    }

    @MainActor
    func testL4_platformCloudKitSyncStatus_L4() throws {
        ensureContractRoot()
        scrollToL4SystemCloudKitContracts()
        scrollToContractIdentifier("platformCloudKitSyncStatus_L4", maxAttempts: Self.maxL4SystemScrollAttempts)
        let exactId = element(matchingIdentifier: "platformCloudKitSyncStatus_L4")
        XCTAssertTrue(
            exactId.waitForExistence(timeout: 3.5),
            "platformCloudKitSyncStatus_L4: contract view must be on-screen with stable a11y identifier"
        )
        let idleContract =
            waitForCombinedAccessibilityLabel(containing: "CloudKit Sync: Idle", timeout: 2.0)
            || app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "CloudKit Sync: Idle")).firstMatch.waitForExistence(timeout: 1.5)
        XCTAssertTrue(
            idleContract,
            "platformCloudKitSyncStatus_L4: idle summary label should be exposed when visible"
        )
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitSyncStatus"))
            .firstMatch
        XCTAssertTrue(
            exactId.waitForExistence(timeout: 1.2) || containsId.waitForExistence(timeout: 2.0),
            "platformCloudKitSyncStatus_L4: view must have a11y identifier (contract a11y)"
        )
    }

    @MainActor
    func testL4_platformCloudKitProgress_L4() throws {
        ensureContractRoot()
        scrollToL4SystemCloudKitContracts()
        scrollToElement(label: "CloudKit Progress", maxAttempts: Self.maxL4SystemScrollAttempts)
        XCTAssertTrue(
            app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "60")).firstMatch.waitForExistence(timeout: 2.0),
            "platformCloudKitProgress_L4: progress caption must be visible (contract structure)"
        )
        XCTAssertTrue(
            waitForCombinedAccessibilityLabel(containing: "CloudKit Sync: Idle", timeout: 3.5)
                || app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "CloudKit Sync: Idle")).firstMatch.waitForExistence(timeout: 2.5),
            "platformCloudKitProgress_L4: nested sync status must be visible when status is provided"
        )
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitProgress_L4"))
            .firstMatch
        XCTAssertTrue(containsId.waitForExistence(timeout: 2.5),
                      "platformCloudKitProgress_L4: view must expose contract a11y identifier (contains platformCloudKitProgress_L4)")
    }

    @MainActor
    func testL4_platformCloudKitAccountStatus_L4() throws {
        ensureContractRoot()
        scrollToL4SystemCloudKitContracts()
        scrollToElement(label: "CloudKit Account", maxAttempts: Self.maxL4SystemScrollAttempts)
        let accountContract =
            waitForCombinedAccessibilityLabel(containing: "iCloud Account: Available", timeout: 3.5)
            || app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "iCloud Account")).firstMatch.waitForExistence(timeout: 2.5)
            || element(matchingIdentifier: "platformCloudKitAccountStatus_L4").waitForExistence(timeout: 2.5)
        XCTAssertTrue(
            accountContract,
            "platformCloudKitAccountStatus_L4: account label must be visible (contract structure)"
        )
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitAccountStatus_L4"))
            .firstMatch
        XCTAssertTrue(containsId.waitForExistence(timeout: 2.5),
                      "platformCloudKitAccountStatus_L4: view must expose contract a11y identifier")
    }

    @MainActor
    func testL4_platformCloudKitServiceStatus_L4() throws {
        ensureContractRoot()
        scrollToL4SystemCloudKitContracts()
        scrollToElement(label: "CloudKit Service Status", maxAttempts: Self.maxL4SystemScrollAttempts)
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitServiceStatus_L4"))
            .firstMatch
        XCTAssertTrue(containsId.waitForExistence(timeout: 3.0),
                      "platformCloudKitServiceStatus_L4: composite view must expose contract a11y identifier")
        let hasIdleOrAccount = waitForCombinedAccessibilityLabel(containing: "CloudKit Sync: Idle", timeout: 3.0)
            || waitForCombinedAccessibilityLabel(containing: "iCloud Account: Available", timeout: 2.5)
            || waitForCombinedAccessibilityLabel(containing: "iCloud Account: Unknown", timeout: 2.5)
            || waitForCombinedAccessibilityLabel(containing: "CloudKit service status", timeout: 2.0)
        XCTAssertTrue(
            hasIdleOrAccount,
            "platformCloudKitServiceStatus_L4: at least one child status line must be visible (contract structure)"
        )
    }

    @MainActor
    func testL4_platformCloudKitSyncButton_L4() throws {
        ensureContractRoot()
        scrollToL4SystemCloudKitContracts()
        scrollToElement(label: "CloudKit Sync Button", maxAttempts: Self.maxL4SystemScrollAttempts)
        let exactId = element(matchingIdentifier: "platformCloudKitSyncButton_L4")
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitSyncButton_L4"))
            .firstMatch
        XCTAssertTrue(
            exactId.waitForExistence(timeout: 3.0) || containsId.waitForExistence(timeout: 3.0),
            "platformCloudKitSyncButton_L4: button must expose contract a11y identifier"
        )
        let syncButton = app.descendants(matching: .button)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitSyncButton_L4"))
            .firstMatch
        let idNode = exactId.exists ? exactId : containsId
        XCTAssertTrue(
            syncButton.waitForExistence(timeout: 2.5)
                || (idNode.elementType == .button && idNode.exists),
            "platformCloudKitSyncButton_L4: sync control should appear as a button (may be disabled when CloudKit is gated in UITest host)"
        )
    }

    @MainActor
    func testL4_platformCloudKitStatusBadge_L4() throws {
        ensureContractRoot()
        scrollToL4SystemCloudKitContracts()
        scrollToElement(label: "CloudKit Status Badge", maxAttempts: Self.maxL4SystemScrollAttempts)
        let containsId = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitStatusBadge_L4"))
            .firstMatch
        let badgeBySummary = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "CloudKit status: idle"))
            .firstMatch
        XCTAssertTrue(
            containsId.waitForExistence(timeout: 2.5) || badgeBySummary.waitForExistence(timeout: 2.0),
            "platformCloudKitStatusBadge_L4: badge must expose contract a11y identifier or idle summary label"
        )
    }

    #if os(iOS)
    @MainActor
    func testL4_platformPhotoPicker_L4() throws {
        ensureContractRoot()
        scrollToL4SystemCloudKitContracts()
        scrollToContractIdentifier("L4ContractPhotoPickerOpen", maxAttempts: Self.maxL4SystemScrollAttempts)
        let openBtn = app.buttons["L4ContractPhotoPickerOpen"].firstMatch
        let openAny = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@ OR label == %@", "L4ContractPhotoPickerOpen", "L4ContractPhotoPickerOpen"))
            .firstMatch
        XCTAssertTrue(
            openBtn.waitForExistence(timeout: 3.0) || openAny.waitForExistence(timeout: 2.0),
            "platformPhotoPicker_L4: contract open control must exist (contract structure)"
        )
        let openControl = openBtn.exists ? openBtn : openAny
        tapByNormalizedCenter(openControl)
        let pickerNode = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformPhotoPicker_L4"))
            .firstMatch
        XCTAssertTrue(
            pickerNode.waitForExistence(timeout: 2.0),
            "platformPhotoPicker_L4: picker subtree must expose contract a11y identifier"
        )
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.waitForExistence(timeout: 1.2) {
            cancel.tap()
        } else if app.navigationBars.buttons["Cancel"].firstMatch.waitForExistence(timeout: 1.0) {
            app.navigationBars.buttons["Cancel"].firstMatch.tap()
        }
        XCTAssertTrue(
            app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 2.5)
                || app.buttons["L4ContractSheet"].waitForExistence(timeout: 1.5),
            "platformPhotoPicker_L4: must return to contract root after dismiss (no stuck sheet)"
        )
    }
    #endif

    @MainActor
    func testL4_platformPhotoDisplay_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "Photo Display")
        let photoView = app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformPhotoDisplay")).firstMatch
        XCTAssertTrue(photoView.waitForExistence(timeout: 2.5),
                      "platformPhotoDisplay_L4: view must have a11y identifier (contract a11y)")
    }
}
