import Foundation
import Testing
@testable import SixLayerFramework

/// Host-resource strategy coverage for `MacOSOptimizationManager` (#422).
/// macOS unit lane only. Do not host views. Do not lock stub constants.
#if os(macOS)
private let gib: UInt64 = 1024 * 1024 * 1024

@Suite("MacOS Optimization Manager")
open class MacOSOptimizationManagerTests: BaseTestClass {

    @Test func testMacOSPerformanceStrategyAllCasesAreCompleteAndUnique() {
        let cases = MacOSPerformanceStrategy.allCases
        #expect(
            cases == [.standard, .optimized, .highPerformance, .maximumPerformance],
            "allCases must stay complete; adding a strategy is a deliberate API change"
        )
        let raw = cases.map(\.rawValue)
        #expect(Set(raw).count == raw.count, "Raw values must be unique")
        #expect(raw.allSatisfy { !$0.isEmpty }, "Raw values must be non-empty")
    }

    @Test func testMacOSVersionMatchesProcessInfoOnHost() {
        let manager = MacOSOptimizationManager()
        let processVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #expect(!manager.macOSVersion.isEmpty, "macOSVersion should be non-empty on the test host")
        #expect(
            manager.macOSVersion == processVersion,
            "macOSVersion should match ProcessInfo on this host"
        )
    }

    @Test func testCurrentInputsMatchProcessInfoOnHost() {
        let current = MacOSOptimizationInputs.current()
        let process = ProcessInfo.processInfo
        #expect(current.processorCount == process.activeProcessorCount)
        #expect(current.physicalMemory == process.physicalMemory)
        #expect(current.thermalState == process.thermalState)
    }

    @Test func testProcessorCountMapsToStrategyWhenNominalAndPlentyOfMemory() {
        #expect(macOSPerformanceStrategy(for: inputs(processors: 1)) == .standard)
        #expect(macOSPerformanceStrategy(for: inputs(processors: 2)) == .standard)
        #expect(macOSPerformanceStrategy(for: inputs(processors: 3)) == .optimized)
        #expect(macOSPerformanceStrategy(for: inputs(processors: 4)) == .optimized)
        #expect(macOSPerformanceStrategy(for: inputs(processors: 5)) == .highPerformance)
        #expect(macOSPerformanceStrategy(for: inputs(processors: 8)) == .highPerformance)
        #expect(macOSPerformanceStrategy(for: inputs(processors: 9)) == .maximumPerformance)
        #expect(macOSPerformanceStrategy(for: inputs(processors: 16)) == .maximumPerformance)
    }

    @Test func testMemoryBandsForceStandardThenCapOptimized() {
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 16, memory: 2 * gib)) == .standard,
            "Under 4 GiB is standard even with many cores"
        )
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 16, memory: 4 * gib - 1)) == .standard,
            "Just under 4 GiB is still the standard band"
        )
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 16, memory: 4 * gib)) == .optimized,
            "4 GiB is below 8 GiB so the ceiling is optimized, not maximum"
        )
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 16, memory: 8 * gib - 1)) == .optimized,
            "Just under 8 GiB stays capped at optimized"
        )
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 16, memory: 8 * gib)) == .maximumPerformance,
            "Exactly 8 GiB is not under the optimized memory cap"
        )
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 1, memory: 2 * gib)) == .standard,
            "Low memory must not raise a standard processor mapping"
        )
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 4, memory: 4 * gib)) == .optimized,
            "4 cores at 4 GiB stay optimized (processor mapping, 8 GiB ceiling)"
        )
    }

    @Test func testFairThermalCapsStrategyAtOptimized() {
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 16, thermal: .fair)) == .optimized
        )
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 1, thermal: .fair)) == .standard
        )
    }

    @Test func testSeriousAndCriticalThermalForceStandard() {
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 16)) == .maximumPerformance,
            "Baseline: 16 cores nominal must not already be standard or thermal caps are invisible"
        )
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 16, thermal: .serious)) == .standard
        )
        #expect(
            macOSPerformanceStrategy(for: inputs(processors: 16, thermal: .critical)) == .standard
        )
    }

    @Test func testThermalCapWinsOverHighMemoryAndCoreCount() {
        let unconstrained = MacOSOptimizationInputs(
            processorCount: 16,
            physicalMemory: 64 * gib,
            thermalState: .nominal
        )
        #expect(
            macOSPerformanceStrategy(for: unconstrained) == .maximumPerformance,
            "Baseline: unconstrained 16-core host must map to maximum or the critical cap is invisible"
        )
        #expect(
            macOSPerformanceStrategy(
                for: MacOSOptimizationInputs(
                    processorCount: 16,
                    physicalMemory: 64 * gib,
                    thermalState: .critical
                )
            ) == .standard
        )
    }

    @Test func testDefaultInitUsesLiveHostStrategy() {
        let manager = MacOSOptimizationManager()
        #expect(
            manager.getCurrentPerformanceStrategy() == macOSPerformanceStrategy(for: .current()),
            "Default init must use live ProcessInfo inputs, not a process-global singleton"
        )
        #expect(manager.isMacOSOptimized == (manager.getCurrentPerformanceStrategy() != .standard))
    }

    @Test func testManagerUsesInjectedInputsForStrategyAndOptimizedFlag() {
        let fast = MacOSOptimizationManager(inputs: inputs(processors: 16))
        #expect(fast.getCurrentPerformanceStrategy() == .maximumPerformance)
        #expect(fast.isMacOSOptimized, "Non-standard strategy means the host is on an optimized path")

        let slow = MacOSOptimizationManager(inputs: inputs(processors: 1))
        #expect(slow.getCurrentPerformanceStrategy() == .standard)
        #expect(!slow.isMacOSOptimized, "Standard strategy is not an optimized path")
    }

    @Test func testInjectedManagersDoNotShareOptimizationState() {
        let a = MacOSOptimizationManager(inputs: inputs(processors: 16))
        let b = MacOSOptimizationManager(inputs: inputs(processors: 1))
        #expect(a.getCurrentPerformanceStrategy() == .maximumPerformance)
        #expect(b.getCurrentPerformanceStrategy() == .standard)
        #expect(a.isMacOSOptimized)
        #expect(!b.isMacOSOptimized)
    }

    private func inputs(
        processors: Int,
        memory: UInt64 = 16 * gib,
        thermal: ProcessInfo.ThermalState = .nominal
    ) -> MacOSOptimizationInputs {
        MacOSOptimizationInputs(
            processorCount: processors,
            physicalMemory: memory,
            thermalState: thermal
        )
    }
}
#endif
