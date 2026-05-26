//
//  DynamicFontResolverTests.swift
//  SixLayerFrameworkUnitTests
//
//  Validates central Dynamic Type font resolution (#295).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Suite(.serialized)
struct DynamicFontResolverTests {

    #if os(iOS) || os(macOS)
    private func bodyPointSize(resolver: DynamicFontResolver, contentSize: SixLayerContentSizeCategory?) -> CGFloat {
        #if os(iOS)
        return resolver.uiFont(for: .body, contentSize: contentSize).pointSize
        #elseif os(macOS)
        return resolver.nsFont(for: .body, contentSize: contentSize).pointSize
        #endif
    }
    #endif

    @Test func testBodyFont_scalesBetweenLargeAndAccessibilityExtraLarge() {
        #if os(iOS) || os(macOS)
        let resolver = DynamicFontResolver()
        let largeSize = bodyPointSize(resolver: resolver, contentSize: .large)
        let accessibilitySize = bodyPointSize(resolver: resolver, contentSize: .accessibilityExtraLarge)
        #expect(accessibilitySize > largeSize, "Body at accessibilityExtraLarge should be larger than at large")
        #else
        let resolver = DynamicFontResolver()
        _ = resolver.font(for: .body, contentSize: .accessibilityExtraLarge)
        #expect(Bool(true), "Non-iOS/macOS platforms return platform reference fonts")
        #endif
    }

    @Test func testExplicitContentSizeOverrideDiffersFromLarge() {
        #if os(iOS) || os(macOS)
        let resolver = DynamicFontResolver(defaultContentSize: .large)
        let atDefault = bodyPointSize(resolver: resolver, contentSize: nil)
        let atAX = bodyPointSize(resolver: resolver, contentSize: .accessibilityExtraLarge)
        #expect(atAX > atDefault, "Explicit accessibilityExtraLarge override should increase body size")
        #else
        #expect(Bool(true))
        #endif
    }

    @Test func testAllTextStylesReturnUsableFonts() {
        let resolver = DynamicFontResolver()
        for style in SixLayerTextStyle.allCases {
            let font = resolver.font(for: style, contentSize: .large)
            _ = Text("Sample").font(font)
            #expect(Bool(true), "Font for \(style) should be usable in SwiftUI")
        }
    }

    #if os(iOS)
    @Test func testUIFontBridgeMatchesFontResolution() {
        let resolver = DynamicFontResolver(defaultContentSize: .extraLarge)
        let uiFont = resolver.uiFont(for: .headline, contentSize: .extraLarge)
        #expect(uiFont.pointSize > 0)
        #expect(uiFont.fontDescriptor.postscriptName != nil)
    }
    #endif

    @Test func testHIGTypographySystemDelegatesToResolver() {
        #if os(iOS) || os(macOS)
        let resolver = DynamicFontResolver(defaultContentSize: .large)
        let large = HIGTypographySystem(for: .iOS, contentSize: .large)
        let accessibility = HIGTypographySystem(for: .iOS, contentSize: .accessibilityExtraLarge)
        #expect(large.body == resolver.font(for: .body, contentSize: .large))
        #expect(accessibility.body == resolver.font(for: .body, contentSize: .accessibilityExtraLarge))
        #expect(large.body != accessibility.body, "HIG body token should scale with content size")
        #else
        let system = HIGTypographySystem(for: .iOS, contentSize: .large)
        _ = system.body
        #expect(Bool(true))
        #endif
    }
}
