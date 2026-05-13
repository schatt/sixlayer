//
//  StandaloneDropIn150HostView.swift
//  SixLayerFrameworkUITests
//
//  GitHub #150: Real-window host for standalone drop-in `platform*` functions (binding + interaction XCUITest).
//  Launched with `-OpenStandaloneDropIn150`. Mirrors are shown only when `XCUI_TESTING=1` (see configureForFastTesting).
//  Not used for #254/#255/#256 closure matrices — interaction and binding only.
//

import SwiftUI
import SixLayerFramework

/// Hosts `platformTextField` / `platformSecureField` / `platformToggle` / `platformTextEditor` / `platformForm` using the public standalone APIs.
/// Inside `ViewBuilder` scopes, unqualified `platform*` would resolve to `View` extension methods; use `SixLayerFramework.` for the free functions (same pattern as `Layer4ContractOnlyView`).
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

    var body: some View {
        NavigationStack {
            SixLayerFramework.platformForm {
                Section {
                    SixLayerFramework.platformTextField("SD150_TextField", text: $textFieldValue)
                    if showBindingMirrors {
                        Text("SD150_Mirror_T:\(textFieldValue)")
                            .accessibilityIdentifier("SD150_Mirror_T")
                    }
                    SixLayerFramework.platformTextField("SD150_AxisField", text: $axisFieldValue, axis: .vertical)
                    if showBindingMirrors {
                        Text("SD150_Mirror_A:\(axisFieldValue)")
                            .accessibilityIdentifier("SD150_Mirror_A")
                    }
                } header: {
                    Text("SD150 Text inputs")
                }
                Section {
                    SixLayerFramework.platformSecureField("SD150_SecureField", text: $secureValue)
                        .accessibilityIdentifier("UITest_SD150_SecureField")
                    if showBindingMirrors {
                        Text("SD150_Mirror_S:\(secureValue)")
                            .accessibilityIdentifier("SD150_Mirror_S")
                    }
                } header: {
                    Text("SD150 Secure")
                }
                Section {
                    SixLayerFramework.platformToggle("SD150_Toggle", isOn: $toggleOn)
                    if showBindingMirrors {
                        Text("SD150_Mirror_G:\(toggleOn ? "1" : "0")")
                            .accessibilityIdentifier("SD150_Mirror_G")
                    }
                } header: {
                    Text("SD150 Toggle")
                }
                Section {
                    SixLayerFramework.platformTextEditor("SD150_EditorPrompt", text: $editorValue)
                    if showBindingMirrors {
                        Text("SD150_Mirror_E:\(editorValue)")
                            .accessibilityIdentifier("SD150_Mirror_E")
                    }
                } header: {
                    Text("SD150 Editor")
                }
                Section {
                    SixLayerFramework.platformTextField("SD150_LongField", text: $longFieldValue)
                    if showBindingMirrors {
                        Text("SD150_Mirror_L:\(longFieldValue)")
                            .accessibilityIdentifier("SD150_Mirror_L")
                    }
                } header: {
                    Text("SD150 Long")
                }
                Section {
                    SixLayerFramework.platformTextField("SD150_Integration_Name", text: $integrationName)
                    SixLayerFramework.platformSecureField("SD150_Integration_Password", text: $integrationPassword)
                    SixLayerFramework.platformToggle("SD150_Integration_Toggle", isOn: $integrationOn)
                    if showBindingMirrors {
                        Text("SD150_Mirror_IN:\(integrationName)|\(integrationPassword)|\(integrationOn ? "1" : "0")")
                            .accessibilityIdentifier("SD150_Mirror_IN")
                    }
                } header: {
                    Text("SD150 Integration")
                }
            }
            .navigationTitle("SD150 Standalone")
            #if os(iOS) || os(macOS)
            .platformNavigationTitleDisplayMode_L4(.inline)
            #endif
        }
    }
}

