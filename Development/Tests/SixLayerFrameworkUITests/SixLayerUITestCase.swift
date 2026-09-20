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
//  Lock lives in the UITest runner's container tmp, not `/tmp` (#400).
//

import XCTest

#if os(macOS)
import Darwin
#endif

/// File-lock gate so parallel UITest workers do not fight over one TestApp process.
enum SixLayerUITestAppGate {
    private static let lockFileName = "sixlayer-uitest-app.lock"

    static var lockFileURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(lockFileName)
            .standardizedFileURL
    }

    static func withExclusive(_ body: () throws -> Void) rethrows {
        #if os(macOS)
        let url = lockFileURL
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let fd = open(url.path, O_CREAT | O_RDWR, 0o644)
        guard fd >= 0 else {
            fatalError("SixLayerUITestAppGate: could not open \(url.path)")
        }
        let locked = flock(fd, LOCK_EX)
        guard locked == 0 else {
            close(fd)
            fatalError("SixLayerUITestAppGate: could not flock \(url.path)")
        }
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
/// (e.g. pure navigator contract tests).
open class SixLayerUITestCase: XCTestCase {
    open var usesExclusiveTestApp: Bool { true }

    #if os(macOS)
    open override func invokeTest() {
        if usesExclusiveTestApp {
            SixLayerUITestAppGate.withExclusive {
                super.invokeTest()
            }
        } else {
            super.invokeTest()
        }
    }
    #endif
}
