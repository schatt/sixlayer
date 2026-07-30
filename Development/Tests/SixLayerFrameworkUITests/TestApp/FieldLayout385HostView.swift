//
//  FieldLayout385HostView.swift
//  SixLayerFrameworkUITests
//
//  GitHub #385: Real-window host for ModalFormView checkbox packing + column alignment.
//  Launch with `-OpenFieldLayout385`.
//

import SwiftUI
import SixLayerFramework

/// Four narrow checkbox fields — packing should place two per row on a phone-width sheet;
/// column peers must share a leading edge (minX).
struct FieldLayout385HostView: View {
    private let fields: [DynamicFormField] = [
        DynamicFormField(
            id: "FL385_Check_A",
            contentType: .boolean,
            label: "FL385 A",
            metadata: ["displayWidth": "narrow"]
        ),
        DynamicFormField(
            id: "FL385_Check_B",
            contentType: .boolean,
            label: "FL385 B",
            metadata: ["displayWidth": "narrow"]
        ),
        DynamicFormField(
            id: "FL385_Check_C",
            contentType: .boolean,
            label: "FL385 C",
            metadata: ["displayWidth": "narrow"]
        ),
        DynamicFormField(
            id: "FL385_Check_D",
            contentType: .boolean,
            label: "FL385 D",
            metadata: ["displayWidth": "narrow"]
        )
    ]

    var body: some View {
        ModalFormView(
            fields: fields,
            formType: .generic,
            context: .modal,
            hints: PresentationHints(
                dataType: .generic,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: .modal,
                customPreferences: [:]
            )
        )
        .accessibilityIdentifier("FL385_Host")
    }
}
