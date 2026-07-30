//
//  CloudKitServiceMock.swift
//  SixLayerTestKit
//
//  Mock implementation of CloudKitService for testing
//

import Foundation
import CloudKit
import SixLayerFramework

/// Mock implementation of CloudKitService for testing
public class CloudKitServiceMock: CloudKitServiceDelegate {

    // MARK: - Configuration

    public enum MockMode {
        case success
        case failure(error: Error)
        case custom(handler: (CloudKitOperation) async throws -> Any)
    }

    private var mode: MockMode = .success

    // MARK: - Mock State Tracking

    public private(set) var saveWasCalled = false
    public private(set) var saveRecords: [CKRecord] = []

    public private(set) var fetchWasCalled = false
    public private(set) var fetchQueries: [CKQuery] = []

    public private(set) var deleteWasCalled = false
    public private(set) var deleteRecordIDs: [CKRecord.ID] = []

    public private(set) var queryWasCalled = false
    public private(set) var queryOperations: [CKQueryOperation] = []

    // MARK: - Configuration Methods

    /// Configure mock to return success for all operations
    public func configureSuccessResponse() {
        mode = .success
    }

    /// Configure mock to return failure for all operations
    public func configureFailureResponse(error: CloudKitServiceError = .networkUnavailable) {
        mode = .failure(error: error)
    }

    /// Configure custom response handler
    public func configureCustomResponse(handler: @escaping (CloudKitOperation) async throws -> Any) {
        mode = .custom(handler: handler)
    }

    /// Reset all tracking state
    public func reset() {
        saveWasCalled = false
        saveRecords = []
        fetchWasCalled = false
        fetchQueries = []
        deleteWasCalled = false
        deleteRecordIDs = []
        queryWasCalled = false
        queryOperations = []
        mode = .success
    }

    // MARK: - CloudKitServiceDelegate Implementation

    public func containerIdentifier() -> String {
        return "iCloud.test.container"
    }

    public func resolveConflict(local: CKRecord, remote: CKRecord) -> CKRecord? {
        // Default to server wins for testing
        return remote
    }

    public func validateRecord(_ record: CKRecord) throws {
        // Allow all records by default
        return
    }

    // MARK: - Mock Operation Execution

    /// Execute a mock CloudKit operation
    public func execute<T>(_ operation: CloudKitOperation) async throws -> T {
        switch mode {
        case .success:
            return try await executeSuccessOperation(operation)
        case .failure(let error):
            throw error
        case .custom(let handler):
            // Use nonisolated to avoid data race warnings for test mocks
            nonisolated(unsafe) let operationCopy = operation
            let result = try await handler(operationCopy)
            guard let typedResult = result as? T else {
                throw CloudKitServiceError.invalidRecord
            }
            return typedResult
        }
    }

    private func executeSuccessOperation<T>(_ operation: CloudKitOperation) async throws -> T {
        switch operation {
        case .save(let record):
            saveWasCalled = true
            saveRecords.append(record)

            // Return the saved record
            guard let result = record as? T else {
                throw CloudKitServiceError.invalidRecord
            }
            return result

        case .fetch(let recordID):
            fetchWasCalled = true

            // Create a mock record with the requested ID
            let mockRecord = CKRecord(recordType: "MockRecord", recordID: recordID)
            mockRecord["name"] = "Mock Record"
            mockRecord["createdAt"] = Date()

            guard let result = mockRecord as? T else {
                throw CloudKitServiceError.invalidRecord
            }
            return result

        case .delete(let recordID):
            deleteWasCalled = true
            deleteRecordIDs.append(recordID)

            // Return success (record ID)
            guard let result = recordID as? T else {
                throw CloudKitServiceError.invalidRecord
            }
            return result

        case .query(let query):
            queryWasCalled = true

            // Return mock results
            let mockRecords = [
                CKRecord(recordType: query.recordType, recordID: CKRecord.ID(recordName: "mock1")),
                CKRecord(recordType: query.recordType, recordID: CKRecord.ID(recordName: "mock2"))
            ]

            guard let result = mockRecords as? T else {
                throw CloudKitServiceError.invalidRecord
            }
            return result

        case .batchSave(let records):
            saveWasCalled = true
            saveRecords.append(contentsOf: records)

            // Return the saved records
            guard let result = records as? T else {
                throw CloudKitServiceError.invalidRecord
            }
            return result

        case .batchDelete(let recordIDs):
            deleteWasCalled = true
            deleteRecordIDs.append(contentsOf: recordIDs)

            // Return success
            guard let result = recordIDs as? T else {
                throw CloudKitServiceError.invalidRecord
            }
            return result
        }
    }

    // MARK: - Convenience Methods

    /// Get the last saved record
    public var lastSavedRecord: CKRecord? {
        return saveRecords.last
    }

    /// Get the last fetched record ID
    public var lastFetchedRecordID: CKRecord.ID? {
        return saveRecords.last?.recordID
    }

    /// Get the last deleted record ID
    public var lastDeletedRecordID: CKRecord.ID? {
        return deleteRecordIDs.last
    }
}

// MARK: - CloudKit Operation Types (for testing)

/// Simplified CloudKit operation types for testing
public enum CloudKitOperation {
    case save(CKRecord)
    case fetch(CKRecord.ID)
    case delete(CKRecord.ID)
    case query(CKQuery)
    case batchSave([CKRecord])
    case batchDelete([CKRecord.ID])
}