//
//  SwiftDataContextAccess.swift
//  SixLayerFramework
//
//  Read a host-installed SwiftData context without opening the empty default store (#589).
//

import SwiftUI
#if canImport(SwiftData)
import SwiftData

/// Looks up a SwiftData context the host actually installed.
///
/// `EnvironmentValues.modelContext` is non-optional. When the key is absent, its getter
/// `try!`s a store at `file:///dev/null` whose `default` configuration has no entities and
/// aborts (`SwiftDataError.loadIssueModelContainer`). The environment description lists
/// `ModelContextEnvironmentKey` only after `.modelContainer` / `.modelContext` writes the key,
/// and that listing does not evaluate the getter.
@available(macOS 14.0, iOS 17.0, *)
enum SwiftDataContextAccess {
    struct MissingContainer: Error, Equatable, LocalizedError {
        var errorDescription: String? {
            "No SwiftData model container is installed. Refusing to open the empty default store."
        }
    }

    /// The installed context, or `nil` when the host did not install one.
    @MainActor
    static func installedContext(in environment: EnvironmentValues) -> ModelContext? {
        guard environment.description.contains("ModelContextEnvironmentKey") else {
            return nil
        }
        return environment.modelContext
    }

    /// The installed context, or ``MissingContainer`` when the host did not install one.
    @MainActor
    static func requireInstalledContext(in environment: EnvironmentValues) throws -> ModelContext {
        guard let context = installedContext(in: environment) else {
            throw MissingContainer()
        }
        return context
    }
}
#endif
