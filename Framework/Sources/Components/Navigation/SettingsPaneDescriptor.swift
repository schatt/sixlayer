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
        var seenIDs = Set<ID>()
        var sectionOrder: [String?] = []
        var sectionBuckets: [String?: [SettingsPaneDescriptor<ID>]] = [:]

        for descriptor in descriptors {
            let insertion = seenIDs.insert(descriptor.id)
            guard insertion.inserted else {
                throw SettingsPaneSectionBuilderError.duplicatePaneID(String(describing: descriptor.id))
            }

            if sectionBuckets[descriptor.section] == nil {
                sectionOrder.append(descriptor.section)
                sectionBuckets[descriptor.section] = []
            }
            sectionBuckets[descriptor.section, default: []].append(descriptor)
        }

        return sectionOrder.map { section in
            (section: section, descriptors: sectionBuckets[section] ?? [])
        }
    }

    public static func settingsSectionData<ID: Hashable & Sendable>(
        _ descriptors: [SettingsPaneDescriptor<ID>],
        unsectionedTitle: String = "Other"
    ) throws -> [SettingsSectionData] {
        let grouped = try groupedBySection(descriptors)

        return grouped.map { group in
            let items = group.descriptors.map { descriptor in
                SettingsItemData(
                    key: String(describing: descriptor.id),
                    title: descriptor.titleKey,
                    description: descriptor.subtitleKey,
                    type: .button
                )
            }
            return SettingsSectionData(
                title: group.section ?? unsectionedTitle,
                items: items
            )
        }
    }
}
