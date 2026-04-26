//
//  PlatformAdvancedContainersExtensionsAuditView.swift
//  SixLayerFrameworkUITests
//
//  RealUI/TestApp coverage for `PlatformAdvancedContainerExtensions` styling modifiers (Issue #170).
//

import SwiftUI
import SixLayerFramework

struct PlatformAdvancedContainersExtensionsAuditView: View {
    var onBackToMain: (() -> Void)?

    private let gridColumns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 18) {
                platformText("Platform Advanced Containers Audit")
                    .font(.headline)
                    .accessibilityIdentifier("platform-advanced-containers-audit-title")

                platformText("LazyVGrid + platformLazyVGridContainer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(0..<4, id: \.self) { idx in
                        platformText("Grid \(idx)")
                            .accessibilityIdentifier("platform-advanced-lazyvgrid-cell-\(idx)")
                    }
                }
                .platformLazyVGridContainer()
                .accessibilityIdentifier("platform-advanced-lazyvgrid-host")

                platformText("ScrollView + platformScrollContainer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ScrollView {
                    platformVStack(alignment: .leading, spacing: 6) {
                        platformText("Scroll row A")
                            .accessibilityIdentifier("platform-advanced-scroll-row-a")
                        platformText("Scroll row B")
                            .accessibilityIdentifier("platform-advanced-scroll-row-b")
                    }
                }
                .frame(minHeight: 72, maxHeight: 96)
                .platformScrollContainer(showsIndicators: false)
                .accessibilityIdentifier("platform-advanced-scroll-host")

                platformText("List + platformListContainer()")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                List {
                    platformText("Advanced list row 0")
                        .accessibilityIdentifier("platform-advanced-list-row-0")
                    platformText("Advanced list row 1")
                        .accessibilityIdentifier("platform-advanced-list-row-1")
                }
                .frame(minHeight: 88, maxHeight: 110)
                .platformListContainer()
                .accessibilityIdentifier("platform-advanced-list-host")

                platformText("Form + platformFormContainer()")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Form {
                    Section("Audit section") {
                        platformText("Form row")
                            .accessibilityIdentifier("platform-advanced-form-row")
                    }
                }
                .frame(minHeight: 100, maxHeight: 130)
                .platformFormContainer()
                .accessibilityIdentifier("platform-advanced-form-host")

                platformText("TabView + platformTabContainer()")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TabView {
                    platformText("Tab one content")
                        .tabItem { platformText("One") }
                        .accessibilityIdentifier("platform-advanced-tab-one")
                    platformText("Tab two content")
                        .tabItem { platformText("Two") }
                        .accessibilityIdentifier("platform-advanced-tab-two")
                }
                .frame(height: 120)
                .platformTabContainer()
                .accessibilityIdentifier("platform-advanced-tab-host")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-advanced-containers-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Advanced Containers")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}
