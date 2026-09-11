//
//  StableCatalogIdentifiableTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for #474 / #475: catalog Identifiable ids must be stable across reinits
//  with the same natural key. `id = UUID()` mints a new identity every init.
//

import CoreLocation
import Foundation
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import SixLayerFramework

@Suite("Stable catalog Identifiable ids (#474, #475)")
struct StableCatalogIdentifiableTests {

    // MARK: - #474 Settings catalog

    @Test func settingsItemData_sameKey_sharesIdAcrossReinits() {
        let a = SettingsItemData(key: "theme", title: "Theme", type: .toggle, value: true)
        let b = SettingsItemData(key: "theme", title: "Theme", type: .toggle, value: false)
        #expect(a.id == b.id)
        #expect(a.id != SettingsItemData(key: "notifications", title: "Notifications", type: .toggle).id)
    }

    @Test func settingsSectionData_sameTitle_sharesIdAcrossReinits() {
        let a = SettingsSectionData(title: "General", items: [], isExpanded: true)
        let b = SettingsSectionData(title: "General", items: [], isExpanded: false)
        #expect(a.id == b.id)
        #expect(a.id != SettingsSectionData(title: "Privacy", items: []).id)
    }

    @Test func settingsSectionCollapse_missingKey_togglesFromDefault() {
        let toggled = SettingsSectionCollapse.toggled([:], id: "General", defaultExpanded: true)
        #expect(toggled["General"] == false)
    }

    // MARK: - #475 other catalog types

    @Test func genericDataItem_sameTitle_sharesIdAndEqualityAcrossReinits() {
        let a = GenericDataItem(title: "Car", subtitle: "A")
        let b = GenericDataItem(title: "Car", subtitle: "B")
        #expect(a.id == b.id)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func genericNumericData_sameLabel_sharesIdAcrossReinits() {
        let a = GenericNumericData(value: 1, label: "mpg", unit: "mpg")
        let b = GenericNumericData(value: 2, label: "mpg", unit: "mpg")
        #expect(a.id == b.id)
        #expect(a == b)
    }

    @Test func genericMediaItem_sameURL_sharesIdAcrossReinits() {
        let a = GenericMediaItem(title: "Photo", url: "https://example.com/a.jpg")
        let b = GenericMediaItem(title: "Other", url: "https://example.com/a.jpg")
        #expect(a.id == b.id)
        #expect(a == b)
    }

    @Test func genericHierarchicalItem_sameTitleAndLevel_sharesIdAcrossReinits() {
        let a = GenericHierarchicalItem(title: "Child", level: 1)
        let b = GenericHierarchicalItem(title: "Child", level: 1)
        #expect(a.id == b.id)
        #expect(a == b)
        #expect(a.id != GenericHierarchicalItem(title: "Child", level: 2).id)
    }

    @Test func genericTemporalItem_sameTitleAndDate_sharesIdAcrossReinits() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = GenericTemporalItem(title: "Event", date: date)
        let b = GenericTemporalItem(title: "Event", date: date)
        #expect(a.id == b.id)
        #expect(a == b)
    }

    @Test func fileInfo_sameURL_sharesIdAcrossReinits() {
        let url = URL(string: "file:///tmp/a.txt")!
        let a = FileInfo(name: "a.txt", size: 10, type: .plainText, url: url)
        let b = FileInfo(name: "renamed.txt", size: 99, type: .plainText, url: url)
        #expect(a.id == b.id)
    }

    @Test func mapAnnotationData_sameTitleAndCoordinate_sharesIdAcrossReinits() {
        #if os(iOS) || os(macOS)
        let coord = CLLocationCoordinate2D(latitude: 37.5, longitude: -122.3)
        let a = MapAnnotationData(title: "Home", coordinate: coord, content: Text("a"))
        let b = MapAnnotationData(title: "Home", coordinate: coord, content: Text("b"))
        #expect(a.id == b.id)
        #endif
    }

    @Test func responsiveCardData_sameTitle_sharesIdAcrossReinits() {
        let a = ResponsiveCardData(
            title: "Dashboard",
            subtitle: "x",
            icon: "gauge",
            color: .blue,
            complexity: .moderate
        )
        let b = ResponsiveCardData(
            title: "Dashboard",
            subtitle: "y",
            icon: "star",
            color: .red,
            complexity: .simple
        )
        #expect(a.id == b.id)
    }

    @Test func accessibilityTestResult_sameTestName_sharesIdAcrossReinits() {
        let a = AccessibilityTestResult(testName: "Contrast", status: .passed, description: "ok")
        let b = AccessibilityTestResult(testName: "Contrast", status: .failed, description: "no")
        #expect(a.id == b.id)
    }

    @Test func platformTabItem_sameTitle_sharesIdAcrossReinits() {
        let a = PlatformTabItem(title: "Home", systemImage: "house")
        let b = PlatformTabItem(title: "Home", systemImage: "house.fill")
        #expect(a.id == b.id)
    }

    @Test func gridItemData_sameTitle_sharesIdAcrossReinits() {
        let a = GridItemData(title: "One", subtitle: "a", icon: "star", color: .blue)
        let b = GridItemData(title: "One", subtitle: "b", icon: "heart", color: .red)
        #expect(a.id == b.id)
    }

    @Test func ocrDataCandidate_sameTextAndBox_sharesIdAcrossReinits() {
        let box = CGRect(x: 1, y: 2, width: 3, height: 4)
        let a = OCRDataCandidate(
            text: "ABC",
            boundingBox: box,
            confidence: 0.9,
            suggestedType: .general,
            alternativeTypes: []
        )
        let b = OCRDataCandidate(
            text: "ABC",
            boundingBox: box,
            confidence: 0.1,
            suggestedType: .general,
            alternativeTypes: []
        )
        #expect(a.id == b.id)
    }

    #if os(macOS)
    @Test func macOSDesktopDataItem_sameTitle_sharesIdAcrossReinits() {
        let a = macOSDesktopDataItem(title: "Files", icon: "folder")
        let b = macOSDesktopDataItem(title: "Files", icon: "folder.fill")
        #expect(a.id == b.id)
    }
    #endif

    #if os(iOS)
    @Test func iOSTouchDataItem_sameTitle_sharesIdAcrossReinits() {
        let a = iOSTouchDataItem(title: "Files", icon: "folder")
        let b = iOSTouchDataItem(title: "Files", icon: "folder.fill")
        #expect(a.id == b.id)
    }
    #endif
}
