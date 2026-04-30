//
//  LiquidGlassExampleUsage.swift
//  SixLayerFramework
//
//  Example usage of Liquid Glass design system with capability detection
//

import Foundation
import SwiftUI

// MARK: - Liquid Glass Example Usage

/// Example demonstrating how to use Liquid Glass with proper capability detection
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
public struct LiquidGlassExampleUsage: View {
    @State private var capabilityInfo: LiquidGlassCapabilityInfo
    
    public init() {
        self._capabilityInfo = State(initialValue: LiquidGlassCapabilityDetection.getPlatformCapabilities())
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Liquid Glass Design System")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Capability Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Capability Status")
                    .font(.headline)
                
                HStack {
                    Text("Supported:")
                    Text(capabilityInfo.isSupported ? "Yes" : "No")
                        .foregroundColor(capabilityInfo.isSupported ? .green : .red)
                }
                
                HStack {
                    Text("Support Level:")
                    Text(capabilityInfo.supportLevel.rawValue)
                        .foregroundColor(.blue)
                }
                
                Text("Recommended Approach:")
                    .font(.subheadline)
                Text(LiquidGlassCapabilityDetection.recommendedFallbackApproach)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Available Features
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Features")
                    .font(.headline)
                
                ForEach(capabilityInfo.availableFeatures, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(feature.rawValue)
                    }
                }
                
                if capabilityInfo.availableFeatures.isEmpty {
                    Text("No Liquid Glass features available")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Fallback Behaviors
            VStack(alignment: .leading, spacing: 8) {
                Text("Fallback Behaviors")
                    .font(.headline)
                
                ForEach(Array(capabilityInfo.fallbackBehaviors.keys), id: \.self) { feature in
                    if let behavior = capabilityInfo.fallbackBehaviors[feature] {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(.orange)
                            Text("\(feature.rawValue): \(behavior.rawValue)")
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .automaticCompliance(named: "LiquidGlassExampleUsage")
    }
}

// MARK: - Conditional Liquid Glass Components

/// Example of how to conditionally use Liquid Glass components
public struct ConditionalLiquidGlassExample: View {
    public init() {}
    
    public var body: some View {
        VStack {
            if LiquidGlassCapabilityDetection.isSupported {
                // Use full Liquid Glass features
                if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                    FullLiquidGlassView()
                } else {
                    FallbackUIView()
                }
            } else {
                // Use fallback UI
                FallbackUIView()
            }
        }
        .automaticCompliance(named: "ConditionalLiquidGlassExample")
    }
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
private struct FullLiquidGlassView: View {
    var body: some View {
        VStack {
            Text("Full Liquid Glass UI")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("This would use the complete Liquid Glass design system")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .automaticCompliance(named: "FullLiquidGlassView")
    }
}

private struct FallbackUIView: View {
    var body: some View {
        VStack {
            Text("Standard UI with Enhanced Styling")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("This uses standard UI components with enhanced styling")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .automaticCompliance(named: "FallbackUIView")
    }
}

// MARK: - Preview

#if DEBUG
struct LiquidGlassExampleUsage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                LiquidGlassExampleUsage()
                    .previewDisplayName("Liquid Glass Example")
            }
            
            ConditionalLiquidGlassExample()
                .previewDisplayName("Conditional Usage")
        }
    }
}
#endif
