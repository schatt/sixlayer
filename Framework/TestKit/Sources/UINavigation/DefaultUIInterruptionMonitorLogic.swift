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

    /// Whether the alert label matches a system dialog we dismiss.
    public static func shouldAttemptDismiss(alertLabel: String) -> Bool {
        dismissKeywords.contains { alertLabel.contains($0) }
    }

    /// Handle using an optional label. `nil` means the interrupting UI could not
    /// be read (e.g. process quit mid-handler) → not handled (#584).
    @discardableResult
    public static func handle(
        alertLabel: String?,
        buttonExists: (String) -> Bool,
        tapButton: (String) -> Void
    ) -> Bool {
        guard let alertLabel, shouldAttemptDismiss(alertLabel: alertLabel) else {
            return false
        }
        guard let title = dismissButtonTitles.first(where: buttonExists) else {
            return false
        }
        tapButton(title)
        return true
    }

    /// Same as ``handle(alertLabel:buttonExists:tapButton:)``, mapping snapshot
    /// `Result` failures to the nil-label path (#584).
    @discardableResult
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
