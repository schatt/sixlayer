import Foundation

/// Collapse-state updates for `GenericSettingsView` section headers (#474).
enum SettingsSectionCollapse {
    /// Intentionally wrong for TDD red: missing keys are a no-op (`?.toggle()`).
    static func toggled(_ states: [String: Bool], id: String, defaultExpanded _: Bool) -> [String: Bool] {
        var next = states
        if var value = next[id] {
            value.toggle()
            next[id] = value
        }
        return next
    }
}
