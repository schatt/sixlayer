//
//  VisionRequestResumeTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Barcode detection and safe Vision OCR resume one continuation from the
//  request completion and again from `VNImageRequestHandler.perform`'s throw.
//  A second resume traps the process (#574).
//
//  TESTING SCOPE:
//  - Completion then perform-throw keeps the completion value and resumes once.
//  - Perform-throw then a late completion keeps the throw and resumes once.
//

import Testing
@testable import SixLayerFramework

private struct VisionResumeProbeError: Error {}

private final class VisionResumeLog<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [Result<T, Error>] = []

    var results: [Result<T, Error>] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func resume(with result: Result<T, Error>) {
        lock.lock()
        stored.append(result)
        lock.unlock()
    }
}

@Suite("Vision request resume")
struct VisionRequestResumeTests {

    /// Completion resumes, then `perform` throws. The throw must not resume again.
    @Test func completionThenPerformThrowKeepsTheFirstResult() throws {
        let sink = VisionResumeLog<String>()
        runVisionRequest(onResume: sink.resume(with:)) { resume in
            resume(.success("33.82"))
            throw VisionResumeProbeError()
        }
        #expect(sink.results.count == 1)
        #expect(try sink.results.first?.get() == "33.82")
    }

    /// `perform` throws before a late completion. The completion must not replace the error.
    @Test func performThrowThenLateCompletionKeepsTheThrow() {
        let sink = VisionResumeLog<String>()
        var resume: ((Result<String, Error>) -> Void)?
        runVisionRequest(onResume: sink.resume(with:)) { attempt in
            resume = attempt
            throw VisionResumeProbeError()
        }
        resume?(.success("late"))
        #expect(sink.results.count == 1)
        #expect(throws: VisionResumeProbeError.self) {
            try sink.results.first?.get()
        }
    }
}
