//
//  BasicComplianceTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for basic automatic compliance tests (Issue #172)
//

import SwiftUI
import SixLayerFramework

struct BasicComplianceTestView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Basic Compliance Test View")
                    .font(.headline)
                    .automaticCompliance()
                
                // Test 1: General .basicAutomaticCompliance() with identifier
                VStack(alignment: .leading, spacing: 8) {
                    Text("General Basic Compliance (Identifier)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Test Content")
                        .basicAutomaticCompliance(identifierName: "testView")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
                
                // Test 2: General .basicAutomaticCompliance() with label
                VStack(alignment: .leading, spacing: 8) {
                    Text("General Basic Compliance (Label)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Test Content")
                        .basicAutomaticCompliance(accessibilityLabel: "Test label")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
                
                // Test 3: Text.basicAutomaticCompliance() with identifier
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Basic Compliance (Identifier)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Hello")
                        .basicAutomaticCompliance(identifierName: "helloText")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
                
                // Test 4: Image.basicAutomaticCompliance() with identifier
                VStack(alignment: .leading, spacing: 8) {
                    Text("Image Basic Compliance (Identifier)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "star")
                        .basicAutomaticCompliance(identifierName: "starImage")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Basic Compliance Test")
    }
}
