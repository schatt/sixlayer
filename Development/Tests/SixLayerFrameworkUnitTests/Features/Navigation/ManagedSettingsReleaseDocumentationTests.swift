//
//  ManagedSettingsReleaseDocumentationTests.swift
//  Issue #215 — release-facing managed settings migration docs.
//

import Foundation
import Testing

@Suite("Managed settings release documentation (#215)")
struct ManagedSettingsReleaseDocumentationTests {
    private static func repositoryRootURL(filePath: String = #filePath) -> URL {
        var url = URL(fileURLWithPath: filePath)
        for _ in 0..<5 {
            url.deleteLastPathComponent()
        }
        return url
    }

    private static func readFile(_ relativePath: String) throws -> String {
        let path = repositoryRootURL().appendingPathComponent(relativePath).path
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    @Test
    func changelog_includesManagedSettingsMigrationBlurb() throws {
        let changelog = try Self.readFile("CHANGELOG.md")
        #expect(changelog.contains("Managed settings migration"))
        #expect(changelog.contains("ManagedPlatformSettingsFlowGuide.md"))
    }

    @Test
    func releaseNotes_includeManagedSettingsMigrationFromSelectedCategory() throws {
        let releaseNotes = try Self.readFile("Development/RELEASE_v7.5.13.md")
        #expect(releaseNotes.contains("migration from manual `selectedCategory`"))
        #expect(releaseNotes.contains("ManagedPlatformSettingsFlowGuide.md"))
        #expect(releaseNotes.contains("ManagedPlatformSettingsFlowGuideExampleTests.swift"))
    }
}
