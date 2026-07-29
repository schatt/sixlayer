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

    /// Approximate average character width for `expectedLength` when no font metrics are injected.
    private static let defaultCharacterWidth: CGFloat = 9
    private static let defaultHorizontalPadding: CGFloat = 16

    public init(_ fieldHints: FieldDisplayHints?) {
        self.fieldHints = fieldHints
    }

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: preferredWidth, alignment: .leading)
            .overlay(alignment: .trailing) {
                if showCharacterCounter {
                    CharacterCounterOverlay()
                }
            }
    }

    // MARK: - Private Computed Properties

    private var preferredWidth: CGFloat? {
        FieldDisplayWidthResolver.preferredWidth(
            hints: fieldHints,
            characterWidth: Self.defaultCharacterWidth,
            horizontalPadding: Self.defaultHorizontalPadding,
            bands: FieldDisplayWidthPlatformBands.forPlatform(SixLayerPlatform.current)
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
    /// Apply field-level display hints to a view
    func applyFieldHints(_ hints: FieldDisplayHints?) -> some View {
        modifier(FieldHintsModifier(hints))
    }
}
