//
//  Layer6PerformanceMetricsNonFiniteTests.swift
//  SixLayerFrameworkUnitTests
//
//  Issue #711: RenderingMetrics.record / MemoryMetrics.record are public and
//  PerformanceMeasurement.value is an arbitrary Double. `Int(_)` / `Int64(_)`
//  trap on NaN, infinity, and out-of-range values, so one bad measurement could
//  abort a consumer's process. Policy: NaN is invalid data and is skipped
//  (previous value kept); infinity and out-of-range values saturate; in-range
//  values truncate toward zero as before.
//

import Foundation
import Testing
@testable import SixLayerFramework

@Suite("Layer 6 performance metrics: non-finite measurements (#711)")
struct Layer6PerformanceMetricsNonFiniteTests {

    private func rendering(_ metric: PerformanceMetric, _ value: Double) -> PerformanceMeasurement {
        PerformanceMeasurement(type: .rendering, metric: metric, value: value)
    }

    private func memory(_ metric: PerformanceMetric, _ value: Double) -> PerformanceMeasurement {
        PerformanceMeasurement(type: .memory, metric: metric, value: value)
    }

    // MARK: - Rendering

    @Test func drawCalls_inRangeValueTruncatesTowardZero() {
        var metrics = RenderingMetrics()
        metrics.record(rendering(.drawCalls, 12.9))
        #expect(metrics.drawCalls == 12)
    }

    @Test func drawCalls_nanKeepsThePreviousValue() {
        var metrics = RenderingMetrics()
        metrics.record(rendering(.drawCalls, 7))
        metrics.record(rendering(.drawCalls, .nan))
        #expect(metrics.drawCalls == 7)
    }

    @Test func drawCalls_infinitySaturates() {
        var metrics = RenderingMetrics()
        metrics.record(rendering(.drawCalls, .infinity))
        #expect(metrics.drawCalls == Int.max)
    }

    @Test func textureMemory_hugeValueSaturates() {
        var metrics = RenderingMetrics()
        metrics.record(rendering(.textureMemory, 1e30))
        #expect(metrics.textureMemory == Int64.max)
    }

    @Test func textureMemory_nanKeepsThePreviousValue() {
        var metrics = RenderingMetrics()
        metrics.record(rendering(.textureMemory, 4096))
        metrics.record(rendering(.textureMemory, .nan))
        #expect(metrics.textureMemory == 4096)
    }

    // MARK: - Memory

    @Test func usedMemory_negativeInfinitySaturates() {
        var metrics = MemoryMetrics()
        metrics.record(memory(.usedMemory, -.infinity))
        #expect(metrics.usedMemory == Int64.min)
    }

    @Test func usedMemory_nanKeepsThePreviousValue() {
        var metrics = MemoryMetrics()
        metrics.record(memory(.usedMemory, 1024))
        metrics.record(memory(.usedMemory, .nan))
        #expect(metrics.usedMemory == 1024)
    }

    @Test func peakMemory_hugeValueSaturates() {
        var metrics = MemoryMetrics()
        metrics.record(memory(.peakMemory, 1e30))
        #expect(metrics.peakMemory == Int64.max)
    }

    @Test func peakMemory_nanKeepsThePreviousValue() {
        var metrics = MemoryMetrics()
        metrics.record(memory(.peakMemory, 2048))
        metrics.record(memory(.peakMemory, .nan))
        #expect(metrics.peakMemory == 2048)
    }

    @Test func memoryPressure_knownLevelsMap() {
        var metrics = MemoryMetrics()
        metrics.record(memory(.memoryPressure, 1))
        #expect(metrics.memoryPressure == .warning)
        metrics.record(memory(.memoryPressure, 2.7))
        #expect(metrics.memoryPressure == .critical)
    }

    @Test func memoryPressure_outOfRangeLevelFallsBackToNormal() {
        var metrics = MemoryMetrics()
        metrics.record(memory(.memoryPressure, 2))
        metrics.record(memory(.memoryPressure, 1e30))
        #expect(metrics.memoryPressure == .normal)
    }

    @Test func memoryPressure_nanKeepsThePreviousLevel() {
        var metrics = MemoryMetrics()
        metrics.record(memory(.memoryPressure, 2))
        metrics.record(memory(.memoryPressure, .nan))
        #expect(metrics.memoryPressure == .critical)
    }
}
