//
//  RuntimeOptimization.swift
//  SixLayerFramework
//
//  Host-resource performance strategy. Distinct from Layer 2 content-complexity
//  `PerformanceStrategy`. Call site matches RuntimeCapabilityDetection: statics
//  for live ProcessInfo, `performanceStrategy(for:)` / `isOptimized(for:)` for
//  injected snapshots. Not a process-global apply service.
//

import Foundation

/// Live host-resource optimization probe (`RuntimeOptimization.inputs`,
/// `.performanceStrategy`, `.isOptimized`).
public enum RuntimeOptimization {

    /// How hard the host can be pushed, derived from cores / RAM / thermal state.
    public enum Strategy: String, CaseIterable, Sendable {
        case standard = "standard"
        case optimized = "optimized"
        case highPerformance = "highPerformance"
        case maximumPerformance = "maximumPerformance"
    }

    /// Snapshot of host resources used to choose a strategy.
    public struct Inputs: Equatable, Sendable {
        public var processorCount: Int
        public var physicalMemory: UInt64
        public var thermalState: ProcessInfo.ThermalState

        public init(
            processorCount: Int,
            physicalMemory: UInt64,
            thermalState: ProcessInfo.ThermalState
        ) {
            self.processorCount = processorCount
            self.physicalMemory = physicalMemory
            self.thermalState = thermalState
        }

        public static func current() -> Inputs {
            let process = ProcessInfo.processInfo
            return Inputs(
                processorCount: process.activeProcessorCount,
                physicalMemory: process.physicalMemory,
                thermalState: process.thermalState
            )
        }
    }

    public static var inputs: Inputs { .current() }

    public static var performanceStrategy: Strategy {
        performanceStrategy(for: inputs)
    }

    public static var isOptimized: Bool {
        performanceStrategy != .standard
    }

    /// Choose a performance strategy from host resources.
    ///
    /// Order: processor-count mapping, then memory cap (`< 4 GiB` → `.standard`;
    /// `< 8 GiB` → not above `.optimized`), then thermal cap (`.fair` → not
    /// above `.optimized`; `.serious` / `.critical` → `.standard`).
    public static func performanceStrategy(for inputs: Inputs) -> Strategy {
        var strategy = strategyForProcessorCount(inputs.processorCount)
        strategy = capped(strategy, at: memoryCeiling(for: inputs.physicalMemory))
        strategy = capped(strategy, at: thermalCeiling(for: inputs.thermalState))
        return strategy
    }

    public static func isOptimized(for inputs: Inputs) -> Bool {
        performanceStrategy(for: inputs) != .standard
    }

    /// Processor bands: ≤2 → `.standard`; ≤4 → `.optimized`; ≤8 → `.highPerformance`; else `.maximumPerformance`.
    private static func strategyForProcessorCount(_ processorCount: Int) -> Strategy {
        switch processorCount {
        case ...2:
            return .standard
        case ...4:
            return .optimized
        case ...8:
            return .highPerformance
        default:
            return .maximumPerformance
        }
    }

    private static func memoryCeiling(for physicalMemory: UInt64) -> Strategy? {
        let fourGiB: UInt64 = 4 * 1024 * 1024 * 1024
        let eightGiB: UInt64 = 8 * 1024 * 1024 * 1024
        switch physicalMemory {
        case ..<fourGiB:
            return .standard
        case ..<eightGiB:
            return .optimized
        default:
            return nil
        }
    }

    private static func thermalCeiling(for thermalState: ProcessInfo.ThermalState) -> Strategy? {
        switch thermalState {
        case .fair:
            return .optimized
        case .serious, .critical:
            return .standard
        case .nominal:
            return nil
        @unknown default:
            return nil
        }
    }

    private static func capped(_ strategy: Strategy, at ceiling: Strategy?) -> Strategy {
        guard let ceiling else { return strategy }
        return rank(strategy) <= rank(ceiling) ? strategy : ceiling
    }

    private static func rank(_ strategy: Strategy) -> Int {
        switch strategy {
        case .standard: return 0
        case .optimized: return 1
        case .highPerformance: return 2
        case .maximumPerformance: return 3
        }
    }
}
