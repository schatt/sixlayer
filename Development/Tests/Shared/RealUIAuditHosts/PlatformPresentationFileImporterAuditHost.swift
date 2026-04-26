//
//  PlatformPresentationFileImporterAuditHost.swift
//  SixLayerFramework
//
//  Shared RealUI (TestApp) + ViewInspector host for presentation detents and file importer (Issue #170).
//

import SwiftUI
import UniformTypeIdentifiers
import SixLayerFramework

struct PlatformPresentationFileImporterAuditHost: View {
    var onBackToMain: (() -> Void)?

    @State private var sheetTyped = false
    @State private var importerPresented = false
    @State private var importerStatus = "Idle"

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 18) {
                platformText("Platform Presentation + File Importer Audit")
                    .font(.headline)
                    .accessibilityIdentifier("platform-pres-file-audit-title")

                platformText("platformPresentationDetents([PlatformPresentationDetent])")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformButton(label: "Open typed detents sheet", id: "platform-pres-typed-sheet-open") {
                    sheetTyped = true
                }
                .sheet(isPresented: $sheetTyped) {
                    platformVStack(alignment: .leading, spacing: 12) {
                        platformText("Medium / large detents (typed enum)")
                            .accessibilityIdentifier("platform-pres-typed-sheet-headline")
                        platformButton(label: "Dismiss typed sheet", id: "platform-pres-typed-sheet-dismiss") {
                            sheetTyped = false
                        }
                    }
                    .padding()
                    .platformPresentationDetents([.medium, .large])
                    .accessibilityIdentifier("platform-pres-typed-sheet-root")
                }

                platformText("platformFileImporter")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Importer status: \(importerStatus)")
                    .accessibilityIdentifier("platform-file-importer-status")
                platformButton(label: "Open file importer (plain text)", id: "platform-file-importer-open") {
                    importerPresented = true
                }
                .platformFileImporter(
                    isPresented: $importerPresented,
                    allowedContentTypes: [UTType.plainText],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        importerStatus = "success count=\(urls.count)"
                    case .failure(let error):
                        importerStatus = "failure \(error.localizedDescription)"
                    }
                }
                .accessibilityIdentifier("platform-file-importer-trigger")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-pres-file-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Presentation + File Importer")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}
