//
//  XCUITestHelpers.swift
//  SixLayerFrameworkUITests
//
//  Performance optimization helpers for XCUITest
//  These utilities help reduce test execution time by optimizing app launch,
//  element queries, and accessibility hierarchy snapshots
//

import XCTest

private enum XCUITestFailFast {
    static let quickWait: TimeInterval = 0.3
    static let mediumWait: TimeInterval = 0.75
    static let launchReadyWait: TimeInterval = 2.0
    static let maxScrollAttempts = 5
}

// MARK: - XCUIApplication Extensions

extension XCUIApplication {
    /// Configure app for fast UI testing
    /// Sets launch arguments and environment variables to skip slow initialization
    func configureForFastTesting() {
        // Skip animations to speed up UI interactions
        launchArguments = ["-UITesting", "-SkipAnimations"]
        
        // Set environment variable to indicate we're in UI testing mode
        // This allows the app to skip slow initialization paths
        launchEnvironment = ["XCUI_TESTING": "1"]
    }
    
    /// Wait for app to be ready: look for a single known text on the launch page (Issue #180).
    /// - Parameter timeout: Maximum time to wait (default: 2.5 seconds; fail fast when launch list is wrong)
    /// - Returns: true if the text appears, false if timeout
    func waitForReady(timeout: TimeInterval = 2.5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if staticTexts["UI Test Views"].exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(XCUITestFailFast.quickWait))
        }
        return false
    }
    
    /// Launch app with performance optimizations
    /// Configures app for fast testing and launches it
    func launchWithOptimizations() {
        configureForFastTesting()
        launch()
    }

    // MARK: - Issue #193 — Form / table scroll hosts

    /// iOS `Form` is backed by a table; swiping the first `scrollView` often does not scroll form rows.
    /// When multiple `tables` exist, `firstMatch` is often a nested list (e.g. L4 overlay split), not the root `Form` — use the last table.
    /// When multiple `scrollViews` exist (e.g. navigation chrome + content), prefer the last scroll view for the main list.
    func xcuiPrimaryScrollHost() -> XCUIElement {
        let tbls = tables
        if tbls.count > 1 {
            return tbls.element(boundBy: tbls.count - 1)
        }
        if tbls.firstMatch.exists { return tbls.firstMatch }
        let svs = scrollViews
        if svs.count > 1 {
            return svs.element(boundBy: svs.count - 1)
        }
        if svs.firstMatch.exists { return svs.firstMatch }
        return windows.firstMatch
    }

    /// Scroll the primary content up: prefers table(s); when two tables exist, swipes both outer and inner; otherwise swipes `xcuiPrimaryScrollHost()`.
    func xcuiSwipeScrollHostsUp() {
        xcuiSwipePrimaryContent(up: true)
    }

    /// Mirror of ``xcuiSwipeScrollHostsUp()`` for scrolling toward the top of Form/table content (e.g. `ensureContractRoot`).
    func xcuiSwipeScrollHostsDown() {
        xcuiSwipePrimaryContent(up: false)
    }

    /// iOS 26 SwiftUI `Form` often reports `tables.count == 0` while `tables.firstMatch` exists; window swipes do not move rows (#261).
    private func xcuiSwipePrimaryContent(up: Bool) {
        func swipe(_ element: XCUIElement) {
            if up { element.swipeUp() } else { element.swipeDown() }
        }

        let tbls = tables
        let tableCount = tbls.count
        if tableCount > 1 {
            swipe(tbls.element(boundBy: tableCount - 1))
            swipe(tbls.element(boundBy: 0))
            return
        }
        if tableCount == 1 {
            swipe(tbls.element(boundBy: 0))
            return
        }

        let cols = collectionViews
        let collectionCount = cols.count
        // Root `Form` is usually the outermost list; a lone CollectionView is often overlay split (#261).
        if collectionCount > 1 {
            swipe(cols.element(boundBy: collectionCount - 1))
            return
        }
        if collectionCount == 1 {
            if tbls.element(boundBy: 0).exists {
                swipe(tbls.element(boundBy: 0))
                return
            }
            xcuiDragScrollContent(up: up)
            return
        }

        let svs = scrollViews
        let scrollCount = svs.count
        if scrollCount > 1 {
            swipe(svs.element(boundBy: scrollCount - 1))
            return
        }
        if scrollCount == 1 {
            swipe(svs.element(boundBy: 0))
            return
        }

        // `count == 0`: latent hosts — prefer table/outer collection before overlay inner lists.
        let latentHosts: [XCUIElement] = [
            tbls.element(boundBy: 0),
            tbls.element(boundBy: 1),
            cols.element(boundBy: 1),
            cols.element(boundBy: 0),
            svs.element(boundBy: 1),
            svs.element(boundBy: 0),
            tbls.firstMatch,
            cols.firstMatch,
            svs.firstMatch,
        ]
        for host in latentHosts where host.exists {
            swipe(host)
            return
        }
        swipe(tbls.element(boundBy: 0))
        xcuiDragScrollContent(up: up)
    }

    /// Coordinate drag when element `swipeUp`/`swipeDown` hits Window and does not move Form rows (#261).
    private func xcuiDragScrollContent(up: Bool) {
        let win = windows.firstMatch
        guard win.exists else { return }
        let startY: CGFloat = up ? 0.78 : 0.22
        let endY: CGFloat = up ? 0.28 : 0.72
        let start = win.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
        let end = win.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: endY))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    /// Swipe down on the software keyboard when present so the next `Form` row can scroll above the
    /// keyboard and accept first responder (Issue #150 / iOS 26 UITest flakes; Refs #261).
    func xcuiDismissSoftwareKeyboardIfPresent() {
        #if os(iOS)
        let board = keyboards.firstMatch
        guard board.exists else { return }
        board.swipeDown()
        let deadline = Date().addingTimeInterval(2.5)
        while keyboards.firstMatch.exists, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        #endif
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Fast wait for existence with shorter default timeout
    /// Use this for elements that should exist immediately after app is ready
    /// - Parameter timeout: Maximum time to wait (default: 0.5 seconds)
    /// - Returns: true if element exists, false if timeout
    func waitForExistenceFast(timeout: TimeInterval = 0.5) -> Bool {
        return waitForExistence(timeout: timeout)
    }
    
    /// Check if element exists without waiting
    /// Use this before waitForExistence to avoid unnecessary waits
    /// - Returns: true if element exists immediately
    var existsImmediately: Bool {
        return exists
    }

    /// Wait for this element to become not hittable (e.g. menu/popover dismissed).
    /// Polls until the element is not hittable or timeout. Use after tapping a menu option to ensure the menu is gone before the next interaction.
    /// - Parameter timeout: Maximum time to wait (default: 3.0 seconds)
    /// - Returns: true if element became not hittable (or no longer exists), false if timeout
    func waitForNotHittable(timeout: TimeInterval = 3.0) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !exists || !isHittable {
                return true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return !exists || !isHittable
    }

    /// Tap to become first responder; uses a coordinate tap when `Form` chrome clips hittability.
    /// On iOS, secure fields often need a second tap before `typeText` receives keyboard focus (#150 / iOS 26).
    /// For switches, prefer the trailing thumb region when the control is not hittable.
    func xcuiTapToBecomeFirstResponder() {
        let center = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        #if os(iOS)
        if elementType == .secureTextField {
            center.tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            center.tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            return
        }
        if elementType == .switch {
            if isHittable {
                tap()
            } else {
                coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            return
        }
        #endif
        if isHittable {
            tap()
        } else {
            center.tap()
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }
}

// MARK: - Accessibility Identifier Helpers

extension XCUIElement {
    /// Find an element by accessibility identifier within this element, trying multiple query types
    /// - Parameters:
    ///   - identifier: The accessibility identifier to search for
    ///   - primaryType: Primary element type to try first (default: .other)
    ///   - secondaryTypes: Additional element types to try if primary fails
    ///   - timeout: Maximum time to wait for each query type
    /// - Returns: The found element, or nil if not found
    /// - Note: Includes .cell so List/Form rows on iOS (exposed as cells) are findable by identifier.
    func findElement(byIdentifier identifier: String, 
                    primaryType: XCUIElement.ElementType = .other,
                    secondaryTypes: [XCUIElement.ElementType] = [.button, .cell, .staticText, .any],
                    timeout: TimeInterval = 1.0) -> XCUIElement? {
        // Strategy 1: Try primary type first (most common case)
        let primaryElement = descendants(matching: primaryType)[identifier]
        if primaryElement.waitForExistence(timeout: timeout) {
            return primaryElement
        }
        
        // Strategy 2: Try secondary types (adapts to platform differences)
        for elementType in secondaryTypes {
            let element = descendants(matching: elementType)[identifier]
            if element.waitForExistence(timeout: 0.5) {
                return element
            }
        }
        
        // Strategy 3: Try any element as last resort (catches edge cases)
        let anyElement = descendants(matching: .any)[identifier]
        if anyElement.waitForExistence(timeout: 0.3) {
            return anyElement
        }
        
        return nil
    }
}

// MARK: - Accessibility contract verification (DRY)

/// When automaticCompliance is in the chain (e.g. called by a layer or platformButton),
/// we must ensure the correct a11y is present. Requirements differ by element type
/// (e.g. image vs text field): interactive controls need a label; meaningful images
/// need a label; decorative images may not.
///
/// **Pickers:** Per Apple requirements, the picker control must have an identifier and label; options alone do not suffice.
/// When testing a picker, always use verifyPickerAccessibilityContract so the picker itself is asserted first, then option identifiers if provided.
extension XCUIElement {

    /// Whether this element type normally requires an accessibility label when automaticCompliance is applied.
    /// - Parameter type: The expected element type.
    /// - Returns: true for interactive controls (button, textField, switch, slider, link); false for image/other by default.
    private static func labelRequiredForType(_ type: XCUIElement.ElementType) -> Bool {
        switch type {
        case .button, .textField, .switch, .slider, .link:
            return true
        default:
            return false
        }
    }

    /// Verify picker a11y contract per Apple requirements: the picker control MUST have an identifier and label;
    /// having only option elements with IDs does not meet requirements. Option elements must also have identifiers.
    /// Call on the picker element (e.g. the menu button). Option identifiers are often only in the hierarchy when the picker is open.
    /// - Parameters:
    ///   - pickerElementName: Name for failure messages.
    ///   - expectedOptionIdentifiers: Optional list of accessibility identifiers for the picker's options. When provided, asserts each exists. Open the picker first if options are only visible when expanded.
    func verifyPickerAccessibilityContract(
        pickerElementName: String,
        expectedOptionIdentifiers: [String]? = nil
    ) {
        XCTAssertFalse(identifier.isEmpty,
                       "\(pickerElementName): Picker must have accessibility identifier (Apple requirement). Options alone are not sufficient. Found: '\(identifier)'")
        XCTAssertFalse(label.isEmpty,
                       "\(pickerElementName): Picker must have accessibility label (Apple requirement). Found: '\(label)'")
        guard let optionIds = expectedOptionIdentifiers else { return }
        for optionId in optionIds {
            let el = descendants(matching: .any)[optionId].firstMatch
            if !el.waitForExistence(timeout: 1.0) {
                let app = XCUIApplication()
                let anywhere = app.descendants(matching: .any)[optionId].firstMatch
                XCTAssertTrue(anywhere.waitForExistence(timeout: 1.0),
                              "\(pickerElementName) picker option '\(optionId)' should have accessibility identifier (open picker if options are in a menu)")
            }
        }
    }

    /// Verify the full a11y contract for this element type. Use this when automaticCompliance is in the chain.
    /// - Parameters:
    ///   - elementName: Name for failure messages.
    ///   - expectedType: The expected element type (traits).
    ///   - requireLabel: Override label requirement. When nil, uses type default: required for button, textField, switch, slider, link; not for image/staticText (pass true for meaningful images).
    func verifyAccessibilityContract(
        elementName: String,
        expectedType: XCUIElement.ElementType,
        requireLabel: Bool? = nil
    ) {
        XCTAssertFalse(identifier.isEmpty,
                       "\(elementName) should have accessibility identifier. Found: '\(identifier)'")
        XCTAssertEqual(elementType, expectedType,
                       "\(elementName) should have correct accessibility trait. Expected: \(expectedType), Found: \(elementType)")
        let needsLabel = requireLabel ?? Self.labelRequiredForType(expectedType)
        if needsLabel {
            XCTAssertFalse(label.isEmpty,
                           "\(elementName) should have accessibility label for type \(expectedType). Found: '\(label)'")
        }
    }

    /// Verify the element has a non-empty accessibility identifier.
    func verifyAccessibilityIdentifier(elementName: String) {
        XCTAssertFalse(identifier.isEmpty,
                       "\(elementName) should have accessibility identifier. Found: '\(identifier)'")
    }

    /// Verify the element has a non-empty accessibility label. Use for interactive elements (button, textField, switch, slider) or meaningful images.
    /// For type-specific contracts, use verifyAccessibilityContract(elementName:expectedType:requireLabel:) instead.
    func verifyAccessibilityLabel(elementName: String) {
        let needsLabel = elementType == .button || elementType == .textField
            || elementType == .switch || elementType == .slider
        if needsLabel {
            XCTAssertFalse(label.isEmpty,
                           "\(elementName) interactive element should have accessibility label. Found: '\(label)'")
        }
    }

    /// Verify the element has the expected accessibility trait (element type).
    func verifyAccessibilityTraits(elementName: String, expectedType: XCUIElement.ElementType) {
        XCTAssertEqual(elementType, expectedType,
                       "\(elementName) should have correct accessibility trait. Expected: \(expectedType), Found: \(elementType)")
    }
}

extension XCUIApplication {
    /// Find a launch-page list entry by identifier (iOS List rows may be .cell, not .button).
    func findLaunchPageEntry(identifier: String) -> XCUIElement {
        findElement(byIdentifier: identifier,
                    primaryType: .button,
                    secondaryTypes: [.link, .cell, .staticText, .other, .any])
            ?? buttons[identifier]
    }

    /// Navigate back to the launch page (e.g. after another test left the app on a subpage). Taps back/nav until "UI Test Views" appears.
    /// - Parameter timeout: Maximum time to wait for launch page (default 2.5; bounded back navigation)
    /// - Returns: true if launch page is visible (staticTexts["UI Test Views"] exists)
    func navigateBackToLaunch(timeout: TimeInterval = 2.5) -> Bool {
        if staticTexts["UI Test Views"].waitForExistence(timeout: XCUITestFailFast.quickWait) { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if buttons["UI Test Views"].waitForExistence(timeout: XCUITestFailFast.quickWait) {
                buttons["UI Test Views"].tap()
                return staticTexts["UI Test Views"].waitForExistence(timeout: XCUITestFailFast.mediumWait)
            }
            if navigationBars.buttons.firstMatch.waitForExistence(timeout: XCUITestFailFast.quickWait) {
                navigationBars.buttons.firstMatch.tap()
            } else if buttons["Back"].waitForExistence(timeout: XCUITestFailFast.quickWait) {
                buttons["Back"].tap()
            } else {
                break
            }
            if staticTexts["UI Test Views"].waitForExistence(timeout: XCUITestFailFast.mediumWait) { return true }
        }
        return staticTexts["UI Test Views"].waitForExistence(timeout: XCUITestFailFast.quickWait)
    }

    /// Navigate from the launch page to a "Layer N Examples" screen by tapping the given link.
    /// Use for Layer 2, 3, 5, 6 examples (shared pattern: ensure launch → find link → tap → wait for nav bar and content).
    /// - Parameters:
    ///   - linkIdentifier: Accessibility identifier of the launch-page link (e.g. "layer2-examples-link").
    ///   - navigationBarTitle: Title of the destination navigation bar (e.g. "Layer 2 Examples").
    ///   - linkLabel: Optional visible label to tap if identifier lookup fails (e.g. "Layer 4 Component Examples").
    /// - Returns: true if navigation succeeded (nav bar and list content visible).
    func navigateToLayerExamples(linkIdentifier: String, navigationBarTitle: String, linkLabel: String? = nil) -> Bool {
        func layerExamplesDestinationReached() -> Bool {
            let navBarExists = navigationBars[navigationBarTitle].waitForExistence(timeout: XCUITestFailFast.mediumWait)
            let contentExists = buttons.firstMatch.waitForExistence(timeout: XCUITestFailFast.quickWait)
                || staticTexts.firstMatch.waitForExistence(timeout: XCUITestFailFast.quickWait)
                || cells.firstMatch.waitForExistence(timeout: XCUITestFailFast.quickWait)
            if navBarExists && contentExists { return true }
            if staticTexts[navigationBarTitle].waitForExistence(timeout: XCUITestFailFast.quickWait) && contentExists { return true }
            return false
        }

        /// Prefer `links[visibleTitle]` for reliable navigation; row nodes may be `.cell` / `.button` by OS.
        /// Scroll with `xcuiSwipeScrollHostsUp()` so root `Form` / list tables move (Issue #193).
        let navigationLinkTitle: String? = linkLabel ?? {
            switch linkIdentifier {
            case "layer2-examples-link": return "Layer 2 Layout Examples"
            case "layer3-examples-link": return "Layer 3 Strategy Examples"
            case "layer4-examples-link": return "Layer 4 Component Examples"
            case "layer5-examples-link": return "Layer 5 Optimization Examples"
            case "layer6-examples-link": return "Layer 6 System Examples"
            default: return nil
            }
        }()

        _ = navigateBackToLaunch(timeout: XCUITestFailFast.launchReadyWait)
        guard waitForReady(timeout: XCUITestFailFast.launchReadyWait) else { return false }

        if let title = navigationLinkTitle {
            for _ in 0..<XCUITestFailFast.maxScrollAttempts {
                let rowLink = links[title].firstMatch
                if rowLink.waitForExistence(timeout: XCUITestFailFast.quickWait) && rowLink.isHittable {
                    rowLink.tap()
                    return layerExamplesDestinationReached()
                }
                xcuiSwipeScrollHostsUp()
            }
        }

        // Fallback: identifier-based (callers on unusual rows or when link query fails)
        if linkIdentifier.contains("layer4") || linkIdentifier.contains("layer5") || linkIdentifier.contains("layer6") {
            for _ in 0..<5 {
                xcuiSwipeScrollHostsUp()
                let found = findLaunchPageEntry(identifier: linkIdentifier)
                if found.waitForExistence(timeout: XCUITestFailFast.quickWait) && found.isHittable { break }
            }
        }
        var link = findLaunchPageEntry(identifier: linkIdentifier)
        if !link.waitForExistence(timeout: XCUITestFailFast.mediumWait), let label = navigationLinkTitle {
            link = links[label].firstMatch
            if !link.exists { link = buttons[label].firstMatch }
            if !link.exists { link = staticTexts[label].firstMatch }
            if !link.exists { link = cells[label].firstMatch }
        }
        var attempts = 0
        while !link.waitForExistence(timeout: XCUITestFailFast.quickWait), attempts < 3 {
            xcuiSwipeScrollHostsUp()
            attempts += 1
            link = findLaunchPageEntry(identifier: linkIdentifier)
            if !link.waitForExistence(timeout: XCUITestFailFast.quickWait), let label = navigationLinkTitle {
                link = links[label].firstMatch
                if !link.exists { link = buttons[label].firstMatch }
                if !link.exists { link = staticTexts[label].firstMatch }
                if !link.exists { link = cells[label].firstMatch }
            }
        }
        guard link.waitForExistence(timeout: XCUITestFailFast.mediumWait) else { return false }
        link.tap()
        return layerExamplesDestinationReached()
    }

    /// Runs compatibility-oriented checks on the **current** screen only (Issue #180).
    ///
    /// Call after navigating to a subview; do **not** use on the bare launch list. Waits are implicit via
    /// `exists` / `waitForExistence` at call sites before sweeping.
    ///
    /// One pass per query axis (`buttons`, `textFields`, `switches`, `sliders`, `staticTexts`). For each element,
    /// runs VoiceOver reachability, readable identity (shared proxy for Dynamic Type readiness and semantic / HC-friendly
    /// naming), and Switch Control–relevant type checks on interactive controls.
    func runAccessibilityCompatibilitySweep(screenLabel: String, file: StaticString = #filePath, line: UInt = #line) {
        let maxPerAxis = 80

        func hint(_ element: XCUIElement) -> String {
            if !element.label.isEmpty { return element.label }
            if !element.identifier.isEmpty { return element.identifier }
            return String(describing: element.elementType)
        }

        let buttonsAxis = buttons.allElementsBoundByIndex
        for i in 0..<min(buttonsAxis.count, maxPerAxis) {
            let element = buttonsAxis[i]
            guard element.exists else { continue }
            let h = hint(element)
            XCTAssertTrue(
                element.isHittable || element.isEnabled,
                "\(screenLabel): button \"\(h)\" should be reachable for VoiceOver",
                file: file,
                line: line
            )
            XCTAssertTrue(
                !element.label.isEmpty || !element.identifier.isEmpty,
                "\(screenLabel): button \"\(h)\" should expose label or identifier (VoiceOver / Dynamic Type readiness)",
                file: file,
                line: line
            )
            XCTAssertEqual(
                element.elementType,
                .button,
                "\(screenLabel): button \"\(h)\" should surface as .button for Switch Control routing",
                file: file,
                line: line
            )
        }

        let textFieldsAxis = textFields.allElementsBoundByIndex
        for i in 0..<min(textFieldsAxis.count, maxPerAxis) {
            let element = textFieldsAxis[i]
            guard element.exists else { continue }
            let h = hint(element)
            XCTAssertTrue(
                element.isHittable || element.isEnabled,
                "\(screenLabel): text field \"\(h)\" should be reachable for VoiceOver",
                file: file,
                line: line
            )
            XCTAssertTrue(
                !element.label.isEmpty || !element.identifier.isEmpty,
                "\(screenLabel): text field \"\(h)\" should expose label or identifier",
                file: file,
                line: line
            )
            XCTAssertEqual(
                element.elementType,
                .textField,
                "\(screenLabel): text field \"\(h)\" should surface as .textField for Switch Control routing",
                file: file,
                line: line
            )
        }

        let switchesAxis = switches.allElementsBoundByIndex
        for i in 0..<min(switchesAxis.count, maxPerAxis) {
            let element = switchesAxis[i]
            guard element.exists else { continue }
            let h = hint(element)
            XCTAssertTrue(
                element.isHittable || element.isEnabled,
                "\(screenLabel): switch \"\(h)\" should be reachable for VoiceOver",
                file: file,
                line: line
            )
            XCTAssertTrue(
                !element.label.isEmpty || !element.identifier.isEmpty,
                "\(screenLabel): switch \"\(h)\" should expose label or identifier",
                file: file,
                line: line
            )
            XCTAssertEqual(
                element.elementType,
                .switch,
                "\(screenLabel): switch \"\(h)\" should surface as .switch for Switch Control routing",
                file: file,
                line: line
            )
        }

        let slidersAxis = sliders.allElementsBoundByIndex
        for i in 0..<min(slidersAxis.count, maxPerAxis) {
            let element = slidersAxis[i]
            guard element.exists else { continue }
            let h = hint(element)
            XCTAssertTrue(
                element.isHittable || element.isEnabled,
                "\(screenLabel): slider \"\(h)\" should be reachable for VoiceOver",
                file: file,
                line: line
            )
            XCTAssertTrue(
                !element.label.isEmpty || !element.identifier.isEmpty,
                "\(screenLabel): slider \"\(h)\" should expose label or identifier",
                file: file,
                line: line
            )
            XCTAssertEqual(
                element.elementType,
                .slider,
                "\(screenLabel): slider \"\(h)\" should surface as .slider for Switch Control routing",
                file: file,
                line: line
            )
        }

        let statics = staticTexts.allElementsBoundByIndex
        for i in 0..<min(statics.count, maxPerAxis) {
            let element = statics[i]
            guard element.exists else { continue }
            if element.label.isEmpty && element.identifier.isEmpty { continue }
            let h = hint(element)
            if !element.label.isEmpty {
                XCTAssertFalse(
                    element.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "\(screenLabel): static text \"\(h)\" label should not be whitespace-only (VoiceOver / Dynamic Type)",
                    file: file,
                    line: line
                )
            }
            if !element.identifier.isEmpty {
                XCTAssertFalse(
                    element.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "\(screenLabel): static text \"\(h)\" identifier should not be whitespace-only",
                    file: file,
                    line: line
                )
            }
        }
    }

}

extension XCUIApplication {
    /// Select a segment in the segmented picker (handles platform differences)
    /// Uses platform-specific strategies based on how segmented pickers are exposed
    /// - Parameter segmentName: Name of the segment to select (e.g., "Text", "Button")
    /// - Returns: true if segment was found and selected, false otherwise
    func selectPickerSegment(_ segmentName: String) -> Bool {
        // First, try to find by accessibility identifier (works if segments have identifiers)
        // This is the most reliable method when segments have explicit identifiers
        if let segmentElement = findElement(byIdentifier: segmentName,
                                           primaryType: .button,
                                           secondaryTypes: [.staticText, .any]) {
            segmentElement.tap()
            return true
        }
        
        #if os(iOS)
        // On iOS, segmented picker exposes segments as buttons directly
        let segmentButton = buttons[segmentName]
        if segmentButton.waitForExistence(timeout: 1.0) {
            segmentButton.tap()
            return true
        }
        return false
        
        #elseif os(tvOS)
        // On tvOS, segmented picker exposes segments as buttons (similar to iOS)
        let segmentButton = buttons[segmentName]
        if segmentButton.waitForExistence(timeout: 1.0) {
            segmentButton.tap()
            return true
        }
        return false
        
        #elseif os(watchOS)
        // On watchOS, segmented picker exposes segments as buttons (similar to iOS)
        let segmentButton = buttons[segmentName]
        if segmentButton.waitForExistence(timeout: 1.0) {
            segmentButton.tap()
            return true
        }
        return false
        
        #elseif os(visionOS)
        // On visionOS, segmented picker exposes segments as buttons (similar to iOS)
        let segmentButton = buttons[segmentName]
        if segmentButton.waitForExistence(timeout: 1.0) {
            segmentButton.tap()
            return true
        }
        return false
        
        #elseif os(macOS)
        // On macOS, try to find within SegmentedControl or Picker
        // Try SegmentedControl first
        let segmentedControl = segmentedControls.firstMatch
        if segmentedControl.waitForExistence(timeout: 1.0) {
            // Try to find segment by identifier within the segmented control
            if let segmentElement = segmentedControl.findElement(byIdentifier: segmentName,
                                                                primaryType: .button,
                                                                secondaryTypes: [.staticText, .any]) {
                segmentElement.tap()
                return true
            }
            
            // Fallback: try by label
            let segmentButton = segmentedControl.buttons[segmentName]
            if segmentButton.waitForExistence(timeout: 0.5) {
                segmentButton.tap()
                return true
            }
        }
        
        // Try Picker
        let picker = pickers.firstMatch
        if picker.waitForExistence(timeout: 1.0) {
            // Try to find segment by identifier within the picker
            if let segmentElement = picker.findElement(byIdentifier: segmentName,
                                                      primaryType: .button,
                                                      secondaryTypes: [.staticText, .any]) {
                segmentElement.tap()
                return true
            }
            
            // Fallback: try by label
            let segmentButton = picker.buttons[segmentName]
            if segmentButton.waitForExistence(timeout: 0.5) {
                segmentButton.tap()
                return true
            }
        }
        
        // Try app-level buttons (segments might be at app level)
        let appLevelButton = buttons[segmentName]
        if appLevelButton.waitForExistence(timeout: 0.5) {
            appLevelButton.tap()
            return true
        }
        
        // If nothing works, segments are not accessible
        return false
        
        #else
        // Unsupported platform
        print("ERROR: selectPickerSegment not implemented for this platform")
        return false
        #endif
    }
}

// MARK: - Performance Logging

/// Performance measurement utilities for XCUITest
enum XCUITestPerformance {
    /// Measure time taken for an operation
    /// - Parameter operation: The operation to measure
    /// - Returns: Time taken in seconds
    static func measure<T>(_ operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try operation()
        let time = Date().timeIntervalSince(startTime)
        return (result, time)
    }
    
    /// Measure time taken for an async operation
    /// - Parameter operation: The async operation to measure
    /// - Returns: Time taken in seconds
    static func measureAsync<T>(_ operation: () async throws -> T) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let time = Date().timeIntervalSince(startTime)
        return (result, time)
    }
    
    /// Log performance metric
    /// - Parameters:
    ///   - label: Description of what was measured
    ///   - time: Time taken in seconds
    static func log(_ label: String, time: TimeInterval) {
        let milliseconds = Int(time * 1000)
        print("⏱️  [XCUITest Performance] \(label): \(milliseconds)ms")
    }
}

// MARK: - Shared UI interruption monitor (DRY for test setUp)

extension XCTestCase {
    /// Add the standard UI interruption monitor that dismisses system alerts (Bluetooth, CPU, Activity Monitor, etc.).
    /// Call once from setUp in UI test classes. Single implementation so behavior is consistent and changes are in one place.
    func addDefaultUIInterruptionMonitor() {
        addUIInterruptionMonitor(withDescription: "System alerts and dialogs") { (alert) -> Bool in
            return MainActor.assumeIsolated {
                // Avoid querying alert descendants here; on newer runtimes this can throw
                // snapshot type-mismatch errors for SwiftUI accessibility nodes.
                let alertText = alert.label
                guard alertText.contains("Bluetooth") || alertText.contains("CPU") || alertText.contains("Activity Monitor") else {
                    return false
                }
                if alert.buttons["OK"].exists { alert.buttons["OK"].tap(); return true }
                if alert.buttons["Cancel"].exists { alert.buttons["Cancel"].tap(); return true }
                if alert.buttons["Don't Allow"].exists { alert.buttons["Don't Allow"].tap(); return true }
                return false
            }
        }
    }
}
