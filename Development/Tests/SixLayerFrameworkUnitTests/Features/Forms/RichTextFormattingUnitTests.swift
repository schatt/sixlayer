//
//  RichTextFormattingUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for RichTextFormatting (#523).
//

import Foundation
import Testing
@testable import SixLayerFramework

@Suite("RichTextFormatting (#523)")
struct RichTextFormattingUnitTests {

    @Test func apply_boldWrapsSelectionWithMarkdown() {
        let text = "hello world"
        let range = NSRange(location: 6, length: 5)
        let updated = RichTextFormatting.apply(.bold, to: text, selection: range)
        #expect(updated == "hello **world**")
    }

    @Test func apply_italicWrapsSelection() {
        let text = "hello world"
        let range = NSRange(location: 6, length: 5)
        #expect(RichTextFormatting.apply(.italic, to: text, selection: range) == "hello *world*")
    }

    @Test func apply_underlineWrapsSelection() {
        let text = "hello world"
        let range = NSRange(location: 6, length: 5)
        #expect(RichTextFormatting.apply(.underline, to: text, selection: range) == "hello <u>world</u>")
    }

    @Test func apply_returnsNilForInvalidRange() {
        let text = "hi"
        let range = NSRange(location: 10, length: 1)
        #expect(RichTextFormatting.apply(.bold, to: text, selection: range) == nil)
    }
}
