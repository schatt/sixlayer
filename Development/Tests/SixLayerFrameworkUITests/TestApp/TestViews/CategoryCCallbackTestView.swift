//
//  CategoryCCallbackTestView.swift
//  SixLayerFrameworkUITests
//
//  Issue #199: Category C callback coverage host.
//

import SwiftUI
import SixLayerFramework

private struct CategoryCCollectionItem: Identifiable {
    let id: String
    let title: String
}

struct CategoryCCallbackTestView: View {
    @State private var name: String = "Category C"
    @State private var formCallbackState: String = "none"
    @State private var selectedItemTitle: String = "none"

    private let items: [CategoryCCollectionItem] = [
        .init(id: "1", title: "Category C Item 1"),
        .init(id: "2", title: "Category C Item 2"),
        .init(id: "3", title: "Category C Item 3"),
    ]

    /// macOS XCUI often leaves `Text.label` empty when only an identifier is set (#316).
    @ViewBuilder
    private func stateText(_ text: String, id: String) -> some View {
        Text(text)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(id)
            .accessibilityLabel(text)
            .accessibilityValue(text)
    }

    var body: some View {
        ScrollView {
            platformVStackContainer(alignment: .leading, spacing: 16) {
                Text("Category C Callback Coverage")
                    .font(.title2)
                    .accessibilityIdentifier("category-c-callback-host-title")
                    .accessibilityLabel("Category C Callback Coverage")

                platformVStackContainer(alignment: .leading, spacing: 10) {
                    Text("Form flow")
                        .font(.headline)

                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    platformHStackContainer(spacing: 10) {
                        Button("Submit") {
                            handleSubmit()
                        }
                        .accessibilityIdentifier("category-c-form-submit-button")

                        Button("Cancel") {
                            handleCancel()
                        }
                        .accessibilityIdentifier("category-c-form-cancel-button")
                    }

                    stateText(
                        "Form callback state: \(formCallbackState)",
                        id: "category-c-form-state-text"
                    )
                }

                platformVStackContainer(alignment: .leading, spacing: 10) {
                    Text("Selection flow")
                        .font(.headline)

                    platformVStackContainer(alignment: .leading, spacing: 8) {
                        ForEach(items) { item in
                            Button(item.title) {
                                handleSelection(item)
                            }
                            .accessibilityIdentifier("category-c-selection-row-\(item.id)")
                        }
                    }

                    stateText(
                        "Selected item: \(selectedItemTitle)",
                        id: "category-c-selection-state-text"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Category C")
    }

    private func handleSubmit() {
        formCallbackState = "submit"
    }

    private func handleCancel() {
        formCallbackState = "cancel"
    }

    private func handleSelection(_ item: CategoryCCollectionItem) {
        selectedItemTitle = item.title
    }
}
