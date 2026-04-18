//
//  PlatformCloudKitComponentsLayer4.swift
//  SixLayerFramework
//
//  Layer 4: Platform-agnostic CloudKit UI components
//  Provides sync status, progress, and account status displays
//

import SwiftUI
import CloudKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - CloudKit Sync Status Display

/// Platform-agnostic view for displaying CloudKit sync status
/// - Parameter status: The current sync status
/// - Returns: A view showing the sync status
public func platformCloudKitSyncStatus_L4(status: CloudKitSyncStatus) -> some View {
    let summaryLabel = cloudKitSyncStatusAccessibilitySummary(status)
    return Group {
        switch status {
        case .idle:
            Label("CloudKit Sync: Idle", systemImage: "icloud")
                .foregroundColor(.secondary)
        case .syncing:
            Label("CloudKit Sync: Syncing...", systemImage: "icloud.and.arrow.up")
                .foregroundColor(.blue)
        case .paused:
            Label("CloudKit Sync: Paused", systemImage: "pause.circle")
                .foregroundColor(.orange)
        case .complete:
            Label("CloudKit Sync: Complete", systemImage: "checkmark.icloud")
                .foregroundColor(.green)
        case .error(let error):
            Label("CloudKit Sync: Error", systemImage: "exclamationmark.icloud")
                .foregroundColor(.red)
                .help(error.localizedDescription)
        }
    }
    .automaticCompliance()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(summaryLabel)
    // Stable id for UI tests (Issue #193); must contain substring "platformCloudKitSyncStatus".
    .accessibilityIdentifier("platformCloudKitSyncStatus_L4")
}

private func cloudKitSyncStatusAccessibilitySummary(_ status: CloudKitSyncStatus) -> String {
    switch status {
    case .idle: return "CloudKit Sync: Idle"
    case .syncing: return "CloudKit Sync: Syncing..."
    case .paused: return "CloudKit Sync: Paused"
    case .complete: return "CloudKit Sync: Complete"
    case .error: return "CloudKit Sync: Error"
    }
}

// MARK: - CloudKit Progress Display

/// Platform-agnostic view for displaying CloudKit sync progress
/// - Parameters:
///   - progress: Progress value (0.0 to 1.0)
///   - status: Optional sync status for additional context
/// - Returns: A view showing the sync progress
@MainActor
public func platformCloudKitProgress_L4(
    progress: Double,
    status: CloudKitSyncStatus? = nil
) -> some View {
    platformVStackContainer(alignment: .leading, spacing: 4) {
        if let status = status {
            platformCloudKitSyncStatus_L4(status: status)
        }
        
        ProgressView(value: progress) {
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    .automaticCompliance()
}

// MARK: - CloudKit Account Status Display

/// Platform-agnostic view for displaying CloudKit account status
/// - Parameter status: The current account status
/// - Returns: A view showing the account status
public func platformCloudKitAccountStatus_L4(status: CKAccountStatus) -> some View {
    Group {
        switch status {
        case .available:
            Label("iCloud Account: Available", systemImage: "person.icloud")
                .foregroundColor(.green)
        case .noAccount:
            Label("iCloud Account: Not Signed In", systemImage: "person.icloud.slash")
                .foregroundColor(.orange)
        case .restricted:
            Label("iCloud Account: Restricted", systemImage: "lock.icloud")
                .foregroundColor(.orange)
        case .couldNotDetermine:
            Label("iCloud Account: Unknown", systemImage: "questionmark.icloud")
                .foregroundColor(.secondary)
        case .temporarilyUnavailable:
            Label("iCloud Account: Temporarily Unavailable", systemImage: "exclamationmark.icloud")
                .foregroundColor(.orange)
        @unknown default:
            Label("iCloud Account: Unknown Status", systemImage: "questionmark.icloud")
                .foregroundColor(.secondary)
        }
    }
    .automaticCompliance()
}

// MARK: - CloudKit Service Status View

/// Complete CloudKit service status view combining all status displays
/// - Parameter service: The CloudKit service to display status for
/// - Returns: A view showing all CloudKit status information
@MainActor
public func platformCloudKitServiceStatus_L4(service: CloudKitService) -> some View {
    platformVStackContainer(alignment: .leading, spacing: 12) {
        // Account Status
        platformCloudKitAccountStatus_L4(status: service.accountStatus)
        
        Divider()
        
        // Sync Status
        platformCloudKitSyncStatus_L4(status: service.syncStatus)
        
        // Progress (if syncing)
        if case .syncing = service.syncStatus {
            platformCloudKitProgress_L4(
                progress: service.syncProgress,
                status: service.syncStatus
            )
        }
        
        // Queue Status (if there are queued operations)
        if service.queuedOperationCount > 0 {
            Divider()
            Label("Queued Operations: \(service.queuedOperationCount)", systemImage: "list.bullet.rectangle")
                .foregroundColor(.orange)
                .font(.caption)
        }
        
        // Error Display (if there's an error)
        if let error = service.lastError {
            Divider()
            let i18n = InternationalizationService()
            Label(i18n.localizedString(for: "SixLayerFramework.error.message", arguments: [error.localizedDescription]), systemImage: "exclamationmark.triangle")
                .foregroundColor(.red)
                .font(.caption)
        }
    }
    .padding()
    #if os(macOS)
    .background(Color(NSColor.controlBackgroundColor))
    #else
    // Color(.systemBackground) is unavailable on tvOS; use shared platform helper (#237).
    .background(Color.platformBackground)
    #endif
    .cornerRadius(8)
    .automaticCompliance()
}

// MARK: - CloudKit Sync Button

/// Platform-agnostic button for triggering CloudKit sync
/// - Parameters:
///   - service: The CloudKit service to sync
///   - label: Optional custom label (default: "Sync")
/// - Returns: A button that triggers sync when tapped
@MainActor
public func platformCloudKitSyncButton_L4(
    service: CloudKitService,
    label: String = "Sync"
) -> some View {
    Button(action: {
        Task {
            do {
                try await service.sync()
            } catch {
                // Error is handled by service's lastError property
            }
        }
    }) {
        Label(label, systemImage: "arrow.clockwise.icloud")
    }
    .disabled(service.syncStatus == .syncing || service.accountStatus != .available)
    .automaticCompliance()
}

// MARK: - CloudKit Compact Status Badge

/// Compact badge view for CloudKit sync status (for use in toolbars, etc.)
/// - Parameter service: The CloudKit service to display status for
/// - Returns: A compact badge view
@MainActor
public func platformCloudKitStatusBadge_L4(service: CloudKitService) -> some View {
    Group {
        switch service.syncStatus {
        case .idle:
            Image(systemName: "icloud")
                .foregroundColor(.secondary)
        case .syncing:
            ProgressView()
                .scaleEffect(0.7)
        case .paused:
            Image(systemName: "pause.circle.fill")
                .foregroundColor(.orange)
        case .complete:
            Image(systemName: "checkmark.icloud.fill")
                .foregroundColor(.green)
        case .error:
            Image(systemName: "exclamationmark.icloud.fill")
                .foregroundColor(.red)
        }
    }
    .help(service.syncStatus == .syncing ? "Syncing..." : "CloudKit Status")
    .automaticCompliance()
}
