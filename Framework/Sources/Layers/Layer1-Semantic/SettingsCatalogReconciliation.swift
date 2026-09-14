import Foundation

/// Reconciles `GenericSettingsView` `@State` with a live settings catalog (#476).
enum SettingsCatalogReconciliation {
    /// Seeds missing item keys from catalog defaults, keeps user edits, drops removed keys.
    static func values(settings: [SettingsSectionData], existing: [String: Any]) -> [String: Any] {
        var defaults: [String: Any] = [:]
        for section in settings {
            for item in section.items {
                if let value = item.value {
                    defaults[item.key] = value
                }
            }
        }
        return merge(
            existing: existing,
            liveKeys: Set(settings.flatMap { $0.items.map(\.key) }),
            seed: { defaults[$0] }
        )
    }

    /// Seeds missing section ids from `isExpanded`, keeps user collapse, drops orphans.
    static func sectionStates(settings: [SettingsSectionData], existing: [String: Bool]) -> [String: Bool] {
        merge(
            existing: existing,
            liveKeys: Set(settings.map(\.id)),
            seed: { id in settings.first { $0.id == id }?.isExpanded }
        )
    }

    private static func merge<Value>(
        existing: [String: Value],
        liveKeys: Set<String>,
        seed: (String) -> Value?
    ) -> [String: Value] {
        var next = existing.filter { liveKeys.contains($0.key) }
        for key in liveKeys where next[key] == nil {
            if let value = seed(key) {
                next[key] = value
            }
        }
        return next
    }
}
