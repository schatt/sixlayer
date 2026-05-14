//
//  PresentationProfilesCatalog.swift
//  SixLayerFramework
//
//  Loads shared presentation policy from `Hints/PresentationProfiles.hints` (JSON).
//  See GitHub #277 — opt-in profile ids; missing id logs and falls back to default `PresentationHints`.
//

import Foundation
import SwiftUI

// MARK: - Catalog

/// Loads **`Hints/PresentationProfiles.hints`** (or root `PresentationProfiles.hints`) and maps
/// **`profiles`** entries to ``PresentationHints`` using the same keys as `_defaults` in model `.hints` files.
public final class PresentationProfilesCatalog: @unchecked Sendable {
    /// Shared catalog for app use (`Bundle.main` by default).
    public static let shared = PresentationProfilesCatalog()

    private let cacheLock = NSLock()
    private let logLock = NSLock()
    private var cache: [String: [String: PresentationHints]] = [:]
    /// Dedupes `[SixLayer]` logs for missing files (per bundle path).
    private var loggedMissingFileBundles = Set<String>()
    /// Dedupes missing profile id logs (per bundle path + profile id).
    private var loggedMissingProfileKeys = Set<String>()

    public init() {}

    /// Clears parsed profile cache. Use from tests or when replacing bundled resources.
    public func resetCache(bundle: Bundle? = nil) {
        cacheLock.lock()
        if let bundle {
            cache.removeValue(forKey: bundle.bundlePath)
        } else {
            cache.removeAll()
        }
        cacheLock.unlock()

        logLock.lock()
        defer { logLock.unlock() }
        if bundle == nil {
            loggedMissingFileBundles.removeAll()
            loggedMissingProfileKeys.removeAll()
        } else {
            let prefix = bundle!.bundlePath
            loggedMissingFileBundles.remove(prefix)
            loggedMissingProfileKeys = loggedMissingProfileKeys.filter { !$0.hasPrefix(prefix + "|") }
        }
    }

    /// Resolved hints for `profileID`, or default ``PresentationHints()`` when the profile or file is absent.
    public func presentationHints(forProfileID profileID: String, bundle: Bundle = .main) -> PresentationHints {
        let all = profilesByID(bundle: bundle)
        if let hints = all[profileID] {
            return hints
        }
        logMissingProfile(profileID: profileID, bundle: bundle)
        return PresentationHints()
    }

    private func profilesByID(bundle: Bundle) -> [String: PresentationHints] {
        let key = bundle.bundlePath
        cacheLock.lock()
        if let hit = cache[key] {
            cacheLock.unlock()
            return hit
        }
        let parsed = Self.parseAllProfiles(bundle: bundle, catalog: self)
        cache[key] = parsed
        cacheLock.unlock()
        return parsed
    }

    private static func parseAllProfiles(bundle: Bundle, catalog: PresentationProfilesCatalog) -> [String: PresentationHints] {
        guard let json = loadJSON(bundle: bundle, catalog: catalog) else {
            return [:]
        }
        guard let rawProfiles = json["profiles"] as? [String: Any] else {
            logInvalidRoot(bundle: bundle, reason: "missing or invalid \"profiles\" object")
            return [:]
        }
        var out: [String: PresentationHints] = [:]
        out.reserveCapacity(rawProfiles.count)
        for (id, value) in rawProfiles {
            guard let dict = value as? [String: Any] else {
                logInvalidRoot(bundle: bundle, reason: "profile \"\(id)\" must be a JSON object")
                continue
            }
            out[id] = Self.presentationHints(fromDefaultsDictionary: dict)
        }
        return out
    }

