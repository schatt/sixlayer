//
//  PlatformMacOSOptimizationsLayer5.swift
//  SixLayerFramework
//
//  Created: August 29, 2025
//  Purpose: macOS-specific Layer 5 optimizations and platform integrations
//

import SwiftUI
import Foundation

#if os(macOS)

/// Layer 5: Platform-Specific Optimizations for macOS
/// This file contains macOS-specific optimizations and platform integrations
/// that enhance performance and user experience on macOS.
///
/// Host-resource strategy selection is distinct from Layer 2 content-complexity
/// `PerformanceStrategy`. Window / menu / a11y apply remains unspecified.

/// macOS-specific performance optimization strategies
public enum MacOSPerformanceStrategy: String, CaseIterable {
    case standard = "standard"
    case optimized = "optimized"
    case highPerformance = "highPerformance"
    case maximumPerformance = "maximumPerformance"
}

/// Snapshot of host resources used to choose a macOS performance strategy.
public struct MacOSOptimizationInputs: Equatable, Sendable {
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

    public static func current() -> MacOSOptimizationInputs {
        let process = ProcessInfo.processInfo
        return MacOSOptimizationInputs(
            processorCount: process.activeProcessorCount,
            physicalMemory: process.physicalMemory,
            thermalState: process.thermalState
        )
    }
}

/// Choose a performance strategy from host resources.
///
/// Order: processor-count mapping, then memory cap (`< 4 GiB` → `.standard`;
/// `< 8 GiB` → not above `.optimized`), then thermal cap (`.fair` → not
/// above `.optimized`; `.serious` / `.critical` → `.standard`).
public func macOSPerformanceStrategy(for inputs: MacOSOptimizationInputs) -> MacOSPerformanceStrategy {
    var strategy = strategyForProcessorCount(inputs.processorCount)
    strategy = capped(strategy, at: memoryCeiling(for: inputs.physicalMemory))
    strategy = capped(strategy, at: thermalCeiling(for: inputs.thermalState))
    return strategy
}

private func strategyForProcessorCount(_ processorCount: Int) -> MacOSPerformanceStrategy {
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

private func memoryCeiling(for physicalMemory: UInt64) -> MacOSPerformanceStrategy? {
    let fourGiB: UInt64 = 4 * 1024 * 1024 * 1024
    let eightGiB: UInt64 = 8 * 1024 * 1024 * 1024
    if physicalMemory < fourGiB {
        return .standard
    }
    if physicalMemory < eightGiB {
        return .optimized
    }
    return nil
}

private func thermalCeiling(for thermalState: ProcessInfo.ThermalState) -> MacOSPerformanceStrategy? {
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

private func capped(
    _ strategy: MacOSPerformanceStrategy,
    at ceiling: MacOSPerformanceStrategy?
) -> MacOSPerformanceStrategy {
    guard let ceiling else { return strategy }
    return rank(strategy) <= rank(ceiling) ? strategy : ceiling
}

private func rank(_ strategy: MacOSPerformanceStrategy) -> Int {
    switch strategy {
    case .standard: return 0
    case .optimized: return 1
    case .highPerformance: return 2
    case .maximumPerformance: return 3
    }
}

/// macOS-specific optimization manager
@MainActor
public class MacOSOptimizationManager: @unchecked Sendable {

    /// Shared instance for macOS optimizations
    @MainActor
    public static let shared = MacOSOptimizationManager()

    private let fixedInputs: MacOSOptimizationInputs?

    public init(inputs: MacOSOptimizationInputs? = nil) {
        self.fixedInputs = inputs
    }

    /// Get current macOS performance strategy from injected or live inputs.
    func getCurrentPerformanceStrategy() -> MacOSPerformanceStrategy {
        macOSPerformanceStrategy(for: fixedInputs ?? .current())
    }

    /// Apply macOS-specific optimizations
    /// Currently a no-op (window / menu / a11y apply is unspecified)
    func applyMacOSOptimizations() {
        // Window management, menu bar, and a11y apply are out of scope for #422.
    }
}

/// Extension to provide macOS-specific functionality
extension MacOSOptimizationManager {

    /// Whether the current strategy is an optimized path (`!= .standard`).
    public var isMacOSOptimized: Bool {
        getCurrentPerformanceStrategy() != .standard
    }

    /// Get macOS version for optimization decisions
    public var macOSVersion: String {
        return ProcessInfo.processInfo.operatingSystemVersionString
    }
}

#endif
