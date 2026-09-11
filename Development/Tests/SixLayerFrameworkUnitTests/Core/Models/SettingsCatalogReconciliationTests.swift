//
//  SettingsCatalogReconciliationTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for #476: live catalog rebuild must seed new keys, drop removed keys,
//  and keep user-edited values / collapse.
//

import Testing
@testable import SixLayerFramework

@Suite("Settings catalog reconciliation (#476)")
struct SettingsCatalogReconciliationTests {

    private func section(
        _ title: String,
        items: [SettingsItemData],
        isExpanded: Bool = true
    ) -> SettingsSectionData {
        SettingsSectionData(title: title, items: items, isExpanded: isExpanded)
    }

    private func toggle(_ key: String, value: Bool) -> SettingsItemData {
        SettingsItemData(key: key, title: key, type: .toggle, value: value)
    }

    @Test func newKeys_receiveCatalogDefaults_existingValuesPreserved() {
        let settings = [
            section("General", items: [
                toggle("theme", value: true),
                toggle("alerts", value: false)
            ])
        ]
        let existing: [String: Any] = ["theme": false]
        let result = SettingsCatalogReconciliation.values(settings: settings, existing: existing)
        #expect(result["theme"] as? Bool == false)
        #expect(result["alerts"] as? Bool == false)
    }

    @Test func removedKeys_areDropped() {
        let settings = [
            section("General", items: [toggle("theme", value: true)])
        ]
        let existing: [String: Any] = ["theme": true, "gone": true]
        let result = SettingsCatalogReconciliation.values(settings: settings, existing: existing)
        #expect(result["theme"] as? Bool == true)
        #expect(result["gone"] == nil)
    }

    @Test func equivalentCatalog_doesNotWipeUserValues() {
        let settings = [
            section("General", items: [toggle("theme", value: true)])
        ]
        let existing: [String: Any] = ["theme": false]
        let result = SettingsCatalogReconciliation.values(settings: settings, existing: existing)
        #expect(result["theme"] as? Bool == false)
    }

    @Test func emptyCatalog_dropsAllExistingKeys() {
        let existing: [String: Any] = ["theme": true, "gone": false]
        let result = SettingsCatalogReconciliation.values(settings: [], existing: existing)
        #expect(result.isEmpty)
        #expect(
            SettingsCatalogReconciliation.sectionStates(
                settings: [],
                existing: ["General": false]
            ).isEmpty
        )
    }

    @Test func newSections_seedExpanded_existingCollapsePreserved_orphansDropped() {
        let settings = [
            section("General", items: [], isExpanded: true),
            section("Privacy", items: [], isExpanded: false)
        ]
        let existing = ["General": false, "Orphan": true]
        let result = SettingsCatalogReconciliation.sectionStates(settings: settings, existing: existing)
        #expect(result["General"] == false)
        #expect(result["Privacy"] == false)
        #expect(result["Orphan"] == nil)
    }
}
