//
//  FieldHintsModifiers.swift
//  SixLayerFramework
//
//  ViewModifiers for applying field-level display hints
//

import SwiftUI

// MARK: - Field Hints ViewModifier

/// Modifier that applies field-level display hints to views
public struct FieldHintsModifier: ViewModifier {
    let fieldHints: FieldDisplayHints?
    let controlSizing: FieldLayoutControlSizing
    let availableWidth: CGFloat?

    public init(
        _ fieldHints: FieldDisplayHints?,
        controlSizing: FieldLayoutControlSizing = .fillClaim,
        availableWidth: CGFloat? = nil
    ) {
        self.fieldHints = fieldHints
        self.controlSizing = controlSizing
        self.availableWidth = availableWidth
    }

    public func body(content: Content) -> some View {
        sized(content)
            .overlay(alignment: .trailing) {
                if showCharacterCounter {
                    CharacterCounterOverlay()
                }
            }
    }

    @ViewBuilder
    private func sized(_ content: Content) -> some View {
        switch controlSizing {
        case .fillClaim:
            content.frame(maxWidth: preferredWidth, alignment: .leading)
        case .intrinsicWithinClaim:
            content
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: preferredWidth, alignment: .leading)
        }
    }

    // MARK: - Private Computed Properties

    private var preferredWidth: CGFloat? {
        FieldDisplayWidthResolver.preferredWidth(
            hints: fieldHints,
            characterWidth: FieldDisplayCharacterMetrics.averageCharacterWidth(),
            horizontalPadding: FieldDisplayCharacterMetrics.defaultHorizontalPadding,
            bands: FieldDisplayWidthPlatformBands.forPlatform(SixLayerPlatform.current),
            availableWidth: availableWidth
        )
    }

    private var showCharacterCounter: Bool {
        return fieldHints?.showCharacterCounter ?? false
    }
}

// MARK: - Character Counter Overlay

/// Overlay view that displays character count
private struct CharacterCounterOverlay: View {
    @Environment(\.fieldTextContent) var textContent

    var body: some View {
        if let text = textContent {
            Text("\(text.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.trailing, 8)
        }
    }
}

// MARK: - Environment Key for Field Text Content

/// Environment key for accessing current field text content
public struct FieldTextContentKey: EnvironmentKey {
    public static let defaultValue: String? = nil
}

public extension EnvironmentValues {
    var fieldTextContent: String? {
        get { self[FieldTextContentKey.self] }
        set { self[FieldTextContentKey.self] = newValue }
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply field-level display hints to a view.
    /// - Parameters:
    ///   - hints: Field display hints (width, counters, etc.)
    ///   - controlSizing: Whether the control fills the claim or stays intrinsic (#385)
    ///   - availableWidth: Optional container cap for preferred width
    func applyFieldHints(
        _ hints: FieldDisplayHints?,
        controlSizing: FieldLayoutControlSizing = .fillClaim,
        availableWidth: CGFloat? = nil
    ) -> some View {
        modifier(FieldHintsModifier(hints, controlSizing: controlSizing, availableWidth: availableWidth))
    }
}
