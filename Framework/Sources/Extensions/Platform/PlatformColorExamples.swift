//
//  PlatformColorExamples.swift
//  SixLayerFramework
//
//  Usage examples for cross-platform color utilities
//

import SwiftUI

// MARK: - Platform Color Usage Examples

/// Examples demonstrating how to use cross-platform color utilities
public struct PlatformColorExamples: View {
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Basic Label Colors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Label Colors")
                        .font(.headline)
                        .foregroundColor(.platformPrimaryLabel)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary Label")
                            .foregroundColor(.platformPrimaryLabel)
                        
                        Text("Secondary Label")
                            .foregroundColor(.platformSecondaryLabel)
                        
                        Text("Tertiary Label")
                            .foregroundColor(.platformTertiaryLabel)
                        
                        Text("Quaternary Label")
                            .foregroundColor(.platformQuaternaryLabel)
                    }
                    .padding()
                    .background(Color.platformSecondaryBackground)
                    .cornerRadius(8)
                }
                
                // MARK: - Text Input Colors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Text Input Colors")
                        .font(.headline)
                        .foregroundColor(.platformPrimaryLabel)
                    
                    VStack(spacing: 8) {
                        TextField("Placeholder text", text: .constant(""))
                            .foregroundColor(.platformPrimaryLabel)
                            #if os(iOS) || os(macOS)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            #else
                            .textFieldStyle(.plain)
                            #endif
                        
                        TextField("Placeholder text", text: .constant(""))
                            .foregroundColor(.platformPlaceholderText)
                            #if os(iOS) || os(macOS)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            #else
                            .textFieldStyle(.plain)
                            #endif
                    }
                    .padding()
                    .background(Color.platformBackground)
                    .cornerRadius(8)
                }
                
                // MARK: - Separator Colors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Separator Colors")
                        .font(.headline)
                        .foregroundColor(.platformPrimaryLabel)
                    
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.platformSeparator)
                            .frame(height: 1)
                        
                        Rectangle()
                            .fill(Color.platformOpaqueSeparator)
                            .frame(height: 2)
                    }
                    .padding()
                    .background(Color.platformBackground)
                    .cornerRadius(8)
                }
                
                // MARK: - Background Colors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Background Colors")
                        .font(.headline)
                        .foregroundColor(.platformPrimaryLabel)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Primary Background")
                                .foregroundColor(.platformPrimaryLabel)
                            Spacer()
                        }
                        .padding()
                        .background(Color.platformBackground)
                        .cornerRadius(8)
                        
                        HStack {
                            Text("Secondary Background")
                                .foregroundColor(.platformPrimaryLabel)
                            Spacer()
                        }
                        .padding()
                        .background(Color.platformSecondaryBackground)
                        .cornerRadius(8)
                        
                        HStack {
                            Text("Grouped Background")
                                .foregroundColor(.platformPrimaryLabel)
                            Spacer()
                        }
                        .padding()
                        .background(Color.platformGroupedBackground)
                        .cornerRadius(8)
                    }
                }
                
                // MARK: - System Colors
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Colors")
                        .font(.headline)
                        .foregroundColor(.platformPrimaryLabel)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ColorSwatch(color: .platformDestructive, name: "Destructive")
                        ColorSwatch(color: .platformTint, name: "Tint")
                        ColorSwatch(color: .platformSuccess, name: "Success")
                        ColorSwatch(color: .platformWarning, name: "Warning")
                        ColorSwatch(color: .platformInfo, name: "Info")
                        ColorSwatch(color: .platformSystemGray, name: "Gray")
                        ColorSwatch(color: .platformSystemGray2, name: "Gray2")
                        ColorSwatch(color: .platformSystemGray3, name: "Gray3")
                        ColorSwatch(color: .platformSystemGray4, name: "Gray4")
                    }
                    .padding()
                    .background(Color.platformSecondaryBackground)
                    .cornerRadius(8)
                }
                
                // MARK: - Before/After Comparison
                VStack(alignment: .leading, spacing: 12) {
                    Text("Before vs After")
                        .font(.headline)
                        .foregroundColor(.platformPrimaryLabel)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("❌ Before (Platform-specific)")
                            .font(.caption)
                            .foregroundColor(.platformDestructive)
                        
                        Text("""
                        #if os(iOS)
                        .foregroundColor(.tertiaryLabel)
                        #elseif os(macOS)
                        .foregroundColor(.secondary)
                        #endif
                        """)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.platformSecondaryLabel)
                        .padding()
                        .background(Color.platformSystemGray6)
                        .cornerRadius(4)
                        
                        Text("✅ After (Cross-platform)")
                            .font(.caption)
                            .foregroundColor(.platformSuccess)
                        
                        Text(".foregroundColor(.platformTertiaryLabel)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.platformSecondaryLabel)
                            .padding()
                            .background(Color.platformSystemGray6)
                            .cornerRadius(4)
                    }
                    .padding()
                    .background(Color.platformBackground)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .background(Color.platformGroupedBackground)
        .navigationTitle("Platform Colors")
        .automaticCompliance(named: "PlatformColorExamples")
    }
}

