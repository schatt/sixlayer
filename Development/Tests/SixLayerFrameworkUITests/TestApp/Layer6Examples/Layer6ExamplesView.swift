//
//  Layer6ExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 6 system optimization functions
//  Issue #165
//

import SwiftUI
import SixLayerFramework

struct Layer6ExamplesView: View {
    var body: some View {
        ScrollView {
            platformVStack(alignment: .leading, spacing: 24) {
                ExampleSection(title: "Navigation Stack Enhancements") {
                    NavigationStackEnhancementExamples()
                }
                
                ExampleSection(title: "Cross-Platform Optimizations") {
                    CrossPlatformOptimizationExamples()
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Layer 6 Examples")
        .platformNavigationTitleDisplayMode_L4(.large)
    }
}

// MARK: - Navigation Stack Enhancement Examples

struct NavigationStackEnhancementExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 6 provides platform-specific enhancements for NavigationStack components.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ExampleCard(title: "Navigation Stack Enhancements", description: "platformNavigationStackEnhancements_L6") {
                NavigationStackEnhancementExample()
            }
        }
    }
}

struct NavigationStackEnhancementExample: View {
    var body: some View {
        NavigationStack {
            platformVStack(alignment: .leading, spacing: 12) {
                Text("This NavigationStack has platform-appropriate enhancements applied.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                NavigationLink("Go to Detail View") {
                    Text("Detail View")
                        .navigationTitle("Detail")
                }
            }
            .padding()
        }
        .platformNavigationStackEnhancements_L6()
        .frame(height: 200)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}


// MARK: - Cross-Platform Optimization Examples

struct CrossPlatformOptimizationExamples: View {
    @StateObject private var optimizationManager = CrossPlatformOptimizationManager()
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("Layer 6 provides cross-platform optimization functions for performance and UI patterns.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ExampleCard(title: "Platform-Specific Optimizations", description: "platformSpecificOptimizations(for:)") {
                PlatformSpecificOptimizationExample(optimizationManager: optimizationManager)
            }
            
            ExampleCard(title: "Performance Optimizations", description: "performanceOptimizations(using:)") {
                PerformanceOptimizationExample(optimizationManager: optimizationManager)
            }
            
            ExampleCard(title: "UI Pattern Optimizations", description: "uiPatternOptimizations(using:)") {
                UIPatternOptimizationExample(optimizationManager: optimizationManager)
            }
            
            ExampleCard(title: "Combined Optimizations", description: "All optimization types combined") {
                CombinedOptimizationExample(optimizationManager: optimizationManager)
            }
        }
    }
}

struct PlatformSpecificOptimizationExample: View {
    @ObservedObject var optimizationManager: CrossPlatformOptimizationManager
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("This view has platform-specific optimizations applied for \(optimizationManager.currentPlatform.rawValue).")
                .font(.caption)
                .foregroundColor(.secondary)
            
            platformButton(label: "Optimized Button", id: "platform-specific-optimized") {
                // Action
            }
        }
        .padding()
        .platformSpecificOptimizations(for: optimizationManager.currentPlatform)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct PerformanceOptimizationExample: View {
    @ObservedObject var optimizationManager: CrossPlatformOptimizationManager
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("This view has performance optimizations applied.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Performance Level: \(String(describing: optimizationManager.optimizationSettings.performanceLevel))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            platformButton(label: "Optimized Button", id: "performance-optimized") {
                // Action
            }
        }
        .padding()
        .performanceOptimizations(using: optimizationManager.optimizationSettings)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct UIPatternOptimizationExample: View {
    @ObservedObject var optimizationManager: CrossPlatformOptimizationManager
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("This view has UI pattern optimizations applied.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            platformButton(label: "Optimized Button", id: "ui-pattern-optimized") {
                // Action
            }
        }
        .padding()
        .uiPatternOptimizations(using: optimizationManager.uiPatterns)
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct CombinedOptimizationExample: View {
    @ObservedObject var optimizationManager: CrossPlatformOptimizationManager
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("This view has all optimization types combined:")
                .font(.caption)
                .bold()
            
            Text("• Platform-specific optimizations")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• Performance optimizations")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("• UI pattern optimizations")
                .font(.caption)
                .foregroundColor(.secondary)
            
            platformButton(label: "Fully Optimized Button", id: "fully-optimized") {
                // Action
            }
        }
        .padding()
        .platformSpecificOptimizations(for: optimizationManager.currentPlatform)
        .performanceOptimizations(using: optimizationManager.optimizationSettings)
        .uiPatternOptimizations(using: optimizationManager.uiPatterns)
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

// MARK: - Direct-open for UI tests (launch argument -OpenLayer6Examples)

/// Shows only the Cross-Platform Optimizations section with Layer 6 Examples nav title.
/// Used when the app is launched with -OpenLayer6Examples so the UI test can assert without navigating or scrolling.
struct Layer6CrossPlatformOnlyView: View {
    var body: some View {
        ScrollView {
            ExampleSection(title: "Cross-Platform Optimizations") {
                CrossPlatformOptimizationExamples()
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Layer 6 Examples")
        .platformNavigationTitleDisplayMode_L4(.large)
    }
}