    private static func loadJSON(bundle: Bundle, catalog: PresentationProfilesCatalog) -> [String: Any]? {
        for url in presentationProfilesCandidateURLs(bundle: bundle) {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                logInvalidRoot(bundle: bundle, reason: "could not parse JSON at \(url.path)")
                return nil
            }
            return json
        }
        catalog.logMissingHintsFile(bundle: bundle)
        return nil
    }

    private static func presentationProfilesCandidateURLs(bundle: Bundle) -> [URL] {
        var urls: [URL] = []
        if let hintsFolder = bundle.url(forResource: "Hints", withExtension: nil) {
            urls.append(hintsFolder.appendingPathComponent("PresentationProfiles.hints"))
        }
        if let root = bundle.url(forResource: "PresentationProfiles", withExtension: "hints") {
            urls.append(root)
        }
        return urls
    }

    private func logMissingHintsFile(bundle: Bundle) {
        logLock.lock()
        defer { logLock.unlock() }
        let key = bundle.bundlePath
        guard !loggedMissingFileBundles.contains(key) else { return }
        loggedMissingFileBundles.insert(key)
        let paths = Self.presentationProfilesCandidateURLs(bundle: bundle).map(\.path).joined(separator: ", ")
        print("[SixLayer] Error: PresentationProfiles.hints not found in bundle=\(key) tried=[\(paths)]")
    }

    private func logMissingProfile(profileID: String, bundle: Bundle) {
        logLock.lock()
        defer { logLock.unlock() }
        let key = "\(bundle.bundlePath)|\(profileID)"
        guard !loggedMissingProfileKeys.contains(key) else { return }
        loggedMissingProfileKeys.insert(key)
        print("[SixLayer] Error: Unknown presentation profile id=\(profileID) bundle=\(bundle.bundlePath)")
    }

    private static func logInvalidRoot(bundle: Bundle, reason: String) {
        print("[SixLayer] Error: PresentationProfiles.hints \(reason) bundle=\(bundle.bundlePath)")
    }

    // MARK: - Defaults dictionary → PresentationHints

    /// Maps `_defaults`-shaped keys to ``PresentationHints``. Field hints are always empty (profiles are surface-only).
    private static func presentationHints(fromDefaultsDictionary dict: [String: Any]) -> PresentationHints {
        let dataType = (dict["_dataType"] as? String).flatMap { Self.caseInsensitiveDataType($0) } ?? .generic
        let complexity = (dict["_complexity"] as? String).flatMap { Self.caseInsensitiveComplexity($0) } ?? .moderate
        let context = (dict["_context"] as? String).flatMap { Self.caseInsensitiveContext($0) } ?? .dashboard
        let custom = dict["_customPreferences"] as? [String: String] ?? [:]
        let presentationPreference = parsePresentationPreference(from: dict["_presentationPreference"])

        var defaultColor: Color?
        if let colorString = dict["_defaultColor"] as? String {
            defaultColor = parseColorFromString(colorString)
        }

        return PresentationHints(
            dataType: dataType,
            presentationPreference: presentationPreference,
            complexity: complexity,
            context: context,
            customPreferences: custom,
            fieldHints: [:],
            colorMapping: nil,
            itemColorProvider: nil,
            defaultColor: defaultColor
        )
    }

    private static func parsePresentationPreference(from value: Any?) -> PresentationPreference {
        guard let value else { return .automatic }
        if let string = value as? String {
            return parseSimplePresentationPreference(string)
        }
        if let dict = value as? [String: Any],
           let type = dict["type"] as? String,
           type == "countBased",
           let lowCount = dict["lowCount"] as? String,
           let highCount = dict["highCount"] as? String,
           let threshold = dict["threshold"] as? Int {
            let lowPref = parseSimplePresentationPreference(lowCount)
            let highPref = parseSimplePresentationPreference(highCount)
            return .countBased(lowCount: lowPref, highCount: highPref, threshold: threshold)
        }
        return .automatic
    }

    private static func caseInsensitiveDataType(_ string: String) -> DataTypeHint? {
        let lower = string.lowercased()
        return DataTypeHint.allCases.first { $0.rawValue.lowercased() == lower }
    }

    private static func caseInsensitiveComplexity(_ string: String) -> ContentComplexity? {
        let lower = string.lowercased()
        return ContentComplexity.allCases.first { $0.rawValue.lowercased() == lower }
    }

    private static func caseInsensitiveContext(_ string: String) -> PresentationContext? {
        let lower = string.lowercased()
        return PresentationContext.allCases.first { $0.rawValue.lowercased() == lower }
    }

    private static func parseSimplePresentationPreference(_ string: String) -> PresentationPreference {
        switch string.lowercased() {
        case "automatic": return .automatic
        case "minimal": return .minimal
        case "moderate": return .moderate
        case "rich": return .rich
        case "custom": return .custom
        case "detail": return .detail
        case "modal": return .modal
        case "navigation": return .navigation
        case "list": return .list
        case "masonry": return .masonry
        case "standard": return .standard
        case "form": return .form
        case "card": return .card
        case "cards": return .cards
        case "compact": return .compact
        case "grid": return .grid
        case "chart": return .chart
        case "coverflow": return .coverFlow
        default: return .automatic
        }
    }

    private static func parseColorFromString(_ colorString: String) -> Color? {
        let trimmed = colorString.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("#") {
            return Color(hex: trimmed)
        }
        let lowercased = trimmed.lowercased()
        switch lowercased {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .gray
        case "black": return .black
        case "white": return .white
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        default: return nil
        }
    }
}

// MARK: - Global

/// Default ``PresentationProfilesCatalog`` for apps (same instance as ``PresentationProfilesCatalog/shared``).
public let globalPresentationProfilesCatalog = PresentationProfilesCatalog.shared

// MARK: - PresentationHints

public extension PresentationHints {
    /// Loads presentation policy from **`Hints/PresentationProfiles.hints`** for `presentationProfileID`.
    ///
    /// Unknown ids and missing files log **`[SixLayer]`** errors (once per bundle / id) and yield default ``PresentationHints()``.
    init(
        presentationProfileID: String,
        bundle: Bundle = .main,
        catalog: PresentationProfilesCatalog = .shared
    ) {
        self = catalog.presentationHints(forProfileID: presentationProfileID, bundle: bundle)
    }
}
