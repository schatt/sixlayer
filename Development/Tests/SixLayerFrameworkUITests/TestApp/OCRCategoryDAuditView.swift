//
//  OCRCategoryDAuditView.swift
//  SixLayerFrameworkUITests
//
//  Issue #200: Category D UI backfill host for OCR disambiguation and overlay outcomes.
//

import SwiftUI
import SixLayerFramework

struct OCRCategoryDAuditView: View {
    @State private var selectedCandidateText = "Selected candidate: none"
    @State private var overlayState = "Overlay state: hidden"
    @State private var showOverlay = false

    private let disambiguationCandidates: [OCRDataCandidate] = [
        OCRDataCandidate(
            text: "Category D Candidate 1",
            boundingBox: CGRect(x: 10, y: 10, width: 80, height: 20),
            confidence: 0.61,
            suggestedType: .general,
            alternativeTypes: [.general, .name]
        ),
        OCRDataCandidate(
            text: "Category D Candidate 2",
            boundingBox: CGRect(x: 10, y: 40, width: 80, height: 20),
            confidence: 0.60,
            suggestedType: .general,
            alternativeTypes: [.general, .name]
        )
    ]

    private var disambiguationResult: OCRDisambiguationResult {
        OCRDisambiguationResult(
            candidates: disambiguationCandidates,
            confidence: 0.605,
            requiresUserSelection: true
        )
    }

    private let overlayResult = OCRResult(
        extractedText: "Category D overlay text",
        confidence: 0.9,
        boundingBoxes: [CGRect(x: 5, y: 5, width: 40, height: 16)]
    )

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 20) {
                Text("Category D OCR Coverage")
                    .font(.headline)
                    .accessibilityIdentifier("Category D OCR Coverage")

                Text("Select OCR candidate")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("category-d-disambiguation-prompt")

                OCRDisambiguationView(result: disambiguationResult) { selection in
                    if let candidate = disambiguationCandidates.first(where: { $0.id == selection.candidateId }) {
                        selectedCandidateText = "Selected candidate: \(candidate.text)"
                    }
                }

                Text(selectedCandidateText)
                    .accessibilityIdentifier("category-d-selection-state")

                Button("Open OCR Overlay") {
                    overlayState = "Overlay state: presented"
                    showOverlay = true
                }
                .accessibilityIdentifier("category-d-open-overlay")

                Text(overlayState)
                    .accessibilityIdentifier("category-d-overlay-state")
            }
            .padding()
        }
        .sheet(isPresented: $showOverlay) {
            NavigationStack {
                platformVStack(alignment: .leading, spacing: 16) {
                    OCROverlayView(
                        image: PlatformImage.createPlaceholder(),
                        result: overlayResult,
                        configuration: OCROverlayConfiguration()
                    )
                    Button("Done Overlay") {
                        overlayState = "Overlay state: dismissed"
                        showOverlay = false
                    }
                    .accessibilityIdentifier("category-d-overlay-done")
                }
                .padding()
                .navigationTitle("Category D Overlay")
                .platformNavigationTitleDisplayMode_L4(.inline)
            }
        }
        .platformFrame()
        .navigationTitle("Category D OCR Coverage")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}
