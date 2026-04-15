//
//  SettingsPaneDescriptorTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for Issue #210: pane identity + metadata descriptor and section builders.
//

import Testing
@testable import SixLayerFramework

@Suite("SettingsPaneDescriptor builders (#210)")
struct SettingsPaneDescriptorTests {

    private enum PaneID: String, Hashable, Sendable {
        case general
        case privacy
        case about
        case advanced
        case diagnostics
    }

    @Test
    func groupedBySection_preservesStableSectionAndPaneOrder() throws {
        let descriptors: [SettingsPaneDescriptor<PaneID>] = [
            .init(id: .general, titleKey: "settings.general", section: "Main"),
            .init(id: .privacy, titleKey: "settings.privacy", section: "Main"),
            .init(id: .about, titleKey: "settings.about", section: nil),
            .init(id: .advanced, titleKey: "settings.advanced", section: "Advanced"),
            .init(id: .diagnostics, titleKey: "settings.diagnostics", section: nil)
        ]

        let grouped = try SettingsPaneSectionBuilder.groupedBySection(descriptors)

        #expect(grouped.count == 3)
        #expect(grouped[0].section == "Main")
        #expect(grouped[0].descriptors.map(\.id) == [.general, .privacy])
        #expect(grouped[1].section == nil)
        #expect(grouped[1].descriptors.map(\.id) == [.about, .diagnostics])
        #expect(grouped[2].section == "Advanced")
        #expect(grouped[2].descriptors.map(\.id) == [.advanced])
    }

    @Test
    func groupedBySection_duplicateIDs_throwInvariantError() throws {
        let descriptors: [SettingsPaneDescriptor<PaneID>] = [
            .init(id: .general, titleKey: "settings.general", section: "Main"),
            .init(id: .general, titleKey: "settings.generalDuplicate", section: "Other")
        ]

        #expect(throws: SettingsPaneSectionBuilderError.duplicatePaneID("general")) {
            _ = try SettingsPaneSectionBuilder.groupedBySection(descriptors)
        }
    }

    @Test
    func groupedBySection_roundTripFlattenedIDs_matchInputOrder() throws {
        let descriptors: [SettingsPaneDescriptor<PaneID>] = [
            .init(id: .general, titleKey: "settings.general", section: "Main"),
            .init(id: .privacy, titleKey: "settings.privacy", section: "Main"),
            .init(id: .about, titleKey: "settings.about", section: nil)
        ]

        let grouped = try SettingsPaneSectionBuilder.groupedBySection(descriptors)
        let flattened = grouped.flatMap(\.descriptors).map(\.id)

        #expect(flattened == descriptors.map(\.id))
    }

    @Test
    func settingsSectionData_mapsDescriptorMetadataAndSectionBuckets() throws {
        let descriptors: [SettingsPaneDescriptor<PaneID>] = [
            .init(
                id: .general,
                titleKey: "settings.general",
                subtitleKey: "settings.general.subtitle",
                systemImage: "gearshape",
                section: "Main"
            ),
            .init(
                id: .about,
                titleKey: "settings.about",
                subtitleKey: nil,
                systemImage: nil,
                section: nil
            )
        ]

        let sections = try SettingsPaneSectionBuilder.settingsSectionData(
            descriptors,
            unsectionedTitle: "Other"
        )

        let byTitle = Dictionary(uniqueKeysWithValues: sections.map { ($0.title, $0) })
        #expect(byTitle.count == 2)

        guard let main = byTitle["Main"] else {
            Issue.record("Expected Main section")
            return
        }
        #expect(main.items.count == 1)
        #expect(main.items[0].key == "general")
        #expect(main.items[0].title == "settings.general")
        #expect(main.items[0].description == "settings.general.subtitle")
        #expect(main.items[0].type == .button)

        guard let other = byTitle["Other"] else {
            Issue.record("Expected Other section")
            return
        }
        #expect(other.items.count == 1)
        #expect(other.items[0].key == "about")
        #expect(other.items[0].title == "settings.about")
    }
}
