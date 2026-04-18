import SwiftUI

// MARK: - Platform Buttons Layer 3: Layout Implementation
/// This layer provides platform-specific button components that implement
/// button patterns across iOS and macOS. This layer handles the specific
/// implementation of button components.
public extension View {
    
    /// Platform-specific primary button style
    /// Provides consistent primary button appearance across platforms
    func platformPrimaryButtonStyle() -> some View {
        let styledView: AnyView = {
            #if os(iOS)
            return AnyView(self.buttonStyle(.borderedProminent))
            #elseif os(macOS)
            if #available(macOS 12.0, *) {
                return AnyView(self.buttonStyle(.borderedProminent))
            } else {
                return AnyView(self.buttonStyle(.bordered)
                    .foregroundColor(.platformButtonTextOnColor)
                    .background(Color.accentColor))
            }
            #else
            return AnyView(self.buttonStyle(.borderedProminent))
            #endif
        }()
        return styledView
            .automaticCompliance(named: "platformPrimaryButtonStyle")
    }
    
    /// Platform-specific secondary button style
    /// Provides consistent secondary button appearance across platforms
    func platformSecondaryButtonStyle() -> some View {
        let styledView: AnyView = {
            #if os(iOS)
            return AnyView(self.buttonStyle(.bordered))
            #elseif os(macOS)
            if #available(macOS 12.0, *) {
                return AnyView(self.buttonStyle(.bordered))
            } else {
                return AnyView(self.buttonStyle(.bordered)
                    .foregroundColor(.accentColor))
            }
            #else
            return AnyView(self.buttonStyle(.bordered))
            #endif
        }()
        return styledView
            .automaticCompliance(named: "platformSecondaryButtonStyle")
    }
    
    /// Platform-specific destructive button style
    /// Provides consistent destructive button appearance across platforms
    func platformDestructiveButtonStyle() -> some View {
        let styledView: AnyView = {
            #if os(iOS)
            return AnyView(self.buttonStyle(.borderedProminent)
                .foregroundColor(.red))
            #elseif os(macOS)
            if #available(macOS 12.0, *) {
                return AnyView(self.buttonStyle(.borderedProminent)
                    .foregroundColor(.red))
            } else {
                return AnyView(self.buttonStyle(.bordered)
                    .foregroundColor(.platformButtonTextOnColor)
                    .background(Color.red))
            }
            #else
            return AnyView(self.buttonStyle(.borderedProminent)
                .foregroundColor(.red))
            #endif
        }()
        return styledView
            .automaticCompliance(named: "platformDestructiveButtonStyle")
    }
    
    /// Platform-specific icon button with consistent styling
    /// Provides standardized icon button appearance across platforms
    func platformIconButton(
        systemImage: String,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            #if os(macOS)
            if #available(macOS 11.0, *) {
                Image(systemName: systemImage)
                    .foregroundColor(.platformLabel)
            } else {
                // Fallback for older macOS versions
                Text("•")
                    .foregroundColor(.platformLabel)
            }
            #else
            Image(systemName: systemImage)
                .foregroundColor(.platformLabel)
            #endif
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .automaticCompliance(named: "platformIconButton")
    }
}
