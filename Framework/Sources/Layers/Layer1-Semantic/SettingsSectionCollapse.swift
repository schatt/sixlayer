import Foundation

/// Collapse-state updates for `GenericSettingsView` section headers (#474).
enum SettingsSectionCollapse {
    /// Flips expanded state. A missing key starts from `defaultExpanded` (not a no-op).
    static func toggled(_ states: [String: Bool], id: String, defaultExpanded: Bool) -> [String: Bool] {
        var next = states
        next[id] = !(states[id] ?? defaultExpanded)
        return next
    }
}
