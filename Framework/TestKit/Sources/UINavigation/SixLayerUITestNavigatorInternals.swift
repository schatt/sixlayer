//
//  SixLayerUITestNavigatorInternals.swift
//  SixLayerTestKit
//
//  Testable navigation helpers for SixLayerUITestNavigator (#229).
//

import Foundation

enum SixLayerUITestNavigatorInternals {
    /// Repeatedly runs `attemptBack` while it returns `true`, up to `maxSteps` times. Returns how many successful attempts ran.
    static func consumeBackSteps(maxSteps: Int, attemptBack: () -> Bool) -> Int {
        // TDD red stub (#229): do not invoke attemptBack.
        _ = (maxSteps, attemptBack)
        return 0
    }
}
