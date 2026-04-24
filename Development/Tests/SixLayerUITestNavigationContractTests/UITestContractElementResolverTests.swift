//
//  UITestContractElementResolverTests.swift
//  SixLayerUITestNavigationContractTests
//
//  Cross-platform contract element resolver (#228).
//

import XCTest
@testable import SixLayerTestKit

final class UITestContractElementResolverTests: XCTestCase {

    func testContractResolutionOrder_isStableDocumentedFallback() {
        XCTAssertEqual(
            UITestContractXCUIQuerySlot.contractResolutionOrder,
            [.button, .cell, .link, .staticText, .image, .toggle, .other]
        )
    }

    func testResolverCore_invokesMaterializeInOrderUntilExists() throws {
        let id = try UITestElementId(validating: "com.example.control")
        var materializeLog: [UITestContractXCUIQuerySlot] = []
        let slots = UITestContractXCUIQuerySlot.contractResolutionOrder

        let result = UITestContractElementResolverCore.firstResolved(
            slots: slots,
            elementId: id,
            timeoutPerSlot: 0.05,
            materialize: { slot in
                materializeLog.append(slot)
                return slot
            },
            exists: { value, _ in value == UITestContractXCUIQuerySlot.cell }
        )

        XCTAssertEqual(result?.slot, .cell)
        XCTAssertEqual(result?.match, .cell)
        XCTAssertEqual(materializeLog, [.button, .cell])
    }

    func testResolverCore_returnsNilWhenNoSlotExists() throws {
        let id = try UITestElementId(validating: "missing")
        var materializeLog: [UITestContractXCUIQuerySlot] = []
        let result = UITestContractElementResolverCore.firstResolved(
            slots: UITestContractXCUIQuerySlot.contractResolutionOrder,
            elementId: id,
            timeoutPerSlot: 0.01,
            materialize: { slot in
                materializeLog.append(slot)
                return slot
            },
            exists: { _, _ in false }
        )
        XCTAssertNil(result)
        XCTAssertEqual(materializeLog, UITestContractXCUIQuerySlot.contractResolutionOrder)
    }
}
