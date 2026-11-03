//
//  PlatformSheetNavigationChrome.swift
//  SixLayerFramework
//
//  Pure decision + compile-time apply for platformSheet NavigationStack chrome (#636).
//  Mirrors the #447 sidebar/overlay pattern so Mirror subject types stay platform-truthful.
//

import Foundation
import SwiftUI

/// How `platformSheet` chromes presented roots for navigation title / toolbar (#636).
public enum PlatformSheetNavigationChrome: Equatable {
    /// Wrap in `NavigationStack` (iOS and macOS).
    case navigationStackWrapped
    /// Pass through (tvOS / watchOS / visionOS).
    case unmodified
}

/// Platform decision for sheet-root navigation chrome.
/// Apply mirrors this table via compile-time `#if os` (not a runtime ViewBuilder switch).
public func platformSheetNavigationChrome(for platform: SixLayerPlatform) -> PlatformSheetNavigationChrome {
    switch platform {
    case .iOS, .macOS:
        return .navigationStackWrapped
    case .tvOS, .watchOS, .visionOS:
        return .unmodified
    }
}

public extension View {
    /// Sheet presented root: `NavigationStack` on iOS and macOS.
    /// Apply path matches `platformSheetNavigationChrome(for: .current)`.
    @MainActor
    func platformSheetNavigationChrome() -> some View {
        #if os(iOS) || os(macOS)
        NavigationStack {
            self
        }
        #else
        self
        #endif
    }
}
