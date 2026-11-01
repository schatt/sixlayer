//
//  PlatformDisplayOCRLabelHarnessLayer1.swift
//  SixLayerFramework
//
//  Layer 1 entry for display OCR label harness (#609 Phase A).
//

import SwiftUI

/// Cross-platform display OCR label harness: load photo, draw ROIs, decode with `.ssocr`, export labels.
@ViewBuilder
@MainActor
public func platformDisplayOCRLabelHarness_L1(
    deskewMaximumDegrees: Double = 3,
    onExport: @escaping (DisplayOCRLabelPackage) -> Void = { _ in }
) -> some View {
    DisplayOCRLabelHarnessView(
        deskewMaximumDegrees: deskewMaximumDegrees,
        onExport: onExport
    )
    .environment(\.accessibilityIdentifierName, "platformDisplayOCRLabelHarness_L1")
    .automaticAccessibility()
    .automaticCompliance(named: "platformDisplayOCRLabelHarness_L1")
}
