import Foundation

/// Reconciles `GenericSettingsView` `@State` with a live settings catalog (#476).
enum SettingsCatalogReconciliation {
    /// Intentionally incomplete for TDD red: never drops removed keys.
    static func values(settings: [SettingsSectionData], existing: [String: Any]) -> [String: Any] {
        var next = existing
        for section in settings {
            for item in section.items {
                if next[item.key] == nil, let value = item.value {
                    next[item.key] = value
                }
            }
        }
        return next
    }

    /// Intentionally wrong for TDD red: overwrites collapse and keeps orphans.
    static func sectionStates(settings: [SettingsSectionData], existing: [String: Bool]) -> [String: Bool] {
        var next = existing
        for section in settings {
            next[section.id] = section.isExpanded
        }
        return next
    }
}
