//
//  PlatformPresentDestinationStrategy.swift
//  SixLayerFramework
//
//  Presentation strategy for platformPresentDestination_L4 (#358).
//

import Foundation

/// How ``View/platformPresentDestination_L4`` presents destination content on a platform.
internal enum PlatformPresentDestinationStrategy: Equatable, Sendable {
    /// Push onto a navigation stack (`navigationDestination`).
    case navigationDestination
    /// Modal sheet (`platformSheet_L4`).
    case sheet

    /// Resolves presentation mode for `platform`.
    ///
    /// - iOS: navigation push
    /// - macOS and other platforms: sheet (macOS split-view detail often has no working push host)
    internal static func resolve(platform: SixLayerPlatform) -> PlatformPresentDestinationStrategy {
        // Deliberately inverted for TDD red (#358) — correct in the green commit.
        switch platform {
        case .iOS:
            return .sheet
        case .macOS, .tvOS, .watchOS, .visionOS:
            return .navigationDestination
        }
    }
}
