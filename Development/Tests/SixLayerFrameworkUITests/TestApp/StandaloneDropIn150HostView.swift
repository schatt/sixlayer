//
//  StandaloneDropIn150HostView.swift
//  SixLayerFrameworkUITests
//
//  GitHub #150: Real-window host for standalone drop-in `platform*` functions (binding + interaction XCUITest).
//  Launched with `-OpenStandaloneDropIn150`. Optional `-SD150Section=<name>` shows one section only
//  so XCUITest never scroll-discovers (#316). Mirrors when `XCUI_TESTING=1`.
//

import SwiftUI
import SixLayerFramework

/// Hosts `platformTextField` / `platformSecureField` / `platformToggle` / `platformTextEditor` / `platformForm`.
/// Inside `ViewBuilder` scopes, use `SixLayerFramework.` for the free functions.
struct StandaloneDropIn150HostView: View {
    @State private var textFieldValue = ""
    @State private var axisFieldValue = ""
    @State private var secureValue = ""
    @State private var toggleOn = false
    @State private var editorValue = "PrefillSeed"
    @State private var longFieldValue = ""
    @State private var integrationName = ""
    @State private var integrationPassword = ""
    @State private var integrationOn = false

    private var showBindingMirrors: Bool {
        ProcessInfo.processInfo.environment["XCUI_TESTING"] == "1"
    }

    /// Optional single-section deep link: `-SD150Section=integration|text|secure|toggle|editor|long`.
    private var focusedSection: String? {
        guard let raw = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("-SD150Section=") })?
            .split(separator: "=", maxSplits: 1)
            .last
        else { return nil }
        let name = String(raw).lowercased()
        return name.isEmpty ? nil : name
    }

    private func shows(_ section: String) -> Bool {
        guard let focusedSection else { return true }
        return focusedSection == section
    }

    /// Mirror contract: exact identifier + non-empty accessibilityLabel (no value/title fallbacks in tests).
    @ViewBuilder
    private func bindingMirror(id: String, text: String) -> some View {
        Text(text)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(id)
            .accessibilityLabel(text)
    }

    var body: some View {
        NavigationStack {
            SixLayerFramework.platformForm {
                if shows("integration") {
                    Section {
                        SixLayerFramework.platformTextField("SD150_Integration_Name", text: $integrationName)
                            .exactNamed("SD150_Integration_Name")
                        SixLayerFramework.platformSecureField("SD150_Integration_Password", text: $integrationPassword)
                            .exactNamed("SD150_Integration_Password")
                        SixLayerFramework.platformToggle("SD150_Integration_Toggle", isOn: $integrationOn)
                            .exactNamed("SD150_Integration_Toggle")
                        if showBindingMirrors {
                            bindingMirror(
                                id: "SD150_Mirror_IN",
                                text: "SD150_Mirror_IN:\(integrationName)|\(integrationPassword)|\(integrationOn ? "1" : "0")"
                            )
                        }
                    } header: {
                        Text("SD150 Integration")
                            .accessibilityIdentifier("SD150_Section_Integration")
                    }
                }
                if shows("text") {
                    Section {
                        SixLayerFramework.platformTextField("SD150_TextField", text: $textFieldValue)
                            .exactNamed("SD150_TextField")
                        if showBindingMirrors {
                            bindingMirror(id: "SD150_Mirror_T", text: "SD150_Mirror_T:\(textFieldValue)")
                        }
                        SixLayerFramework.platformTextField("SD150_AxisField", text: $axisFieldValue, axis: .vertical)
                            .exactNamed("SD150_AxisField")
                        if showBindingMirrors {
                            bindingMirror(id: "SD150_Mirror_A", text: "SD150_Mirror_A:\(axisFieldValue)")
                        }
                    } header: {
                        Text("SD150 Text inputs")
                            .accessibilityIdentifier("SD150_Section_Text")
                    }
                }
                if shows("secure") {
                    Section {
                        SixLayerFramework.platformSecureField("SD150_SecureField", text: $secureValue)
                            .exactNamed("SD150_SecureField")
                        if showBindingMirrors {
                            bindingMirror(id: "SD150_Mirror_S", text: "SD150_Mirror_S:\(secureValue)")
                        }
                    } header: {
                        Text("SD150 Secure")
                            .accessibilityIdentifier("SD150_Section_Secure")
                    }
                }
                if shows("toggle") {
                    Section {
                        SixLayerFramework.platformToggle("SD150_Toggle", isOn: $toggleOn)
                            .exactNamed("SD150_Toggle")
                        if showBindingMirrors {
                            bindingMirror(id: "SD150_Mirror_G", text: "SD150_Mirror_G:\(toggleOn ? "1" : "0")")
                        }
                    } header: {
                        Text("SD150 Toggle")
                            .accessibilityIdentifier("SD150_Section_Toggle")
                    }
                }
                if shows("editor") {
                    Section {
                        SixLayerFramework.platformTextEditor("SD150_EditorPrompt", text: $editorValue)
                            .exactNamed("SD150_EditorPrompt")
                        if showBindingMirrors {
                            bindingMirror(id: "SD150_Mirror_E", text: "SD150_Mirror_E:\(editorValue)")
                        }
                    } header: {
                        Text("SD150 Editor")
                            .accessibilityIdentifier("SD150_Section_Editor")
                    }
                }
                if shows("long") {
                    Section {
                        SixLayerFramework.platformTextField("SD150_LongField", text: $longFieldValue)
                            .exactNamed("SD150_LongField")
                        if showBindingMirrors {
                            bindingMirror(id: "SD150_Mirror_L", text: "SD150_Mirror_L:\(longFieldValue)")
                        }
                    } header: {
                        Text("SD150 Long")
                            .accessibilityIdentifier("SD150_Section_Long")
                    }
                }
            }
            .navigationTitle("SD150 Standalone")
            #if os(iOS) || os(macOS)
            .platformNavigationTitleDisplayMode_L4(.inline)
            #endif
        }
    }
}
