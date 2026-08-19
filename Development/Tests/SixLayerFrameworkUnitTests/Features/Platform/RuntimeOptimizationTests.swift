import Foundation
import Testing
import SixLayerFramework

/// Host-resource strategy coverage for `RuntimeOptimization` (#422).
/// Shared unit sources; no hosting.
private let gib: UInt64 = 1024 * 1024 * 1024

@Suite("Runtime Optimization")
open class RuntimeOptimizationTests: BaseTestClass {

    @Test func testStrategyAllCasesAreCompleteAndUnique() {
        let cases = RuntimeOptimization.Strategy.allCases
        #expect(
            cases == [.standard, .optimized, .highPerformance, .maximumPerformance],
            "allCases must stay complete; adding a strategy is a deliberate API change"
        )
        let raw = cases.map(\.rawValue)
        #expect(Set(raw).count == raw.count, "Raw values must be unique")
        #expect(raw.allSatisfy { !$0.isEmpty }, "Raw values must be non-empty")
    }

    @Test func testLiveInputsMatchProcessInfoOnHost() {
        let current = RuntimeOptimization.inputs
        let process = ProcessInfo.processInfo
        #expect(current.processorCount == process.activeProcessorCount)
        #expect(current.physicalMemory == process.physicalMemory)
        #expect(current.thermalState == process.thermalState)
        #expect(current == RuntimeOptimization.Inputs.current())
    }

    @Test func testLiveStaticsMatchPureMapOfCurrentInputs() {
        let mapped = RuntimeOptimization.performanceStrategy(for: RuntimeOptimization.inputs)
        #expect(RuntimeOptimization.performanceStrategy == mapped)
        #expect(RuntimeOptimization.isOptimized == (mapped != .standard))
    }

    @Test func testProcessorCountMapsToStrategyWhenNominalAndPlentyOfMemory() {
        #expect(RuntimeOptimization.performanceStrategy(for: inputs(processors: 1)) == .standard)
        #expect(RuntimeOptimization.performanceStrategy(for: inputs(processors: 2)) == .standard)
        #expect(RuntimeOptimization.performanceStrategy(for: inputs(processors: 3)) == .optimized)
        #expect(RuntimeOptimization.performanceStrategy(for: inputs(processors: 4)) == .optimized)
        #expect(RuntimeOptimization.performanceStrategy(for: inputs(processors: 5)) == .highPerformance)
        #expect(RuntimeOptimization.performanceStrategy(for: inputs(processors: 8)) == .highPerformance)
        #expect(RuntimeOptimization.performanceStrategy(for: inputs(processors: 9)) == .maximumPerformance)
        #expect(RuntimeOptimization.performanceStrategy(for: inputs(processors: 16)) == .maximumPerformance)
    }

    @Test func testMemoryBandsForceStandardThenCapOptimized() {
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 16, memory: 2 * gib)) == .standard,
            "Under 4 GiB is standard even with many cores"
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 16, memory: 4 * gib - 1)) == .standard,
            "Just under 4 GiB is still the standard band"
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 16, memory: 4 * gib)) == .optimized,
            "4 GiB is below 8 GiB so the ceiling is optimized, not maximum"
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 16, memory: 8 * gib - 1)) == .optimized,
            "Just under 8 GiB stays capped at optimized"
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 16, memory: 8 * gib)) == .maximumPerformance,
            "Exactly 8 GiB is not under the optimized memory cap"
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 1, memory: 2 * gib)) == .standard,
            "Low memory must not raise a standard processor mapping"
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 4, memory: 4 * gib)) == .optimized,
            "4 cores at 4 GiB stay optimized (processor mapping, 8 GiB ceiling)"
        )
    }

    @Test func testFairThermalCapsStrategyAtOptimized() {
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 16, thermal: .fair)) == .optimized
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 1, thermal: .fair)) == .standard
        )
    }

    @Test func testSeriousAndCriticalThermalForceStandard() {
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 16)) == .maximumPerformance,
            "Baseline: 16 cores nominal must not already be standard or thermal caps are invisible"
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 16, thermal: .serious)) == .standard
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: inputs(processors: 16, thermal: .critical)) == .standard
        )
    }

    @Test func testThermalCapWinsOverHighMemoryAndCoreCount() {
        let unconstrained = RuntimeOptimization.Inputs(
            processorCount: 16,
            physicalMemory: 64 * gib,
            thermalState: .nominal
        )
        #expect(
            RuntimeOptimization.performanceStrategy(for: unconstrained) == .maximumPerformance,
            "Baseline: unconstrained 16-core host must map to maximum or the critical cap is invisible"
        )
        #expect(
            RuntimeOptimization.performanceStrategy(
                for: RuntimeOptimization.Inputs(
                    processorCount: 16,
                    physicalMemory: 64 * gib,
                    thermalState: .critical
                )
            ) == .standard
        )
    }

    @Test func testIsOptimizedFollowsInjectedStrategy() {
        #expect(RuntimeOptimization.isOptimized(for: inputs(processors: 16)))
        #expect(!RuntimeOptimization.isOptimized(for: inputs(processors: 1)))
    }

    private func inputs(
        processors: Int,
        memory: UInt64 = 16 * gib,
        thermal: ProcessInfo.ThermalState = .nominal
    ) -> RuntimeOptimization.Inputs {
        RuntimeOptimization.Inputs(
            processorCount: processors,
            physicalMemory: memory,
            thermalState: thermal
        )
    }
}
