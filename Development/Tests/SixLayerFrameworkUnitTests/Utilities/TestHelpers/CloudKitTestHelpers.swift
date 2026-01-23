//
//  CloudKitTestHelpers.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Shared test helper for CloudKit service tests
//  Provides a single TestCloudKitDelegate implementation to avoid redeclaration errors
//
//  USAGE:
//  Import this file in CloudKit test files instead of declaring TestCloudKitDelegate locally
//

import Testing
import CloudKit
@testable import SixLayerFramework

// MARK: - Test Delegate (Shared Implementation)

/// Shared test delegate for CloudKit service tests
/// Use this instead of declaring TestCloudKitDelegate in individual test files
@MainActor
public class TestCloudKitDelegate: CloudKitServiceDelegate {
    public let containerID: String
    
    public init(containerID: String = "iCloud.com.test.app") {
        self.containerID = containerID
    }
    
    public func containerIdentifier() -> String {
        return containerID
    }
    
    // Uses default implementations from protocol extension:
    // - resolveConflict: returns remote (server wins)
    // - validateRecord: no validation
    // - transformRecord: returns record unchanged
    // - handleError: returns false (framework handles)
    // - syncDidComplete: no-op
}
