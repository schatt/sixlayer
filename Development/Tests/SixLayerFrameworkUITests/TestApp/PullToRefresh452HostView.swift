//
//  PullToRefresh452HostView.swift
//  SixLayerFrameworkUITests
//
//  GitHub #452: Minimal host for `.platformIOSPullToRefresh` → onRefresh observation.
//  Launch with `-OpenPullToRefresh452`.
//

import SwiftUI
import SixLayerFramework

/// Scroll content with pull-to-refresh; status identifier flips when `onRefresh` runs.
struct PullToRefresh452HostView: View {
    @State private var isRefreshing = false
    /// `idle` until pull fires `onRefresh`, then `refreshed`.
    @State private var status = "idle"

    var body: some View {
        NavigationStack {
            List {
                uiTestHostLandMarker("PullToRefresh452_Host", title: "Pull to Refresh #452")
                Text("Pull down to refresh")
                    .accessibilityIdentifier("PullToRefresh452_Hint")
                Text(status)
                    .accessibilityIdentifier("PullToRefresh452_Status")
                    .accessibilityValue(status)
                ForEach(0..<20, id: \.self) { i in
                    Text("Row \(i)")
                }
            }
            .platformIOSPullToRefresh(isRefreshing: $isRefreshing) {
                status = "refreshed"
            }
        }
    }
}
