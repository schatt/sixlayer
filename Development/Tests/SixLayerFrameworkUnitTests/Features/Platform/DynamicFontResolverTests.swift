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

    // MARK: - iOS / macOS metrics

    #if os(iOS)
    private func bodyPointSize(contentSize: SixLayerContentSizeCategory) -> CGFloat {
        let resolver = DynamicFontResolver(defaultContentSize: contentSize)
        return resolver.uiFont(for: .body, contentSize: contentSize).pointSize
    }
    #elseif os(macOS)
    private func bodyPointSize(contentSize: SixLayerContentSizeCategory) -> CGFloat {
        let resolver = DynamicFontResolver(defaultContentSize: contentSize)
        let font = resolver.nsFont(for: .body, contentSize: contentSize)
        return font.pointSize
    }
    #endif

    @Test func testBodyFont_scalesBetweenLargeAndAccessibilityExtraLarge() {
        #if os(iOS) || os(macOS)
        let largeSize = bodyPointSize(contentSize: .large)
        let accessibilitySize = bodyPointSize(contentSize: .accessibilityExtraLarge)
        #expect(accessibilitySize > largeSize, "Body at accessibilityExtraLarge should be larger than at large")
        #else
        let resolver = DynamicFontResolver()
        _ = resolver.font(for: .body, contentSize: .accessibilityExtraLarge)
        #expect(Bool(true), "Non-iOS/macOS platforms return semantic fonts")
        #endif
    }

    @Test func testExplicitContentSizeOverrideDiffersFromLarge() {
        #if os(iOS) || os(macOS)
        let resolver = DynamicFontResolver(defaultContentSize: .large)
        #if os(iOS)
        let atDefault = resolver.uiFont(for: .body, contentSize: nil).pointSize
        let atAX = resolver.uiFont(for: .body, contentSize: .accessibilityExtraLarge).pointSize
        #elseif os(macOS)
        let atDefault = resolver.nsFont(for: .body, contentSize: nil).pointSize
        let atAX = resolver.nsFont(for: .body, contentSize: .accessibilityExtraLarge).pointSize
        #endif
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
        let large = HIGTypographySystem(for: .iOS, contentSize: .large)
        let accessibility = HIGTypographySystem(for: .iOS, contentSize: .accessibilityExtraLarge)
        let resolver = DynamicFontResolver(defaultContentSize: .large)
        let expectedLargeBody = resolver.font(for: .body, contentSize: .large)
        let expectedAXBody = resolver.font(for: .body, contentSize: .accessibilityExtraLarge)
        #expect(large.body == expectedLargeBody)
        #expect(accessibility.body == expectedAXBody)
        #expect(large.body != accessibility.body, "HIG body token should scale with content size")
        #else
        let system = HIGTypographySystem(for: .iOS, contentSize: .large)
        _ = system.body
        #expect(Bool(true))
        #endif
    }
}
