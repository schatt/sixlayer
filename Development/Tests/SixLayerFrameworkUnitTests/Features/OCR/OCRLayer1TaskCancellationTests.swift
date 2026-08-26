//
//  OCRLayer1TaskCancellationTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Layer 1 OCR wrappers must cancel in-flight recognition when the hosting view
//  disappears. Unstructured `Task` spawned from `.task` / `onAppear` is not
//  cancelled with the view and can stack Vision work (GitHub #436).
//
//  TESTING SCOPE:
//  - Visual correction L1: teardown cancels hanging processImage
//  - Structured extraction L1: same
//  - Repeated host/teardown does not accumulate in-flight work or unbounded RSS
//

import Darwin
import Foundation
import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("OCR Layer 1 Task Cancellation", HostedViewTestIsolationTrait())
@MainActor
open class OCRLayer1TaskCancellationTests: BaseTestClass {

    @Test func testVisualCorrectionHostTeardownCancelsInFlightOCR() async {
        await assertHostTeardownCancelsInFlightOCR(
            makeView: { image, context, onResult, mock in
                platformOCRWithVisualCorrection_L1(
                    image: image,
                    context: context,
                    onResult: onResult
                )
                .environment(\.sixLayerOCRService, mock)
            }
        )
    }

    @Test func testStructuredExtractionHostTeardownCancelsInFlightOCR() async {
        await assertHostTeardownCancelsInFlightOCR(
            makeView: { image, context, onResult, mock in
                platformExtractStructuredData_L1(
                    image: image,
                    context: context,
                    onResult: onResult
                )
                .environment(\.sixLayerOCRService, mock)
            }
        )
    }

    @Test func testRepeatedVisualCorrectionHostTeardownKeepsResidentSizeBounded() async {
        let mock = HangingOCRService()
        let resultCount = CallbackCounter()
        let context = OCRContext()
        let image = PlatformImage()
        let rssBefore = currentResidentBytes()

        await OCRServiceFactory.$testOverride.withValue(mock) {
            for cycle in 0..<12 {
                let hosted = hostRootPlatformView(
                    platformOCRWithVisualCorrection_L1(
                        image: image,
                        context: context,
                        onResult: { _ in resultCount.increment() }
                    )
                    .environment(\.sixLayerOCRService, mock),
                    forceLayout: true
                )
                guard hosted != nil else { return }

                let started = await waitUntil(timeout: 2.0) { mock.started > cycle }
                #expect(started, "cycle \(cycle): OCR .task should start under host")
                guard started else { return }

                HostingControllerStorage.tearDownActiveSession()
                pumpRunLoop(for: 0.05)

                let idle = await waitUntil(timeout: 2.0) { mock.inFlight == 0 }
                #expect(idle, "cycle \(cycle): in-flight OCR should be 0 after teardown, was \(mock.inFlight)")
                guard idle else { return }
            }
        }

        #expect(mock.completed == 0, "cancelled OCR must not complete")
        #expect(resultCount.value == 0, "onResult must not fire after cancel")

        let rssAfter = currentResidentBytes()
        let growth = rssAfter > rssBefore ? rssAfter - rssBefore : 0
        print("OCR L1 RSS #436 before=\(rssBefore) after=\(rssAfter) growth=\(growth) bytes")
        // 64 MiB bound is generous for 12 host/teardown cycles of a hanging mock (no Vision).
        // Unbounded growth would indicate leaked tasks/images, not Mini 16 GB by itself.
        #expect(
            growth < 64 * 1024 * 1024,
            "resident size grew by \(growth) bytes (before \(rssBefore), after \(rssAfter))"
        )
    }

    // MARK: - Shared assertion

    private func assertHostTeardownCancelsInFlightOCR<V: View>(
        makeView: (PlatformImage, OCRContext, @escaping (OCRResult) -> Void, HangingOCRService) -> V
    ) async {
        let mock = HangingOCRService()
        let resultCount = CallbackCounter()
        let context = OCRContext()
        let image = PlatformImage()

        await OCRServiceFactory.$testOverride.withValue(mock) {
            let hosted = hostRootPlatformView(
                makeView(image, context, { _ in resultCount.increment() }, mock),
                forceLayout: true
            )
            guard hosted != nil else { return }

            let started = await waitUntil(timeout: 2.0) { mock.started >= 1 }
            #expect(started, "OCR work should start when the L1 view is hosted (started=\(mock.started))")
            guard started else { return }

            HostingControllerStorage.tearDownActiveSession()
            pumpRunLoop(for: 0.05)

            let cancelled = await waitUntil(timeout: 2.0) { mock.inFlight == 0 }
            #expect(
                cancelled,
                "in-flight OCR should drop to 0 after host teardown (inFlight=\(mock.inFlight), completed=\(mock.completed))"
            )
            #expect(mock.completed == 0, "cancelled OCR must not complete")
            #expect(resultCount.value == 0, "onResult must not fire after cancel")
        }
    }
}

// MARK: - Hanging mock

private final class HangingOCRService: OCRServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _started = 0
    private var _inFlight = 0
    private var _completed = 0
    private var _cancelled = 0

    var started: Int { lock.withLock { _started } }
    var inFlight: Int { lock.withLock { _inFlight } }
    var completed: Int { lock.withLock { _completed } }
    var cancelled: Int { lock.withLock { _cancelled } }

    var isAvailable: Bool { true }

    var capabilities: OCRCapabilities {
        OCRCapabilities(
            supportsVision: true,
            supportedLanguages: [.english],
            supportedTextTypes: [.general],
            maxImageSize: CGSize(width: 1000, height: 1000),
            processingTimeEstimate: 60
        )
    }

    func processImage(
        _ image: PlatformImage,
        context: OCRContext,
        strategy: OCRStrategy
    ) async throws -> OCRResult {
        lock.withLock {
            _started += 1
            _inFlight += 1
        }
        defer {
            lock.withLock { _inFlight -= 1 }
        }
        do {
            try await Task.sleep(for: .seconds(60))
        } catch is CancellationError {
            lock.withLock { _cancelled += 1 }
            throw CancellationError()
        }
        lock.withLock { _completed += 1 }
        return OCRResult(
            extractedText: "should-not-complete",
            confidence: 0.5
        )
    }
}

private final class CallbackCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0
    var value: Int { lock.withLock { _value } }
    func increment() { lock.withLock { _value += 1 } }
}

@MainActor
private func pumpRunLoop(for duration: TimeInterval) {
    let deadline = Date().addingTimeInterval(duration)
    while Date() < deadline {
        RunLoop.main.run(mode: .common, before: Date(timeIntervalSinceNow: 0.005))
    }
}

@MainActor
private func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    if condition() { return true }
    while Date() < deadline {
        pumpRunLoop(for: 0.02)
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}

private func currentResidentBytes() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
    let kernelResult = withUnsafeMutablePointer(to: &info) { infoPointer in
        infoPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), rebound, &count)
        }
    }
    guard kernelResult == KERN_SUCCESS else { return 0 }
    return UInt64(info.resident_size)
}
