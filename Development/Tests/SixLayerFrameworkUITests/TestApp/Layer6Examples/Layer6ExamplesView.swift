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

// MARK: - L6 modifier contract (test that L6 modifiers do the right thing on the element they're applied to)

/// Elements that have ONLY the L6 modifier applied (no platformButton, no other automaticCompliance).
/// automaticCompliance runs only on the element it's called on; the L6 modifiers call it on their content.
/// So this Text and Button get a11y solely from the L6 modifier — we can verify the modifier did its job.
private struct L6ModifierContractSection: View {
    @ObservedObject var optimizationManager: CrossPlatformOptimizationManager

    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text("L6 modifier contract: elements below have only the L6 modifier applied (no platformButton).")
                .font(.caption)
                .foregroundColor(.secondary)

            // Plain Text — only a11y comes from .platformSpecificOptimizations' .automaticCompliance()
            Text("L6ContractText")
                .platformSpecificOptimizations(for: optimizationManager.currentPlatform)

            // Plain Button — only a11y comes from the modifier
            Button("L6ContractButton") { }
                .platformSpecificOptimizations(for: optimizationManager.currentPlatform)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Direct-open for UI tests (launch argument -OpenLayer6Examples)

/// Shows both Layer 6 sections (Navigation Stack Enhancements + Cross-Platform Optimizations) so
/// UI tests can assert on the actual Layer 6 API names: platformNavigationStackEnhancements_L6 and
/// platformSpecificOptimizations/performanceOptimizations/uiPatternOptimizations.
/// Includes L6 modifier contract section so tests can verify the modifier applies a11y to the element it wraps.
struct Layer6CrossPlatformOnlyView: View {
    @StateObject private var optimizationManager = CrossPlatformOptimizationManager()

    var body: some View {
        ScrollView {
            platformVStack(alignment: .leading, spacing: 24) {
                ExampleSection(title: "L6 modifier contract") {
                    L6ModifierContractSection(optimizationManager: optimizationManager)
                }
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
