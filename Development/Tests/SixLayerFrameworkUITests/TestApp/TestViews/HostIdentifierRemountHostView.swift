//
//  HostIdentifierRemountHostView.swift
//  SixLayerFrameworkUITests
//
//  #473: TestApp host for accessibilityHostIdentifier remount contract.
//  Outer container stamps **only** `accessibilityHostIdentifier` (no plain
//  `.accessibilityIdentifier` on that view). Nested content remounts via `.id`.
//

import SwiftUI
import SixLayerFramework

enum HostIdentifierRemountIDs {
    static let land = "host-identifier-remount-host-root"
    static let host = "SixLayer.uitest.hostIdentifier.scrollHost"
    static let nested = "SixLayer.uitest.hostIdentifier.nested"
    static let presentSheet = "SixLayer.uitest.hostIdentifier.presentSheet"
    static let dismissSheet = "SixLayer.uitest.hostIdentifier.dismissSheet"
    static let remount = "SixLayer.uitest.hostIdentifier.remount"
    static let sheetContent = "SixLayer.uitest.hostIdentifier.sheetContent"
}

/// Deep-link: `-OpenHostIdentifierRemount`.
struct HostIdentifierRemountHostView: View {
    @State private var showSheet = false
    @State private var nestedEpoch = 0

    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            uiTestHostLandMarker(HostIdentifierRemountIDs.land, title: "Host Identifier Remount")
            contractSurface
        }
        .padding()
        .platformFrame()
    }

    /// Contract under test: host id on this container only, via host sentinel.
    private var contractSurface: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Nested \(nestedEpoch)")
                .accessibilityIdentifier(HostIdentifierRemountIDs.nested)
                .accessibilityLabel("Nested \(nestedEpoch)")
                .id(nestedEpoch)

            Button("Present sheet") { showSheet = true }
                .accessibilityIdentifier(HostIdentifierRemountIDs.presentSheet)
                .accessibilityLabel("Present sheet")
                .buttonStyle(.borderless)

            Button("Remount nested") { /* no-op: deliberate red for epoch assertion (#473) */ }
                .accessibilityIdentifier(HostIdentifierRemountIDs.remount)
                .accessibilityLabel("Remount nested")
                .buttonStyle(.borderless)
        }
        .accessibilityHostIdentifier(HostIdentifierRemountIDs.host)
        .platformSheet_L4(isPresented: $showSheet) {
            HostIdentifierRemountSheetContent()
        }
    }
}

private struct HostIdentifierRemountSheetContent: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        platformVStack(spacing: 16) {
            Text("Host identifier remount sheet")
                .font(.title)
                .accessibilityIdentifier(HostIdentifierRemountIDs.sheetContent)
                .accessibilityLabel("Host identifier remount sheet")
            Button("Dismiss") { dismiss() }
                .accessibilityIdentifier(HostIdentifierRemountIDs.dismissSheet)
                .accessibilityLabel("Dismiss")
                .buttonStyle(.borderless)
        }
        .padding()
    }
}
