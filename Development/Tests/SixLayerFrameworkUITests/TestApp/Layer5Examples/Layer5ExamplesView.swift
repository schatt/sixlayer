//
//  Layer5ExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 5 platform optimization functions
//  Issue #165
//

import SwiftUI
import SixLayerFramework

struct Layer5ExamplesView: View {
    var body: some View {
        ScrollView {
            platformVStack(alignment: .leading, spacing: 24) {
                ExampleSection(title: "Navigation Stack Optimizations") {
                    NavigationStackOptimizationExamples()
                }
                
                ExampleSection(title: "Split View Optimizations") {
                    SplitViewOptimizationExamples()
                }
                
                ExampleSection(title: "Accessibility Features") {
                    AccessibilityFeatureExamples()
                }
            }
            .padding()
        }
        .navigationTitle("Layer 5 Examples")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Navigation Stack Optimization Examples

struct NavigationStackOptimizationExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 5 provides platform-specific performance optimizations for NavigationStack components.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ExampleCard(title: "Navigation Stack Optimizations", description: "platformNavigationStackOptimizations_L5") {
                NavigationStackOptimizationExample()
            }
            
            ExampleCard(title: "iOS Navigation Stack Optimizations", description: "platformIOSNavigationStackOptimizations_L5") {
                IOSNavigationStackOptimizationExample()
            }
            
            ExampleCard(title: "macOS Navigation Stack Optimizations", description: "platformMacOSNavigationStackOptimizations_L5") {
                MacOSNavigationStackOptimizationExample()
            }
        }
    }
}

struct NavigationStackOptimizationExample: View {
    var body: some View {
        NavigationStack {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("This NavigationStack has platform-appropriate optimizations applied.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                NavigationLink("Go to Detail View") {
                    Text("Detail View")
                        .navigationTitle("Detail")
                }
            }
            .padding()
        }
        .platformNavigationStackOptimizations_L5()
        .frame(height: 200)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct IOSNavigationStackOptimizationExample: View {
    var body: some View {
        #if os(iOS)
        NavigationStack {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("iOS-specific optimizations: touch responsiveness, smooth transitions, memory efficiency")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                NavigationLink("Go to Detail View") {
                    Text("Detail View")
                        .navigationTitle("Detail")
                }
            }
            .padding()
        }
        .platformIOSNavigationStackOptimizations_L5()
        .frame(height: 200)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        #else
        Text("iOS-specific optimizations are only available on iOS")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
        #endif
    }
}

struct MacOSNavigationStackOptimizationExample: View {
    var body: some View {
        #if os(macOS)
        NavigationStack {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("macOS-specific optimizations: window performance, state preservation, desktop rendering")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                NavigationLink("Go to Detail View") {
                    Text("Detail View")
                        .navigationTitle("Detail")
                }
            }
            .padding()
        }
        .platformMacOSNavigationStackOptimizations_L5()
        .frame(height: 200)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        #else
        Text("macOS-specific optimizations are only available on macOS")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
        #endif
    }
}

// MARK: - Split View Optimization Examples

struct SplitViewOptimizationExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 5 provides platform-specific performance optimizations for split views.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ExampleCard(title: "Split View Optimizations", description: "platformSplitViewOptimizations_L5") {
                SplitViewOptimizationExample()
            }
            
            ExampleCard(title: "iOS Split View Optimizations", description: "platformIOSSplitViewOptimizations_L5") {
                IOSSplitViewOptimizationExample()
            }
            
            ExampleCard(title: "macOS Split View Optimizations", description: "platformMacOSSplitViewOptimizations_L5") {
                MacOSSplitViewOptimizationExample()
            }
        }
    }
}

struct SplitViewOptimizationExample: View {
    var body: some View {
        #if os(iOS) || os(macOS)
        NavigationSplitView {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("Sidebar")
                    .font(.headline)
                Text("This split view has platform-appropriate optimizations applied.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        } detail: {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("Detail")
                    .font(.headline)
                Text("Optimizations improve performance and responsiveness.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .platformSplitViewOptimizations_L5()
        .frame(height: 200)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        #else
        Text("Split views are only available on iOS and macOS")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
        #endif
    }
}

struct IOSSplitViewOptimizationExample: View {
    var body: some View {
        #if os(iOS)
        NavigationSplitView {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("Sidebar")
                    .font(.headline)
                Text("iOS optimizations: touch responsiveness, smooth animations, memory efficiency")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        } detail: {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("Detail")
                    .font(.headline)
            }
            .padding()
        }
        .platformIOSSplitViewOptimizations_L5()
        .frame(height: 200)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        #else
        Text("iOS-specific optimizations are only available on iOS")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
        #endif
    }
}

struct MacOSSplitViewOptimizationExample: View {
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("Sidebar")
                    .font(.headline)
                Text("macOS optimizations: window performance, large dataset handling, desktop rendering")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        } detail: {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("Detail")
                    .font(.headline)
            }
            .padding()
        }
        .platformMacOSSplitViewOptimizations_L5()
        .frame(height: 200)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        #else
        Text("macOS-specific optimizations are only available on macOS")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.platformSecondaryBackground)
            .cornerRadius(8)
        #endif
    }
}

// MARK: - Accessibility Feature Examples

struct AccessibilityFeatureExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 5 provides accessibility enhancement functions for improved accessibility support.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ExampleCard(title: "Accessibility Enhanced", description: "accessibilityEnhanced()") {
                AccessibilityEnhancedExample()
            }
            
            ExampleCard(title: "VoiceOver Enabled", description: "voiceOverEnabled()") {
                VoiceOverEnabledExample()
            }
            
            ExampleCard(title: "Keyboard Navigable", description: "keyboardNavigable()") {
                KeyboardNavigableExample()
            }
            
            ExampleCard(title: "High Contrast Enabled", description: "highContrastEnabled()") {
                HighContrastEnabledExample()
            }
        }
    }
}

struct AccessibilityEnhancedExample: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("This view has comprehensive accessibility enhancements applied.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            platformButton("Accessible Button") {
                // Action
            }
        }
        .padding()
        .accessibilityEnhanced()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct VoiceOverEnabledExample: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("This view is optimized for VoiceOver navigation.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            platformButton("VoiceOver Button") {
                // Action
            }
        }
        .padding()
        .voiceOverEnabled()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct KeyboardNavigableExample: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("This view supports full keyboard navigation.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            platformButton("Keyboard Button") {
                // Action
            }
        }
        .padding()
        .keyboardNavigable()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct HighContrastEnabledExample: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("This view is optimized for high contrast mode.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            platformButton("High Contrast Button") {
                // Action
            }
        }
        .padding()
        .highContrastEnabled()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

private struct ExampleSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
            
            content()
        }
    }
}

private struct ExampleCard<Content: View>: View {
    let title: String
    let description: String
    let content: () -> Content
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            content()
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(12)
    }
}
