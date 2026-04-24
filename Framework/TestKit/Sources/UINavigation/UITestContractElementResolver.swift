//
//  UITestContractElementResolver.swift
//  SixLayerTestKit
//
//  XCUIElement contract resolution using deterministic fallback ordering (#228).
//

import XCTest

extension UITestContractXCUIQuerySlot {
    /// Maps a contract slot to the XCUIElement query axis used under a root element.
    public var xcElementType: XCUIElement.ElementType {
        switch self {
        case .button: .button
        case .cell: .cell
        case .link: .link
        case .staticText: .staticText
        case .image: .image
        case .toggle: .switch
        case .other: .other
        }
    }
}

/// Identifier-first XCUI lookup with deterministic cross-platform fallback ordering.
///
/// See ``UITestContractXCUIQuerySlot/contractResolutionOrder`` and `Framework/docs/UITestContractElementResolver.md`.
public enum UITestContractElementResolver {
    /// Walks ``slots`` in order, returning the first element matching `elementId` that becomes hittable within the per-slot timeout.
    ///
    /// - Parameters:
    ///   - root: Search root (often `XCUIApplication` or a container).
    ///   - elementId: Validated contract identifier (accessibility identifier).
    ///   - slots: Fallback sequence; defaults to ``UITestContractXCUIQuerySlot/contractResolutionOrder``.
    ///   - configuration: Per-slot wait budget (see ``UITestContractElementResolverConfiguration``).
    /// - Returns: First matching element, or `nil` if no slot produced a matching element in time.
    public static func findFirstExisting(
        under root: XCUIElement,
        elementId: UITestElementId,
        slots: [UITestContractXCUIQuerySlot] = UITestContractXCUIQuerySlot.contractResolutionOrder,
        configuration: UITestContractElementResolverConfiguration = .init()
    ) -> XCUIElement? {
        UITestContractElementResolverCore.firstResolved(
            slots: slots,
            elementId: elementId,
            timeoutPerSlot: configuration.timeoutPerSlot,
            materialize: { slot in
                root.descendants(matching: slot.xcElementType)
                    .matching(identifier: elementId.rawValue)
                    .element
            },
            exists: { element, timeout in
                element.waitForExistence(timeout: timeout)
            }
        )?.match
    }
}
