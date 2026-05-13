//
//  FormTestPickerStyle.swift
//  Shared test helper: MenuPickerStyle is unavailable on watchOS.
//

import SwiftUI

extension View {
    /// Unit tests that use `.menu` pickers for smoke builds; watchOS uses `.wheel`.
    @ViewBuilder
    public func pickerStyleMenuOrWheelForUnitTests() -> some View {
        #if os(watchOS)
        self.pickerStyle(.wheel)
        #else
        self.pickerStyle(.menu)
        #endif
    }
}
