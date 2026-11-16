//
//  XCUIElement+SoftLabel.swift
//  SixLayerTestKit
//
//  Soft alert/element label for UI interruption monitors (#584).
//

import Foundation

#if canImport(XCTest)
import XCTest

extension XCUIElement {

    /// Best-effort label that does not fail the test when the hosting process has quit (#584).
    ///
    /// Prefer this over `label` inside UI interruption monitors: a direct attribute
    /// read records `Failed to get matching snapshot: Application … is not running`
    /// as a test failure. `snapshot()` surfaces that as an error instead.
    public var xcuiSoftLabelResult: Result<String, Error> {
        Result { try snapshot().label }
    }
}
#endif
