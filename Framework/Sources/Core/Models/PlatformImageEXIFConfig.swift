//
//  PlatformImageEXIFConfig.swift
//  SixLayerFramework
//
//  Framework-wide configuration for PlatformImage EXIF writers.
//  Implements GitHub Issue #275.
//
//  Owns the default container format (HEIC) used by writer APIs that do not
//  take an explicit format argument. Mirrors the existing `*.shared` config
//  pattern in the framework (e.g. AccessibilityIdentifierConfig) and supports
//  per-test isolation via `@TaskLocal` so parallel tests do not race on the
//  singleton.
//

import Foundation

/// Configuration for `PlatformImage.exif` writer APIs (Issue #275).
///
/// The `defaultWriteFormat` controls which container format the writer uses
/// when no explicit format is provided. Defaults to `.heic`.
///
/// ## Parallel test safety
/// Tests should override the default via `withTaskLocalConfig`, not by mutating
/// `.shared`. Framework code resolves the active config through `current`,
/// which prefers the task-local override when present.
public final class PlatformImageEXIFConfig: @unchecked Sendable {
    /// Shared singleton (production default).
    public static let shared = PlatformImageEXIFConfig()

    /// Task-local override for per-test isolation. Set via `withTaskLocalConfig`.
    @TaskLocal internal static var taskLocalConfig: PlatformImageEXIFConfig?

    /// Default container format used by writers when no explicit format is provided.
    /// Defaults to `.heic`. Falls back to `.jpeg` at the writer if the runtime
    /// cannot produce HEIC.
    public var defaultWriteFormat: ImageFormat = .heic

    /// Resolves the active config for the current task.
    /// Prefers the `@TaskLocal` override, then falls back to `shared`.
    internal static var current: PlatformImageEXIFConfig {
        taskLocalConfig ?? shared
    }

    public init() {}

    /// Run `body` with `config` installed as the task-local default.
    /// Use this in tests to override `defaultWriteFormat` without mutating `.shared`.
    public static func withTaskLocalConfig<T>(
        _ config: PlatformImageEXIFConfig,
        _ body: () throws -> T
    ) rethrows -> T {
        try Self.$taskLocalConfig.withValue(config, operation: body)
    }
}
