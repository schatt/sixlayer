//
//  FieldLayoutBridgeTests.swift
//  SixLayerFrameworkTests
//
//  DynamicFormField / DataField → packer bridges (GitHub #385).
//

import Testing
import CoreGraphics
@testable import SixLayerFramework

@Suite("Field Layout Bridges")
struct FieldLayoutBridgeTests {

    @Test func dynamicFormField_checkboxMapsToCheckboxKind() {
        let field = DynamicFormField(
            id: "active",
            contentType: .checkbox,
            label: "Active",
            metadata: ["displayWidth": "medium"]
        )
        #expect(field.layoutPackKind == .checkbox)
    }

    @Test func dynamicFormField_textareaMapsToTall() {
        let field = DynamicFormField(
            id: "notes",
            contentType: .textarea,
            label: "Notes"
        )
        #expect(field.layoutPackKind == .tall)
    }

    @Test func dynamicFormField_wideHintMapsToWideFlex() {
        let field = DynamicFormField(
            id: "email",
            contentType: .email,
            label: "Email",
            metadata: ["displayWidth": "wide"]
        )
        #expect(field.layoutPackKind == .wideFlex)
    }

    @Test func dynamicFormField_narrowPreferredWidthUsesResolver() {
        let field = DynamicFormField(
            id: "zip",
            contentType: .text,
            label: "ZIP",
            metadata: ["displayWidth": "narrow"]
        )
        let bands = FieldDisplayWidthPlatformBands(narrow: 150, medium: 200, wide: 400)
        #expect(field.preferredLayoutWidth(bands: bands) == 150)
        #expect(field.layoutPackItem(bands: bands).preferredWidth == 150)
    }

    @Test func dynamicFormField_layoutPackItem_capsPreferredWidthToAvailableWidth() {
        let field = DynamicFormField(
            id: "email",
            contentType: .email,
            label: "Email",
            metadata: ["displayWidth": "wide"]
        )
        let bands = FieldDisplayWidthPlatformBands(narrow: 120, medium: 180, wide: 320)
        let item = field.layoutPackItem(bands: bands, availableWidth: 200)
        #expect(item.preferredWidth == 200)
    }

    @Test func dynamicFormField_layoutPackItem_usesOverrideHintsOverFieldMetadata() {
        let field = DynamicFormField(
            id: "zip",
            contentType: .text,
            label: "ZIP",
            metadata: ["displayWidth": "wide"]
        )
        let bands = FieldDisplayWidthPlatformBands(narrow: 120, medium: 180, wide: 320)
        let override = FieldDisplayHints(displayWidth: "narrow")
        let item = field.layoutPackItem(hints: override, bands: bands)
        #expect(item.preferredWidth == 120)
    }

    @Test func controlSizing_checkboxKindKeepsIntrinsicWithinClaim() {
        #expect(FieldLayoutControlSizing.forPackKind(.checkbox) == .intrinsicWithinClaim)
        #expect(FieldLayoutControlSizing.forPackKind(.compact) == .fillClaim)
        #expect(FieldLayoutControlSizing.forPackKind(.tall) == .fillClaim)
    }

    @Test func presentationHints_resolvedFieldDisplayHints_prefersPresentationMap() {
        let field = DynamicFormField(
            id: "zip",
            contentType: .text,
            label: "ZIP",
            metadata: ["displayWidth": "wide"]
        )
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard,
            fieldHints: ["zip": FieldDisplayHints(displayWidth: "narrow")]
        )
        #expect(
            hints.resolvedFieldDisplayHints(
                fieldId: field.id,
                fieldDisplayHints: field.displayHints
            )?.displayWidth == "narrow"
        )
    }

    @Test func presentationHints_resolvedFieldDisplayHints_fallsBackToFieldMetadata() {
        let field = DynamicFormField(
            id: "zip",
            contentType: .text,
            label: "ZIP",
            metadata: ["displayWidth": "medium"]
        )
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        #expect(
            hints.resolvedFieldDisplayHints(
                fieldId: field.id,
                fieldDisplayHints: field.displayHints
            )?.displayWidth == "medium"
        )
    }

    @Test func dataField_booleanMapsToCheckboxKind() {
        let field = DataField(name: "active", type: .boolean)
        #expect(field.layoutPackKind(hints: nil) == .checkbox)
    }

    @Test func dataField_expectedLengthFeedsPreferredWidth() {
        let field = DataField(name: "code", type: .string)
        let hints = FieldDisplayHints(expectedLength: 10)
        let width = field.preferredLayoutWidth(
            hints: hints,
            characterWidth: 8,
            horizontalPadding: 4,
            bands: FieldDisplayWidthPlatformBands(narrow: 120, medium: 180, wide: 320)
        )
        #expect(width == 84) // 10 * 8 + 4
    }
}
