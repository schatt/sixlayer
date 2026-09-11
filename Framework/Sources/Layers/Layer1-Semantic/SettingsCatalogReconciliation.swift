import Foundation

/// Reconciles `GenericSettingsView` `@State` with a live settings catalog (#476).
enum SettingsCatalogReconciliation {
    /// Seeds missing item keys from catalog defaults, keeps user edits, drops removed keys.
    static func values(settings: [SettingsSectionData], existing: [String: Any]) -> [String: Any] {
        let liveKeys = Set(settings.flatMap { $0.items.map(\.key) })
        var defaults: [String: Any] = [:]
        for section in settings {
            for item in section.items {
                if let value = item.value {
                    defaults[item.key] = value
                }
            }
        }
        var next = existing.filter { liveKeys.contains($0.key) }
        for key in liveKeys where next[key] == nil {
            if let value = defaults[key] {
                next[key] = value
            }
        }
        return next
    }

    /// Seeds missing section ids from `isExpanded`, keeps user collapse, drops orphans.
    static func sectionStates(settings: [SettingsSectionData], existing: [String: Bool]) -> [String: Bool] {
        let liveIds = Set(settings.map(\.id))
        var next = existing.filter { liveIds.contains($0.key) }
        for section in settings where next[section.id] == nil {
            next[section.id] = section.isExpanded
        }
        return next
    }
}
