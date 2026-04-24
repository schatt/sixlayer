//
//  SixLayerUITestNavigator.swift
//  SixLayerTestKit
//
//  Consumer UI test navigation primitives (#229).
//  See also: Framework/docs/SixLayerUITestNavigator.md
//

#if canImport(XCTest)
import XCTest

/// Thin XCUI primitives composed over ``UITestContractElementResolver`` and contract identifiers (#229).
public final class SixLayerUITestNavigator: @unchecked Sendable {
    private let application: XCUIApplication
    private let resolverConfiguration: UITestContractElementResolverConfiguration
    private let findFirstExisting: (XCUIElement, UITestElementId, UITestContractElementResolverConfiguration) -> XCUIElement?
    private let backAttemptOverride: (() -> Bool)?

    /// Creates a navigator rooted at ``application`` using the default resolver behavior.
    public init(
        application: XCUIApplication,
        resolverConfiguration: UITestContractElementResolverConfiguration = .init()
    ) {
        self.application = application
        self.resolverConfiguration = resolverConfiguration
        self.backAttemptOverride = nil
        self.findFirstExisting = { root, id, cfg in
            UITestContractElementResolver.findFirstExisting(under: root, elementId: id, configuration: cfg)
        }
    }

    /// Test hook: inject element resolution (e.g. record calls) without a hosted UI test target.
    internal init(
        application: XCUIApplication,
        resolverConfiguration: UITestContractElementResolverConfiguration = .init(),
        findFirstExisting: @escaping (XCUIElement, UITestElementId, UITestContractElementResolverConfiguration) -> XCUIElement?,
        backAttemptOverride: (() -> Bool)? = nil
    ) {
        self.application = application
        self.resolverConfiguration = resolverConfiguration
        self.findFirstExisting = findFirstExisting
        self.backAttemptOverride = backAttemptOverride
    }

    /// Passthrough to ``UITestContractElementResolver/findFirstExisting`` under `root` or the app root.
    public func findContractElement(_ elementId: UITestElementId, under root: XCUIElement? = nil) -> XCUIElement? {
        let scope = root ?? application
        return findFirstExisting(scope, elementId, resolverConfiguration)
    }

    /// Ensures a screen contract is present (and taps it when hittable) using identifier resolution.
    public func goToScreen(_ screenId: UITestScreenId, timeout: TimeInterval = 5.0) -> Bool {
        guard let elementId = try? UITestElementId(validating: screenId.rawValue),
              let element = findFirstExisting(application, elementId, resolverConfiguration),
              element.waitForExistence(timeout: timeout) else { return false }
        if element.isHittable { element.tap() }
        return element.exists
    }

    /// Opens a section identified by ``UITestRouteId`` within `root` or the application.
    public func openSection(_ routeId: UITestRouteId, under root: XCUIElement? = nil, timeout: TimeInterval = 5.0) -> Bool {
        let scope = root ?? application
        guard let elementId = try? UITestElementId(validating: routeId.rawValue),
              let element = findFirstExisting(scope, elementId, resolverConfiguration),
              element.waitForExistence(timeout: timeout) else { return false }
        if element.isHittable { element.tap() }
        return element.exists
    }

    /// Pops stacked navigation by tapping the leading navigation-bar control until it disappears or `maxSteps` is reached.
    ///
    /// Uses the **first** button of the **first** navigation bar (common iOS push stack convention). macOS hosts with
    /// different chrome may need a custom ``backAttemptOverride`` via the internal test initializer.
    ///
    /// - Returns: Number of successful back transitions performed.
    public func backToRoot(maxSteps: Int = 20, stepTimeout: TimeInterval = 2.0) -> Int {
        let attemptBack: () -> Bool = {
            if let override = self.backAttemptOverride {
                return override()
            }
            return self.performSingleBackTap(stepTimeout: stepTimeout)
        }
        return SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: maxSteps, attemptBack: attemptBack)
    }

    private func performSingleBackTap(stepTimeout: TimeInterval) -> Bool {
        let navBar = application.navigationBars.firstMatch
        guard navBar.waitForExistence(timeout: stepTimeout) else { return false }
        let leading = navBar.buttons.element(boundBy: 0)
        guard leading.waitForExistence(timeout: stepTimeout), leading.isHittable else { return false }
        leading.tap()
        return true
    }
}
#endif
