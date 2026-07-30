//
//  macOSSpecificHelpers.swift
//  SixLayerFramework
//
//  macOS-specific UI helper functions
//  Optimized for mouse/keyboard interfaces and macOS Human Interface Guidelines
//

#if os(macOS)
import SwiftUI

// MARK: - macOS-Specific UI Helpers

/// macOS-optimized card component with mouse-friendly design
public struct macOSDesktopCard: View {
    private let title: String
    private let subtitle: String?
    private let content: AnyView
    private let action: (() -> Void)?
    
    public init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> some View,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = AnyView(content())
        self.action = action
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let action = action {
                Button("Action") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular) // macOS standard size
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16) // macOS standard padding
        .background(Color.cardBackground)
        .cornerRadius(8) // macOS standard corner radius
        .shadow(radius: 2, y: 1)
        .onHover { isHovered in
            // macOS hover effects
            if isHovered {
                // Could add hover state styling
            }
        }
        .automaticCompliance(named: "macOSDesktopCard")
    }
}

/// macOS-optimized list item with mouse-friendly spacing
public struct macOSDesktopListItem<Content: View>: View {
    private let content: Content
    private let action: (() -> Void)?
    
    public init(
        @ViewBuilder content: () -> Content,
        action: (() -> Void)? = nil
    ) {
        self.content = content()
        self.action = action
    }
    
    public var body: some View {
        HStack {
            content
            Spacer()
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .onHover { isHovered in
            // macOS hover effects
            if isHovered {
                // Could add hover state styling
            }
        }
        .onTapGesture {
            action?()
        }
        .automaticCompliance(named: "macOSDesktopListItem")
    }
}

/// macOS-optimized form field with proper keyboard navigation
public struct macOSDesktopFormField: View {
    private let label: String
    private let placeholder: String
    @Binding private var text: String
    private let displayHints: FieldDisplayHints?
    
    public init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        displayHints: FieldDisplayHints? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.displayHints = displayHints
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(height: 32) // macOS standard height
                .font(.body)
        }
        .applyFieldHints(displayHints)
        .automaticCompliance(named: "macOSDesktopFormField")
    }
}

// MARK: - macOS-Specific Extensions

public extension View {
    /// macOS-specific styling with proper desktop spacing
    func macOSStyle() -> some View {
        self
                    .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(6)
            .shadow(radius: 1, y: 1)
    }
    
    /// macOS window-relative padding
    func macOSWindowPadding() -> some View {
        self
            .padding(.top, 8) // Account for window chrome
    }
}

// MARK: - macOS-Specific Data Models

/// macOS-optimized data model for desktop interfaces
public struct macOSDesktopDataItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let isActive: Bool
    
    public init(title: String, subtitle: String? = nil, icon: String, isActive: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isActive = isActive
    }
}

// MARK: - macOS Preview

#if ENABLE_PREVIEWS
#Preview {
    VStack(spacing: 20) {
        macOSDesktopCard(
            title: "macOS Card",
            subtitle: "Desktop-optimized design"
        ) {
            Text("This card is specifically designed for macOS with proper mouse interactions, keyboard navigation, and macOS Human Interface Guidelines compliance.")
        } action: {
            print("macOS card action")
        }
        
        macOSDesktopFormField(
            label: "macOS Field",
            placeholder: "Enter text here",
            text: .constant("")
        )
        
        macOSDesktopListItem {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                VStack(alignment: .leading) {
                    Text("Desktop List Item")
                        .font(.headline)
                    Text("With subtitle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        } action: {
            print("Desktop list item clicked")
        }
        .macOSStyle()
    }
    .padding()
    .frame(width: 400, height: 600)
}
#endif

#endif
