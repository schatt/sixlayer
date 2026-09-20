//
//  SixLayerUITestAppGateTests.swift
//  SixLayerFrameworkUITests
//
//  #499: exclusive TestApp gate must use a sandbox-writable lock, not /tmp (#400).
//

import XCTest

#if canImport(Darwin)
import Darwin
#endif

final class SixLayerUITestAppGateTests: XCTestCase {
    func testLockFileLivesInProcessTemporaryDirectory() {
        let tmp = FileManager.default.temporaryDirectory.standardizedFileURL
        let lock = SixLayerUITestAppGate.lockFileURL.standardizedFileURL
        XCTAssertNotEqual(
            lock.path,
            "/tmp/sixlayer-uitest-app.lock",
            "global /tmp is not writable for sandboxed macOS UITest runners (#400)"
        )
        XCTAssertEqual(lock.lastPathComponent, "sixlayer-uitest-app.lock")
        XCTAssertTrue(
            lock.path.hasPrefix(tmp.path),
            "lock must live in the runner tmp (container-writable); lock=\(lock.path) tmp=\(tmp.path)"
        )
    }

    func testLockFileIsWritable() {
        let url = SixLayerUITestAppGate.lockFileURL
        let parent = url.deletingLastPathComponent()
        XCTAssertNoThrow(
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        )
        #if canImport(Darwin)
        let fd = open(url.path, O_CREAT | O_RDWR, 0o644)
        XCTAssertGreaterThanOrEqual(fd, 0, "runner must be able to open \(url.path)")
        if fd >= 0 {
            close(fd)
        }
        #endif
    }

    func testWithExclusiveRunsBody() {
        var ran = false
        SixLayerUITestAppGate.withExclusive {
            ran = true
        }
        XCTAssertTrue(ran)
    }
}
