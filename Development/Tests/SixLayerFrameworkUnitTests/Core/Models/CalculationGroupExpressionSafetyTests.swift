//
//  CalculationGroupExpressionSafetyTests.swift
//  SixLayerFrameworkTests
//
//  Empty and non-numeric field values must not reach NSExpression (GitHub #542).
//

import Testing
@testable import SixLayerFramework

@Suite("Calculation group expression safety")
@MainActor
struct CalculationGroupExpressionSafetyTests {

    private func formState() -> DynamicFormState {
        DynamicFormState(
            configuration: DynamicFormConfiguration(id: "fuel", title: "Fuel")
        )
    }

    private func costGroup() -> CalculationGroup {
        CalculationGroup(
            id: "cost",
            formula: "result = gallons * price",
            dependentFields: ["gallons", "price"],
            priority: 1
        )
    }

    @Test func emptyStringDependencyReturnsNil() {
        let form = formState()
        form.setValue("", for: "gallons")
        form.setValue("3.25", for: "price")

        let result = form.calculateFieldFromGroups(
            fieldId: "result",
            calculationGroups: [costGroup()]
        )

        #expect(result == nil)
    }

    @Test func ellipsisDependencyReturnsNil() {
        let form = formState()
        form.setValue("..", for: "gallons")
        form.setValue("3.25", for: "price")

        let result = form.calculateFieldFromGroups(
            fieldId: "result",
            calculationGroups: [costGroup()]
        )

        #expect(result == nil)
    }

    @Test func nonNumericBoolReturnsNil() {
        let form = formState()
        form.setValue(true, for: "gallons")
        form.setValue(3.25, for: "price")

        let result = form.calculateFieldFromGroups(
            fieldId: "result",
            calculationGroups: [costGroup()]
        )

        #expect(result == nil)
    }

    @Test func numericStringsStillCalculate() {
        let form = formState()
        form.setValue("2", for: "gallons")
        form.setValue("3.25", for: "price")

        let result = form.calculateFieldFromGroups(
            fieldId: "result",
            calculationGroups: [costGroup()]
        )

        #expect(result?.calculatedValue == 6.5)
        #expect(result?.confidence == .high)
    }

    @Test func numericScalarsStillCalculate() {
        let form = formState()
        form.setValue(2, for: "gallons")
        form.setValue(3.25, for: "price")

        let result = form.calculateFieldFromGroups(
            fieldId: "result",
            calculationGroups: [costGroup()]
        )

        #expect(result?.calculatedValue == 6.5)
    }

    @Test func tinyNumericStringStillCalculates() {
        let form = formState()
        form.setValue("0.0000001", for: "gallons")
        form.setValue("2", for: "price")

        let result = form.calculateFieldFromGroups(
            fieldId: "result",
            calculationGroups: [costGroup()]
        )

        let value = result?.calculatedValue
        #expect(value != nil)
        if let value {
            #expect(abs(value - 0.0000002) < 0.0000000000001)
        }
    }

    @Test func parenthesizedFormulaStillCalculates() {
        let form = formState()
        form.setValue("2", for: "a")
        form.setValue("3", for: "b")
        form.setValue("4", for: "c")

        let result = form.calculateFieldFromGroups(
            fieldId: "result",
            calculationGroups: [
                CalculationGroup(
                    id: "paren",
                    formula: "result = (a * b) + c",
                    dependentFields: ["a", "b", "c"],
                    priority: 1
                )
            ]
        )

        #expect(result?.calculatedValue == 10)
    }
}
