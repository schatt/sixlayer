import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - iOS-Specific UI Helpers

/// iOS-optimized card with touch-friendly design
public struct iOSOptimizedCard<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let content: Content
    private let action: (() -> Void)?
    
    public init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.action = action
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .dynamicTypeSize(.large...(.accessibility3))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .dynamicTypeSize(.large...(.accessibility3))
                }
            }
            
            content
                .frame(maxWidth: .infinity)
        }
        .padding(20) // iOS standard padding
        .background(Color.platformBackground)
        .cornerRadius(16) // iOS standard corner radius
        .shadow(radius: 3, y: 2)
        .contentShape(Rectangle()) // Better touch handling
        .automaticCompliance(named: "iOSOptimizedCard")
    }
}

/// iOS-optimized list item with touch-friendly spacing
public struct iOSTouchListItem<Content: View>: View {
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.platformBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
        .automaticCompliance(named: "iOSTouchListItem")
    }
}

/// iOS-optimized form field with proper touch targets
public struct iOSTouchFormField: View {
    private let label: String
    private let placeholder: String
    @Binding private var text: String
    #if os(iOS)
    private let keyboardType: UIKeyboardType
    #endif
    
    #if os(iOS)
    public init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
    }
    #else
    public init(
        label: String,
        placeholder: String,
        text: Binding<String>
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
    }
    #endif
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.headline)
                .fontWeight(.medium)
                .dynamicTypeSize(.large...(.accessibility3))
            
            TextField(placeholder, text: $text)
                #if os(iOS) || os(macOS)
                .textFieldStyle(.roundedBorder)
                #else
                // .roundedBorder is unavailable on tvOS (and not used on watchOS here) (#237).
                .textFieldStyle(.plain)
                #endif
                #if os(iOS)
                .keyboardType(keyboardType)
                #endif
                .frame(height: 44) // iOS minimum touch target
                .font(.body)
                .dynamicTypeSize(.large...(.accessibility3))
        }
        .automaticCompliance(named: "iOSTouchFormField")
    }
}

// MARK: - iOS-Specific Extensions

public extension View {
    /// iOS-specific styling with proper touch targets
    func iOSStyle() -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.platformBackground)
            .cornerRadius(12)
            .shadow(radius: 2, y: 1)
    }
    
    /// iOS-safe area padding
    func iOSSafeArea() -> some View {
        self
            .padding(.top, 1) // Account for safe area
    }
}

// MARK: - iOS-Specific Data Models

/// iOS-optimized data model for touch interfaces
public struct iOSTouchDataItem: Identifiable {
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

// MARK: - iOS Preview

#if ENABLE_PREVIEWS
#Preview {
    NavigationView {
        VStack(spacing: 20) {
            iOSOptimizedCard(
                title: "iOS Card",
                subtitle: "Touch-optimized design"
            ) {
                Text("This card is specifically designed for iOS with proper touch targets, dynamic type support, and iOS Human Interface Guidelines compliance.")
            } action: {
                print("iOS card action")
            }
            
            iOSTouchFormField(
                label: "iOS Field",
                placeholder: "Enter text here",
                text: .constant("")
            )
            
            iOSTouchListItem {
                HStack {
                    VStack(alignment: .leading) {
                        Text("List Item")
                            .font(.headline)
                        Text("With subtitle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            } action: {
                print("List item tapped")
            }
            .iOSStyle()
        }
        .padding()
        .navigationTitle("iOS Helpers")
    }
}
#endif
