//
//  SettingsPaneDescriptor.swift
//  SixLayerFramework
//
//  Issue #210: pane identity + metadata descriptors and section builders.
//

import Foundation

public struct SettingsPaneDescriptor<ID: Hashable & Sendable>: Sendable {
    public let id: ID
    public let titleKey: String
    public let subtitleKey: String?
    public let systemImage: String?
    public let section: String?

    public init(
        id: ID,
        titleKey: String,
        subtitleKey: String? = nil,
        systemImage: String? = nil,
        section: String? = nil
    ) {
        self.id = id
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self.systemImage = systemImage
        self.section = section
    }
}

public enum SettingsPaneSectionBuilderError: Error, Equatable, Sendable {
    case duplicatePaneID(String)
}

public enum SettingsPaneSectionBuilder: Sendable {
    public static func groupedBySection<ID: Hashable & Sendable>(
        _ descriptors: [SettingsPaneDescriptor<ID>]
    ) throws -> [(section: String?, descriptors: [SettingsPaneDescriptor<ID>])] {
        // Intentionally minimal for red phase.
        return descriptors.isEmpty ? [] : [(section: nil, descriptors: descriptors)]
    }

    public static func settingsSectionData<ID: Hashable & Sendable>(
        _ descriptors: [SettingsPaneDescriptor<ID>],
        unsectionedTitle: String = "Other"
    ) throws -> [SettingsSectionData] {
        // Intentionally minimal for red phase.
        let items = descriptors.map {
            SettingsItemData(
                key: String(describing: $0.id),
                title: $0.titleKey,
                description: $0.subtitleKey,
                type: .button
            )
        }
        return [SettingsSectionData(title: unsectionedTitle, items: items)]
    }
}
