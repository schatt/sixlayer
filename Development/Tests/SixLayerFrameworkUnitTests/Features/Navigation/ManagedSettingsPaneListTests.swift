//
//  ManagedSettingsPaneListTests.swift
//  SixLayerFrameworkUnitTests
//
//  Strict TDD for Issue #214: descriptor-driven default settings sidebar.
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("ManagedSettingsPaneList (#214)")
struct ManagedSettingsPaneListTests {

    private enum PaneID: String, Hashable, Sendable {
        case general
        case privacy
        case about
    }

    private final class TopHolder: @unchecked Sendable {
        var state: PlatformManagedSettingsTopLevelState<PaneID>
        init(_ state: PlatformManagedSettingsTopLevelState<PaneID>) { self.state = state }
        var binding: Binding<PlatformManagedSettingsTopLevelState<PaneID>> {
            Binding(get: { self.state }, set: { self.state = $0 })
        }
    }

    @Test @MainActor
    func init_throwsOnDuplicatePaneIDs() {
        let descriptors: [SettingsPaneDescriptor<PaneID>] = [
            .init(id: .general, titleKey: "settings.general", section: "Main"),
            .init(id: .general, titleKey: "settings.generalDup", section: "Other")
        ]
        let holder = TopHolder(
            PlatformManagedSettingsTopLevelState<PaneID>(orderedTopLevelPaneIDs: [.general, .privacy, .about], deviceType: .pad)
        )

        #expect(throws: SettingsPaneSectionBuilderError.duplicatePaneID("general")) {
            _ = try ManagedSettingsPaneList(descriptors: descriptors, state: holder.binding)
        }
    }

    @Test @MainActor
    func testDescriptorRowCount_matchesFlattenedDescriptors() throws {
        let descriptors: [SettingsPaneDescriptor<PaneID>] = [
            .init(id: .general, titleKey: "settings.general", section: "Main"),
            .init(id: .privacy, titleKey: "settings.privacy", section: "Main"),
            .init(id: .about, titleKey: "settings.about", section: nil)
        ]
        let holder = TopHolder(
            PlatformManagedSettingsTopLevelState<PaneID>(orderedTopLevelPaneIDs: [.general, .privacy, .about], deviceType: .pad)
        )
        let list = try ManagedSettingsPaneList(descriptors: descriptors, state: holder.binding)

        #expect(list.testDescriptorRowCount == 3)
    }

    @Test @MainActor
    func defaultSelectionBinding_updatesTopLevelState() throws {
        let descriptors: [SettingsPaneDescriptor<PaneID>] = [
            .init(id: .general, titleKey: "settings.general", section: nil),
            .init(id: .privacy, titleKey: "settings.privacy", section: nil)
        ]
        let holder = TopHolder(
            PlatformManagedSettingsTopLevelState<PaneID>(orderedTopLevelPaneIDs: [.general, .privacy], deviceType: .pad)
        )
        let list = try ManagedSettingsPaneList(descriptors: descriptors, state: holder.binding, onSelectionChange: nil)

        list.testSelectionBinding.wrappedValue = .privacy

        #expect(holder.state.selectedTopLevel == .privacy)
    }

    @Test @MainActor
    func customOnSelectionChange_doesNotMutateStateByDefault() throws {
        let descriptors: [SettingsPaneDescriptor<PaneID>] = [
            .init(id: .general, titleKey: "settings.general", section: nil)
        ]
        let holder = TopHolder(
            PlatformManagedSettingsTopLevelState<PaneID>(orderedTopLevelPaneIDs: [.general], deviceType: .pad)
        )
        let before = holder.state.selectedTopLevel
        let list = try ManagedSettingsPaneList(descriptors: descriptors, state: holder.binding) { _ in
            // Adopter handles mutation; list does not touch `state`.
        }

        list.testSelectionBinding.wrappedValue = nil

        #expect(holder.state.selectedTopLevel == before)
    }
}
