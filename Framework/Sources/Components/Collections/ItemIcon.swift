//
//  ItemIcon.swift
//  SixLayerFramework
//
//  Icon component that automatically resolves color from hints files
//  Issue #144 - Color Resolution System from Hints Files
//

import SwiftUI

/// Icon component that automatically resolves color from hints files
public struct ItemIcon<Item: CardDisplayable>: View {
    let item: Item
    let iconName: String
    let size: CGFloat
    let hints: PresentationHints
    
    public init(
        item: Item,
        iconName: String,
        size: CGFloat = 20,
        hints: PresentationHints
    ) {
        self.item = item
        self.iconName = iconName
        self.size = size
        self.hints = hints
    }
    
    public var body: some View {
        let color = CardDisplayHelper.extractColor(from: item, hints: hints) ?? hints.defaultColor ?? .accentColor
        
        Image(systemName: iconName)
            .foregroundColor(color)
            .frame(width: size, height: size)
    }
}

