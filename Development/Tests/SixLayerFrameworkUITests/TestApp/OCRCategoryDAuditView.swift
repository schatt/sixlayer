//
//  OCRCategoryDAuditView.swift
//  SixLayerFrameworkUITests
//
//  Issue #200: Category D OCR UI coverage host.
//

import SwiftUI

struct OCRCategoryDAuditView: View {
    @State private var selectedCandidate: String = "none"
    @State private var isOverlayPresented: Bool = false
    @State private var overlayState: String = "hidden"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Category D OCR Coverage")
                    .font(.title2)
                    .accessibilityIdentifier("category-d-host-title")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose OCR candidate")
                        .font(.headline)
                        .accessibilityIdentifier("category-d-disambiguation-prompt")

                    Button("Use Category D Candidate 1") {
                        selectedCandidate = "Category D Candidate 1"
                    }

                    Button("Use Category D Candidate 2") {
                        selectedCandidate = "Category D Candidate 2"
                    }

                    Text("Selected candidate: \(selectedCandidate)")
                        .accessibilityIdentifier("category-d-selection-state")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Button("Present OCR overlay") {
                        overlayState = "presented"
                        isOverlayPresented = true
                    }
                    .accessibilityIdentifier("category-d-open-overlay")

                    Text("Overlay state: \(overlayState)")
                        .accessibilityIdentifier("category-d-overlay-state")
                }
            }
            .padding()
        }
        .sheet(isPresented: $isOverlayPresented) {
            VStack(spacing: 12) {
                Text("OCR Overlay")
                    .font(.headline)

                Button("Done") {
                    overlayState = "dismissed"
                    isOverlayPresented = false
                }
                .accessibilityIdentifier("category-d-overlay-done")
            }
            .padding()
        }
        .navigationTitle("Category D")
    }
}
