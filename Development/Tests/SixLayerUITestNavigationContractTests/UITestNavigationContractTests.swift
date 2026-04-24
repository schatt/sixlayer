//
//  UITestNavigationContractTests.swift
//  SixLayerUITestNavigationContractTests
//
//  Contract validation for SixLayerTestKit UI navigation (#227).
//

import XCTest
import SixLayerTestKit

final class UITestNavigationContractTests: XCTestCase {

    func testScreenId_rejectsEmptyAndWhitespaceOnly() {
        XCTAssertThrowsError(try UITestScreenId(validating: "")) { error in
            XCTAssertEqual(error as? UITestNavigationContractError, .emptyScreenId)
        }
        XCTAssertThrowsError(try UITestScreenId(validating: "   \t\n")) { error in
            XCTAssertEqual(error as? UITestNavigationContractError, .emptyScreenId)
        }
    }

    func testScreenId_rejectsDisallowedCharacters() {
        XCTAssertThrowsError(try UITestScreenId(validating: "home screen")) { error in
            XCTAssertEqual(
                error as? UITestNavigationContractError,
                .invalidIdentifier(role: "screen", value: "home screen")
            )
        }
        XCTAssertThrowsError(try UITestScreenId(validating: "café")) { error in
            XCTAssertEqual(
                error as? UITestNavigationContractError,
                .invalidIdentifier(role: "screen", value: "café")
            )
        }
    }

    func testScreenId_acceptsTrimmedValidIdentifier() throws {
        let id = try UITestScreenId(validating: "  com.example.Main  ")
        XCTAssertEqual(id.rawValue, "com.example.Main")
    }

    func testRouteId_rejectsEmpty() {
        XCTAssertThrowsError(try UITestRouteId(validating: "")) { error in
            XCTAssertEqual(error as? UITestNavigationContractError, .emptyRouteId)
        }
    }

    func testElementId_rejectsEmpty() {
        XCTAssertThrowsError(try UITestElementId(validating: "")) { error in
            XCTAssertEqual(error as? UITestNavigationContractError, .emptyElementId)
        }
    }

    func testAggregateContract_validatesAllParts() throws {
        let contract = try UITestNavigationContract(
            screen: "settings.root",
            route: "section.advanced",
            element: "toggle.analytics"
        )
        XCTAssertEqual(contract.screenId.rawValue, "settings.root")
        XCTAssertEqual(contract.routeId?.rawValue, "section.advanced")
        XCTAssertEqual(contract.elementId?.rawValue, "toggle.analytics")
    }

    func testAggregateContract_propagatesScreenValidation() {
        XCTAssertThrowsError(try UITestNavigationContract(screen: "")) { error in
            XCTAssertEqual(error as? UITestNavigationContractError, .emptyScreenId)
        }
    }

    func testLocalizedErrorDescriptionsAreDeterministic() {
        XCTAssertEqual(
            (UITestNavigationContractError.emptyScreenId as LocalizedError).errorDescription,
            "Screen identifier must not be empty."
        )
        XCTAssertEqual(
            (UITestNavigationContractError.emptyRouteId as LocalizedError).errorDescription,
            "Route identifier must not be empty."
        )
        XCTAssertEqual(
            (UITestNavigationContractError.emptyElementId as LocalizedError).errorDescription,
            "Element identifier must not be empty."
        )
        let invalid = UITestNavigationContractError.invalidIdentifier(role: "screen", value: "bad id")
        XCTAssertEqual(
            invalid.errorDescription,
            "Invalid screen identifier \"bad id\": use only ASCII letters, digits, '.', '-', or '_'."
        )
    }
}
