//
//  SixLayerUITestNavigator.swift
//  SixLayerTestKit
//
//  Consumer UI test navigation primitives (#229).
//

#if canImport(XCTest)
import XCTest

/// Thin XCUI primitives composed over ``UITestContractElementResolver`` and contract identifiers (#229).
public final class SixLayerUITestNavigator: @unchecked Sendable {
    private let application: XCUIApplication
    private let resolverConfiguration: UITestContractElementResolverConfiguration
    private let findFirstExisting: (XCUIElement, UITestElementId, UITestContractElementResolverConfiguration) -> XCUIElement?

    /// Creates a navigator rooted at ``application`` using the default resolver behavior.
    public init(
        application: XCUIApplication,
        resolverConfiguration: UITestContractElementResolverConfiguration = .init()
    ) {
        self.application = application
        self.resolverConfiguration = resolverConfiguration
        self.findFirstExisting = { root, id, cfg in
            UITestContractElementResolver.findFirstExisting(under: root, elementId: id, configuration: cfg)
        }
    }

    /// Test hook: inject element resolution (e.g. record calls) without launching an app.
    internal init(
        application: XCUIApplication,
        resolverConfiguration: UITestContractElementResolverConfiguration = .init(),
        findFirstExisting: @escaping (XCUIElement, UITestElementId, UITestContractElementResolverConfiguration) -> XCUIElement?
    ) {
        self.application = application
        self.resolverConfiguration = resolverConfiguration
        self.findFirstExisting = findFirstExisting
    }

    /// Passthrough to ``UITestContractElementResolver/findFirstExisting`` under `root` or the app root.
    public func findContractElement(_ elementId: UITestElementId, under root: XCUIElement? = nil) -> XCUIElement? {
        nil
    }

    /// Ensures a screen contract is present (and taps it when hittable) using the same identifier resolution as elements.
    public func goToScreen(_ screenId: UITestScreenId, timeout: TimeInterval = 5.0) -> Bool {
        false
    }

    /// Opens a section identified by ``UITestRouteId`` within `root` or the application.
    public func openSection(_ routeId: UITestRouteId, under root: XCUIElement? = nil, timeout: TimeInterval = 5.0) -> Bool {
        false
    }

    /// Pops stacked navigation by tapping the leading navigation-bar control until it disappears or `maxSteps` is reached.
    ///
    /// - Returns: Number of successful back transitions performed.
    public func backToRoot(maxSteps: Int = 20, stepTimeout: TimeInterval = 2.0) -> Int {
        SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: maxSteps) {
            self.performSingleBackTap(stepTimeout: stepTimeout)
        }
    }

    private func performSingleBackTap(stepTimeout: TimeInterval) -> Bool {
        false
    }
}
#endif
