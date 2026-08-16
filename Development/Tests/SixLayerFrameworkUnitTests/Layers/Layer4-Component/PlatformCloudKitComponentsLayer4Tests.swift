//
//  PlatformCloudKitComponentsLayer4Tests.swift
//  SixLayerFrameworkTests
//
//  Tests for CloudKit Layer 4 UI components
//

import Testing
import SwiftUI
import CloudKit
@testable import SixLayerFramework

@Suite("CloudKit Layer 4 Components")
@MainActor
final class PlatformCloudKitComponentsLayer4Tests {
    
    // MARK: - Sync Status Display Tests
    
    @Test func testPlatformCloudKitSyncStatusIdle() {
        let status = CloudKitSyncStatus.idle
        let view = platformCloudKitSyncStatus_L4(status: status)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    @Test func testPlatformCloudKitSyncStatusSyncing() {
        let status = CloudKitSyncStatus.syncing
        let view = platformCloudKitSyncStatus_L4(status: status)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    @Test func testPlatformCloudKitSyncStatusComplete() {
        let status = CloudKitSyncStatus.complete
        let view = platformCloudKitSyncStatus_L4(status: status)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    @Test func testPlatformCloudKitSyncStatusError() {
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let status = CloudKitSyncStatus.error(error)
        let view = platformCloudKitSyncStatus_L4(status: status)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    // MARK: - Progress Display Tests
    
    @Test func testPlatformCloudKitProgress() {
        let view = platformCloudKitProgress_L4(progress: 0.5)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    @Test func testPlatformCloudKitProgressWithStatus() {
        let status = CloudKitSyncStatus.syncing
        let view = platformCloudKitProgress_L4(progress: 0.75, status: status)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    // MARK: - Account Status Display Tests
    
    @Test func testPlatformCloudKitAccountStatusAvailable() {
        let status = CKAccountStatus.available
        let view = platformCloudKitAccountStatus_L4(status: status)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    @Test func testPlatformCloudKitAccountStatusNoAccount() {
        let status = CKAccountStatus.noAccount
        let view = platformCloudKitAccountStatus_L4(status: status)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    @Test func testPlatformCloudKitAccountStatusCouldNotDetermine() {
        let status = CKAccountStatus.couldNotDetermine
        let view = platformCloudKitAccountStatus_L4(status: status)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    // MARK: - Service Status View Tests
    
    @Test func testPlatformCloudKitServiceStatus() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitServiceStatus_L4(service: service)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    // MARK: - Sync Button Tests
    
    @Test func testPlatformCloudKitSyncButton() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitSyncButton_L4(service: service)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    @Test func testPlatformCloudKitSyncButtonWithCustomLabel() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitSyncButton_L4(service: service, label: "Sync Now")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
    
    // MARK: - Status Badge Tests
    
    @Test func testPlatformCloudKitStatusBadge() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitStatusBadge_L4(service: service)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotACloudKitL4View")
    }
}
