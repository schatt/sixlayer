//
//  PlatformPickerTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for platformPicker accessibility identifier test (Issue #163)
//

import SwiftUI
import SixLayerFramework

struct PlatformPickerTestView: View {
    var onBackToMain: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var platformPickerSelection: String = "Option1"
    
    // Options for platformPicker test (Issue #163)
    private let platformPickerOptions = ["Option1", "Option2", "Option3"]
    
    var body: some View {
        platformVStack(spacing: 20) {
            platformText("Platform Picker Test View")
                .font(.headline)
                .automaticCompliance()
            
            // TDD Test: platformPicker with automatic accessibility (Issue #163)
            // This verifies that platformPicker automatically applies accessibility
            // identifiers to both the picker and its segments
            platformPicker(
                label: "Platform Picker Test",
                selection: $platformPickerSelection,
                options: platformPickerOptions,
                pickerName: "PlatformPickerTest",
                style: SegmentedPickerStyle()
            )
            
            // Back to main page button
            platformButton("Back to Main") {
                if let action = onBackToMain { action() } else { dismiss() }
            }
            .accessibilityIdentifier("back-to-main-button")
        }
        .padding()
        .platformFrame()
        .navigationTitle("Platform Picker Test")
    }
}
