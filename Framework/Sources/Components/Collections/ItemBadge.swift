//
//  ItemBadge.swift
//  SixLayerFramework
//
//  Badge component that automatically resolves color from hints files
//  Issue #144 - Color Resolution System from Hints Files
//

import SwiftUI

/// Badge style options
public enum BadgeStyle {
    /// Colored background, white icon/text
    case `default`
    /// Colored border, colored icon/text
    case outline
    /// Light colored background, colored icon/text
    case subtle
    /// Just icon with colored foreground
    case iconOnly
}

/// Badge component that automatically resolves color from hints files
public struct ItemBadge<Item: CardDisplayable>: View {
    let item: Item
    let icon: String?
    let text: String?
    let style: BadgeStyle
    let hints: PresentationHints
    
    public init(
        item: Item,
        icon: String? = nil,
        text: String? = nil,
        style: BadgeStyle = .default,
        hints: PresentationHints
    ) {
        self.item = item
        self.icon = icon
        self.text = text
        self.style = style
        self.hints = hints
    }
    
    public var body: some View {
        let color = CardDisplayHelper.extractColor(from: item, hints: hints) ?? hints.defaultColor ?? .accentColor
        
        Group {
            switch style {
            case .default:
                defaultStyle(color: color)
            case .outline:
                outlineStyle(color: color)
            case .subtle:
                subtleStyle(color: color)
            case .iconOnly:
                iconOnlyStyle(color: color)
            }
        }
    }
    
    @ViewBuilder
    private func defaultStyle(color: Color) -> some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            if let text = text {
                Text(text)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color)
        .cornerRadius(4)
    }
    
    @ViewBuilder
    private func outlineStyle(color: Color) -> some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            if let text = text {
                Text(text)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(color, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func subtleStyle(color: Color) -> some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            if let text = text {
                Text(text)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
    
    @ViewBuilder
    private func iconOnlyStyle(color: Color) -> some View {
        if let icon = icon {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
        }
    }
}

