//
//  SixLayerUITestCase.swift
//  SixLayerFrameworkUITests
//
//  Cross-process exclusive ownership of the single TestApp under test (#400).
//  Parallel XCUI workers share one app bundle whose deep links come from
//  ProcessInfo launch arguments — without a lock, workers terminate/relaunch
//  each other and host markers never appear. This is shared-resource isolation,
//  not scheme/suite serialization (see no-suite-serialization.mdc).
//

import XCTest

#if canImport(Darwin)
import Darwin
#endif

/// File-lock gate so parallel UITest workers do not fight over one TestApp process.
enum SixLayerUITestAppGate {
    private static let lockPath = "/tmp/sixlayer-uitest-app.lock"

    static func withExclusive(_ body: () throws -> Void) rethrows {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let fd = open(lockPath, O_CREAT | O_RDWR, 0o644)
        precondition(fd >= 0, "SixLayerUITestAppGate: could not open \(lockPath)")
        let locked = flock(fd, LOCK_EX)
        precondition(locked == 0, "SixLayerUITestAppGate: could not flock \(lockPath)")
        defer {
            _ = flock(fd, LOCK_UN)
            close(fd)
        }
        try body()
        #else
        try body()
        #endif
    }
}

/// Base class for XCUITests that launch `SixLayerFrameworkTestApp`.
/// Override ``usesExclusiveTestApp`` to `false` for suites that never launch the app
/// (e.g. pure navigator contract unit-style tests).
open class SixLayerUITestCase: XCTestCase {
    open var usesExclusiveTestApp: Bool { true }

    open override func invokeTest() {
        if usesExclusiveTestApp {
            SixLayerUITestAppGate.withExclusive {
                super.invokeTest()
            }
        } else {
            super.invokeTest()
        }
    }
}
