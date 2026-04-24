//
//  SixLayerUITestNavigatorInternals.swift
//  SixLayerTestKit
//
//  Testable navigation helpers for SixLayerUITestNavigator (#229).
//  See also: Framework/docs/SixLayerUITestNavigator.md
//

import Foundation

enum SixLayerUITestNavigatorInternals {
    /// Repeatedly runs `attemptBack` while it returns `true`, up to `maxSteps` times. Returns how many successful attempts ran.
    static func consumeBackSteps(maxSteps: Int, attemptBack: () -> Bool) -> Int {
        guard maxSteps > 0 else { return 0 }
        var performed = 0
        for _ in 0..<maxSteps {
            if !attemptBack() { break }
            performed += 1
        }
        return performed
    }
}