// MARK: - Color Swatch Component

private struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.platformSeparator, lineWidth: 1)
                )
            
            Text(name)
                .font(.caption2)
                .foregroundColor(.platformSecondaryLabel)
        }
        .automaticCompliance(named: "ColorSwatch")
    }
}

// MARK: - Usage Examples for Different Scenarios

/// Examples for form usage
public struct PlatformColorFormExamples: View {
    @State private var text = ""
    @State private var email = ""
    @State private var password = ""
    
    public init() {}
    
    public var body: some View {
        Form {
            Section {
                TextField("Enter your name", text: $text)
                    .foregroundColor(.platformPrimaryLabel)
            } header: {
                Text("Personal Information")
                    .foregroundColor(.platformPrimaryLabel)
            } footer: {
                Text("This information will be kept private")
                    .foregroundColor(.platformTertiaryLabel)
            }
            
            Section {
                TextField("Enter your email", text: $email)
                    .foregroundColor(.platformPrimaryLabel)
                    #if os(iOS)
                    .keyboardType(KeyboardType.emailAddress)
                    #endif
                
                SecureField("Enter your password", text: $password)
                    .foregroundColor(.platformPrimaryLabel)
            } header: {
                Text("Account Details")
                    .foregroundColor(.platformPrimaryLabel)
            } footer: {
                Text("Use a strong password with at least 8 characters")
                    .foregroundColor(.platformTertiaryLabel)
            }
        }
        .background(Color.platformGroupedBackground)
        .automaticCompliance(named: "PlatformColorFormExamples")
    }
}

/// Examples for list usage
public struct PlatformColorListExamples: View {
    let items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
    
    public init() {}
    
    public var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                HStack {
                    Text(item)
                        .foregroundColor(.platformPrimaryLabel)
                    
                    Spacer()
                    
                    Text("Details")
                        .foregroundColor(.platformTertiaryLabel)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .background(Color.platformGroupedBackground)
        .listStyle(PlainListStyle())
        .automaticCompliance(named: "PlatformColorListExamples")
    }
}

/// Examples for card usage
public struct PlatformColorCardExamples: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            CardView(
                title: "Primary Card",
                subtitle: "This is a primary card with important information",
                color: .platformPrimaryLabel
            )
            
            CardView(
                title: "Secondary Card",
                subtitle: "This is a secondary card with supporting information",
                color: .platformSecondaryLabel
            )
            
            CardView(
                title: "Tertiary Card",
                subtitle: "This is a tertiary card with additional details",
                color: .platformTertiaryLabel
            )
        }
        .padding()
        .background(Color.platformGroupedBackground)
        .automaticCompliance(named: "PlatformColorCardExamples")
    }
}

private struct CardView: View {
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.platformSecondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.platformSeparator, lineWidth: 1)
        )
        .automaticCompliance(named: "CardView")
    }
}

// MARK: - Preview

#if DEBUG
struct PlatformColorExamples_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlatformColorExamples()
        }
        .previewDisplayName("Platform Colors")
        
        NavigationView {
            PlatformColorFormExamples()
        }
        .previewDisplayName("Form Examples")
        
        NavigationView {
            PlatformColorListExamples()
        }
        .previewDisplayName("List Examples")
        
        NavigationView {
            PlatformColorCardExamples()
        }
        .previewDisplayName("Card Examples")
    }
}
#endif
