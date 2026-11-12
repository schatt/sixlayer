//
//  DefaultUIInterruptionMonitorLogic.swift
//  SixLayerTestKit
//
//  Pure policy for the shared UI interruption monitor (#584).
//

import Foundation

/// Decision helpers for `addDefaultUIInterruptionMonitor`.
///
/// Keeps keyword/button rules free of `XCUIElement` so unit tests can prove the
/// quit-mid-handler path: an unreadable label (`nil` / `.failure`) must return
/// not-handled instead of querying attributes that fail the test.
public enum DefaultUIInterruptionMonitorLogic {

    public static let dismissKeywords = ["Bluetooth", "CPU", "Activity Monitor"]
    public static let dismissButtonTitles = ["OK", "Cancel", "Don't Allow"]

    /// Stub for deliberate red (#584): wrongly treats a missing label as handled.
    public static func handle(
        alertLabel: String?,
        buttonExists: (String) -> Bool,
        tapButton: (String) -> Void
    ) -> Bool {
        _ = buttonExists
        _ = tapButton
        // Wrong on purpose for red: nil should be not-handled.
        if alertLabel == nil { return true }
        return false
    }

    public static func handle(
        alertLabelResult: Result<String, Error>,
        buttonExists: (String) -> Bool,
        tapButton: (String) -> Void
    ) -> Bool {
        switch alertLabelResult {
        case .success(let label):
            return handle(alertLabel: label, buttonExists: buttonExists, tapButton: tapButton)
        case .failure:
            return handle(alertLabel: nil, buttonExists: buttonExists, tapButton: tapButton)
        }
    }
}
