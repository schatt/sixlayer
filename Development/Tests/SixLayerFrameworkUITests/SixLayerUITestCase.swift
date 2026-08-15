//
//  SixLayerUITestCase.swift
//  SixLayerFrameworkUITests
//
//  Shared XCTestCase base for UITest suites. Keep this a no-op pass-through —
// do not add cross-process file locks here (sandboxed runners cannot use /tmp;
// that broke macOS UITests on CI — #400).
//

import XCTest

/// Base class for XCUITests. Subclasses may override hooks later; do not gate
/// on filesystem locks from the test runner process.
open class SixLayerUITestCase: XCTestCase {
    /// Reserved for future exclusive-app coordination that does not use /tmp.
    /// Currently unused — left so navigator can keep `override var … { false }`.
    open var usesExclusiveTestApp: Bool { true }
}
