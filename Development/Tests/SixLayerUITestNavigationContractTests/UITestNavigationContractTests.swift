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

    func testRouteId_rejectsWhitespaceOnly() {
        XCTAssertThrowsError(try UITestRouteId(validating: "  \t")) { error in
            XCTAssertEqual(error as? UITestNavigationContractError, .emptyRouteId)
        }
    }

    func testRouteId_rejectsDisallowedCharacters() {
        XCTAssertThrowsError(try UITestRouteId(validating: "bad route")) { error in
            XCTAssertEqual(
                error as? UITestNavigationContractError,
                .invalidIdentifier(role: "route", value: "bad route")
            )
        }
    }

    func testRouteId_acceptsTrimmedValidIdentifier() throws {
        let id = try UITestRouteId(validating: "  section.A  ")
        XCTAssertEqual(id.rawValue, "section.A")
    }

    func testElementId_rejectsEmpty() {
        XCTAssertThrowsError(try UITestElementId(validating: "")) { error in
            XCTAssertEqual(error as? UITestNavigationContractError, .emptyElementId)
        }
    }

    func testElementId_rejectsWhitespaceOnly() {
        XCTAssertThrowsError(try UITestElementId(validating: "\n  ")) { error in
            XCTAssertEqual(error as? UITestNavigationContractError, .emptyElementId)
        }
    }

    func testElementId_rejectsDisallowedCharacters() {
        XCTAssertThrowsError(try UITestElementId(validating: "toggle%")) { error in
            XCTAssertEqual(
                error as? UITestNavigationContractError,
                .invalidIdentifier(role: "element", value: "toggle%")
            )
        }
    }

    func testElementId_acceptsTrimmedValidIdentifier() throws {
        let id = try UITestElementId(validating: "  row.item-1  ")
        XCTAssertEqual(id.rawValue, "row.item-1")
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

    func testAggregateContract_screenOnlyOptionalPartsNil() throws {
        let contract = try UITestNavigationContract(screen: "home.root")
        XCTAssertEqual(contract.screenId.rawValue, "home.root")
        XCTAssertNil(contract.routeId)
        XCTAssertNil(contract.elementId)
    }

    func testAggregateContract_propagatesRouteValidation() {
        XCTAssertThrowsError(try UITestNavigationContract(screen: "ok.screen", route: "bad route")) { error in
            XCTAssertEqual(
                error as? UITestNavigationContractError,
                .invalidIdentifier(role: "route", value: "bad route")
            )
        }
    }

    func testAggregateContract_propagatesElementValidation() {
        XCTAssertThrowsError(try UITestNavigationContract(screen: "ok.screen", element: "x@y")) { error in
            XCTAssertEqual(
                error as? UITestNavigationContractError,
                .invalidIdentifier(role: "element", value: "x@y")
            )
        }
    }

    func testTypedInitializer_roundTrip() throws {
        let screen = try UITestScreenId(validating: "a.b")
        let route = try UITestRouteId(validating: "c.d")
        let element = try UITestElementId(validating: "e.f")
        let contract = UITestNavigationContract(screenId: screen, routeId: route, elementId: element)
        XCTAssertEqual(contract.screenId, screen)
        XCTAssertEqual(contract.routeId, route)
        XCTAssertEqual(contract.elementId, element)
    }

    func testScreenId_codableRoundTrip() throws {
        let original = try UITestScreenId(validating: "com.example.Screen")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UITestScreenId.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testNavigationContract_codableRoundTrip() throws {
        let original = try UITestNavigationContract(
            screen: "s.one",
            route: "r.two",
            element: "e.three"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UITestNavigationContract.self, from: data)
        XCTAssertEqual(decoded, original)
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
