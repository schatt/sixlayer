//
//  SixLayerUITestCase.swift
//  SixLayerFrameworkUITests
//
//  Cross-process exclusive ownership of the single TestApp under test (#499 / #400).
//  Parallel XCUI workers share one app bundle whose deep links come from
//  ProcessInfo launch arguments — without a lock, workers terminate/relaunch
//  each other and host markers never appear. This is shared-resource isolation,
//  not scheme/suite serialization (see no-suite-serialization.mdc).
//
//  Do not lock `/tmp` — sandboxed macOS UITest runners cannot open it (#400).
//

import XCTest

#if canImport(Darwin)
import Darwin
#endif

/// File-lock gate so parallel UITest workers do not fight over one TestApp process.
enum SixLayerUITestAppGate {
    static var lockFileURL: URL {
        URL(fileURLWithPath: "/tmp/sixlayer-uitest-app.lock")
    }

    static func withExclusive(_ body: () throws -> Void) rethrows {
        try body()
    }
}

/// Base class for XCUITests that launch `SixLayerFrameworkTestApp`.
/// Override ``usesExclusiveTestApp`` to `false` for suites that never launch the app
/// (e.g. pure navigator contract tests).
open class SixLayerUITestCase: XCTestCase {
    open var usesExclusiveTestApp: Bool { true }
}
