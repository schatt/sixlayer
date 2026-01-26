//
//  PlatformInternationalizationL1.swift
//  SixLayerFramework
//
//  Layer 1 Semantic Intent functions for Internationalization & Localization
//  Provides high-level i18n/l10n interfaces following SixLayer architecture
//

import Foundation
import SwiftUI

// MARK: - Layer 1 Internationalization Functions

/// Present localized content with automatic RTL support
/// - Parameters:
///   - content: The content to present
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with proper localization
public func platformPresentLocalizedContent_L1<Content: View>(
    content: Content,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let layoutDirection = i18n.getLayoutDirection()
    
    return AnyView(content
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformPresentLocalizedContent_L1"))
}

/// Present localized text with automatic formatting
/// - Parameters:
///   - text: The text to present
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with proper text formatting
public func platformPresentLocalizedText_L1(
    text: String,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let direction = i18n.textDirection(for: text)
    let alignment = i18n.textAlignment(for: text)
    
    return AnyView(Text(text)
        .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
        .environment(\.layoutDirection, direction == .rightToLeft ? .rightToLeft : .leftToRight)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformPresentLocalizedText_L1"))
}

/// Present localized number with proper formatting
/// - Parameters:
///   - number: The number to present
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with formatted number
public func platformPresentLocalizedNumber_L1(
    number: Double,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let formatted = i18n.formatNumber(number, decimalPlaces: hints.decimalPlaces)
    
    return AnyView(Text(formatted)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformPresentLocalizedNumber_L1"))
}

/// Present localized currency with proper formatting
/// - Parameters:
///   - amount: The amount to present
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with formatted currency
public func platformPresentLocalizedCurrency_L1(
    amount: Double,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let formatted = i18n.formatCurrency(amount, currencyCode: hints.currencyCode)
    
    return AnyView(Text(formatted)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformPresentLocalizedCurrency_L1"))
}

/// Present localized date with proper formatting
/// - Parameters:
///   - date: The date to present
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with formatted date
public func platformPresentLocalizedDate_L1(
    date: Date,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let formatted = i18n.formatDate(date, style: hints.dateStyle)
    
    return AnyView(Text(formatted)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformPresentLocalizedDate_L1"))
}

/// Present localized time with proper formatting
/// - Parameters:
///   - date: The date containing the time to present
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with formatted time
public func platformPresentLocalizedTime_L1(
    date: Date,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let formatted = i18n.formatTime(date, style: hints.timeStyle)
    
    return AnyView(Text(formatted)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformPresentLocalizedTime_L1"))
}

/// Present localized percentage with proper formatting
/// - Parameters:
///   - value: The percentage value (0.0 to 1.0)
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with formatted percentage
public func platformPresentLocalizedPercentage_L1(
    value: Double,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let formatted = i18n.formatPercentage(value)
    
    return AnyView(Text(formatted)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformPresentLocalizedPercentage_L1"))
}

/// Present localized pluralized text
/// - Parameters:
///   - word: The word to pluralize
///   - count: The count
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with pluralized text
public func platformPresentLocalizedPlural_L1(
    word: String,
    count: Int,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let pluralized = i18n.pluralize(word, count: count)
    
    return AnyView(Text(pluralized)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformPresentLocalizedPlural_L1"))
}

/// Present localized string with arguments
/// - Parameters:
///   - key: The localization key
///   - arguments: Arguments for string formatting
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with localized string
public func platformPresentLocalizedString_L1(
    key: String,
    arguments: [String] = [],
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let localized = i18n.localizedString(for: key, arguments: arguments)
    
    return AnyView(Text(localized)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformPresentLocalizedString_L1"))
}

// MARK: - Internationalization Hints

/// Hints for internationalization and localization
public struct InternationalizationHints {
    public let locale: Locale
    public let currencyCode: String
    public let decimalPlaces: Int?
    public let dateStyle: DateFormatStyle
    public let timeStyle: TimeFormatStyle
    public let enableRTL: Bool
    public let customFormat: String?
    
    public init(
        locale: Locale = Locale.current,
        currencyCode: String = "USD",
        decimalPlaces: Int? = nil,
        dateStyle: DateFormatStyle = .medium,
        timeStyle: TimeFormatStyle = .medium,
        enableRTL: Bool = true,
        customFormat: String? = nil
    ) {
        self.locale = locale
        self.currencyCode = currencyCode
        self.decimalPlaces = decimalPlaces
        self.dateStyle = dateStyle
        self.timeStyle = timeStyle
        self.enableRTL = enableRTL
        self.customFormat = customFormat
    }
}

// MARK: - RTL-Aware Container Views

/// RTL-aware container view that automatically adjusts layout direction
/// - Parameters:
///   - content: The content to wrap
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with RTL support
public func platformRTLContainer_L1<Content: View>(
    content: Content,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let layoutDirection = i18n.getLayoutDirection()
    
    return AnyView(content
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformRTLContainer_L1"))
}

/// RTL-aware HStack that automatically adjusts alignment
/// - Parameters:
///   - alignment: The vertical alignment
///   - spacing: The spacing between items
///   - content: The content to arrange horizontally
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with RTL-aware horizontal arrangement
public func platformRTLHStack_L1<Content: View>(
    alignment: VerticalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let layoutDirection = i18n.getLayoutDirection()
    
    return AnyView(platformHStackContainer(alignment: alignment, spacing: spacing, content: content)
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformRTLHStack_L1"))
}

/// RTL-aware VStack that automatically adjusts alignment
/// - Parameters:
///   - alignment: The horizontal alignment
///   - spacing: The spacing between items
///   - content: The content to arrange vertically
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with RTL-aware vertical arrangement
public func platformRTLVStack_L1<Content: View>(
    alignment: HorizontalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let layoutDirection = i18n.getLayoutDirection()
    
    return AnyView(platformVStackContainer(alignment: alignment, spacing: spacing, content: content)
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformRTLVStack_L1"))
}

/// RTL-aware ZStack that automatically adjusts alignment
/// - Parameters:
///   - alignment: The alignment
///   - content: The content to stack
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with RTL-aware stacking
public func platformRTLZStack_L1<Content: View>(
    alignment: Alignment = .center,
    @ViewBuilder content: () -> Content,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let layoutDirection = i18n.getLayoutDirection()
    
    return AnyView(platformZStackContainer(alignment: alignment, content: content)
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformRTLZStack_L1"))
}

// MARK: - Localized Form Fields

/// RTL-aware text field with proper localization
/// - Parameters:
///   - title: The field title
///   - text: Binding to the text value
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with localized text field
public func platformLocalizedTextField_L1(
    title: String,
    text: Binding<String>,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let layoutDirection = i18n.getLayoutDirection()
    
    return AnyView(TextField(title, text: text)
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformLocalizedTextField_L1"))
}

/// RTL-aware secure field with proper localization
/// - Parameters:
///   - title: The field title
///   - text: Binding to the text value
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with localized secure field
public func platformLocalizedSecureField_L1(
    title: String,
    text: Binding<String>,
    hints: InternationalizationHints = InternationalizationHints()
) -> AnyView {
    let i18n = InternationalizationService(locale: hints.locale)
    let layoutDirection = i18n.getLayoutDirection()
    
    return AnyView(SecureField(title, text: text)
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformLocalizedSecureField_L1"))
}

/// RTL-aware text editor with proper localization
/// - Parameters:
///   - title: The editor title
///   - text: Binding to the text value
///   - hints: Internationalization hints
/// - Returns: SwiftUI view with localized text editor
public func platformLocalizedTextEditor_L1(
    title: String,
    text: Binding<String>,
    hints: InternationalizationHints = InternationalizationHints()
) -> some View {
    let i18n = InternationalizationService(locale: hints.locale)
    let layoutDirection = i18n.getLayoutDirection()
    
    return TextEditor(text: text)
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.locale, hints.locale)
        .environmentObject(i18n)
        .automaticCompliance(named: "platformLocalizedTextEditor_L1")
}
